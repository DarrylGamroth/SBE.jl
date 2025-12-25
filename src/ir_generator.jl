"""
XML -> IR generator.

This ports the reference IrGenerator behavior to Julia, using EzXML for parsing.
"""

using EzXML: parsexml, root, nodename, haskey, findall, eachelement, nodecontent

abstract type XmlType end

mutable struct XmlEncodedType <: XmlType
    name::String
    package_name::Union{Nothing, String}
    referenced_name::Union{Nothing, String}
    presence::IR.Presence.T
    description::String
    semantic_type::Union{Nothing, String}
    primitive_type::IR.PrimitiveType.T
    length::Int
    variable_length::Bool
    min_value::Union{Nothing, IR.PrimitiveValue}
    max_value::Union{Nothing, IR.PrimitiveValue}
    null_value::Union{Nothing, IR.PrimitiveValue}
    const_value::Union{Nothing, IR.PrimitiveValue}
    value_ref::Union{Nothing, String}
    character_encoding::Union{Nothing, String}
    offset_attribute::Int
    since_version::Int
    deprecated::Int
end

mutable struct XmlCompositeType <: XmlType
    name::String
    package_name::Union{Nothing, String}
    referenced_name::Union{Nothing, String}
    presence::IR.Presence.T
    description::String
    semantic_type::Union{Nothing, String}
    offset_attribute::Int
    since_version::Int
    deprecated::Int
    members::Vector{XmlType}
    member_by_name::Dict{String, XmlType}
end

mutable struct XmlValidValue
    name::String
    description::String
    since_version::Int
    deprecated::Int
    primitive_value::IR.PrimitiveValue
end

mutable struct XmlEnumType <: XmlType
    name::String
    package_name::Union{Nothing, String}
    referenced_name::Union{Nothing, String}
    presence::IR.Presence.T
    description::String
    semantic_type::Union{Nothing, String}
    encoding_type::IR.PrimitiveType.T
    valid_values::Vector{XmlValidValue}
    offset_attribute::Int
    since_version::Int
    deprecated::Int
    null_value::Union{Nothing, IR.PrimitiveValue}
end

mutable struct XmlChoice
    name::String
    description::String
    since_version::Int
    deprecated::Int
    primitive_value::IR.PrimitiveValue
end

mutable struct XmlSetType <: XmlType
    name::String
    package_name::Union{Nothing, String}
    referenced_name::Union{Nothing, String}
    presence::IR.Presence.T
    description::String
    semantic_type::Union{Nothing, String}
    encoding_type::IR.PrimitiveType.T
    choices::Vector{XmlChoice}
    offset_attribute::Int
    since_version::Int
    deprecated::Int
end

mutable struct XmlField
    name::String
    id::Int
    type_def::Union{Nothing, XmlType}
    offset::Int
    computed_offset::Int
    description::String
    since_version::Int
    presence::IR.Presence.T
    value_ref::Union{Nothing, String}
    epoch::Union{Nothing, String}
    time_unit::Union{Nothing, String}
    semantic_type::Union{Nothing, String}
    deprecated::Int
    dimension_type::Union{Nothing, XmlCompositeType}
    block_length::Int
    computed_block_length::Int
    group_fields::Union{Nothing, Vector{XmlField}}
    variable_length::Bool
end

mutable struct XmlMessage
    name::String
    id::Int
    block_length::Int
    computed_block_length::Int
    description::String
    since_version::Int
    semantic_type::Union{Nothing, String}
    deprecated::Int
    fields::Vector{XmlField}
end

mutable struct XmlMessageSchema
    package_name::String
    description::String
    id::Int
    version::Int
    semantic_version::String
    byte_order::Symbol
    header_type::String
    types_by_name::Dict{String, XmlType}
    messages::Vector{XmlMessage}
end

function parse_presence(value::Union{Nothing, String})
    if value === nothing
        return IR.Presence.REQUIRED
    end
    if value == "optional"
        return IR.Presence.OPTIONAL
    elseif value == "constant"
        return IR.Presence.CONSTANT
    end
    return IR.Presence.REQUIRED
end

function parse_primitive_type(value::String)
    mapping = Dict(
        "char" => IR.PrimitiveType.CHAR,
        "int8" => IR.PrimitiveType.INT8,
        "int16" => IR.PrimitiveType.INT16,
        "int32" => IR.PrimitiveType.INT32,
        "int64" => IR.PrimitiveType.INT64,
        "uint8" => IR.PrimitiveType.UINT8,
        "uint16" => IR.PrimitiveType.UINT16,
        "uint32" => IR.PrimitiveType.UINT32,
        "uint64" => IR.PrimitiveType.UINT64,
        "float" => IR.PrimitiveType.FLOAT,
        "double" => IR.PrimitiveType.DOUBLE
    )
    return get(mapping, value, IR.PrimitiveType.NONE)
end

function primitive_value_from_text(
    value::AbstractString,
    primitive_type::IR.PrimitiveType.T,
    length::Int,
    character_encoding::Union{Nothing, String}
)
    if primitive_type == IR.PrimitiveType.FLOAT || primitive_type == IR.PrimitiveType.DOUBLE
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.DOUBLE, value, nothing, IR.primitive_type_size(primitive_type))
    elseif primitive_type == IR.PrimitiveType.CHAR && (length > 1 || ncodeunits(value) > 1)
        encoding = character_encoding === nothing ? "US-ASCII" : character_encoding
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.BYTE_ARRAY, value, encoding, length)
    else
        return IR.PrimitiveValue(IR.PrimitiveValueRepresentation.LONG, value, nothing, IR.primitive_type_size(primitive_type))
    end
