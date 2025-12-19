# Direct IR → Julia Code Generation TODO

## Current State

The implementation uses a Schema bridge: `IR → Schema → Julia`

This deviates from the reference implementation which does: `IR → Julia`

## Reference Implementation

The Java reference implementation processes IR directly:
https://github.com/New-Earth-Lab/simple-binary-encoding/blob/julia/sbe-tool/src/main/java/uk/co/real_logic/sbe/generation/julia/JuliaGenerator.java

### Key Patterns from Reference

1. **Token Collection**:
   ```java
   collectFields(tokens, index)
   collectGroups(tokens, index)
   collectVarData(tokens, index)
   ```

2. **Direct Iteration**:
   ```java
   for (final List<Token> tokens : ir.messages()) {
       // Process message tokens directly
   }
   for (final List<Token> tokens : ir.types()) {
       // Process type tokens directly
   }
   ```

3. **Signal-Based Switching**:
   ```java
   switch (tokens.get(0).signal()) {
       case BEGIN_ENUM:
           generateEnum(tokens);
           break;
       case BEGIN_SET:
           generateChoiceSet(tokens);
           break;
   }
   ```

## Implementation Plan

### Phase 1: Token Organization (Helper Functions)

Create Julia equivalents of the Java collector functions:

```julia
# src/ir_helpers.jl

function collect_fields(tokens::Vector{IR.IRToken}, start_idx::Int)
    # Collect field tokens between BEGIN_FIELD and END_FIELD
end

function collect_groups(tokens::Vector{IR.IRToken}, start_idx::Int)
    # Collect group token lists
end

function collect_var_data(tokens::Vector{IR.IRToken}, start_idx::Int)
    # Collect var data token lists
end

function find_end_signal(tokens::Vector{IR.IRToken}, start_idx::Int, begin_signal::IR.Signal, end_signal::IR.Signal)
    # Find matching END signal for a BEGIN signal
end
```

### Phase 2: Direct Type Generation

Replace Schema-based generation with IR token processing:

```julia
# Instead of:
function generateEnum_expr(enum_def::Schema.EnumType, schema::Schema.MessageSchema)
    # Uses Schema.EnumType structure
end

# Do:
function generate_enum_from_tokens(tokens::Vector{IR.IRToken})
    # tokens[1] is BEGIN_ENUM
    # tokens[2..n-1] are VALID_VALUE
    # tokens[n] is END_ENUM
    
    begin_token = tokens[1]
    name = begin_token.name
    encoding_type = begin_token.referenced_name
    
    # Generate enum code directly from tokens
end
```

### Phase 3: Direct Message Generation

```julia
function generate_message_from_tokens(tokens::Vector{IR.IRToken})
    begin_token = tokens[1]  # BEGIN_MESSAGE
    name = begin_token.name
    id = begin_token.field_id
    block_length = begin_token.token_size
    
    # Collect parts
    fields = collect_fields(tokens, 2)
    groups = collect_groups(tokens, 2)
    var_data = collect_var_data(tokens, 2)
    
    # Generate message struct
    # Generate encoder/decoder
    # Generate field accessors
    # Generate group iterators
    # Generate var data accessors
end
```

### Phase 4: Module Generation

```julia
function generate_from_ir_direct(ir::IR.IntermediateRepresentation)
    # Extract module metadata from frame
    module_name = format_module_name(ir.frame.package_name)
    
    # Organize tokens by type
    type_tokens = organize_type_tokens(ir.tokens)
    message_tokens = organize_message_tokens(ir.tokens)
    
    # Generate components
    enum_exprs = [generate_enum_from_tokens(t) for t in type_tokens.enums]
    set_exprs = [generate_set_from_tokens(t) for t in type_tokens.sets]
    composite_exprs = [generate_composite_from_tokens(t) for t in type_tokens.composites]
    message_exprs = [generate_message_from_tokens(t) for t in message_tokens]
    
    # Build module
    module_expr = build_module_expr(module_name, enum_exprs, set_exprs, composite_exprs, message_exprs)
    
    return expr_to_code_string(module_expr)
end
```

### Phase 5: Replace Bridge

Update `generate_from_ir()` to use direct implementation:

```julia
function generate_from_ir(ir::IR.IntermediateRepresentation)
    return generate_from_ir_direct(ir)
end
```

Remove `ir_to_schema()` and Schema bridge code.

## Token Structure Mapping

### Message Tokens

```
BEGIN_MESSAGE (name, id, blockLength)
├── BEGIN_FIELD (name, id, offset)
│   ├── ENCODING (primitiveType, size, presence)
│   └── END_FIELD
├── BEGIN_FIELD ...
├── BEGIN_GROUP (name, id)
│   ├── (dimension header reference)
│   ├── BEGIN_FIELD ...
│   └── END_GROUP
├── BEGIN_VAR_DATA (name, id)
│   ├── (length header reference)
│   └── END_VAR_DATA
└── END_MESSAGE
```

### Type Tokens

```
BEGIN_ENUM (name, encodingType)
├── VALID_VALUE (name, value)
├── VALID_VALUE ...
└── END_ENUM

BEGIN_SET (name, encodingType)
├── CHOICE (name, bitPosition)
├── CHOICE ...
└── END_SET

BEGIN_COMPOSITE (name)
├── ENCODING (name, primitiveType)
├── BEGIN_ENUM ...
├── BEGIN_COMPOSITE (nested) ...
└── END_COMPOSITE
```

## Benefits of Direct Implementation

1. **No Maintenance Overhead**: Eliminates Schema bridge
2. **Matches Reference**: Aligns with standard SBE approach
3. **Single Source of Truth**: IR is the only intermediate format
4. **Simpler**: No Schema reconstruction needed
5. **More Flexible**: Can optimize token processing directly

## Estimated Effort

- **Phase 1** (Token helpers): ~200 lines, 4 hours
- **Phase 2** (Type generation): ~400 lines, 8 hours  
- **Phase 3** (Message generation): ~600 lines, 12 hours
- **Phase 4** (Module assembly): ~200 lines, 4 hours
- **Phase 5** (Integration/testing): ~100 lines, 8 hours

**Total**: ~1500 lines, ~36 hours of careful implementation

## Current Bridge Code to Replace

Files containing Schema bridge:
- `src/ir_codegen.jl` (489 lines) - Contains `ir_to_schema()` bridge
- Tests should work unchanged (IR generation already tested)

## Testing Strategy

1. Keep existing tests that validate IR generation
2. Add tests that compare output of direct vs bridge generators
3. Once validated, remove bridge code
4. Update documentation to remove technical debt warnings

## Notes

The existing `codegen_utils.jl` (~3000 lines) can serve as a reference for what Julia code needs to be generated. The direct implementation will generate the same structures, just driven by IR tokens instead of Schema objects.
