"""
SBE Schema Data Structures

This module defines the data structures that represent parsed SBE schemas.
"""
module Schema

"""
Base type for all SBE type definitions
"""
abstract type AbstractTypeDefinition end

"""
Valid value for an enumeration
"""
struct ValidValue
    name::String
    value::String
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Choice within a set (bitset)
"""
struct Choice
    name::String
    bit_position::Int
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Encoded data type (primitive or array of primitives)
"""
struct EncodedType <: AbstractTypeDefinition
    name::String
    primitive_type::String
    length::Int
    null_value::Union{String, Nothing}
    min_value::Union{String, Nothing}
    max_value::Union{String, Nothing}
    character_encoding::Union{String, Nothing}
    offset::Union{Int, Nothing}
    presence::String
    constant_value::Union{String, Nothing}  # For presence="constant", the constant value
    semantic_type::Union{String, Nothing}
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Composite data type (composed of multiple parts)
"""
struct CompositeType <: AbstractTypeDefinition
    name::String
    members::Vector{AbstractTypeDefinition}
    offset::Union{Int, Nothing}
    semantic_type::Union{String, Nothing}
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Enumeration type
"""
struct EnumType <: AbstractTypeDefinition
    name::String
    encoding_type::String
    values::Vector{ValidValue}
    offset::Union{Int, Nothing}
    semantic_type::Union{String, Nothing}
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Set type (multi-value choice encoded as bitset)
"""
struct SetType <: AbstractTypeDefinition
    name::String
    encoding_type::String
    choices::Vector{Choice}
    offset::Union{Int, Nothing}
    semantic_type::Union{String, Nothing}
    description::String
    since_version::Int
    deprecated::Union{String, Nothing}
end

"""
Reference to an existing type
"""
struct RefType <: AbstractTypeDefinition
    name::String
    type_ref::String
    offset::Int
end

"""
Field definition within a message or group
"""
struct FieldDefinition
    name::String
    id::UInt16
    type_ref::String
    offset::Int
    description::String
    since_version::Int
    presence::String
    value_ref::Union{String, Nothing}
    epoch::String
    time_unit::Union{String, Nothing}
    semantic_type::Union{String, Nothing}
    deprecated::Union{String, Nothing}
end

"""
Variable-length data definition
"""
struct VarDataDefinition
    name::String
    id::UInt16
    type_ref::String
    description::String
    since_version::Int
    character_encoding::Union{String, Nothing}
    semantic_type::Union{String, Nothing}
    deprecated::Union{String, Nothing}
end

"""
Group definition (repeating group)
"""
struct GroupDefinition
    name::String
    id::UInt16
    block_length::Union{String, Nothing}
    dimension_type::String
    description::String
    since_version::Int
    semantic_type::Union{String, Nothing}
    deprecated::Union{String, Nothing}
    fields::Vector{FieldDefinition}
    groups::Vector{GroupDefinition}
    var_data::Vector{VarDataDefinition}
end

"""
Message definition
"""
struct MessageDefinition
    name::String
    id::UInt16
    block_length::Union{String, Nothing}
    description::String
    since_version::Int
    semantic_type::Union{String, Nothing}
    deprecated::Union{String, Nothing}
    fields::Vector{FieldDefinition}
    groups::Vector{GroupDefinition}
    var_data::Vector{VarDataDefinition}
end

"""
Message schema containing all type definitions and message definitions
"""
struct MessageSchema
    id::UInt16
    version::UInt16
    semantic_version::String
    package::String
    byte_order::String
    header_type::String
    description::String
    types::Vector{AbstractTypeDefinition}
    messages::Vector{MessageDefinition}
end

# Utility functions for working with schemas

"""
    get_type_by_name(schema::MessageSchema, name::String) -> Union{TypeDefinition, Nothing}

Find a type definition by name in the schema.
"""
function get_type_by_name(schema::MessageSchema, name::String)
    for type_def in schema.types
        if get_type_name(type_def) == name
            return type_def
        end
    end
    return nothing
end

"""
    get_type_name(type_def::TypeDefinition) -> String

Get the name of a type definition.
"""
get_type_name(type_def::EncodedType) = type_def.name
get_type_name(type_def::CompositeType) = type_def.name
get_type_name(type_def::EnumType) = type_def.name
get_type_name(type_def::SetType) = type_def.name
get_type_name(type_def::RefType) = type_def.name

"""
    is_primitive_type(type_name::String) -> Bool

Check if a type name refers to a primitive SBE type.
"""
function is_primitive_type(type_name::String)
    return type_name in [
        "char", "int8", "int16", "int32", "int64",
        "uint8", "uint16", "uint32", "uint64",
        "float", "double"
    ]
end

"""
    julia_type_name(primitive_type::String) -> String

Convert SBE primitive type to Julia type name.
"""
function julia_type_name(primitive_type::String)
    mapping = Dict(
        "char" => "UInt8",
        "int8" => "Int8",
        "int16" => "Int16", 
        "int32" => "Int32",
        "int64" => "Int64",
        "uint8" => "UInt8",
        "uint16" => "UInt16",
        "uint32" => "UInt32", 
        "uint64" => "UInt64",
        "float" => "Float32",
        "double" => "Float64"
    )
    return get(mapping, primitive_type, primitive_type)
end

"""
    format_struct_name(name::String) -> String

Format a name as a Julia struct name (PascalCase).
"""
function format_struct_name(name::String)
    # Convert to PascalCase
    parts = split(name, r"[_\-]")
    return join([uppercasefirst(part) for part in parts])
end

"""
    format_property_name(name::String) -> String

Format a name as a Julia property name (camelCase).
"""
function format_property_name(name::String)
    # Convert to camelCase
    parts = split(name, r"[_\-]")
    if length(parts) == 1
        return lowercase(name)
    end
    return lowercase(parts[1]) * join([uppercasefirst(part) for part in parts[2:end]])
end

end # module Schema