end

function primitive_value_numeric(value::IR.PrimitiveValue, primitive_type::IR.PrimitiveType.T)
    if value.representation == IR.PrimitiveValueRepresentation.DOUBLE
        return parse(Float64, value.value)
    end
    if primitive_type == IR.PrimitiveType.CHAR
        text = value.value
        if isempty(text)
            return 0
        end
        if all(isdigit, text) || startswith(text, "0x") || startswith(text, "-")
            return parse(Int64, text)
        end
        return Int64(codeunit(text, 1))
    end
    return parse(Int64, value.value)
end

function validate_enum_values!(
    enum_name::String,
    encoding_type::IR.PrimitiveType.T,
    min_value::Union{Nothing, IR.PrimitiveValue},
    max_value::Union{Nothing, IR.PrimitiveValue},
    null_value::Union{Nothing, IR.PrimitiveValue},
    presence::IR.Presence.T,
    values::Vector{XmlValidValue}
)
    if min_value !== nothing || max_value !== nothing
        min_num = min_value === nothing ? -Inf : primitive_value_numeric(min_value, encoding_type)
        max_num = max_value === nothing ? Inf : primitive_value_numeric(max_value, encoding_type)
        for value in values
            num = primitive_value_numeric(value.primitive_value, encoding_type)
            if num < min_num || num > max_num
                error("enum value out of range: $(enum_name).$(value.name)")
            end
        end
        if null_value !== nothing
            null_num = primitive_value_numeric(null_value, encoding_type)
            if null_num < min_num || null_num > max_num
                error("enum null value out of range: $(enum_name)")
            end
        end
    end

    if presence == IR.Presence.OPTIONAL && null_value !== nothing
        null_num = primitive_value_numeric(null_value, encoding_type)
        for value in values
            if primitive_value_numeric(value.primitive_value, encoding_type) == null_num
                error("enum null value collides with valid value: $(enum_name).$(value.name)")
            end
        end
    end
end

function encoded_length(type_def::XmlType)
    if type_def isa XmlEncodedType
        type_def.presence == IR.Presence.CONSTANT && return 0
        type_def.variable_length && return IR.VARIABLE_LENGTH
        return IR.primitive_type_size(type_def.primitive_type) * type_def.length
    elseif type_def isa XmlCompositeType
        length = 0
        for member in type_def.members
            member_length = encoded_length(member)
            if member_length == IR.VARIABLE_LENGTH
                return IR.VARIABLE_LENGTH
            end
            if member isa XmlEncodedType && member.offset_attribute != -1
                length = member.offset_attribute
            elseif member isa XmlEnumType && member.offset_attribute != -1
                length = member.offset_attribute
            elseif member isa XmlSetType && member.offset_attribute != -1
                length = member.offset_attribute
            elseif member isa XmlCompositeType && member.offset_attribute != -1
                length = member.offset_attribute
            end
            if member isa XmlEncodedType && member.presence == IR.Presence.CONSTANT
                continue
            end
            length += member_length
        end
        return length
    elseif type_def isa XmlEnumType
        return IR.primitive_type_size(type_def.encoding_type)
    elseif type_def isa XmlSetType
        return IR.primitive_type_size(type_def.encoding_type)
    end
    return 0
end

function make_data_field_composite_type!(composite::XmlCompositeType)
    var_data = get(composite.member_by_name, "varData", nothing)
    if var_data isa XmlEncodedType
        var_data.variable_length = true
    end
end

function parse_encoded_type(
    node,
    package_name::Union{Nothing, String},
    given_name::Union{Nothing, String}=nothing,
    referenced_name::Union{Nothing, String}=nothing
)
    name = given_name === nothing ? node["name"] : given_name
    primitive_type = parse_primitive_type(node["primitiveType"])
    presence = parse_presence(haskey(node, "presence") ? node["presence"] : nothing)
    description = haskey(node, "description") ? node["description"] : ""
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    offset_attribute = parse(Int, haskey(node, "offset") ? node["offset"] : "-1")
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0")
    character_encoding = haskey(node, "characterEncoding") ? node["characterEncoding"] : nothing

    length_attr = haskey(node, "length") ? node["length"] : nothing
    length = length_attr === nothing ? 1 : parse(Int, length_attr)
    variable_length = haskey(node, "variableLength") ? (node["variableLength"] == "true") : false

    const_value = nothing
    value_ref = haskey(node, "valueRef") ? node["valueRef"] : nothing
    if presence == IR.Presence.CONSTANT
        text = strip(nodecontent(node))
        if !isempty(text)
            if length_attr === nothing && primitive_type == IR.PrimitiveType.CHAR
                length = ncodeunits(text)
            end
            const_value = primitive_value_from_text(text, primitive_type, length, character_encoding)
        end
    end

    min_value = haskey(node, "minValue") ? primitive_value_from_text(node["minValue"], primitive_type, length, character_encoding) : nothing
    max_value = haskey(node, "maxValue") ? primitive_value_from_text(node["maxValue"], primitive_type, length, character_encoding) : nothing
    null_value = haskey(node, "nullValue") ? primitive_value_from_text(node["nullValue"], primitive_type, length, character_encoding) : nothing

    return XmlEncodedType(
        name,
        package_name,
        referenced_name,
        presence,
        description,
        semantic_type,
        primitive_type,
        length,
        variable_length,
        min_value,
        max_value,
        null_value,
        const_value,
        value_ref,
        character_encoding,
        offset_attribute,
        since_version,
        deprecated
    )
end

