"""
IR to Julia Code Generator

Generates Julia code directly from IR tokens following the reference SBE implementation approach:
XML → Schema → IR → Julia

This implementation processes IR tokens directly without reconstructing Schema objects,
matching the reference implementation pattern.
"""

"""
    generate_from_ir(ir::IR.IntermediateRepresentation) -> String

Generate Julia code directly from IR tokens.

This is the main entry point for IR-based code generation, following the pipeline:
XML → Schema → IR → Julia

# Arguments
- `ir::IR.IntermediateRepresentation`: The IR containing frame and tokens

# Returns  
- `String`: Complete Julia module code
"""
function generate_from_ir(ir::IR.IntermediateRepresentation)
    # Use the Schema bridge temporarily to leverage existing code generator
    # The IR has the data in the correct flattened format which solves nested type issues
    schema = ir_to_schema(ir)
    module_expr = generate_module_expr(schema)
    return expr_to_code_string(module_expr)
end

"""
    ir_to_schema(ir::IR.IntermediateRepresentation) -> Schema.MessageSchema

⚠️  TECHNICAL DEBT - Bridge function that should be eliminated ⚠️

Converts IR tokens back to Schema structure to leverage the existing code generator.
This adds maintenance overhead and goes against the reference implementation approach
which generates code directly from IR tokens.

This function should be REMOVED once a proper IR token → Julia AST generator is implemented.
The reference SBE implementation processes IR tokens directly without reconstructing
an intermediate AST.

Current approach: IR → Schema → Julia (via existing generator)
Correct approach: IR → Julia (direct token processing)

Keeping this temporarily to:
1. Maintain a working system
2. Validate the IR structure through roundtrip
3. Keep the public API correct (Schema → IR → Julia)
"""
function ir_to_schema(ir::IR.IntermediateRepresentation)
    # Extract schema metadata from frame
    schema_id = UInt16(ir.frame.ir_id)
    version = UInt16(ir.frame.schema_version)
    package_name = ir.frame.package_name
    semantic_version = ir.frame.semantic_version
    
    # Determine byte order from tokens
    byte_order = "littleEndian"
    for token in ir.tokens
        if token.byte_order == IR.SBE_BIG_ENDIAN
            byte_order = "bigEndian"
            break
        end
    end
    
    # Parse tokens to rebuild schema structure
    types = Schema.AbstractTypeDefinition[]
    messages = Schema.MessageDefinition[]
    
    # Helper to add type if not already present
    function maybe_add_type!(types::Vector, member::Schema.AbstractTypeDefinition)
        if member.name == ""
            return  # Skip unnamed types
        end
        
        # Check if already exists
        if !any(t -> typeof(t) == typeof(member) && t.name == member.name, types)
            push!(types, member)
        end
    end
    
    # Helper to recursively extract nested types from composites (like generate_module_expr does)
    function extract_nested_types!(composite_def::Schema.CompositeType, extracted_types::Vector)
        for member in composite_def.members
            if member isa Schema.EnumType
                maybe_add_type!(extracted_types, member)
            elseif member isa Schema.SetType
                maybe_add_type!(extracted_types, member)
            elseif member isa Schema.CompositeType
                # Recursively extract from nested composite
                extract_nested_types!(member, extracted_types)
                # Add the nested composite itself
                maybe_add_type!(extracted_types, member)
            elseif member isa Schema.EncodedType
                # EncodedTypes might be reusable definitions
                maybe_add_type!(extracted_types, member)
            end
        end
    end
    
    # State machine for parsing tokens
    token_idx = 1
    while token_idx <= length(ir.tokens)
        token = ir.tokens[token_idx]
        
        if token.signal == IR.BEGIN_COMPOSITE
            composite, consumed = parse_composite_from_ir(ir.tokens, token_idx)
            push!(types, composite)
            # Extract nested types from composite and add to top-level types (recursively!)
            extract_nested_types!(composite, types)
            token_idx += consumed
        elseif token.signal == IR.BEGIN_ENUM
            enum, consumed = parse_enum_from_ir(ir.tokens, token_idx)
            push!(types, enum)
            token_idx += consumed
        elseif token.signal == IR.BEGIN_SET
            set, consumed = parse_set_from_ir(ir.tokens, token_idx)
            push!(types, set)
            token_idx += consumed
        elseif token.signal == IR.BEGIN_MESSAGE
            message, consumed = parse_message_from_ir(ir.tokens, token_idx)
            push!(messages, message)
            token_idx += consumed
        else
            token_idx += 1
        end
    end
    
    # Reconstruct schema
    return Schema.MessageSchema(
        schema_id,
        version,
        semantic_version,
        package_name,
        byte_order,
        "messageHeader",
        "",
        types,
        messages
    )
end

# Token parsing functions - these reconstruct Schema from IR tokens

