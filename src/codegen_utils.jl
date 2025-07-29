# SBE Code Generation Utilities
#
# This file contains shared utilities for generating SBE types and methods
# that are used by both metaprogramming.jl and schema_loader.jl

using MappedArrays

# Global tracking for meta_attribute functions to avoid redefinition warnings
const _GENERATED_META_ATTRIBUTE_FUNCTIONS = Set{Tuple{Module, Symbol}}()

# ============================================================================
# Shared Type Generation Functions
# ============================================================================

"""
Generate attribute functions for a field type in the given module.
This includes id, since_version, encoding_offset, encoding_length, length, and eltype.
"""
function generate_field_attributes!(target_module::Module, field_name::Symbol, field_def::Schema.FieldDefinition, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)
    total_length = sizeof(julia_type) * type_def.length
    
    Core.eval(target_module, quote
        # SBE field attributes
        id(::Type{<:$field_name}) = UInt16($(field_def.id))
        id(::$field_name) = UInt16($(field_def.id))
        since_version(::Type{<:$field_name}) = UInt16($(field_def.since_version))
        since_version(::$field_name) = UInt16($(field_def.since_version))
        
        # Encoding information
        encoding_offset(::Type{<:$field_name}) = $(field_def.offset)
        encoding_offset(::$field_name) = $(field_def.offset)
        encoding_length(::Type{<:$field_name}) = $total_length
        encoding_length(::$field_name) = $total_length
        
        # Array/type information
        Base.length(::Type{<:$field_name}) = $(type_def.length)
        Base.length(::$field_name) = $(type_def.length)
        Base.eltype(::Type{<:$field_name}) = $julia_type
        Base.eltype(::$field_name) = $julia_type
    end)
end

"""
Generate value accessor functions for a field type in the given module.
This includes value() and value!() methods for both single values and arrays.
"""
function generate_value_accessors!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)
    
    if type_def.length == 1
        # Single value accessor
        Core.eval(target_module, quote
            function value(field::$field_name)
                return mappedarray(ltoh, reinterpret($julia_type, view(field.buffer, field.offset+1:field.offset+sizeof($julia_type))))[1]
            end
            
            function value!(field::$field_name, val::$julia_type)
                mapped = mappedarray(ltoh, htol, reinterpret($julia_type, view(field.buffer, field.offset+1:field.offset+sizeof($julia_type))))
                mapped[1] = val
                return field
            end
        end)
    else
        # Array value accessor
        total_bytes = sizeof(julia_type) * type_def.length
        
        Core.eval(target_module, quote
            function value(field::$field_name)
                return mappedarray(ltoh, reinterpret($julia_type, view(field.buffer, field.offset+1:field.offset+$total_bytes)))
            end
            
            function value!(field::$field_name)
                return mappedarray(ltoh, htol, reinterpret($julia_type, view(field.buffer, field.offset+1:field.offset+$total_bytes)))
            end
            
            function value!(field::$field_name, val)
                copyto!(value!(field), val)
                return field
            end
        end)
    end
end

"""
Generate meta attribute function for a field in the given module.
"""
function generate_meta_attribute_function!(target_module::Module, field_name::Symbol, message_symbol::Symbol, field_def::Schema.FieldDefinition)
    # Check if we've already generated this function for this module/message combination
    key = (target_module, message_symbol)
    if key in _GENERATED_META_ATTRIBUTE_FUNCTIONS
        return  # Already generated, skip
    end
    
    # Build the function body based on the actual field definition values
    checks = Expr[]
    
    # Epoch - defaults to "unix" according to SBE spec
    push!(checks, :(meta_attribute === :epoch && return Symbol($(field_def.epoch))))
    
    # Time unit - only add if not nothing
    if field_def.time_unit !== nothing && !isempty(field_def.time_unit)
        push!(checks, :(meta_attribute === :time_unit && return Symbol($(field_def.time_unit))))
    else
        push!(checks, :(meta_attribute === :time_unit && return Symbol("")))
    end
    
    # Semantic type - only add if not nothing
    if field_def.semantic_type !== nothing && !isempty(field_def.semantic_type)
        push!(checks, :(meta_attribute === :semantic_type && return Symbol($(field_def.semantic_type))))
    else
        push!(checks, :(meta_attribute === :semantic_type && return Symbol("")))
    end
    
    # Presence - always present
    push!(checks, :(meta_attribute === :presence && return Symbol($(field_def.presence))))
    
    # Default case
    push!(checks, :(return Symbol("")))
    
    Core.eval(target_module, quote
        function meta_attribute(::$message_symbol, meta_attribute)
            $(checks...)
        end
    end)
    
    # Mark as generated
    push!(_GENERATED_META_ATTRIBUTE_FUNCTIONS, key)
