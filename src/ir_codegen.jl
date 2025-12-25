"""
IR-based code generation utilities.

These helpers are shared by the IR code generator as it is ported from the Java reference.
"""

struct IrEnumValue
    name::String
    literal::String
    description::String
    since_version::Int
    deprecated::Int
end

struct IrEnumDef
    name::String
    encoding_type::IR.PrimitiveType.T
    values::Vector{IrEnumValue}
end

struct IrSetChoice
    name::String
    bit_position::Int
    description::String
    since_version::Int
    deprecated::Int
end

struct IrSetDef
    name::String
    encoding_type::IR.PrimitiveType.T
    choices::Vector{IrSetChoice}
    since_version::Int
    offset::Int
end

function format_struct_name(name::String)
    parts = split(name, r"[_\\-]")
    return join([uppercasefirst(part) for part in parts])
end

function format_property_name(name::String)
    parts = split(name, r"[_\\-]")
    if length(parts) == 1
        return lowercase(name)
    end
    return lowercase(parts[1]) * join([uppercasefirst(part) for part in parts[2:end]])
end

function primitive_value_literal(value::IR.PrimitiveValue, primitive_type::IR.PrimitiveType.T)
    if value.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        return repr(value.value)
    elseif value.representation == IR.PrimitiveValueRepresentation.DOUBLE
        if primitive_type == IR.PrimitiveType.FLOAT
            return "Float32(" * value.value * ")"
        elseif primitive_type == IR.PrimitiveType.DOUBLE
            return "Float64(" * value.value * ")"
        end
        return value.value
    end

    if primitive_type == IR.PrimitiveType.CHAR
        return "UInt8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT8
        return "UInt8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT16
        return "UInt16(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT32
        return "UInt32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT64
        return "UInt64(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT8
        return "Int8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT16
        return "Int16(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT32
        return "Int32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT64
        return "Int64(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.FLOAT
        return "Float32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.DOUBLE
        return "Float64(" * value.value * ")"
    end

    return value.value
end

function enum_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    encoding_type = begin_token.encoding.primitive_type
    values = IrEnumValue[]
    for token in tokens
        if token.signal == IR.Signal.VALID_VALUE
            literal = primitive_value_literal(token.encoding.const_value, encoding_type)
            push!(values, IrEnumValue(token.name, literal, token.description, token.version, token.deprecated))
        end
    end
    return IrEnumDef(begin_token.name, encoding_type, values)
end

function set_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    encoding_type = begin_token.encoding.primitive_type
    choices = IrSetChoice[]
    for token in tokens
        if token.signal == IR.Signal.CHOICE
            bit_position = parse(Int, token.encoding.const_value.value)
            push!(choices, IrSetChoice(token.name, bit_position, token.description, token.version, token.deprecated))
        end
    end
    return IrSetDef(begin_token.name, encoding_type, choices, begin_token.version, begin_token.offset)
end

