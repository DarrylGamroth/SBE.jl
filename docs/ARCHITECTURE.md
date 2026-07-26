# SBE.jl Architecture

## Generation pipeline

SBE.jl uses the SBE Intermediate Representation (IR) token stream as the common
boundary between schema parsing and Julia code generation:

```text
SBE XML --XML.jl + SBE validation--> SBE.IR.Ir --IR codegen--> Julia codecs
Java .sbeir ---------decode_ir---------^
```

The XML path parses a message schema with XML.jl, applies SBE semantic validation by
default, and creates the token model defined in [`src/IR.jl`](../src/IR.jl). The
`.sbeir` path uses the handwritten bootstrap decoder in
[`src/ir_decoder.jl`](../src/ir_decoder.jl). Both paths feed
[`src/ir_codegen.jl`](../src/ir_codegen.jl), so equivalent XML- and IR-derived schemas
produce the same generated Julia API.

| Input | IR entry point | Codec-generation entry point |
|---|---|---|
| XML file | `generate_ir_file` | `generate` or `@load_schema` |
| XML text | `generate_ir_xml` | Generate IR, then `generate_from_ir` |
| Java `.sbeir` | `decode_ir` | `generate_from_ir` or `@load_sbeir` |
| `SBE.IR.Ir` | Already decoded | `generate_from_ir` |

The IR API is public and follows SBE.jl package versioning. It is not independently
versioned, and SBE.jl does not currently serialize IR back to `.sbeir`.

## Generated Julia API

Each generated schema is a Julia module containing message, composite, enum, set, and
repeating-group modules. Message encoders and decoders are mutable flyweights over a
caller-owned `AbstractArray{UInt8}`.

- `Message.Encoder(buffer, offset=0)` writes the message header and wraps the body.
- `Message.Decoder(buffer, offset=0)` reads and validates the header, then wraps the
  message body using its block length and schema version.
- `Encoder(typeof(buffer))` and `Decoder(typeof(buffer))`, followed by `wrap!` or
  `wrap_and_apply_header!`, retain codec state for allocation-sensitive reuse.
- Fixed fields use direct buffer access. Fixed text exposes `StringView`; variable data
  exposes a raw byte view unless the caller explicitly requests an owned `String`.
- Repeating groups and variable data share a stateful message position and must be
  consumed in schema order. Group iteration repositions and returns one reusable entry
  flyweight.

Generated public modules, codec types, fields, groups, enums, and set choices carry
schema-derived docstrings. Value setters return their receiver; no-value fixed-array
setters return a writable zero-copy view.

## Loading and Julia world age

`@load_schema` and `@load_sbeir` require literal paths and expand to ordinary top-level
module definitions in the caller. Functions defined after either macro compile in a
world that already contains the generated methods.

For a schema known at build time, `generate` or `generate_from_ir` can write a Julia
source file that the application includes at top level. Truly runtime-selected schemas
necessarily install methods in a newer Julia world; callers must cross that dynamic
loading boundary with `Base.invokelatest` before using the newly defined API.

## Generated-artifact policy

The package does not check in `src/generated/sbe_ir.jl`. Tests generate the SBE IR
codec from [`src/resources/sbe-ir.xml`](../src/resources/sbe-ir.xml) and compare it with
the handwritten bootstrap decoder. Test codecs are generated into a fresh temporary
directory for each test process, loaded once in private host modules, and discarded
when that process exits.

Applications may check in codecs generated from application-owned schemas when that
improves reproducible builds, IDE indexing, or code review. The generated file should
then be updated atomically with its schema and generator version.

## Compatibility boundary

The exact SbeTool release in `test/sbetool/pom.xml` is the maintained reference
oracle. The pinned schema differential, normalized IR comparison, Java wire fixtures,
and explicit unsupported features are recorded in the
[SbeTool compatibility ledger](SBETOOL_COMPATIBILITY.md). This evidence supports the
documented schema, IR, and wire cases; it is not formal FIX conformance certification
or a claim of parity with Java-only generator features.

## Allocation boundary

Selected reusable flyweight paths are tested for zero heap allocation after compilation
and setup. Codec construction, position-pointer creation, schema generation, dynamic
loading, and owned result materialization such as `String` are outside that scope.

[`test/test_allocations.jl`](../test/test_allocations.jl) checks representative fixed
fields, composites, metadata, variable data, and a warmed repeating-group loop.
[`benchmark/benchmarks.jl`](../benchmark/benchmarks.jl) separates setup-inclusive paths
from retained-codec reuse. These are maintained evidence for specific paths, not a
blanket allocation guarantee for every schema, buffer type, Julia version, or caller.