end

"""
Generate value limit functions (null_value, min_value, max_value) for a field type in the given module.
"""
function generate_value_limits!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)
    
    # Null value
    if type_def.null_value !== nothing
        null_val = parse_typed_value(type_def.null_value, julia_type)
        Core.eval(target_module, quote
            null_value(::Type{<:$field_name}) = $null_val
            null_value(::$field_name) = $null_val
        end)
    end
    
    # Min value
    if type_def.min_value !== nothing
        min_val = parse_typed_value(type_def.min_value, julia_type)
        Core.eval(target_module, quote
            min_value(::Type{<:$field_name}) = $min_val
            min_value(::$field_name) = $min_val
        end)
    else
        Core.eval(target_module, quote
            min_value(::Type{<:$field_name}) = typemin($julia_type)
            min_value(::$field_name) = typemin($julia_type)
        end)
    end
    
    # Max value
    if type_def.max_value !== nothing
        max_val = parse_typed_value(type_def.max_value, julia_type)
        Core.eval(target_module, quote
            max_value(::Type{<:$field_name}) = $max_val
            max_value(::$field_name) = $max_val
        end)
    else
        Core.eval(target_module, quote
            max_value(::Type{<:$field_name}) = typemax($julia_type)
            max_value(::$field_name) = typemax($julia_type)
        end)
    end
end

"""
Generate a complete field type in the given module.
This is a convenience function that generates the struct, constructor, and all methods.
"""
function generate_complete_field_type!(target_module::Module, field_def::Schema.FieldDefinition, message_name::String, schema::Schema.MessageSchema)
    field_name = Symbol(to_pascal_case(field_def.name))
    message_symbol = Symbol(message_name)
    
    # Get the type definition
    type_def = find_type_by_name(schema, field_def.type_ref)
    if type_def === nothing || !(type_def isa Schema.EncodedType)
        return nothing
    end
    
    # Generate the field type struct
    Core.eval(target_module, quote
        struct $field_name{T<:AbstractVector{UInt8}} <: AbstractSbeEncodedType
            buffer::T
            offset::Int
        end
    end)
    
    # Generate constructor
    Core.eval(target_module, quote
        function $field_name(m::$message_symbol)
            field_offset = encoding_offset($field_name)
            return $field_name(m.buffer, m.offset + field_offset)
        end
    end)
    
    # Generate all the methods
    generate_field_attributes!(target_module, field_name, field_def, type_def)
    generate_value_accessors!(target_module, field_name, type_def)
    
    # Generate meta_attribute function (only once per message type)
    generate_meta_attribute_function!(target_module, field_name, message_symbol, field_def)
    
    generate_value_limits!(target_module, field_name, type_def)
    
    return field_name
end

# ============================================================================
# Utility Functions
# ============================================================================

"""
Convert snake_case to PascalCase for type names.
"""
function to_pascal_case(name::String)
    parts = split(name, '_')
    return join([uppercasefirst(part) for part in parts])
end

"""
Convert SBE primitive type name to Julia type.
"""
function to_julia_type(primitive_type::String)
    type_map = Dict(
        "char" => UInt8,
        "int8" => Int8,
        "uint8" => UInt8,
        "int16" => Int16,
        "uint16" => UInt16,
        "int32" => Int32,
        "uint32" => UInt32,
        "int64" => Int64,
        "uint64" => UInt64,
        "float" => Float32,
        "double" => Float64
    )
    
    return get(type_map, primitive_type, UInt8)
end

"""
Parse a typed value from string representation.
"""
function parse_typed_value(value_str::String, julia_type::Type)
    try
        return parse(julia_type, value_str)
    catch
        # Fallback for special values
        if julia_type <: Unsigned
            return typemax(julia_type)
        else
            return zero(julia_type)
        end
    end
end

"""
Find a type definition by name in the schema.
"""
function find_type_by_name(schema::Schema.MessageSchema, type_name::String)
    for type_def in schema.types
        if type_def.name == type_name
            return type_def
        end
    end
    return nothing
end
