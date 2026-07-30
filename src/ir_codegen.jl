"""
IR-based code generation utilities.

These helpers are shared by the IR code generator as it is ported from the Java reference.
"""

struct IrEnumValue
    name::String
    literal::String
    description::String
    since_version::Int
    deprecated::Int
end

struct IrEnumDef
    name::String
    description::String
    encoding_type::IR.PrimitiveType.T
    null_value::Union{Nothing, IR.PrimitiveValue}
    values::Vector{IrEnumValue}
end

struct IrCompositeMember
    signal::IR.Signal.T
    tokens::Vector{IR.Token}
end

struct IrCompositeDef
    name::String
    description::String
    members::Vector{IrCompositeMember}
    encoded_length::Int
    semantic_type::Union{Nothing, String}
end

struct IrSetChoice
    name::String
    bit_position::Int
    description::String
    since_version::Int
    deprecated::Int
end

struct IrSetDef
    name::String
    description::String
    encoding_type::IR.PrimitiveType.T
    choices::Vector{IrSetChoice}
    since_version::Int
    offset::Int
end

const RESERVED_IDENTIFIERS = Set([
    "Any",
    "Bool",
    "Char",
    "Complex",
    "Expr",
    "Float16",
    "Float32",
    "Float64",
    "Int",
    "Int8",
    "Int16",
    "Int32",
    "Int64",
    "Int128",
    "Missing",
    "Module",
    "Nothing",
    "Ptr",
    "String",
    "Symbol",
    "Tuple",
    "Type",
    "UInt",
    "UInt8",
    "UInt16",
    "UInt32",
    "UInt64",
    "UInt128",
    "Union",
    "AbstractArray",
    "AbstractString",
])

function sanitize_identifier(name::String)
    candidate = replace(name, r"[^A-Za-z0-9_]" => "_")
    if isempty(candidate)
        candidate = "field"
    elseif all(==('_'), candidate)
        candidate *= "field"
    end
    if !isempty(candidate) && isdigit(first(candidate))
        candidate = "_" * candidate
    end
    while !Base.isidentifier(candidate) || (candidate in JULIA_KEYWORDS) || (candidate in RESERVED_IDENTIFIERS)
        candidate *= "_"
    end
    return candidate
end

function format_struct_name(name::String)
    parts = split(name, r"[_\\-]")
    raw = join([uppercasefirst(part) for part in parts])
    return sanitize_identifier(raw)
end

function format_property_name(name::String)
    parts = split(name, r"[_\\-]")
    raw = if length(parts) == 1
        lowercasefirst(parts[1])
    else
        lowercasefirst(parts[1]) * join([uppercasefirst(part) for part in parts[2:end]])
    end
    return sanitize_identifier(raw)
end

function format_choice_name(name::String)
    if !isempty(name) && isuppercase(first(name))
        return format_struct_name(name)
    end
    return format_property_name(name)
end

function generated_doc_expr(documentation::String, documented_expr)
    return Expr(
        :macrocall,
        Expr(:., :Base, QuoteNode(Symbol("@doc"))),
        LineNumberNode(0, Symbol("ir_codegen")),
        documentation,
        documented_expr
    )
end

function generated_binding_doc_expr(documentation::String, binding)
    return generated_doc_expr(documentation, binding)
end

function description_or_default(description::String, default::String)
    stripped = strip(description)
    return isempty(stripped) ? default : stripped
end

function presence_name(token::IR.Token)
    presence = token.encoding.presence
    presence == IR.Presence.CONSTANT && return "constant"
    presence == IR.Presence.OPTIONAL && return "optional"
    return "required"
end

function schema_metadata_doc(token::IR.Token; kind::String="field")
    metadata = "SBE $kind `$(token.name)`: id=$(token.id), presence=$(presence_name(token)), sinceVersion=$(token.version)"
    token.deprecated > 0 && (metadata *= ", deprecated=$(token.deprecated)")
    return metadata * "."
end

function field_accessor_doc(field_tokens::Vector{IR.Token})
    field_token = field_tokens[1]
    value_token = field_tokens[2]
    accessor = format_property_name(field_token.name)
    description = description_or_default(
        field_token.description,
        "Access the `$(field_token.name)` field."
    )
    encoder_signature = if value_token.signal == IR.Signal.BEGIN_SET ||
                           value_token.signal == IR.Signal.BEGIN_COMPOSITE
        "\n    $accessor(encoder)"
    elseif value_token.encoding.presence != IR.Presence.CONSTANT
        "\n    $(accessor)!(encoder, value) -> encoder"
    else
        ""
    end
    return """
        $accessor(decoder)$encoder_signature

    $description

    $(schema_metadata_doc(field_token))
    """
end

function field_has_setter(field_tokens::Vector{IR.Token})
    value_token = field_tokens[2]
    return (value_token.signal == IR.Signal.ENCODING ||
            value_token.signal == IR.Signal.BEGIN_ENUM) &&
           value_token.encoding.presence != IR.Presence.CONSTANT
end

function var_data_accessor_doc(var_data_tokens::Vector{IR.Token})
    field_token = var_data_tokens[1]
    data_token = find_first_token("varData", var_data_tokens, 1)
    accessor = format_property_name(field_token.name)
    encoding = data_token.encoding.character_encoding
    encoding_note = encoding === nothing ? "binary data" : "$encoding text"
    default_return = data_token.encoding.primitive_type == IR.PrimitiveType.CHAR ?
        "AbstractString" : "AbstractVector{UInt8}"
    description = description_or_default(
        field_token.description,
        "Access the `$(field_token.name)` variable-length $encoding_note field."
    )
    return """
        $accessor(decoder) -> $default_return
        $accessor(decoder, String) -> String
        $(accessor)!(encoder, value) -> encoder

    $description

    $(schema_metadata_doc(field_token; kind="variable-data field")) Reading or writing advances the shared message position. Access variable-length fields and repeating groups in schema order.
    """
end


function group_accessor_doc(group_token::IR.Token)
    accessor = format_property_name(group_token.name)
    description = description_or_default(
        group_token.description,
        "Access the `$(group_token.name)` repeating group."
    )
    return """
        $accessor(decoder)
        $(accessor)!(encoder, count)

    $description

    $(schema_metadata_doc(group_token; kind="repeating group")) Accessing or iterating the group advances the shared message position. Iteration reuses one mutable flyweight entry; do not retain entries as independent values.
    """
end


function composite_member_accessor_doc(token::IR.Token; has_setter::Bool=true)
    accessor = format_property_name(token.name)
    description = description_or_default(
        token.description,
        "Access the `$(token.name)` composite member."
    )
    setter_signature = !has_setter || token.encoding.presence == IR.Presence.CONSTANT ? "" :
        "\n    $(accessor)!(encoder, value) -> encoder"
    return """
        $accessor(decoder)$setter_signature

    $description

    $(schema_metadata_doc(token; kind="composite member"))
    """
end


function codec_type_doc(
    type_name::AbstractString,
    description::String,
    kind::String;
    extra::String=""
)
    body = description_or_default(description, "Generated SBE $kind `$type_name`.")
    suffix = isempty(extra) ? "" : "\n\n$extra"
    return "$body$suffix"
end


function message_codec_doc(msg_token::IR.Token, ir::IR.Ir)
    body = description_or_default(
        msg_token.description,
        "Generated SBE message codec `$(msg_token.name)`."
    )
    return """
    $body

    Template ID $(msg_token.id), schema ID $(ir.id), schema version $(ir.version), fixed block length $(msg_token.encoded_length) bytes.

    This is a zero-copy flyweight codec. Fixed fields support random access; repeating groups and variable-length data share a mutable cursor and must be traversed in schema order.
    """
end


function group_codec_doc(group_token::IR.Token)
    body = description_or_default(
        group_token.description,
        "Generated codec for the `$(group_token.name)` repeating group."
    )
    return """
    $body

    Iteration advances the parent message cursor and reuses one mutable flyweight entry. Consume fields before advancing and do not retain entries as independent values.
    """
end


function schema_module_doc(ir::IR.Ir, module_name::Symbol)
    body = description_or_default(
        ir.description,
        "Generated SBE codec module `$module_name`."
    )
    return """
    $body

    SBE package `$(ir.package_name)`, schema ID $(ir.id), schema version $(ir.version), semantic version `$(ir.semantic_version)`, byte order `$(ir.byte_order)`.
    """
end


function character_encoding_kind(encoding::Union{Nothing, String})
    encoding === nothing && return :raw
    normalized = uppercase(replace(strip(encoding), '_' => '-', ' ' => '-'))
    normalized in ("ASCII", "US-ASCII") && return :ascii
    normalized in ("UTF8", "UTF-8") && return :utf8
    return :unsupported
end

function string_encoding_guard_expr(encoding::Union{Nothing, String}, value_name::Symbol)
    kind = character_encoding_kind(encoding)
    if kind == :ascii
        return :(@boundscheck isascii($value_name) || throw(ArgumentError("value is not valid ASCII")))
    elseif kind == :utf8 || kind == :raw
        return :(nothing)
    end
    message = "unsupported character encoding: $encoding"
    return :(throw(ArgumentError($message)))
end

function relative_using_expr(depth::Int, name::Symbol)
    dots = repeat(".", depth + 1)
    return Meta.parse("using " * dots * string(name))
end

function precedence_helper_name(
    mode::Symbol,
    key::PrecedenceInteractionKey,
)
    kind, path = key
    raw = string("_", mode, "_precedence_", kind, "_", path, "!")
    return Symbol(sanitize_identifier(raw))
end

function precedence_helper_symbols(
    model::FieldPrecedenceModel,
    mode::Symbol,
)
    interaction_keys = filter(
        key -> first(key) != :wrap,
        collect(Base.keys(model.transitions)),
    )
    sort!(interaction_keys; by=key -> string(first(key), ":", last(key)))
    return [precedence_helper_name(mode, key) for key in interaction_keys]
end

function precedence_relative_import_expr(
    module_depth::Int,
    message_name::Symbol,
    names::Vector{Symbol},
)
    isempty(names) && return Expr(:block)
    dots = repeat(".", module_depth)
    return Meta.parse(
        "using " *
        dots *
        string(message_name) *
        ": " *
        join(string.(names), ", "),
    )
end

function precedence_state_condition(states::Vector{Int})
    conditions = [:(state == UInt16($state)) for state in states]
    isempty(conditions) && return false
    result = first(conditions)
    for condition in Iterators.drop(conditions, 1)
        result = :($result || $condition)
    end
    return result
end

function precedence_error_expr(
    model::FieldPrecedenceModel,
    key::PrecedenceInteractionKey,
    state_names_symbol::Symbol,
    state_transitions_symbol::Symbol,
)
    return :(throw_precedence_error(
        $(model.actions[key]),
        $(last(key)),
        state,
        $state_names_symbol,
        $state_transitions_symbol,
        $(model.machine_name),
    ))
end

function precedence_listener_expr(
    model::FieldPrecedenceModel,
    key::PrecedenceInteractionKey,
    state_names_symbol::Symbol,
    state_transitions_symbol::Symbol,
)
    error_expr = precedence_error_expr(
        model,
        key,
        state_names_symbol,
        state_transitions_symbol,
    )

    if first(key) == :field && last(key) in model.top_level_block_fields
        return quote
            state = codec_state.value
            state == UInt16(0) && $error_expr
            return nothing
        end
    end

    fallback = error_expr
    for transition in Iterators.reverse(model.transitions[key])
        condition = precedence_state_condition(transition.from)
        success = quote
            codec_state.value = UInt16($(transition.to))
            return nothing
        end
        fallback = Expr(:if, condition, success, fallback)
    end

    return quote
        state = codec_state.value
        $fallback
    end
end

function generate_precedence_helpers(
    model::FieldPrecedenceModel,
    mode::Symbol,
)
    prefix = Symbol("_", mode, "_precedence")
    state_names_symbol = Symbol(prefix, "_state_names")
    state_transitions_symbol = Symbol(prefix, "_state_transitions")
    state_names = Tuple(model.state_names)
    state_transitions = Tuple(Tuple(expected) for expected in model.expected_by_state)
    exprs = Expr[
        :(const $state_names_symbol = $state_names),
        :(const $state_transitions_symbol = $state_transitions),
    ]

    interaction_keys = filter(
        key -> first(key) != :wrap,
        collect(Base.keys(model.transitions)),
    )
    sort!(interaction_keys; by=key -> string(first(key), ":", last(key)))
    for key in interaction_keys
        helper_name = precedence_helper_name(mode, key)
        listener = precedence_listener_expr(
            model,
            key,
            state_names_symbol,
            state_transitions_symbol,
        )
        push!(
            exprs,
            quote
                @inline function $helper_name(codec_state::CodecStatePointer)
                    $listener
                end
            end,
        )
    end

    return exprs, state_names_symbol, state_transitions_symbol
end

@inline function precedence_access_expr(
    model::FieldPrecedenceModel,
    mode::Symbol,
    key::PrecedenceInteractionKey,
    object::Symbol=:m,
)
    helper_name = precedence_helper_name(mode, key)
    return :($helper_name($object.codec_state))
end

function precedence_decoder_wrap_expr(
    model::FieldPrecedenceModel,
    object::Symbol,
    acting_version,
)
    fallback = :(throw(ArgumentError(
        "unsupported acting version for precedence checks: " *
        string($acting_version),
    )))
    for version in sort!(collect(keys(model.wrapped_states)))
        state = model.wrapped_states[version]
        fallback = Expr(
            :if,
            :($acting_version >= $version),
            :($object.codec_state.value = UInt16($state)),
            fallback,
        )
    end
    return fallback
end

function julia_type_from_symbol(sym::Symbol)
    if sym === :UInt8
        return UInt8
    elseif sym === :UInt16
        return UInt16
    elseif sym === :UInt32
        return UInt32
    elseif sym === :UInt64
        return UInt64
    elseif sym === :Int8
        return Int8
    elseif sym === :Int16
        return Int16
    elseif sym === :Int32
        return Int32
    elseif sym === :Int64
        return Int64
    elseif sym === :Float32
        return Float32
    elseif sym === :Float64
        return Float64
    end
    error("Unsupported Julia type symbol: $(sym)")
end

function strip_interpolations!(expr)
    if expr isa Expr
        if expr.head == :$
            return strip_interpolations!(expr.args[1])
        end
        for i in eachindex(expr.args)
            arg = expr.args[i]
            if arg isa Expr
                expr.args[i] = strip_interpolations!(arg)
            elseif arg isa AbstractVector
                for j in eachindex(arg)
                    arg_j = arg[j]
                    if arg_j isa Expr
                        arg[j] = strip_interpolations!(arg_j)
                    end
                end
            end
        end
    end
    return expr