function generate_enum_expr(enum_def::IrEnumDef)
    enum_name = Symbol(format_struct_name(enum_def.name))
    encoding_julia_type = IR.primitive_type_julia(enum_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    enum_values = Expr[]

    for value in enum_def.values
        value_name = Symbol(value.name)
        push!(enum_values, :($value_name = $(Meta.parse(value.literal))))
    end

    null_value = if enum_def.encoding_type == IR.PrimitiveType.CHAR
        UInt8(0x0)
    else
        encoding_julia_type <: Unsigned ? typemax(encoding_julia_type) : typemin(encoding_julia_type)
    end

    push!(enum_values, :(NULL_VALUE = $encoding_type_symbol($null_value)))

    enum_quoted = quote
        @enumx T = SbeEnum $enum_name::$encoding_julia_type begin
            $(enum_values...)
        end
    end

    return extract_expr_from_quote(enum_quoted, :macrocall)
end

function header_field_type(ir::IR.Ir, field_name::String)
    header = ir.header_structure
    if field_name == "blockLength"
        return IR.primitive_type_julia(header.block_length_type)
    elseif field_name == "templateId"
        return IR.primitive_type_julia(header.template_id_type)
    elseif field_name == "schemaId"
        return IR.primitive_type_julia(header.schema_id_type)
    elseif field_name == "version"
        return IR.primitive_type_julia(header.schema_version_type)
    end
    return UInt16
end

function ir_type_expr(ir::IR.Ir, field_name::String, value)
    field_type = header_field_type(ir, field_name)
    return Expr(:call, Symbol(field_type), value)
end

template_id_expr(ir::IR.Ir, value) = ir_type_expr(ir, "templateId", value)
schema_id_expr(ir::IR.Ir, value) = ir_type_expr(ir, "schemaId", value)
version_expr(ir::IR.Ir, value) = ir_type_expr(ir, "version", value)
block_length_expr(ir::IR.Ir, value) = ir_type_expr(ir, "blockLength", value)

function generate_encoded_types_expr(byte_order::Symbol)
    if byte_order == :bigEndian
        return quote
            import SBE: encode_value_be, decode_value_be, encode_array_be, decode_array_be
            const encode_value = encode_value_be
            const decode_value = decode_value_be
            const encode_array = encode_array_be
            const decode_array = decode_array_be
        end
    end
    return quote
        import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
        const encode_value = encode_value_le
        const decode_value = decode_value_le
        const encode_array = encode_array_le
        const decode_array = decode_array_le
    end
end

function generate_set_expr(set_def::IrSetDef, ir::IR.Ir)
    set_name = Symbol(format_struct_name(set_def.name))
    abstract_type_name = Symbol(string("Abstract", set_name))
    decoder_name = :Decoder
    encoder_name = :Encoder

    encoding_julia_type = IR.primitive_type_julia(set_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    encoding_size = sizeof(encoding_julia_type)

    choice_exprs = Expr[]
    for choice in set_def.choices
        choice_func_name = Symbol(format_property_name(choice.name))
        choice_func_name_set = Symbol(string(choice_func_name, "!"))
        bit_position = choice.bit_position

        push!(choice_exprs, quote
            @inline function $choice_func_name(set::$abstract_type_name)
                return decode_value($encoding_type_symbol, set.buffer, set.offset) & ($encoding_type_symbol(0x1) << $bit_position) != 0
            end
        end)

        push!(choice_exprs, quote
            @inline function $choice_func_name_set(set::$encoder_name, value::Bool)
                bits = decode_value($encoding_type_symbol, set.buffer, set.offset)
                bits = value ? (bits | ($encoding_type_symbol(0x1) << $bit_position)) : (bits & ~($encoding_type_symbol(0x1) << $bit_position))
                encode_value($encoding_type_symbol, set.buffer, set.offset, bits)
                return set
            end
        end)

        push!(choice_exprs, :(export $choice_func_name, $choice_func_name_set))
    end

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    set_quoted = quote
        module $set_name
            using SBE: AbstractSbeEncodedType

            $endian_imports

            abstract type $abstract_type_name <: AbstractSbeEncodedType end

            struct $decoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
                acting_version::UInt16
            end

            struct $encoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
            end

            @inline function $decoder_name(buffer::AbstractVector{UInt8})
                $decoder_name(buffer, Int64(0), $(version_expr(ir, ir.version)))
            end

            @inline function $decoder_name(buffer::AbstractVector{UInt8}, offset::Integer)
                $decoder_name(buffer, Int64(offset), $(version_expr(ir, ir.version)))
            end

            @inline function $encoder_name(buffer::AbstractVector{UInt8})
                $encoder_name(buffer, Int64(0))
            end

            id(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, 0xffff))
            id(::$abstract_type_name) = $(template_id_expr(ir, 0xffff))
            since_version(::Type{<:$abstract_type_name}) = $(version_expr(ir, set_def.since_version))
            since_version(::$abstract_type_name) = $(version_expr(ir, set_def.since_version))

            encoding_offset(::Type{<:$abstract_type_name}) = $(set_def.offset)
            encoding_offset(::$abstract_type_name) = $(set_def.offset)
            encoding_length(::Type{<:$abstract_type_name}) = $encoding_size
            encoding_length(::$abstract_type_name) = $encoding_size

            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))

            Base.eltype(::Type{<:$abstract_type_name}) = $encoding_julia_type
            Base.eltype(::$abstract_type_name) = $encoding_julia_type

            @inline function clear!(set::$encoder_name)
                encode_value($encoding_julia_type, set.buffer, set.offset, zero($encoding_julia_type))
                return set
            end

            @inline function is_empty(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset) == zero($encoding_julia_type)
            end

            @inline function raw_value(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset)
            end

            $(choice_exprs...)

            export $abstract_type_name, $decoder_name, $encoder_name
            export clear!, is_empty, raw_value
        end
    end

    return extract_expr_from_quote(set_quoted, :module)
end

function find_first_token(name::String, tokens::Vector{IR.Token}, start_index::Int=1)
    for i in start_index:length(tokens)
        if tokens[i].name == name
            return tokens[i]
        end
    end
    error("token not found: $(name)")
end

function module_name_from_package(package_name::String)
    parts = split(replace(package_name, "." => "_"), "_")
    return Symbol(join([uppercasefirst(part) for part in parts]))
end

function generate_ir_module_expr(ir::IR.Ir)
    module_name = module_name_from_package(ir.package_name)
    enum_exprs = Expr[]
    set_exprs = Expr[]

    for tokens in values(ir.types_by_name)
        if isempty(tokens)
            continue
        end
        if tokens[1].signal == IR.Signal.BEGIN_ENUM
            enum_def = enum_def_from_tokens(tokens)
            push!(enum_exprs, generate_enum_expr(enum_def))
        elseif tokens[1].signal == IR.Signal.BEGIN_SET
            set_def = set_def_from_tokens(tokens)
            push!(set_exprs, generate_set_expr(set_def, ir))
        end
    end

    module_quoted = quote
        module $module_name
            using EnumX
            $(enum_exprs...)
            $(set_exprs...)
        end
    end

    return extract_expr_from_quote(module_quoted, :module)
end
