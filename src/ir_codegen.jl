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
    literal::String
    description::String
    since_version::Int
    deprecated::Int
end

struct IrSetDef
    name::String
    encoding_type::IR.PrimitiveType.T
    choices::Vector{IrSetChoice}
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
            literal = primitive_value_literal(token.encoding.const_value, encoding_type)
            push!(choices, IrSetChoice(token.name, literal, token.description, token.version, token.deprecated))
        end
    end
    return IrSetDef(begin_token.name, encoding_type, choices)
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