end

function normalize_dotted_exprs!(expr)
    if expr isa Expr
        if expr.head == :. && length(expr.args) == 2 && expr.args[2] isa Symbol
            expr.args[2] = QuoteNode(expr.args[2])
        end
        for i in eachindex(expr.args)
            normalize_dotted_exprs!(expr.args[i])
        end
    elseif expr isa AbstractVector
        for item in expr
            normalize_dotted_exprs!(item)
        end
    end
    return expr
end

function primitive_value_literal(value::IR.PrimitiveValue, primitive_type::IR.PrimitiveType.T)
    if value.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        return repr(value.value)
    elseif value.representation == IR.PrimitiveValueRepresentation.DOUBLE
        return value.value
    elseif primitive_type == IR.PrimitiveType.CHAR &&
           (value.representation == IR.PrimitiveValueRepresentation.LONG ||
            value.representation == IR.PrimitiveValueRepresentation.STRING)
        if all(isdigit, value.value) || startswith(value.value, "0x") || startswith(value.value, "-")
            return value.value
        end
        code = Int(codeunit(value.value, 1))
        return "0x" * lowercase(string(code, base=16, pad=2))
    end

    return value.value
end

function enum_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    enum_name = begin_token.referenced_name === nothing ? begin_token.name : begin_token.referenced_name
    encoding_type = begin_token.encoding.primitive_type
    null_value = begin_token.encoding.null_value
    values = IrEnumValue[]
    for token in tokens
        if token.signal == IR.Signal.VALID_VALUE
            literal = primitive_value_literal(token.encoding.const_value, encoding_type)
            push!(values, IrEnumValue(token.name, literal, token.description, token.version, token.deprecated))
        end
    end
    return IrEnumDef(enum_name, begin_token.description, encoding_type, null_value, values)
end

function composite_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    composite_name = begin_token.referenced_name === nothing ? begin_token.name : begin_token.referenced_name
    members = IrCompositeMember[]
    i = 2
    while i < length(tokens)
        token = tokens[i]
        if token.signal == IR.Signal.ENCODING
            push!(members, IrCompositeMember(token.signal, [token]))
            i += 1
        elseif token.signal == IR.Signal.BEGIN_ENUM ||
               token.signal == IR.Signal.BEGIN_SET ||
               token.signal == IR.Signal.BEGIN_COMPOSITE
            count = token.component_token_count
            push!(members, IrCompositeMember(token.signal, tokens[i:(i + count - 1)]))
            i += count
        else
            i += 1
        end
    end

    return IrCompositeDef(
        composite_name,
        begin_token.description,
        members,
        begin_token.encoded_length,
        begin_token.encoding.semantic_type
    )
end

function primitive_value_or_default(
    value::Union{Nothing, IR.PrimitiveValue},
    primitive_type::IR.PrimitiveType.T,
    default_fn::Function
)
    return value === nothing ? default_fn(primitive_type) : value
end

function encoding_literal(value::Union{Nothing, IR.PrimitiveValue}, primitive_type::IR.PrimitiveType.T, default_fn::Function)
    actual = primitive_value_or_default(value, primitive_type, default_fn)
    return Meta.parse(primitive_value_literal(actual, primitive_type))
end

function primitive_value_int(value::Union{Nothing, IR.PrimitiveValue}, primitive_type::IR.PrimitiveType.T, default_fn::Function)
    actual = primitive_value_or_default(value, primitive_type, default_fn)
    return parse(Int, actual.value)
end

function composite_member_field_name(name::String)
    return Symbol(format_property_name(name))
end

function composite_member_module_name(token::IR.Token)
    type_name = token.referenced_name === nothing ? token.name : token.referenced_name
    return Symbol(format_struct_name(type_name))
end

function generate_composite_member_expr(
    token::IR.Token,
    base_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
)
    member_name = composite_member_field_name(token.name)
    primitive_type = token.encoding.primitive_type
    julia_type = IR.primitive_type_julia(primitive_type)
    julia_type_symbol = Symbol(julia_type)
    encoding_length = token.encoded_length
    is_constant = token.encoding.presence == IR.Presence.CONSTANT

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($(token.offset))
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($(token.offset))
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(encoding_length))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(encoding_length))

        $(Symbol(member_name, :_null_value))(::$base_type_name) = $julia_type_symbol($(encoding_literal(token.encoding.null_value, primitive_type, IR.primitive_type_null)))
        $(Symbol(member_name, :_null_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(encoding_literal(token.encoding.null_value, primitive_type, IR.primitive_type_null)))
        $(Symbol(member_name, :_min_value))(::$base_type_name) = $julia_type_symbol($(encoding_literal(token.encoding.min_value, primitive_type, IR.primitive_type_min)))
        $(Symbol(member_name, :_min_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(encoding_literal(token.encoding.min_value, primitive_type, IR.primitive_type_min)))
        $(Symbol(member_name, :_max_value))(::$base_type_name) = $julia_type_symbol($(encoding_literal(token.encoding.max_value, primitive_type, IR.primitive_type_max)))
        $(Symbol(member_name, :_max_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(encoding_literal(token.encoding.max_value, primitive_type, IR.primitive_type_max)))
    end)

    if is_constant
        const_val = token.encoding.const_value === nothing ? IR.primitive_type_null(primitive_type) : token.encoding.const_value
        literal = primitive_value_literal(const_val, primitive_type)
        if const_val.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
            push!(exprs, quote
                @inline $member_name(::$base_type_name) = $(Meta.parse(literal))
                @inline $member_name(::Type{<:$base_type_name}) = $(Meta.parse(literal))
                export $member_name
            end)
        else
            push!(exprs, quote
                @inline $member_name(::$base_type_name) = $julia_type_symbol($(Meta.parse(literal)))
                @inline $member_name(::Type{<:$base_type_name}) = $julia_type_symbol($(Meta.parse(literal)))
                export $member_name
            end)
        end
        return exprs
    end

    if encoding_length == 0 && token.name == "varData"
        return exprs
    end

    array_len = encoding_length > 0 ? encoding_length ÷ IR.primitive_type_size(primitive_type) : 1

    if array_len == 1
        push!(exprs, quote
            @inline function $member_name(m::$decoder_name)
                return decode_value($julia_type, m.buffer, m.offset + $(token.offset))
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                encode_value($julia_type, m.buffer, m.offset + $(token.offset), val)
                return m
            end

            export $member_name, $(Symbol(member_name, :!))
        end)
        return exprs
    end

    is_char_array = primitive_type == IR.PrimitiveType.CHAR
    if is_char_array
        string_guard = string_encoding_guard_expr(
            something(token.encoding.character_encoding, "ASCII"),
            :value
        )
        length_error = "value exceeds fixed encoded length $array_len"
        push!(exprs, :(using StringViews: StringView))
        push!(exprs, quote
            @inline function $member_name(m::$decoder_name)
                bytes = decode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                pos = findfirst(iszero, bytes)
                len = pos !== nothing ? pos - 1 : Base.length(bytes)
                return StringView(view(bytes, 1:len))
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name)
                return encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractString)
                $string_guard
                bytes = codeunits(value)
                dest = encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                len = Base.length(bytes)
                @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                copyto!(dest, 1, bytes, 1, len)
                if len < Base.length(dest)
                    fill!(view(dest, len+1:Base.length(dest)), 0x00)
                end
                return m
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                dest = encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                len = Base.length(value)
                @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                copyto!(dest, 1, value, 1, len)
                if len < Base.length(dest)
                    fill!(view(dest, len+1:Base.length(dest)), 0x00)
                end
                return m
            end

            export $member_name, $(Symbol(member_name, :!))
        end)
        return exprs
    end

    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            return decode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
        end

        @inline function $member_name(m::$decoder_name, ::Type{T}) where {T<:NTuple}
            Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
            elem_type = Base.tuple_type_head(T)
            elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
            len = fieldcount(T)
            len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
            x = decode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
            return ntuple(i -> x[i], Val(len))
        end

        @inline function $(Symbol(member_name, :!))(m::$encoder_name)
            return encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
        end

        @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
            copyto!($(Symbol(member_name, :!))(m), val)
            return m
        end

        @inline function $(Symbol(member_name, :!))(m::$encoder_name, val::T) where {T<:NTuple}
            Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
            elem_type = Base.tuple_type_head(T)
            elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
            len = fieldcount(T)
            len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
            dest = $(Symbol(member_name, :!))(m)
            @inbounds for i in 1:$array_len
                dest[i] = val[i]
            end
            return m
        end

        export $member_name, $(Symbol(member_name, :!))
    end)

    return exprs
end

function generate_composite_enum_accessor(
    token::IR.Token,
    base_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
)
    member_name = composite_member_field_name(token.name)
    enum_module = composite_member_module_name(token)
    julia_type = IR.primitive_type_julia(token.encoding.primitive_type)
    julia_type_symbol = Symbol(julia_type)
    offset = token.offset
    encoding_size = IR.primitive_type_size(token.encoding.primitive_type)

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($encoding_size)
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($encoding_size)
    end)

    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            raw_value = decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
            return $enum_module.SbeEnum(raw_value)
        end

        @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
            encode_value($julia_type_symbol, m.buffer, m.offset + $offset, $julia_type_symbol(val))
            return m
        end

        export $member_name, $(Symbol(member_name, :!))
    end)

    return exprs
end

function generate_composite_set_accessor(
    token::IR.Token,
    base_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
)
    member_name = composite_member_field_name(token.name)
    set_module = composite_member_module_name(token)
    julia_type = IR.primitive_type_julia(token.encoding.primitive_type)
    offset = token.offset
    encoding_size = IR.primitive_type_size(token.encoding.primitive_type)

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($encoding_size)
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($encoding_size)
    end)

    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            return $set_module.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end

        @inline function $member_name(m::$encoder_name)
            return $set_module.Encoder(m.buffer, m.offset + $offset)
        end

        export $member_name
    end)

    return exprs
end

function generate_composite_composite_accessor(
    token::IR.Token,
    base_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
)
    member_name = composite_member_field_name(token.name)
    composite_module = composite_member_module_name(token)
    offset = token.offset

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(token.encoded_length))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(token.encoded_length))
    end)

    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            return $composite_module.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end

        @inline function $member_name(m::$encoder_name)
            return $composite_module.Encoder(m.buffer, m.offset + $offset)
        end

        export $member_name
    end)

    return exprs
end

