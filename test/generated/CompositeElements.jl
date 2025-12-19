module CompositeElements
using SBE: AbstractSbeMessage, AbstractSbeField, AbstractSbeGroup
using SBE: PositionPointer, to_string
using EnumX
using MappedArrays
using StringViews
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
@enumx T = SbeEnum EnumOne::UInt8 begin
        Value1 = UInt8(0x01)
        Value10 = UInt8(0x0a)
        NULL_VALUE = UInt8(0xff)
    end
module SetOne
using SBE: AbstractSbeEncodedType
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractSetOne <: AbstractSbeEncodedType end
struct Decoder{T <: AbstractVector{UInt8}} <: AbstractSetOne
    buffer::T
    offset::Int
    acting_version::UInt16
end
struct Encoder{T <: AbstractVector{UInt8}} <: AbstractSetOne
    buffer::T
    offset::Int
end
@inline function Decoder(buffer::AbstractVector{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0000))
    end
@inline function Decoder(buffer::AbstractVector{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0000))
    end
@inline function Encoder(buffer::AbstractVector{UInt8})
        Encoder(buffer, Int64(0))
    end
id(::Type{<:AbstractSetOne}) = begin
        UInt16(0xffff)
    end
id(::AbstractSetOne) = begin
        UInt16(0xffff)
    end
since_version(::Type{<:AbstractSetOne}) = begin
        UInt16(0)
    end
since_version(::AbstractSetOne) = begin
        UInt16(0)
    end
encoding_offset(::Type{<:AbstractSetOne}) = begin
        1
    end
encoding_offset(::AbstractSetOne) = begin
        1
    end
encoding_length(::Type{<:AbstractSetOne}) = begin
        4
    end
encoding_length(::AbstractSetOne) = begin
        4
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.eltype(::Type{<:AbstractSetOne}) = begin
        UInt32
    end
Base.eltype(::AbstractSetOne) = begin
        UInt32
    end
@inline function clear!(set::Encoder)
        encode_value(UInt32, set.buffer, set.offset, zero(UInt32))
        return set
    end
@inline function is_empty(set::AbstractSetOne)
        return decode_value(UInt32, set.buffer, set.offset) == zero(UInt32)
    end
@inline function raw_value(set::AbstractSetOne)
        return decode_value(UInt32, set.buffer, set.offset)
    end
begin
    @inline function Bit0(set::AbstractSetOne)
            return decode_value(UInt32, set.buffer, set.offset) & UInt32(0x01) << 0 != 0
        end
end
begin
    @inline function Bit0!(set::Encoder, value::Bool)
            bits = decode_value(UInt32, set.buffer, set.offset)
            bits = if value
                    bits | UInt32(0x01) << 0
                else
                    bits & ~(UInt32(0x01) << 0)
                end
            encode_value(UInt32, set.buffer, set.offset, bits)
            return set
        end
end
export Bit0, Bit0!
begin
    @inline function Bit16(set::AbstractSetOne)
            return decode_value(UInt32, set.buffer, set.offset) & UInt32(0x01) << 16 != 0
        end
end
begin
    @inline function Bit16!(set::Encoder, value::Bool)
            bits = decode_value(UInt32, set.buffer, set.offset)
            bits = if value
                    bits | UInt32(0x01) << 16
                else
                    bits & ~(UInt32(0x01) << 16)
                end
            encode_value(UInt32, set.buffer, set.offset, bits)
            return set
        end
end
export Bit16, Bit16!
begin
    @inline function Bit26(set::AbstractSetOne)
            return decode_value(UInt32, set.buffer, set.offset) & UInt32(0x01) << 26 != 0
        end
end
begin
    @inline function Bit26!(set::Encoder, value::Bool)
            bits = decode_value(UInt32, set.buffer, set.offset)
            bits = if value
                    bits | UInt32(0x01) << 26
                else
                    bits & ~(UInt32(0x01) << 26)
                end
            encode_value(UInt32, set.buffer, set.offset, bits)
            return set
        end
end
export Bit26, Bit26!
export AbstractSetOne, Decoder, Encoder
export clear!, is_empty, raw_value
end
module Inner
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
using MappedArrays: mappedarray
nothing
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractInner <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractInner
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractInner
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0000))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0000))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractInner) = begin
        UInt16(16)
    end
