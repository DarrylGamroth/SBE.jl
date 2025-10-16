"""
XML Parser for SBE Schema Files

This module provides functionality to parse SBE XML schema definitions
according to the SBE specification.
"""

using EzXML: parsexml, root, nodename, haskey, findall, eachelement, nodecontent

"""
    parse_sbe_schema(xml_content::String) -> Schema.MessageSchema

Parse SBE XML schema content and return a structured representation.
"""
function parse_sbe_schema(xml_content::String)
    doc = parsexml(xml_content)
    root = EzXML.root(doc)
    
    # Validate root element
    if nodename(root) != "messageSchema"
        error("Expected root element 'messageSchema', got '$(nodename(root))'")
    end
    
    # Extract schema attributes
    schema_id = parse(UInt16, root["id"])
    version = parse(UInt16, root["version"])
    semantic_version = haskey(root, "semanticVersion") ? root["semanticVersion"] : ""
    package_name = haskey(root, "package") ? root["package"] : ""
    byte_order = haskey(root, "byteOrder") ? root["byteOrder"] : "littleEndian"
    header_type = haskey(root, "headerType") ? root["headerType"] : "messageHeader"
    description = haskey(root, "description") ? root["description"] : ""
    
    # Parse types and messages
    types = parse_types(root)
    messages = parse_messages(root)
    
    # Create preliminary schema to enable field size lookups
    schema = Schema.MessageSchema(
        schema_id,
        version,
        semantic_version,
        package_name,
        byte_order,
        header_type,
        description,
        types,
        messages
    )
    
    # Auto-calculate field offsets for any fields without explicit offsets
    calculate_field_offsets!(schema)
    
    return schema
end

function parse_types(root::EzXML.Node)
    types = Schema.AbstractTypeDefinition[]
    
    for types_element in findall("types", root)
        for child in eachelement(types_element)
            if nodename(child) == "type"
                push!(types, parse_encoded_type(child))
            elseif nodename(child) == "composite"
                push!(types, parse_composite_type(child))
            elseif nodename(child) == "enum"
                push!(types, parse_enum_type(child))
            elseif nodename(child) == "set"
                push!(types, parse_set_type(child))
            end
        end
    end
    
    return types
end

function parse_encoded_type(node::EzXML.Node)
    name = node["name"]
    primitive_type = node["primitiveType"]
    presence = haskey(node, "presence") ? node["presence"] : "required"
    
    # Extract constant value if presence="constant"
    constant_value = nothing
    if presence == "constant"
        text = EzXML.nodecontent(node)
        if !isempty(strip(text))
            constant_value = strip(text)
        end
    end
    
    # For constant char arrays, infer length from constant value if not specified
    if haskey(node, "length")
        length = parse(Int, node["length"])
    elseif presence == "constant" && primitive_type == "char" && constant_value !== nothing
        length = Base.length(constant_value)
    else
        length = 1
    end
    
    null_value = haskey(node, "nullValue") ? node["nullValue"] : nothing
    min_value = haskey(node, "minValue") ? node["minValue"] : nothing
    max_value = haskey(node, "maxValue") ? node["maxValue"] : nothing
    character_encoding = haskey(node, "characterEncoding") ? node["characterEncoding"] : nothing
    offset = haskey(node, "offset") ? parse(Int, node["offset"]) : nothing
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    description = haskey(node, "description") ? node["description"] : ""
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = haskey(node, "deprecated") ? node["deprecated"] : nothing
    
    return Schema.EncodedType(
        name, primitive_type, length, null_value, min_value, max_value,
        character_encoding, offset, presence, constant_value, semantic_type, description,
        since_version, deprecated
    )
end

function parse_composite_type(node::EzXML.Node)
    name = node["name"]
    offset = haskey(node, "offset") ? parse(Int, node["offset"]) : nothing
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    description = haskey(node, "description") ? node["description"] : ""
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = haskey(node, "deprecated") ? node["deprecated"] : nothing

    members = Schema.AbstractTypeDefinition[]

    for child in eachelement(node)
        if nodename(child) == "type"
            push!(members, parse_encoded_type(child))
        elseif nodename(child) == "ref"
            push!(members, parse_ref_type(child))
        elseif nodename(child) == "enum"
            push!(members, parse_enum_type(child))
        elseif nodename(child) == "set"
            push!(members, parse_set_type(child))
        elseif nodename(child) == "composite"
            push!(members, parse_composite_type(child))
        end
    end

    return Schema.CompositeType(name, members, offset, semantic_type, description, since_version, deprecated)
end

