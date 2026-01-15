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
    encoding_type::IR.PrimitiveType.T
    choices::Vector{IrSetChoice}
    since_version::Int
    offset::Int
end

const JULIA_KEYWORDS = Set([
    "abstract",
    "baremodule",
    "begin",
    "break",
    "catch",
    "const",
    "continue",
    "do",
    "else",
    "elseif",
    "end",
    "export",
    "false",
    "finally",
    "for",
    "function",
    "global",
    "if",
    "import",
    "let",
    "local",
    "macro",
    "module",
    "mutable",
    "new",
    "primitive",
    "quote",
    "return",
    "struct",
    "true",
    "try",
    "using",
    "where",
    "while",
    "_",
    "Enum",
    "Set",
])

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

function relative_using_expr(depth::Int, name::Symbol)
    dots = repeat(".", depth + 1)
    return Meta.parse("using " * dots * string(name))
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
    return IrEnumDef(enum_name, encoding_type, null_value, values)
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

            @inline $(Symbol(member_name, :!))(m::$encoder_name, val) = encode_value($julia_type, m.buffer, m.offset + $(token.offset), val)

            export $member_name, $(Symbol(member_name, :!))
        end)
        return exprs
    end

    is_char_array = primitive_type == IR.PrimitiveType.CHAR
    if is_char_array
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
                bytes = codeunits(value)
                dest = encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                len = min(Base.length(bytes), Base.length(dest))
                copyto!(dest, 1, bytes, 1, len)
                if len < Base.length(dest)
                    fill!(view(dest, len+1:Base.length(dest)), 0x00)
                end
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                dest = encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                len = min(Base.length(value), Base.length(dest))
                copyto!(dest, 1, value, 1, len)
                if len < Base.length(dest)
                    fill!(view(dest, len+1:Base.length(dest)), 0x00)
                end
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
        end
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
    var_data_exprs = Expr[]
    skip_calls = Expr[]
    group_exprs = Expr[]
    group_accessors = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()

    for member in composite_def.members
        tokens = member.tokens
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

            export $abstract_type_name, $decoder_name, $encoder_name
        end
    end

    return extract_expr_from_quote(composite_quoted, :module)
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