function parse_enum_type(
    node,
    package_name::Union{Nothing, String},
    type_nodes_by_name::Union{Nothing, Dict{String, EzXML.Node}}=nothing,
    given_name::Union{Nothing, String}=nothing,
    referenced_name::Union{Nothing, String}=nothing
)
    name = given_name === nothing ? node["name"] : given_name
    encoding_type_name = node["encodingType"]
    encoding_type = parse_primitive_type(encoding_type_name)
    ref_null_value = nothing
    ref_min_value = nothing
    ref_max_value = nothing
    if encoding_type == IR.PrimitiveType.NONE && type_nodes_by_name !== nothing
        ref_node = get(type_nodes_by_name, encoding_type_name, nothing)
        if ref_node !== nothing && nodename(ref_node) == "type"
            encoding_type = parse_primitive_type(ref_node["primitiveType"])
            ref_null_value = haskey(ref_node, "nullValue") ? ref_node["nullValue"] : nothing
            ref_min_value = haskey(ref_node, "minValue") ? ref_node["minValue"] : nothing
            ref_max_value = haskey(ref_node, "maxValue") ? ref_node["maxValue"] : nothing
        end
    end
    presence = parse_presence(haskey(node, "presence") ? node["presence"] : nothing)
    description = haskey(node, "description") ? node["description"] : ""
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    offset_attribute = parse(Int, haskey(node, "offset") ? node["offset"] : "-1")
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0")
    null_value = if haskey(node, "nullValue")
        primitive_value_from_text(node["nullValue"], encoding_type, 1, nothing)
    elseif ref_null_value !== nothing
        primitive_value_from_text(ref_null_value, encoding_type, 1, nothing)
    else
        IR.primitive_type_null(encoding_type)
    end
    min_value = if haskey(node, "minValue")
        primitive_value_from_text(node["minValue"], encoding_type, 1, nothing)
    elseif ref_min_value !== nothing
        primitive_value_from_text(ref_min_value, encoding_type, 1, nothing)
    else
        nothing
    end
    max_value = if haskey(node, "maxValue")
        primitive_value_from_text(node["maxValue"], encoding_type, 1, nothing)
    elseif ref_max_value !== nothing
        primitive_value_from_text(ref_max_value, encoding_type, 1, nothing)
    else
        nothing
    end

    values = XmlValidValue[]
    for value_node in findall("validValue", node)
        value_name = value_node["name"]
        value_text = strip(nodecontent(value_node))
        value_desc = haskey(value_node, "description") ? value_node["description"] : ""
        value_since = parse(Int, haskey(value_node, "sinceVersion") ? value_node["sinceVersion"] : "0")
        value_deprecated = parse(Int, haskey(value_node, "deprecated") ? value_node["deprecated"] : "0")
        primitive_value = primitive_value_from_text(value_text, encoding_type, 1, nothing)
        push!(values, XmlValidValue(value_name, value_desc, value_since, value_deprecated, primitive_value))
    end

    validate_enum_values!(name, encoding_type, min_value, max_value, null_value, presence, values)

    return XmlEnumType(
        name,
        package_name,
        referenced_name,
        presence,
        description,
        semantic_type,
        encoding_type,
        values,
        offset_attribute,
        since_version,
        deprecated,
        null_value
    )
end

function parse_set_type(
    node,
    package_name::Union{Nothing, String},
    type_nodes_by_name::Union{Nothing, Dict{String, EzXML.Node}}=nothing,
    given_name::Union{Nothing, String}=nothing,
    referenced_name::Union{Nothing, String}=nothing
)
    name = given_name === nothing ? node["name"] : given_name
    encoding_type_name = node["encodingType"]
    encoding_type = parse_primitive_type(encoding_type_name)
    if encoding_type == IR.PrimitiveType.NONE && type_nodes_by_name !== nothing
        ref_node = get(type_nodes_by_name, encoding_type_name, nothing)
        if ref_node !== nothing && nodename(ref_node) == "type"
            encoding_type = parse_primitive_type(ref_node["primitiveType"])
        end
    end
    presence = parse_presence(haskey(node, "presence") ? node["presence"] : nothing)
    description = haskey(node, "description") ? node["description"] : ""
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    offset_attribute = parse(Int, haskey(node, "offset") ? node["offset"] : "-1")
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0")

    choices = XmlChoice[]
    for choice_node in findall("choice", node)
        choice_name = choice_node["name"]
        choice_text = strip(nodecontent(choice_node))
        choice_desc = haskey(choice_node, "description") ? choice_node["description"] : ""
        choice_since = parse(Int, haskey(choice_node, "sinceVersion") ? choice_node["sinceVersion"] : "0")
        choice_deprecated = parse(Int, haskey(choice_node, "deprecated") ? choice_node["deprecated"] : "0")
        primitive_value = primitive_value_from_text(choice_text, encoding_type, 1, nothing)
        push!(choices, XmlChoice(choice_name, choice_desc, choice_since, choice_deprecated, primitive_value))
    end

    return XmlSetType(
        name,
        package_name,
        referenced_name,
        presence,
        description,
        semantic_type,
        encoding_type,
        choices,
        offset_attribute,
        since_version,
        deprecated
    )
end

