module SBE

# Load dependencies
using EzXML
using MappedArrays
using EnumX

# Import schema definitions
include("Schema.jl")
import .Schema

# Schema parsing and data structures - use qualified names internally
# include("schema.jl")  # Remove this line since we now use Schema.jl

# XML parsing
include("xml_parser.jl")

# Runtime utilities for zero-copy operations  
include("runtime.jl")

# Shared code generation utilities
include("codegen_utils.jl")

# Runtime metaprogramming for dynamic method creation
include("metaprogramming.jl")

# Schema loading and module generation
include("schema_loader.jl")

# Re-export important types and functions that users need
export Schema  # Users can access Schema.MessageDefinition, etc.
export SBECodec, SBEFlyweight, SBEMessage
export load_schema, create_codec_from_schema, create_message, parse_sbe_schema

# Export abstract types for interface
export AbstractSbeMessage, AbstractSbeField, AbstractSbeGroup, AbstractSbeData
export AbstractSbeEncodedType, AbstractSbeCompositeType

# Export interface functions
export id, since_version, in_acting_version, encoding_offset, encoding_length
export null_value, min_value, max_value, value, value!, meta_attribute

# Export utility functions for testing (with underscore prefix they're still internal)
export generate_encoded_field_type

end # module SBE
