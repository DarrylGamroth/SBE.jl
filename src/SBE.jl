module SBE

# Load dependencies
using EnumX
using EzXML
using MappedArrays
using StringViews
using UnsafeArrays

"""
    PositionPointer

Mutable position tracker for SBE message decoding/encoding.
Used to track the current position in a buffer as variable-length
fields are processed.

# Examples
```julia
pos = PositionPointer()
pos[] = 100      # Set position
current = pos[]  # Get position
```
"""
mutable struct PositionPointer
    value::Int64
    PositionPointer() = new(0)
    PositionPointer(v::Integer) = new(Int64(v))
end

Base.getindex(pos::PositionPointer) = pos.value
Base.setindex!(pos::PositionPointer, v) = (pos.value = Int64(v))

# ============================================================================
# SBE Interface Function Declarations
# ============================================================================
# These are declared here BEFORE includes so all included files can use them.
# They are extended by generated types to provide type-specific implementations.

"""
Generic interface function for getting values from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value end

"""
Generic interface function for setting values in SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value! end

"""
Generic interface function for getting meta-attributes from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function meta_attribute end

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

"""
Return the underlying buffer for this SBE object.
"""
function sbe_buffer end

"""
Return the byte offset of this SBE object in the buffer.
"""
function sbe_offset end

"""
Return the acting version of the schema being used.
"""
function sbe_acting_version end

"""
Return the encoded length of this message in bytes.
"""
function sbe_encoded_length end

"""
Return the SBE template ID for this message type.
"""
function sbe_template_id end

"""
Return the SBE schema ID.
"""
function sbe_schema_id end

"""
Return the SBE schema version.
"""
function sbe_schema_version end

"""
Return the block length for this message type.
"""
function sbe_block_length end

"""
Return the acting block length for this message instance.
"""
function sbe_acting_block_length end

"""
Return the position pointer for this message (shared with groups/var data).
"""
function sbe_position_ptr end

"""
Return the current position in the buffer.
"""
function sbe_position end

"""
Set the current position in the buffer.
"""
function sbe_position! end

"""
Rewind the position to the start of variable-length data section.
"""
function sbe_rewind! end

"""
Return the decoded length of this message (requires traversing groups/var data).
"""
function sbe_decoded_length end

"""
Return the semantic type hint for this field.
"""
function sbe_semantic_type end

"""
Return the description of this message type.
"""
function sbe_description end

# ============================================================================
# Include Source Files
# ============================================================================

# Import schema definitions
include("Schema.jl")
import .Schema

# Intermediate Representation (IR)
include("IR.jl")
import .IR

# XML parsing
include("xml_parser.jl")

# Code generation utilities (includes abstract types and runtime support)
include("codegen_utils.jl")

# ============================================================================
# @load_schema Macro - Primary User API
# ============================================================================

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
- Idempotent: calling multiple times with the same schema is safe (uses existing module)

# Notes
Modules are loaded into the `Main` namespace and cannot be redefined without restarting
Julia. If you call `@load_schema` multiple times with the same schema file, the macro
will detect that the module already exists and return its name without regenerating.

# See Also
- `generate(xml_path)` - Generate code as string
"""
macro load_schema(xml_path)
    return quote
        let xml_file = $(esc(xml_path))
            # Parse to get module name
            xml_content = read(xml_file, String)
            schema = SBE.parse_sbe_schema(xml_content)
            # Convert package name to PascalCase (e.g., "composite.elements" -> "CompositeElements")
            package_parts = split(replace(schema.package, "." => "_"), "_")
            module_name = Symbol(join([uppercasefirst(part) for part in package_parts]))
            
            # Check if already exists
            if !isdefined(Main, module_name)
                # Generate and load
                code = SBE.generate(xml_file)
                Base.include_string(Main, code)
            end
            # If already exists, silently return the existing module name
            # (modules cannot be redefined without restarting Julia)
            
            module_name
        end
    end
end

# Re-export important types and functions that users need
export Schema  # Users can access Schema.MessageDefinition, etc.
export SBECodec, SBEFlyweight, SBEMessage
export @load_schema, create_codec_from_schema, create_message, parse_sbe_schema
export generate  # Main code generation API

# Export position pointer type
export PositionPointer

# Export abstract types for interface
export AbstractSbeMessage, AbstractSbeField, AbstractSbeGroup, AbstractSbeData
export AbstractSbeEncodedType, AbstractSbeCompositeType

# Export interface functions
export id, since_version, in_acting_version, encoding_offset, encoding_length
export null_value, min_value, max_value, value, value!, meta_attribute
export sbe_buffer, sbe_offset, sbe_acting_version, sbe_encoded_length
export sbe_template_id, sbe_schema_id, sbe_schema_version, sbe_block_length
export sbe_acting_block_length, sbe_position_ptr, sbe_position, sbe_position!
export sbe_rewind!, sbe_decoded_length, sbe_semantic_type, sbe_description

# Export utility functions
export to_string

# Export utility functions for testing (with underscore prefix they're still internal)
export generate_encoded_field_type

end # module SBE