sbe_encoded_length(::Type{<:AbstractInner}) = begin
        UInt16(16)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractInner) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractInner)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractInner)
    print(io, "Inner", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    first_id(::AbstractInner) = begin
            UInt16(0xffff)
        end
    first_id(::Type{<:AbstractInner}) = begin
            UInt16(0xffff)
        end
    first_since_version(::AbstractInner) = begin
            UInt16(0)
        end
    first_since_version(::Type{<:AbstractInner}) = begin
            UInt16(0)
        end
    first_in_acting_version(m::AbstractInner) = begin
            m.acting_version >= UInt16(0)
        end
    first_encoding_offset(::AbstractInner) = begin
            Int(0)
        end
    first_encoding_offset(::Type{<:AbstractInner}) = begin
            Int(0)
        end
    first_encoding_length(::AbstractInner) = begin
            Int(8)
        end
    first_encoding_length(::Type{<:AbstractInner}) = begin
            Int(8)
        end
    first_null_value(::AbstractInner) = begin
            Int64(-9223372036854775808)
        end
    first_null_value(::Type{<:AbstractInner}) = begin
            Int64(-9223372036854775808)
        end
    first_min_value(::AbstractInner) = begin
            Int64(-9223372036854775808)
        end
    first_min_value(::Type{<:AbstractInner}) = begin
            Int64(-9223372036854775808)
        end
    first_max_value(::AbstractInner) = begin
            Int64(9223372036854775807)
        end
    first_max_value(::Type{<:AbstractInner}) = begin
            Int64(9223372036854775807)
        end
end
begin
    @inline function first(m::Decoder)
            return decode_value(Int64, m.buffer, m.offset + 0)
        end
    @inline first!(m::Encoder, val) = begin
                encode_value(Int64, m.buffer, m.offset + 0, val)
            end
    export first, first!
end
begin
    second_id(::AbstractInner) = begin
            UInt16(0xffff)
        end
    second_id(::Type{<:AbstractInner}) = begin
            UInt16(0xffff)
        end
    second_since_version(::AbstractInner) = begin
            UInt16(0)
        end
    second_since_version(::Type{<:AbstractInner}) = begin
            UInt16(0)
        end
    second_in_acting_version(m::AbstractInner) = begin
            m.acting_version >= UInt16(0)
        end
    second_encoding_offset(::AbstractInner) = begin
            Int(8)
        end
    second_encoding_offset(::Type{<:AbstractInner}) = begin
            Int(8)
        end
    second_encoding_length(::AbstractInner) = begin
            Int(8)
        end
    second_encoding_length(::Type{<:AbstractInner}) = begin
            Int(8)
        end
    second_null_value(::AbstractInner) = begin
            Int64(-9223372036854775808)
        end
    second_null_value(::Type{<:AbstractInner}) = begin
            Int64(-9223372036854775808)
        end
    second_min_value(::AbstractInner) = begin
            Int64(-9223372036854775808)
        end
    second_min_value(::Type{<:AbstractInner}) = begin
            Int64(-9223372036854775808)
        end
    second_max_value(::AbstractInner) = begin
            Int64(9223372036854775807)
        end
    second_max_value(::Type{<:AbstractInner}) = begin
            Int64(9223372036854775807)
        end
end
begin
    @inline function second(m::Decoder)
            return decode_value(Int64, m.buffer, m.offset + 8)
        end
    @inline second!(m::Encoder, val) = begin
                encode_value(Int64, m.buffer, m.offset + 8, val)
            end
    export second, second!
end
export AbstractInner, Decoder, Encoder
end
module MessageHeader
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
using MappedArrays: mappedarray
nothing
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractMessageHeader <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractMessageHeader
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractMessageHeader
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0000))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0000))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractMessageHeader) = begin
        UInt16(8)
    end
