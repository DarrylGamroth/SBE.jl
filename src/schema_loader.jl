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
Baseline = SBE.load_schema("test/example-schema.xml")

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
    Core.eval(generated_module, :(import SBE: meta_attribute, ltoh, htol))
    # Import the common SBE API functions (defined in metaprogramming.jl)
    Core.eval(generated_module, :(import SBE: sbe_buffer, sbe_offset, sbe_position_ptr, sbe_position, sbe_position!))
    Core.eval(generated_module, :(import SBE: sbe_rewind!, sbe_encoded_length, sbe_acting_block_length))
    # Note: value and value! are generic interface functions defined locally per type
    Core.eval(generated_module, :(import Base: length, eltype))
    Core.eval(generated_module, :(using MappedArrays: mappedarray))
    
    # Add utility functions for encoding/decoding (schema-specific)
    Core.eval(generated_module, quote
        @inline function encode_le(::Type{T}, buffer, offset, value) where {T}
            @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = htol(value)
        end
        
        @inline function decode_le(::Type{T}, buffer, offset) where {T}
            @inbounds ltoh(reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[])
        end
    end)
    
    # Store the schema for reference
    Core.eval(generated_module, :(const SCHEMA = $schema))
    
    # Generate all composite types first (needed for MessageHeader)
    for type_def in schema.types
        if type_def isa Schema.CompositeType
            generateComposite!(generated_module, type_def, schema)
        end
    end
    
    # Generate all enum types
    for type_def in schema.types
        if type_def isa Schema.EnumType
            generateEnum!(generated_module, type_def, schema)
        end
    end
    
    # Generate all set types
    for type_def in schema.types
        if type_def isa Schema.SetType
            generateChoiceSet!(generated_module, type_def, schema)
        end
    end
    
    # Ensure the header type exists before generating messages
    header_type_name = SBE.to_pascal_case(schema.header_type)
    
    if !isdefined(generated_module, Symbol(header_type_name))
        error("Header type '$(schema.header_type)' ($(header_type_name) module) not found in schema types")
    end
    
    # Verify the header module has Decoder type
    header_module = getfield(generated_module, Symbol(header_type_name))
    if !isdefined(header_module, :Decoder)
        error("Header module '$(header_type_name)' does not have Decoder type")
    end
    
    # Generate all message types with complete interface
    for message in schema.messages
        generateMessageFlyweightStruct!(generated_module, message, schema)
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
    message_name = Symbol(SBE.to_pascal_case(message.name))
    decoder_name = Symbol(string(message_name, "Decoder"))
    encoder_name = Symbol(string(message_name, "Encoder"))
    
    # Create a comprehensive meta_attribute function for all message types
    Core.eval(target_module, quote
        # For abstract base type
        function meta_attribute(::$message_name, attribute)
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
        
        # For decoder type
        function meta_attribute(::$decoder_name, attribute)
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
        
        # For encoder type
        function meta_attribute(::$encoder_name, attribute)
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
