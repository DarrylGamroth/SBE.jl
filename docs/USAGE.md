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

Baseline = @load_schema "path/to/example-schema.xml"

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

SBE.jl uses a macro to load schemas at parse time. This avoids world-age issues.

```julia
using SBE

Baseline = @load_schema "path/to/example-schema.xml"
```

The macro returns a module that contains all generated types and functions.

## File-Based Code Generation

For production or precompilation, generate code to a file and include it:

```julia
using SBE

SBE.generate("path/to/schema.xml", "generated/Baseline.jl")

include("generated/Baseline.jl")
using .Baseline
```

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

### Variable-Length Data

Var-data accessors operate on the message position pointer. Writing advances the pointer.

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

SBE.jl uses a shared position pointer for variable-length data:

```julia
pos = SBE.sbe_position(car)
SBE.sbe_position!(car, pos)
len = SBE.sbe_encoded_length(car)
decoded_len = SBE.sbe_decoded_length(dec)
```

### Reusing PositionPointer

Use a shared `PositionPointer` to avoid allocating a new pointer for each encoder/decoder.

```julia
buffer = zeros(UInt8, 512)
pos = SBE.PositionPointer(0)

enc = Baseline.Car.Encoder(buffer, 0, pos)
Baseline.Car.serialNumber!(enc, 12345)
Baseline.Car.modelYear!(enc, 2024)

dec = Baseline.Car.Decoder(buffer, 0, pos)
serial = Baseline.Car.serialNumber(dec)
year = Baseline.Car.modelYear(dec)
```

## Versioning

The generated code respects `sinceVersion` and `deprecated` attributes. You can
override acting version and block length on decoders:

```julia
dec = Baseline.Car.Decoder(buffer, 0, SBE.PositionPointer(0), UInt16(45), UInt16(0))
```

## Endianness

Endianness is taken from the schema. Primitive encoders/decoders respect the byte order
declared in XML.

## IR Utilities

SBE.jl can decode `.sbeir` files for tooling and debugging:

```julia
ir = SBE.decode_ir("schema.sbeir")
```

## Testing and Java Fixtures

Java fixtures are generated with:

```bash
julia --project=. scripts/generate_java_fixtures.jl
```

`Pkg.test()` will run the generator automatically when Java is installed and fixtures
are missing.
