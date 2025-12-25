# SBE.jl IR Refactor Plan

## Goal
Refactor SBE.jl to follow the reference SBE tool pipeline: parse XML into the SBE Intermediate Representation (IR) token stream, then generate Julia code from IR. This should simplify nested messages/composites and improve parity with the Java reference implementation while keeping codegen zero-allocation and type stable.

## Current State (Key Files)
- `src/xml_parser.jl` parses XML directly into `Schema.MessageSchema` structures.
- `src/codegen_utils.jl` generates Julia code directly from `Schema.MessageSchema`.
- Nested types are handled via ad-hoc recursion and special casing in codegen; this is the primary pain point.

## Plan
1. **Study reference IR and Julia generator**
   - Read `sbe-tool/src/main/java/uk/co/real_logic/sbe/xml/IrGenerator.java` and `sbe-tool/src/main/java/uk/co/real_logic/sbe/ir/*` for token/encoding structures and flattening rules.
   - Read `sbe-tool/src/main/java/uk/co/real_logic/sbe/generation/julia/JuliaGenerator.java` to mirror token traversal patterns, especially `collectFields/collectGroups/collectVarData` and `Signal` handling.

2. **Introduce a Julia IR model and utilities**
   - Add `src/IR.jl` (or similar) with Julia equivalents of `Ir`, `Token`, `Encoding`, `Signal`, and related enums/structs.
   - Implement traversal helpers matching the reference `GenerationUtil` (e.g., collect fields/groups/var-data, find end signal, etc.).
   - Keep IR types immutable and compact to preserve type stability and minimize allocation.

3. **Port IrGenerator and generate IR directly from XML**
   - Implement a Julia port of `IrGenerator` that consumes XML (via EzXML) and builds IR tokens directly, matching Java semantics for offsets, sizes, presence/constant values, sinceVersion/deprecated, and computed block lengths.
   - Ensure message header tokens are generated via `headerType` and available types.
   - Treat the current `Schema` model as legacy; do not depend on it in the IR path.

4. **Generate Julia code directly from IR**
   - Refactor codegen to build modules exclusively from `Ir` tokens.
   - Reuse existing low-level encode/decode helpers (`encode_value_le`, `decode_value_le`, etc.) but adjust field/group/composite generation to use token streams and signal boundaries.
   - Allow API changes as needed to remain idiomatic Julia while preserving SBE semantics and zero-allocation behavior.

5. **Remove schema-based codegen**
   - Delete or deprecate `Schema.jl` and schema-based generators once IR generation is the sole pipeline.
   - Update docs and tests to target the IR pipeline only.

6. **Tests and validation**
   - Add unit tests for IR generation using `test/sbe-ir.xml` and cross-check expected token properties (ids, offsets, lengths, presence, signals).
   - Port or reuse schemas from `simple-binary-encoding/sbe-tool/src/test/` to validate nested composites/groups and edge cases.
   - Run existing test suite to ensure no regressions; add new tests for nested messages/composites that previously failed.
   - Optional: generate Java codecs from the same schema and validate binary interoperability (round-trip encode/decode between Java and Julia).

## Deliverables
- New IR model and IR generator in Julia.
- Codegen path that consumes IR tokens (with fallback or migration from current schema-based generator).
- Expanded tests that cover nested composites/groups and IR generation.

## Notes / Constraints
- Generated Julia code must remain zero-allocation and type stable.
- Keep output idiomatic Julia while matching SBE design principles and wire format semantics.
- Avoid breaking existing public API unless necessary; if changes are needed, document them clearly.

## Proposed API (Zero-Overhead Convenience)
- Keep module-based API as the primary surface (e.g., `Baseline.Car.Encoder`).
- Add optional, compile-time helpers that avoid runtime lookup and allocations:
  - `SchemaSpec{M}` singleton wrapper, where `M` is the generated module.
  - `SBE.schema(mod::Module) -> SchemaSpec{mod}`.
  - `SBE.message(::SchemaSpec{M}, ::Val{:MessageName}) -> M.MessageName` (returns the module itself).
- Example usage:
  - `Baseline = SBE.load("example-schema.xml")`
  - `spec = SBE.schema(Baseline)`
  - `car_mod = SBE.message(spec, Val(:Car))`
  - `enc = car_mod.Encoder(buffer)`
