"""
Intermediate Representation (IR) types and utilities.

Ported from the SBE reference implementation to support XML -> IR -> Julia codegen.
"""
module IR

using EnumX

export Signal, Presence, PrimitiveType, PrimitiveValue, PrimitiveValueRepresentation
export Encoding, Token, Ir, HeaderStructure
export INVALID_ID, VARIABLE_LENGTH
export primitive_type_name, primitive_type_size, primitive_type_julia
export primitive_type_min, primitive_type_max, primitive_type_null
export applicable_type_name, array_length, is_constant_encoding, is_optional_encoding
export update_component_token_counts!
export collect_fields, collect_groups, collect_var_data, collect_tokens
export get_message_body, find_end_signal, find_sub_group_names, find_signal

const INVALID_ID = -1
const VARIABLE_LENGTH = -1

@enumx Signal begin
    BEGIN_MESSAGE
    END_MESSAGE
    BEGIN_COMPOSITE
    END_COMPOSITE
    BEGIN_FIELD
    END_FIELD
    BEGIN_GROUP
    END_GROUP
    BEGIN_ENUM
    VALID_VALUE
    END_ENUM
    BEGIN_SET
    CHOICE
    END_SET
    BEGIN_VAR_DATA
    END_VAR_DATA
    ENCODING
end

@enumx Presence begin
    REQUIRED
    OPTIONAL
    CONSTANT
end

@enumx PrimitiveType begin
    NONE
    CHAR
    INT8
    INT16
    INT32
    INT64
    UINT8
    UINT16
    UINT32
    UINT64
    FLOAT
    DOUBLE
end

@enumx PrimitiveValueRepresentation begin
    LONG
    DOUBLE
    BYTE_ARRAY
end

struct PrimitiveValue
    representation::PrimitiveValueRepresentation.T
    value::String
    character_encoding::Union{Nothing, String}
    size::Int
end

struct Encoding
    presence::Presence.T
    primitive_type::PrimitiveType.T
    byte_order::Symbol
    min_value::Union{Nothing, PrimitiveValue}
    max_value::Union{Nothing, PrimitiveValue}
    null_value::Union{Nothing, PrimitiveValue}
    const_value::Union{Nothing, PrimitiveValue}
    character_encoding::Union{Nothing, String}
    epoch::Union{Nothing, String}
    time_unit::Union{Nothing, String}
    semantic_type::Union{Nothing, String}
end

Encoding() = Encoding(
    Presence.REQUIRED, PrimitiveType.NONE, :littleEndian,
    nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing
)

struct Token
    signal::Signal.T
    name::String
    referenced_name::Union{Nothing, String}
    description::String
    package_name::Union{Nothing, String}
    id::Int
    version::Int
    deprecated::Int
    encoded_length::Int
    offset::Int
    component_token_count::Int
    encoding::Encoding
end

struct HeaderStructure
    tokens::Vector{Token}
    block_length_type::PrimitiveType.T
    template_id_type::PrimitiveType.T
    schema_id_type::PrimitiveType.T
    schema_version_type::PrimitiveType.T
end

struct Ir
    package_name::String
    namespace_name::Union{Nothing, String}
    id::Int
    version::Int
    description::String
    semantic_version::String
    byte_order::Symbol
    header_structure::HeaderStructure
    messages_by_id::Dict{Int, Vector{Token}}
    types_by_name::Dict{String, Vector{Token}}
    namespaces::Vector{String}
end

primitive_type_name(pt::PrimitiveType.T) = Dict(
    PrimitiveType.NONE => "none",
    PrimitiveType.CHAR => "char",
    PrimitiveType.INT8 => "int8",
    PrimitiveType.INT16 => "int16",
    PrimitiveType.INT32 => "int32",
    PrimitiveType.INT64 => "int64",
    PrimitiveType.UINT8 => "uint8",
    PrimitiveType.UINT16 => "uint16",
    PrimitiveType.UINT32 => "uint32",
    PrimitiveType.UINT64 => "uint64",
    PrimitiveType.FLOAT => "float",
    PrimitiveType.DOUBLE => "double"
)[pt]

primitive_type_size(pt::PrimitiveType.T) = Dict(
    PrimitiveType.NONE => 0,
    PrimitiveType.CHAR => 1,
    PrimitiveType.INT8 => 1,
    PrimitiveType.INT16 => 2,
    PrimitiveType.INT32 => 4,
    PrimitiveType.INT64 => 8,
    PrimitiveType.UINT8 => 1,
    PrimitiveType.UINT16 => 2,
    PrimitiveType.UINT32 => 4,
    PrimitiveType.UINT64 => 8,
    PrimitiveType.FLOAT => 4,
    PrimitiveType.DOUBLE => 8
)[pt]

