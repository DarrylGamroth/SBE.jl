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

"""
    @load_schema xml_path

Macro to load an SBE schema at parse time, avoiding world age issues.

This macro generates code at parse time, then uses `include_string()` to load
it into the calling module. Because the `include_string()` happens at parse time,
there are no world age issues when accessing the generated module.

# Arguments
- `xml_path`: Path to the SBE XML schema file (can be a string or expression)

# Returns
The macro expands to code that loads the schema and returns the module name as a Symbol.

# Example
```julia
using SBE

# Load schema at parse time - no world age issues!
module_name = SBE.@load_schema "test/example-schema.xml"
# => :Baseline

# Access the module immediately
Baseline = getfield(Main, module_name)

# Or use directly
buffer = zeros(UInt8, 1024)
car = Main.Baseline.Car.Encoder(buffer, 0)
```

# Advantages
- No world age warnings
- Code is evaluated at parse time
- Clean, simple syntax
- No temporary files

# See Also
- `load_schema(xml_path)` - Function version
- `generate(xml_path)` - Generate code as string
"""
macro load_schema(xml_path)
    return quote
        let xml_file = $(esc(xml_path))
            # Parse to get module name
            xml_content = read(xml_file, String)
            schema = SBE.parse_sbe_schema(xml_content)
            module_name = Symbol(uppercasefirst(schema.package))
            
            # Check if already exists
            if isdefined(Main, module_name)
                @warn "Module $module_name already exists in Main. " *
                      "To regenerate, restart Julia."
            else
                # Generate and load
                code = SBE.generate(xml_file)
                Base.include_string(Main, code)
            end
            
            module_name
        end
    end
end
