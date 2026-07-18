# SBE.jl Usage Guide

This guide documents the public API and common workflows for SBE.jl.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/DarrylGamroth/SBE.jl")
```

## Quick Start

```julia
using SBE

baseline_name = @load_schema "path/to/example-schema.xml"
Baseline = getfield(@__MODULE__, baseline_name)

buffer = zeros(UInt8, 512)
car = Baseline.Car.Encoder(buffer)

Baseline.Car.serialNumber!(car, 12345)
Baseline.Car.modelYear!(car, 2024)
Baseline.Car.available!(car, Baseline.BooleanType.T)
Baseline.Car.code!(car, Baseline.Model.A)
Baseline.Car.vehicleCode!(car, "ABC123")

encoded_len = SBE.sbe_encoded_length(car)

dec = Baseline.Car.Decoder(buffer)
serial = Baseline.Car.serialNumber(dec)
```

## Schema Loading

`@load_schema` generates codecs during macro expansion and emits their definitions
as ordinary top-level Julia syntax.

```julia
using SBE

baseline_name = @load_schema "path/to/example-schema.xml"
Baseline = getfield(@__MODULE__, baseline_name)
```

The macro must be used at top level, and its path and keyword values must be
literals. A relative path in a source file is resolved relative to that file; at
the REPL it is resolved relative to the working directory. The generated module is
defined in the calling module, and the macro returns its name as a `Symbol`.

Generated schema modules, messages, codec types, fields, groups, enums, and set
choices carry schema-derived docstrings. Use Julia help, for example
`?Baseline.Car.manufacturer`, to inspect wire metadata and cursor behavior.

Julia methods are tagged with a world age. Code already executing cannot normally
dispatch to methods installed dynamically with `include_string` or `eval`. By
emitting the generated module as a top-level form, `@load_schema` ensures that
functions defined afterward are compiled in a world that already contains the
codec methods. If a schema path is known only at runtime, use `generate` and load
the resulting file at top level, or use `Base.invokelatest` at the transition into
the dynamically loaded API.

## File-Based Code Generation

For production or precompilation, generate code to a file and include it:

```julia
using SBE

SBE.generate("path/to/schema.xml", "generated/Baseline.jl")

include("generated/Baseline.jl")
using .Baseline
```

Validation can be configured during parsing and generation:

```julia
SBE.generate("path/to/schema.xml", "generated/Baseline.jl"; warnings_fatal=true)
SBE.parse_xml_schema(read("path/to/schema.xml", String); suppress_warnings=true)
baseline_name = @load_schema("path/to/schema.xml"; warnings_fatal=true)
Baseline = getfield(Main, baseline_name)
```

Use `parse_xml_schema_file("path/to/schema.xml")` when a schema contains relative
XML XInclude elements. File-based parsing, `generate`, `generate_ir_file`, and
`@load_schema` resolve local XML includes by default. The string-only
`parse_xml_schema` API has no base path and therefore does not resolve them.

### Validation Matrix

Errors (always fatal):
- duplicate message ids or names
- duplicate field ids or names within a message/group
- field/group/data ordering violations
- invalid or missing types, composites, or refs
- invalid offsets or insufficient blockLength
- enum/set encodingType length not equal to 1
- malformed valueRef or missing valueRef targets
- enum nullValue collisions or out-of-range enum values
- invalid group size or varData composites
- maxValue larger than the primitive type allows for group/varData length fields
- missing or greater-than-`typemax(Int32)` maxValue for `uint32` group dimensions
- mismatched semanticType between field and its type

Warnings (fatal only when `warnings_fatal=true`):
- invalid identifiers for C/C++/Java/Go/C#/Julia
- duplicate enum validValue names or values
- duplicate set choice names or values
- nonstandard header field types (e.g., header fields not `uint16`)
- nonstandard `blockLength`/`numInGroup`/`length` primitive widths
- `nullValue` provided for non-optional encodings

## Encoding

Encoders write directly into a `Vector{UInt8}`.

```julia
buffer = zeros(UInt8, 512)
car = Baseline.Car.Encoder(buffer)

Baseline.Car.serialNumber!(car, 12345)
Baseline.Car.modelYear!(car, 2024)
Baseline.Car.available!(car, Baseline.BooleanType.T)
Baseline.Car.code!(car, Baseline.Model.A)

engine = Baseline.Car.engine(car)
Baseline.Engine.capacity!(engine, 2000)
Baseline.Engine.numCylinders!(engine, 4)

extras = Baseline.Car.extras(car)
Baseline.OptionalExtras.cruiseControl!(extras, true)
Baseline.OptionalExtras.sunRoof!(extras, false)
```

Value setters return their encoder, which permits optional chaining or simple
identity checks. A no-value fixed-array setter such as `someNumbers!(car)` still
returns the writable zero-copy array view.

Fixed-length text setters reject values whose encoded byte length exceeds the
schema length rather than truncating them. ASCII fields reject non-ASCII strings;
UTF-8 fields copy Julia string code units directly.

### Repeating Groups

```julia
fuel = Baseline.Car.fuelFigures!(car, 2)
fig = Baseline.Car.FuelFigures.next!(fuel)
Baseline.Car.FuelFigures.speed!(fig, 30)
Baseline.Car.FuelFigures.mpg!(fig, 35.9f0)