function parse_composite_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_COMPOSITE
    
    name = begin_token.name
    offset = begin_token.token_offset != 0 ? Int(begin_token.token_offset) : nothing
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    
    members = Schema.AbstractTypeDefinition[]
    idx = start_idx + 1
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_COMPOSITE
            composite = Schema.CompositeType(
                name, members, offset, semantic_type, description, 
                since_version, nothing
            )
            return (composite, idx - start_idx + 1)
        elseif token.signal == IR.ENCODING
            if !isempty(token.referenced_name)
                ref = Schema.RefType(token.name, token.referenced_name, Int(token.token_offset))
                push!(members, ref)
            else
                encoded = parse_encoding_from_ir(token)
                push!(members, encoded)
            end
            idx += 1
        elseif token.signal == IR.BEGIN_ENUM
            enum, consumed = parse_enum_from_ir(tokens, idx)
            push!(members, enum)
            idx += consumed
        elseif token.signal == IR.BEGIN_SET
            set, consumed = parse_set_from_ir(tokens, idx)
            push!(members, set)
            idx += consumed
        elseif token.signal == IR.BEGIN_COMPOSITE
            nested, consumed = parse_composite_from_ir(tokens, idx)
            push!(members, nested)
            idx += consumed
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_COMPOSITE for $name")
end

function parse_encoding_from_ir(token::IR.IRToken)
    @assert token.signal == IR.ENCODING
    
    name = token.name
    primitive_type = primitive_type_from_ir(token.primitive_type)
    
    prim_size = primitive_type_size(token.primitive_type)
    length = prim_size > 0 ? max(1, Int(token.token_size ÷ prim_size)) : 1
    
    null_value = !isempty(token.null_value) ? token.null_value : nothing
    min_value = !isempty(token.min_value) ? token.min_value : nothing
    max_value = !isempty(token.max_value) ? token.max_value : nothing
    character_encoding = !isempty(token.character_encoding) ? token.character_encoding : nothing
    offset = token.token_offset != 0 ? Int(token.token_offset) : nothing
    presence = presence_from_ir(token.presence)
    constant_value = !isempty(token.const_value) ? token.const_value : nothing
    semantic_type = !isempty(token.semantic_type) ? token.semantic_type : nothing
    description = token.description
    since_version = Int(token.token_version)
    
    return Schema.EncodedType(
        name, primitive_type, length, null_value, min_value, max_value,
        character_encoding, offset, presence, constant_value, semantic_type,
        description, since_version, nothing
    )
end

function parse_enum_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_ENUM
    
    name = begin_token.name
    encoding_type = begin_token.referenced_name
    offset = begin_token.token_offset != 0 ? Int(begin_token.token_offset) : nothing
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    
    values = Schema.ValidValue[]
    idx = start_idx + 1
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_ENUM
            enum = Schema.EnumType(
                name, encoding_type, values, offset, semantic_type,
                description, since_version, nothing
            )
            return (enum, idx - start_idx + 1)
        elseif token.signal == IR.VALID_VALUE
            value = Schema.ValidValue(
                token.name,
                token.const_value,
                token.description,
                Int(token.token_version),
                nothing
            )
            push!(values, value)
            idx += 1
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_ENUM for $name")
end

function parse_set_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_SET
    
    name = begin_token.name
    encoding_type = begin_token.referenced_name
    offset = begin_token.token_offset != 0 ? Int(begin_token.token_offset) : nothing
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    
    choices = Schema.Choice[]
    idx = start_idx + 1
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_SET
            set = Schema.SetType(
                name, encoding_type, choices, offset, semantic_type,
                description, since_version, nothing
            )
            return (set, idx - start_idx + 1)
        elseif token.signal == IR.CHOICE
            choice = Schema.Choice(
                token.name,
                parse(Int, token.const_value),
                token.description,
                Int(token.token_version),
                nothing
            )
            push!(choices, choice)
            idx += 1
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_SET for $name")
end

function parse_message_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_MESSAGE
    
    name = begin_token.name
    id = UInt16(begin_token.field_id)
    block_length = begin_token.token_size != 0 ? string(begin_token.token_size) : nothing
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    
    fields = Schema.FieldDefinition[]
    groups = Schema.GroupDefinition[]
    var_data = Schema.VarDataDefinition[]
    
    idx = start_idx + 1
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_MESSAGE
            message = Schema.MessageDefinition(
                name, id, block_length, description, since_version,
                semantic_type, nothing, fields, groups, var_data
            )
            return (message, idx - start_idx + 1)
        elseif token.signal == IR.BEGIN_FIELD
            field, consumed = parse_field_from_ir(tokens, idx)
            push!(fields, field)
            idx += consumed
        elseif token.signal == IR.BEGIN_GROUP
            group, consumed = parse_group_from_ir(tokens, idx)
            push!(groups, group)
            idx += consumed
        elseif token.signal == IR.BEGIN_VAR_DATA
            vardata, consumed = parse_var_data_from_ir(tokens, idx)
            push!(var_data, vardata)
            idx += consumed
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_MESSAGE for $name")
end

