"""
Decode SBE IR (.sbeir) files into the in-memory IR representation.

This follows the sbe-ir.xml schema used by the reference implementation.
"""
module IrDecoder

using ..IR
import ..capture_types!

const SBE_IR_MODULE_NAME = Symbol("UkCoRealLogicSbeIrGenerated")
const SBE_IR_ALIAS_NAME = Symbol("Uk_co_real_logic_sbe_ir_generated")

const SIGNAL_BY_CODE = Dict(
    UInt8(1) => IR.Signal.BEGIN_MESSAGE,
    UInt8(2) => IR.Signal.END_MESSAGE,
    UInt8(3) => IR.Signal.BEGIN_COMPOSITE,
    UInt8(4) => IR.Signal.END_COMPOSITE,
    UInt8(5) => IR.Signal.BEGIN_FIELD,
    UInt8(6) => IR.Signal.END_FIELD,
    UInt8(7) => IR.Signal.BEGIN_GROUP,
    UInt8(8) => IR.Signal.END_GROUP,
    UInt8(9) => IR.Signal.BEGIN_ENUM,
    UInt8(10) => IR.Signal.VALID_VALUE,
    UInt8(11) => IR.Signal.END_ENUM,
    UInt8(12) => IR.Signal.BEGIN_SET,
    UInt8(13) => IR.Signal.CHOICE,
    UInt8(14) => IR.Signal.END_SET,
    UInt8(15) => IR.Signal.BEGIN_VAR_DATA,
    UInt8(16) => IR.Signal.END_VAR_DATA,
    UInt8(17) => IR.Signal.ENCODING
)

const PRIMITIVE_TYPE_BY_CODE = Dict(
    UInt8(0) => IR.PrimitiveType.NONE,
    UInt8(1) => IR.PrimitiveType.CHAR,
    UInt8(2) => IR.PrimitiveType.INT8,
    UInt8(3) => IR.PrimitiveType.INT16,
    UInt8(4) => IR.PrimitiveType.INT32,
    UInt8(5) => IR.PrimitiveType.INT64,
    UInt8(6) => IR.PrimitiveType.UINT8,
    UInt8(7) => IR.PrimitiveType.UINT16,
    UInt8(8) => IR.PrimitiveType.UINT32,
    UInt8(9) => IR.PrimitiveType.UINT64,
    UInt8(10) => IR.PrimitiveType.FLOAT,
    UInt8(11) => IR.PrimitiveType.DOUBLE
)

const PRESENCE_BY_CODE = Dict(
    UInt8(0) => IR.Presence.REQUIRED,
    UInt8(1) => IR.Presence.OPTIONAL,
    UInt8(2) => IR.Presence.CONSTANT
)

@inline function read_le(::Type{T}, buffer::AbstractVector{UInt8}, offset::Int) where {T}
    @inbounds return ltoh(reinterpret(T, view(buffer, offset + 1:offset + sizeof(T)))[1])
end

@inline read_u8(buffer::AbstractVector{UInt8}, offset::Int) = @inbounds buffer[offset + 1]

function read_var_data(buffer::AbstractVector{UInt8}, offset::Int)
    len = read_le(UInt16, buffer, offset)
    start = offset + 2
    if len == 0
        return UInt8[], start
    end
    bytes = view(buffer, start + 1:start + len)
    return bytes, start + len
end

string_from_bytes(bytes::AbstractVector{UInt8}) = isempty(bytes) ? "" : String(Vector{UInt8}(bytes))

function optional_string_from_bytes(bytes::AbstractVector{UInt8})
    isempty(bytes) && return nothing
    return String(Vector{UInt8}(bytes))
end

function sbe_ir_module()
    root = parentmodule(@__MODULE__)
    for name in (SBE_IR_ALIAS_NAME, SBE_IR_MODULE_NAME)
        if isdefined(root, name)
            return getfield(root, name)
        end
    end
    return nothing
end

function map_signal(code::UInt8)
    return get(SIGNAL_BY_CODE, code, IR.Signal.ENCODING)
end

function map_primitive_type(code::UInt8)
    return get(PRIMITIVE_TYPE_BY_CODE, code, IR.PrimitiveType.NONE)
end

function map_presence(code::UInt8)
    return get(PRESENCE_BY_CODE, code, IR.Presence.REQUIRED)
end

function map_byte_order(code::UInt8)
    return code == 0x01 ? :bigEndian : :littleEndian
end

