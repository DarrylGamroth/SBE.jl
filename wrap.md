# Sketch: `wrap!` for message + group encoders/decoders

Goal: add a zero-alloc reuse path that mirrors the Java pattern by making message and group
wrappers mutable and providing `wrap!` functions. Keep existing constructors for ergonomics.
Do **not** add `wrap!` for composites or other internal types. Keep the shared
`PositionPointer` model for message/group traversal.

## Scope
- Messages: generated `Encoder` + `Decoder` structs (top-level message modules).
- Groups: generated `Encoder` + `Decoder` structs for repeating groups.
- Exclude composites and encoded types.

## High-level approach
1. Change generated message/group `Encoder` and `Decoder` structs to `mutable struct`.
2. Add `wrap!(...)` functions that mutate existing instances with a new buffer/offset/position.
3. Keep existing constructors intact to avoid breaking API; they can allocate new wrappers.
4. Provide `wrap!` overloads that match the common call patterns (header vs no header).
5. Mirror the Java `wrap` flow: set buffer, set offset, update position.
6. Reuse a shared `PositionPointer` to keep group traversal unchanged. Message wrappers
   store `position_ptr::PositionPointer` directly (no type parameter) and message `wrap!`
   reuses the wrapper's existing pointer without taking it as an argument.

## Messages: codegen sketch
Add to `ir_codegen.jl` in the message module generation (around message struct definitions):

- Change:
  - `struct Decoder` -> `mutable struct Decoder`
  - `struct Encoder` -> `mutable struct Encoder`

- Add `wrap!` methods in the generated module:

```
@inline function wrap!(m::Decoder, buffer::T, offset::Integer,
    acting_block_length::Integer, acting_version::Integer) where {T<:AbstractArray{UInt8}}
    m.buffer = buffer
    m.offset = Int64(offset)
    m.acting_block_length = UInt16(acting_block_length)
    m.acting_version = $(version_type_symbol)(acting_version)
    # Java: limit(offset + actingBlockLength)
    m.position_ptr[] = m.offset + m.acting_block_length
    return m
end

@inline function wrap!(m::Decoder, buffer::AbstractArray, offset::Integer=0;
    header=$header_module.Decoder(buffer, offset))
    if $header_module.templateId(header) != $(template_id_expr(ir, msg_token.id)) ||
       $header_module.schemaId(header) != $(schema_id_expr(ir, ir.id))
        throw(DomainError("Template id or schema id mismatch"))
    end
    return wrap!(m, buffer, offset + sbe_encoded_length(header),
        $header_module.blockLength(header), $header_module.version(header))
end
```

```
@inline function wrap!(m::Encoder, buffer::T, offset::Integer) where {T<:AbstractArray{UInt8}}
    m.buffer = buffer
    m.offset = Int64(offset)
    # Java: limit(offset + BLOCK_LENGTH)
    m.position_ptr[] = m.offset + $(block_length_expr(ir, msg_token.encoded_length))
    return m
end

@inline function wrap_and_apply_header!(m::Encoder, buffer::AbstractArray, offset::Integer=0;
    header=$header_module.Encoder(buffer, offset))
    $header_module.blockLength!(header, $(block_length_expr(ir, msg_token.encoded_length)))
    $header_module.templateId!(header, $(template_id_expr(ir, msg_token.id)))
    $header_module.schemaId!(header, $(schema_id_expr(ir, ir.id)))
    $header_module.version!(header, $(version_expr(ir, ir.version)))
    return wrap!(m, buffer, offset + sbe_encoded_length(header))
end
```

Notes:
- With `HasSbeHeader` removed, the ergonomic distinction is carried by the API shape:
  `wrap_and_apply_header!(enc, buffer, offset; header=...)` maps to Java `wrapAndApplyHeader(...)`, and
  `wrap!(enc, buffer, offset)` maps to Java `wrap(...)`.
  
Java reference (from `tmp/java-sbe/baseline/CarEncoder.java` and `CarDecoder.java`):
- `wrap(...)` sets `buffer`, `offset`, and `limit(offset + blockLength)`; `wrapAndApplyHeader(...)`
  fills the header then calls `wrap(...)`.
- `sbeRewind()` is implemented as `wrap(buffer, offset, actingBlockLength, actingVersion)`.

## Groups: codegen sketch
In group generation (around `generate_group_expr`), change:
- `struct Decoder` -> `mutable struct Decoder`
- `struct Encoder` -> `mutable struct Encoder`

Add `wrap!` for group decoders/encoders. These should mirror existing constructors and
match the fields in the group types.

Example shape (adjust names/fields to actual generated layout):

```
@inline function wrap!(g::Decoder, buffer::T, offset::Integer, position_ptr::PositionPointer,
    block_length::Integer, acting_version::Integer, count::Integer) where {T<:AbstractArray{UInt8}}
    g.buffer = buffer
    g.offset = Int64(offset)
    g.position_ptr = position_ptr
    g.block_length = UInt16(block_length)
    g.acting_version = $(version_type_symbol)(acting_version)
    g.count = Int64(count)
    g.index = Int64(0)
    position_ptr[] = g.offset + g.block_length
    return g
end

@inline function wrap!(g::Encoder, buffer::T, offset::Integer, position_ptr::PositionPointer,
    initial_position::Integer, count::Integer) where {T<:AbstractArray{UInt8}}
    g.buffer = buffer
    g.offset = Int64(offset)
    g.position_ptr = position_ptr
    g.initial_position = Int64(initial_position)
    g.count = Int64(count)
    g.index = Int64(0)
    position_ptr[] = g.offset + g.block_length
    return g
end
```

This should set the same fields that existing constructors set, plus reset `index`.

Java reference (from `tmp/java-sbe/baseline/CarEncoder.java` and `CarDecoder.java`):
- Group encoder `wrap(buffer, count)` writes the group dimension header using the parent
  message limit, then advances the parent limit by `HEADER_SIZE`.
- Group decoder `wrap(buffer)` reads the dimension header from the parent limit, updates
  `blockLength` and `count`, and advances the parent limit by `HEADER_SIZE`.
- `next()` advances `offset` from parent limit and increments the parent limit by block length.

## API guidance
- Add a short section to README or docs: “For zero allocations, reuse wrapper objects
  with `wrap!` (messages reuse their own `PositionPointer`; groups still use the shared
  pointer).”
- Keep constructors for convenience; `wrap!` is the fast path.

## Open questions
- Do we want `wrap!(...)` for the header codec itself? (Probably no.)