function generate_composite_expr(composite_def::IrCompositeDef, ir::IR.Ir)
    composite_name = Symbol(format_struct_name(composite_def.name))
    abstract_type_name = Symbol(string("Abstract", composite_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    version_type_symbol = header_field_type(ir, "version")

    field_exprs = Expr[]
    field_doc_exprs = Expr[]
    var_data_exprs = Expr[]
    skip_calls = Expr[]
    group_exprs = Expr[]
    group_accessors = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()

    for member in composite_def.members
        tokens = member.tokens
        member_name = composite_member_field_name(tokens[1].name)
        has_setter = member.signal == IR.Signal.ENCODING ||
            member.signal == IR.Signal.BEGIN_ENUM
        documentation = composite_member_accessor_doc(
            tokens[1];
            has_setter=has_setter
        )
        push!(
            field_doc_exprs,
            generated_binding_doc_expr(
                documentation,
                member_name
            )
        )
        if has_setter && tokens[1].encoding.presence != IR.Presence.CONSTANT
            push!(
                field_doc_exprs,
                generated_binding_doc_expr(
                    documentation,
                    Symbol(member_name, :!)
                )
            )
        end
        if member.signal == IR.Signal.ENCODING
            append!(field_exprs, generate_composite_member_expr(tokens[1], abstract_type_name, decoder_name, encoder_name, ir))
        elseif member.signal == IR.Signal.BEGIN_ENUM
            module_name = composite_member_module_name(tokens[1])
            push!(enum_imports, module_name)
            append!(field_exprs, generate_composite_enum_accessor(tokens[1], abstract_type_name, decoder_name, encoder_name, ir))
        elseif member.signal == IR.Signal.BEGIN_SET
            module_name = composite_member_module_name(tokens[1])
            push!(enum_imports, module_name)
            append!(field_exprs, generate_composite_set_accessor(tokens[1], abstract_type_name, decoder_name, encoder_name, ir))
        elseif member.signal == IR.Signal.BEGIN_COMPOSITE
            module_name = composite_member_module_name(tokens[1])
            push!(composite_imports, module_name)
            append!(field_exprs, generate_composite_composite_accessor(tokens[1], abstract_type_name, decoder_name, encoder_name, ir))
        end
    end

    endian_imports = generate_encoded_types_expr(ir.byte_order)
    needs_enumx = !isempty(enum_imports)

    composite_quoted = quote
        module $composite_name
            using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
            import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
            import SBE: value, value!
            import SBE: sbe_buffer, sbe_offset, sbe_acting_version, sbe_encoded_length
            import SBE: sbe_schema_id, sbe_schema_version
            using MappedArrays: mappedarray
            $(needs_enumx ? :(using EnumX) : nothing)

            $([:($using_stmt) for using_stmt in [:(using ..$enum_name) for enum_name in enum_imports]]...)
            $([:($using_stmt) for using_stmt in [:(using ..$composite_name) for composite_name in composite_imports]]...)

            $endian_imports

            abstract type $abstract_type_name <: AbstractSbeCompositeType end

            struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int64
                acting_version::$version_type_symbol
            end

            struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int64
            end

            $(generated_binding_doc_expr(
                "Abstract flyweight type for the generated `$(composite_def.name)` composite codec.",
                abstract_type_name
            ))
            $(generated_binding_doc_expr(
                "Zero-copy decoder for the `$(composite_def.name)` SBE composite.",
                decoder_name
            ))
            $(generated_binding_doc_expr(
                "Zero-copy encoder for the `$(composite_def.name)` SBE composite.",
                encoder_name
            ))

            @inline function $decoder_name(buffer::AbstractArray{UInt8})
                $decoder_name(buffer, Int64(0), $(version_expr(ir, ir.version)))
            end

            @inline function $decoder_name(buffer::AbstractArray{UInt8}, offset::Integer)
                $decoder_name(buffer, Int64(offset), $(version_expr(ir, ir.version)))
            end

            @inline function $encoder_name(buffer::AbstractArray{UInt8})
                $encoder_name(buffer, Int64(0))
            end

            sbe_buffer(m::$abstract_type_name) = m.buffer
            sbe_offset(m::$abstract_type_name) = m.offset
            sbe_encoded_length(::$abstract_type_name) = $(block_length_expr(ir, composite_def.encoded_length))
            sbe_encoded_length(::Type{<:$abstract_type_name}) = $(block_length_expr(ir, composite_def.encoded_length))

            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))
            sbe_schema_id(::$abstract_type_name) = $(schema_id_expr(ir, ir.id))
            sbe_schema_id(::Type{<:$abstract_type_name}) = $(schema_id_expr(ir, ir.id))
            sbe_schema_version(::$abstract_type_name) = $(version_expr(ir, ir.version))
            sbe_schema_version(::Type{<:$abstract_type_name}) = $(version_expr(ir, ir.version))

            Base.sizeof(m::$abstract_type_name) = sbe_encoded_length(m)

            function Base.convert(::Type{<:AbstractArray{UInt8}}, m::$abstract_type_name)
                return view(m.buffer, m.offset+1:m.offset+sbe_encoded_length(m))
            end

            function Base.show(io::IO, m::$abstract_type_name)
                print(io, $(string(composite_name)), "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
            end

            $(field_exprs...)
            $(field_doc_exprs...)

            export $abstract_type_name, $decoder_name, $encoder_name
        end
    end

    module_expr = extract_expr_from_quote(composite_quoted, :module)
    return generated_doc_expr(
        codec_type_doc(
            composite_def.name,
            composite_def.description,
            "composite";
            extra="Encoded length: $(composite_def.encoded_length) bytes."
        ),
        module_expr
    )
end

function split_components(tokens::Vector{IR.Token}, signal::IR.Signal.T, start_index::Int)
    components = Vector{Vector{IR.Token}}()
    i = start_index
    while i <= length(tokens)
        token = tokens[i]
        if token.signal != signal
            break
        end
        count = token.component_token_count
        push!(components, tokens[i:(i + count - 1)])
        i += count
    end
    return components, i
end

function field_meta_attribute_expr(
    field_name::Symbol,
    abstract_type_name::Symbol,
    field_token::IR.Token
)
    presence = field_token.encoding.presence == IR.Presence.CONSTANT ? "constant" :
               field_token.encoding.presence == IR.Presence.OPTIONAL ? "optional" : "required"
    semantic_type = field_token.encoding.semantic_type === nothing ? "" : field_token.encoding.semantic_type
    return quote
        function $(Symbol(field_name, :_meta_attribute))(::$abstract_type_name, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
        function $(Symbol(field_name, :_meta_attribute))(::Type{<:$abstract_type_name}, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
    end
end

function generated_method_signature_call(signature)
    signature isa Expr || return nothing
    signature.head == :call && return signature
    signature.head == :where || return nothing
    return generated_method_signature_call(signature.args[1])
end

function generated_method_argument_type(argument)
    argument isa Expr && argument.head == :(::) || return nothing
    length(argument.args) == 2 || return nothing
    argument.args[1] == :m || return nothing
    return argument.args[2]
end

function instrument_generated_field_methods!(
    expr,
    method_names::Set{Symbol},
    decoder_name::Symbol,
    encoder_name::Symbol,
    decoder_access,
    encoder_access,
    since_version::Int,
    ir::IR.Ir,
)
    expr isa Expr || return expr
    if expr.head == :function
        call = generated_method_signature_call(expr.args[1])
        call === nothing && return expr
        call.args[1] in method_names || return expr
        length(call.args) >= 2 || return expr
        argument_type = generated_method_argument_type(call.args[2])
        access = if argument_type == decoder_name
            if decoder_access === nothing
                nothing
            elseif since_version > 0
                quote
                    if sbe_acting_version(m) >= $(version_expr(ir, since_version))
                        $decoder_access
                    end
                end
            else
                decoder_access
            end
        elseif argument_type == encoder_name
            encoder_access
        else
            nothing
        end
        access === nothing && return expr
        body = expr.args[2]
        expr.args[2] = Expr(:block, access, body)
        return expr
    end
    for argument in expr.args
        instrument_generated_field_methods!(
            argument,
            method_names,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            since_version,
            ir,
        )
    end
    return expr
end

function instrument_generated_field_methods!(
    exprs::Vector{Expr},
    field_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    decoder_access,
    encoder_access,
    since_version::Int,
    ir::IR.Ir,
)
    method_names = Set([field_name, Symbol(field_name, :!)])
    for expr in exprs
        instrument_generated_field_methods!(
            expr,
            method_names,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            since_version,
            ir,
        )
    end
    return exprs
end

function generate_encoded_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir;
    decoder_access=nothing,
    encoder_access=nothing,
)
    field_token = field_tokens[1]
    encoding_token = field_tokens[2]
    field_name = composite_member_field_name(field_token.name)
    primitive_type = encoding_token.encoding.primitive_type
    julia_type = IR.primitive_type_julia(primitive_type)
    julia_type_symbol = Symbol(julia_type)
    encoding_length = encoding_token.encoded_length
    is_constant = encoding_token.encoding.presence == IR.Presence.CONSTANT
    array_len = encoding_length > 0 ? encoding_length ÷ IR.primitive_type_size(primitive_type) : 1

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))

        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = Int($(field_token.offset))
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = Int($(field_token.offset))
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = Int($encoding_length)
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = Int($encoding_length)

        $(Symbol(field_name, :_null_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.null_value, primitive_type, IR.primitive_type_null)))
        $(Symbol(field_name, :_null_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.null_value, primitive_type, IR.primitive_type_null)))
        $(Symbol(field_name, :_min_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.min_value, primitive_type, IR.primitive_type_min)))
        $(Symbol(field_name, :_min_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.min_value, primitive_type, IR.primitive_type_min)))
        $(Symbol(field_name, :_max_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.max_value, primitive_type, IR.primitive_type_max)))
        $(Symbol(field_name, :_max_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(encoding_token.encoding.max_value, primitive_type, IR.primitive_type_max)))
    end)
    push!(exprs, field_meta_attribute_expr(field_name, abstract_type_name, field_token))

    if is_constant
        const_val = encoding_token.encoding.const_value === nothing ? IR.primitive_type_null(primitive_type) : encoding_token.encoding.const_value
        literal = primitive_value_literal(const_val, primitive_type)
        if const_val.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
            push!(exprs, quote
                @inline $field_name(::$decoder_name) = $(Meta.parse(literal))
                @inline $field_name(::Type{<:$decoder_name}) = $(Meta.parse(literal))
                export $field_name
            end)
        else
            push!(exprs, quote
                @inline $field_name(::$decoder_name) = $julia_type_symbol($(Meta.parse(literal)))
                @inline $field_name(::Type{<:$decoder_name}) = $julia_type_symbol($(Meta.parse(literal)))
                export $field_name
            end)
        end
        return instrument_generated_field_methods!(
            exprs,
            field_name,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            field_token.version,
            ir,
        )
    end

    if array_len == 1
        if field_token.version > 0
            null_val = encoding_literal(encoding_token.encoding.null_value, primitive_type, IR.primitive_type_null)
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return $julia_type_symbol($(null_val))
                    end
                    return decode_value($julia_type, m.buffer, m.offset + $(field_token.offset))
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, val)
                    encode_value($julia_type, m.buffer, m.offset + $(field_token.offset), val)
                    return m
                end

                export $field_name, $(Symbol(field_name, :!))
            end)
        else
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $(field_token.offset))
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, val)
                    encode_value($julia_type, m.buffer, m.offset + $(field_token.offset), val)
                    return m
                end

                export $field_name, $(Symbol(field_name, :!))
            end)
        end
        return instrument_generated_field_methods!(
            exprs,
            field_name,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            field_token.version,
            ir,
        )
    end

    is_char_array = primitive_type == IR.PrimitiveType.CHAR
    if is_char_array
        string_guard = string_encoding_guard_expr(
            something(encoding_token.encoding.character_encoding, "ASCII"),
            :value
        )
        length_error = "value exceeds fixed encoded length $array_len"
        push!(exprs, :(using StringViews: StringView))
        if field_token.version > 0
            null_val = encoding_literal(encoding_token.encoding.null_value, primitive_type, IR.primitive_type_null)
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return StringView(rstrip_nul(fill($julia_type_symbol($(null_val)), $array_len)))
                    end
                    bytes = decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    pos = findfirst(iszero, bytes)
                    len = pos !== nothing ? pos - 1 : Base.length(bytes)
                    return StringView(view(bytes, 1:len))
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name)
                    return encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractString)
                    $string_guard
                    bytes = codeunits(value)
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = Base.length(bytes)
                    @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                    copyto!(dest, 1, bytes, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                    return m
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = Base.length(value)
                    @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                    copyto!(dest, 1, value, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                    return m
                end

                export $field_name, $(Symbol(field_name, :!))
            end)
        else
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    bytes = decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    pos = findfirst(iszero, bytes)
                    len = pos !== nothing ? pos - 1 : Base.length(bytes)
                    return StringView(view(bytes, 1:len))
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name)
                    return encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractString)
                    $string_guard
                    bytes = codeunits(value)
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = Base.length(bytes)
                    @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                    copyto!(dest, 1, bytes, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                    return m
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = Base.length(value)
                    @boundscheck len <= Base.length(dest) || throw(ArgumentError($length_error))
                    copyto!(dest, 1, value, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                    return m
                end

                export $field_name, $(Symbol(field_name, :!))
            end)
        end
        return instrument_generated_field_methods!(
            exprs,
            field_name,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            field_token.version,
            ir,
        )
    end
    if field_token.version > 0
        null_val = encoding_literal(encoding_token.encoding.null_value, primitive_type, IR.primitive_type_null)
        push!(exprs, quote
            @inline function $field_name(m::$decoder_name)
                if m.acting_version < $(version_expr(ir, field_token.version))
                    return fill($julia_type_symbol($(null_val)), $array_len)
                end
                return decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
            end

            @inline function $field_name(m::$decoder_name, ::Type{T}) where {T<:NTuple}
                Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
                elem_type = Base.tuple_type_head(T)
                elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
                len = fieldcount(T)
                len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
                if m.acting_version < $(version_expr(ir, field_token.version))
                    return ntuple(_ -> $julia_type_symbol($(null_val)), Val(len))
                end
                x = decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                return ntuple(i -> x[i], Val(len))
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name)
                return encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, val)
                copyto!($(Symbol(field_name, :!))(m), val)
                return m
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, val::T) where {T<:NTuple}
                Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
                elem_type = Base.tuple_type_head(T)
                elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
                len = fieldcount(T)
                len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
                dest = $(Symbol(field_name, :!))(m)
                @inbounds for i in 1:$array_len
                    dest[i] = val[i]
                end
                return m
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
    else
        push!(exprs, quote
            @inline function $field_name(m::$decoder_name)
                return decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
            end

            @inline function $field_name(m::$decoder_name, ::Type{T}) where {T<:NTuple}
                Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
                elem_type = Base.tuple_type_head(T)
                elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
                len = fieldcount(T)
                len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
                x = decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                return ntuple(i -> x[i], Val(len))
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name)
                return encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, val)
                copyto!($(Symbol(field_name, :!))(m), val)
                return m
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, val::T) where {T<:NTuple}
                Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
                elem_type = Base.tuple_type_head(T)
                elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
                len = fieldcount(T)
                len == $array_len || throw(ArgumentError("Expected NTuple{$array_len,<:Real}"))
                dest = $(Symbol(field_name, :!))(m)
                @inbounds for i in 1:$array_len
                    dest[i] = val[i]
                end
                return m
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
    end

    return instrument_generated_field_methods!(
        exprs,
        field_name,
        decoder_name,
        encoder_name,
        decoder_access,
        encoder_access,
        field_token.version,
        ir,
    )
end

function generate_enum_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir;
    decoder_access=nothing,
    encoder_access=nothing,
)
    field_token = field_tokens[1]
    enum_token = field_tokens[2]
    field_name = composite_member_field_name(field_token.name)
    enum_module = composite_member_module_name(enum_token)
    encoding_type = enum_token.encoding.primitive_type
    julia_type = IR.primitive_type_julia(encoding_type)
    julia_type_symbol = Symbol(julia_type)
    offset = field_token.offset
    encoding_size = IR.primitive_type_size(encoding_type)

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))

        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = Int($offset)
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = Int($offset)
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = Int($encoding_size)
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = Int($encoding_size)

        $(Symbol(field_name, :_null_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(enum_token.encoding.null_value, encoding_type, IR.primitive_type_null)))
        $(Symbol(field_name, :_null_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(enum_token.encoding.null_value, encoding_type, IR.primitive_type_null)))
        $(Symbol(field_name, :_min_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(enum_token.encoding.min_value, encoding_type, IR.primitive_type_min)))
        $(Symbol(field_name, :_min_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(enum_token.encoding.min_value, encoding_type, IR.primitive_type_min)))
        $(Symbol(field_name, :_max_value))(::$abstract_type_name) = $julia_type_symbol($(encoding_literal(enum_token.encoding.max_value, encoding_type, IR.primitive_type_max)))
        $(Symbol(field_name, :_max_value))(::Type{<:$abstract_type_name}) = $julia_type_symbol($(encoding_literal(enum_token.encoding.max_value, encoding_type, IR.primitive_type_max)))
    end)
    push!(exprs, field_meta_attribute_expr(field_name, abstract_type_name, field_token))

    if field_token.encoding.presence == IR.Presence.CONSTANT
        const_value = field_token.encoding.const_value
        null_val = encoding_literal(enum_token.encoding.null_value, encoding_type, IR.primitive_type_null)
        if const_value !== nothing
            const_str = const_value.value
            dot_index = findlast(==('.'), const_str)
            value_name = dot_index === nothing ? const_str : const_str[(dot_index + 1):end]
            value_symbol = Symbol(value_name)
            enum_value_expr = Expr(:., enum_module, value_symbol)
            int_value_expr = Expr(:call, julia_type_symbol, enum_value_expr)
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return $julia_type_symbol($(null_val))
                    end
                    return $int_value_expr
                end

                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return $enum_module.NULL_VALUE
                    end
                    return $enum_value_expr
                end
                export $field_name
            end)
        else
            literal = encoding_literal(enum_token.encoding.const_value, encoding_type, IR.primitive_type_null)
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return $julia_type_symbol($(null_val))
                    end
                    return $julia_type_symbol($literal)
                end

                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < $(version_expr(ir, field_token.version))
                        return $enum_module.NULL_VALUE
                    end
                    return $enum_module.SbeEnum($literal)
                end
                export $field_name
            end)
        end
        return instrument_generated_field_methods!(
            exprs,
            field_name,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            field_token.version,
            ir,
        )
    end

    if field_token.version > 0
        null_val = encoding_literal(enum_token.encoding.null_value, encoding_type, IR.primitive_type_null)
        push!(exprs, quote
            @inline function $field_name(m::$decoder_name, ::Type{Integer})
                if m.acting_version < $(version_expr(ir, field_token.version))
                    return $julia_type_symbol($(null_val))
                end
                return decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
            end

            @inline function $field_name(m::$decoder_name)
                if m.acting_version < $(version_expr(ir, field_token.version))
                    return $enum_module.SbeEnum($julia_type_symbol($(null_val)))
                end
                raw = decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
                return $enum_module.SbeEnum(raw)
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::$enum_module.SbeEnum)
                encode_value($julia_type_symbol, m.buffer, m.offset + $offset, $julia_type_symbol(value))
                return m
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
        return instrument_generated_field_methods!(
            exprs,
            field_name,
            decoder_name,
            encoder_name,
            decoder_access,
            encoder_access,
            field_token.version,
            ir,
        )
    end

    push!(exprs, quote
        @inline function $field_name(m::$decoder_name, ::Type{Integer})
            return decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
        end

        @inline function $field_name(m::$decoder_name)
            raw = decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
            return $enum_module.SbeEnum(raw)
        end

        @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::$enum_module.SbeEnum)
            encode_value($julia_type_symbol, m.buffer, m.offset + $offset, $julia_type_symbol(value))
            return m
        end

        export $field_name, $(Symbol(field_name, :!))
    end)

    return instrument_generated_field_methods!(
        exprs,
        field_name,
        decoder_name,
        encoder_name,
        decoder_access,
        encoder_access,
        field_token.version,
        ir,
    )
