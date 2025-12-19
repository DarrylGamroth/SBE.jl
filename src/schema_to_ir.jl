"""
Schema to IR Converter

Converts the parsed Schema representation to the Intermediate Representation (IR)
compatible with the reference SBE implementation.
"""

using .IR
using .Schema

"""
    schema_to_ir(schema::Schema.MessageSchema) -> IR.IntermediateRepresentation

Convert a parsed SBE schema to an Intermediate Representation.
"""
function schema_to_ir(schema::Schema.MessageSchema)
    # Create the frame header
    frame = IR.IRFrame(
        Int32(schema.id),
        Int32(0),  # IR version
        Int32(schema.version),
        schema.package,
        "",  # namespace (not used in Julia)
        schema.semantic_version
    )
    
    # Generate tokens
    tokens = IR.IRToken[]
    
    # Add tokens for types (composites, enums, sets)
    for type_def in schema.types
        add_type_tokens!(tokens, type_def, schema)
    end
    
    # Add tokens for messages
    for message in schema.messages
        add_message_tokens!(tokens, message, schema)
    end
    
    return IR.IntermediateRepresentation(frame, tokens)
end

"""
Add tokens for a type definition
"""
function add_type_tokens!(tokens::Vector{IR.IRToken}, type_def::Schema.AbstractTypeDefinition, schema::Schema.MessageSchema)
    if type_def isa Schema.CompositeType
        add_composite_tokens!(tokens, type_def, schema)
    elseif type_def isa Schema.EnumType
        add_enum_tokens!(tokens, type_def, schema)
    elseif type_def isa Schema.SetType
        add_set_tokens!(tokens, type_def, schema)
    end
    # EncodedType standalone types don't generate tokens (they're referenced)
end

"""
Add tokens for a composite type
"""
function add_composite_tokens!(tokens::Vector{IR.IRToken}, composite::Schema.CompositeType, schema::Schema.MessageSchema)
    offset = composite.offset !== nothing ? Int32(composite.offset) : Int32(0)
    size = Int32(calculate_composite_size(composite, schema))
    
    # BEGIN_COMPOSITE token
    push!(tokens, IR.IRToken(
        token_offset = offset,
        token_size = size,
        field_id = Int32(-1),
        token_version = Int32(composite.since_version),
        component_token_count = Int32(length(composite.members)),
        signal = IR.BEGIN_COMPOSITE,
        name = composite.name,
        description = composite.description,
        semantic_type = composite.semantic_type !== nothing ? composite.semantic_type : ""
    ))
    
    # Add member tokens
    current_offset = 0
    for member in composite.members
        if member isa Schema.EncodedType
            add_encoded_type_token!(tokens, member, current_offset, schema)
            if member.presence != "constant"
                current_offset += get_type_size(member, schema)
            end
        elseif member isa Schema.RefType
            add_ref_type_token!(tokens, member, current_offset, schema)
            current_offset += get_ref_type_size(member, schema)
        elseif member isa Schema.EnumType
            add_enum_tokens!(tokens, member, schema, current_offset)
            current_offset += get_enum_size(member, schema)
        elseif member isa Schema.SetType
            add_set_tokens!(tokens, member, schema, current_offset)
            current_offset += get_set_size(member, schema)
        elseif member isa Schema.CompositeType
            add_composite_tokens!(tokens, member, schema)
            current_offset += calculate_composite_size(member, schema)
        end
    end
    
    # END_COMPOSITE token
    push!(tokens, IR.IRToken(
        signal = IR.END_COMPOSITE,
        name = composite.name
    ))
end

"""
Add token for an encoded type (primitive or array)
"""
function add_encoded_type_token!(tokens::Vector{IR.IRToken}, encoded::Schema.EncodedType, offset::Int, schema::Schema.MessageSchema)
    primitive_type = primitive_type_to_ir(encoded.primitive_type)
    presence = presence_to_ir(encoded.presence)
    byte_order = schema.byte_order == "littleEndian" ? IR.SBE_LITTLE_ENDIAN : IR.SBE_BIG_ENDIAN
    
    push!(tokens, IR.IRToken(
        token_offset = Int32(offset !== nothing ? offset : (encoded.offset !== nothing ? encoded.offset : 0)),
        token_size = Int32(get_type_size(encoded, schema)),
        field_id = Int32(-1),
        token_version = Int32(encoded.since_version),
        signal = IR.ENCODING,
        primitive_type = primitive_type,
        byte_order = byte_order,
        presence = presence,
        name = encoded.name,
        const_value = encoded.constant_value !== nothing ? encoded.constant_value : "",
        min_value = encoded.min_value !== nothing ? encoded.min_value : "",
        max_value = encoded.max_value !== nothing ? encoded.max_value : "",
        null_value = encoded.null_value !== nothing ? encoded.null_value : "",
        character_encoding = encoded.character_encoding !== nothing ? encoded.character_encoding : "",
        semantic_type = encoded.semantic_type !== nothing ? encoded.semantic_type : "",
        description = encoded.description
    ))