function generate_encoded_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
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
        return exprs
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

                @inline $(Symbol(field_name, :!))(m::$encoder_name, val) = encode_value($julia_type, m.buffer, m.offset + $(field_token.offset), val)

                export $field_name, $(Symbol(field_name, :!))
            end)
        else
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $(field_token.offset))
                end

                @inline $(Symbol(field_name, :!))(m::$encoder_name, val) = encode_value($julia_type, m.buffer, m.offset + $(field_token.offset), val)

                export $field_name, $(Symbol(field_name, :!))
            end)
        end
        return exprs
    end

    is_char_array = primitive_type == IR.PrimitiveType.CHAR
    if is_char_array
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
                    bytes = codeunits(value)
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = min(Base.length(bytes), Base.length(dest))
                    copyto!(dest, 1, bytes, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = min(Base.length(value), Base.length(dest))
                    copyto!(dest, 1, value, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
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
                    bytes = codeunits(value)
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = min(Base.length(bytes), Base.length(dest))
                    copyto!(dest, 1, bytes, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                end

                @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                    dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                    len = min(Base.length(value), Base.length(dest))
                    copyto!(dest, 1, value, 1, len)
                    if len < Base.length(dest)
                        fill!(view(dest, len+1:Base.length(dest)), 0x00)
                    end
                end

                export $field_name, $(Symbol(field_name, :!))
            end)
        end
        return exprs
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
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
    end

    return exprs
end

function generate_enum_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
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
        return exprs
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
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
        return exprs
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
        end

        export $field_name, $(Symbol(field_name, :!))
    end)

    return exprs
end

function generate_set_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
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

    return exprs
end

function generate_composite_field_expr(
    field_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
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

    return exprs
end

function generate_var_data_expr(
    var_data_tokens::Vector{IR.Token},
    abstract_type_name::Symbol,
    decoder_name::Symbol,
    encoder_name::Symbol,
    ir::IR.Ir
)
    field_token = var_data_tokens[1]
    accessor_name = Symbol(format_property_name(field_token.name))
    length_name = Symbol(string(accessor_name, "_length"))
    length_name_setter = Symbol(string(accessor_name, "_length!"))
    skip_name = Symbol(string("skip_", accessor_name, "!"))
    buffer_name = Symbol(string(accessor_name, "_buffer!"))
    accessor_setter = Symbol(string(accessor_name, "!"))
    since_version = field_token.version

    length_token = find_first_token("length", var_data_tokens, 1)
    var_data_token = find_first_token("varData", var_data_tokens, 1)

    length_type = IR.primitive_type_julia(length_token.encoding.primitive_type)
    length_type_symbol = Symbol(length_type)
    header_length = length_token.encoded_length
    max_literal = encoding_literal(length_token.encoding.max_value, length_token.encoding.primitive_type, IR.primitive_type_max)
    returns_string = var_data_token.encoding.primitive_type == IR.PrimitiveType.CHAR
    bytes_accessor = Symbol(string(accessor_name, "_bytes"))

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

    if since_version > 0
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
            @boundscheck n > $max_literal && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + $header_length + n)
            return encode_value($length_type, m.buffer, sbe_position(m), $length_type_symbol(n))
        end
    end)

    push!(exprs, quote
        @inline function $skip_name(m::$decoder_name)
            len = $length_name(m)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            return len
        end
    end)

    if returns_string
        push!(exprs, quote
            @inline function $bytes_accessor(m::$decoder_name)
                len = $length_name(m)
                pos = sbe_position(m) + $header_length
                sbe_position!(m, pos + len)
                return view(m.buffer, pos+1:pos+len)
            end
        end)
        push!(exprs, quote
            @inline function $accessor_name(m::$decoder_name)
                return StringView(rstrip_nul($bytes_accessor(m)))
            end
        end)
    else
        push!(exprs, quote
            @inline function $accessor_name(m::$decoder_name)
                len = $length_name(m)
                pos = sbe_position(m) + $header_length
                sbe_position!(m, pos + len)
                return view(m.buffer, pos+1:pos+len)
            end
        end)
    end

    push!(exprs, quote
        @inline function $buffer_name(m::$encoder_name, len)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            return view(m.buffer, pos+1:pos+len)
        end
    end)

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, reinterpret(UInt8, src))
        end
    end)

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::NTuple)
            len = sizeof(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, reinterpret(NTuple{len,UInt8}, src))
        end
    end)

    push!(exprs, quote
        @inline function $accessor_setter(m::$encoder_name, src::AbstractString)
            len = sizeof(src)
            $length_name_setter(m, len)
            pos = sbe_position(m) + $header_length
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, codeunits(src))
        end
    end)

    push!(exprs, quote
        @inline $accessor_setter(m::$encoder_name, src::Symbol) = $accessor_setter(m, to_string(src))
        @inline $accessor_setter(m::$encoder_name, src::Real) = $accessor_setter(m, Tuple(src))
        @inline $accessor_setter(m::$encoder_name, ::Nothing) = $buffer_name(m, 0)
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

    return exprs
end

function generate_group_expr(
    group_tokens::Vector{IR.Token},
    parent_abstract_type::Symbol,
    parent_encoder_name::Symbol,
    ir::IR.Ir,
    module_depth::Int
)
    group_token = group_tokens[1]
    group_name = group_token.name
    group_module_name = Symbol(format_struct_name(group_name))
    abstract_type_name = Symbol(string("Abstract", group_module_name))
    decoder_name = :Decoder
    encoder_name = :Encoder

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
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}([dimension_module_name])
    group_exprs = Expr[]
    parent_accessors = Expr[]
    skip_calls = Expr[]

    for field_tokens in fields
        inner = field_tokens[2]
        if inner.signal == IR.Signal.ENCODING
            append!(field_exprs, generate_encoded_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_ENUM
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_enum_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_SET
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_set_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_COMPOSITE
            push!(composite_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_composite_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        end
    end

    for nested_group_tokens in groups
        nested_group_exprs, nested_accessors, nested_accessor_name, nested_group_module_name = generate_group_expr(
            nested_group_tokens,
            abstract_type_name,
            encoder_name,
            ir,
            module_depth + 1
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
        append!(var_data_exprs, generate_var_data_expr(var_data_tokens, abstract_type_name, decoder_name, encoder_name, ir))
    end

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    dimension_decoder = Expr(:., dimension_module_name, :Decoder)
    dimension_encoder = Expr(:., dimension_module_name, :Encoder)
    block_length_get = Expr(:., dimension_module_name, :blockLength)
    block_length_set = Expr(:., dimension_module_name, :blockLength!)
    num_in_group_get = Expr(:., dimension_module_name, :numInGroup)
    num_in_group_set = Expr(:., dimension_module_name, :numInGroup!)

    group_quoted = quote
        module $group_module_name
        using SBE: AbstractSbeGroup, PositionPointer, to_string
        import SBE: sbe_header_size, sbe_block_length, sbe_acting_block_length, sbe_acting_version
        import SBE: sbe_position, sbe_position!, sbe_position_ptr, next!
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

        @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = $dimension_decoder(buffer, position_ptr[])
            position_ptr[] += $dimension_header_length
            return $decoder_name(buffer, 0, position_ptr, $block_length_get(dimensions),
                acting_version, $num_in_group_get(dimensions), $count_zero_expr)
        end

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

        @inline function wrap!(g::$decoder_name{T}, buffer::T, position_ptr::PositionPointer, acting_version) where {T}
            return reset!(g, buffer, position_ptr, acting_version)
        end

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
        @inline function next!(g::$abstract_type_name)
            if g.index >= g.count
                error("index >= count")
            end
            g.offset = sbe_position(g)
            sbe_position!(g, g.offset + sbe_acting_block_length(g))
            g.index += one($count_type_symbol)
            return g
        end
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
        Base.eltype(::Type{<:$decoder_name}) = $decoder_name
        Base.eltype(::Type{<:$encoder_name}) = $encoder_name
        Base.isdone(g::$abstract_type_name, state=nothing) = g.index >= g.count
        Base.length(g::$abstract_type_name) = Int(g.count)

        function reset_count_to_index!(g::$encoder_name)
            g.count = g.index
            dimensions = $dimension_encoder(g.buffer, g.initial_position)
            $num_in_group_set(dimensions, g.count)
            return g.count
        end

        export reset_count_to_index!

        $(field_exprs...)
        $(var_data_exprs...)
        $(group_exprs...)

        @inline function sbe_skip!(m::$decoder_name)
            $(isempty(skip_calls) ? :(return) : Expr(:block, skip_calls...))
            return
        end

        export $abstract_type_name, $decoder_name, $encoder_name
        end
    end

    group_body = extract_expr_from_quote(group_quoted, :module)

    accessor_name = Symbol(format_property_name(group_name))
    accessor_name_encoder = Symbol(string(accessor_name, "!"))
    accessor_group_count = Symbol(string(accessor_name, "_group_count!"))

    if since_version > 0
        push!(parent_accessors, quote
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
            $accessor_group_count(m::$parent_encoder_name, count) = $accessor_name_encoder(m, count)
            $(Symbol(accessor_name, :_id))(::$parent_abstract_type) = $(template_id_expr(ir, group_id))
            $(Symbol(accessor_name, :_since_version))(::$parent_abstract_type) = $(version_expr(ir, since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::$parent_abstract_type) = sbe_acting_version(m) >= $(version_expr(ir, since_version))
            export $accessor_name, $(Symbol(accessor_name, "!")), $accessor_name_encoder, $group_module_name
        end)
    else
        push!(parent_accessors, quote
            @inline function $accessor_name(m::$parent_abstract_type)
                return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $(Symbol(accessor_name, "!"))(m::$parent_abstract_type, g::$group_module_name.Decoder)
                return $group_module_name.reset!(g, m.buffer, sbe_position_ptr(m), sbe_acting_version(m))
            end
            @inline function $accessor_name_encoder(m::$parent_abstract_type, count)
                return $group_module_name.Encoder(m.buffer, count, sbe_position_ptr(m))
            end
            $accessor_group_count(m::$parent_encoder_name, count) = $accessor_name_encoder(m, count)
            $(Symbol(accessor_name, :_id))(::$parent_abstract_type) = $(template_id_expr(ir, group_id))
            $(Symbol(accessor_name, :_since_version))(::$parent_abstract_type) = $(version_expr(ir, since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::$parent_abstract_type) = sbe_acting_version(m) >= $(version_expr(ir, since_version))
            export $accessor_name, $(Symbol(accessor_name, "!")), $accessor_name_encoder, $group_module_name
        end)
    end

    return [group_body], parent_accessors, accessor_name, group_module_name
end

function generate_message_expr(message_tokens::Vector{IR.Token}, ir::IR.Ir)
    msg_token = message_tokens[1]
    message_name = Symbol(format_struct_name(msg_token.name))
    abstract_type_name = Symbol(string("Abstract", message_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    header_module = Symbol(format_struct_name(ir.header_structure.tokens[1].name))
    version_type_symbol = header_field_type(ir, "version")

    body = IR.get_message_body(message_tokens)
    fields, idx = split_components(collect(body), IR.Signal.BEGIN_FIELD, 1)
    groups, idx = split_components(collect(body), IR.Signal.BEGIN_GROUP, idx)
    var_data, _ = split_components(collect(body), IR.Signal.BEGIN_VAR_DATA, idx)

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    field_exprs = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()
    group_exprs = Expr[]
    group_accessors = Expr[]
    skip_calls = Expr[]
    var_data_exprs = Expr[]

    for field_tokens in fields
        inner = field_tokens[2]
        if inner.signal == IR.Signal.ENCODING
            append!(field_exprs, generate_encoded_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_ENUM
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_enum_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_SET
            push!(enum_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_set_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        elseif inner.signal == IR.Signal.BEGIN_COMPOSITE
            push!(composite_imports, composite_member_module_name(inner))
            append!(field_exprs, generate_composite_field_expr(field_tokens, abstract_type_name, decoder_name, encoder_name, ir))
        end
    end

    for group_tokens in groups
        group_defs, parent_accessors, accessor_name, group_module_name = generate_group_expr(
            group_tokens,
            abstract_type_name,
            encoder_name,
            ir,
            2
        )
        append!(group_exprs, group_defs)
        append!(group_accessors, parent_accessors)
        push!(skip_calls, quote
            for group in $accessor_name(m)
                $group_module_name.sbe_skip!(group)
            end
        end)
    end

    for var_data_tokens in var_data
        name_symbol = Symbol(format_property_name(var_data_tokens[1].name))
        skip_name = Symbol(string("skip_", name_symbol, "!"))
        push!(skip_calls, :($skip_name(m)))
        append!(var_data_exprs, generate_var_data_expr(var_data_tokens, abstract_type_name, decoder_name, encoder_name, ir))
    end

    message_quoted = quote
        module $message_name
        export $abstract_type_name, $decoder_name, $encoder_name
        using SBE: AbstractSbeMessage, PositionPointer, to_string
        import SBE: sbe_buffer, sbe_offset, sbe_position_ptr, sbe_position, sbe_position!
        import SBE: sbe_block_length, sbe_template_id, sbe_schema_id, sbe_schema_version
        import SBE: sbe_acting_block_length, sbe_acting_version, sbe_rewind!
        import SBE: sbe_encoded_length, sbe_decoded_length, sbe_semantic_type
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

        mutable struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
            buffer::T
            offset::Int64
            position_ptr::PositionPointer
            acting_block_length::UInt16
            acting_version::$version_type_symbol
            function $decoder_name{T}() where {T<:AbstractArray{UInt8}}
                obj = new{T}()
                obj.offset = Int64(0)
                obj.position_ptr = PositionPointer()
                obj.acting_block_length = UInt16(0)
                obj.acting_version = $version_type_symbol(0)
                return obj
            end
        end

        mutable struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
            buffer::T
            offset::Int64
            position_ptr::PositionPointer
            function $encoder_name{T}() where {T<:AbstractArray{UInt8}}
                obj = new{T}()
                obj.offset = Int64(0)
                obj.position_ptr = PositionPointer()
                return obj
            end
        end

        @inline function $decoder_name(::Type{T}) where {T<:AbstractArray{UInt8}}
            return $decoder_name{T}()
        end

        @inline function $encoder_name(::Type{T}) where {T<:AbstractArray{UInt8}}
            return $encoder_name{T}()
        end

        @inline function wrap!(m::$decoder_name{T}, buffer::T, offset::Integer,
            acting_block_length::Integer, acting_version::Integer) where {T}
            m.buffer = buffer
            m.offset = Int64(offset)
            m.acting_block_length = UInt16(acting_block_length)
            m.acting_version = $version_type_symbol(acting_version)
            m.position_ptr[] = m.offset + m.acting_block_length
            return m
        end

        @inline function wrap!(m::$decoder_name, buffer::AbstractArray, offset::Integer=0;
            header=$header_module.Decoder(buffer, offset))
            if $header_module.templateId(header) != $(template_id_expr(ir, msg_token.id)) ||
               $header_module.schemaId(header) != $(schema_id_expr(ir, ir.id))
                throw(DomainError("Template id or schema id mismatch"))
            end
            return wrap!(m, buffer, offset + sbe_encoded_length(header),
                $header_module.blockLength(header), $header_module.version(header))
        end

        @inline function wrap!(m::$encoder_name{T}, buffer::T, offset::Integer) where {T}
            m.buffer = buffer
            m.offset = Int64(offset)
            m.position_ptr[] = m.offset + $(block_length_expr(ir, msg_token.encoded_length))
            return m
        end

        @inline function wrap_and_apply_header!(m::$encoder_name, buffer::AbstractArray, offset::Integer=0;
            header=$header_module.Encoder(buffer, offset))
            $header_module.blockLength!(header, $(block_length_expr(ir, msg_token.encoded_length)))
            $header_module.templateId!(header, $(template_id_expr(ir, msg_token.id)))
            $header_module.schemaId!(header, $(schema_id_expr(ir, ir.id)))
            $header_module.version!(header, $(version_expr(ir, ir.version)))
            return wrap!(m, buffer, offset + sbe_encoded_length(header))
        end

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
        sbe_acting_block_length(m::$decoder_name) = m.acting_block_length
        sbe_acting_block_length(::$encoder_name) = $(block_length_expr(ir, msg_token.encoded_length))
        sbe_acting_version(m::$decoder_name) = m.acting_version
        sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))
        sbe_rewind!(m::$abstract_type_name) = sbe_position!(m, m.offset + sbe_acting_block_length(m))
        sbe_encoded_length(m::$abstract_type_name) = sbe_position(m) - m.offset

        Base.sizeof(m::$abstract_type_name) = sbe_encoded_length(m)

        $(field_exprs...)
        $(group_exprs...)
        $(group_accessors...)
        $(var_data_exprs...)

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

    return extract_expr_from_quote(message_quoted, :module)
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
    return IrSetDef(set_name, encoding_type, choices, begin_token.version, begin_token.offset)
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

    return Expr(
        :macrocall,
        Symbol("@enumx"),
        LineNumberNode(0, Symbol("ir_codegen")),
        Expr(:(=), :T, :SbeEnum),
        Expr(:(::), enum_name, encoding_type_symbol),
        Expr(:block, enum_values...)
    )
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

            export $abstract_type_name, $decoder_name, $encoder_name
            export clear!, is_empty, raw_value
        end
    end

    return extract_expr_from_quote(set_quoted, :module)
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

function generate_ir_module_expr(ir::IR.Ir; module_name::Union{Nothing, Symbol, String}=nothing)
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
        push!(message_exprs, generate_message_expr(tokens, ir))
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

    if alias_name != module_name
        return Expr(:block, module_expr, :(const $alias_name = $module_name))
    end
    return module_expr
end
