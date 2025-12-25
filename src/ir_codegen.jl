"""
IR-based code generation utilities.

These helpers are shared by the IR code generator as it is ported from the Java reference.
"""

function primitive_value_literal(value::IR.PrimitiveValue, primitive_type::IR.PrimitiveType.T)
    if value.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        return repr(value.value)
    elseif value.representation == IR.PrimitiveValueRepresentation.DOUBLE
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

