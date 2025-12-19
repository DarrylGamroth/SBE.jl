# Intermediate Representation (IR) Implementation

## Overview

This document describes the Intermediate Representation (IR) implementation in SBE.jl, which provides compatibility with the reference SBE implementation.

## Architecture

The code generation pipeline now follows:

```
XML Schema → Schema (AST) → IR → Julia Code
     ↓            ↓          ↓         ↓
 parse_sbe  Schema types  IR types  generate()
```

The IR is the **canonical intermediate representation** in this pipeline.

### Step 1: XML → Schema
The XML parser (`xml_parser.jl`) parses the SBE XML schema into a structured `Schema.MessageSchema` representation. This is an Abstract Syntax Tree (AST) that represents the schema structure.

### Step 2: Schema → IR
The schema-to-IR converter (`schema_to_ir.jl`) transforms the Schema AST into an Intermediate Representation compatible with the reference implementation. The IR consists of:

- **IRFrame**: Header with schema metadata (id, version, package name, etc.)
- **IRToken[]**: Sequence of tokens representing the schema structure

Each token represents a structural element with signal types like:
- `BEGIN_MESSAGE` / `END_MESSAGE` - Message boundaries
- `BEGIN_FIELD` / `END_FIELD` - Field boundaries  
- `BEGIN_GROUP` / `END_GROUP` - Repeating group boundaries
- `BEGIN_COMPOSITE` / `END_COMPOSITE` - Composite type boundaries
- `BEGIN_ENUM` / `END_ENUM` - Enumeration boundaries
- `BEGIN_SET` / `END_SET` - Bitset boundaries
- `BEGIN_VAR_DATA` / `END_VAR_DATA` - Variable-length data boundaries
- `ENCODING` - Primitive type encoding
- `VALID_VALUE` - Enumeration value
- `CHOICE` - Bitset choice

### Step 3: IR → Julia Code
Julia code is generated from the IR. The IR is the **canonical intermediate representation**.

The `generate_from_ir()` function takes IR and produces Julia code.

**Current Implementation Status:**
The function currently uses Schema as a temporary bridge to the existing code generator:
1. **IR → Schema** (temporary): IR tokens are parsed to reconstruct Schema
2. **Schema → Julia AST**: Schema is used to generate Julia expressions  
3. **Julia AST → Code String**: Expressions are converted to code

**Correct Implementation (TODO):**
Direct IR token processing without Schema:
1. **IR Tokens → Julia AST**: Process tokens directly to generate expressions
2. **Julia AST → Code String**: Convert to code

The temporary bridge approach was chosen for pragmatism - it reuses the robust existing code generator (~3000 lines) while establishing the correct pipeline. The Schema reconstruction is an internal implementation detail not exposed in the public API.

## API

### For Users

```julia
using SBE

# Generate Julia code (traditional workflow - now includes IR step internally)
code = SBE.generate("schema.xml")

# Generate and inspect IR
ir = SBE.generate_ir("schema.xml")
println("Package: ", ir.frame.package_name)
println("Number of tokens: ", length(ir.tokens))

# Convert Schema to IR directly
schema = SBE.parse_sbe_schema(read("schema.xml", String))
ir = SBE.schema_to_ir(schema)
```

### For Developers

The IR module is available for inspection:

```julia
using SBE

# Access IR types
SBE.IR.Signal       # Enum for token signal types
SBE.IR.PrimitiveType  # Enum for primitive types
SBE.IR.ByteOrder    # Enum for byte order
SBE.IR.Presence     # Enum for field presence

# Create IR tokens programmatically
token = SBE.IR.IRToken(
    signal = SBE.IR.BEGIN_MESSAGE,
    name = "MyMessage",
    field_id = Int32(1)
)
```

## IR Structure

### IRFrame

Contains schema-level metadata:

```julia
struct IRFrame
    ir_id::Int32                 # Schema ID
    ir_version::Int32            # IR format version
    schema_version::Int32        # Schema version
    package_name::String         # Package/namespace
    namespace_name::String       # Additional namespace
    semantic_version::String     # Semantic version string
end
```

### IRToken

Represents a structural element in the schema:

```julia
struct IRToken
    token_offset::Int32          # Byte offset in message
    token_size::Int32            # Size in bytes
    field_id::Int32              # Field/message ID
    token_version::Int32         # Version introduced
    component_token_count::Int32 # Number of child tokens
    signal::Signal               # Token type (BEGIN_MESSAGE, etc.)
    primitive_type::PrimitiveType # Primitive type if applicable
    byte_order::ByteOrder        # Endianness
    presence::Presence           # Required/optional/constant
    deprecated::Union{Int32, Nothing}  # Deprecation version
    name::String                 # Element name
    const_value::String          # Constant value
    min_value::String            # Min value constraint
    max_value::String            # Max value constraint
    null_value::String           # Null/sentinel value
    character_encoding::String   # Character encoding
    epoch::String                # Time epoch
    time_unit::String            # Time unit
    semantic_type::String        # Semantic type hint
    description::String          # Documentation
    referenced_name::String      # Referenced type name
end
```

## Token Sequence Example

For a simple message with one field:

```
BEGIN_MESSAGE (name="Car", field_id=1)
  BEGIN_FIELD (name="serialNumber", field_id=1)
    ENCODING (primitive_type=UINT64)
  END_FIELD
END_MESSAGE
```

For a composite type:

```
BEGIN_COMPOSITE (name="Engine")
  ENCODING (name="capacity", primitive_type=UINT16)
  ENCODING (name="numCylinders", primitive_type=UINT8)
END_COMPOSITE
```

## Compatibility

The IR format is designed to be binary-compatible with the reference SBE implementation:

1. **Token Structure**: Matches the TokenCodec message in sbe-ir.xml
2. **Frame Structure**: Matches the FrameCodec message in sbe-ir.xml  
3. **Signal Types**: Match the SignalCodec enum values
4. **Primitive Types**: Match the PrimitiveTypeCodec enum values

This allows:
- Serializing IR to binary format using the provided SBE IR codecs
- Exchanging IR with other SBE implementations
- Validating compatibility with the reference implementation

## Testing

Tests are provided in `test/test_ir_generation.jl`:

```julia
# Run IR generation tests
using Test
include("test/test_ir_generation.jl")
```

Tests verify:
- IR frame header generation
- Token generation for all schema elements
- Token structure validation (matching BEGIN/END pairs)
- Primitive type and presence mapping
- Cross-schema compatibility

## Future Enhancements

1. **Direct IR → Julia Code Generation** (HIGH PRIORITY)
   - Implement true token-based code generator
   - Process IR tokens directly to Julia AST without Schema bridge
   - This is the correct implementation per reference SBE architecture
   - Currently using Schema bridge temporarily for pragmatism

2. **IR Serialization**: Add functions to serialize IR to binary format using the SBE IR schema
3. **IR Deserialization**: Add functions to deserialize IR from binary format
4. **IR Comparison**: Tools to compare IR with reference implementation output
5. **IR Optimization**: Detect and optimize IR patterns

## References

- [SBE Intermediate Representation Wiki](https://github.com/aeron-io/simple-binary-encoding/wiki/Intermediate-Representation)
- [SBE IR Schema](https://github.com/aeron-io/simple-binary-encoding/blob/master/sbe-tool/src/main/resources/sbe-ir.xml)
- [Reference Implementation](https://github.com/aeron-io/simple-binary-encoding)