end

"""
Add token for a ref type
"""
function add_ref_type_token!(tokens::Vector{IR.IRToken}, ref::Schema.RefType, offset::Int, schema::Schema.MessageSchema)
    push!(tokens, IR.IRToken(
        token_offset = Int32(offset),
        field_id = Int32(-1),
        signal = IR.ENCODING,
        name = ref.name,
        referenced_name = ref.type_ref
    ))
end

"""
Add tokens for an enum type
"""
function add_enum_tokens!(tokens::Vector{IR.IRToken}, enum::Schema.EnumType, schema::Schema.MessageSchema, offset::Int = 0)
    # Get the encoding type
    encoding_type_def = find_type(schema, enum.encoding_type)
    size = encoding_type_def !== nothing ? get_type_size(encoding_type_def, schema) : 0
    
    # BEGIN_ENUM token
    push!(tokens, IR.IRToken(
        token_offset = Int32(enum.offset !== nothing ? enum.offset : offset),
        token_size = Int32(size),
        field_id = Int32(-1),
        token_version = Int32(enum.since_version),
        component_token_count = Int32(length(enum.values)),
        signal = IR.BEGIN_ENUM,
        name = enum.name,
        description = enum.description,
        semantic_type = enum.semantic_type !== nothing ? enum.semantic_type : "",
        referenced_name = enum.encoding_type
    ))
    
    # Add VALID_VALUE tokens
    for value in enum.values
        push!(tokens, IR.IRToken(
            field_id = Int32(-1),
            token_version = Int32(value.since_version),
            signal = IR.VALID_VALUE,
            name = value.name,
            const_value = value.value,
            description = value.description
        ))
    end
    
    # END_ENUM token
    push!(tokens, IR.IRToken(
        signal = IR.END_ENUM,
        name = enum.name
    ))
end

"""
Add tokens for a set type
"""
function add_set_tokens!(tokens::Vector{IR.IRToken}, set::Schema.SetType, schema::Schema.MessageSchema, offset::Int = 0)
    # Get the encoding type
    encoding_type_def = find_type(schema, set.encoding_type)
    size = encoding_type_def !== nothing ? get_type_size(encoding_type_def, schema) : 0
    
    # BEGIN_SET token
    push!(tokens, IR.IRToken(
        token_offset = Int32(set.offset !== nothing ? set.offset : offset),
        token_size = Int32(size),
        field_id = Int32(-1),
        token_version = Int32(set.since_version),
        component_token_count = Int32(length(set.choices)),
        signal = IR.BEGIN_SET,
        name = set.name,
        description = set.description,
        semantic_type = set.semantic_type !== nothing ? set.semantic_type : "",
        referenced_name = set.encoding_type
    ))
    
    # Add CHOICE tokens
    for choice in set.choices
        push!(tokens, IR.IRToken(
            field_id = Int32(-1),
            token_version = Int32(choice.since_version),
            signal = IR.CHOICE,
            name = choice.name,
            const_value = string(choice.bit_position),
            description = choice.description
        ))
    end
    
    # END_SET token
    push!(tokens, IR.IRToken(
        signal = IR.END_SET,
        name = set.name
    ))
end

"""
Add tokens for a message
"""
function add_message_tokens!(tokens::Vector{IR.IRToken}, message::Schema.MessageDefinition, schema::Schema.MessageSchema)
    # Calculate block length
    block_length = if message.block_length !== nothing
        parse(Int32, message.block_length)
    else
        Int32(sum(get_field_size(schema, f) for f in message.fields; init=0))
    end
    
    # BEGIN_MESSAGE token
    push!(tokens, IR.IRToken(
        token_offset = Int32(0),
        token_size = block_length,
        field_id = Int32(message.id),
        token_version = Int32(message.since_version),
        component_token_count = Int32(length(message.fields) + length(message.groups) + length(message.var_data)),
        signal = IR.BEGIN_MESSAGE,
        name = message.name,
        description = message.description,
        semantic_type = message.semantic_type !== nothing ? message.semantic_type : ""
    ))
    
    # Add field tokens
    for field in message.fields
        add_field_tokens!(tokens, field, schema)
    end
    
    # Add group tokens
    for group in message.groups
        add_group_tokens!(tokens, group, schema)
    end
    
    # Add var data tokens
    for var_data in message.var_data
        add_var_data_tokens!(tokens, var_data, schema)
    end
    
    # END_MESSAGE token
    push!(tokens, IR.IRToken(
        signal = IR.END_MESSAGE,
        name = message.name
    ))