end

function generate_set_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir;
    decoder_access=nothing,
    encoder_access=nothing,
)
    field_token = field_tokens[1]
    set_token = field_tokens[2]
    field_name = composite_member_field_name(field_token.name)
    set_module = composite_member_module_name(set_token)
    julia_type = IR.primitive_type_julia(set_token.encoding.primitive_type)
    offset = field_token.offset
    encoding_size = IR.primitive_type_size(set_token.encoding.primitive_type)

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))

        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = Int($offset)
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = Int($offset)
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = Int($encoding_size)
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = Int($encoding_size)
    end)
    push!(exprs, field_meta_attribute_expr(field_name, abstract_type_name, field_token))

    push!(exprs, quote
        @inline function $field_name(m::$decoder_name)
            return $set_module.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end

        @inline function $field_name(m::$encoder_name)
            return $set_module.Encoder(m.buffer, m.offset + $offset)
        end

        export $field_name
    end)

    return instrument_generated_field_methods!(
        exprs,
        field_name,
        decoder_name,
        encoder_name,
        decoder_access,
        encoder_access,
        field_token.version,
        ir,
    )
end

function generate_composite_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir;
    decoder_access=nothing,
    encoder_access=nothing,
)
    field_token = field_tokens[1]
    composite_token = field_tokens[2]
    field_name = composite_member_field_name(field_token.name)
    composite_module = composite_member_module_name(composite_token)
    composite_size = composite_token.encoded_length
    offset = field_token.offset

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = $offset
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = $offset
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = $composite_size
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = $composite_size
    end)
    push!(exprs, field_meta_attribute_expr(field_name, abstract_type_name, field_token))

    push!(exprs, quote
        @inline function $field_name(m::$decoder_name)
            return $composite_module.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end

        @inline function $field_name(m::$encoder_name)
            return $composite_module.Encoder(m.buffer, m.offset + $offset)
        end

        export $field_name
    end)

    return instrument_generated_field_methods!(
        exprs,
        field_name,
        decoder_name,
        encoder_name,
        decoder_access,
        encoder_access,
        field_token.version,
        ir,
    )
end

function generate_var_data_expr(
    var_data_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir;
    external_tail::Bool=false,
    decoder_model::Union{Nothing, FieldPrecedenceModel}=nothing,
    encoder_model::Union{Nothing, FieldPrecedenceModel}=nothing,
    qualified_path::String=var_data_tokens[1].name,
)
    field_token = var_data_tokens[1]
    accessor_name = Symbol(format_property_name(field_token.name))
    length_name = Symbol(string(accessor_name, "_length"))
    length_name_setter = Symbol(string(accessor_name, "_length!"))
    skip_name = Symbol(string("skip_", accessor_name, "!"))
    buffer_name = Symbol(string(accessor_name, "_buffer!"))
    accessor_setter = Symbol(string(accessor_name, "!"))
    external_setter = Symbol(string(accessor_name, "_external!"))
    since_version = field_token.version

    length_token = find_first_token("length", var_data_tokens, 1)
    var_data_token = find_first_token("varData", var_data_tokens, 1)

    length_type = IR.primitive_type_julia(length_token.encoding.primitive_type)
    length_type_symbol = Symbol(length_type)
    header_length = length_token.encoded_length
    max_literal = encoding_literal(length_token.encoding.max_value, length_token.encoding.primitive_type, IR.primitive_type_max)
    returns_string = var_data_token.encoding.primitive_type == IR.PrimitiveType.CHAR
    bytes_accessor = Symbol(string(accessor_name, "_bytes"))
    string_guard = string_encoding_guard_expr(
        var_data_token.encoding.character_encoding,
        :src
    )
    decoder_access = decoder_model === nothing ? nothing :
        precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_field_key(qualified_path),
        )
    encoder_access = encoder_model === nothing ? nothing :
        precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_field_key(qualified_path),
        )
    decoder_length_access = decoder_model === nothing ? nothing :
        precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_var_data_length_key(qualified_path),
        )
    decoded_length_name = decoder_model === nothing ?
        length_name : Symbol("_", length_name)

    exprs = Expr[]

    push!(exprs, field_meta_attribute_expr(accessor_name, abstract_type_name, field_token))

    if var_data_token.encoding.character_encoding !== nothing
        push!(exprs, quote
            $(Symbol(accessor_name, :_character_encoding))(::$abstract_type_name) = $(var_data_token.encoding.character_encoding)
            $(Symbol(accessor_name, :_character_encoding))(::Type{<:$abstract_type_name}) = $(var_data_token.encoding.character_encoding)
        end)
    end

    push!(exprs, quote
        const $(Symbol(accessor_name, :_id)) = $(template_id_expr(ir, field_token.id))
        const $(Symbol(accessor_name, :_since_version)) = $(version_expr(ir, since_version))
        const $(Symbol(accessor_name, :_header_length)) = $header_length
        $(Symbol(accessor_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, since_version))
    end)

    if decoder_model !== nothing && since_version > 0
        push!(exprs, quote
            @inline function $decoded_length_name(m::$decoder_name)
                if sbe_acting_version(m) < $(version_expr(ir, since_version))
                    return $length_type_symbol(0)
                end
                return decode_value($length_type, m.buffer, sbe_position(m))
            end

            @inline function $length_name(m::$decoder_name)
                if sbe_acting_version(m) < $(version_expr(ir, since_version))
                    return $length_type_symbol(0)
                end
                $decoder_length_access
                return $decoded_length_name(m)
            end
        end)
    elseif decoder_model !== nothing
        push!(exprs, quote
            @inline function $decoded_length_name(m::$decoder_name)
                return decode_value($length_type, m.buffer, sbe_position(m))
            end

            @inline function $length_name(m::$decoder_name)
                $decoder_length_access
                return $decoded_length_name(m)
            end
        end)
    elseif since_version > 0
        push!(exprs, quote
            @inline function $length_name(m::$abstract_type_name)
                if sbe_acting_version(m) < $(version_expr(ir, since_version))
                    return $length_type_symbol(0)
                end
                return decode_value($length_type, m.buffer, sbe_position(m))
            end
        end)
    else
        push!(exprs, quote
            @inline function $length_name(m::$abstract_type_name)
                return decode_value($length_type, m.buffer, sbe_position(m))
            end
        end)
    end

    push!(exprs, quote
        @inline function $length_name_setter(m::$encoder_name, n)
            @boundscheck (n < 0 || n > $max_literal) && throw(ArgumentError("length outside schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + $header_length + n)
            return encode_value($length_type, m.buffer, sbe_position(m), $length_type_symbol(n))
        end
    end)

    skip_missing_guard = if since_version > 0
        quote
            if sbe_acting_version(m) < $(version_expr(ir, since_version))
                return $length_type_symbol(0)
            end
        end
    else
        :(nothing)
    end

    push!(exprs, quote
        @inline function $skip_name(m::$decoder_name)
            $skip_missing_guard
            $(decoder_access === nothing ? :(nothing) : decoder_access)
            len = $decoded_length_name(m)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            return len
        end
    end)

    empty_view_guard = if since_version > 0
        quote
            if sbe_acting_version(m) < $(version_expr(ir, since_version))
                pos = sbe_position(m)
                return view(m.buffer, pos+1:pos)
            end
        end
    else
        :(nothing)
    end

    external_decode_missing_guard = if since_version > 0
        quote
            if sbe_acting_version(m) < $(version_expr(ir, since_version))
                return sbe_external_tail(
                    m.buffer,
                    Int(sbe_position(m)),
                    0
                )
            end
        end
    else
        :(nothing)
    end

    external_decode_body = quote
        $external_decode_missing_guard
        $(decoder_access === nothing ? :(nothing) : decoder_access)
        len = $decoded_length_name(m)
        payload_pos = Base.Checked.checked_add(
            Int(sbe_position(m)),
            $header_length
        )
        logical_end = Base.Checked.checked_add(payload_pos, Int(len))
        tail = sbe_external_tail(m.buffer, payload_pos, Int(len))
        sbe_position!(m, logical_end)
        return tail
    end

    if returns_string
        push!(exprs, quote
            @inline function $bytes_accessor(m::$decoder_name)
                $empty_view_guard
                $(decoder_access === nothing ? :(nothing) : decoder_access)
                len = $decoded_length_name(m)
                pos = sbe_position(m) + $header_length
                sbe_position!(m, pos + len)
                return view(m.buffer, pos+1:pos+len)
            end
        end)
        if external_tail
            push!(exprs, quote
                @inline function $bytes_accessor(
                    m::$decoder_name{T}
                ) where {T <: SbeFrame}
                    $external_decode_body
                end
            end)
        end
        push!(exprs, quote
            @inline function $accessor_name(m::$decoder_name)
                return StringView(rstrip_nul($bytes_accessor(m)))
            end
        end)
    else
        push!(exprs, quote
            @inline function $accessor_name(m::$decoder_name)
                $empty_view_guard
                $(decoder_access === nothing ? :(nothing) : decoder_access)
                len = $decoded_length_name(m)
                pos = sbe_position(m) + $header_length
                sbe_position!(m, pos + len)
                return view(m.buffer, pos+1:pos+len)
            end
        end)
        if external_tail
            push!(exprs, quote
                @inline function $accessor_name(
                    m::$decoder_name{T}
                ) where {T <: SbeFrame}
                    $external_decode_body
                end
            end)
        end
    end

    push!(exprs, quote
        @inline function $buffer_name(m::$encoder_name, len)
            $(encoder_access === nothing ? :(nothing) : encoder_access)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            return view(m.buffer, pos+1:pos+len)
        end
    end)

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::AbstractArray)
            $(encoder_access === nothing ? :(nothing) : encoder_access)
            len = sizeof(eltype(src)) * Base.length(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, reinterpret(UInt8, src))
            return m
        end
    end)

    if external_tail
        push!(exprs, quote
            @inline function $external_setter(
                m::$encoder_name,
                src::AbstractVector{UInt8}
            )
                $(encoder_access === nothing ? :(nothing) : encoder_access)
                Base.require_one_based_indexing(src)
                len = length(src)
                (len > $max_literal) &&
                    throw(ArgumentError("length outside schema limit"))

                pos = Int(sbe_position(m))
                payload_pos = Base.Checked.checked_add(pos, $header_length)
                logical_end = Base.Checked.checked_add(payload_pos, len)
                @boundscheck checkbounds(m.buffer, payload_pos)
                encode_value(
                    $length_type,
                    m.buffer,
                    pos,
                    $length_type_symbol(len)
                )

                prefix_start = Base.Checked.checked_add(
                    Int(sbe_frame_offset(m)),
                    1
                )
                prefix = view(m.buffer, prefix_start:payload_pos)
                frame = SbeFrame(prefix, src)
                sbe_position!(m, logical_end)
                return frame
            end

            @inline function $external_setter(
                m::$encoder_name,
                src::AbstractString
            )
                $string_guard
                return $external_setter(m, codeunits(src))
            end
        end)
    end

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::NTuple)
            $(encoder_access === nothing ? :(nothing) : encoder_access)
            len = sizeof(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, reinterpret(NTuple{len,UInt8}, src))
            return m
        end
    end)

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::AbstractString)
            $(encoder_access === nothing ? :(nothing) : encoder_access)
            $string_guard
            len = sizeof(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            bytes = codeunits(src)
            @inbounds for index in eachindex(bytes)
                m.buffer[pos + index] = bytes[index]
            end
            return m
        end
    end)

    push!(exprs, quote
        @inline $accessor_setter(m::$encoder_name, src::Symbol) = $accessor_setter(m, to_string(src))
        @inline $accessor_setter(m::$encoder_name, src::Real) = $accessor_setter(m, Tuple(src))
        @inline function $accessor_setter(m::$encoder_name, ::Nothing)
            $buffer_name(m, 0)
            return m
        end
    end)

    push!(exprs, quote
        @inline function $accessor_name(m::$decoder_name, ::Type{String})
            return String(StringView(rstrip_nul($(returns_string ? bytes_accessor : accessor_name)(m))))
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:AbstractString}
            return StringView(rstrip_nul($(returns_string ? bytes_accessor : accessor_name)(m)))
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:Symbol}
            return Symbol($accessor_name(m, StringView))
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:Real}
            return reinterpret(T, $(returns_string ? bytes_accessor : accessor_name)(m))[]
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{AbstractArray{T}}) where {T<:Real}
            return reinterpret(T, $(returns_string ? bytes_accessor : accessor_name)(m))
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:NTuple}
            Base.isconcretetype(T) || throw(ArgumentError("NTuple type must be concrete"))
            elem_type = Base.tuple_type_head(T)
            elem_type <: Real || throw(ArgumentError("NTuple element type must be Real"))
            x = reinterpret(elem_type, $(returns_string ? bytes_accessor : accessor_name)(m))
            return ntuple(i -> x[i], Val(fieldcount(T)))
        end
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:Nothing}
            $skip_name(m)
            return nothing
        end
    end)

    documentation = var_data_accessor_doc(var_data_tokens)
    push!(exprs, generated_binding_doc_expr(documentation, accessor_name))
    push!(exprs, generated_binding_doc_expr(documentation, accessor_setter))
    if external_tail
        external_documentation = """
            $external_setter(encoder, bytes) -> SbeFrame

        Encode the length header for the terminal `$(field_token.name)` variable-data field without copying `bytes` into the encoder buffer. The returned logical frame retains the encoded prefix and external tail; pass `SBE.sbe_regions(frame)` to a scatter/gather transport or decode the frame directly.

        This method is generated only for the final top-level variable-data field. Encoding cannot continue after attaching the external tail. The source must remain unchanged while the frame is in use.
        """
        push!(
            exprs,
            generated_binding_doc_expr(external_documentation, external_setter)
        )
    end
    push!(exprs, quote
        export $accessor_name, $accessor_setter
    end)
    if external_tail
        push!(exprs, :(export $external_setter))
    end

    return exprs