primitive_type_julia(pt::PrimitiveType.T) = Dict(
    PrimitiveType.CHAR => :UInt8,
    PrimitiveType.INT8 => :Int8,
    PrimitiveType.INT16 => :Int16,
    PrimitiveType.INT32 => :Int32,
    PrimitiveType.INT64 => :Int64,
    PrimitiveType.UINT8 => :UInt8,
    PrimitiveType.UINT16 => :UInt16,
    PrimitiveType.UINT32 => :UInt32,
    PrimitiveType.UINT64 => :UInt64,
    PrimitiveType.FLOAT => :Float32,
    PrimitiveType.DOUBLE => :Float64
)[pt]

function primitive_value_long(value::Integer, size::Int)
    PrimitiveValue(PrimitiveValueRepresentation.LONG, string(value), nothing, size)
end

function primitive_value_double(value::AbstractFloat, size::Int)
    PrimitiveValue(PrimitiveValueRepresentation.DOUBLE, string(value), nothing, size)
end

function primitive_value_bytes(value::String, encoding::String, size::Int)
    PrimitiveValue(PrimitiveValueRepresentation.BYTE_ARRAY, value, encoding, size)
end

function primitive_type_min(pt::PrimitiveType.T)
    if pt == PrimitiveType.CHAR
        return primitive_value_long(0x20, 1)
    elseif pt == PrimitiveType.INT8
        return primitive_value_long(-127, 1)
    elseif pt == PrimitiveType.INT16
        return primitive_value_long(-32767, 2)
    elseif pt == PrimitiveType.INT32
        return primitive_value_long(-2147483647, 4)
    elseif pt == PrimitiveType.INT64
        return primitive_value_long(-9223372036854775807, 8)
    elseif pt == PrimitiveType.UINT8
        return primitive_value_long(0, 1)
    elseif pt == PrimitiveType.UINT16
        return primitive_value_long(0, 2)
    elseif pt == PrimitiveType.UINT32
        return primitive_value_long(0, 4)
    elseif pt == PrimitiveType.UINT64
        return primitive_value_long(0, 8)
    elseif pt == PrimitiveType.FLOAT
        return primitive_value_double(-floatmax(Float32), 4)
    elseif pt == PrimitiveType.DOUBLE
        return primitive_value_double(-floatmax(Float64), 8)
    end
    return primitive_value_long(0, 0)
end

function primitive_type_max(pt::PrimitiveType.T)
    if pt == PrimitiveType.CHAR
        return primitive_value_long(0x7e, 1)
    elseif pt == PrimitiveType.INT8
        return primitive_value_long(127, 1)
    elseif pt == PrimitiveType.INT16
        return primitive_value_long(32767, 2)
    elseif pt == PrimitiveType.INT32
        return primitive_value_long(2147483647, 4)
    elseif pt == PrimitiveType.INT64
        return primitive_value_long(9223372036854775807, 8)
    elseif pt == PrimitiveType.UINT8
        return primitive_value_long(254, 1)
    elseif pt == PrimitiveType.UINT16
        return primitive_value_long(65534, 2)
    elseif pt == PrimitiveType.UINT32
        return primitive_value_long(0xffffffff - 1, 4)
    elseif pt == PrimitiveType.UINT64
        return primitive_value_long(0xffffffffffffffff - 1, 8)
    elseif pt == PrimitiveType.FLOAT
        return primitive_value_double(floatmax(Float32), 4)
    elseif pt == PrimitiveType.DOUBLE
        return primitive_value_double(floatmax(Float64), 8)
    end
    return primitive_value_long(0, 0)
end

