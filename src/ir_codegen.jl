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

function format_struct_name(name::String)
    parts = split(name, r"[_\\-]")
    return join([uppercasefirst(part) for part in parts])
end

function format_property_name(name::String)
    parts = split(name, r"[_\\-]")
    if length(parts) == 1
        return lowercase(name)
    end
    return lowercase(parts[1]) * join([uppercasefirst(part) for part in parts[2:end]])
end

function primitive_value_literal(value::IR.PrimitiveValue, primitive_type::IR.PrimitiveType.T)
    if value.representation == IR.PrimitiveValueRepresentation.BYTE_ARRAY
        return repr(value.value)
    elseif value.representation == IR.PrimitiveValueRepresentation.DOUBLE
        if primitive_type == IR.PrimitiveType.FLOAT
            return "Float32(" * value.value * ")"
        elseif primitive_type == IR.PrimitiveType.DOUBLE
            return "Float64(" * value.value * ")"
        end
        return value.value
    end

    if primitive_type == IR.PrimitiveType.CHAR
        return "UInt8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT8
        return "UInt8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT16
        return "UInt16(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT32
        return "UInt32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.UINT64
        return "UInt64(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT8
        return "Int8(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT16
        return "Int16(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT32
        return "Int32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.INT64
        return "Int64(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.FLOAT
        return "Float32(" * value.value * ")"
    elseif primitive_type == IR.PrimitiveType.DOUBLE
        return "Float64(" * value.value * ")"
    end

    return value.value
end

function enum_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    encoding_type = begin_token.encoding.primitive_type
    values = IrEnumValue[]
    for token in tokens
        if token.signal == IR.Signal.VALID_VALUE
            literal = primitive_value_literal(token.encoding.const_value, encoding_type)
            push!(values, IrEnumValue(token.name, literal, token.description, token.version, token.deprecated))
        end
    end
    return IrEnumDef(begin_token.name, encoding_type, values)
end

function composite_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
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
        begin_token.name,
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
    return primitive_value_literal(actual, primitive_type)
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
                len = min(length(bytes), length(dest))
                copyto!(dest, 1, bytes, 1, len)
                if len < length(dest)
                    fill!(view(dest, len+1:length(dest)), 0x00)
                end
            end

            @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                dest = encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
                len = min(length(value), length(dest))
                copyto!(dest, 1, value, 1, len)
                if len < length(dest)
                    fill!(view(dest, len+1:length(dest)), 0x00)
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

        @inline function $(Symbol(member_name, :!))(m::$encoder_name)
            return encode_array($julia_type, m.buffer, m.offset + $(token.offset), $array_len)
        end

        @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
            copyto!($(Symbol(member_name, :!))(m), val)
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

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
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

    exprs = Expr[]

    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(ir, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(ir, token.version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(ir, token.version))

        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
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

    field_exprs = Expr[]
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
            using MappedArrays: mappedarray
            $(needs_enumx ? :(using EnumX) : nothing)

            $([:($using_stmt) for using_stmt in [:(using ..$enum_name) for enum_name in enum_imports]]...)
            $([:($using_stmt) for using_stmt in [:(using ..$composite_name) for composite_name in composite_imports]]...)

            $endian_imports

            abstract type $abstract_type_name <: AbstractSbeCompositeType end

            struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int64
                acting_version::UInt16
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

            sbe_encoded_length(::$abstract_type_name) = $(block_length_expr(ir, composite_def.encoded_length))
            sbe_encoded_length(::Type{<:$abstract_type_name}) = $(block_length_expr(ir, composite_def.encoded_length))

            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(ir, ir.version))

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
                len = min(length(bytes), length(dest))
                copyto!(dest, 1, bytes, 1, len)
                if len < length(dest)
                    fill!(view(dest, len+1:length(dest)), 0x00)
                end
            end

            @inline function $(Symbol(field_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                dest = encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
                len = min(length(value), length(dest))
                copyto!(dest, 1, value, 1, len)
                if len < length(dest)
                    fill!(view(dest, len+1:length(dest)), 0x00)
                end
            end

            export $field_name, $(Symbol(field_name, :!))
        end)
        return exprs
    end

    push!(exprs, quote
        @inline function $field_name(m::$decoder_name)
            return decode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
        end

        @inline function $(Symbol(field_name, :!))(m::$encoder_name)
            return encode_array($julia_type, m.buffer, m.offset + $(field_token.offset), $array_len)
        end

        @inline function $(Symbol(field_name, :!))(m::$encoder_name, val)
            copyto!($(Symbol(field_name, :!))(m), val)
        end

        export $field_name, $(Symbol(field_name, :!))
    end)

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

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))

        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = Int($offset)
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = Int($offset)
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = Int($(sizeof(julia_type)))
    end)
    push!(exprs, field_meta_attribute_expr(field_name, abstract_type_name, field_token))

    if field_token.encoding.presence == IR.Presence.CONSTANT
        const_val = field_token.encoding.const_value
        literal = primitive_value_literal(const_val, encoding_type)
        push!(exprs, quote
            @inline function $field_name(::$decoder_name)
                return $enum_module.SbeEnum($(Meta.parse(literal)))
            end
            export $field_name
        end)
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

    exprs = Expr[]
    push!(exprs, quote
        $(Symbol(field_name, :_id))(::$abstract_type_name) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_id))(::Type{<:$abstract_type_name}) = $(template_id_expr(ir, field_token.id))
        $(Symbol(field_name, :_since_version))(::$abstract_type_name) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_since_version))(::Type{<:$abstract_type_name}) = $(version_expr(ir, field_token.version))
        $(Symbol(field_name, :_in_acting_version))(m::$abstract_type_name) = sbe_acting_version(m) >= $(version_expr(ir, field_token.version))

        $(Symbol(field_name, :_encoding_offset))(::$abstract_type_name) = Int($offset)
        $(Symbol(field_name, :_encoding_offset))(::Type{<:$abstract_type_name}) = Int($offset)
        $(Symbol(field_name, :_encoding_length))(::$abstract_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(field_name, :_encoding_length))(::Type{<:$abstract_type_name}) = Int($(sizeof(julia_type)))
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

