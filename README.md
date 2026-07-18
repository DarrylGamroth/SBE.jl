# SBE.jl

[![CI](https://github.com/DarrylGamroth/SBE.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/DarrylGamroth/SBE.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DarrylGamroth/SBE.jl/branch/main/graph/badge.svg)](https://app.codecov.io/gh/DarrylGamroth/SBE.jl)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

A high-performance Julia implementation of the [Simple Binary Encoding (SBE)](https://github.com/aeron-io/simple-binary-encoding) protocol for low-latency financial messaging.

## Overview

SBE.jl generates type-stable Julia flyweight codecs from SBE XML schemas. Warmed,
steady-state field access, group iteration, and raw variable-data operations are
designed to run without heap allocation. Codec setup and materializing owned values
such as `String` can allocate.

## Features

- **Allocation-Conscious**: Reusable flyweights and zero-copy buffer views for hot paths
- **Type Stable**: All types known at code generation time
- **SBE Schema Support**: Messages, groups, variable-length data, enums, sets, and composites
- **Version Handling**: Schema versioning with `sinceVersion` and `acting_version`
- **Endianness**: Little-endian (default) and big-endian byte order
- **Character Encodings**: ASCII and UTF-8 with zero-copy StringView

## Usage

### Loading a Schema

```julia
using SBE

# Top-level macro call: generate during expansion and define the codec module here.
baseline_name = @load_schema "example-schema.xml"
Baseline = getfield(@__MODULE__, baseline_name)
```

You can override the generated module name:

```julia
custom_name = @load_schema("example-schema.xml"; module_name="CustomSchema")
CustomSchema = getfield(@__MODULE__, custom_name)
```

`@load_schema` must be used at top level with a literal path. In a source file,
relative paths are resolved relative to that file; at the REPL they are resolved
relative to the working directory. The macro emits the generated codec module into
the calling module before later functions are defined, avoiding world-age problems
without `Base.invokelatest`.

### Encoding a Message

```julia
# Create buffer and encoder
buffer = zeros(UInt8, 512)
car = Baseline.Car.Encoder(buffer)

# Set message fields
Baseline.Car.serialNumber!(car, 12345)
Baseline.Car.modelYear!(car, 2024)
Baseline.Car.available!(car, Baseline.BooleanType.T)
Baseline.Car.code!(car, Baseline.Model.A)
Baseline.Car.vehicleCode!(car, "ABC123")

# Set composite field
engine = Baseline.Car.engine(car)
Baseline.Engine.capacity!(engine, 2000)
Baseline.Engine.numCylinders!(engine, 4)
Baseline.Engine.manufacturerCode!(engine, "XYZ")

# Set optional extras (bitset)
extras = Baseline.Car.extras(car)
Baseline.OptionalExtras.sunRoof!(extras, true)
Baseline.OptionalExtras.cruiseControl!(extras, true)

# Add repeating group
fuel_figures = Baseline.Car.fuelFigures!(car, 2)
for (speed, mpg, desc) in [(30, 35.9, "Urban"), (70, 49.0, "Highway")]
    fig = Baseline.Car.FuelFigures.next!(fuel_figures)
    Baseline.Car.FuelFigures.speed!(fig, speed)
    Baseline.Car.FuelFigures.mpg!(fig, mpg)
    Baseline.Car.FuelFigures.usageDescription!(fig, desc)
end

# Add variable-length data
Baseline.Car.manufacturer!(car, "Honda")
Baseline.Car.model!(car, "Civic")
Baseline.Car.activationCode!(car, "ABCD1234")

# Get encoded length
encoded_length = SBE.sbe_encoded_length(car)
```

### Decoding a Message

```julia
# Create decoder from buffer
car_decoder = Baseline.Car.Decoder(buffer)

# Read fields
serial = Baseline.Car.serialNumber(car_decoder)
year = Baseline.Car.modelYear(car_decoder)
is_available = Baseline.Car.available(car_decoder)
model_code = Baseline.Car.code(car_decoder)
vehicle_code = Baseline.Car.vehicleCode(car_decoder)

# Read composite
engine = Baseline.Car.engine(car_decoder)
capacity = Baseline.Engine.capacity(engine)
cylinders = Baseline.Engine.numCylinders(engine)
max_rpm = Baseline.Engine.maxRpm(engine)  # Constant field

# Read optional extras
extras = Baseline.Car.extras(car_decoder)
has_sunroof = Baseline.OptionalExtras.sunRoof(extras)
has_cruise = Baseline.OptionalExtras.cruiseControl(extras)

# Iterate over group
fuel_figures = Baseline.Car.fuelFigures(car_decoder)
for fig in fuel_figures
    speed = Baseline.Car.FuelFigures.speed(fig)
    mpg = Baseline.Car.FuelFigures.mpg(fig)
    desc = Baseline.Car.FuelFigures.usageDescription(fig)
    println("At $speed mph: $mpg mpg ($desc)")
end

# Read variable-length data
manufacturer = Baseline.Car.manufacturer(car_decoder)
model = Baseline.Car.model(car_decoder)
activation = Baseline.Car.activationCode(car_decoder)
```

Generated setters return their encoder, fixed-length text rejects values that do
not fit, and fields declared as ASCII reject non-ASCII strings. Repeating groups
and variable-length data share a stateful cursor: access them in schema order and
do not retain group entries as independent objects. Generated modules, codec
types, fields, groups, enums, and set choices include schema-derived docstrings,
so Julia's `?` help and editor hover documentation describe these contracts.

For allocation-sensitive reuse, construct an unwrapped flyweight from the buffer
type and wrap it repeatedly:

```julia
car = Baseline.Car.Encoder(typeof(buffer))
Baseline.Car.wrap_and_apply_header!(car, buffer)

car_decoder = Baseline.Car.Decoder(typeof(buffer))
Baseline.Car.wrap!(car_decoder, buffer)
```

### Nested Groups

```julia
# Encoding nested groups
perf_figures = Baseline.Car.performanceFigures!(car, 2)

fig1 = Baseline.Car.PerformanceFigures.next!(perf_figures)
Baseline.Car.PerformanceFigures.octaneRating!(fig1, 95)

accel1 = Baseline.Car.PerformanceFigures.acceleration!(fig1, 2)
acc = Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
Baseline.Car.PerformanceFigures.Acceleration.mph!(acc, 60)
Baseline.Car.PerformanceFigures.Acceleration.seconds!(acc, 4.5)

acc = Baseline.Car.PerformanceFigures.Acceleration.next!(accel1)
Baseline.Car.PerformanceFigures.Acceleration.mph!(acc, 100)
Baseline.Car.PerformanceFigures.Acceleration.seconds!(acc, 7.2)

# Decoding nested groups
perf_figures = Baseline.Car.performanceFigures(car_decoder)
for fig in perf_figures
    octane = Baseline.Car.PerformanceFigures.octaneRating(fig)
    println("Octane: $octane")
    
    acceleration = Baseline.Car.PerformanceFigures.acceleration(fig)
    for acc in acceleration
        mph = Baseline.Car.PerformanceFigures.Acceleration.mph(acc)
        secs = Baseline.Car.PerformanceFigures.Acceleration.seconds(acc)
        println("  0-$mph mph: $secs seconds")
    end
end
```

## IR API

SBE.jl exposes a public Intermediate Representation (IR) surface for tooling:

```julia
ir = SBE.generate_ir_file("example-schema.xml")
messages = SBE.IR.ir_messages(ir)
schema_id = SBE.IR.ir_id(ir)
```

Java-produced `.sbeir` files can be decoded and used to generate the same Julia
codec source as XML-derived IR:

```julia
# Generate source or a normal includable Julia file.
code = SBE.generate_from_ir("example-schema.sbeir"; module_name=:Baseline)
SBE.generate_from_ir(
    "example-schema.sbeir",
    "generated/Baseline.jl";
    module_name=:Baseline,
)

# Or generate and define the module at expansion time.
baseline_name = SBE.@load_sbeir(
    "example-schema.sbeir";
    module_name=:Baseline,
)
```

`@load_sbeir` has the same top-level, literal-path, caller-module, and world-age
semantics as `@load_schema`. SBE.jl does not currently serialize IR back to
`.sbeir`.

## Benchmarks

Benchmarks cover encode-only, decode-only, and round-trip paths:

```bash
julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
julia --project=benchmark benchmark/benchmarks.jl
```

## File-Based Generation

For production use, generate standalone Julia files:

```julia
using SBE

# Generate a .jl file from XML schema
SBE.generate("example-schema.xml", "generated/Baseline.jl")

# Load the generated schema
include("generated/Baseline.jl")
using .Baseline
```

Validation can be configured during parsing and generation:

```julia
SBE.generate("example-schema.xml", "generated/Baseline.jl"; warnings_fatal=true)
SBE.parse_xml_schema(read("example-schema.xml", String); suppress_warnings=true)
baseline_name = @load_schema("example-schema.xml"; warnings_fatal=true)
Baseline = getfield(@__MODULE__, baseline_name)
```

This approach:
- Avoids Core.eval and world-age issues
- Enables proper IDE support and autocomplete
- Makes generated code reviewable
- Works with Julia's package precompilation

## Documentation

- **[Usage Guide](docs/USAGE.md)** - Comprehensive API guide and examples
- **[SbeTool Compatibility](docs/SBETOOL_COMPATIBILITY.md)** - Pinned upstream evidence and support boundaries
- **[Architecture](docs/ARCHITECTURE.md)** - XML/IR/code-generation pipeline and support boundaries

## Testing

```bash
# Run all tests
julia --project -e 'using Pkg; Pkg.test()'

# Run one or more test files through the shared fixture runner
julia --project -e 'using Pkg; Pkg.test(test_args=["test_groups"])'
julia --project -e 'using Pkg; Pkg.test(test_args=["test_groups", "test_vardata"])'

# Generate Java fixtures (used for parity tests)
julia --project=. scripts/generate_java_fixtures.jl
```

The runner generates test codecs into a fresh temporary directory and loads each
fixture once in an isolated module. The suite covers generated-code behavior,
validation, Java interoperability, and QA checks.

## Performance

SBE.jl targets **zero heap allocation after warmup** for reusable flyweight hot
paths. Fixed fields, raw buffer views, repeating-group iteration, and variable-data
byte access operate directly on caller-owned storage. Creating codec state (including
its position pointer) and requesting owned results such as `String` may allocate.

- Reuse codecs with `wrap!` and `wrap_and_apply_header!` in allocation-sensitive loops.
- Prefer raw byte or `StringView` accessors when an owned `String` is unnecessary.
- Use the benchmark suite and committed allocation tests for representative evidence.

See `docs/USAGE.md` for usage notes and performance considerations.

## Binary Compatibility

SBE.jl is tested for binary interoperability with SbeTool 1.37.1:
- Decodes the Java fixtures produced by SbeTool
- Produces messages accepted by the generated Java codecs
- Matches all 79 upstream fixture acceptance decisions and the normalized IR for all
  66 fixtures accepted by both tools
- Resolves the relative XInclude case exercised by the upstream parser suite

The complete pinned fixture, schema, and IR differential can be rerun with
`scripts/check_sbetool_schema_compat.jl` against an SbeTool checkout and jar.

See `docs/SBETOOL_COMPATIBILITY.md` for the evidence ledger and explicit support
boundaries. This is an interoperability claim, not formal FIX conformance certification.

## References

- [SBE Specification](https://github.com/aeron-io/simple-binary-encoding)
- [FIX SBE Documentation](https://github.com/FIXTradingCommunity/fix-simple-binary-encoding)

## License

SBE.jl is licensed under the [Apache License 2.0](LICENSE). Copyright 2025-2026
Rubus Technologies Inc.; see [NOTICE](NOTICE).