function primitive_value_from_bytes(bytes::AbstractVector{UInt8}, primitive_type::IR.PrimitiveType.T)
    isempty(bytes) && return nothing
    if primitive_type == IR.PrimitiveType.CHAR
        if length(bytes) == 1
            return IR.PrimitiveValue(
                IR.PrimitiveValueRepresentation.LONG,
                string(UInt8(bytes[1])),
                "US-ASCII",
                1
            )
        end
        return IR.PrimitiveValue(
            IR.PrimitiveValueRepresentation.BYTE_ARRAY,
            String(Vector{UInt8}(bytes)),
            "US-ASCII",
            length(bytes)
        )
    elseif primitive_type == IR.PrimitiveType.FLOAT
        val = read_le(Float32, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.DOUBLE, string(val), nothing, 4)
    elseif primitive_type == IR.PrimitiveType.DOUBLE
        val = read_le(Float64, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.DOUBLE, string(val), nothing, 8)
    elseif primitive_type == IR.PrimitiveType.INT8
        val = reinterpret(Int8, bytes)[1]
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 1)
    elseif primitive_type == IR.PrimitiveType.INT16
        val = read_le(Int16, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 2)
    elseif primitive_type == IR.PrimitiveType.INT32
        val = read_le(Int32, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 4)
    elseif primitive_type == IR.PrimitiveType.INT64
        val = read_le(Int64, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 8)
    elseif primitive_type == IR.PrimitiveType.UINT8
        val = UInt8(bytes[1])
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 1)
    elseif primitive_type == IR.PrimitiveType.UINT16
        val = read_le(UInt16, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 2)
    elseif primitive_type == IR.PrimitiveType.UINT32
        val = read_le(UInt32, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 4)
    elseif primitive_type == IR.PrimitiveType.UINT64
        val = read_le(UInt64, bytes, 0)
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, string(val), nothing, 8)
    end
    return nothing
end

function decode_header_structure(tokens::Vector{IR.Token})
    block_type = IR.PrimitiveType.UINT16
    template_type = IR.PrimitiveType.UINT16
    schema_type = IR.PrimitiveType.UINT16
    version_type = IR.PrimitiveType.UINT16

    for token in tokens
        if token.signal != IR.Signal.ENCODING
            continue
        end
        if token.name == "blockLength"
            block_type = token.encoding.primitive_type
        elseif token.name == "templateId"
            template_type = token.encoding.primitive_type
        elseif token.name == "schemaId"
            schema_type = token.encoding.primitive_type
        elseif token.name == "version"
            version_type = token.encoding.primitive_type
        end
    end

    return IR.HeaderStructure(tokens, block_type, template_type, schema_type, version_type)
end