function generate_message_expr(message_tokens::Vector{IR.Token}, ir::IR.Ir)
    msg_token = message_tokens[1]
    message_name = Symbol(format_struct_name(msg_token.name))
    abstract_type_name = Symbol(string("Abstract", message_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    header_module = Symbol(format_struct_name(ir.header_structure.tokens[1].name))

    body = IR.get_message_body(message_tokens)
    fields, idx = split_components(collect(body), IR.Signal.BEGIN_FIELD, 1)
    groups, idx = split_components(collect(body), IR.Signal.BEGIN_GROUP, idx)
    var_data, _ = split_components(collect(body), IR.Signal.BEGIN_VAR_DATA, idx)

    endian_imports = generate_encoded_types_expr(ir.byte_order)

    field_exprs = Expr[]
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()

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

    message_quoted = quote
        module $message_name
        export $abstract_type_name, $decoder_name, $encoder_name
        abstract type $abstract_type_name{T} end

        using ..$header_module
        $([:($using_stmt) for using_stmt in [:(using ..$enum_name) for enum_name in enum_imports]]...)
        $([:($using_stmt) for using_stmt in [:(using ..$composite_name) for composite_name in composite_imports]]...)

        $endian_imports

        struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
            buffer::T
            offset::Int64
            position_ptr::Base.RefValue{Int64}
            acting_block_length::UInt16
            acting_version::UInt16
            function $decoder_name(buffer::T, offset::Integer, position_ptr::Ref{Int64},
                acting_block_length::Integer, acting_version::Integer) where {T}
                position_ptr[] = offset + acting_block_length
                new{T}(buffer, offset, position_ptr, acting_block_length, acting_version)
            end
        end

        struct $encoder_name{T<:AbstractArray{UInt8},HasSbeHeader} <: $abstract_type_name{T}
            buffer::T
            offset::Int64
            position_ptr::Base.RefValue{Int64}
            function $encoder_name(buffer::T, offset::Integer,
                position_ptr::Ref{Int64}, hasSbeHeader::Bool=false) where {T}
                position_ptr[] = offset + $(block_length_expr(ir, msg_token.encoded_length))
                new{T,hasSbeHeader}(buffer, offset, position_ptr)
            end
        end

        @inline function $decoder_name(buffer::AbstractArray, offset::Integer=0;
            position_ptr::Base.RefValue{Int64}=Ref(0),
            header::$header_module=$header_module(buffer, offset))
            if $header_module.templateId(header) != $(template_id_expr(ir, msg_token.id)) ||
               $header_module.schemaId(header) != $(schema_id_expr(ir, ir.id))
                throw(DomainError("Template id or schema id mismatch"))
            end
            $decoder_name(buffer, offset + sbe_encoded_length(header), position_ptr,
                $header_module.blockLength(header), $header_module.version(header))
        end

        @inline function $encoder_name(buffer::AbstractArray, offset::Integer=0;
            position_ptr::Base.RefValue{Int64}=Ref(0),
            header::$header_module=$header_module(buffer, offset))
            $header_module.blockLength!(header, $(block_length_expr(ir, msg_token.encoded_length)))
            $header_module.templateId!(header, $(template_id_expr(ir, msg_token.id)))
            $header_module.schemaId!(header, $(schema_id_expr(ir, ir.id)))
            $header_module.version!(header, $(version_expr(ir, ir.version)))
            $encoder_name(buffer, offset + sbe_encoded_length(header), position_ptr, true)
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
        end
    end

    return extract_expr_from_quote(message_quoted, :module)
end

function set_def_from_tokens(tokens::Vector{IR.Token})
    begin_token = tokens[1]
    encoding_type = begin_token.encoding.primitive_type
    choices = IrSetChoice[]
    for token in tokens
        if token.signal == IR.Signal.CHOICE
            bit_position = parse(Int, token.encoding.const_value.value)
            push!(choices, IrSetChoice(token.name, bit_position, token.description, token.version, token.deprecated))
        end
    end
    return IrSetDef(begin_token.name, encoding_type, choices, begin_token.version, begin_token.offset)
end

function generate_enum_expr(enum_def::IrEnumDef)
    enum_name = Symbol(format_struct_name(enum_def.name))
    encoding_julia_type = IR.primitive_type_julia(enum_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    enum_values = Expr[]

    for value in enum_def.values
        value_name = Symbol(value.name)
        push!(enum_values, :($value_name = $(Meta.parse(value.literal))))
    end

    null_value = if enum_def.encoding_type == IR.PrimitiveType.CHAR
        UInt8(0x0)
    else
        encoding_julia_type <: Unsigned ? typemax(encoding_julia_type) : typemin(encoding_julia_type)
    end

    push!(enum_values, :(NULL_VALUE = $encoding_type_symbol($null_value)))

    enum_quoted = quote
        @enumx T = SbeEnum $enum_name::$encoding_julia_type begin
            $(enum_values...)
        end
    end

    return extract_expr_from_quote(enum_quoted, :macrocall)
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

    encoding_julia_type = IR.primitive_type_julia(set_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    encoding_size = sizeof(encoding_julia_type)

    choice_exprs = Expr[]
    for choice in set_def.choices
        choice_func_name = Symbol(format_property_name(choice.name))
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

            $endian_imports

            abstract type $abstract_type_name <: AbstractSbeEncodedType end

            struct $decoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
                acting_version::UInt16
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
    parts = split(replace(package_name, "." => "_"), "_")
    return Symbol(join([uppercasefirst(part) for part in parts]))
end

function generate_ir_module_expr(ir::IR.Ir)
    module_name = module_name_from_package(ir.package_name)
    enum_exprs = Expr[]
    set_exprs = Expr[]
    composite_exprs = Expr[]
    message_exprs = Expr[]

    for tokens in values(ir.types_by_name)
        if isempty(tokens)
            continue
        end
        if tokens[1].signal == IR.Signal.BEGIN_ENUM
            enum_def = enum_def_from_tokens(tokens)
            push!(enum_exprs, generate_enum_expr(enum_def))
        elseif tokens[1].signal == IR.Signal.BEGIN_SET
            set_def = set_def_from_tokens(tokens)
            push!(set_exprs, generate_set_expr(set_def, ir))
        elseif tokens[1].signal == IR.Signal.BEGIN_COMPOSITE
            composite_def = composite_def_from_tokens(tokens)
            push!(composite_exprs, generate_composite_expr(composite_def, ir))
        end
    end

    for tokens in values(ir.messages_by_id)
        push!(message_exprs, generate_message_expr(tokens, ir))
    end

    module_quoted = quote
        module $module_name
            using EnumX
            $(enum_exprs...)
            $(set_exprs...)
            $(composite_exprs...)
            $(message_exprs...)
        end
    end

    return extract_expr_from_quote(module_quoted, :module)
end
