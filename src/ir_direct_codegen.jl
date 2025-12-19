"""
Direct IR to Julia Code Generator

Generates Julia code directly from IR tokens following the reference implementation approach.
Based on: https://github.com/New-Earth-Lab/simple-binary-encoding/blob/julia/sbe-tool/src/main/java/uk/co/real_logic/sbe/generation/julia/JuliaGenerator.java

This implementation processes IR tokens directly without reconstructing Schema,
matching the reference SBE implementation's approach.
"""

# Token collection helpers (similar to Java's GenerationUtil.collect*)

"""
    collect_fields(tokens::Vector{IR.IRToken}, start_idx::Int) -> Vector{IR.IRToken}

Collect field tokens from a message or group.
Returns tokens between BEGIN_FIELD and END_FIELD signals.
"""
function collect_fields(tokens::Vector{IR.IRToken}, start_idx::Int)
    fields = IR.IRToken[]
    idx = start_idx
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.BEGIN_FIELD
            # Collect the field tokens (BEGIN_FIELD ... END_FIELD)
            field_tokens = IR.IRToken[token]
            idx += 1
            depth = 1
            
            while idx <= length(tokens) && depth > 0
                t = tokens[idx]
                push!(field_tokens, t)
                
                if t.signal == IR.BEGIN_FIELD
                    depth += 1
                elseif t.signal == IR.END_FIELD
                    depth -= 1
                end
                
                idx += 1
            end
            
            push!(fields, field_tokens...)
        elseif token.signal in [IR.END_MESSAGE, IR.END_GROUP, IR.BEGIN_GROUP, IR.BEGIN_VAR_DATA]
            break
        else
            idx += 1
        end
    end
    
    return fields
end

"""
    collect_groups(tokens::Vector{IR.IRToken}, start_idx::Int) -> Vector{Vector{IR.IRToken}}

Collect group token lists from a message or group.
Returns a list of token lists, one for each group.
"""
function collect_groups(tokens::Vector{IR.IRToken}, start_idx::Int)
    groups = Vector{IR.IRToken}[]
    idx = start_idx
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.BEGIN_GROUP
            # Collect the entire group (BEGIN_GROUP ... END_GROUP)
            group_tokens = IR.IRToken[token]
            idx += 1
            depth = 1
            
            while idx <= length(tokens) && depth > 0
                t = tokens[idx]
                push!(group_tokens, t)
                
                if t.signal == IR.BEGIN_GROUP
                    depth += 1
                elseif t.signal == IR.END_GROUP
                    depth -= 1
                end
                
                idx += 1
            end
            
            push!(groups, group_tokens)
        elseif token.signal in [IR.END_MESSAGE, IR.END_GROUP, IR.BEGIN_VAR_DATA]
            break
        else
            idx += 1
        end
    end
    
    return groups
end

"""
    collect_var_data(tokens::Vector{IR.IRToken}, start_idx::Int) -> Vector{Vector{IR.IRToken}}

Collect variable-length data token lists.
Returns a list of token lists, one for each var data field.
"""
function collect_var_data(tokens::Vector{IR.IRToken}, start_idx::Int)
    var_data = Vector{IR.IRToken}[]
    idx = start_idx
    
    while idx <= length(tokens)
        token = tokens[idx]
        
        if token.signal == IR.BEGIN_VAR_DATA
            # Collect the var data tokens (BEGIN_VAR_DATA ... END_VAR_DATA)
            vd_tokens = IR.IRToken[token]
            idx += 1
            
            while idx <= length(tokens)
                t = tokens[idx]
                push!(vd_tokens, t)
                
                if t.signal == IR.END_VAR_DATA
                    idx += 1
                    break
                end
                
                idx += 1
            end
            
            push!(var_data, vd_tokens)
        elseif token.signal in [IR.END_MESSAGE, IR.END_GROUP]
            break
        else
            idx += 1
        end
    end
    
    return var_data
end

"""
    generate_from_ir_direct(ir::IR.IntermediateRepresentation) -> String

Generate Julia code directly from IR tokens without Schema bridge.

This follows the reference implementation approach:
1. Iterate over IR messages/types
2. Use collector functions to extract fields, groups, var data
3. Generate code directly from tokens

This eliminates the Schema bridge and reduces maintenance overhead.
"""
function generate_from_ir_direct(ir::IR.IntermediateRepresentation)
    # For now, fall back to the Schema bridge approach
    # This is a placeholder for the direct implementation
    # TODO: Implement full direct token processing
    
    # The proper implementation would:
    # 1. Generate module header
    # 2. Process types (enums, sets, composites) from tokens
    # 3. Process messages from tokens using collect_fields/groups/vardata
    # 4. Generate encoder/decoder structs and methods directly
    
    return generate_from_ir(ir)  # Temporary fallback
end

# Export the new function
# Note: This is being developed to replace generate_from_ir()