function decode_ir(buffer::AbstractVector{UInt8})
    offset = 0
    ir_id = read_le(Int32, buffer, offset)
    ir_version = read_le(Int32, buffer, offset + 4)
    schema_version = read_le(Int32, buffer, offset + 8)
    ir_version == 0 || error("Unknown IR version: $ir_version")

    offset += 12
    package_bytes, offset = read_var_data(buffer, offset)
    namespace_bytes, offset = read_var_data(buffer, offset)
    semantic_bytes, offset = read_var_data(buffer, offset)

    package_name = string_from_bytes(package_bytes)
    namespace_name = optional_string_from_bytes(namespace_bytes)
    semantic_version = optional_string_from_bytes(semantic_bytes)

    tokens = IR.Token[]
    while offset < length(buffer)
        token_offset = read_le(Int32, buffer, offset)
        token_size = read_le(Int32, buffer, offset + 4)
        field_id = read_le(Int32, buffer, offset + 8)
        token_version = read_le(Int32, buffer, offset + 12)
        component_token_count = read_le(Int32, buffer, offset + 16)
        signal = map_signal(read_u8(buffer, offset + 20))
        primitive_type = map_primitive_type(read_u8(buffer, offset + 21))
        byte_order = map_byte_order(read_u8(buffer, offset + 22))
        presence = map_presence(read_u8(buffer, offset + 23))
        deprecated = read_le(Int32, buffer, offset + 24)

        offset += 28

        name_bytes, offset = read_var_data(buffer, offset)
        const_bytes, offset = read_var_data(buffer, offset)
        min_bytes, offset = read_var_data(buffer, offset)
        max_bytes, offset = read_var_data(buffer, offset)
        null_bytes, offset = read_var_data(buffer, offset)
        char_enc_bytes, offset = read_var_data(buffer, offset)
        epoch_bytes, offset = read_var_data(buffer, offset)
        time_unit_bytes, offset = read_var_data(buffer, offset)
        semantic_type_bytes, offset = read_var_data(buffer, offset)
        description_bytes, offset = read_var_data(buffer, offset)
        referenced_name_bytes, offset = read_var_data(buffer, offset)
        package_name_bytes, offset = read_var_data(buffer, offset)

        encoding = IR.Encoding(
            presence,
            primitive_type,
            byte_order,
            primitive_value_from_bytes(min_bytes, primitive_type),
            primitive_value_from_bytes(max_bytes, primitive_type),
            primitive_value_from_bytes(null_bytes, primitive_type),
            primitive_value_from_bytes(const_bytes, primitive_type),
            optional_string_from_bytes(char_enc_bytes),
            optional_string_from_bytes(epoch_bytes),
            optional_string_from_bytes(time_unit_bytes),
            optional_string_from_bytes(semantic_type_bytes)
        )

        push!(tokens, IR.Token(
            signal,
            string_from_bytes(name_bytes),
            optional_string_from_bytes(referenced_name_bytes),
            string_from_bytes(description_bytes),
            optional_string_from_bytes(package_name_bytes),
            field_id,
            token_version,
            deprecated,
            token_size,
            token_offset,
            component_token_count,
            encoding
        ))
    end

    header_tokens = IR.Token[]
    token_start = 1
    if !isempty(tokens) && tokens[1].signal == IR.Signal.BEGIN_COMPOSITE
        header_name = tokens[1].name
        for i in eachindex(tokens)
            push!(header_tokens, tokens[i])
            if tokens[i].signal == IR.Signal.END_COMPOSITE && tokens[i].name == header_name
                token_start = i + 1
                break
            end
        end
    end

    byte_order = :littleEndian
    for token in tokens
        if token.signal == IR.Signal.ENCODING
            byte_order = token.encoding.byte_order
            break
        end
    end

    header_structure = decode_header_structure(header_tokens)
    namespace_source = namespace_name === nothing ? package_name : namespace_name
    ir = IR.Ir(
        package_name,
        namespace_name,
        ir_id,
        schema_version,
        "",
        semantic_version === nothing ? "" : semantic_version,
        byte_order,
        header_structure,
        Dict{Int, Vector{IR.Token}}(),
        Dict{String, Vector{IR.Token}}(),
        split(namespace_source, ".")
    )

    if !isempty(header_tokens)
        capture_types!(ir, header_tokens)
    end

    i = token_start
    while i <= length(tokens)
        token = tokens[i]
        if token.signal == IR.Signal.BEGIN_MESSAGE
            message_tokens = IR.Token[token]
            i += 1
            while i <= length(tokens)
                push!(message_tokens, tokens[i])
                if tokens[i].signal == IR.Signal.END_MESSAGE
                    break
                end
                i += 1
            end
            ir.messages_by_id[token.id] = message_tokens
            capture_types!(ir, message_tokens)
        end
        i += 1
    end

    return ir
end

function decode_ir(path::AbstractString)
    return decode_ir(read(path))
end

