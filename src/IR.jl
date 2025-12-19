"""
SBE Intermediate Representation (IR) Module

This module defines data structures for the SBE Intermediate Representation,
which is compatible with the reference implementation:
https://github.com/aeron-io/simple-binary-encoding/wiki/Intermediate-Representation

The IR consists of:
1. A Frame header with schema metadata
2. A sequence of Tokens representing the schema structure

This IR can be:
- Serialized to binary format using the SBE IR schema
- Used to generate code in any target language
- Shared between different SBE implementations
"""
module IR

export IRFrame, IRToken, Signal, PrimitiveType, ByteOrder, Presence, IntermediateRepresentation

"""
Signal types in the IR indicating structural elements
"""
@enum Signal::UInt8 begin
    BEGIN_MESSAGE = 1
    END_MESSAGE = 2
    BEGIN_COMPOSITE = 3
    END_COMPOSITE = 4
    BEGIN_FIELD = 5
    END_FIELD = 6
    BEGIN_GROUP = 7
    END_GROUP = 8
    BEGIN_ENUM = 9
    VALID_VALUE = 10
    END_ENUM = 11
    BEGIN_SET = 12
    CHOICE = 13
    END_SET = 14
    BEGIN_VAR_DATA = 15
    END_VAR_DATA = 16
    ENCODING = 17
end

"""
Primitive type codes in the IR
"""
@enum PrimitiveType::UInt8 begin
    PT_NONE = 0
    PT_CHAR = 1
    PT_INT8 = 2
    PT_INT16 = 3
    PT_INT32 = 4
    PT_INT64 = 5
    PT_UINT8 = 6
    PT_UINT16 = 7
    PT_UINT32 = 8
    PT_UINT64 = 9
    PT_FLOAT = 10
    PT_DOUBLE = 11
end

"""
Byte order encoding
"""
@enum ByteOrder::UInt8 begin
    SBE_LITTLE_ENDIAN = 0
    SBE_BIG_ENDIAN = 1
end

"""
Field presence declaration
"""
@enum Presence::UInt8 begin
    SBE_REQUIRED = 0
    SBE_OPTIONAL = 1
    SBE_CONSTANT = 2
end

"""
Frame header for the IR - contains schema metadata
"""
struct IRFrame
    ir_id::Int32
    ir_version::Int32
    schema_version::Int32
    package_name::String
    namespace_name::String
    semantic_version::String
end

"""
Token in the IR - represents a structural element
Each token describes one element of the schema (message, field, group, etc.)
"""
mutable struct IRToken
    token_offset::Int32
    token_size::Int32
    field_id::Int32
    token_version::Int32
    component_token_count::Int32
    signal::Signal
    primitive_type::PrimitiveType
    byte_order::ByteOrder
    presence::Presence
    deprecated::Union{Int32, Nothing}
    name::String
    const_value::String
    min_value::String
    max_value::String
    null_value::String
    character_encoding::String
    epoch::String
    time_unit::String
    semantic_type::String
    description::String
    referenced_name::String
end

"""
Complete IR representation
"""
struct IntermediateRepresentation
    frame::IRFrame
    tokens::Vector{IRToken}
end

"""
    IRToken(; kwargs...)

Constructor for IRToken with default values
"""
function IRToken(;
    token_offset::Int32 = Int32(0),
    token_size::Int32 = Int32(0),
    field_id::Int32 = Int32(-1),
    token_version::Int32 = Int32(0),
    component_token_count::Int32 = Int32(0),
    signal::Signal = ENCODING,
    primitive_type::PrimitiveType = NONE,
    byte_order::ByteOrder = SBE_LITTLE_ENDIAN,
    presence::Presence = SBE_REQUIRED,
    deprecated::Union{Int32, Nothing} = nothing,
    name::String = "",
    const_value::String = "",
    min_value::String = "",
    max_value::String = "",
    null_value::String = "",
    character_encoding::String = "",
    epoch::String = "",
    time_unit::String = "",
    semantic_type::String = "",
    description::String = "",
    referenced_name::String = ""
)
    IRToken(
        token_offset, token_size, field_id, token_version, component_token_count,
        signal, primitive_type, byte_order, presence, deprecated,
        name, const_value, min_value, max_value, null_value,
        character_encoding, epoch, time_unit, semantic_type, description,
        referenced_name
    )
end

end # module IR
