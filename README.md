# SBE.jl

[![CI](https://github.com/DarrylGamroth/SBE.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/DarrylGamroth/SBE.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DarrylGamroth/SBE.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/DarrylGamroth/SBE.jl)

A high-performance Julia implementation of the [Simple Binary Encoding (SBE)](https://github.com/aeron-io/simple-binary-encoding) protocol for low-latency financial messaging.

## Overview

SBE.jl generates zero-allocation, type-stable Julia code from SBE XML schemas. The implementation uses flyweight patterns to operate directly on byte buffers without intermediate object allocation, making it suitable for high-frequency trading and other performance-critical applications.

## Features

- **Zero Allocation**: Direct buffer access using views and reinterpret
- **Type Stable**: All types known at code generation time
- **Full SBE Support**: Messages, groups, variable-length data, enums, sets, composites
- **Version Handling**: Schema versioning with `sinceVersion` and `acting_version`
- **Endianness**: Little-endian (default) and big-endian byte order
- **Character Encodings**: ASCII and UTF-8 with zero-copy StringView

## Usage

### Loading a Schema

```julia
using SBE

# Load schema and generate types
Baseline = SBE.load_schema("example-schema.xml")
```

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

This approach:
- ✅ Avoids Core.eval and world-age issues
- ✅ Enables proper IDE support and autocomplete
- ✅ Makes generated code reviewable
- ✅ Works with Julia's package precompilation

## Intermediate Representation (IR)

SBE.jl includes a complete Intermediate Representation (IR) compatible with the reference implementation. The code generation pipeline follows: **XML → Schema → IR → Julia Code**

```julia
# Generate and inspect IR
ir = SBE.generate_ir("example-schema.xml")
println("Package: ", ir.frame.package_name)
println("Number of tokens: ", length(ir.tokens))
```

The IR enables:
- **Cross-implementation compatibility** - IR can be serialized and shared with other SBE implementations
- **Schema inspection** - Programmatic access to schema structure
- **Future optimizations** - Alternative code generation strategies

**Note**: Current implementation uses a Schema bridge for code generation. The reference implementation generates code directly from IR tokens. See [docs/IR_IMPLEMENTATION.md](docs/IR_IMPLEMENTATION.md) for details and roadmap.

## Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Development history and completed features
- **[TODO.md](TODO.md)** - Planned enhancements and known issues
- **[Technical Documentation](docs/technical/)** - Deep dives into implementation details:
  - Code generation comparison with sbe-tool
  - Performance analysis and zero-allocation verification
  - Julia 1.12 world-age semantics analysis

## Testing

```bash
# Run all tests
julia --project -e 'using Pkg; Pkg.test()'

# Run specific test
julia --project test/test_groups.jl
```

Current status: **533+ tests passing** ✅

## Performance

SBE.jl achieves **zero allocation** for message encoding/decoding:
- Direct buffer access via views
- No intermediate object creation
- Type-stable code generation
- Optimal memory layout

See [PERFORMANCE_INSIGHTS.md](docs/technical/PERFORMANCE_INSIGHTS.md) for detailed benchmarks.

## Binary Compatibility

SBE.jl is binary-compatible with the official sbe-tool:
- ✅ Can decode messages encoded by sbe-tool
- ✅ sbe-tool can decode messages encoded by SBE.jl
- ✅ Identical byte layouts for all types

See [CODEGEN_COMPARISON.md](docs/technical/CODEGEN_COMPARISON.md) for API differences.

## References

- [SBE Specification](https://github.com/aeron-io/simple-binary-encoding)
- [FIX SBE Documentation](https://github.com/FIXTradingCommunity/fix-simple-binary-encoding)