fig = Baseline.Car.FuelFigures.next!(fuel)
Baseline.Car.FuelFigures.speed!(fig, 60)
Baseline.Car.FuelFigures.mpg!(fig, 42.0f0)
```

Group iteration is deliberately stateful and zero-allocation: every iteration
returns the same flyweight object repositioned on the next entry. Consume an
entry before advancing and do not collect or retain entries as independent values.

To reuse a group decoder without allocations, call the accessor with an existing decoder:

```julia
car_dec = Baseline.Car.Decoder(typeof(buffer))
Baseline.Car.wrap!(car_dec, buffer, 0)
fuel_dec = Baseline.Car.fuelFigures(car_dec)
for fig in fuel_dec
    Baseline.Car.FuelFigures.speed(fig)
end

Baseline.Car.fuelFigures!(car_dec, fuel_dec)  # reset and reuse
```

### Variable-Length Data

Var-data accessors operate on the message position pointer. Reading and writing
advance the pointer, so groups and variable-length fields must be consumed in
schema order. Calling the same accessor twice consumes two consecutive fields.

```julia
Baseline.Car.manufacturer!(car, "Honda")
Baseline.Car.model!(car, "Civic")
Baseline.Car.activationCode!(car, "ABCD1234")
```

## Decoding

Decoders read directly from the same buffer.

```julia
dec = Baseline.Car.Decoder(buffer)
serial = Baseline.Car.serialNumber(dec)
year = Baseline.Car.modelYear(dec)

engine = Baseline.Car.engine(dec)
capacity = Baseline.Engine.capacity(engine)
```

`Encoder(buffer, offset=0)` writes the message header, and
`Decoder(buffer, offset=0)` validates and consumes it. To reuse flyweights without
constructing another position pointer, retain the lower-level workflow:

```julia
enc = Baseline.Car.Encoder(typeof(buffer))
Baseline.Car.wrap_and_apply_header!(enc, buffer)

dec = Baseline.Car.Decoder(typeof(buffer))
Baseline.Car.wrap!(dec, buffer)
```

### String Handling

Fixed-length strings return `StringView` to avoid allocations. Convert with `String(...)`.

```julia
code_view = Baseline.Car.vehicleCode(dec)
code = String(code_view)
```

Variable-length data returns a view of `UInt8` bytes, with typed helpers:

```julia
bytes = Baseline.Car.manufacturer(dec)
text = Baseline.Car.manufacturer(dec, String)
```

## Message Headers

Encoders/decoders accept optional headers. This is useful when framing messages.

```julia
header = Baseline.MessageHeader.Encoder(buffer, 0)
car = Baseline.Car.Encoder(buffer, 0; header=header)

dec_header = Baseline.MessageHeader.Decoder(buffer, 0)
dec = Baseline.Car.Decoder(buffer, 0; header=dec_header)
```

## Positions and Lengths

SBE.jl uses a shared position pointer for variable-length data. Messages own their
position pointer internally; groups share the parent message pointer when iterating.

```julia
pos = SBE.sbe_position(car)
SBE.sbe_position!(car, pos)
len = SBE.sbe_encoded_length(car)
decoded_len = SBE.sbe_decoded_length(dec)
```

## Versioning

The generated code respects `sinceVersion` and `deprecated` attributes. You can
override acting version and block length on decoders:

```julia
dec = Baseline.Car.Decoder(typeof(buffer))
Baseline.Car.wrap!(dec, buffer, 0, UInt16(45), UInt16(0))
```

## Endianness

Endianness is taken from the schema. Primitive encoders/decoders respect the byte order
declared in XML.

## IR Utilities

SBE.jl exposes a public IR API (mirroring the reference implementation) for tooling
and code generation. It follows package semantic versioning but is not a separate,
independently versioned stability promise:

```julia
ir = SBE.generate_ir_file("schema.xml")
msgs = SBE.IR.ir_messages(ir)
first_msg = SBE.IR.ir_message(ir, 1)
types = SBE.IR.ir_types(ir)
schema_id = SBE.IR.ir_id(ir)
```

You can also build IR from XML content directly:

```julia
ir = SBE.generate_ir_xml(read("schema.xml", String))
```

SBE.jl can decode `.sbeir` files for tooling and debugging:

```julia
ir = SBE.decode_ir("schema.sbeir")
```

The decoded IR can drive the same Julia code generator used for XML schemas:

```julia
# Return Julia source.
code = SBE.generate_from_ir("schema.sbeir"; module_name=:MySchema)

# Write an includable Julia source file.
SBE.generate_from_ir(
    "schema.sbeir",
    "generated/MySchema.jl";
    module_name=:MySchema,
)

# Expansion-time loading from a literal path.
schema_name = SBE.@load_sbeir("schema.sbeir"; module_name=:MySchema)
MySchema = getfield(@__MODULE__, schema_name)
```

`generate_from_ir` also accepts an `SBE.IR.Ir` value as its first argument.
`@load_sbeir` follows the same top-level, literal-path, caller-module, and
world-age rules as `@load_schema`. SBE.jl reads Java-compatible `.sbeir` files but
does not currently write them.

## Testing and Java Fixtures

Java fixtures are generated with:

```bash
julia --project=. scripts/generate_java_fixtures.jl
```

`Pkg.test()` uses the committed binary fixtures and does not require Java or network
access. Run the generator explicitly when updating the schemas, SBE tool version, or
fixture-generation code.

The CI compatibility gate additionally checks the pinned SbeTool test resources,
schema acceptance, decoded IR, and the upstream relative-XInclude case. See
`docs/SBETOOL_COMPATIBILITY.md` for the evidence ledger and support boundaries.