end

"""
Add tokens for a field
"""
function add_field_tokens!(tokens::Vector{IR.IRToken}, field::Schema.FieldDefinition, schema::Schema.MessageSchema)
    # Try to find type in schema types
    type_def = find_type(schema, field.type_ref)
    
    # If not found, it might be a primitive type - create a virtual EncodedType
    if type_def === nothing
        # Check if it's a valid primitive type
        if field.type_ref in ["char", "int8", "uint8", "int16", "uint16", "int32", "uint32", "int64", "uint64", "float", "double"]
            # Create a virtual EncodedType for this primitive
            # Constructor: name, primitive_type, length, null_value, min_value, max_value, 
            #              character_encoding, offset, presence, constant_value, semantic_type, 
            #              description, since_version, deprecated
            type_def = Schema.EncodedType(
                field.name,  # name
                field.type_ref,  # primitive_type
                1,  # length
                nothing,  # null_value
                nothing,  # min_value
                nothing,  # max_value
                nothing,  # character_encoding
                field.offset,  # offset
                "required",  # presence
                nothing,  # constant_value
                field.semantic_type,  # semantic_type
                "",  # description
                field.since_version,  # since_version
                nothing  # deprecated
            )
        else
            error("Type not found: $(field.type_ref)")
        end
    end
    
    # BEGIN_FIELD token
    push!(tokens, IR.IRToken(
        token_offset = Int32(field.offset),
        field_id = Int32(field.id),
        token_version = Int32(field.since_version),
        signal = IR.BEGIN_FIELD,
        name = field.name,
        description = field.description,
        semantic_type = field.semantic_type !== nothing ? field.semantic_type : ""
    ))
    
    # Add type-specific tokens
    if type_def isa Schema.EncodedType
        add_encoded_type_token!(tokens, type_def, field.offset, schema)
    elseif type_def isa Schema.CompositeType
        # For composite fields, reference the composite type
        push!(tokens, IR.IRToken(
            token_offset = Int32(field.offset),
            field_id = Int32(-1),
            signal = IR.ENCODING,
            referenced_name = field.type_ref
        ))
    elseif type_def isa Schema.EnumType
        # For enum fields, reference the enum type
        push!(tokens, IR.IRToken(
            token_offset = Int32(field.offset),
            field_id = Int32(-1),
            signal = IR.ENCODING,
            referenced_name = field.type_ref
        ))
    elseif type_def isa Schema.SetType
        # For set fields, reference the set type
        push!(tokens, IR.IRToken(
            token_offset = Int32(field.offset),
            field_id = Int32(-1),
            signal = IR.ENCODING,
            referenced_name = field.type_ref
        ))
    end
    
    # END_FIELD token
    push!(tokens, IR.IRToken(
        signal = IR.END_FIELD,
        name = field.name
    ))
end

"""
Add tokens for a group
"""
function add_group_tokens!(tokens::Vector{IR.IRToken}, group::Schema.GroupDefinition, schema::Schema.MessageSchema)
    # Calculate block length
    block_length = if group.block_length !== nothing
        parse(Int32, group.block_length)
    else
        Int32(sum(get_field_size(schema, f) for f in group.fields; init=0))
    end
    
    # BEGIN_GROUP token
    push!(tokens, IR.IRToken(
        token_size = block_length,
        field_id = Int32(group.id),
        token_version = Int32(group.since_version),
        component_token_count = Int32(length(group.fields) + length(group.groups) + length(group.var_data)),
        signal = IR.BEGIN_GROUP,
        name = group.name,
        description = group.description,
        semantic_type = group.semantic_type !== nothing ? group.semantic_type : "",
        referenced_name = group.dimension_type
    ))
    
    # Add field tokens
    for field in group.fields
        add_field_tokens!(tokens, field, schema)
    end
    
    # Add nested group tokens
    for nested_group in group.groups
        add_group_tokens!(tokens, nested_group, schema)
    end
    
    # Add var data tokens
    for var_data in group.var_data
        add_var_data_tokens!(tokens, var_data, schema)
    end
    
    # END_GROUP token
    push!(tokens, IR.IRToken(
        signal = IR.END_GROUP,
        name = group.name
    ))
