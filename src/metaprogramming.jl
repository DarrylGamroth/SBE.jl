# SBE Runtime Metaprogramming
#
# This file contains the code generation and metaprogramming functionality
# for creating flyweight message wrappers from SBE schemas.

# ============================================================================
# Abstract Base Types - Interface Hierarchy
# ============================================================================

"""
Base abstract type for all SBE message types.
Provides the interface for flyweight message wrappers that operate directly on byte buffers.
"""
abstract type AbstractSbeMessage end

"""
Base abstract type for all SBE field accessors.
Represents individual fields within messages that can be read/written.
"""
abstract type AbstractSbeField end

"""
Base abstract type for all SBE group accessors.
Represents repeating groups within messages with iteration capabilities.
"""
abstract type AbstractSbeGroup end

"""
Base abstract type for all SBE variable-length data accessors.
Represents variable-length data fields like strings and binary data.
"""
abstract type AbstractSbeData end

"""
Base abstract type for SBE encoded type accessors.
Represents primitive types and arrays of primitives with endian conversion.
"""
abstract type AbstractSbeEncodedType <: AbstractSbeField end

"""
Base abstract type for SBE composite type accessors.
Represents composite types that contain multiple sub-fields.
"""
abstract type AbstractSbeCompositeType <: AbstractSbeField end

# ============================================================================
# Interface Functions - To be implemented by concrete types
# ============================================================================

"""
Return the SBE field ID for this field type.
"""
function id end

"""
Return the SBE version when this field was introduced.
"""
function since_version end

"""
Check if this field is present in the given acting version.
"""
function in_acting_version end

"""
Return the byte offset of this field within its parent message.
"""
function encoding_offset end

"""
Return the total number of bytes this field occupies.
"""
function encoding_length end

"""
Return the null/sentinel value for this field type.
"""
function null_value end

"""
Return the minimum valid value for this field type.
"""
function min_value end

"""
Return the maximum valid value for this field type.
"""
function max_value end

# ============================================================================
# Field Type Generation
# ============================================================================

"""
Generate a field type for an encoded SBE field.

Example generated type:
```julia
struct SomeNumbers{T<:AbstractVector{UInt8}} <: AbstractSbeEncodedType
    buffer::T
    offset::Int
end

function SomeNumbers(m::Car)
    return SomeNumbers(m.buffer, m.offset + encoding_offset(SomeNumbers))
end

# Both type and instance versions
id(::Type{<:SomeNumbers}) = UInt16(0x5)
id(::SomeNumbers) = UInt16(0x5)
since_version(::Type{<:SomeNumbers}) = UInt16(0x0)
since_version(::SomeNumbers) = UInt16(0x0)
# ... other attribute functions
```
"""
function generate_encoded_field_type(field_def::Schema.FieldDefinition, message_name::String, schema::Schema.MessageSchema)
    # Use the shared utility to generate in the current module (@__MODULE__ which is SBE)
    return generate_complete_field_type!(@__MODULE__, field_def, message_name, schema)
end