function primitive_type_null(pt::PrimitiveType.T)
    if pt == PrimitiveType.CHAR
        return primitive_value_long(0, 1)
    elseif pt == PrimitiveType.INT8
        return primitive_value_long(-128, 1)
    elseif pt == PrimitiveType.INT16
        return primitive_value_long(-32768, 2)
    elseif pt == PrimitiveType.INT32
        return primitive_value_long(-2147483648, 4)
    elseif pt == PrimitiveType.INT64
        return primitive_value_long(-9223372036854775808, 8)
    elseif pt == PrimitiveType.UINT8
        return primitive_value_long(255, 1)
    elseif pt == PrimitiveType.UINT16
        return primitive_value_long(65535, 2)
    elseif pt == PrimitiveType.UINT32
        return primitive_value_long(0xffffffff, 4)
    elseif pt == PrimitiveType.UINT64
        return primitive_value_long(0xffffffffffffffff, 8)
    elseif pt == PrimitiveType.FLOAT
        return primitive_value_double(Float32(NaN), 4)
    elseif pt == PrimitiveType.DOUBLE
        return primitive_value_double(Float64(NaN), 8)
    end
    return primitive_value_long(0, 0)
end

applicable_type_name(token::Token) = isnothing(token.referenced_name) ? token.name : token.referenced_name

function array_length(token::Token)
    if token.encoding.primitive_type == PrimitiveType.NONE || token.encoded_length == 0
        return 0
    end
    return token.encoded_length ÷ primitive_type_size(token.encoding.primitive_type)
end

is_constant_encoding(token::Token) = token.encoding.presence == Presence.CONSTANT
is_optional_encoding(token::Token) = token.encoding.presence == Presence.OPTIONAL

function update_component_token_counts!(tokens::Vector{Token})
    stacks = Dict{String, Vector{Int}}()
    for i in eachindex(tokens)
        token = tokens[i]
        signal_name = string(token.signal)
        if startswith(signal_name, "BEGIN_")
            component_type = signal_name[7:end]
            stack = get!(stacks, component_type, Int[])
            push!(stack, i)
        elseif startswith(signal_name, "END_")
            component_type = signal_name[5:end]
            stack = get!(stacks, component_type, Int[])
            begin_index = pop!(stack)
            component_count = (i - begin_index) + 1
            tokens[begin_index] = Token(
                tokens[begin_index].signal,
                tokens[begin_index].name,
                tokens[begin_index].referenced_name,
                tokens[begin_index].description,
                tokens[begin_index].package_name,
                tokens[begin_index].id,
                tokens[begin_index].version,
                tokens[begin_index].deprecated,
                tokens[begin_index].encoded_length,
                tokens[begin_index].offset,
                component_count,
                tokens[begin_index].encoding
            )
            tokens[i] = Token(
                tokens[i].signal,
                tokens[i].name,
                tokens[i].referenced_name,
                tokens[i].description,
                tokens[i].package_name,
                tokens[i].id,
                tokens[i].version,
                tokens[i].deprecated,
                tokens[i].encoded_length,
                tokens[i].offset,
                component_count,
                tokens[i].encoding
            )
        end
    end
    return tokens
end

function collect_tokens(signal::Signal.T, tokens::Vector{Token}, index::Int, collected::Vector{Token})
    i = index
    while i <= length(tokens)
        token = tokens[i]
        if token.signal != signal
            break
        end
        token_count = token.component_token_count
        for j in i:(i + token_count - 1)
            push!(collected, tokens[j])
        end
        i += token_count
    end
    return i
end

collect_fields(tokens::Vector{Token}, index::Int, fields::Vector{Token}) =
    collect_tokens(Signal.BEGIN_FIELD, tokens, index, fields)

collect_groups(tokens::Vector{Token}, index::Int, groups::Vector{Token}) =
    collect_tokens(Signal.BEGIN_GROUP, tokens, index, groups)

collect_var_data(tokens::Vector{Token}, index::Int, var_data::Vector{Token}) =
    collect_tokens(Signal.BEGIN_VAR_DATA, tokens, index, var_data)

get_message_body(tokens::Vector{Token}) = @view tokens[2:end-1]

function find_end_signal(tokens::Vector{Token}, index::Int, signal::Signal.T, name::String)
    result = length(tokens)
    for i in index:(length(tokens) - 1)
        token = tokens[i]
        if token.signal == signal && token.name == name
            result = i
            break
        end
    end
    return result
end

function find_sub_group_names(tokens::Vector{Token})
    names = String[]
    level = 0
    for token in tokens
        if token.signal == Signal.BEGIN_GROUP
            if level == 0
                push!(names, token.name)
            end
            level += 1
        elseif token.signal == Signal.END_GROUP
            level -= 1
        end
    end
    return names
end

function find_signal(tokens::Vector{Token}, signal::Signal.T)
    for i in 1:(length(tokens) - 1)
        if tokens[i].signal == signal
            return i
        end
    end
    return -1
end

end # module IR