function parse_enum_type(node::EzXML.Node)
    name = node["name"]
    encoding_type = node["encodingType"]
    offset = haskey(node, "offset") ? parse(Int, node["offset"]) : nothing
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    description = haskey(node, "description") ? node["description"] : ""
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = haskey(node, "deprecated") ? node["deprecated"] : nothing

    values = Schema.ValidValue[]
    for value_node in findall("validValue", node)
        value_name = value_node["name"]
        value_content = nodecontent(value_node)
        value_description = haskey(value_node, "description") ? value_node["description"] : ""
        value_since_version = parse(Int, haskey(value_node, "sinceVersion") ? value_node["sinceVersion"] : "0")
        value_deprecated = haskey(value_node, "deprecated") ? value_node["deprecated"] : nothing
        
        push!(values, Schema.ValidValue(value_name, value_content, value_description, value_since_version, value_deprecated))
    end

    return Schema.EnumType(name, encoding_type, values, offset, semantic_type, description, since_version, deprecated)
end

function parse_set_type(node::EzXML.Node)
    name = node["name"]
    encoding_type = node["encodingType"]
    offset = haskey(node, "offset") ? parse(Int, node["offset"]) : nothing
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    description = haskey(node, "description") ? node["description"] : ""
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = haskey(node, "deprecated") ? node["deprecated"] : nothing
    
    choices = Schema.Choice[]
    
    for choice_node in findall("choice", node)
        choice_name = choice_node["name"]
        bit_position = parse(Int, nodecontent(choice_node))
        choice_description = haskey(choice_node, "description") ? choice_node["description"] : ""
        choice_since_version = parse(Int, haskey(choice_node, "sinceVersion") ? choice_node["sinceVersion"] : "0")
        choice_deprecated = haskey(choice_node, "deprecated") ? choice_node["deprecated"] : nothing
        
        push!(choices, Schema.Choice(choice_name, bit_position, choice_description, choice_since_version, choice_deprecated))
    end
    
    return Schema.SetType(name, encoding_type, choices, offset, semantic_type, description, since_version, deprecated)
end

function parse_ref_type(node::EzXML.Node)
    name = node["name"]
    type_ref = node["type"]
    offset = parse(Int, haskey(node, "offset") ? node["offset"] : "0")
    
    return Schema.RefType(name, type_ref, offset)
end

function parse_messages(root::EzXML.Node)
    messages = Schema.MessageDefinition[]
    
    # Try both with and without namespace
    for xpath in ["message", "sbe:message", ".//message", ".//sbe:message"]
        message_nodes = findall(xpath, root)
        if !isempty(message_nodes)
            for message_node in message_nodes
                name = message_node["name"]
                id = parse(UInt16, message_node["id"])
                block_length = haskey(message_node, "blockLength") ? message_node["blockLength"] : nothing
                description = haskey(message_node, "description") ? message_node["description"] : ""
                since_version = parse(Int, haskey(message_node, "sinceVersion") ? message_node["sinceVersion"] : "0")
                semantic_type = haskey(message_node, "semanticType") ? message_node["semanticType"] : nothing
                deprecated = haskey(message_node, "deprecated") ? message_node["deprecated"] : nothing
                
                fields = parse_fields(message_node)
                groups = parse_groups(message_node)
                var_data = parse_var_data(message_node)
                
                push!(messages, Schema.MessageDefinition(
                    name, id, block_length, description, since_version, semantic_type, deprecated,
                    fields, groups, var_data
                ))
            end
            break  # Stop after finding messages with the first working xpath
        end
    end
    
    return messages
end

function parse_fields(node::EzXML.Node)
    fields = Schema.FieldDefinition[]
    
    for field_node in findall("field", node)
        name = field_node["name"]
        id = parse(UInt16, field_node["id"])
        type_ref = field_node["type"]
        # Default to 0 if not specified - will be auto-calculated later
        offset = parse(Int, haskey(field_node, "offset") ? field_node["offset"] : "0")
        description = haskey(field_node, "description") ? field_node["description"] : ""
        since_version = parse(Int, haskey(field_node, "sinceVersion") ? field_node["sinceVersion"] : "0")
        presence = haskey(field_node, "presence") ? field_node["presence"] : "required"
        value_ref = haskey(field_node, "valueRef") ? field_node["valueRef"] : nothing
        epoch = haskey(field_node, "epoch") ? field_node["epoch"] : "unix"
        time_unit = haskey(field_node, "timeUnit") ? field_node["timeUnit"] : nothing
        semantic_type = haskey(field_node, "semanticType") ? field_node["semanticType"] : nothing
        deprecated = haskey(field_node, "deprecated") ? field_node["deprecated"] : nothing
        
        push!(fields, Schema.FieldDefinition(
            name, id, type_ref, offset, description, since_version, 
            presence, value_ref, epoch, time_unit, semantic_type, deprecated
        ))
    end
    
    return fields