function parse_composite_type(
    node,
    package_name::Union{Nothing, String},
    type_nodes_by_name::Dict{String, EzXML.Node},
    given_name::Union{Nothing, String}=nothing,
    referenced_name::Union{Nothing, String}=nothing,
    composites_path::Vector{String}=String[]
)
    name = given_name === nothing ? node["name"] : given_name
    presence = parse_presence(haskey(node, "presence") ? node["presence"] : nothing)
    description = haskey(node, "description") ? node["description"] : ""
    semantic_type = haskey(node, "semanticType") ? node["semanticType"] : nothing
    offset_attribute = parse(Int, haskey(node, "offset") ? node["offset"] : "-1")
    since_version = parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0")
    deprecated = parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0")

    members = XmlType[]
    member_by_name = Dict{String, XmlType}()

    for child in eachelement(node)
        child_name = nodename(child)
        if child_name == "type"
            member = parse_encoded_type(child, package_name)
        elseif child_name == "enum"
            member = parse_enum_type(child, package_name, type_nodes_by_name)
        elseif child_name == "set"
            member = parse_set_type(child, package_name, type_nodes_by_name)
        elseif child_name == "composite"
            member = parse_composite_type(child, package_name, type_nodes_by_name, nothing, nothing, [composites_path; name])
        elseif child_name == "ref"
            ref_type_name = child["type"]
            ref_name = child["name"]
            ref_node = get(type_nodes_by_name, ref_type_name, nothing)
            if ref_node === nothing
                error("ref type not found: $(ref_type_name)")
            end
            if ref_type_name in composites_path
                error("ref types cannot create circular dependencies: $(ref_type_name)")
            end
            member = parse_type_node(
                ref_node,
                type_nodes_by_name,
                ref_name,
                ref_type_name,
                [composites_path; ref_type_name]
            )
            ref_offset = haskey(child, "offset") ? child["offset"] : nothing
            if ref_offset !== nothing
                member.offset_attribute = parse(Int, ref_offset)
            end
            ref_version = haskey(child, "sinceVersion") ? child["sinceVersion"] : nothing
            if ref_version !== nothing
                member.since_version = parse(Int, ref_version)
            end
        else
            continue
        end
        member_by_name[member.name] = member
        push!(members, member)
    end

    return XmlCompositeType(
        name,
        package_name,
        referenced_name,
        presence,
        description,
        semantic_type,
        offset_attribute,
        since_version,
        deprecated,
        members,
        member_by_name
    )
end

function parse_type_node(
    node,
    type_nodes_by_name::Dict{String, EzXML.Node},
    given_name::Union{Nothing, String}=nothing,
    referenced_name::Union{Nothing, String}=nothing,
    composites_path::Vector{String}=String[]
)
    package_name = get_types_package_attribute(node)
    child_name = nodename(node)
    if child_name == "type"
        return parse_encoded_type(node, package_name, given_name, referenced_name)
    elseif child_name == "enum"
        return parse_enum_type(node, package_name, type_nodes_by_name, given_name, referenced_name)
    elseif child_name == "set"
        return parse_set_type(node, package_name, type_nodes_by_name, given_name, referenced_name)
    elseif child_name == "composite"
        return parse_composite_type(node, package_name, type_nodes_by_name, given_name, referenced_name, composites_path)
    end
    error("Unknown type node: $(child_name)")
end

function get_types_package_attribute(node)
    parent = node.parentnode
    while parent !== nothing
        if nodename(parent) == "types"
            return haskey(parent, "package") ? parent["package"] : nothing
        end
        parent = parent.parentnode
    end
    return nothing
end

function parse_xml_schema(xml_content::String)
    doc = parsexml(xml_content)
    root_node = root(doc)
    if nodename(root_node) != "messageSchema"
        error("Expected root element 'messageSchema', got '$(nodename(root_node))'")
    end

    schema_id = parse(Int, root_node["id"])
    version = parse(Int, haskey(root_node, "version") ? root_node["version"] : "0")
    semantic_version = haskey(root_node, "semanticVersion") ? root_node["semanticVersion"] : ""
    package_name = haskey(root_node, "package") ? root_node["package"] : ""
    byte_order = haskey(root_node, "byteOrder") ? Symbol(root_node["byteOrder"]) : :littleEndian
    header_type = haskey(root_node, "headerType") ? root_node["headerType"] : "messageHeader"
    description = haskey(root_node, "description") ? root_node["description"] : ""

    type_nodes_by_name = Dict{String, EzXML.Node}()
    for types_element in findall("types", root_node)
        for child in eachelement(types_element)
            if haskey(child, "name")
                type_nodes_by_name[child["name"]] = child
            end
        end
    end

    types_by_name = Dict{String, XmlType}()
    for (name, node) in type_nodes_by_name
        types_by_name[name] = parse_type_node(node, type_nodes_by_name, nothing, nothing, String[])
    end

    messages = parse_messages(root_node, types_by_name)

    return XmlMessageSchema(
        package_name,
        description,
        schema_id,
        version,
        semantic_version,
        byte_order,
        header_type,
        types_by_name,
        messages
    )
end

function parse_messages(root_node, types_by_name::Dict{String, XmlType})
    messages = XmlMessage[]
    for xpath in ["message", "sbe:message", ".//message", ".//sbe:message"]
        message_nodes = findall(xpath, root_node)
        if !isempty(message_nodes)
            for message_node in message_nodes
                push!(messages, parse_message(message_node, types_by_name))
            end
            break
        end
    end
    return messages
end

function parse_message(message_node, types_by_name::Dict{String, XmlType})
    name = message_node["name"]
    id = parse(Int, message_node["id"])
    block_length = parse(Int, haskey(message_node, "blockLength") ? message_node["blockLength"] : "0")
    description = haskey(message_node, "description") ? message_node["description"] : ""
    since_version = parse(Int, haskey(message_node, "sinceVersion") ? message_node["sinceVersion"] : "0")
    semantic_type = haskey(message_node, "semanticType") ? message_node["semanticType"] : nothing
    deprecated = parse(Int, haskey(message_node, "deprecated") ? message_node["deprecated"] : "0")

    fields = parse_message_fields(message_node, types_by_name)
    compute_and_set_offsets!(fields, block_length)
    computed_block_length = compute_message_root_block_length(fields)

    return XmlMessage(
        name,
        id,
        block_length,
        computed_block_length,
        description,
        since_version,
        semantic_type,
        deprecated,
        fields
    )