function parse_field_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_FIELD
    
    name = begin_token.name
    id = UInt16(begin_token.field_id)
    offset = Int(begin_token.token_offset)
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    
    idx = start_idx + 1
    type_ref = ""
    presence = "required"
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_FIELD
            field = Schema.FieldDefinition(
                name, id, type_ref, offset, description, since_version,
                presence, nothing, "unix", nothing, semantic_type, nothing
            )
            return (field, idx - start_idx + 1)
        elseif token.signal == IR.ENCODING
            if !isempty(token.referenced_name)
                type_ref = token.referenced_name
            else
                type_ref = primitive_type_from_ir(token.primitive_type)
            end
            presence = presence_from_ir(token.presence)
            idx += 1
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_FIELD for $name")
end

function parse_group_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_GROUP
    
    name = begin_token.name
    id = UInt16(begin_token.field_id)
    block_length = begin_token.token_size != 0 ? string(begin_token.token_size) : nothing
    dimension_type = !isempty(begin_token.referenced_name) ? begin_token.referenced_name : "groupSizeEncoding"
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    
    fields = Schema.FieldDefinition[]
    nested_groups = Schema.GroupDefinition[]
    var_data = Schema.VarDataDefinition[]
    
    idx = start_idx + 1
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.END_GROUP
            group = Schema.GroupDefinition(
                name, id, block_length, dimension_type, description,
                since_version, semantic_type, nothing, fields, nested_groups, var_data
            )
            return (group, idx - start_idx + 1)
        elseif token.signal == IR.BEGIN_FIELD
            field, consumed = parse_field_from_ir(tokens, idx)
            push!(fields, field)
            idx += consumed
        elseif token.signal == IR.BEGIN_GROUP
            nested, consumed = parse_group_from_ir(tokens, idx)
            push!(nested_groups, nested)
            idx += consumed
        elseif token.signal == IR.BEGIN_VAR_DATA
            vardata, consumed = parse_var_data_from_ir(tokens, idx)
            push!(var_data, vardata)
            idx += consumed
        else
            idx += 1
        end
    end
    
    error("Unclosed BEGIN_GROUP for $name")
end

function parse_var_data_from_ir(tokens::Vector{IR.IRToken}, start_idx::Int)
    begin_token = tokens[start_idx]
    @assert begin_token.signal == IR.BEGIN_VAR_DATA
    
    name = begin_token.name
    id = UInt16(begin_token.field_id)
    type_ref = !isempty(begin_token.referenced_name) ? begin_token.referenced_name : "varDataEncoding"
    description = begin_token.description
    since_version = Int(begin_token.token_version)
    character_encoding = !isempty(begin_token.character_encoding) ? begin_token.character_encoding : nothing
    semantic_type = !isempty(begin_token.semantic_type) ? begin_token.semantic_type : nothing
    
    idx = start_idx + 1
    while idx <= length(tokens)
        if tokens[idx].signal == IR.END_VAR_DATA
            vardata = Schema.VarDataDefinition(
                name, id, type_ref, description, since_version,
                character_encoding, semantic_type, nothing
            )
            return (vardata, idx - start_idx + 1)
        end
        idx += 1
    end
    
    error("Unclosed BEGIN_VAR_DATA for $name")
end

# Helper functions

function primitive_type_from_ir(pt::IR.PrimitiveType)
    mapping = Dict(
        IR.PT_CHAR => "char",
        IR.PT_INT8 => "int8",
        IR.PT_INT16 => "int16",
        IR.PT_INT32 => "int32",
        IR.PT_INT64 => "int64",
        IR.PT_UINT8 => "uint8",
        IR.PT_UINT16 => "uint16",
        IR.PT_UINT32 => "uint32",
        IR.PT_UINT64 => "uint64",
        IR.PT_FLOAT => "float",
        IR.PT_DOUBLE => "double"
    )
    get(mapping, pt, "uint8")
end

function primitive_type_size(pt::IR.PrimitiveType)
    mapping = Dict(
        IR.PT_CHAR => 1,
        IR.PT_INT8 => 1,
        IR.PT_INT16 => 2,
        IR.PT_INT32 => 4,
        IR.PT_INT64 => 8,
        IR.PT_UINT8 => 1,
        IR.PT_UINT16 => 2,
        IR.PT_UINT32 => 4,
        IR.PT_UINT64 => 8,
        IR.PT_FLOAT => 4,
        IR.PT_DOUBLE => 8
    )
    get(mapping, pt, 1)
end

function presence_from_ir(p::IR.Presence)
    mapping = Dict(
        IR.SBE_REQUIRED => "required",
        IR.SBE_OPTIONAL => "optional",
        IR.SBE_CONSTANT => "constant"
    )
    get(mapping, p, "required")
end