end

function parse_groups(node::EzXML.Node)
    groups = Schema.GroupDefinition[]
    
    for group_node in findall("group", node)
        name = group_node["name"]
        id = parse(UInt16, group_node["id"])
        block_length = haskey(group_node, "blockLength") ? group_node["blockLength"] : nothing
        dimension_type = haskey(group_node, "dimensionType") ? group_node["dimensionType"] : "groupSizeEncoding"
        description = haskey(group_node, "description") ? group_node["description"] : ""
        since_version = parse(Int, haskey(group_node, "sinceVersion") ? group_node["sinceVersion"] : "0")
        semantic_type = haskey(group_node, "semanticType") ? group_node["semanticType"] : nothing
        deprecated = haskey(group_node, "deprecated") ? group_node["deprecated"] : nothing
        
        fields = parse_fields(group_node)
        nested_groups = parse_groups(group_node)  # Fixed: use nested_groups to avoid shadowing
        var_data = parse_var_data(group_node)
        
        push!(groups, Schema.GroupDefinition(
            name, id, block_length, dimension_type, description, since_version, semantic_type, deprecated,
            fields, nested_groups, var_data  # Fixed: pass nested_groups instead of groups
        ))
    end
    
    return groups
end

function parse_var_data(node::EzXML.Node)
    var_data = Schema.VarDataDefinition[]
    
    for data_node in findall("data", node)
        name = data_node["name"]
        id = parse(UInt16, data_node["id"])
        type_ref = data_node["type"]
        description = haskey(data_node, "description") ? data_node["description"] : ""
        since_version = parse(Int, haskey(data_node, "sinceVersion") ? data_node["sinceVersion"] : "0")
        character_encoding = haskey(data_node, "characterEncoding") ? data_node["characterEncoding"] : nothing
        semantic_type = haskey(data_node, "semanticType") ? data_node["semanticType"] : nothing
        deprecated = haskey(data_node, "deprecated") ? data_node["deprecated"] : nothing
        
        push!(var_data, Schema.VarDataDefinition(
            name, id, type_ref, description, since_version, character_encoding, semantic_type, deprecated
        ))
    end
    
    return var_data
end

"""
    calculate_field_offsets!(schema::Schema.MessageSchema)

Auto-calculate field offsets for any fields that don't have explicit offsets.
According to SBE spec, fields are laid out sequentially if offsets are not specified.
If the first field has offset 0 and no explicit offsets are in the XML, we auto-calculate.
"""
function calculate_field_offsets!(schema::Schema.MessageSchema)
    for (msg_idx, message) in enumerate(schema.messages)
        # Check if we need to auto-calculate (first field offset is 0 means no explicit offsets in XML)
        if !isempty(message.fields) && message.fields[1].offset == 0
            new_fields = Schema.FieldDefinition[]
            current_offset = 0
            for field in message.fields
                # Create new field with calculated offset
                field_def = Schema.FieldDefinition(
                    field.name, field.id, field.type_ref, current_offset,
                    field.description, field.since_version, field.presence,
                    field.value_ref, field.epoch, field.time_unit,
                    field.semantic_type, field.deprecated
                )
                push!(new_fields, field_def)
                # Update offset for next field
                current_offset += get_field_size(schema, field_def)
            end
            
            # Replace message with updated fields
            schema.messages[msg_idx] = Schema.MessageDefinition(
                message.name, message.id, message.block_length, message.description,
                message.since_version, message.semantic_type, message.deprecated,
                new_fields, message.groups, message.var_data
            )
        end
    end
    
    # Also calculate offsets for group fields
    for message in schema.messages
        for (grp_idx, group) in enumerate(message.groups)
            if !isempty(group.fields) && group.fields[1].offset == 0
                new_fields = Schema.FieldDefinition[]
                current_offset = 0
                for field in group.fields
                    field_def = Schema.FieldDefinition(
                        field.name, field.id, field.type_ref, current_offset,
                        field.description, field.since_version, field.presence,
                        field.value_ref, field.epoch, field.time_unit,
                        field.semantic_type, field.deprecated
                    )
                    push!(new_fields, field_def)
                    current_offset += get_field_size(schema, field_def)
                end
                
                # Replace group with updated fields
                message.groups[grp_idx] = Schema.GroupDefinition(
                    group.name, group.id, group.block_length, group.dimension_type,
                    group.description, group.since_version, group.semantic_type,
                    group.deprecated, new_fields, group.groups, group.var_data
                )
            end
        end
    end
end