end

function parse_message_fields(node, types_by_name::Dict{String, XmlType})
    fields = XmlField[]
    for child in eachelement(node)
        child_name = nodename(child)
        if child_name == "field"
            push!(fields, parse_field(child, types_by_name))
        elseif child_name == "group"
            push!(fields, parse_group(child, types_by_name))
        elseif child_name == "data"
            push!(fields, parse_data(child, types_by_name))
        end
    end
    return fields
end

function parse_field(node, types_by_name::Dict{String, XmlType})
    type_name = node["type"]
    type_def = get(types_by_name, type_name, nothing)
    if type_def === nothing
        primitive_type = parse_primitive_type(type_name)
        primitive_type == IR.PrimitiveType.NONE && error("could not find type: $(type_name)")
        type_def = XmlEncodedType(
            type_name,
            nothing,
            nothing,
            IR.Presence.REQUIRED,
            "",
            nothing,
        primitive_type,
        1,
        false,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        0,
        0,
        0
        )
    end
    return XmlField(
        node["name"],
        parse(Int, node["id"]),
        type_def,
        parse(Int, haskey(node, "offset") ? node["offset"] : "0"),
        0,
        haskey(node, "description") ? node["description"] : "",
        parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0"),
        parse_presence(haskey(node, "presence") ? node["presence"] : nothing),
        haskey(node, "valueRef") ? node["valueRef"] : nothing,
        haskey(node, "epoch") ? node["epoch"] : nothing,
        haskey(node, "timeUnit") ? node["timeUnit"] : nothing,
        haskey(node, "semanticType") ? node["semanticType"] : nothing,
        parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0"),
        nothing,
        0,
        0,
        nothing,
        false
    )
end

function parse_group(node, types_by_name::Dict{String, XmlType})
    dimension_type_name = haskey(node, "dimensionType") ? node["dimensionType"] : "groupSizeEncoding"
    dimension_type = get(types_by_name, dimension_type_name, nothing)
    dimension_type isa XmlCompositeType || error("dimensionType must be a composite: $(dimension_type_name)")

    group_fields = parse_message_fields(node, types_by_name)
    compute_and_set_offsets!(group_fields, 0)
    group_block_length = compute_message_root_block_length(group_fields)

    return XmlField(
        node["name"],
        parse(Int, node["id"]),
        nothing,
        0,
        0,
        haskey(node, "description") ? node["description"] : "",
        parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0"),
        IR.Presence.REQUIRED,
        nothing,
        nothing,
        nothing,
        haskey(node, "semanticType") ? node["semanticType"] : nothing,
        parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0"),
        dimension_type,
        parse(Int, haskey(node, "blockLength") ? node["blockLength"] : "0"),
        group_block_length,
        group_fields,
        false
    )
end

function parse_data(node, types_by_name::Dict{String, XmlType})
    type_name = node["type"]
    type_def = get(types_by_name, type_name, nothing)
    type_def isa XmlCompositeType || error("data type is not composite: $(type_name)")
    make_data_field_composite_type!(type_def)

    return XmlField(
        node["name"],
        parse(Int, node["id"]),
        type_def,
        parse(Int, haskey(node, "offset") ? node["offset"] : "0"),
        0,
        haskey(node, "description") ? node["description"] : "",
        parse(Int, haskey(node, "sinceVersion") ? node["sinceVersion"] : "0"),
        parse_presence(haskey(node, "presence") ? node["presence"] : nothing),
        haskey(node, "valueRef") ? node["valueRef"] : nothing,
        haskey(node, "epoch") ? node["epoch"] : nothing,
        haskey(node, "timeUnit") ? node["timeUnit"] : nothing,
        haskey(node, "semanticType") ? node["semanticType"] : nothing,
        parse(Int, haskey(node, "deprecated") ? node["deprecated"] : "0"),
        nothing,
        0,
        0,
        nothing,
        true
    )
end

function compute_and_set_offsets!(fields::Vector{XmlField}, block_length::Int)
    variable_length_block = false
    offset = 0

    for field in fields
        if field.offset != 0 && field.offset < offset
            error("Offset provides insufficient space at field: $(field.name)")
        end

        if offset != IR.VARIABLE_LENGTH
            if field.offset != 0
                offset = field.offset
            elseif field.dimension_type !== nothing && block_length != 0
                offset = block_length
            elseif field.variable_length && block_length != 0
                offset = block_length
            end
        end

        field.computed_offset = variable_length_block ? IR.VARIABLE_LENGTH : offset

        if field.group_fields !== nothing
            group_block_length = compute_and_set_offsets!(field.group_fields, 0)
            field.computed_block_length = max(field.block_length, group_block_length)
            variable_length_block = true
        elseif field.type_def !== nothing && field.presence != IR.Presence.CONSTANT
            size = encoded_length(field.type_def)
            if size == IR.VARIABLE_LENGTH
                variable_length_block = true
            else
                field.computed_block_length = size
            end
            if !variable_length_block
                offset += size
            end
        end
    end

    return offset
end

function compute_message_root_block_length(fields::Vector{XmlField})
    block_length = 0
    for field in fields
        if field.group_fields !== nothing
            return block_length
        elseif field.type_def !== nothing
            field_length = encoded_length(field.type_def)
            if field_length == IR.VARIABLE_LENGTH
                return block_length
            end
            if field.presence == IR.Presence.CONSTANT
                block_length = field.computed_offset
            else
                block_length = field.computed_offset + field_length
            end
        end
    end
    return block_length
