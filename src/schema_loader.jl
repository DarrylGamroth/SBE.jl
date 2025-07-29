# Schema Loading and Module Generation
#
# This file contains the functionality for loading SBE schemas and generating
# schema-specific modules with all the message and field types.

"""
Load an SBE schema and generate a module containing all the types and methods.

The generated module will be named after the schema package (capitalized).
For example, a schema with package="baseline" will create a module named `Baseline`.

# Arguments
- `xml_file::String`: Path to the SBE XML schema file

# Returns
- The generated module containing all message and field types

# Example
```julia
# Load the baseline schema
Baseline = SBE.load_schema("example-schema.xml")

# Use the generated types
buffer = zeros(UInt8, 1024)
car = Baseline.Car(buffer, 0)
model_year = Baseline.ModelYear(car)

# Interface functions work seamlessly
SBE.id(model_year)
SBE.value(model_year)
```
"""
function load_schema(xml_file::String)
    # Parse the schema
    xml_content = read(xml_file, String)
    schema = parse_sbe_schema(xml_content)
    
    # Create module name from package (capitalize first letter)
    module_name = Symbol(uppercasefirst(schema.package))
    
    # Check if module already exists, if so return it
    if isdefined(@__MODULE__, module_name)
        return getfield(@__MODULE__, module_name)
    end
    
    # Create the module at top level using Core.eval
    Core.eval(@__MODULE__, :(module $module_name end))
    
    # Get reference to the new module
    generated_module = getfield(@__MODULE__, module_name)
    
    # Import necessary types and functions into the module
    Core.eval(generated_module, :(using SBE: AbstractSbeMessage, AbstractSbeField, AbstractSbeEncodedType, AbstractSbeCompositeType))
    Core.eval(generated_module, :(import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value))
    Core.eval(generated_module, :(import SBE: value, value!, meta_attribute, ltoh, htol))
    Core.eval(generated_module, :(import Base: length, eltype))
    Core.eval(generated_module, :(using MappedArrays: mappedarray))
    
    # Store the schema for reference
    Core.eval(generated_module, :(const SCHEMA = $schema))
    
    # Generate all message types
    for message in schema.messages
        generate_message_type(generated_module, message)
    end
    
    # Generate all field types for each message
    for message in schema.messages
        for field in message.fields
            # Skip non-encoded types for now
            type_def = find_type_by_name(schema, field.type_ref)
            if type_def !== nothing && type_def isa Schema.EncodedType
                generate_field_type(generated_module, field, message.name, schema)
            end
        end
        
        # Generate meta_attribute function once per message
        generate_message_meta_attribute_function!(generated_module, message, schema)
    end
    
    # Export all generated types
    exports = generate_export_list(schema)
    if !isempty(exports)
        Core.eval(generated_module, :(export $(exports...)))
    end
    
    return generated_module
end

"""
Generate a message type definition in the given module.
"""
function generate_message_type(target_module::Module, message::Schema.MessageDefinition)
    message_name = Symbol(message.name)
    
    Core.eval(target_module, quote
        struct $message_name{T<:AbstractVector{UInt8}} <: AbstractSbeMessage
            buffer::T
            offset::Int
        end
    end)
end

"""
Generate a field type definition in the given module.
"""
function generate_field_type(target_module::Module, field_def::Schema.FieldDefinition, message_name::String, schema::Schema.MessageSchema)
    # Use the shared utility function but skip meta_attribute generation
    # We'll generate that once per message instead
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
    
    # Generate all the methods except meta_attribute
    generate_field_attributes!(target_module, field_name, field_def, type_def)
    generate_value_accessors!(target_module, field_name, type_def)
    generate_value_limits!(target_module, field_name, type_def)
    
    return field_name
end

"""
Generate meta_attribute function for a message that handles all its fields.
"""
function generate_message_meta_attribute_function!(target_module::Module, message::Schema.MessageDefinition, schema::Schema.MessageSchema)
    message_symbol = Symbol(message.name)
    
    # Create a comprehensive meta_attribute function that returns general message attributes
    Core.eval(target_module, quote
        function meta_attribute(::$message_symbol, attribute)
            # For now, return basic defaults
            if attribute === :presence
                return Symbol("required")
            elseif attribute === :epoch
                return Symbol("unix")  # Default epoch for time-related fields
            elseif attribute === :time_unit
                return Symbol("")  # Most fields don't have time units
            elseif attribute === :semantic_type
                return Symbol("")  # Most fields don't have semantic types
            else
                return Symbol("")  # Unknown attributes return empty
            end
        end
    end)
end

"""
Generate export list for all generated types.
"""
function generate_export_list(schema::Schema.MessageSchema)
    exports = Symbol[]
    
    # Export all message types
    for message in schema.messages
        push!(exports, Symbol(message.name))
    end
    
    # Export all field types
    for message in schema.messages
        for field in message.fields
            type_def = find_type_by_name(schema, field.type_ref)
            if type_def !== nothing && type_def isa Schema.EncodedType
                field_name = Symbol(to_pascal_case(field.name))
                push!(exports, field_name)
            end
        end
    end
    
    return exports
end