end

"""
Add tokens for variable-length data
"""
function add_var_data_tokens!(tokens::Vector{IR.IRToken}, var_data::Schema.VarDataDefinition, schema::Schema.MessageSchema)
    # BEGIN_VAR_DATA token
    push!(tokens, IR.IRToken(
        field_id = Int32(var_data.id),
        token_version = Int32(var_data.since_version),
        signal = IR.BEGIN_VAR_DATA,
        name = var_data.name,
        description = var_data.description,
        semantic_type = var_data.semantic_type !== nothing ? var_data.semantic_type : "",
        character_encoding = var_data.character_encoding !== nothing ? var_data.character_encoding : "",
        referenced_name = var_data.type_ref
    ))
    
    # END_VAR_DATA token
    push!(tokens, IR.IRToken(
        signal = IR.END_VAR_DATA,
        name = var_data.name
    ))
end

# Helper functions

"""
Convert primitive type name to IR enum
"""
function primitive_type_to_ir(primitive_type::String)
    mapping = Dict(
        "char" => IR.PT_CHAR,
        "int8" => IR.PT_INT8,
        "int16" => IR.PT_INT16,
        "int32" => IR.PT_INT32,
        "int64" => IR.PT_INT64,
        "uint8" => IR.PT_UINT8,
        "uint16" => IR.PT_UINT16,
        "uint32" => IR.PT_UINT32,
        "uint64" => IR.PT_UINT64,
        "float" => IR.PT_FLOAT,
        "double" => IR.PT_DOUBLE
    )
    get(mapping, lowercase(primitive_type), IR.PT_NONE)
end

"""
Convert presence string to IR enum
"""
function presence_to_ir(presence::String)
    mapping = Dict(
        "required" => IR.SBE_REQUIRED,
        "optional" => IR.SBE_OPTIONAL,
        "constant" => IR.SBE_CONSTANT
    )
    get(mapping, lowercase(presence), IR.SBE_REQUIRED)
end

"""
Find a type definition by name
"""
function find_type(schema::Schema.MessageSchema, type_name::String)
    for type_def in schema.types
        if type_def isa Schema.EncodedType && type_def.name == type_name
            return type_def
        elseif type_def isa Schema.CompositeType && type_def.name == type_name
            return type_def
        elseif type_def isa Schema.EnumType && type_def.name == type_name
            return type_def
        elseif type_def isa Schema.SetType && type_def.name == type_name
            return type_def
        end
    end
    return nothing
end

"""
Get the size of a type in bytes
"""
function get_type_size(type_def::Schema.EncodedType, schema::Schema.MessageSchema)
    julia_type = to_julia_type(type_def.primitive_type)
    return sizeof(julia_type) * type_def.length
end

function get_ref_type_size(ref::Schema.RefType, schema::Schema.MessageSchema)
    type_def = find_type(schema, ref.type_ref)
    if type_def === nothing
        return 0
    end
    if type_def isa Schema.EncodedType
        return get_type_size(type_def, schema)
    elseif type_def isa Schema.CompositeType
        return calculate_composite_size(type_def, schema)
    elseif type_def isa Schema.EnumType
        return get_enum_size(type_def, schema)
    elseif type_def isa Schema.SetType
        return get_set_size(type_def, schema)
    end
    return 0
end

function get_enum_size(enum::Schema.EnumType, schema::Schema.MessageSchema)
    encoding_type = find_type(schema, enum.encoding_type)
    if encoding_type !== nothing && encoding_type isa Schema.EncodedType
        return get_type_size(encoding_type, schema)
    end
    return 0
end

function get_set_size(set::Schema.SetType, schema::Schema.MessageSchema)
    encoding_type = find_type(schema, set.encoding_type)
    if encoding_type !== nothing && encoding_type isa Schema.EncodedType
        return get_type_size(encoding_type, schema)
    end
    return 0
end

# Note: to_julia_type, get_field_size, and calculate_composite_size
# are defined in codegen_utils.jl which is included after this file
# in SBE.jl, so they will be available when these functions are called