end

mutable struct IrGeneratorState
    schema::XmlMessageSchema
    tokens::Vector{IR.Token}
end

function generate_ir(schema::XmlMessageSchema)
    header_type = get(schema.types_by_name, schema.header_type, nothing)
    header_type isa XmlCompositeType || error("headerType must be a composite: $(schema.header_type)")

    state = IrGeneratorState(schema, IR.Token[])
    add_composite!(state, header_type, 0, nothing)
    header_tokens = state.tokens
    IR.update_component_token_counts!(header_tokens)

    header_structure = build_header_structure(header_tokens)
    ir = IR.Ir(
        schema.package_name,
        nothing,
        schema.id,
        schema.version,
        schema.description,
        schema.semantic_version,
        schema.byte_order,
        header_structure,
        Dict{Int, Vector{IR.Token}}(),
        Dict{String, Vector{IR.Token}}(),
        split(schema.package_name, ".")
    )

    capture_types!(ir, header_tokens)

    for message in schema.messages
        state = IrGeneratorState(schema, IR.Token[])
        add_message_signal!(state, message, IR.Signal.BEGIN_MESSAGE)
        add_all_fields!(state, message.fields)
        add_message_signal!(state, message, IR.Signal.END_MESSAGE)
        IR.update_component_token_counts!(state.tokens)
        ir.messages_by_id[message.id] = state.tokens
        capture_types!(ir, state.tokens)
    end

    return ir
end

function capture_types!(ir::IR.Ir, tokens::Vector{IR.Token}, begin_index::Int=1, end_index::Int=length(tokens))
    i = begin_index
    while i <= end_index
        token = tokens[i]
        type_begin = i
        if token.signal == IR.Signal.BEGIN_COMPOSITE
            type_end = capture_type!(ir, tokens, i, IR.Signal.END_COMPOSITE, token.name, token.referenced_name)
            capture_types!(ir, tokens, type_begin + 1, type_end - 1)
            i = type_end + 1
        elseif token.signal == IR.Signal.BEGIN_ENUM
            type_end = capture_type!(ir, tokens, i, IR.Signal.END_ENUM, token.name, token.referenced_name)
            i = type_end + 1
        elseif token.signal == IR.Signal.BEGIN_SET
            type_end = capture_type!(ir, tokens, i, IR.Signal.END_SET, token.name, token.referenced_name)
            i = type_end + 1
        else
            i += 1
        end
    end
end

function capture_type!(
    ir::IR.Ir,
    tokens::Vector{IR.Token},
    index::Int,
    end_signal::IR.Signal.T,
    name::String,
    referenced_name::Union{Nothing, String}
)
    type_tokens = IR.Token[]
    i = index
    push!(type_tokens, tokens[i])
    while true
        i += 1
        token = tokens[i]
        push!(type_tokens, token)
        if token.signal == end_signal && token.name == name
            break
        end
    end

    IR.update_component_token_counts!(type_tokens)
    type_name = referenced_name === nothing ? name : referenced_name
    existing = get(ir.types_by_name, type_name, nothing)
    if existing === nothing || existing[1].version > type_tokens[1].version
        ir.types_by_name[type_name] = type_tokens
    end

    return i
end

function build_header_structure(tokens::Vector{IR.Token})
    block_length_type = IR.PrimitiveType.NONE
    template_id_type = IR.PrimitiveType.NONE
    schema_id_type = IR.PrimitiveType.NONE
    schema_version_type = IR.PrimitiveType.NONE

    for token in tokens
        if token.name == "blockLength"
            block_length_type = token.encoding.primitive_type
        elseif token.name == "templateId"
            template_id_type = token.encoding.primitive_type
        elseif token.name == "schemaId"
            schema_id_type = token.encoding.primitive_type
        elseif token.name == "version"
            schema_version_type = token.encoding.primitive_type
        end
    end

    return IR.HeaderStructure(tokens, block_length_type, template_id_type, schema_id_type, schema_version_type)
end

function add_message_signal!(state::IrGeneratorState, message::XmlMessage, signal::IR.Signal.T)
    encoding = IR.Encoding(
        IR.Presence.REQUIRED,
        IR.PrimitiveType.NONE,
        state.schema.byte_order,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        message.semantic_type
    )

    token = IR.Token(
        signal,
        message.name,
        nothing,
        message.description,
        nothing,
        message.id,
        message.since_version,
        message.deprecated,
        max(message.block_length, message.computed_block_length),
        0,
        1,
        encoding
    )
    push!(state.tokens, token)
end

function add_field_signal!(state::IrGeneratorState, field::XmlField, signal::IR.Signal.T, type_since_version::Int)
    primitive_type = IR.PrimitiveType.NONE
    const_value = nothing
    if field.presence == IR.Presence.CONSTANT && field.value_ref !== nothing
        const_value = primitive_value_from_text(
            field.value_ref,
            IR.PrimitiveType.CHAR,
            ncodeunits(field.value_ref),
            "US-ASCII"
        )
        primitive_type = IR.PrimitiveType.CHAR
    end

    encoding = IR.Encoding(
        map_presence(field.presence),
        primitive_type,
        state.schema.byte_order,
        nothing,
        nothing,
        nothing,
        const_value,
        nothing,
        field.epoch,
        field.time_unit,
        field.semantic_type
    )

    token = IR.Token(
        signal,
        field.name,
        nothing,
        field.description,
        nothing,
        field.id,
        max(field.since_version, type_since_version),
        field.deprecated,
        field.computed_block_length,
        field.computed_offset,
        1,
        encoding
    )
    push!(state.tokens, token)