function decode_ir_generated(buffer::AbstractVector{UInt8})
    mod = sbe_ir_module()
    mod === nothing && error("Generated SBE IR codecs not loaded. Run scripts/generate_sbe_ir.jl.")

    pos = Ref(0)
    frame_block_length = mod.FrameCodec.sbe_block_length(mod.FrameCodec.Decoder)
    frame_schema_version = mod.FrameCodec.sbe_schema_version(mod.FrameCodec.Decoder)
    frame = mod.FrameCodec.Decoder(buffer, 0, pos, frame_block_length, frame_schema_version)

    ir_id = mod.FrameCodec.irId(frame)
    ir_version = mod.FrameCodec.irVersion(frame)
    schema_version = mod.FrameCodec.schemaVersion(frame)
    ir_version == 0 || error("Unknown IR version: $ir_version")

    package_bytes = mod.FrameCodec.packageName(frame)
    namespace_bytes = mod.FrameCodec.namespaceName(frame)
    semantic_bytes = mod.FrameCodec.semanticVersion(frame)

    package_name = string_from_bytes(package_bytes)
    namespace_name = optional_string_from_bytes(namespace_bytes)
    semantic_version = optional_string_from_bytes(semantic_bytes)

    tokens = IR.Token[]
    offset = pos[]
    token_block_length = mod.TokenCodec.sbe_block_length(mod.TokenCodec.Decoder)
    token_schema_version = mod.TokenCodec.sbe_schema_version(mod.TokenCodec.Decoder)

    while offset < length(buffer)
        token_pos = Ref(offset)
        token = mod.TokenCodec.Decoder(buffer, offset, token_pos, token_block_length, token_schema_version)

        token_offset = mod.TokenCodec.tokenOffset(token)
        token_size = mod.TokenCodec.tokenSize(token)
        field_id = mod.TokenCodec.fieldId(token)
        token_version = mod.TokenCodec.tokenVersion(token)
        component_token_count = mod.TokenCodec.componentTokenCount(token)
        signal = map_signal(UInt8(mod.TokenCodec.signal(token)))
        primitive_type = map_primitive_type(UInt8(mod.TokenCodec.primitiveType(token)))
        byte_order = map_byte_order(UInt8(mod.TokenCodec.byteOrder(token)))
        presence = map_presence(UInt8(mod.TokenCodec.presence(token)))
        deprecated = mod.TokenCodec.deprecated(token)

        name_bytes = mod.TokenCodec.name(token)
        const_bytes = mod.TokenCodec.constValue(token)
        min_bytes = mod.TokenCodec.minValue(token)
        max_bytes = mod.TokenCodec.maxValue(token)
        null_bytes = mod.TokenCodec.nullValue(token)
        char_enc_bytes = mod.TokenCodec.characterEncoding(token)
        epoch_bytes = mod.TokenCodec.epoch(token)
        time_unit_bytes = mod.TokenCodec.timeUnit(token)
        semantic_type_bytes = mod.TokenCodec.semanticType(token)
        description_bytes = mod.TokenCodec.description(token)
        referenced_name_bytes = mod.TokenCodec.referencedName(token)
        package_name_bytes = mod.TokenCodec.packageName(token)

        encoding = IR.Encoding(
            presence,
            primitive_type,
            byte_order,
            primitive_value_from_bytes(min_bytes, primitive_type),
            primitive_value_from_bytes(max_bytes, primitive_type),
            primitive_value_from_bytes(null_bytes, primitive_type),
            primitive_value_from_bytes(const_bytes, primitive_type),
            optional_string_from_bytes(char_enc_bytes),
            optional_string_from_bytes(epoch_bytes),
            optional_string_from_bytes(time_unit_bytes),
            optional_string_from_bytes(semantic_type_bytes)
        )

        push!(tokens, IR.Token(
            signal,
            string_from_bytes(name_bytes),
            optional_string_from_bytes(referenced_name_bytes),
            string_from_bytes(description_bytes),
            optional_string_from_bytes(package_name_bytes),
            field_id,
            token_version,
            deprecated,
            token_size,
            token_offset,
            component_token_count,
            encoding
        ))

        offset = token_pos[]
    end

    header_tokens = IR.Token[]
    token_start = 1
    if !isempty(tokens) && tokens[1].signal == IR.Signal.BEGIN_COMPOSITE
        header_name = tokens[1].name
        for i in eachindex(tokens)
            push!(header_tokens, tokens[i])
            if tokens[i].signal == IR.Signal.END_COMPOSITE && tokens[i].name == header_name
                token_start = i + 1
                break
            end
        end
    end

    byte_order = :littleEndian
    for token in tokens
        if token.signal == IR.Signal.ENCODING
            byte_order = token.encoding.byte_order
            break
        end
    end

    header_structure = decode_header_structure(header_tokens)
    namespace_source = namespace_name === nothing ? package_name : namespace_name
    ir = IR.Ir(
        package_name,
        namespace_name,
        ir_id,
        schema_version,
        "",
        semantic_version === nothing ? "" : semantic_version,
        byte_order,
        header_structure,
        Dict{Int, Vector{IR.Token}}(),
        Dict{String, Vector{IR.Token}}(),
        split(namespace_source, ".")
    )

    if !isempty(header_tokens)
        capture_types!(ir, header_tokens)
    end

    i = token_start
    while i <= length(tokens)
        token = tokens[i]
        if token.signal == IR.Signal.BEGIN_MESSAGE
            message_tokens = IR.Token[token]
            i += 1
            while i <= length(tokens)
                push!(message_tokens, tokens[i])
                if tokens[i].signal == IR.Signal.END_MESSAGE
                    break
                end
                i += 1
            end
            ir.messages_by_id[token.id] = message_tokens
            capture_types!(ir, message_tokens)
        end
        i += 1
    end

    return ir
end

function decode_ir_generated(path::AbstractString)
    return decode_ir_generated(read(path))
end

end # module IrDecoder
