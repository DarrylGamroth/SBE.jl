using Test
using SBE

const IR = SBE.IR

function encode_integer_bytes(::Type{T}, value) where {T}
    return reinterpret(UInt8, [htol(T(value))])
end

function encode_float_bytes(value::Float32)
    bits = reinterpret(UInt32, value)
    return reinterpret(UInt8, [htol(bits)])
end

function encode_float_bytes(value::Float64)
    bits = reinterpret(UInt64, value)
    return reinterpret(UInt8, [htol(bits)])
end

function parse_integer_value(value::String, primitive_type::IR.PrimitiveType.T)
    if primitive_type == IR.PrimitiveType.CHAR && !all(isdigit, value)
        return UInt8(codeunit(value, 1))
    end
    if primitive_type in (IR.PrimitiveType.UINT8, IR.PrimitiveType.UINT16,
        IR.PrimitiveType.UINT32, IR.PrimitiveType.UINT64)
        parsed = tryparse(UInt64, value)
        return parsed === nothing ? UInt64(parse(Int64, value)) : parsed
    end
    return parse(Int64, value)
end

function primitive_value_bytes(value::Union{Nothing, IR.PrimitiveValue}, primitive_type::IR.PrimitiveType.T)
    value === nothing && return UInt8[]
    if value.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        return collect(codeunits(value.value))
    elseif value.representation == IR.PrimitiveValueRepresentation.DOUBLE
        if primitive_type == IR.PrimitiveType.FLOAT
            return encode_float_bytes(parse(Float32, value.value))
        end
        return encode_float_bytes(parse(Float64, value.value))
    end

    parsed = parse_integer_value(value.value, primitive_type)
    if primitive_type == IR.PrimitiveType.INT8
        return reinterpret(UInt8, [Int8(parsed)])
    elseif primitive_type == IR.PrimitiveType.UINT8 || primitive_type == IR.PrimitiveType.CHAR
        return [UInt8(parsed)]
    elseif primitive_type == IR.PrimitiveType.INT16
        return encode_integer_bytes(Int16, parsed)
    elseif primitive_type == IR.PrimitiveType.UINT16
        return encode_integer_bytes(UInt16, parsed)
    elseif primitive_type == IR.PrimitiveType.INT32
        return encode_integer_bytes(Int32, parsed)
    elseif primitive_type == IR.PrimitiveType.UINT32
        return encode_integer_bytes(UInt32, parsed)
    elseif primitive_type == IR.PrimitiveType.INT64
        return encode_integer_bytes(Int64, parsed)
    elseif primitive_type == IR.PrimitiveType.UINT64
        return encode_integer_bytes(UInt64, parsed)
    end

    return UInt8[]
end

function compare_encoding(a::IR.Encoding, b::IR.Encoding)
    @test a.presence == b.presence
    @test a.primitive_type == b.primitive_type
    @test a.byte_order == b.byte_order
    @test a.character_encoding == b.character_encoding
    @test a.epoch == b.epoch
    @test a.time_unit == b.time_unit
    @test a.semantic_type == b.semantic_type

    @test primitive_value_bytes(a.const_value, a.primitive_type) ==
        primitive_value_bytes(b.const_value, b.primitive_type)
    @test primitive_value_bytes(a.min_value, a.primitive_type) ==
        primitive_value_bytes(b.min_value, b.primitive_type)
    @test primitive_value_bytes(a.max_value, a.primitive_type) ==
        primitive_value_bytes(b.max_value, b.primitive_type)
    @test primitive_value_bytes(a.null_value, a.primitive_type) ==
        primitive_value_bytes(b.null_value, b.primitive_type)
end

function compare_tokens(a::Vector{IR.Token}, b::Vector{IR.Token})
    @test length(a) == length(b)
    for (token_a, token_b) in zip(a, b)
        @test token_a.signal == token_b.signal
        @test token_a.name == token_b.name
        @test token_a.referenced_name == token_b.referenced_name
        @test token_a.description == token_b.description
        @test token_a.package_name == token_b.package_name
        @test token_a.id == token_b.id
        @test token_a.version == token_b.version
        @test token_a.deprecated == token_b.deprecated
        @test token_a.encoded_length == token_b.encoded_length
        @test token_a.offset == token_b.offset
        @test token_a.component_token_count == token_b.component_token_count
        compare_encoding(token_a.encoding, token_b.encoding)
    end
end

function compare_ir(ir_a::IR.Ir, ir_b::IR.Ir)
    @test ir_a.package_name == ir_b.package_name
    @test ir_a.namespace_name == ir_b.namespace_name
    @test ir_a.id == ir_b.id
    @test ir_a.version == ir_b.version
    @test ir_a.semantic_version == ir_b.semantic_version
    @test ir_a.byte_order == ir_b.byte_order
    @test ir_a.namespaces == ir_b.namespaces

    compare_tokens(ir_a.header_structure.tokens, ir_b.header_structure.tokens)
    @test ir_a.header_structure.block_length_type == ir_b.header_structure.block_length_type
    @test ir_a.header_structure.template_id_type == ir_b.header_structure.template_id_type
    @test ir_a.header_structure.schema_id_type == ir_b.header_structure.schema_id_type
    @test ir_a.header_structure.schema_version_type == ir_b.header_structure.schema_version_type

    @test sort(collect(keys(ir_a.messages_by_id))) == sort(collect(keys(ir_b.messages_by_id)))
    for key in keys(ir_a.messages_by_id)
        compare_tokens(ir_a.messages_by_id[key], ir_b.messages_by_id[key])
    end

    @test sort(collect(keys(ir_a.types_by_name))) == sort(collect(keys(ir_b.types_by_name)))
    for key in keys(ir_a.types_by_name)
        compare_tokens(ir_a.types_by_name[key], ir_b.types_by_name[key])
    end
end

@testset "IR Decoder" begin
    xml_path = joinpath(@__DIR__, "resources", "ir-basic-schema.xml")
    sbeir_path = joinpath(@__DIR__, "resources", "ir-basic-schema.sbeir")

    xml_content = read(xml_path, String)
    schema = parse_xml_schema(xml_content)
    ir_from_xml = SBE.generate_ir(schema)

    ir_from_sbeir = decode_ir(sbeir_path)
    ir_from_sbeir_generated = decode_ir_generated(sbeir_path)

    compare_ir(ir_from_xml, ir_from_sbeir)
    compare_ir(ir_from_xml, ir_from_sbeir_generated)
    compare_ir(ir_from_sbeir, ir_from_sbeir_generated)
end