end

function add_all_fields!(state::IrGeneratorState, fields::Vector{XmlField})
    for field in fields
        if field.group_fields !== nothing
            add_field_signal!(state, field, IR.Signal.BEGIN_GROUP, 0)
            add_composite!(state, field.dimension_type, 0, field)
            add_all_fields!(state, field.group_fields)
            add_field_signal!(state, field, IR.Signal.END_GROUP, 0)
        elseif field.type_def isa XmlCompositeType && field.variable_length
            add_field_signal!(state, field, IR.Signal.BEGIN_VAR_DATA, 0)
            add_composite!(state, field.type_def, field.computed_offset, field)
            add_field_signal!(state, field, IR.Signal.END_VAR_DATA, 0)
        else
            type_def = field.type_def
            type_def === nothing && error("field type missing for $(field.name)")
            type_since_version = type_def.since_version
            add_field_signal!(state, field, IR.Signal.BEGIN_FIELD, type_since_version)
            if type_def isa XmlEncodedType
                add_encoded_type!(state, type_def, field.computed_offset, field)
            elseif type_def isa XmlCompositeType
                add_composite!(state, type_def, field.computed_offset, field)
            elseif type_def isa XmlEnumType
                add_enum_type!(state, type_def, field.computed_offset, field)
            elseif type_def isa XmlSetType
                add_set_type!(state, type_def, field.computed_offset, field)
            end
            add_field_signal!(state, field, IR.Signal.END_FIELD, type_since_version)
        end
    end
end

function add_composite!(state::IrGeneratorState, type_def::XmlCompositeType, curr_offset::Int, field::Union{Nothing, XmlField})
    version = field === nothing ? type_def.since_version : max(field.since_version, type_def.since_version)
    encoding = IR.Encoding(
        IR.Presence.REQUIRED,
        IR.PrimitiveType.NONE,
        state.schema.byte_order,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        type_def.semantic_type !== nothing ? type_def.semantic_type : (field === nothing ? nothing : field.semantic_type)
    )

    token = IR.Token(
        IR.Signal.BEGIN_COMPOSITE,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        encoded_length(type_def),
        curr_offset,
        1,
        encoding
    )
    push!(state.tokens, token)

    offset = 0
    for member in type_def.members
        if member isa XmlEncodedType && member.offset_attribute != -1
            offset = member.offset_attribute
        elseif member isa XmlEnumType && member.offset_attribute != -1
            offset = member.offset_attribute
        elseif member isa XmlSetType && member.offset_attribute != -1
            offset = member.offset_attribute
        elseif member isa XmlCompositeType && member.offset_attribute != -1
            offset = member.offset_attribute
        end

        if member isa XmlEncodedType
            add_encoded_type!(state, member, offset, version)
        elseif member isa XmlEnumType
            add_enum_type!(state, member, offset, field)
        elseif member isa XmlSetType
            add_set_type!(state, member, offset, field)
        elseif member isa XmlCompositeType
            add_composite!(state, member, offset, field)
        end
        offset += encoded_length(member)
    end

    end_token = IR.Token(
        IR.Signal.END_COMPOSITE,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        encoded_length(type_def),
        curr_offset,
        1,
        encoding
    )
    push!(state.tokens, end_token)
end

function add_enum_type!(state::IrGeneratorState, type_def::XmlEnumType, offset::Int, field::Union{Nothing, XmlField})
    version = field === nothing ? type_def.since_version : max(field.since_version, type_def.since_version)
    encoding = IR.Encoding(
        IR.Presence.REQUIRED,
        type_def.encoding_type,
        state.schema.byte_order,
        nothing,
        nothing,
        type_def.null_value,
        nothing,
        nothing,
        nothing,
        nothing,
        type_def.semantic_type !== nothing ? type_def.semantic_type : (field === nothing ? nothing : field.semantic_type)
    )

    begin_token = IR.Token(
        IR.Signal.BEGIN_ENUM,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        IR.primitive_type_size(type_def.encoding_type),
        offset,
        1,
        encoding
    )
    push!(state.tokens, begin_token)

    for value in type_def.valid_values
        value_encoding = IR.Encoding(
            IR.Presence.REQUIRED,
            type_def.encoding_type,
            state.schema.byte_order,
            nothing,
            nothing,
            nothing,
            value.primitive_value,
            nothing,
            nothing,
            nothing,
            nothing
        )
        token = IR.Token(
            IR.Signal.VALID_VALUE,
            value.name,
            nothing,
            value.description,
            nothing,
            IR.INVALID_ID,
            value.since_version,
            value.deprecated,
            0,
            0,
            1,
            value_encoding
        )
        push!(state.tokens, token)
    end

    end_token = IR.Token(
        IR.Signal.END_ENUM,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        IR.primitive_type_size(type_def.encoding_type),
        offset,
        1,
        encoding
    )
    push!(state.tokens, end_token)
end