sbe_encoded_length(::Type{<:AbstractMessageHeader}) = begin
        UInt16(8)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractMessageHeader) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractMessageHeader)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractMessageHeader)
    print(io, "MessageHeader", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    blockLength_id(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    blockLength_id(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    blockLength_since_version(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    blockLength_since_version(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    blockLength_in_acting_version(m::AbstractMessageHeader) = begin
            m.acting_version >= UInt16(0)
        end
    blockLength_encoding_offset(::AbstractMessageHeader) = begin
            Int(0)
        end
    blockLength_encoding_offset(::Type{<:AbstractMessageHeader}) = begin
            Int(0)
        end
    blockLength_encoding_length(::AbstractMessageHeader) = begin
            Int(2)
        end
    blockLength_encoding_length(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    blockLength_null_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    blockLength_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    blockLength_min_value(::AbstractMessageHeader) = begin
            UInt16(0x0000)
        end
    blockLength_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0x0000)
        end
    blockLength_max_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    blockLength_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function blockLength(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline blockLength!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, val)
            end
    export blockLength, blockLength!
end
begin
    templateId_id(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    templateId_id(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    templateId_since_version(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    templateId_since_version(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    templateId_in_acting_version(m::AbstractMessageHeader) = begin
            m.acting_version >= UInt16(0)
        end
    templateId_encoding_offset(::AbstractMessageHeader) = begin
            Int(2)
        end
    templateId_encoding_offset(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    templateId_encoding_length(::AbstractMessageHeader) = begin
            Int(2)
        end
    templateId_encoding_length(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    templateId_null_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    templateId_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    templateId_min_value(::AbstractMessageHeader) = begin
            UInt16(0x0000)
        end
    templateId_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0x0000)
        end
    templateId_max_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    templateId_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function templateId(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 2)
        end
    @inline templateId!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 2, val)
            end
    export templateId, templateId!
end
begin
    schemaId_id(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    schemaId_id(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    schemaId_since_version(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    schemaId_since_version(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    schemaId_in_acting_version(m::AbstractMessageHeader) = begin
            m.acting_version >= UInt16(0)
        end
    schemaId_encoding_offset(::AbstractMessageHeader) = begin
            Int(4)
        end
    schemaId_encoding_offset(::Type{<:AbstractMessageHeader}) = begin
            Int(4)
        end
    schemaId_encoding_length(::AbstractMessageHeader) = begin
            Int(2)
        end
    schemaId_encoding_length(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    schemaId_null_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    schemaId_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    schemaId_min_value(::AbstractMessageHeader) = begin
            UInt16(0x0000)
        end
    schemaId_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0x0000)
        end
    schemaId_max_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    schemaId_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function schemaId(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 4)
        end
    @inline schemaId!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 4, val)
            end
    export schemaId, schemaId!
end
begin
    version_id(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    version_id(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    version_since_version(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    version_since_version(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    version_in_acting_version(m::AbstractMessageHeader) = begin
            m.acting_version >= UInt16(0)
        end
    version_encoding_offset(::AbstractMessageHeader) = begin
            Int(6)
        end
    version_encoding_offset(::Type{<:AbstractMessageHeader}) = begin
            Int(6)
        end
    version_encoding_length(::AbstractMessageHeader) = begin
            Int(2)
        end
    version_encoding_length(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    version_null_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    version_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    version_min_value(::AbstractMessageHeader) = begin
            UInt16(0x0000)
        end
    version_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0x0000)
        end
    version_max_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    version_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function version(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 6)
        end
    @inline version!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 6, val)
            end
    export version, version!
end
export AbstractMessageHeader, Decoder, Encoder
end
module Inner
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
using MappedArrays: mappedarray
using EnumX
using ..EnumOne
using ..SetOne
using ..Inner
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractOuter <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractOuter
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractOuter
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0000))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0000))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractOuter) = begin
        UInt16(6)
    end
sbe_encoded_length(::Type{<:AbstractOuter}) = begin
        UInt16(6)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractOuter) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractOuter)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractOuter)
    print(io, "Inner", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    enumOne_id(::AbstractOuter) = begin
            UInt16(0xffff)
        end
    enumOne_id(::Type{<:AbstractOuter}) = begin
            UInt16(0xffff)
        end
    enumOne_since_version(::AbstractOuter) = begin
            UInt16(0)
        end
    enumOne_since_version(::Type{<:AbstractOuter}) = begin
            UInt16(0)
        end
    enumOne_in_acting_version(m::AbstractOuter) = begin
            m.acting_version >= UInt16(0)
        end
    enumOne_encoding_offset(::AbstractOuter) = begin
            Int(0)
        end
    enumOne_encoding_offset(::Type{<:AbstractOuter}) = begin
            Int(0)
        end
    enumOne_encoding_length(::AbstractOuter) = begin
            Int(1)
        end
    enumOne_encoding_length(::Type{<:AbstractOuter}) = begin
            Int(1)
        end
end
begin
    @inline function enumOne(m::Decoder)
            raw_value = decode_value(UInt8, m.buffer, m.offset + 0)
            return EnumOne.SbeEnum(raw_value)
        end
    @inline function enumOne!(m::Encoder, val)
            encode_value(UInt8, m.buffer, m.offset + 0, UInt8(val))
        end
end
begin
    zeroth_id(::AbstractOuter) = begin
            UInt16(0xffff)
        end
    zeroth_id(::Type{<:AbstractOuter}) = begin
            UInt16(0xffff)
        end
    zeroth_since_version(::AbstractOuter) = begin
            UInt16(0)
        end
    zeroth_since_version(::Type{<:AbstractOuter}) = begin
            UInt16(0)
        end
    zeroth_in_acting_version(m::AbstractOuter) = begin
            m.acting_version >= UInt16(0)
        end
    zeroth_encoding_offset(::AbstractOuter) = begin
            Int(1)
        end
    zeroth_encoding_offset(::Type{<:AbstractOuter}) = begin
            Int(1)
        end
    zeroth_encoding_length(::AbstractOuter) = begin
            Int(1)
        end
    zeroth_encoding_length(::Type{<:AbstractOuter}) = begin
            Int(1)
        end
    zeroth_null_value(::AbstractOuter) = begin
            UInt8(0xff)
        end
    zeroth_null_value(::Type{<:AbstractOuter}) = begin
            UInt8(0xff)
        end
    zeroth_min_value(::AbstractOuter) = begin
            UInt8(0x00)
        end
    zeroth_min_value(::Type{<:AbstractOuter}) = begin
            UInt8(0x00)
        end
    zeroth_max_value(::AbstractOuter) = begin
            UInt8(0xff)
        end
    zeroth_max_value(::Type{<:AbstractOuter}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function zeroth(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 1)
        end
    @inline zeroth!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 1, val)
            end
    export zeroth, zeroth!
end
begin
    setOne_id(::AbstractOuter) = begin
            UInt16(0xffff)
        end
    setOne_id(::Type{<:AbstractOuter}) = begin
            UInt16(0xffff)
        end
    setOne_since_version(::AbstractOuter) = begin
            UInt16(0)
        end
    setOne_since_version(::Type{<:AbstractOuter}) = begin
            UInt16(0)
        end
    setOne_in_acting_version(m::AbstractOuter) = begin
            m.acting_version >= UInt16(0)
        end
    setOne_encoding_offset(::AbstractOuter) = begin
            Int(2)
        end
    setOne_encoding_offset(::Type{<:AbstractOuter}) = begin
            Int(2)
        end
    setOne_encoding_length(::AbstractOuter) = begin
            Int(4)
        end
    setOne_encoding_length(::Type{<:AbstractOuter}) = begin
            Int(4)
        end
end
begin
    @inline function setOne(m::Decoder)
            return SetOne.Decoder(m.buffer, m.offset + 2, m.acting_version)
        end
    @inline function setOne(m::Encoder)
            return SetOne.Encoder(m.buffer, m.offset + 2)
        end
end
begin
    inner_id(::AbstractOuter) = begin
            UInt16(0xffff)
        end
    inner_id(::Type{<:AbstractOuter}) = begin
            UInt16(0xffff)
        end
    inner_since_version(::AbstractOuter) = begin
            UInt16(0)
        end
    inner_since_version(::Type{<:AbstractOuter}) = begin
            UInt16(0)
        end
    inner_in_acting_version(m::AbstractOuter) = begin
            m.acting_version >= UInt16(0)
        end
    inner_encoding_offset(::AbstractOuter) = begin
            Int(6)
        end
    inner_encoding_offset(::Type{<:AbstractOuter}) = begin
            Int(6)
        end
    inner_encoding_length(::AbstractOuter) = begin
            Int(16)
        end
    inner_encoding_length(::Type{<:AbstractOuter}) = begin
            Int(16)
        end
end
begin
    @inline function inner(m::Decoder)
            return Inner.Decoder(m.buffer, m.offset + 6, m.acting_version)
        end
    @inline function inner(m::Encoder)
            return Inner.Encoder(m.buffer, m.offset + 6)
        end
end
export AbstractOuter, Decoder, Encoder
end
module Msg
using SBE: AbstractSbeMessage, AbstractSbeEncodedType, AbstractSbeData, AbstractSbeGroup
using MappedArrays: mappedarray
using StringViews: StringView
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
import SBE: sbe_template_id, sbe_schema_id, sbe_schema_version, sbe_block_length
import SBE: sbe_acting_block_length, sbe_buffer, sbe_offset
import SBE: sbe_position_ptr, sbe_position, sbe_position!, sbe_rewind!, sbe_encoded_length
import SBE: sbe_semantic_type, sbe_description
using ..MessageHeader
using ..Outer
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractMsg{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractMsg{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    acting_block_length::UInt16
    acting_version::UInt16
    function Decoder(buffer::T, offset::Int64, position_ptr::PositionPointer, acting_block_length::UInt16, acting_version::UInt16) where T
        position_ptr[] = offset + acting_block_length
        new{T}(buffer, offset, position_ptr, acting_block_length, acting_version)
    end
    function Decoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + UInt16(6)
        new{T}(buffer, offset, position_ptr, UInt16(6), UInt16(0x0000))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractMsg{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 6
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0001) || MessageHeader.schemaId(header) != UInt16(0x0003)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(6))
        MessageHeader.templateId!(header, UInt16(0x0001))
        MessageHeader.schemaId!(header, UInt16(0x0003))
        MessageHeader.version!(header, UInt16(0x0000))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    structure_id(::AbstractMsg) = begin
            UInt16(0x002a)
        end
    structure_since_version(::AbstractMsg) = begin
            UInt16(0)
        end
    structure_in_acting_version(m::AbstractMsg) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    structure_encoding_offset(::AbstractMsg) = begin
            0
        end
    structure_encoding_length(::AbstractMsg) = begin
            6
        end
    structure_null_value(::AbstractMsg) = begin
            0xff
        end
    structure_min_value(::AbstractMsg) = begin
            0x00
        end
    structure_max_value(::AbstractMsg) = begin
            0xff
        end
    structure_id(::Type{<:AbstractMsg}) = begin
            UInt16(0x002a)
        end
    structure_since_version(::Type{<:AbstractMsg}) = begin
            UInt16(0)
        end
    structure_encoding_offset(::Type{<:AbstractMsg}) = begin
            0
        end
    structure_encoding_length(::Type{<:AbstractMsg}) = begin
            6
        end
    structure_null_value(::Type{<:AbstractMsg}) = begin
            0xff
        end
    structure_min_value(::Type{<:AbstractMsg}) = begin
            0x00
        end
    structure_max_value(::Type{<:AbstractMsg}) = begin
            0xff
        end
    function structure_meta_attribute(::AbstractMsg, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function structure_meta_attribute(::Type{<:AbstractMsg}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export structure_id, structure_since_version, structure_in_acting_version, structure_encoding_offset, structure_encoding_length
    export structure_null_value, structure_min_value, structure_max_value, structure_meta_attribute
    @inline function structure(m::Decoder)
            return Outer.Decoder(m.buffer, m.offset + 0, m.acting_version)
        end
    @inline function structure(m::Encoder)
            return Outer.Encoder(m.buffer, m.offset + 0)
        end
    export structure
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractMsg) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_id(::AbstractMsg) = begin
            UInt16(0x0003)
        end
    SBE.sbe_schema_version(::AbstractMsg) = begin
            UInt16(0x0000)
        end
    SBE.sbe_block_length(::AbstractMsg) = begin
            UInt16(6)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractMsg) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractMsg) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractMsg) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractMsg) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractMsg, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
export EnumOne, SetOne, Inner, MessageHeader, Outer, Msg
end