end

function generate_group_expr(
    group_tokens::Vector{IR.Token},
    parent_abstract_type::Symbol,
    parent_encoder_name::Symbol,
    ir::IR.Ir,
    module_depth::Int;
    precedence_checks::Bool=false,
    decoder_model::Union{Nothing, FieldPrecedenceModel}=nothing,
    encoder_model::Union{Nothing, FieldPrecedenceModel}=nothing,
    parent_path::String="",
    root_message_name::Symbol=Symbol("Message"),
    precedence_helper_names::Vector{Symbol}=Symbol[],
)
    group_token = group_tokens[1]
    group_name = group_token.name
    group_module_name = Symbol(format_struct_name(group_name))
    abstract_type_name = Symbol(string("Abstract", group_module_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    group_path = precedence_qualified_name(parent_path, group_name)

    dimension_tokens = group_tokens[2:1 + group_tokens[2].component_token_count]
    dimension_module_name = Symbol(format_struct_name(dimension_tokens[1].name))
    dimension_header_length = dimension_tokens[1].encoded_length
    block_length = group_token.encoded_length
    group_id = group_token.id
    since_version = group_token.version
    version_type_symbol = header_field_type(ir, "version")

    num_in_group_token = find_first_token("numInGroup", dimension_tokens, 1)
    max_count = primitive_value_int(num_in_group_token.encoding.max_value, num_in_group_token.encoding.primitive_type, IR.primitive_type_max)
    min_count = primitive_value_int(num_in_group_token.encoding.min_value, num_in_group_token.encoding.primitive_type, IR.primitive_type_min)
    min_check = min_count > 0 ? :(count < $min_count) : nothing
    count_type_symbol = IR.primitive_type_julia(num_in_group_token.encoding.primitive_type)
    count_zero_expr = :($count_type_symbol(0))

    body_start = 2 + dimension_tokens[1].component_token_count
    fields, idx = split_components(group_tokens, IR.Signal.BEGIN_FIELD, body_start)
    groups, idx = split_components(group_tokens, IR.Signal.BEGIN_GROUP, idx)
    var_data, _ = split_components(group_tokens, IR.Signal.BEGIN_VAR_DATA, idx)

    field_exprs = Expr[]
    field_doc_exprs = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}([dimension_module_name])
    group_exprs = Expr[]
    parent_accessors = Expr[]
    skip_calls = Expr[]

    for field_tokens in fields
        inner = field_tokens[2]
        field_path = precedence_qualified_name(
            group_path,
            field_tokens[1].name,
        )
        decoder_access = precedence_checks ? precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_field_key(field_path),
        ) : nothing
        encoder_access = precedence_checks ? precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_field_key(field_path),
        ) : nothing
        documentation = field_accessor_doc(field_tokens)
        push!(
            field_doc_exprs,
            generated_binding_doc_expr(
                documentation,
                composite_member_field_name(field_tokens[1].name)
            )
        )
        if field_has_setter(field_tokens)
            push!(
                field_doc_exprs,
                generated_binding_doc_expr(
                    documentation,
                    Symbol(composite_member_field_name(field_tokens[1].name), :!)
                )
            )
        end
        if inner.signal == IR.Signal.ENCODING
            append!(field_exprs, generate_encoded_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_ENUM
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_enum_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_SET
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_set_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_COMPOSITE
            push!(composite_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_composite_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        end
    end

    for nested_group_tokens in groups
        nested_group_exprs, nested_accessors, nested_accessor_name, nested_group_module_name = generate_group_expr(
            nested_group_tokens,
            abstract_type_name,
            encoder_name,
            ir,
            module_depth + 1;
            precedence_checks=precedence_checks,
            decoder_model=decoder_model,
            encoder_model=encoder_model,
            parent_path=group_path,
            root_message_name=root_message_name,
            precedence_helper_names=precedence_helper_names,
        )
        append!(group_exprs, nested_group_exprs)
        append!(group_exprs, nested_accessors)
        push!(skip_calls, quote
            for group in $nested_accessor_name(m)
                $nested_group_module_name.sbe_skip!(group)
            end
        end)
    end

    var_data_exprs = Expr[]
    for var_data_tokens in var_data
        name_symbol = Symbol(format_property_name(var_data_tokens[1].name))
        skip_name = Symbol(string("skip_", name_symbol, "!"))
        push!(skip_calls, :($skip_name(m)))
        append!(
            var_data_exprs,
            generate_var_data_expr(
                var_data_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_model=decoder_model,
                encoder_model=encoder_model,
                qualified_path=precedence_qualified_name(
                    group_path,
                    var_data_tokens[1].name,
                ),
            ),
        )
    end

    endian_imports = generate_encoded_types_expr(ir.byte_order)
    precedence_group_import = precedence_checks ?
        precedence_relative_import_expr(
            module_depth,
            root_message_name,
            precedence_helper_names,
        ) : Expr(:block)

    dimension_decoder = Expr(:., dimension_module_name, :Decoder)
    dimension_encoder = Expr(:., dimension_module_name, :Encoder)
    block_length_get = Expr(:., dimension_module_name, :blockLength)
    block_length_set = Expr(:., dimension_module_name, :blockLength!)
    num_in_group_get = Expr(:., dimension_module_name, :numInGroup)
    num_in_group_set = Expr(:., dimension_module_name, :numInGroup!)

    precedence_runtime_import = precedence_checks ?
        :(using SBE: CodecStatePointer) : Expr(:block)

    group_struct_exprs = if precedence_checks
        Expr[
            extract_expr_from_quote(quote
                mutable struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                    buffer::T
                    offset::Int64
                    position_ptr::PositionPointer
                    block_length::UInt16
                    acting_version::$version_type_symbol
                    count::$count_type_symbol
                    index::$count_type_symbol
                    codec_state::CodecStatePointer
                    function $decoder_name(
                        buffer::T,
                        offset::Integer,
                        position_ptr::PositionPointer,
                        block_length::Integer,
                        acting_version::Integer,
                        count::Integer,
                        index::Integer,
                        codec_state::CodecStatePointer,
                    ) where {T}
                        new{T}(
                            buffer,
                            offset,
                            position_ptr,
                            block_length,
                            acting_version,
                            $count_type_symbol(count),
                            $count_type_symbol(index),
                            codec_state,
                        )
                    end
                end
            end, :struct),
            extract_expr_from_quote(quote
                mutable struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                    buffer::T
                    offset::Int64
                    position_ptr::PositionPointer
                    initial_position::Int64
                    count::$count_type_symbol
                    index::$count_type_symbol
                    codec_state::CodecStatePointer
                    function $encoder_name(
                        buffer::T,
                        offset::Integer,
                        position_ptr::PositionPointer,
                        initial_position::Int64,
                        count::Integer,
                        index::Integer,
                        codec_state::CodecStatePointer,
                    ) where {T}
                        new{T}(
                            buffer,
                            offset,
                            position_ptr,
                            initial_position,
                            $count_type_symbol(count),
                            $count_type_symbol(index),
                            codec_state,
                        )
                    end
                end
            end, :struct),
        ]
    else
        Expr[
            extract_expr_from_quote(quote
                mutable struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                    buffer::T
                    offset::Int64
                    position_ptr::PositionPointer
                    block_length::UInt16
                    acting_version::$version_type_symbol
                    count::$count_type_symbol
                    index::$count_type_symbol
                    function $decoder_name(buffer::T, offset::Integer, position_ptr::PositionPointer,
                        block_length::Integer, acting_version::Integer,
                        count::Integer, index::Integer) where {T}
                        new{T}(buffer, offset, position_ptr, block_length, acting_version,
                            $count_type_symbol(count), $count_type_symbol(index))
                    end
                end
            end, :struct),
            extract_expr_from_quote(quote
                mutable struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                    buffer::T
                    offset::Int64
                    position_ptr::PositionPointer
                    initial_position::Int64
                    count::$count_type_symbol
                    index::$count_type_symbol
                    function $encoder_name(buffer::T, offset::Integer, position_ptr::PositionPointer,
                        initial_position::Int64, count::Integer, index::Integer) where {T}
                        new{T}(buffer, offset, position_ptr, initial_position,
                            $count_type_symbol(count), $count_type_symbol(index))
                    end
                end
            end, :struct),
        ]
    end

    group_wrap_exprs = if precedence_checks
        Expr[
            quote
                @inline function $decoder_name(
                    buffer,
                    position_ptr::PositionPointer,
                    acting_version,
                    codec_state::CodecStatePointer,
                )
                    dimensions = $dimension_decoder(buffer, position_ptr[])
                    position_ptr[] += $dimension_header_length
                    return $decoder_name(
                        buffer,
                        0,
                        position_ptr,
                        $block_length_get(dimensions),
                        acting_version,
                        $num_in_group_get(dimensions),
                        $count_zero_expr,
                        codec_state,
                    )
                end
            end,
            quote
                @inline function reset!(
                    g::$decoder_name{T},
                    buffer::T,
                    position_ptr::PositionPointer,
                    acting_version,
                    codec_state::CodecStatePointer,
                ) where {T}
                    dimensions = $dimension_decoder(buffer, position_ptr[])
                    position_ptr[] += $dimension_header_length
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.block_length = $block_length_get(dimensions)
                    g.acting_version = acting_version
                    g.count = $num_in_group_get(dimensions)
                    g.index = $count_zero_expr
                    g.codec_state = codec_state
                    return g
                end
            end,
            quote
                @inline function reset_missing!(
                    g::$decoder_name{T},
                    buffer::T,
                    position_ptr::PositionPointer,
                    acting_version,
                    codec_state::CodecStatePointer,
                ) where {T}
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.block_length = $(version_expr(ir, 0))
                    g.acting_version = acting_version
                    g.count = $count_zero_expr
                    g.index = $count_zero_expr
                    g.codec_state = codec_state
                    return g
                end
            end,
            quote
                @inline function wrap!(
                    g::$decoder_name{T},
                    buffer::T,
                    position_ptr::PositionPointer,
                    acting_version,
                    codec_state::CodecStatePointer,
                ) where {T}
                    return reset!(
                        g,
                        buffer,
                        position_ptr,
                        acting_version,
                        codec_state,
                    )
                end
            end,
            quote
                @inline function $encoder_name(
                    buffer,
                    count,
                    position_ptr::PositionPointer,
                    codec_state::CodecStatePointer,
                )
                    if $(min_check === nothing ? :(count > $max_count) : :($min_check || count > $max_count))
                        error("count outside of allowed range")
                    end
                    dimensions = $dimension_encoder(buffer, position_ptr[])
                    $block_length_set(
                        dimensions,
                        $(block_length_expr(ir, block_length)),
                    )
                    $num_in_group_set(dimensions, count)
                    initial_position = position_ptr[]
                    position_ptr[] += $dimension_header_length
                    return $encoder_name(
                        buffer,
                        0,
                        position_ptr,
                        initial_position,
                        count,
                        $count_zero_expr,
                        codec_state,
                    )
                end
            end,
            quote
                @inline function wrap!(
                    g::$encoder_name{T},
                    buffer::T,
                    count,
                    position_ptr::PositionPointer,
                    codec_state::CodecStatePointer,
                ) where {T}
                    if $(min_check === nothing ? :(count > $max_count) : :($min_check || count > $max_count))
                        error("count outside of allowed range")
                    end
                    dimensions = $dimension_encoder(buffer, position_ptr[])
                    $block_length_set(
                        dimensions,
                        $(block_length_expr(ir, block_length)),
                    )
                    $num_in_group_set(dimensions, count)
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.initial_position = position_ptr[]
                    g.count = $count_type_symbol(count)
                    g.index = $count_zero_expr
                    g.codec_state = codec_state
                    position_ptr[] += $dimension_header_length
                    return g
                end
            end,
        ]
    else
        Expr[
            quote
                @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version)
                    dimensions = $dimension_decoder(buffer, position_ptr[])
                    position_ptr[] += $dimension_header_length
                    return $decoder_name(buffer, 0, position_ptr, $block_length_get(dimensions),
                        acting_version, $num_in_group_get(dimensions), $count_zero_expr)
                end
            end,
            quote
                @inline function reset!(g::$decoder_name{T}, buffer::T, position_ptr::PositionPointer, acting_version) where {T}
                    dimensions = $dimension_decoder(buffer, position_ptr[])
                    position_ptr[] += $dimension_header_length
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.block_length = $block_length_get(dimensions)
                    g.acting_version = acting_version
                    g.count = $num_in_group_get(dimensions)
                    g.index = $count_zero_expr
                    return g
                end
            end,
            quote
                @inline function reset_missing!(g::$decoder_name{T}, buffer::T, position_ptr::PositionPointer, acting_version) where {T}
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.block_length = $(version_expr(ir, 0))
                    g.acting_version = acting_version
                    g.count = $count_zero_expr
                    g.index = $count_zero_expr
                    return g
                end
            end,
            quote
                @inline function wrap!(g::$decoder_name{T}, buffer::T, position_ptr::PositionPointer, acting_version) where {T}
                    return reset!(g, buffer, position_ptr, acting_version)
                end
            end,
            quote
                @inline function $encoder_name(buffer, count, position_ptr::PositionPointer)
                    if $(min_check === nothing ? :(count > $max_count) : :($min_check || count > $max_count))
                        error("count outside of allowed range")
                    end
                    dimensions = $dimension_encoder(buffer, position_ptr[])
                    $block_length_set(dimensions, $(block_length_expr(ir, block_length)))
                    $num_in_group_set(dimensions, count)
                    initial_position = position_ptr[]
                    position_ptr[] += $dimension_header_length
                    return $encoder_name(buffer, 0, position_ptr, initial_position, count, $count_zero_expr)
                end
            end,
            quote
                @inline function wrap!(g::$encoder_name{T}, buffer::T, count, position_ptr::PositionPointer) where {T}
                    if $(min_check === nothing ? :(count > $max_count) : :($min_check || count > $max_count))
                        error("count outside of allowed range")
                    end
                    dimensions = $dimension_encoder(buffer, position_ptr[])
                    $block_length_set(dimensions, $(block_length_expr(ir, block_length)))
                    $num_in_group_set(dimensions, count)
                    g.buffer = buffer
                    g.offset = 0
                    g.position_ptr = position_ptr
                    g.initial_position = position_ptr[]
                    g.count = $count_type_symbol(count)
                    g.index = $count_zero_expr
                    position_ptr[] += $dimension_header_length
                    return g
                end
            end,
        ]
    end

    group_iteration_exprs = if precedence_checks
        decoder_next = precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_group_next_key(group_path),
            :g,
        )
        decoder_last = precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_group_last_key(group_path),
            :g,
        )
        encoder_next = precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_group_next_key(group_path),
            :g,
        )
        encoder_last = precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_group_last_key(group_path),
            :g,
        )
        encoder_reset = precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_group_reset_key(group_path),
            :g,
        )
        Expr[
            quote
                @inline function next!(g::$decoder_name)
                    g.index < g.count || error("index >= count")
                    remaining = Int(g.count) - Int(g.index)
                    if remaining > 1
                        $decoder_next
                    else
                        $decoder_last
                    end
                    g.offset = sbe_position(g)
                    sbe_position!(g, g.offset + sbe_acting_block_length(g))
                    g.index += one($count_type_symbol)
                    return g
                end
            end,
            quote
                @inline function next!(g::$encoder_name)
                    g.index < g.count || error("index >= count")
                    remaining = Int(g.count) - Int(g.index)
                    if remaining > 1
                        $encoder_next
                    else
                        $encoder_last
                    end
                    g.offset = sbe_position(g)
                    sbe_position!(g, g.offset + sbe_acting_block_length(g))
                    g.index += one($count_type_symbol)
                    return g
                end
            end,
            quote
                function Base.iterate(g::$decoder_name, state=nothing)
                    g.index < g.count || return nothing
                    return next!(g), state
                end
            end,
            quote
                function Base.iterate(g::$encoder_name, state=nothing)
                    g.index < g.count || return nothing
                    return next!(g), state
                end
            end,
            quote
                function reset_count_to_index!(g::$encoder_name)
                    $encoder_reset
                    g.count = g.index
                    dimensions = $dimension_encoder(
                        g.buffer,
                        g.initial_position,
                    )
                    $num_in_group_set(dimensions, g.count)
                    return g.count
                end
            end,
        ]
    else
        Expr[
            quote
                @inline function next!(g::$abstract_type_name)
                    if g.index >= g.count
                        error("index >= count")
                    end
                    g.offset = sbe_position(g)
                    sbe_position!(g, g.offset + sbe_acting_block_length(g))
                    g.index += one($count_type_symbol)
                    return g
                end
            end,
            quote
                function Base.iterate(g::$abstract_type_name, state=nothing)
                    if g.index < g.count
                        g.offset = sbe_position(g)
                        sbe_position!(g, g.offset + sbe_acting_block_length(g))
                        g.index += one($count_type_symbol)
                        return g, state
                    else
                        return nothing
                    end
                end
            end,
            quote
                function reset_count_to_index!(g::$encoder_name)
                    g.count = g.index
                    dimensions = $dimension_encoder(g.buffer, g.initial_position)
                    $num_in_group_set(dimensions, g.count)
                    return g.count
                end
            end,
        ]
    end

    group_quoted = quote
        module $group_module_name
        using SBE: AbstractSbeGroup, PositionPointer, to_string
        import SBE: sbe_header_size, sbe_block_length, sbe_acting_block_length, sbe_acting_version
        import SBE: sbe_position, sbe_position!, sbe_position_ptr, next!
        $precedence_group_import
        $precedence_runtime_import
        using StringViews: StringView
        $([relative_using_expr(module_depth, enum_name) for enum_name in enum_imports]...)
        $([relative_using_expr(module_depth, composite_name) for composite_name in composite_imports]...)

        $endian_imports

        @inline function rstrip_nul(a::Union{AbstractString,AbstractArray})
            pos = findfirst(iszero, a)
            len = pos !== nothing ? pos - 1 : Base.length(a)
            return view(a, 1:len)
        end

        abstract type $abstract_type_name{T} <: AbstractSbeGroup end

        $(group_struct_exprs...)

        $(generated_binding_doc_expr(
            "Abstract flyweight type for the generated `$(group_token.name)` repeating-group codec.",
            abstract_type_name
        ))
        $(generated_binding_doc_expr(
            "Stateful zero-copy decoder for the `$(group_token.name)` repeating group. Iteration reuses this object for each entry.",
            decoder_name
        ))
        $(generated_binding_doc_expr(
            "Stateful zero-copy encoder for the `$(group_token.name)` repeating group.",
            encoder_name
        ))

        $(group_wrap_exprs...)

        sbe_header_size(::$abstract_type_name) = $dimension_header_length
        sbe_header_size(::Type{<:$abstract_type_name}) = $dimension_header_length
        sbe_block_length(::$abstract_type_name) = $(block_length_expr(ir, block_length))
        sbe_block_length(::Type{<:$abstract_type_name}) = $(block_length_expr(ir, block_length))
        sbe_acting_block_length(g::$decoder_name) = g.block_length
        sbe_acting_block_length(g::$encoder_name) = $(block_length_expr(ir, block_length))
        sbe_acting_version(g::$decoder_name) = g.acting_version
        sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))
        sbe_acting_version(::Type{<:$abstract_type_name}) = $(version_expr(ir, ir.version))
        sbe_position(g::$abstract_type_name) = g.position_ptr[]
        @inline sbe_position!(g::$abstract_type_name, position) = g.position_ptr[] = position
        sbe_position_ptr(g::$abstract_type_name) = g.position_ptr
        $(group_iteration_exprs...)
        Base.eltype(::Type{<:$decoder_name}) = $decoder_name
        Base.eltype(::Type{<:$encoder_name}) = $encoder_name
        Base.isdone(g::$abstract_type_name, state=nothing) = g.index >= g.count
        Base.length(g::$abstract_type_name) = Int(g.count)

        $(generated_binding_doc_expr(
            "Set the encoded group count to the number of entries written and return the resulting count.",
            :reset_count_to_index!
        ))

        export reset_count_to_index!

        $(field_exprs...)
        $(field_doc_exprs...)
        $(var_data_exprs...)
        $(group_exprs...)

        @inline function sbe_skip!(m::$decoder_name)
            $(isempty(skip_calls) ? :(return) : Expr(:block, skip_calls...))
            return
        end

        export $abstract_type_name, $decoder_name, $encoder_name
        end
    end

    group_body = generated_doc_expr(
        group_codec_doc(group_token),
        extract_expr_from_quote(group_quoted, :module)
    )

    accessor_name = Symbol(format_property_name(group_name))
    accessor_name_encoder = Symbol(string(accessor_name, "!"))
    accessor_group_count = Symbol(string(accessor_name, "_group_count!"))

    parent_accessor_methods = if precedence_checks
        decoder_empty = precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_group_empty_key(group_path),
        )
        decoder_nonempty = precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_group_nonempty_key(group_path),
        )
        encoder_empty = precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_group_empty_key(group_path),
        )
        encoder_nonempty = precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_group_nonempty_key(group_path),
        )
        if since_version > 0
            quote
                @inline function $accessor_name(m::Decoder)
                    if sbe_acting_version(m) <
                       $(version_expr(ir, since_version))
                        return $group_module_name.Decoder(
                            m.buffer,
                            0,
                            sbe_position_ptr(m),
                            $(version_expr(ir, 0)),
                            sbe_acting_version(m),
                            $count_zero_expr,
                            $count_zero_expr,
                            m.codec_state,
                        )
                    end
                    group = $group_module_name.Decoder(
                        m.buffer,
                        sbe_position_ptr(m),
                        sbe_acting_version(m),
                        m.codec_state,
                    )
                    if group.count == 0
                        $decoder_empty
                    else
                        $decoder_nonempty
                    end
                    return group
                end

                @inline function $(Symbol(accessor_name, "!"))(
                    m::Decoder,
                    group::$group_module_name.Decoder,
                )
                    if sbe_acting_version(m) <
                       $(version_expr(ir, since_version))
                        return $group_module_name.reset_missing!(
                            group,
                            m.buffer,
                            sbe_position_ptr(m),
                            sbe_acting_version(m),
                            m.codec_state,
                        )
                    end
                    $group_module_name.reset!(
                        group,
                        m.buffer,
                        sbe_position_ptr(m),
                        sbe_acting_version(m),
                        m.codec_state,
                    )
                    if group.count == 0
                        $decoder_empty
                    else
                        $decoder_nonempty
                    end
                    return group
                end

                @inline function $accessor_name_encoder(
                    m::$parent_encoder_name,
                    count,
                )
                    if count == 0
                        $encoder_empty
                    else
                        $encoder_nonempty
                    end
                    return $group_module_name.Encoder(
                        m.buffer,
                        count,
                        sbe_position_ptr(m),
                        m.codec_state,
                    )
                end
            end
        else
            quote
                @inline function $accessor_name(m::Decoder)
                    group = $group_module_name.Decoder(
                        m.buffer,
                        sbe_position_ptr(m),
                        sbe_acting_version(m),
                        m.codec_state,
                    )
                    if group.count == 0
                        $decoder_empty
                    else
                        $decoder_nonempty
                    end
                    return group
                end

                @inline function $(Symbol(accessor_name, "!"))(
                    m::Decoder,
                    group::$group_module_name.Decoder,
                )
                    $group_module_name.reset!(
                        group,
                        m.buffer,
                        sbe_position_ptr(m),
                        sbe_acting_version(m),
                        m.codec_state,
                    )
                    if group.count == 0
                        $decoder_empty
                    else
                        $decoder_nonempty
                    end
                    return group
                end

                @inline function $accessor_name_encoder(
                    m::$parent_encoder_name,
                    count,
                )
                    if count == 0
                        $encoder_empty
                    else
                        $encoder_nonempty
                    end
                    return $group_module_name.Encoder(
                        m.buffer,
                        count,
                        sbe_position_ptr(m),
                        m.codec_state,
                    )
                end
            end
        end
    elseif since_version > 0
        quote
            @inline function $accessor_name(m::$parent_abstract_type)
                if sbe_acting_version(m) < $(version_expr(ir, since_version))
                    return $group_module_name.Decoder(m.buffer, 0, sbe_position_ptr(m), $(version_expr(ir, 0)),
                        sbe_acting_version(m), $count_zero_expr, $count_zero_expr)
                end
                return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $(Symbol(accessor_name, "!"))(m::$parent_abstract_type, g::$group_module_name.Decoder)
                if sbe_acting_version(m) < $(version_expr(ir, since_version))
                    return $group_module_name.reset_missing!(g, m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
                end
                return $group_module_name.reset!(g, m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $accessor_name_encoder(m::$parent_abstract_type, count)
                return $group_module_name.Encoder(m.buffer, count, sbe_position_ptr(m))
            end
        end
    else
        quote
            @inline function $accessor_name(m::$parent_abstract_type)
                return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $(Symbol(accessor_name, "!"))(m::$parent_abstract_type, g::$group_module_name.Decoder)
                return $group_module_name.reset!(g, m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $accessor_name_encoder(m::$parent_abstract_type, count)
                return $group_module_name.Encoder(m.buffer, count, sbe_position_ptr(m))
            end
        end
    end

    push!(parent_accessors, quote
        $parent_accessor_methods
        $accessor_group_count(m::$parent_encoder_name, count) =
            $accessor_name_encoder(m, count)
        $(Symbol(accessor_name, :_id))(::$parent_abstract_type) =
            $(template_id_expr(ir, group_id))
        $(Symbol(accessor_name, :_since_version))(::$parent_abstract_type) =
            $(version_expr(ir, since_version))
        $(Symbol(accessor_name, :_in_acting_version))(m::$parent_abstract_type) =
            sbe_acting_version(m) >= $(version_expr(ir, since_version))
        $(generated_binding_doc_expr(group_accessor_doc(group_token), accessor_name))
        $(generated_binding_doc_expr(
            group_accessor_doc(group_token),
            Symbol(accessor_name, "!")
        ))
        $(generated_binding_doc_expr(
            "Create the `$(group_token.name)` group encoder with `count` entries.",
            accessor_group_count
        ))
        export $accessor_name, $(Symbol(accessor_name, "!")),
            $accessor_group_count, $group_module_name
    end)

    return [group_body], parent_accessors, accessor_name, group_module_name
end

function generate_message_expr(
    message_tokens::Vector{IR.Token},
    ir::IR.Ir;
    precedence_checks::Bool=false,
)
    msg_token = message_tokens[1]
    message_name = Symbol(format_struct_name(msg_token.name))
    abstract_type_name = Symbol(string("Abstract", message_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    header_module = Symbol(format_struct_name(ir.header_structure.tokens[1].name))
    version_type_symbol = header_field_type(ir, "version")
    header_mismatch_prefix = "SBE header mismatch: expected template/schema $(msg_token.id)/$(ir.id), got "
    encoder_model = precedence_checks ? build_field_precedence_model(
        message_tokens,
        string(message_name, ".Encoder");
        latest_version_only=true,
    ) : nothing
    decoder_model = precedence_checks ? build_field_precedence_model(
        message_tokens,
        string(message_name, ".Decoder");
        latest_version_only=false,
    ) : nothing

    precedence_helper_exprs = Expr[]
    encoder_state_names_symbol = nothing
    encoder_state_transitions_symbol = nothing
    if precedence_checks
        encoder_helpers, encoder_state_names_symbol, encoder_state_transitions_symbol =
            generate_precedence_helpers(encoder_model, :encoder)
        decoder_helpers, _, _ =
            generate_precedence_helpers(decoder_model, :decoder)
        append!(precedence_helper_exprs, encoder_helpers)
        append!(precedence_helper_exprs, decoder_helpers)
    end
    precedence_helper_names = precedence_checks ? vcat(
        precedence_helper_symbols(encoder_model, :encoder),
        precedence_helper_symbols(decoder_model, :decoder),
    ) : Symbol[]

    body = IR.get_message_body(message_tokens)
    fields, idx = split_components(collect(body), IR.Signal.BEGIN_FIELD, 1)
    groups, idx = split_components(collect(body), IR.Signal.BEGIN_GROUP, idx)
    var_data, _ = split_components(collect(body), IR.Signal.BEGIN_VAR_DATA, idx)

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    field_exprs = Expr[]
    field_doc_exprs = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()
    group_exprs = Expr[]
    group_accessors = Expr[]
    skip_calls = Expr[]
    var_data_exprs = Expr[]

    for field_tokens in fields
        inner = field_tokens[2]
        field_path = field_tokens[1].name
        decoder_access = precedence_checks ? precedence_access_expr(
            decoder_model,
            :decoder,
            precedence_field_key(field_path),
        ) : nothing
        encoder_access = precedence_checks ? precedence_access_expr(
            encoder_model,
            :encoder,
            precedence_field_key(field_path),
        ) : nothing
        documentation = field_accessor_doc(field_tokens)
        push!(
            field_doc_exprs,
            generated_binding_doc_expr(
                documentation,
                composite_member_field_name(field_tokens[1].name)
            )
        )
        if field_has_setter(field_tokens)
            push!(
                field_doc_exprs,
                generated_binding_doc_expr(
                    documentation,
                    Symbol(composite_member_field_name(field_tokens[1].name), :!)
                )
            )
        end
        if inner.signal == IR.Signal.ENCODING
            append!(field_exprs, generate_encoded_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_ENUM
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_enum_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_SET
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_set_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        elseif inner.signal == IR.Signal.BEGIN_COMPOSITE
            push!(composite_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_composite_field_expr(
                field_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                decoder_access=decoder_access,
                encoder_access=encoder_access,
            ))
        end
    end

    for group_tokens in groups
        group_defs, parent_accessors, accessor_name, group_module_name = generate_group_expr(
            group_tokens,
            abstract_type_name,
            encoder_name,
            ir,
            2;
            precedence_checks=precedence_checks,
            decoder_model=decoder_model,
            encoder_model=encoder_model,
            parent_path="",
            root_message_name=message_name,
            precedence_helper_names=precedence_helper_names,
        )
        append!(group_exprs, group_defs)
        append!(group_accessors, parent_accessors)
        push!(skip_calls, quote
            for group in $accessor_name(m)
                $group_module_name.sbe_skip!(group)
            end
        end)
    end

    for (index, var_data_tokens) in enumerate(var_data)
        name_symbol = Symbol(format_property_name(var_data_tokens[1].name))
        skip_name = Symbol(string("skip_", name_symbol, "!"))
        push!(skip_calls, :($skip_name(m)))
        append!(
            var_data_exprs,
            generate_var_data_expr(
                var_data_tokens,
                abstract_type_name,
                decoder_name,
                encoder_name,
                ir;
                external_tail=index == length(var_data),
                decoder_model=decoder_model,
                encoder_model=encoder_model,
                qualified_path=var_data_tokens[1].name,
            )
        )
    end

    message_state_fields = precedence_checks ?
        [:(codec_state::CodecStatePointer)] : Expr[]
    decoder_state_initializers = precedence_checks ?
        [:(obj.codec_state = CodecStatePointer())] : Expr[]
    encoder_state_initializers = precedence_checks ?
        [:(obj.codec_state = CodecStatePointer())] : Expr[]
    decoder_wrap_state_updates = precedence_checks ?
        [precedence_decoder_wrap_expr(decoder_model, :m, :acting_version)] : Expr[]
    encoder_wrap_state_updates = precedence_checks ?
        [:(m.codec_state.value = UInt16($(encoder_model.latest_wrapped_state)))] :
        Expr[]
    precedence_imports = precedence_checks ? quote
        using SBE: CodecStatePointer, throw_precedence_error
        import SBE: check_encoding_is_complete
    end : Expr(:block)

    rewind_exprs = if precedence_checks
        decoder_rewind_state = precedence_decoder_wrap_expr(
            decoder_model,
            :m,
            :(sbe_acting_version(m)),
        )
        Expr[
            quote
                @inline function sbe_rewind!(m::$decoder_name)
                    sbe_position!(m, m.offset + sbe_acting_block_length(m))
                    $decoder_rewind_state
                    return m
                end
            end,
            quote
                @inline function sbe_rewind!(m::$encoder_name)
                    sbe_position!(m, m.offset + sbe_acting_block_length(m))
                    m.codec_state.value =
                        UInt16($(encoder_model.latest_wrapped_state))
                    return m
                end
            end,
        ]
    else
        Expr[
            :(sbe_rewind!(m::$abstract_type_name) =
                sbe_position!(m, m.offset + sbe_acting_block_length(m))),
        ]
    end

    completion_exprs = Expr[]
    if precedence_checks
        terminal_condition = precedence_state_condition(
            encoder_model.terminal_states,
        )
        push!(
            completion_exprs,
            quote
                """
                    check_encoding_is_complete(encoder)

                Validate that every required repeating group and variable-data
                transition has been completed. This check is explicit; querying
                the encoded length does not imply completeness.
                """
                @inline function check_encoding_is_complete(m::$encoder_name)
                    state = m.codec_state.value
                    $terminal_condition && return nothing
                    throw_precedence_error(
                        "complete encoding",
                        "check_encoding_is_complete",
                        state,
                        $encoder_state_names_symbol,
                        $encoder_state_transitions_symbol,
                        $(encoder_model.machine_name),
                    )
                end

                export check_encoding_is_complete
            end,
        )
    end

    message_quoted = quote
        module $message_name
        export $abstract_type_name, $decoder_name, $encoder_name
        using SBE: AbstractSbeMessage, PositionPointer, SbeFrame
        using SBE: sbe_external_tail, to_string
        import SBE: sbe_buffer, sbe_offset, sbe_position_ptr, sbe_position, sbe_position!
        import SBE: sbe_frame_offset
        import SBE: sbe_block_length, sbe_template_id, sbe_schema_id, sbe_schema_version
        import SBE: sbe_acting_block_length, sbe_acting_version, sbe_rewind!
        import SBE: sbe_encoded_length, sbe_decoded_length, sbe_semantic_type, sbe_description
        $precedence_imports
        abstract type $abstract_type_name{T} <: AbstractSbeMessage{T} end

        using ..$header_module
        using StringViews: StringView
        $([:($using_stmt) for using_stmt in [:(using ..$enum_name) for enum_name in enum_imports]]...)
        $([:($using_stmt) for using_stmt in [:(using ..$composite_name) for composite_name in composite_imports]]...)

        $endian_imports

        @inline function rstrip_nul(a::Union{AbstractString,AbstractArray})
            pos = findfirst(iszero, a)
            len = pos !== nothing ? pos - 1 : Base.length(a)
            return view(a, 1:len)
        end

        $(precedence_helper_exprs...)

        mutable struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
            buffer::T
            frame_offset::Int64
            offset::Int64
            position_ptr::PositionPointer
            acting_block_length::UInt16
            acting_version::$version_type_symbol
            $(message_state_fields...)
            function $decoder_name{T}() where {T<:AbstractArray{UInt8}}
                obj = new{T}()
                obj.frame_offset = Int64(0)
                obj.offset = Int64(0)
                obj.position_ptr = PositionPointer()
                obj.acting_block_length = UInt16(0)
                obj.acting_version = $version_type_symbol(0)
                $(decoder_state_initializers...)
                return obj
            end
        end

        mutable struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
            buffer::T
            frame_offset::Int64
            offset::Int64
            position_ptr::PositionPointer
            $(message_state_fields...)
            function $encoder_name{T}() where {T<:AbstractArray{UInt8}}
                obj = new{T}()
                obj.frame_offset = Int64(0)
                obj.offset = Int64(0)
                obj.position_ptr = PositionPointer()
                $(encoder_state_initializers...)
                return obj
            end
        end

        $(generated_binding_doc_expr(
            "Abstract flyweight type for the generated `$(msg_token.name)` message codec.",
            abstract_type_name
        ))
        $(generated_binding_doc_expr(
            """
                Decoder(buffer, offset=0; header=MessageHeader.Decoder(buffer, offset))
                Decoder(typeof(buffer))

            Zero-copy decoder for `$(msg_token.name)`. The buffer constructor validates and consumes the SBE message header. The type constructor creates an unwrapped reusable flyweight for use with `wrap!`.
            """,
            decoder_name
        ))
        $(generated_binding_doc_expr(
            """
                Encoder(buffer, offset=0; header=MessageHeader.Encoder(buffer, offset))
                Encoder(typeof(buffer))

            Zero-copy encoder for `$(msg_token.name)`. The buffer constructor writes the SBE message header. The type constructor creates an unwrapped reusable flyweight for use with `wrap!` or `wrap_and_apply_header!`.
            """,
            encoder_name
        ))

        @inline function $decoder_name(::Type{T}) where {T<:AbstractArray{UInt8}}
            return $decoder_name{T}()
        end

        @inline function $encoder_name(::Type{T}) where {T<:AbstractArray{UInt8}}
            return $encoder_name{T}()
        end

        @inline function wrap!(m::$decoder_name{T}, buffer::T, offset::Integer,
            acting_block_length::Integer, acting_version::Integer) where {T}
            m.buffer = buffer
            m.frame_offset = Int64(offset)
            m.offset = Int64(offset)
            m.acting_block_length = UInt16(acting_block_length)
            m.acting_version = $version_type_symbol(acting_version)
            m.position_ptr[] = m.offset + m.acting_block_length
            $(decoder_wrap_state_updates...)
            return m
        end

        @inline function wrap!(m::$decoder_name, buffer::AbstractArray, offset::Integer=0;
            header=$header_module.Decoder(buffer, offset))
            actual_template_id = $header_module.templateId(header)
            actual_schema_id = $header_module.schemaId(header)
            if actual_template_id != $(template_id_expr(ir, msg_token.id)) ||
               actual_schema_id != $(schema_id_expr(ir, ir.id))
                throw(ArgumentError(
                    $header_mismatch_prefix *
                    string(actual_template_id) * "/" * string(actual_schema_id)
                ))
            end
            result = wrap!(m, buffer, offset + sbe_encoded_length(header),
                $header_module.blockLength(header), $header_module.version(header))
            result.frame_offset = Int64(offset)
            return result
        end

        @inline function wrap!(m::$encoder_name{T}, buffer::T, offset::Integer) where {T}
            m.buffer = buffer
            m.frame_offset = Int64(offset)
            m.offset = Int64(offset)
            m.position_ptr[] = m.offset + $(block_length_expr(ir, msg_token.encoded_length))
            $(encoder_wrap_state_updates...)
            return m
        end

        @inline function wrap_and_apply_header!(m::$encoder_name, buffer::AbstractArray, offset::Integer=0;
            header=$header_module.Encoder(buffer, offset))
            $header_module.blockLength!(header, $(block_length_expr(ir, msg_token.encoded_length)))
            $header_module.templateId!(header, $(template_id_expr(ir, msg_token.id)))
            $header_module.schemaId!(header, $(schema_id_expr(ir, ir.id)))
            $header_module.version!(header, $(version_expr(ir, ir.version)))
            result = wrap!(m, buffer, offset + sbe_encoded_length(header))
            result.frame_offset = Int64(offset)
            return result
        end

        @inline function $decoder_name(buffer::T, offset::Integer=0;
            header=$header_module.Decoder(buffer, offset)) where {T<:AbstractArray{UInt8}}
            return wrap!($decoder_name(T), buffer, offset; header=header)
        end

        @inline function $encoder_name(buffer::T, offset::Integer=0;
            header=$header_module.Encoder(buffer, offset)) where {T<:AbstractArray{UInt8}}
            return wrap_and_apply_header!($encoder_name(T), buffer, offset; header=header)
        end

        $(generated_binding_doc_expr(
            "Wrap a reusable decoder around a buffer. The header-aware method validates template and schema IDs; the five-argument method accepts an already-decoded block length and acting version.",
            :wrap!
        ))
        $(generated_binding_doc_expr(
            "Write the message header and wrap a reusable encoder around the message body.",
            :wrap_and_apply_header!
        ))

        sbe_buffer(m::$abstract_type_name) = m.buffer
        sbe_offset(m::$abstract_type_name) = m.offset
        sbe_position_ptr(m::$abstract_type_name) = m.position_ptr
        sbe_position(m::$abstract_type_name) = m.position_ptr[]
        sbe_position!(m::$abstract_type_name, position) = m.position_ptr[] = position
        sbe_block_length(::$abstract_type_name) = $(block_length_expr(ir, msg_token.encoded_length))
        sbe_block_length(::Type{<:$abstract_type_name}) = $(block_length_expr(ir, msg_token.encoded_length))
        sbe_template_id(::$abstract_type_name) = $(template_id_expr(ir, msg_token.id))
        sbe_template_id(::Type{<:$abstract_type_name})  = $(template_id_expr(ir, msg_token.id))
        sbe_schema_id(::$abstract_type_name) = $(schema_id_expr(ir, ir.id))
        sbe_schema_id(::Type{<:$abstract_type_name})  = $(schema_id_expr(ir, ir.id))
        sbe_schema_version(::$abstract_type_name) = $(version_expr(ir, ir.version))
        sbe_schema_version(::Type{<:$abstract_type_name})  = $(version_expr(ir, ir.version))
        sbe_semantic_type(::$abstract_type_name) = $(msg_token.encoding.semantic_type === nothing ? "" : msg_token.encoding.semantic_type)
        sbe_description(::$abstract_type_name) = $(msg_token.description)
        sbe_description(::Type{<:$abstract_type_name}) = $(msg_token.description)
        sbe_acting_block_length(m::$decoder_name) = m.acting_block_length
        sbe_acting_block_length(::$encoder_name) = $(block_length_expr(ir, msg_token.encoded_length))
        sbe_acting_version(m::$decoder_name) = m.acting_version
        sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))
        $(rewind_exprs...)
        sbe_encoded_length(m::$abstract_type_name) = sbe_position(m) - m.offset

        Base.sizeof(m::$abstract_type_name) = sbe_encoded_length(m)

        @inline function Base.show(io::IO, m::$abstract_type_name)
            print(io, string(typeof(m)), "(offset=", sbe_offset(m),
                ", position=", sbe_position(m),
                ", acting_block_length=", sbe_acting_block_length(m),
                ", acting_version=", sbe_acting_version(m),
                ", template_id=", sbe_template_id(m),
                ", schema_id=", sbe_schema_id(m),
                ", schema_version=", sbe_schema_version(m), ")")
        end

        @inline function Base.show(io::IO, ::MIME"application/json", m::$abstract_type_name)
            print(io, "{\"type\":\"", $(string(message_name)), "\",",
                "\"offset\":", sbe_offset(m), ",",
                "\"position\":", sbe_position(m), ",",
                "\"acting_block_length\":", sbe_acting_block_length(m), ",",
                "\"acting_version\":", sbe_acting_version(m), ",",
                "\"template_id\":", sbe_template_id(m), ",",
                "\"schema_id\":", sbe_schema_id(m), ",",
                "\"schema_version\":", sbe_schema_version(m), "}")
        end

        $(field_exprs...)
        $(field_doc_exprs...)
        $(group_exprs...)
        $(group_accessors...)
        $(var_data_exprs...)
        $(completion_exprs...)

        @inline function sbe_decoded_length(m::$abstract_type_name)
            skipper = $decoder_name(typeof(sbe_buffer(m)))
            skipper.position_ptr = PositionPointer()
            wrap!(skipper, sbe_buffer(m), sbe_offset(m),
                sbe_acting_block_length(m), sbe_acting_version(m))
            sbe_skip!(skipper)
            return sbe_encoded_length(skipper)
        end

        @inline function sbe_skip!(m::$decoder_name)
            sbe_rewind!(m)
            $(isempty(skip_calls) ? :(return) : Expr(:block, skip_calls...))
            return
        end
    end
    end

    return generated_doc_expr(
        message_codec_doc(msg_token, ir),
        extract_expr_from_quote(message_quoted, :module)
    )
end

function set_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    set_name = begin_token.referenced_name === nothing ? begin_token.name : begin_token.referenced_name
    encoding_type = begin_token.encoding.primitive_type
    choices = IrSetChoice[]
    for token in tokens
        if token.signal == IR.Signal.CHOICE
            bit_position = parse(Int, token.encoding.const_value.value)
            push!(choices, IrSetChoice(token.name, bit_position, token.description, token.version, token.deprecated))
        end
    end
    return IrSetDef(
        set_name,
        begin_token.description,
        encoding_type,
        choices,
        begin_token.version,
        begin_token.offset
    )
end

function generate_enum_expr(enum_def::IrEnumDef)
    enum_name = Symbol(format_struct_name(enum_def.name))
    encoding_julia_type = IR.primitive_type_julia(enum_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    encoding_type = julia_type_from_symbol(encoding_type_symbol)
    enum_values = Expr[]

    for value in enum_def.values
        value_name = Symbol(sanitize_identifier(value.name))
        push!(enum_values, :($value_name = $(Meta.parse(value.literal))))
    end

    null_value = if enum_def.null_value !== nothing
        Meta.parse(primitive_value_literal(enum_def.null_value, enum_def.encoding_type))
    elseif enum_def.encoding_type == IR.PrimitiveType.CHAR
        UInt8(0x0)
    else
        encoding_type <: Unsigned ? typemax(encoding_type) : typemin(encoding_type)
    end

    push!(enum_values, :(NULL_VALUE = $encoding_type_symbol($null_value)))

    enum_expr = Expr(
        :macrocall,
        Symbol("@enumx"),
        LineNumberNode(0, Symbol("ir_codegen")),
        Expr(:(=), :T, :SbeEnum),
        Expr(:(::), enum_name, encoding_type_symbol),
        Expr(:block, enum_values...)
    )

    documented_enum = generated_doc_expr(
        codec_type_doc(
            enum_def.name,
            enum_def.description,
            "enum";
            extra="Encoded as `$(encoding_type_symbol)`."
        ),
        enum_expr
    )
    value_docs = Expr[
        generated_binding_doc_expr(
            "Concrete Julia enum type for the `$(enum_def.name)` SBE enum. " *
            "Encoded as `$(encoding_type_symbol)`.",
            Expr(:., enum_name, QuoteNode(:SbeEnum))
        )
    ]
    for value in enum_def.values
        value_name = Symbol(sanitize_identifier(value.name))
        description = description_or_default(
            value.description,
            "`$(value.name)` value of the `$(enum_def.name)` SBE enum."
        )
        details = "Encoded value: `$(value.literal)`; sinceVersion=$(value.since_version)"
        value.deprecated > 0 && (details *= "; deprecated=$(value.deprecated)")
        push!(
            value_docs,
            generated_binding_doc_expr(
                "$description\n\n$details.",
                Expr(:., enum_name, QuoteNode(value_name))
            )
        )
    end
    push!(
        value_docs,
        generated_binding_doc_expr(
            "Null or not-present value for the `$(enum_def.name)` SBE enum.",
            Expr(:., enum_name, QuoteNode(:NULL_VALUE))
        )
    )
    return Expr(:block, documented_enum, value_docs...)
end

function header_field_type(ir::IR.Ir, field_name::String)
    header = ir.header_structure
    if field_name == "blockLength"
        return IR.primitive_type_julia(header.block_length_type)
    elseif field_name == "templateId"
        return IR.primitive_type_julia(header.template_id_type)
    elseif field_name == "schemaId"
        return IR.primitive_type_julia(header.schema_id_type)
    elseif field_name == "version"
        return IR.primitive_type_julia(header.schema_version_type)
    end
    return UInt16
end

function ir_type_expr(ir::IR.Ir, field_name::String, value)
    field_type = header_field_type(ir, field_name)
    return Expr(:call, Symbol(field_type), value)
end

template_id_expr(ir::IR.Ir, value) = ir_type_expr(ir, "templateId", value)
schema_id_expr(ir::IR.Ir, value) = ir_type_expr(ir, "schemaId", value)
version_expr(ir::IR.Ir, value) = ir_type_expr(ir, "version", value)
block_length_expr(ir::IR.Ir, value) = ir_type_expr(ir, "blockLength", value)

function generate_encoded_types_expr(byte_order::Symbol)
    if byte_order == :bigEndian
        return quote
            import SBE: encode_value_be, decode_value_be, encode_array_be, decode_array_be
            const encode_value = encode_value_be
            const decode_value = decode_value_be
            const encode_array = encode_array_be
            const decode_array = decode_array_be
        end
    end
    return quote
        import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
        const encode_value = encode_value_le
        const decode_value = decode_value_le
        const encode_array = encode_array_le
        const decode_array = decode_array_le
    end
end

function generate_set_expr(set_def::IrSetDef, ir::IR.Ir)
    set_name = Symbol(format_struct_name(set_def.name))
    abstract_type_name = Symbol(string("Abstract", set_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    version_type_symbol = header_field_type(ir, "version")

    encoding_julia_type = IR.primitive_type_julia(set_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    encoding_type = julia_type_from_symbol(encoding_type_symbol)
    encoding_size = sizeof(encoding_type)

    choice_exprs = Expr[]
    choice_doc_exprs = Expr[]
    for choice in set_def.choices
        choice_func_name = Symbol(format_choice_name(choice.name))
        choice_func_name_set = Symbol(string(choice_func_name, "!"))
        bit_position = choice.bit_position

        push!(choice_exprs, quote
            @inline function $choice_func_name(set::$abstract_type_name)
                return decode_value($encoding_type_symbol, set.buffer, set.offset) & ($encoding_type_symbol(0x1) << $bit_position) != 0
            end
        end)

        push!(choice_exprs, quote
            @inline function $choice_func_name_set(set::$encoder_name, value::Bool)
                bits = decode_value($encoding_type_symbol, set.buffer, set.offset)
                bits = value ? (bits | ($encoding_type_symbol(0x1) << $bit_position)) : (bits & ~($encoding_type_symbol(0x1) << $bit_position))
                encode_value($encoding_type_symbol, set.buffer, set.offset, bits)
                return set
            end
        end)

        push!(choice_exprs, :(export $choice_func_name, $choice_func_name_set))
        choice_description = description_or_default(
            choice.description,
            "Read or update the `$(choice.name)` bit in the `$(set_def.name)` SBE set."
        )
        choice_details = "Bit $(choice.bit_position); sinceVersion=$(choice.since_version)"
        choice.deprecated > 0 && (choice_details *= "; deprecated=$(choice.deprecated)")
        documentation = """
            $choice_func_name(set) -> Bool
            $(choice_func_name)!(set, value::Bool) -> set

        $choice_description

        $choice_details.
        """
        push!(
            choice_doc_exprs,
            generated_binding_doc_expr(documentation, choice_func_name)
        )
        push!(
            choice_doc_exprs,
            generated_binding_doc_expr(documentation, choice_func_name_set)
        )
    end

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    set_quoted = quote
        module $set_name
            using SBE: AbstractSbeEncodedType
            import SBE: id, since_version, encoding_offset, encoding_length, sbe_acting_version

            $endian_imports

            abstract type $abstract_type_name <: AbstractSbeEncodedType end

            struct $decoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
                acting_version::$version_type_symbol
            end

            struct $encoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
            end

            $(generated_binding_doc_expr(
                "Abstract flyweight type for the generated `$(set_def.name)` SBE set codec.",
                abstract_type_name
            ))
            $(generated_binding_doc_expr(
                "Zero-copy decoder for the `$(set_def.name)` SBE set.",
                decoder_name
            ))
            $(generated_binding_doc_expr(
                "Zero-copy encoder for the `$(set_def.name)` SBE set.",
                encoder_name
            ))

            @inline function $decoder_name(buffer::AbstractVector{UInt8})
                $decoder_name(buffer, Int64(0), $(version_expr(ir, ir.version)))
            end

            @inline function $decoder_name(buffer::AbstractVector{UInt8}, offset::Integer)
                $decoder_name(buffer, Int64(offset), $(version_expr(ir, ir.version)))
            end

            @inline function $encoder_name(buffer::AbstractVector{UInt8})
                $encoder_name(buffer, Int64(0))
            end

            id(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, 0xffff))
            id(::$abstract_type_name) = $(template_id_expr(ir, 0xffff))
            since_version(::Type{<:$abstract_type_name}) = $(version_expr(ir, set_def.since_version))
            since_version(::$abstract_type_name) = $(version_expr(ir, set_def.since_version))

            encoding_offset(::Type{<:$abstract_type_name}) = $(set_def.offset)
            encoding_offset(::$abstract_type_name) = $(set_def.offset)
            encoding_length(::Type{<:$abstract_type_name}) = $encoding_size
            encoding_length(::$abstract_type_name) = $encoding_size

            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))

            Base.eltype(::Type{<:$abstract_type_name}) = $encoding_julia_type
            Base.eltype(::$abstract_type_name) = $encoding_julia_type

            @inline function clear!(set::$encoder_name)
                encode_value($encoding_julia_type, set.buffer, set.offset, zero($encoding_julia_type))
                return set
            end

            @inline function is_empty(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset) == zero($encoding_julia_type)
            end

            @inline function raw_value(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset)
            end

            $(choice_exprs...)
            $(choice_doc_exprs...)

            $(generated_binding_doc_expr(
                "Clear all choices in this set and return the encoder.",
                :clear!
            ))
            $(generated_binding_doc_expr(
                "Return `true` when no choices are set.",
                :is_empty
            ))
            $(generated_binding_doc_expr(
                "Return the raw encoded integer value of this set.",
                :raw_value
            ))

            export $abstract_type_name, $decoder_name, $encoder_name
            export clear!, is_empty, raw_value
        end
    end

    return generated_doc_expr(
        codec_type_doc(
            set_def.name,
            set_def.description,
            "set";
            extra="Encoded as `$(encoding_type_symbol)`."
        ),
        extract_expr_from_quote(set_quoted, :module)
    )
end

function find_first_token(name::String, tokens::Vector{IR.Token}, start_index::Int=1)
    for i in start_index:length(tokens)
        if tokens[i].name == name
            return tokens[i]
        end
    end
    error("token not found: $(name)")
end

function module_name_from_package(package_name::String)
    normalized = replace(package_name, r"[^A-Za-z0-9_]" => "_")
    parts = split(normalized, "_")
    parts = filter(!isempty, parts)
    raw = join([uppercasefirst(part) for part in parts])
    raw = isempty(raw) ? "Schema" : raw
    return Symbol(sanitize_identifier(raw))
end

function generate_ir_module_expr(
    ir::IR.Ir;
    module_name::Union{Nothing, Symbol, String}=nothing,
    precedence_checks::Bool=false,
)
    module_name = module_name === nothing ? module_name_from_package(ir.package_name) :
        Symbol(sanitize_identifier(String(module_name)))
    alias_raw = replace(ir.package_name, r"[^A-Za-z0-9_]" => "_")
    alias_name = Symbol(sanitize_identifier(uppercasefirst(alias_raw)))
    type_exprs = Expr[]
    message_exprs = Expr[]

    type_deps = Dict{String, Set{String}}()
    for (name, tokens) in ir.types_by_name
        deps = Set{String}()
        for (idx, token) in enumerate(tokens)
            if idx == 1
                continue
            end
            if token.signal == IR.Signal.BEGIN_COMPOSITE ||
               token.signal == IR.Signal.BEGIN_ENUM ||
               token.signal == IR.Signal.BEGIN_SET
                dep_name = token.referenced_name === nothing ? token.name : token.referenced_name
                dep_name == name && continue
                push!(deps, dep_name)
            end
        end
        type_deps[name] = deps
    end

    ordered_types = String[]
    visited = Dict{String, Symbol}()
    function visit_type(name::String)
        state = get(visited, name, :none)
        state == :visiting && return
        state == :done && return
        visited[name] = :visiting
        for dep in get(type_deps, name, Set{String}())
            haskey(type_deps, dep) || continue
            visit_type(dep)
        end
        visited[name] = :done
        push!(ordered_types, name)
    end

    for name in sort!(collect(keys(type_deps)))
        visit_type(name)
    end

    for name in ordered_types
        tokens = ir.types_by_name[name]
        isempty(tokens) && continue
        if tokens[1].signal == IR.Signal.BEGIN_ENUM
            enum_def = enum_def_from_tokens(tokens)
            push!(type_exprs, generate_enum_expr(enum_def))
        elseif tokens[1].signal == IR.Signal.BEGIN_SET
            set_def = set_def_from_tokens(tokens)
            push!(type_exprs, generate_set_expr(set_def, ir))
        elseif tokens[1].signal == IR.Signal.BEGIN_COMPOSITE
            composite_def = composite_def_from_tokens(tokens)
            push!(type_exprs, generate_composite_expr(composite_def, ir))
        end
    end

    for tokens in values(ir.messages_by_id)
        push!(
            message_exprs,
            generate_message_expr(
                tokens,
                ir;
                precedence_checks=precedence_checks,
            ),
        )
    end

    module_quoted = quote
        module $module_name
            using EnumX
            using StringViews

            @inline function rstrip_nul(a::Union{AbstractString,AbstractArray})
                pos = findfirst(iszero, a)
                len = pos !== nothing ? pos - 1 : Base.length(a)
                return view(a, 1:len)
            end

            $(type_exprs...)
            $(message_exprs...)
        end
    end

    module_expr = extract_expr_from_quote(module_quoted, :module)
    strip_interpolations!(module_expr)
    normalize_dotted_exprs!(module_expr)
    documented_module = generated_doc_expr(
        schema_module_doc(ir, module_name),
        module_expr
    )

    if alias_name != module_name
        return Expr(
            :block,
            documented_module,
            :(const $alias_name = $module_name),
            generated_binding_doc_expr(
                "Compatibility alias for the generated `$module_name` schema module.",
                alias_name
            )
        )
    end
    return documented_module
end