function add_set_type!(state::IrGeneratorState, type_def::XmlSetType, offset::Int, field::Union{Nothing, XmlField})
    version = field === nothing ? type_def.since_version : max(field.since_version, type_def.since_version)
    encoding = IR.Encoding(
        IR.Presence.REQUIRED,
        type_def.encoding_type,
        state.schema.byte_order,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
        type_def.semantic_type !== nothing ? type_def.semantic_type : (field === nothing ? nothing : field.semantic_type)
    )

    begin_token = IR.Token(
        IR.Signal.BEGIN_SET,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        IR.primitive_type_size(type_def.encoding_type),
        offset,
        1,
        encoding
    )
    push!(state.tokens, begin_token)

    for choice in type_def.choices
        choice_encoding = IR.Encoding(
            IR.Presence.REQUIRED,
            type_def.encoding_type,
            state.schema.byte_order,
            nothing,
            nothing,
            nothing,
            choice.primitive_value,
            nothing,
            nothing,
            nothing,
            nothing
        )
        token = IR.Token(
            IR.Signal.CHOICE,
            choice.name,
            nothing,
            choice.description,
            nothing,
            IR.INVALID_ID,
            choice.since_version,
            choice.deprecated,
            0,
            0,
            1,
            choice_encoding
        )
        push!(state.tokens, token)
    end

    end_token = IR.Token(
        IR.Signal.END_SET,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        IR.primitive_type_size(type_def.encoding_type),
        offset,
        1,
        encoding
    )
    push!(state.tokens, end_token)
end

function add_encoded_type!(state::IrGeneratorState, type_def::XmlEncodedType, offset::Int, since_version::Int)
    size = encoded_length(type_def)
    if type_def.presence == IR.Presence.CONSTANT
        size = 0
    end

    if type_def.presence == IR.Presence.CONSTANT
        const_value = type_def.const_value
        if const_value === nothing && type_def.value_ref !== nothing
            const_value = lookup_value_ref(state.schema, type_def.value_ref)
        end
        encoding = IR.Encoding(
            IR.Presence.CONSTANT,
            type_def.primitive_type,
            state.schema.byte_order,
            nothing,
            nothing,
            nothing,
            const_value,
            type_def.character_encoding,
            nothing,
            nothing,
            type_def.semantic_type
        )
    elseif type_def.presence == IR.Presence.OPTIONAL
        encoding = IR.Encoding(
            IR.Presence.OPTIONAL,
            type_def.primitive_type,
            state.schema.byte_order,
            type_def.min_value,
            type_def.max_value,
            type_def.null_value,
            nothing,
            type_def.character_encoding,
            nothing,
            nothing,
            type_def.semantic_type
        )
    else
        encoding = IR.Encoding(
            IR.Presence.REQUIRED,
            type_def.primitive_type,
            state.schema.byte_order,
            type_def.min_value,
            type_def.max_value,
            nothing,
            nothing,
            type_def.character_encoding,
            nothing,
            nothing,
            type_def.semantic_type
        )
    end

    token = IR.Token(
        IR.Signal.ENCODING,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        since_version,
        type_def.deprecated,
        size,
        offset,
        1,
        encoding
    )
    push!(state.tokens, token)
end

function add_encoded_type!(state::IrGeneratorState, type_def::XmlEncodedType, offset::Int, field::XmlField)
    version = max(field.since_version, type_def.since_version)
    semantic = type_def.semantic_type === nothing ? field.semantic_type : type_def.semantic_type

    effective_presence = field.presence
    if field.presence == IR.Presence.REQUIRED && type_def.presence != IR.Presence.REQUIRED
        effective_presence = type_def.presence
    end

    size = encoded_length(type_def)
    if effective_presence == IR.Presence.CONSTANT
        size = 0
    end

    if effective_presence == IR.Presence.CONSTANT
        const_value = field.value_ref === nothing ? type_def.const_value : lookup_value_ref(state.schema, field.value_ref)
        if const_value === nothing && type_def.value_ref !== nothing
            const_value = lookup_value_ref(state.schema, type_def.value_ref)
        end
        encoding = IR.Encoding(
            IR.Presence.CONSTANT,
            type_def.primitive_type,
            state.schema.byte_order,
            nothing,
            nothing,
            nothing,
            const_value,
            type_def.character_encoding,
            field.epoch,
            field.time_unit,
            semantic
        )
    elseif effective_presence == IR.Presence.OPTIONAL
        encoding = IR.Encoding(
            IR.Presence.OPTIONAL,
            type_def.primitive_type,
            state.schema.byte_order,
            type_def.min_value,
            type_def.max_value,
            type_def.null_value,
            nothing,
            type_def.character_encoding,
            field.epoch,
            field.time_unit,
            semantic
        )
    else
        encoding = IR.Encoding(
            IR.Presence.REQUIRED,
            type_def.primitive_type,
            state.schema.byte_order,
            type_def.min_value,
            type_def.max_value,
            nothing,
            nothing,
            type_def.character_encoding,
            field.epoch,
            field.time_unit,
            semantic
        )
    end

    token = IR.Token(
        IR.Signal.ENCODING,
        type_def.name,
        type_def.referenced_name,
        type_def.description,
        type_def.package_name,
        IR.INVALID_ID,
        version,
        type_def.deprecated,
        size,
        offset,
        1,
        encoding
    )
    push!(state.tokens, token)
end

function lookup_value_ref(schema::XmlMessageSchema, value_ref::String)
    period_index = findfirst(==('.'), value_ref)
    period_index === nothing && error("invalid valueRef: $(value_ref)")
    type_name = value_ref[1:period_index-1]
    value_name = value_ref[period_index+1:end]
    enum_type = get(schema.types_by_name, type_name, nothing)
    enum_type isa XmlEnumType || error("valueRef type not found: $(type_name)")
    for value in enum_type.valid_values
        if value.name == value_name
            return value.primitive_value
        end
    end
    error("valueRef not found: $(value_ref)")
end

function map_presence(presence::IR.Presence.T)
    presence == IR.Presence.OPTIONAL && return IR.Presence.OPTIONAL
    presence == IR.Presence.CONSTANT && return IR.Presence.CONSTANT
    return IR.Presence.REQUIRED
end
