module OrderCheck
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
@enumx T = SbeEnum Direction::Int8 begin
        BUY = Int8(1)
        SELL = Int8(2)
        NULL_VALUE = Int8(-128)
    end
module Flags
using SBE: AbstractSbeEncodedType
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractFlags <: AbstractSbeEncodedType end
struct Decoder{T <: AbstractVector{UInt8}} <: AbstractFlags
    buffer::T
    offset::Int
    acting_version::UInt16
end
struct Encoder{T <: AbstractVector{UInt8}} <: AbstractFlags
    buffer::T
    offset::Int
end
@inline function Decoder(buffer::AbstractVector{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0003))
    end
@inline function Decoder(buffer::AbstractVector{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0003))
    end
@inline function Encoder(buffer::AbstractVector{UInt8})
        Encoder(buffer, Int64(0))
    end
id(::Type{<:AbstractFlags}) = begin
        UInt16(0xffff)
    end
id(::AbstractFlags) = begin
        UInt16(0xffff)
    end
since_version(::Type{<:AbstractFlags}) = begin
        UInt16(0)
    end
since_version(::AbstractFlags) = begin
        UInt16(0)
    end
encoding_offset(::Type{<:AbstractFlags}) = begin
        0
    end
encoding_offset(::AbstractFlags) = begin
        0
    end
encoding_length(::Type{<:AbstractFlags}) = begin
        1
    end
encoding_length(::AbstractFlags) = begin
        1
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0003)
    end
Base.eltype(::Type{<:AbstractFlags}) = begin
        UInt8
    end
Base.eltype(::AbstractFlags) = begin
        UInt8
    end
@inline function clear!(set::Encoder)
        encode_value(UInt8, set.buffer, set.offset, zero(UInt8))
        return set
    end
@inline function is_empty(set::AbstractFlags)
        return decode_value(UInt8, set.buffer, set.offset) == zero(UInt8)
    end
@inline function raw_value(set::AbstractFlags)
        return decode_value(UInt8, set.buffer, set.offset)
    end
begin
    @inline function guacamole(set::AbstractFlags)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 1 != 0
        end
end
begin
    @inline function guacamole!(set::Encoder, value::Bool)
            bits = decode_value(UInt8, set.buffer, set.offset)
            bits = if value
                    bits | UInt8(0x01) << 1
                else
                    bits & ~(UInt8(0x01) << 1)
                end
            encode_value(UInt8, set.buffer, set.offset, bits)
            return set
        end
end
export guacamole, guacamole!
begin
    @inline function cheese(set::AbstractFlags)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 2 != 0
        end
end
begin
    @inline function cheese!(set::Encoder, value::Bool)
            bits = decode_value(UInt8, set.buffer, set.offset)
            bits = if value
                    bits | UInt8(0x01) << 2
                else
                    bits & ~(UInt8(0x01) << 2)
                end
            encode_value(UInt8, set.buffer, set.offset, bits)
            return set
        end
end
export cheese, cheese!
begin
    @inline function sourCream(set::AbstractFlags)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 4 != 0
        end
end
begin
    @inline function sourCream!(set::Encoder, value::Bool)
            bits = decode_value(UInt8, set.buffer, set.offset)
            bits = if value
                    bits | UInt8(0x01) << 4
                else
                    bits & ~(UInt8(0x01) << 4)
                end
            encode_value(UInt8, set.buffer, set.offset, bits)
            return set
        end
end
export sourCream, sourCream!
export AbstractFlags, Decoder, Encoder
export clear!, is_empty, raw_value
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
        Decoder(buffer, Int64(0), UInt16(0x0003))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0003))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractMessageHeader) = begin
        UInt16(10)
    end
sbe_encoded_length(::Type{<:AbstractMessageHeader}) = begin
        UInt16(10)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0003)
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
begin
    numGroups_id(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    numGroups_id(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    numGroups_since_version(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    numGroups_since_version(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    numGroups_in_acting_version(m::AbstractMessageHeader) = begin
            m.acting_version >= UInt16(0)
        end
    numGroups_encoding_offset(::AbstractMessageHeader) = begin
            Int(8)
        end
    numGroups_encoding_offset(::Type{<:AbstractMessageHeader}) = begin
            Int(8)
        end
    numGroups_encoding_length(::AbstractMessageHeader) = begin
            Int(2)
        end
    numGroups_encoding_length(::Type{<:AbstractMessageHeader}) = begin
            Int(2)
        end
    numGroups_null_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    numGroups_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
    numGroups_min_value(::AbstractMessageHeader) = begin
            UInt16(0x0000)
        end
    numGroups_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0x0000)
        end
    numGroups_max_value(::AbstractMessageHeader) = begin
            UInt16(0xffff)
        end
    numGroups_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function numGroups(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 8)
        end
    @inline numGroups!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 8, val)
            end
    export numGroups, numGroups!
end
export AbstractMessageHeader, Decoder, Encoder
end
module GroupSizeEncoding
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
abstract type AbstractGroupSizeEncoding <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractGroupSizeEncoding
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractGroupSizeEncoding
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0003))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0003))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractGroupSizeEncoding) = begin
        UInt16(2)
    end
sbe_encoded_length(::Type{<:AbstractGroupSizeEncoding}) = begin
        UInt16(2)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0003)
    end
Base.sizeof(m::AbstractGroupSizeEncoding) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractGroupSizeEncoding)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractGroupSizeEncoding)
    print(io, "GroupSizeEncoding", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    blockLength_id(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    blockLength_id(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0xffff)
        end
    blockLength_since_version(::AbstractGroupSizeEncoding) = begin
            UInt16(0)
        end
    blockLength_since_version(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0)
        end
    blockLength_in_acting_version(m::AbstractGroupSizeEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    blockLength_encoding_offset(::AbstractGroupSizeEncoding) = begin
            Int(0)
        end
    blockLength_encoding_offset(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(0)
        end
    blockLength_encoding_length(::AbstractGroupSizeEncoding) = begin
            Int(1)
        end
    blockLength_encoding_length(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(1)
        end
    blockLength_null_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0xff)
        end
    blockLength_null_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0xff)
        end
    blockLength_min_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0x00)
        end
    blockLength_min_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0x00)
        end
    blockLength_max_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0xff)
        end
    blockLength_max_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function blockLength(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline blockLength!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, val)
            end
    export blockLength, blockLength!
end
begin
    numInGroup_id(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    numInGroup_id(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0xffff)
        end
    numInGroup_since_version(::AbstractGroupSizeEncoding) = begin
            UInt16(0)
        end
    numInGroup_since_version(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0)
        end
    numInGroup_in_acting_version(m::AbstractGroupSizeEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    numInGroup_encoding_offset(::AbstractGroupSizeEncoding) = begin
            Int(1)
        end
    numInGroup_encoding_offset(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(1)
        end
    numInGroup_encoding_length(::AbstractGroupSizeEncoding) = begin
            Int(1)
        end
    numInGroup_encoding_length(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(1)
        end
    numInGroup_null_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0xff)
        end
    numInGroup_null_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0xff)
        end
    numInGroup_min_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0x00)
        end
    numInGroup_min_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0x00)
        end
    numInGroup_max_value(::AbstractGroupSizeEncoding) = begin
            UInt8(0xff)
        end
    numInGroup_max_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function numInGroup(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 1)
        end
    @inline numInGroup!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 1, val)
            end
    export numInGroup, numInGroup!
end
export AbstractGroupSizeEncoding, Decoder, Encoder
end
module VarDataEncoding
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
abstract type AbstractVarDataEncoding <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractVarDataEncoding
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractVarDataEncoding
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0003))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0003))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractVarDataEncoding) = begin
        UInt16(2)
    end
sbe_encoded_length(::Type{<:AbstractVarDataEncoding}) = begin
        UInt16(2)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0003)
    end
Base.sizeof(m::AbstractVarDataEncoding) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractVarDataEncoding)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractVarDataEncoding)
    print(io, "VarDataEncoding", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    length_id(::AbstractVarDataEncoding) = begin
            UInt16(0xffff)
        end
    length_id(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(0xffff)
        end
    length_since_version(::AbstractVarDataEncoding) = begin
            UInt16(0)
        end
    length_since_version(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(0)
        end
    length_in_acting_version(m::AbstractVarDataEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    length_encoding_offset(::AbstractVarDataEncoding) = begin
            Int(0)
        end
    length_encoding_offset(::Type{<:AbstractVarDataEncoding}) = begin
            Int(0)
        end
    length_encoding_length(::AbstractVarDataEncoding) = begin
            Int(1)
        end
    length_encoding_length(::Type{<:AbstractVarDataEncoding}) = begin
            Int(1)
        end
    length_null_value(::AbstractVarDataEncoding) = begin
            UInt8(0xff)
        end
    length_null_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0xff)
        end
    length_min_value(::AbstractVarDataEncoding) = begin
            UInt8(0x00)
        end
    length_min_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0x00)
        end
    length_max_value(::AbstractVarDataEncoding) = begin
            UInt8(0xff)
        end
    length_max_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function length(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline length!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, val)
            end
    export length, length!
end
begin
    varData_id(::AbstractVarDataEncoding) = begin
            UInt16(0xffff)
        end
    varData_id(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(0xffff)
        end
    varData_since_version(::AbstractVarDataEncoding) = begin
            UInt16(0)
        end
    varData_since_version(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(0)
        end
    varData_in_acting_version(m::AbstractVarDataEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    varData_encoding_offset(::AbstractVarDataEncoding) = begin
            Int(1)
        end
    varData_encoding_offset(::Type{<:AbstractVarDataEncoding}) = begin
            Int(1)
        end
    varData_encoding_length(::AbstractVarDataEncoding) = begin
            Int(1)
        end
    varData_encoding_length(::Type{<:AbstractVarDataEncoding}) = begin
            Int(1)
        end
    varData_null_value(::AbstractVarDataEncoding) = begin
            UInt8(0xff)
        end
    varData_null_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0xff)
        end
    varData_min_value(::AbstractVarDataEncoding) = begin
            UInt8(0x00)
        end
    varData_min_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0x00)
        end
    varData_max_value(::AbstractVarDataEncoding) = begin
            UInt8(0xff)
        end
    varData_max_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function varData(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 1)
        end
    @inline varData!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 1, val)
            end
    export varData, varData!
end
export AbstractVarDataEncoding, Decoder, Encoder
end
module Point
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
abstract type AbstractPoint <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractPoint
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractPoint
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0003))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0003))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractPoint) = begin
        UInt16(8)
    end
sbe_encoded_length(::Type{<:AbstractPoint}) = begin
        UInt16(8)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0003)
    end
Base.sizeof(m::AbstractPoint) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractPoint)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractPoint)
    print(io, "Point", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    x_id(::AbstractPoint) = begin
            UInt16(0xffff)
        end
    x_id(::Type{<:AbstractPoint}) = begin
            UInt16(0xffff)
        end
    x_since_version(::AbstractPoint) = begin
            UInt16(0)
        end
    x_since_version(::Type{<:AbstractPoint}) = begin
            UInt16(0)
        end
    x_in_acting_version(m::AbstractPoint) = begin
            m.acting_version >= UInt16(0)
        end
    x_encoding_offset(::AbstractPoint) = begin
            Int(0)
        end
    x_encoding_offset(::Type{<:AbstractPoint}) = begin
            Int(0)
        end
    x_encoding_length(::AbstractPoint) = begin
            Int(4)
        end
    x_encoding_length(::Type{<:AbstractPoint}) = begin
            Int(4)
        end
    x_null_value(::AbstractPoint) = begin
            Int32(-2147483648)
        end
    x_null_value(::Type{<:AbstractPoint}) = begin
            Int32(-2147483648)
        end
    x_min_value(::AbstractPoint) = begin
            Int32(-2147483648)
        end
    x_min_value(::Type{<:AbstractPoint}) = begin
            Int32(-2147483648)
        end
    x_max_value(::AbstractPoint) = begin
            Int32(2147483647)
        end
    x_max_value(::Type{<:AbstractPoint}) = begin
            Int32(2147483647)
        end
end
begin
    @inline function x(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline x!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 0, val)
            end
    export x, x!
end
begin
    y_id(::AbstractPoint) = begin
            UInt16(0xffff)
        end
    y_id(::Type{<:AbstractPoint}) = begin
            UInt16(0xffff)
        end
    y_since_version(::AbstractPoint) = begin
            UInt16(0)
        end
    y_since_version(::Type{<:AbstractPoint}) = begin
            UInt16(0)
        end
    y_in_acting_version(m::AbstractPoint) = begin
            m.acting_version >= UInt16(0)
        end
    y_encoding_offset(::AbstractPoint) = begin
            Int(4)
        end
    y_encoding_offset(::Type{<:AbstractPoint}) = begin
            Int(4)
        end
    y_encoding_length(::AbstractPoint) = begin
            Int(4)
        end
    y_encoding_length(::Type{<:AbstractPoint}) = begin
            Int(4)
        end
    y_null_value(::AbstractPoint) = begin
            Int32(-2147483648)
        end
    y_null_value(::Type{<:AbstractPoint}) = begin
            Int32(-2147483648)
        end
    y_min_value(::AbstractPoint) = begin
            Int32(-2147483648)
        end
    y_min_value(::Type{<:AbstractPoint}) = begin
            Int32(-2147483648)
        end
    y_max_value(::AbstractPoint) = begin
            Int32(2147483647)
        end
    y_max_value(::Type{<:AbstractPoint}) = begin
            Int32(2147483647)
        end
end
begin
    @inline function y(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline y!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 4, val)
            end
    export y, y!
end
export AbstractPoint, Decoder, Encoder
end
module MultipleVarLength
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractMultipleVarLength{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractMultipleVarLength{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractMultipleVarLength{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0001) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0001))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractMultipleVarLength) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractMultipleVarLength) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractMultipleVarLength) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractMultipleVarLength) = begin
            0
        end
    a_encoding_length(::AbstractMultipleVarLength) = begin
            4
        end
    a_null_value(::AbstractMultipleVarLength) = begin
            2147483647
        end
    a_min_value(::AbstractMultipleVarLength) = begin
            -2147483648
        end
    a_max_value(::AbstractMultipleVarLength) = begin
            2147483647
        end
    a_id(::Type{<:AbstractMultipleVarLength}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractMultipleVarLength}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractMultipleVarLength}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractMultipleVarLength}) = begin
            4
        end
    a_null_value(::Type{<:AbstractMultipleVarLength}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractMultipleVarLength}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractMultipleVarLength}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractMultipleVarLength, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractMultipleVarLength}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractMultipleVarLength) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_id(::AbstractMultipleVarLength) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractMultipleVarLength) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractMultipleVarLength) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractMultipleVarLength) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractMultipleVarLength) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractMultipleVarLength) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractMultipleVarLength) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractMultipleVarLength, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
begin
    @inline function c_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function c_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_c!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = c_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function c(m::Decoder)
            len = c_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function c(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, c(m))
        end
    @inline function c(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = c(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function c(m::Decoder, ::Type{Symbol})
            return Symbol(c(m, String))
        end
    @inline function c(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, c(m)))[]
        end
    @inline function c(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, c(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function c!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            c_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function c!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            c_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function c!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            c_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function c!(m::Encoder, src::Symbol)
            return c!(m, to_string(src))
        end
    @inline function c!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return c!(m, bytes)
        end
    @inline function c!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return c!(m, bytes)
        end
end
begin
    const c_id = UInt16(0x0003)
    const c_since_version = UInt16(0)
    const c_header_length = 2
end
begin
    export c, c!, c_length, c_length!, skip_c!
end
end
module GroupAndVarLength
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractGroupAndVarLength{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractGroupAndVarLength{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractGroupAndVarLength{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0002) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0002))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractGroupAndVarLength) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractGroupAndVarLength) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractGroupAndVarLength) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractGroupAndVarLength) = begin
            0
        end
    a_encoding_length(::AbstractGroupAndVarLength) = begin
            4
        end
    a_null_value(::AbstractGroupAndVarLength) = begin
            2147483647
        end
    a_min_value(::AbstractGroupAndVarLength) = begin
            -2147483648
        end
    a_max_value(::AbstractGroupAndVarLength) = begin
            2147483647
        end
    a_id(::Type{<:AbstractGroupAndVarLength}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractGroupAndVarLength}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractGroupAndVarLength}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractGroupAndVarLength}) = begin
            4
        end
    a_null_value(::Type{<:AbstractGroupAndVarLength}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractGroupAndVarLength}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractGroupAndVarLength}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractGroupAndVarLength, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractGroupAndVarLength}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractGroupAndVarLength) = begin
            UInt16(0x0002)
        end
    SBE.sbe_schema_id(::AbstractGroupAndVarLength) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractGroupAndVarLength) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractGroupAndVarLength) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractGroupAndVarLength) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractGroupAndVarLength) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractGroupAndVarLength) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractGroupAndVarLength) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractGroupAndVarLength, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractGroupAndVarLength) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractGroupAndVarLength) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
begin
    @inline function d_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function d_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_d!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function d(m::Decoder)
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function d(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, d(m))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = d(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function d(m::Decoder, ::Type{Symbol})
            return Symbol(d(m, String))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, d(m)))[]
        end
    @inline function d(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, d(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function d!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::Symbol)
            return d!(m, to_string(src))
        end
    @inline function d!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return d!(m, bytes)
        end
    @inline function d!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return d!(m, bytes)
        end
end
begin
    const d_id = UInt16(0x0004)
    const d_since_version = UInt16(0)
    const d_header_length = 2
end
begin
    export d, d!, d_length, d_length!, skip_d!
end
end
module VarLengthInsideGroup
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractVarLengthInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractVarLengthInsideGroup{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractVarLengthInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0003) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0003))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractVarLengthInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractVarLengthInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractVarLengthInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractVarLengthInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractVarLengthInsideGroup) = begin
            4
        end
    a_null_value(::AbstractVarLengthInsideGroup) = begin
            2147483647
        end
    a_min_value(::AbstractVarLengthInsideGroup) = begin
            -2147483648
        end
    a_max_value(::AbstractVarLengthInsideGroup) = begin
            2147483647
        end
    a_id(::Type{<:AbstractVarLengthInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractVarLengthInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractVarLengthInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractVarLengthInsideGroup}) = begin
            4
        end
    a_null_value(::Type{<:AbstractVarLengthInsideGroup}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractVarLengthInsideGroup}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractVarLengthInsideGroup}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractVarLengthInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractVarLengthInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractVarLengthInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_schema_id(::AbstractVarLengthInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractVarLengthInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractVarLengthInsideGroup) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractVarLengthInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractVarLengthInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractVarLengthInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractVarLengthInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractVarLengthInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
begin
    @inline function d_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function d_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_d!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function d(m::Decoder)
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function d(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, d(m))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = d(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function d(m::Decoder, ::Type{Symbol})
            return Symbol(d(m, String))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, d(m)))[]
        end
    @inline function d(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, d(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function d!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::Symbol)
            return d!(m, to_string(src))
        end
    @inline function d!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return d!(m, bytes)
        end
    @inline function d!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return d!(m, bytes)
        end
end
begin
    const d_id = UInt16(0x0004)
    const d_since_version = UInt16(0)
    const d_header_length = 2
end
begin
    export d, d!, d_length, d_length!, skip_d!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractVarLengthInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractVarLengthInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
begin
    @inline function e_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function e_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_e!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = e_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function e(m::Decoder)
            len = e_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function e(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, e(m))
        end
    @inline function e(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = e(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function e(m::Decoder, ::Type{Symbol})
            return Symbol(e(m, String))
        end
    @inline function e(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, e(m)))[]
        end
    @inline function e(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, e(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function e!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            e_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function e!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            e_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function e!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            e_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function e!(m::Encoder, src::Symbol)
            return e!(m, to_string(src))
        end
    @inline function e!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return e!(m, bytes)
        end
    @inline function e!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return e!(m, bytes)
        end
end
begin
    const e_id = UInt16(0x0005)
    const e_since_version = UInt16(0)
    const e_header_length = 2
end
begin
    export e, e!, e_length, e_length!, skip_e!
end
end
module NestedGroups
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractNestedGroups{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractNestedGroups{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractNestedGroups{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0004) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0004))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractNestedGroups) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractNestedGroups) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractNestedGroups) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractNestedGroups) = begin
            0
        end
    a_encoding_length(::AbstractNestedGroups) = begin
            4
        end
    a_null_value(::AbstractNestedGroups) = begin
            2147483647
        end
    a_min_value(::AbstractNestedGroups) = begin
            -2147483648
        end
    a_max_value(::AbstractNestedGroups) = begin
            2147483647
        end
    a_id(::Type{<:AbstractNestedGroups}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractNestedGroups}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractNestedGroups}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractNestedGroups}) = begin
            4
        end
    a_null_value(::Type{<:AbstractNestedGroups}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractNestedGroups}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractNestedGroups}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractNestedGroups, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractNestedGroups}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractNestedGroups) = begin
            UInt16(0x0004)
        end
    SBE.sbe_schema_id(::AbstractNestedGroups) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractNestedGroups) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractNestedGroups) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractNestedGroups) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractNestedGroups) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractNestedGroups) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractNestedGroups) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractNestedGroups, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
module D
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractD{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractD) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    e_id(::AbstractD) = begin
            UInt16(0x0005)
        end
    e_since_version(::AbstractD) = begin
            UInt16(0)
        end
    e_in_acting_version(m::AbstractD) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    e_encoding_offset(::AbstractD) = begin
            0
        end
    e_encoding_length(::AbstractD) = begin
            4
        end
    e_null_value(::AbstractD) = begin
            2147483647
        end
    e_min_value(::AbstractD) = begin
            -2147483648
        end
    e_max_value(::AbstractD) = begin
            2147483647
        end
    e_id(::Type{<:AbstractD}) = begin
            UInt16(0x0005)
        end
    e_since_version(::Type{<:AbstractD}) = begin
            UInt16(0)
        end
    e_encoding_offset(::Type{<:AbstractD}) = begin
            0
        end
    e_encoding_length(::Type{<:AbstractD}) = begin
            4
        end
    e_null_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    e_min_value(::Type{<:AbstractD}) = begin
            -2147483648
        end
    e_max_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    function e_meta_attribute(::AbstractD, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function e_meta_attribute(::Type{<:AbstractD}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export e_id, e_since_version, e_in_acting_version, e_encoding_offset, e_encoding_length
    export e_null_value, e_min_value, e_max_value, e_meta_attribute
end
begin
    @inline function e(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline e!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export e, e!
end
end
@inline function d(m::Decoder)
        return D.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function d!(m::Encoder, count)
        return D.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
d_id(::AbstractB) = begin
        UInt16(0x0004)
    end
d_since_version(::AbstractB) = begin
        UInt16(0)
    end
d_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
d_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export d, d!, D
module F
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractF{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractF{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractF{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractF) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    g_id(::AbstractF) = begin
            UInt16(0x0007)
        end
    g_since_version(::AbstractF) = begin
            UInt16(0)
        end
    g_in_acting_version(m::AbstractF) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    g_encoding_offset(::AbstractF) = begin
            0
        end
    g_encoding_length(::AbstractF) = begin
            4
        end
    g_null_value(::AbstractF) = begin
            2147483647
        end
    g_min_value(::AbstractF) = begin
            -2147483648
        end
    g_max_value(::AbstractF) = begin
            2147483647
        end
    g_id(::Type{<:AbstractF}) = begin
            UInt16(0x0007)
        end
    g_since_version(::Type{<:AbstractF}) = begin
            UInt16(0)
        end
    g_encoding_offset(::Type{<:AbstractF}) = begin
            0
        end
    g_encoding_length(::Type{<:AbstractF}) = begin
            4
        end
    g_null_value(::Type{<:AbstractF}) = begin
            2147483647
        end
    g_min_value(::Type{<:AbstractF}) = begin
            -2147483648
        end
    g_max_value(::Type{<:AbstractF}) = begin
            2147483647
        end
    function g_meta_attribute(::AbstractF, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function g_meta_attribute(::Type{<:AbstractF}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export g_id, g_since_version, g_in_acting_version, g_encoding_offset, g_encoding_length
    export g_null_value, g_min_value, g_max_value, g_meta_attribute
end
begin
    @inline function g(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline g!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export g, g!
end
end
@inline function f(m::Decoder)
        return F.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function f!(m::Encoder, count)
        return F.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
f_id(::AbstractB) = begin
        UInt16(0x0006)
    end
f_since_version(::AbstractB) = begin
        UInt16(0)
    end
f_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
f_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export f, f!, F
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractNestedGroups) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractNestedGroups) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
module H
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractH{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractH{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractH{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractH) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    i_id(::AbstractH) = begin
            UInt16(0x0009)
        end
    i_since_version(::AbstractH) = begin
            UInt16(0)
        end
    i_in_acting_version(m::AbstractH) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    i_encoding_offset(::AbstractH) = begin
            0
        end
    i_encoding_length(::AbstractH) = begin
            4
        end
    i_null_value(::AbstractH) = begin
            2147483647
        end
    i_min_value(::AbstractH) = begin
            -2147483648
        end
    i_max_value(::AbstractH) = begin
            2147483647
        end
    i_id(::Type{<:AbstractH}) = begin
            UInt16(0x0009)
        end
    i_since_version(::Type{<:AbstractH}) = begin
            UInt16(0)
        end
    i_encoding_offset(::Type{<:AbstractH}) = begin
            0
        end
    i_encoding_length(::Type{<:AbstractH}) = begin
            4
        end
    i_null_value(::Type{<:AbstractH}) = begin
            2147483647
        end
    i_min_value(::Type{<:AbstractH}) = begin
            -2147483648
        end
    i_max_value(::Type{<:AbstractH}) = begin
            2147483647
        end
    function i_meta_attribute(::AbstractH, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function i_meta_attribute(::Type{<:AbstractH}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export i_id, i_since_version, i_in_acting_version, i_encoding_offset, i_encoding_length
    export i_null_value, i_min_value, i_max_value, i_meta_attribute
end
begin
    @inline function i(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline i!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export i, i!
end
end
@inline function h(m::Decoder)
        return H.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function h!(m::Encoder, count)
        return H.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
h_id(::AbstractNestedGroups) = begin
        UInt16(0x0008)
    end
h_since_version(::AbstractNestedGroups) = begin
        UInt16(0)
    end
h_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
h_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export h, h!, H
end
module CompositeInsideGroup
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
using ..Point
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractCompositeInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractCompositeInsideGroup{T}
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
        position_ptr[] = offset + UInt16(8)
        new{T}(buffer, offset, position_ptr, UInt16(8), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractCompositeInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 8
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0005) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(8))
        MessageHeader.templateId!(header, UInt16(0x0005))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractCompositeInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractCompositeInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractCompositeInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractCompositeInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractCompositeInsideGroup) = begin
            8
        end
    a_null_value(::AbstractCompositeInsideGroup) = begin
            0xff
        end
    a_min_value(::AbstractCompositeInsideGroup) = begin
            0x00
        end
    a_max_value(::AbstractCompositeInsideGroup) = begin
            0xff
        end
    a_id(::Type{<:AbstractCompositeInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractCompositeInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractCompositeInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractCompositeInsideGroup}) = begin
            8
        end
    a_null_value(::Type{<:AbstractCompositeInsideGroup}) = begin
            0xff
        end
    a_min_value(::Type{<:AbstractCompositeInsideGroup}) = begin
            0x00
        end
    a_max_value(::Type{<:AbstractCompositeInsideGroup}) = begin
            0xff
        end
    function a_meta_attribute(::AbstractCompositeInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractCompositeInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
    @inline function a(m::Decoder)
            return Point.Decoder(m.buffer, m.offset + 0, m.acting_version)
        end
    @inline function a(m::Encoder)
            return Point.Encoder(m.buffer, m.offset + 0)
        end
    export a
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractCompositeInsideGroup) = begin
            UInt16(0x0005)
        end
    SBE.sbe_schema_id(::AbstractCompositeInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractCompositeInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractCompositeInsideGroup) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractCompositeInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractCompositeInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractCompositeInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractCompositeInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractCompositeInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
using ..Point
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(8))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(8)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            8
        end
    c_null_value(::AbstractB) = begin
            0xff
        end
    c_min_value(::AbstractB) = begin
            0x00
        end
    c_max_value(::AbstractB) = begin
            0xff
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            8
        end
    c_null_value(::Type{<:AbstractB}) = begin
            0xff
        end
    c_min_value(::Type{<:AbstractB}) = begin
            0x00
        end
    c_max_value(::Type{<:AbstractB}) = begin
            0xff
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
    @inline function c(m::Decoder)
            return Point.Decoder(m.buffer, m.offset + 0, m.acting_version)
        end
    @inline function c(m::Encoder)
            return Point.Encoder(m.buffer, m.offset + 0)
        end
    export c
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractCompositeInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractCompositeInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddPrimitiveV0
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0006) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0006))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveV0) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveV0) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveV0) = begin
            UInt16(0x0006)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
module AddPrimitiveV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveV1{T}
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
        position_ptr[] = offset + UInt16(8)
        new{T}(buffer, offset, position_ptr, UInt16(8), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 8
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03ee) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(8))
        MessageHeader.templateId!(header, UInt16(0x03ee))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveV1) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveV1) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    b_id(::AbstractAddPrimitiveV1) = begin
            UInt16(0x0002)
        end
    b_since_version(::AbstractAddPrimitiveV1) = begin
            UInt16(1)
        end
    b_in_acting_version(m::AbstractAddPrimitiveV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    b_encoding_offset(::AbstractAddPrimitiveV1) = begin
            4
        end
    b_encoding_length(::AbstractAddPrimitiveV1) = begin
            4
        end
    b_null_value(::AbstractAddPrimitiveV1) = begin
            2147483647
        end
    b_min_value(::AbstractAddPrimitiveV1) = begin
            -2147483648
        end
    b_max_value(::AbstractAddPrimitiveV1) = begin
            2147483647
        end
    b_id(::Type{<:AbstractAddPrimitiveV1}) = begin
            UInt16(0x0002)
        end
    b_since_version(::Type{<:AbstractAddPrimitiveV1}) = begin
            UInt16(1)
        end
    b_encoding_offset(::Type{<:AbstractAddPrimitiveV1}) = begin
            4
        end
    b_encoding_length(::Type{<:AbstractAddPrimitiveV1}) = begin
            4
        end
    b_null_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            2147483647
        end
    b_min_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            -2147483648
        end
    b_max_value(::Type{<:AbstractAddPrimitiveV1}) = begin
            2147483647
        end
    function b_meta_attribute(::AbstractAddPrimitiveV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function b_meta_attribute(::Type{<:AbstractAddPrimitiveV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export b_id, b_since_version, b_in_acting_version, b_encoding_offset, b_encoding_length
    export b_null_value, b_min_value, b_max_value, b_meta_attribute
end
begin
    @inline function b(m::Decoder)
            if m.acting_version < UInt16(1)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline b!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 4, value)
            end
end
begin
    export b, b!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveV1) = begin
            UInt16(0x03ee)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveV1) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
module AddPrimitiveBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0007) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0007))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(0x0007)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddPrimitiveBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddPrimitiveBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddPrimitiveBeforeGroupV1
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(8)
        new{T}(buffer, offset, position_ptr, UInt16(8), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 8
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03ef) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(8))
        MessageHeader.templateId!(header, UInt16(0x03ef))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddPrimitiveBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddPrimitiveBeforeGroupV1) = begin
            4
        end
    d_null_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            2147483647
        end
    d_min_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            -2147483648
        end
    d_max_value(::AbstractAddPrimitiveBeforeGroupV1) = begin
            2147483647
        end
    d_id(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            4
        end
    d_null_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            2147483647
        end
    d_min_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            -2147483648
        end
    d_max_value(::Type{<:AbstractAddPrimitiveBeforeGroupV1}) = begin
            2147483647
        end
    function d_meta_attribute(::AbstractAddPrimitiveBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            if m.acting_version < UInt16(1)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 4, value)
            end
end
begin
    export d, d!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0x03ef)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveBeforeGroupV1) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddPrimitiveBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddPrimitiveBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddPrimitiveBeforeVarDataV0
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveBeforeVarDataV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeVarDataV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeVarDataV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0008) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0008))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveBeforeVarDataV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveBeforeVarDataV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeVarDataV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(0x0008)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveBeforeVarDataV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveBeforeVarDataV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveBeforeVarDataV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveBeforeVarDataV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveBeforeVarDataV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveBeforeVarDataV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module AddPrimitiveBeforeVarDataV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveBeforeVarDataV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeVarDataV1{T}
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
        position_ptr[] = offset + UInt16(8)
        new{T}(buffer, offset, position_ptr, UInt16(8), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveBeforeVarDataV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 8
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f0) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(8))
        MessageHeader.templateId!(header, UInt16(0x03f0))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveBeforeVarDataV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    c_id(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(1)
        end
    c_in_acting_version(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    c_encoding_offset(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            4
        end
    c_encoding_length(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            4
        end
    c_null_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            2147483647
        end
    c_min_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            -2147483648
        end
    c_max_value(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            2147483647
        end
    c_id(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            UInt16(1)
        end
    c_encoding_offset(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            4
        end
    c_encoding_length(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            4
        end
    c_null_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractAddPrimitiveBeforeVarDataV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractAddPrimitiveBeforeVarDataV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            if m.acting_version < UInt16(1)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 4, value)
            end
end
begin
    export c, c!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0x03f0)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveBeforeVarDataV1) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveBeforeVarDataV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveBeforeVarDataV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module AddPrimitiveInsideGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveInsideGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveInsideGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveInsideGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0009) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0009))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveInsideGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveInsideGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveInsideGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveInsideGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveInsideGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveInsideGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveInsideGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveInsideGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveInsideGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(0x0009)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveInsideGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveInsideGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveInsideGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveInsideGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveInsideGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveInsideGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddPrimitiveInsideGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddPrimitiveInsideGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddPrimitiveInsideGroupV1
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddPrimitiveInsideGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveInsideGroupV1{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddPrimitiveInsideGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f1) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x03f1))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddPrimitiveInsideGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddPrimitiveInsideGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddPrimitiveInsideGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddPrimitiveInsideGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddPrimitiveInsideGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddPrimitiveInsideGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddPrimitiveInsideGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddPrimitiveInsideGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddPrimitiveInsideGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(0x03f1)
        end
    SBE.sbe_schema_id(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddPrimitiveInsideGroupV1) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddPrimitiveInsideGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddPrimitiveInsideGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddPrimitiveInsideGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddPrimitiveInsideGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddPrimitiveInsideGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(8))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(8)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
begin
    d_id(::AbstractB) = begin
            UInt16(0x0004)
        end
    d_since_version(::AbstractB) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractB) = begin
            4
        end
    d_encoding_length(::AbstractB) = begin
            4
        end
    d_null_value(::AbstractB) = begin
            2147483647
        end
    d_min_value(::AbstractB) = begin
            -2147483648
        end
    d_max_value(::AbstractB) = begin
            2147483647
        end
    d_id(::Type{<:AbstractB}) = begin
            UInt16(0x0004)
        end
    d_since_version(::Type{<:AbstractB}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractB}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    d_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    d_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    d_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function d_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            if m.acting_version < UInt16(1)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 4, value)
            end
end
begin
    export d, d!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddPrimitiveInsideGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddPrimitiveInsideGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddGroupBeforeVarDataV0
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddGroupBeforeVarDataV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddGroupBeforeVarDataV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddGroupBeforeVarDataV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000a) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x000a))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddGroupBeforeVarDataV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddGroupBeforeVarDataV0) = begin
            0
        end
    a_encoding_length(::AbstractAddGroupBeforeVarDataV0) = begin
            4
        end
    a_null_value(::AbstractAddGroupBeforeVarDataV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddGroupBeforeVarDataV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddGroupBeforeVarDataV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddGroupBeforeVarDataV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddGroupBeforeVarDataV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddGroupBeforeVarDataV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(0x000a)
        end
    SBE.sbe_schema_id(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddGroupBeforeVarDataV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddGroupBeforeVarDataV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddGroupBeforeVarDataV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddGroupBeforeVarDataV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddGroupBeforeVarDataV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddGroupBeforeVarDataV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module AddGroupBeforeVarDataV1
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddGroupBeforeVarDataV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddGroupBeforeVarDataV1{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddGroupBeforeVarDataV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f2) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x03f2))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddGroupBeforeVarDataV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddGroupBeforeVarDataV1) = begin
            0
        end
    a_encoding_length(::AbstractAddGroupBeforeVarDataV1) = begin
            4
        end
    a_null_value(::AbstractAddGroupBeforeVarDataV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddGroupBeforeVarDataV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddGroupBeforeVarDataV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddGroupBeforeVarDataV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddGroupBeforeVarDataV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddGroupBeforeVarDataV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(0x03f2)
        end
    SBE.sbe_schema_id(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddGroupBeforeVarDataV1) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddGroupBeforeVarDataV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddGroupBeforeVarDataV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddGroupBeforeVarDataV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddGroupBeforeVarDataV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddGroupBeforeVarDataV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module C
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractC{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractC{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractC{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractC) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    d_id(::AbstractC) = begin
            UInt16(0x0004)
        end
    d_since_version(::AbstractC) = begin
            UInt16(0)
        end
    d_in_acting_version(m::AbstractC) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    d_encoding_offset(::AbstractC) = begin
            0
        end
    d_encoding_length(::AbstractC) = begin
            4
        end
    d_null_value(::AbstractC) = begin
            2147483647
        end
    d_min_value(::AbstractC) = begin
            -2147483648
        end
    d_max_value(::AbstractC) = begin
            2147483647
        end
    d_id(::Type{<:AbstractC}) = begin
            UInt16(0x0004)
        end
    d_since_version(::Type{<:AbstractC}) = begin
            UInt16(0)
        end
    d_encoding_offset(::Type{<:AbstractC}) = begin
            0
        end
    d_encoding_length(::Type{<:AbstractC}) = begin
            4
        end
    d_null_value(::Type{<:AbstractC}) = begin
            2147483647
        end
    d_min_value(::Type{<:AbstractC}) = begin
            -2147483648
        end
    d_max_value(::Type{<:AbstractC}) = begin
            2147483647
        end
    function d_meta_attribute(::AbstractC, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractC}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export d, d!
end
end
@inline function c(m::Decoder)
        if m.acting_version < UInt16(1)
            return C.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version, UInt16(0), UInt16(0))
        end
        return C.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function c!(m::Encoder, count)
        return C.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
c_id(::AbstractAddGroupBeforeVarDataV1) = begin
        UInt16(0x0003)
    end
c_since_version(::AbstractAddGroupBeforeVarDataV1) = begin
        UInt16(1)
    end
c_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(1)
    end
c_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(1)
    end
export c, c!, C
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module AddEnumBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddEnumBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddEnumBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddEnumBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000b) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x000b))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddEnumBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddEnumBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddEnumBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddEnumBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddEnumBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddEnumBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddEnumBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddEnumBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddEnumBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(0x000b)
        end
    SBE.sbe_schema_id(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddEnumBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddEnumBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddEnumBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddEnumBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddEnumBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddEnumBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddEnumBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddEnumBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddEnumBeforeGroupV1
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
using ..Direction
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddEnumBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddEnumBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(5)
        new{T}(buffer, offset, position_ptr, UInt16(5), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddEnumBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 5
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f3) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(5))
        MessageHeader.templateId!(header, UInt16(0x03f3))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddEnumBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddEnumBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddEnumBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddEnumBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddEnumBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddEnumBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddEnumBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddEnumBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddEnumBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddEnumBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddEnumBeforeGroupV1) = begin
            1
        end
    d_null_value(::AbstractAddEnumBeforeGroupV1) = begin
            127
        end
    d_min_value(::AbstractAddEnumBeforeGroupV1) = begin
            -128
        end
    d_max_value(::AbstractAddEnumBeforeGroupV1) = begin
            127
        end
    d_id(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            1
        end
    d_null_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            127
        end
    d_min_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            -128
        end
    d_max_value(::Type{<:AbstractAddEnumBeforeGroupV1}) = begin
            127
        end
    function d_meta_attribute(::AbstractAddEnumBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddEnumBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder, ::Type{Integer})
            if m.acting_version < UInt16(1)
                return -128
            end
            return decode_value(Int8, m.buffer, m.offset + 4)
        end
    @inline function d(m::Decoder)
            if m.acting_version < UInt16(1)
                return Direction.SbeEnum(-128)
            end
            raw = decode_value(Int8, m.buffer, m.offset + 4)
            return Direction.SbeEnum(raw)
        end
    @inline function d!(m::Encoder, value::Direction.SbeEnum)
            encode_value(Int8, m.buffer, m.offset + 4, Int8(value))
        end
    export d, d!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0x03f3)
        end
    SBE.sbe_schema_id(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddEnumBeforeGroupV1) = begin
            UInt16(5)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddEnumBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddEnumBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddEnumBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddEnumBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddEnumBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddEnumBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddEnumBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddCompositeBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddCompositeBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddCompositeBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddCompositeBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000c) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x000c))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddCompositeBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddCompositeBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddCompositeBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddCompositeBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddCompositeBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddCompositeBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddCompositeBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddCompositeBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddCompositeBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(0x000c)
        end
    SBE.sbe_schema_id(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddCompositeBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddCompositeBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddCompositeBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddCompositeBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddCompositeBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddCompositeBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddCompositeBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddCompositeBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddCompositeBeforeGroupV1
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
using ..Point
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddCompositeBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddCompositeBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(12)
        new{T}(buffer, offset, position_ptr, UInt16(12), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddCompositeBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 12
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f4) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(12))
        MessageHeader.templateId!(header, UInt16(0x03f4))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddCompositeBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddCompositeBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddCompositeBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddCompositeBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddCompositeBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddCompositeBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddCompositeBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddCompositeBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddCompositeBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddCompositeBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddCompositeBeforeGroupV1) = begin
            8
        end
    d_null_value(::AbstractAddCompositeBeforeGroupV1) = begin
            0xff
        end
    d_min_value(::AbstractAddCompositeBeforeGroupV1) = begin
            0x00
        end
    d_max_value(::AbstractAddCompositeBeforeGroupV1) = begin
            0xff
        end
    d_id(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            8
        end
    d_null_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            0xff
        end
    d_min_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            0x00
        end
    d_max_value(::Type{<:AbstractAddCompositeBeforeGroupV1}) = begin
            0xff
        end
    function d_meta_attribute(::AbstractAddCompositeBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddCompositeBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
    @inline function d(m::Decoder)
            return Point.Decoder(m.buffer, m.offset + 4, m.acting_version)
        end
    @inline function d(m::Encoder)
            return Point.Encoder(m.buffer, m.offset + 4)
        end
    export d
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0x03f4)
        end
    SBE.sbe_schema_id(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddCompositeBeforeGroupV1) = begin
            UInt16(12)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddCompositeBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddCompositeBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddCompositeBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddCompositeBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddCompositeBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddCompositeBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddCompositeBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddArrayBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddArrayBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddArrayBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddArrayBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000d) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x000d))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddArrayBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddArrayBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddArrayBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddArrayBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddArrayBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddArrayBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddArrayBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddArrayBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddArrayBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(0x000d)
        end
    SBE.sbe_schema_id(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddArrayBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddArrayBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddArrayBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddArrayBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddArrayBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddArrayBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddArrayBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddArrayBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddArrayBeforeGroupV1
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddArrayBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddArrayBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(8)
        new{T}(buffer, offset, position_ptr, UInt16(8), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddArrayBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 8
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f5) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(8))
        MessageHeader.templateId!(header, UInt16(0x03f5))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddArrayBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddArrayBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddArrayBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddArrayBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddArrayBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddArrayBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddArrayBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddArrayBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddArrayBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddArrayBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddArrayBeforeGroupV1) = begin
            1
        end
    d_null_value(::AbstractAddArrayBeforeGroupV1) = begin
            0xff
        end
    d_min_value(::AbstractAddArrayBeforeGroupV1) = begin
            0x00
        end
    d_max_value(::AbstractAddArrayBeforeGroupV1) = begin
            0xfe
        end
    d_id(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            1
        end
    d_null_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            0xff
        end
    d_min_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            0x00
        end
    d_max_value(::Type{<:AbstractAddArrayBeforeGroupV1}) = begin
            0xfe
        end
    function d_meta_attribute(::AbstractAddArrayBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddArrayBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            if m.acting_version < UInt16(1)
                return 0xff
            end
            return decode_value(UInt8, m.buffer, m.offset + 4)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 4, value)
            end
end
begin
    export d, d!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0x03f5)
        end
    SBE.sbe_schema_id(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddArrayBeforeGroupV1) = begin
            UInt16(8)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddArrayBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddArrayBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddArrayBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddArrayBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddArrayBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddArrayBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddArrayBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddBitSetBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddBitSetBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddBitSetBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddBitSetBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000e) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x000e))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddBitSetBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddBitSetBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddBitSetBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddBitSetBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddBitSetBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddBitSetBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddBitSetBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddBitSetBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddBitSetBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(0x000e)
        end
    SBE.sbe_schema_id(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddBitSetBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddBitSetBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddBitSetBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddBitSetBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddBitSetBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddBitSetBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddBitSetBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddBitSetBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddBitSetBeforeGroupV1
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
using ..GroupSizeEncoding
using ..Flags
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddBitSetBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddBitSetBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(5)
        new{T}(buffer, offset, position_ptr, UInt16(5), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddBitSetBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 5
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03f6) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(5))
        MessageHeader.templateId!(header, UInt16(0x03f6))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddBitSetBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddBitSetBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddBitSetBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddBitSetBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddBitSetBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddBitSetBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddBitSetBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddBitSetBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddBitSetBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddBitSetBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddBitSetBeforeGroupV1) = begin
            1
        end
    d_null_value(::AbstractAddBitSetBeforeGroupV1) = begin
            0xff
        end
    d_min_value(::AbstractAddBitSetBeforeGroupV1) = begin
            0x00
        end
    d_max_value(::AbstractAddBitSetBeforeGroupV1) = begin
            0xff
        end
    d_id(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            1
        end
    d_null_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            0xff
        end
    d_min_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            0x00
        end
    d_max_value(::Type{<:AbstractAddBitSetBeforeGroupV1}) = begin
            0xff
        end
    function d_meta_attribute(::AbstractAddBitSetBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddBitSetBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            return Flags.Decoder(m.buffer, m.offset + 4)
        end
    @inline function d(m::Encoder)
            return Flags.Encoder(m.buffer, m.offset + 4)
        end
    export d
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0x03f6)
        end
    SBE.sbe_schema_id(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddBitSetBeforeGroupV1) = begin
            UInt16(5)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddBitSetBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddBitSetBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddBitSetBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddBitSetBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddBitSetBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddBitSetBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddBitSetBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module EnumInsideGroup
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
using ..Direction
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractEnumInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractEnumInsideGroup{T}
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
        position_ptr[] = offset + UInt16(1)
        new{T}(buffer, offset, position_ptr, UInt16(1), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractEnumInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 1
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x000f) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(1))
        MessageHeader.templateId!(header, UInt16(0x000f))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractEnumInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractEnumInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractEnumInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractEnumInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractEnumInsideGroup) = begin
            1
        end
    a_null_value(::AbstractEnumInsideGroup) = begin
            127
        end
    a_min_value(::AbstractEnumInsideGroup) = begin
            -128
        end
    a_max_value(::AbstractEnumInsideGroup) = begin
            127
        end
    a_id(::Type{<:AbstractEnumInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractEnumInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractEnumInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractEnumInsideGroup}) = begin
            1
        end
    a_null_value(::Type{<:AbstractEnumInsideGroup}) = begin
            127
        end
    a_min_value(::Type{<:AbstractEnumInsideGroup}) = begin
            -128
        end
    a_max_value(::Type{<:AbstractEnumInsideGroup}) = begin
            127
        end
    function a_meta_attribute(::AbstractEnumInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractEnumInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder, ::Type{Integer})
            return decode_value(Int8, m.buffer, m.offset + 0)
        end
    @inline function a(m::Decoder)
            raw = decode_value(Int8, m.buffer, m.offset + 0)
            return Direction.SbeEnum(raw)
        end
    @inline function a!(m::Encoder, value::Direction.SbeEnum)
            encode_value(Int8, m.buffer, m.offset + 0, Int8(value))
        end
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractEnumInsideGroup) = begin
            UInt16(0x000f)
        end
    SBE.sbe_schema_id(::AbstractEnumInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractEnumInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractEnumInsideGroup) = begin
            UInt16(1)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractEnumInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractEnumInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractEnumInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractEnumInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractEnumInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
using ..Direction
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(1))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(1)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(1)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            1
        end
    c_null_value(::AbstractB) = begin
            127
        end
    c_min_value(::AbstractB) = begin
            -128
        end
    c_max_value(::AbstractB) = begin
            127
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            1
        end
    c_null_value(::Type{<:AbstractB}) = begin
            127
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -128
        end
    c_max_value(::Type{<:AbstractB}) = begin
            127
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder, ::Type{Integer})
            return decode_value(Int8, m.buffer, m.offset + 0)
        end
    @inline function c(m::Decoder)
            raw = decode_value(Int8, m.buffer, m.offset + 0)
            return Direction.SbeEnum(raw)
        end
    @inline function c!(m::Encoder, value::Direction.SbeEnum)
            encode_value(Int8, m.buffer, m.offset + 0, Int8(value))
        end
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractEnumInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractEnumInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module ArrayInsideGroup
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractArrayInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractArrayInsideGroup{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractArrayInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0010) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0010))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractArrayInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractArrayInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractArrayInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractArrayInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractArrayInsideGroup) = begin
            1
        end
    a_null_value(::AbstractArrayInsideGroup) = begin
            0xff
        end
    a_min_value(::AbstractArrayInsideGroup) = begin
            0x00
        end
    a_max_value(::AbstractArrayInsideGroup) = begin
            0xfe
        end
    a_id(::Type{<:AbstractArrayInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractArrayInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractArrayInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractArrayInsideGroup}) = begin
            1
        end
    a_null_value(::Type{<:AbstractArrayInsideGroup}) = begin
            0xff
        end
    a_min_value(::Type{<:AbstractArrayInsideGroup}) = begin
            0x00
        end
    a_max_value(::Type{<:AbstractArrayInsideGroup}) = begin
            0xfe
        end
    function a_meta_attribute(::AbstractArrayInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractArrayInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractArrayInsideGroup) = begin
            UInt16(0x0010)
        end
    SBE.sbe_schema_id(::AbstractArrayInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractArrayInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractArrayInsideGroup) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractArrayInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractArrayInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractArrayInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractArrayInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractArrayInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            1
        end
    c_null_value(::AbstractB) = begin
            0xff
        end
    c_min_value(::AbstractB) = begin
            0x00
        end
    c_max_value(::AbstractB) = begin
            0xfe
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            1
        end
    c_null_value(::Type{<:AbstractB}) = begin
            0xff
        end
    c_min_value(::Type{<:AbstractB}) = begin
            0x00
        end
    c_max_value(::Type{<:AbstractB}) = begin
            0xfe
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractArrayInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractArrayInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module BitSetInsideGroup
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
using ..GroupSizeEncoding
using ..Flags
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractBitSetInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractBitSetInsideGroup{T}
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
        position_ptr[] = offset + UInt16(1)
        new{T}(buffer, offset, position_ptr, UInt16(1), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractBitSetInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 1
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0011) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(1))
        MessageHeader.templateId!(header, UInt16(0x0011))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractBitSetInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractBitSetInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractBitSetInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractBitSetInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractBitSetInsideGroup) = begin
            1
        end
    a_null_value(::AbstractBitSetInsideGroup) = begin
            0xff
        end
    a_min_value(::AbstractBitSetInsideGroup) = begin
            0x00
        end
    a_max_value(::AbstractBitSetInsideGroup) = begin
            0xff
        end
    a_id(::Type{<:AbstractBitSetInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractBitSetInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractBitSetInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractBitSetInsideGroup}) = begin
            1
        end
    a_null_value(::Type{<:AbstractBitSetInsideGroup}) = begin
            0xff
        end
    a_min_value(::Type{<:AbstractBitSetInsideGroup}) = begin
            0x00
        end
    a_max_value(::Type{<:AbstractBitSetInsideGroup}) = begin
            0xff
        end
    function a_meta_attribute(::AbstractBitSetInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractBitSetInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return Flags.Decoder(m.buffer, m.offset + 0)
        end
    @inline function a(m::Encoder)
            return Flags.Encoder(m.buffer, m.offset + 0)
        end
    export a
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractBitSetInsideGroup) = begin
            UInt16(0x0011)
        end
    SBE.sbe_schema_id(::AbstractBitSetInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractBitSetInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractBitSetInsideGroup) = begin
            UInt16(1)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractBitSetInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractBitSetInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractBitSetInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractBitSetInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractBitSetInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
using ..Flags
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(1))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(1)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(1)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            1
        end
    c_null_value(::AbstractB) = begin
            0xff
        end
    c_min_value(::AbstractB) = begin
            0x00
        end
    c_max_value(::AbstractB) = begin
            0xff
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            1
        end
    c_null_value(::Type{<:AbstractB}) = begin
            0xff
        end
    c_min_value(::Type{<:AbstractB}) = begin
            0x00
        end
    c_max_value(::Type{<:AbstractB}) = begin
            0xff
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return Flags.Decoder(m.buffer, m.offset + 0)
        end
    @inline function c(m::Encoder)
            return Flags.Encoder(m.buffer, m.offset + 0)
        end
    export c
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractBitSetInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractBitSetInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module MultipleGroups
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractMultipleGroups{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractMultipleGroups{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractMultipleGroups{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0012) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0012))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractMultipleGroups) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractMultipleGroups) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractMultipleGroups) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractMultipleGroups) = begin
            0
        end
    a_encoding_length(::AbstractMultipleGroups) = begin
            4
        end
    a_null_value(::AbstractMultipleGroups) = begin
            2147483647
        end
    a_min_value(::AbstractMultipleGroups) = begin
            -2147483648
        end
    a_max_value(::AbstractMultipleGroups) = begin
            2147483647
        end
    a_id(::Type{<:AbstractMultipleGroups}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractMultipleGroups}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractMultipleGroups}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractMultipleGroups}) = begin
            4
        end
    a_null_value(::Type{<:AbstractMultipleGroups}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractMultipleGroups}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractMultipleGroups}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractMultipleGroups, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractMultipleGroups}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractMultipleGroups) = begin
            UInt16(0x0012)
        end
    SBE.sbe_schema_id(::AbstractMultipleGroups) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractMultipleGroups) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractMultipleGroups) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractMultipleGroups) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractMultipleGroups) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractMultipleGroups) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractMultipleGroups) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractMultipleGroups, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractMultipleGroups) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractMultipleGroups) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
module D
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractD{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractD) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    e_id(::AbstractD) = begin
            UInt16(0x0005)
        end
    e_since_version(::AbstractD) = begin
            UInt16(0)
        end
    e_in_acting_version(m::AbstractD) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    e_encoding_offset(::AbstractD) = begin
            0
        end
    e_encoding_length(::AbstractD) = begin
            4
        end
    e_null_value(::AbstractD) = begin
            2147483647
        end
    e_min_value(::AbstractD) = begin
            -2147483648
        end
    e_max_value(::AbstractD) = begin
            2147483647
        end
    e_id(::Type{<:AbstractD}) = begin
            UInt16(0x0005)
        end
    e_since_version(::Type{<:AbstractD}) = begin
            UInt16(0)
        end
    e_encoding_offset(::Type{<:AbstractD}) = begin
            0
        end
    e_encoding_length(::Type{<:AbstractD}) = begin
            4
        end
    e_null_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    e_min_value(::Type{<:AbstractD}) = begin
            -2147483648
        end
    e_max_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    function e_meta_attribute(::AbstractD, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function e_meta_attribute(::Type{<:AbstractD}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export e_id, e_since_version, e_in_acting_version, e_encoding_offset, e_encoding_length
    export e_null_value, e_min_value, e_max_value, e_meta_attribute
end
begin
    @inline function e(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline e!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export e, e!
end
end
@inline function d(m::Decoder)
        return D.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function d!(m::Encoder, count)
        return D.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
d_id(::AbstractMultipleGroups) = begin
        UInt16(0x0004)
    end
d_since_version(::AbstractMultipleGroups) = begin
        UInt16(0)
    end
d_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
d_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export d, d!, D
end
module AddVarDataV0
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddVarDataV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddVarDataV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddVarDataV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0013) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0013))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddVarDataV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddVarDataV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddVarDataV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddVarDataV0) = begin
            0
        end
    a_encoding_length(::AbstractAddVarDataV0) = begin
            4
        end
    a_null_value(::AbstractAddVarDataV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddVarDataV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddVarDataV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddVarDataV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddVarDataV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddVarDataV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddVarDataV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddVarDataV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddVarDataV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddVarDataV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddVarDataV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddVarDataV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddVarDataV0) = begin
            UInt16(0x0013)
        end
    SBE.sbe_schema_id(::AbstractAddVarDataV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddVarDataV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddVarDataV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddVarDataV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddVarDataV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddVarDataV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddVarDataV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddVarDataV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
module AddVarDataV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddVarDataV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddVarDataV1{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddVarDataV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03fb) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x03fb))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddVarDataV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddVarDataV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddVarDataV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddVarDataV1) = begin
            0
        end
    a_encoding_length(::AbstractAddVarDataV1) = begin
            4
        end
    a_null_value(::AbstractAddVarDataV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddVarDataV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddVarDataV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddVarDataV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddVarDataV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddVarDataV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddVarDataV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddVarDataV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddVarDataV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddVarDataV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddVarDataV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddVarDataV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddVarDataV1) = begin
            UInt16(0x03fb)
        end
    SBE.sbe_schema_id(::AbstractAddVarDataV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddVarDataV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddVarDataV1) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddVarDataV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddVarDataV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddVarDataV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddVarDataV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddVarDataV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(1)
                return (UInt8)(0)
            end
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(1)
                return 0
            end
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            if m.acting_version < UInt16(1)
                return ""
            end
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(1)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module AddAsciiBeforeGroupV0
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddAsciiBeforeGroupV0{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddAsciiBeforeGroupV0{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddAsciiBeforeGroupV0{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0014) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0014))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddAsciiBeforeGroupV0) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddAsciiBeforeGroupV0) = begin
            0
        end
    a_encoding_length(::AbstractAddAsciiBeforeGroupV0) = begin
            4
        end
    a_null_value(::AbstractAddAsciiBeforeGroupV0) = begin
            2147483647
        end
    a_min_value(::AbstractAddAsciiBeforeGroupV0) = begin
            -2147483648
        end
    a_max_value(::AbstractAddAsciiBeforeGroupV0) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddAsciiBeforeGroupV0}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddAsciiBeforeGroupV0, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddAsciiBeforeGroupV0}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(0x0014)
        end
    SBE.sbe_schema_id(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddAsciiBeforeGroupV0) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddAsciiBeforeGroupV0) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddAsciiBeforeGroupV0) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddAsciiBeforeGroupV0) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddAsciiBeforeGroupV0) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddAsciiBeforeGroupV0, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddAsciiBeforeGroupV0) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddAsciiBeforeGroupV0) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AddAsciiBeforeGroupV1
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAddAsciiBeforeGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAddAsciiBeforeGroupV1{T}
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
        position_ptr[] = offset + UInt16(10)
        new{T}(buffer, offset, position_ptr, UInt16(10), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAddAsciiBeforeGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 10
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x03fc) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(10))
        MessageHeader.templateId!(header, UInt16(0x03fc))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAddAsciiBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAddAsciiBeforeGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractAddAsciiBeforeGroupV1) = begin
            4
        end
    a_null_value(::AbstractAddAsciiBeforeGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractAddAsciiBeforeGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractAddAsciiBeforeGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractAddAsciiBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAddAsciiBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    d_id(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    d_since_version(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(1)
        end
    d_in_acting_version(m::AbstractAddAsciiBeforeGroupV1) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    d_encoding_offset(::AbstractAddAsciiBeforeGroupV1) = begin
            4
        end
    d_encoding_length(::AbstractAddAsciiBeforeGroupV1) = begin
            1
        end
    d_null_value(::AbstractAddAsciiBeforeGroupV1) = begin
            0xff
        end
    d_min_value(::AbstractAddAsciiBeforeGroupV1) = begin
            0x00
        end
    d_max_value(::AbstractAddAsciiBeforeGroupV1) = begin
            0xfe
        end
    d_id(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            UInt16(0x0003)
        end
    d_since_version(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            UInt16(1)
        end
    d_encoding_offset(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            4
        end
    d_encoding_length(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            1
        end
    d_null_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            0xff
        end
    d_min_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            0x00
        end
    d_max_value(::Type{<:AbstractAddAsciiBeforeGroupV1}) = begin
            0xfe
        end
    function d_meta_attribute(::AbstractAddAsciiBeforeGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractAddAsciiBeforeGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            if m.acting_version < UInt16(1)
                return 0xff
            end
            return decode_value(UInt8, m.buffer, m.offset + 4)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 4, value)
            end
end
begin
    export d, d!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0x03fc)
        end
    SBE.sbe_schema_id(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAddAsciiBeforeGroupV1) = begin
            UInt16(10)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAddAsciiBeforeGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAddAsciiBeforeGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAddAsciiBeforeGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAddAsciiBeforeGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAddAsciiBeforeGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAddAsciiBeforeGroupV1) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAddAsciiBeforeGroupV1) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module AsciiInsideGroup
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractAsciiInsideGroup{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAsciiInsideGroup{T}
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
        new{T}(buffer, offset, position_ptr, UInt16(6), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAsciiInsideGroup{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 6
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0015) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(6))
        MessageHeader.templateId!(header, UInt16(0x0015))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractAsciiInsideGroup) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractAsciiInsideGroup) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractAsciiInsideGroup) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractAsciiInsideGroup) = begin
            0
        end
    a_encoding_length(::AbstractAsciiInsideGroup) = begin
            1
        end
    a_null_value(::AbstractAsciiInsideGroup) = begin
            0xff
        end
    a_min_value(::AbstractAsciiInsideGroup) = begin
            0x00
        end
    a_max_value(::AbstractAsciiInsideGroup) = begin
            0xfe
        end
    a_id(::Type{<:AbstractAsciiInsideGroup}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractAsciiInsideGroup}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractAsciiInsideGroup}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractAsciiInsideGroup}) = begin
            1
        end
    a_null_value(::Type{<:AbstractAsciiInsideGroup}) = begin
            0xff
        end
    a_min_value(::Type{<:AbstractAsciiInsideGroup}) = begin
            0x00
        end
    a_max_value(::Type{<:AbstractAsciiInsideGroup}) = begin
            0xfe
        end
    function a_meta_attribute(::AbstractAsciiInsideGroup, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractAsciiInsideGroup}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractAsciiInsideGroup) = begin
            UInt16(0x0015)
        end
    SBE.sbe_schema_id(::AbstractAsciiInsideGroup) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractAsciiInsideGroup) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractAsciiInsideGroup) = begin
            UInt16(6)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractAsciiInsideGroup) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractAsciiInsideGroup) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractAsciiInsideGroup) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractAsciiInsideGroup) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractAsciiInsideGroup, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(6))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(6)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(6)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            1
        end
    c_null_value(::AbstractB) = begin
            0xff
        end
    c_min_value(::AbstractB) = begin
            0x00
        end
    c_max_value(::AbstractB) = begin
            0xfe
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            1
        end
    c_null_value(::Type{<:AbstractB}) = begin
            0xff
        end
    c_min_value(::Type{<:AbstractB}) = begin
            0x00
        end
    c_max_value(::Type{<:AbstractB}) = begin
            0xfe
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractAsciiInsideGroup) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractAsciiInsideGroup) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module NoBlock
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractNoBlock{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractNoBlock{T}
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
        position_ptr[] = offset + UInt16(0)
        new{T}(buffer, offset, position_ptr, UInt16(0), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractNoBlock{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 0
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0016) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(0))
        MessageHeader.templateId!(header, UInt16(0x0016))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    import SBE
    SBE.sbe_template_id(::AbstractNoBlock) = begin
            UInt16(0x0016)
        end
    SBE.sbe_schema_id(::AbstractNoBlock) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractNoBlock) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractNoBlock) = begin
            UInt16(0)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractNoBlock) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractNoBlock) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractNoBlock) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractNoBlock) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractNoBlock, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function a_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function a_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_a!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = a_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function a(m::Decoder)
            len = a_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function a(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, a(m))
        end
    @inline function a(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = a(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function a(m::Decoder, ::Type{Symbol})
            return Symbol(a(m, String))
        end
    @inline function a(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, a(m)))[]
        end
    @inline function a(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, a(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function a!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            a_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function a!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            a_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function a!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            a_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function a!(m::Encoder, src::Symbol)
            return a!(m, to_string(src))
        end
    @inline function a!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return a!(m, bytes)
        end
    @inline function a!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return a!(m, bytes)
        end
end
begin
    const a_id = UInt16(0x0001)
    const a_since_version = UInt16(0)
    const a_header_length = 2
end
begin
    export a, a!, a_length, a_length!, skip_a!
end
end
module GroupWithNoBlock
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractGroupWithNoBlock{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractGroupWithNoBlock{T}
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
        position_ptr[] = offset + UInt16(0)
        new{T}(buffer, offset, position_ptr, UInt16(0), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractGroupWithNoBlock{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 0
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0017) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(0))
        MessageHeader.templateId!(header, UInt16(0x0017))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    import SBE
    SBE.sbe_template_id(::AbstractGroupWithNoBlock) = begin
            UInt16(0x0017)
        end
    SBE.sbe_schema_id(::AbstractGroupWithNoBlock) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractGroupWithNoBlock) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractGroupWithNoBlock) = begin
            UInt16(0)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractGroupWithNoBlock) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractGroupWithNoBlock) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractGroupWithNoBlock) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractGroupWithNoBlock) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractGroupWithNoBlock, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module A
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractA{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractA{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractA{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(0))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractA) = begin
            UInt16(0)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(0)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
@inline function a(m::Decoder)
        return A.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function a!(m::Encoder, count)
        return A.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
a_id(::AbstractGroupWithNoBlock) = begin
        UInt16(0x0001)
    end
a_since_version(::AbstractGroupWithNoBlock) = begin
        UInt16(0)
    end
a_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
a_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export a, a!, A
end
module NestedGroupWithVarLength
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractNestedGroupWithVarLength{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractNestedGroupWithVarLength{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractNestedGroupWithVarLength{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0018) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0018))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractNestedGroupWithVarLength) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractNestedGroupWithVarLength) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractNestedGroupWithVarLength) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractNestedGroupWithVarLength) = begin
            0
        end
    a_encoding_length(::AbstractNestedGroupWithVarLength) = begin
            4
        end
    a_null_value(::AbstractNestedGroupWithVarLength) = begin
            2147483647
        end
    a_min_value(::AbstractNestedGroupWithVarLength) = begin
            -2147483648
        end
    a_max_value(::AbstractNestedGroupWithVarLength) = begin
            2147483647
        end
    a_id(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            4
        end
    a_null_value(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractNestedGroupWithVarLength}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractNestedGroupWithVarLength, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractNestedGroupWithVarLength}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractNestedGroupWithVarLength) = begin
            UInt16(0x0018)
        end
    SBE.sbe_schema_id(::AbstractNestedGroupWithVarLength) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractNestedGroupWithVarLength) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractNestedGroupWithVarLength) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractNestedGroupWithVarLength) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractNestedGroupWithVarLength) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractNestedGroupWithVarLength) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractNestedGroupWithVarLength) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractNestedGroupWithVarLength, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0003)
        end
    c_since_version(::AbstractB) = begin
            UInt16(0)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0003)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(0)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
module D
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractD{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractD{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractD) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    e_id(::AbstractD) = begin
            UInt16(0x0005)
        end
    e_since_version(::AbstractD) = begin
            UInt16(0)
        end
    e_in_acting_version(m::AbstractD) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    e_encoding_offset(::AbstractD) = begin
            0
        end
    e_encoding_length(::AbstractD) = begin
            4
        end
    e_null_value(::AbstractD) = begin
            2147483647
        end
    e_min_value(::AbstractD) = begin
            -2147483648
        end
    e_max_value(::AbstractD) = begin
            2147483647
        end
    e_id(::Type{<:AbstractD}) = begin
            UInt16(0x0005)
        end
    e_since_version(::Type{<:AbstractD}) = begin
            UInt16(0)
        end
    e_encoding_offset(::Type{<:AbstractD}) = begin
            0
        end
    e_encoding_length(::Type{<:AbstractD}) = begin
            4
        end
    e_null_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    e_min_value(::Type{<:AbstractD}) = begin
            -2147483648
        end
    e_max_value(::Type{<:AbstractD}) = begin
            2147483647
        end
    function e_meta_attribute(::AbstractD, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function e_meta_attribute(::Type{<:AbstractD}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export e_id, e_since_version, e_in_acting_version, e_encoding_offset, e_encoding_length
    export e_null_value, e_min_value, e_max_value, e_meta_attribute
end
begin
    @inline function e(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline e!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export e, e!
end
begin
    @inline function f_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function f_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_f!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = f_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function f(m::Decoder)
            len = f_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function f(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, f(m))
        end
    @inline function f(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = f(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function f(m::Decoder, ::Type{Symbol})
            return Symbol(f(m, String))
        end
    @inline function f(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, f(m)))[]
        end
    @inline function f(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, f(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function f!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            f_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function f!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            f_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function f!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            f_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function f!(m::Encoder, src::Symbol)
            return f!(m, to_string(src))
        end
    @inline function f!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return f!(m, bytes)
        end
    @inline function f!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return f!(m, bytes)
        end
end
begin
    const f_id = UInt16(0x0006)
    const f_since_version = UInt16(0)
    const f_header_length = 2
end
begin
    export f, f!, f_length, f_length!, skip_f!
end
end
@inline function d(m::Decoder)
        return D.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function d!(m::Encoder, count)
        return D.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
d_id(::AbstractB) = begin
        UInt16(0x0004)
    end
d_since_version(::AbstractB) = begin
        UInt16(0)
    end
d_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
d_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export d, d!, D
end
@inline function b(m::Decoder)
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractNestedGroupWithVarLength) = begin
        UInt16(0x0002)
    end
b_since_version(::AbstractNestedGroupWithVarLength) = begin
        UInt16(0)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(0)
    end
export b, b!, B
end
module SkipVersionAddPrimitiveV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddPrimitiveV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddPrimitiveV1{T}
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
        position_ptr[] = offset + UInt16(0)
        new{T}(buffer, offset, position_ptr, UInt16(0), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddPrimitiveV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 0
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0019) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(0))
        MessageHeader.templateId!(header, UInt16(0x0019))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddPrimitiveV1) = begin
            UInt16(0x0019)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddPrimitiveV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddPrimitiveV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddPrimitiveV1) = begin
            UInt16(0)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddPrimitiveV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddPrimitiveV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddPrimitiveV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddPrimitiveV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddPrimitiveV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0003)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module SkipVersionAddPrimitiveV2
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddPrimitiveV2{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddPrimitiveV2{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddPrimitiveV2{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0401) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0401))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(2)
        end
    a_in_acting_version(m::AbstractSkipVersionAddPrimitiveV2) = begin
            sbe_acting_version(m) >= UInt16(2)
        end
    a_encoding_offset(::AbstractSkipVersionAddPrimitiveV2) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddPrimitiveV2) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddPrimitiveV2) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddPrimitiveV2) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddPrimitiveV2) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            UInt16(2)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddPrimitiveV2}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddPrimitiveV2, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddPrimitiveV2}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            if m.acting_version < UInt16(2)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(0x0401)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddPrimitiveV2) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddPrimitiveV2) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddPrimitiveV2) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddPrimitiveV2) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddPrimitiveV2) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddPrimitiveV2, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0003)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module SkipVersionAddGroupV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddGroupV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupV1{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x001a) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x001a))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractSkipVersionAddGroupV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractSkipVersionAddGroupV1) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddGroupV1) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddGroupV1) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddGroupV1) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddGroupV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddGroupV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddGroupV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddGroupV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(0x001a)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddGroupV1) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddGroupV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddGroupV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddGroupV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddGroupV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddGroupV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function d_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function d_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_d!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function d(m::Decoder)
            len = d_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function d(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, d(m))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = d(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function d(m::Decoder, ::Type{Symbol})
            return Symbol(d(m, String))
        end
    @inline function d(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, d(m)))[]
        end
    @inline function d(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, d(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function d!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            d_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function d!(m::Encoder, src::Symbol)
            return d!(m, to_string(src))
        end
    @inline function d!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return d!(m, bytes)
        end
    @inline function d!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return d!(m, bytes)
        end
end
begin
    const d_id = UInt16(0x0002)
    const d_since_version = UInt16(0)
    const d_header_length = 2
end
begin
    export d, d!, d_length, d_length!, skip_d!
end
end
module SkipVersionAddGroupV2
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddGroupV2{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupV2{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupV2{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0402) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0402))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractSkipVersionAddGroupV2) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractSkipVersionAddGroupV2) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddGroupV2) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddGroupV2) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddGroupV2) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddGroupV2) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddGroupV2}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddGroupV2, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddGroupV2}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(0x0402)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddGroupV2) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddGroupV2) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddGroupV2) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddGroupV2) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddGroupV2) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddGroupV2, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module B
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractB{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractB{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractB) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    c_id(::AbstractB) = begin
            UInt16(0x0004)
        end
    c_since_version(::AbstractB) = begin
            UInt16(2)
        end
    c_in_acting_version(m::AbstractB) = begin
            sbe_acting_version(m) >= UInt16(2)
        end
    c_encoding_offset(::AbstractB) = begin
            0
        end
    c_encoding_length(::AbstractB) = begin
            4
        end
    c_null_value(::AbstractB) = begin
            2147483647
        end
    c_min_value(::AbstractB) = begin
            -2147483648
        end
    c_max_value(::AbstractB) = begin
            2147483647
        end
    c_id(::Type{<:AbstractB}) = begin
            UInt16(0x0004)
        end
    c_since_version(::Type{<:AbstractB}) = begin
            UInt16(2)
        end
    c_encoding_offset(::Type{<:AbstractB}) = begin
            0
        end
    c_encoding_length(::Type{<:AbstractB}) = begin
            4
        end
    c_null_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    c_min_value(::Type{<:AbstractB}) = begin
            -2147483648
        end
    c_max_value(::Type{<:AbstractB}) = begin
            2147483647
        end
    function c_meta_attribute(::AbstractB, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function c_meta_attribute(::Type{<:AbstractB}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export c_id, c_since_version, c_in_acting_version, c_encoding_offset, c_encoding_length
    export c_null_value, c_min_value, c_max_value, c_meta_attribute
end
begin
    @inline function c(m::Decoder)
            if m.acting_version < UInt16(2)
                return 2147483647
            end
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline c!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export c, c!
end
end
@inline function b(m::Decoder)
        if m.acting_version < UInt16(2)
            return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version, UInt16(0), UInt16(0))
        end
        return B.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function b!(m::Encoder, count)
        return B.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
b_id(::AbstractSkipVersionAddGroupV2) = begin
        UInt16(0x0003)
    end
b_since_version(::AbstractSkipVersionAddGroupV2) = begin
        UInt16(2)
    end
b_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(2)
    end
b_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(2)
    end
export b, b!, B
end
module SkipVersionAddVarDataV1
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddVarDataV1{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddVarDataV1{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddVarDataV1{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x001b) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x001b))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractSkipVersionAddVarDataV1) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractSkipVersionAddVarDataV1) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddVarDataV1) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddVarDataV1) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddVarDataV1) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddVarDataV1) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddVarDataV1}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddVarDataV1, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddVarDataV1}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(0x001b)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddVarDataV1) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddVarDataV1) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddVarDataV1) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddVarDataV1) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddVarDataV1) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddVarDataV1, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
module SkipVersionAddVarDataV2
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
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddVarDataV2{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddVarDataV2{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddVarDataV2{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0403) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0403))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractSkipVersionAddVarDataV2) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractSkipVersionAddVarDataV2) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddVarDataV2) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddVarDataV2) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddVarDataV2) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddVarDataV2) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddVarDataV2}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddVarDataV2, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddVarDataV2}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(0x0403)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddVarDataV2) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddVarDataV2) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddVarDataV2) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddVarDataV2) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddVarDataV2) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddVarDataV2, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(2)
                return (UInt8)(0)
            end
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(2)
                return 0
            end
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            if m.acting_version < UInt16(2)
                return ""
            end
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(2)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
module SkipVersionAddGroupBeforeVarDataV2
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
using ..GroupSizeEncoding
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractSkipVersionAddGroupBeforeVarDataV2{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupBeforeVarDataV2{T}
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
        position_ptr[] = offset + UInt16(4)
        new{T}(buffer, offset, position_ptr, UInt16(4), UInt16(0x0003))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSkipVersionAddGroupBeforeVarDataV2{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 4
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0404) || MessageHeader.schemaId(header) != UInt16(0x0001)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(4))
        MessageHeader.templateId!(header, UInt16(0x0404))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0003))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    a_id(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(0x0001)
        end
    a_since_version(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(0)
        end
    a_in_acting_version(m::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    a_encoding_offset(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            0
        end
    a_encoding_length(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            4
        end
    a_null_value(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            2147483647
        end
    a_min_value(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            -2147483648
        end
    a_max_value(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            2147483647
        end
    a_id(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            UInt16(0x0001)
        end
    a_since_version(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            UInt16(0)
        end
    a_encoding_offset(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            0
        end
    a_encoding_length(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            4
        end
    a_null_value(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            2147483647
        end
    a_min_value(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            -2147483648
        end
    a_max_value(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}) = begin
            2147483647
        end
    function a_meta_attribute(::AbstractSkipVersionAddGroupBeforeVarDataV2, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function a_meta_attribute(::Type{<:AbstractSkipVersionAddGroupBeforeVarDataV2}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export a_id, a_since_version, a_in_acting_version, a_encoding_offset, a_encoding_length
    export a_null_value, a_min_value, a_max_value, a_meta_attribute
end
begin
    @inline function a(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline a!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export a, a!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(0x0404)
        end
    SBE.sbe_schema_id(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(0x0003)
        end
    SBE.sbe_block_length(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractSkipVersionAddGroupBeforeVarDataV2, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module C
using SBE: PositionPointer
using SBE: AbstractSbeGroup
using SBE: AbstractSbeMessage
using SBE: to_string
using StringViews: StringView
using ..GroupSizeEncoding
import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
const encode_value = encode_value_le
const decode_value = decode_value_le
const encode_array = encode_array_le
const decode_array = decode_array_le
begin
    abstract type AbstractC{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractC{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const block_length::UInt16
        const acting_version::UInt16
        const count::UInt16
        index::UInt16
        function Decoder(buffer::T, offset::Integer, position_ptr::PositionPointer, block_length::Integer, acting_version::Integer, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length), UInt16(acting_version), UInt16(count), UInt16(index))
        end
    end
end
begin
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractC{T}
        const buffer::T
        offset::Int64
        const position_ptr::PositionPointer
        const initial_position::Int64
        count::UInt16
        index::UInt16
        function Encoder(buffer::T, offset::Integer, position_ptr::PositionPointer, initial_position::Int64, count::Integer, index::Integer) where T
            new{T}(buffer, Int64(offset), position_ptr, initial_position, UInt16(count), UInt16(index))
        end
    end
end
begin
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = GroupSizeEncoding.Decoder(buffer, position_ptr[])
            position_ptr[] += 2
            block_len = GroupSizeEncoding.blockLength(dimensions)
            num_in_group = GroupSizeEncoding.numInGroup(dimensions)
            return Decoder(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end
    @inline function Decoder(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return Decoder(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
end
begin
    @inline function Encoder(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = GroupSizeEncoding.Encoder(buffer, position_ptr[])
            GroupSizeEncoding.blockLength!(dimensions, UInt16(4))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 2
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractC) = begin
            UInt16(4)
        end
    SBE.sbe_acting_block_length(g::Decoder) = begin
            g.block_length
        end
    SBE.sbe_acting_block_length(::Encoder) = begin
            UInt16(4)
        end
    SBE.sbe_acting_version(g::Decoder) = begin
            g.acting_version
        end
    SBE.sbe_acting_version(::Encoder) = begin
            UInt16(0x0003)
        end
    Base.eltype(::Type{<:Decoder}) = begin
            Decoder
        end
    Base.eltype(::Type{<:Encoder}) = begin
            Encoder
        end
    export next!
end
using SBE: Base.iterate, Base.length, Base.isdone
begin
    function reset_count_to_index!(g::Encoder)
        g.count = g.index
        dimensions = GroupSizeEncoding.Encoder(g.buffer, g.initial_position)
        GroupSizeEncoding.numInGroup!(dimensions, g.count)
        return g.count
    end
    export reset_count_to_index!
end
begin
    d_id(::AbstractC) = begin
            UInt16(0x0004)
        end
    d_since_version(::AbstractC) = begin
            UInt16(0)
        end
    d_in_acting_version(m::AbstractC) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    d_encoding_offset(::AbstractC) = begin
            0
        end
    d_encoding_length(::AbstractC) = begin
            4
        end
    d_null_value(::AbstractC) = begin
            2147483647
        end
    d_min_value(::AbstractC) = begin
            -2147483648
        end
    d_max_value(::AbstractC) = begin
            2147483647
        end
    d_id(::Type{<:AbstractC}) = begin
            UInt16(0x0004)
        end
    d_since_version(::Type{<:AbstractC}) = begin
            UInt16(0)
        end
    d_encoding_offset(::Type{<:AbstractC}) = begin
            0
        end
    d_encoding_length(::Type{<:AbstractC}) = begin
            4
        end
    d_null_value(::Type{<:AbstractC}) = begin
            2147483647
        end
    d_min_value(::Type{<:AbstractC}) = begin
            -2147483648
        end
    d_max_value(::Type{<:AbstractC}) = begin
            2147483647
        end
    function d_meta_attribute(::AbstractC, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function d_meta_attribute(::Type{<:AbstractC}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export d_id, d_since_version, d_in_acting_version, d_encoding_offset, d_encoding_length
    export d_null_value, d_min_value, d_max_value, d_meta_attribute
end
begin
    @inline function d(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline d!(m::Encoder, value) = begin
                encode_value(Int32, m.buffer, m.offset + 0, value)
            end
end
begin
    export d, d!
end
end
@inline function c(m::Decoder)
        if m.acting_version < UInt16(2)
            return C.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version, UInt16(0), UInt16(0))
        end
        return C.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function c!(m::Encoder, count)
        return C.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
c_id(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
        UInt16(0x0003)
    end
c_since_version(::AbstractSkipVersionAddGroupBeforeVarDataV2) = begin
        UInt16(2)
    end
c_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(2)
    end
c_in_acting_version(m::Encoder) = begin
        UInt16(0x0003) >= UInt16(2)
    end
export c, c!, C
begin
    @inline function b_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt8, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function b_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt8, m.buffer, m.position_ptr[], convert(UInt8, n))
        end
end
begin
    @inline function skip_b!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function b(m::Decoder)
            len = b_length(m)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            bytes = view(m.buffer, pos + 1:pos + len)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
end
begin
    @inline function b(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, b(m))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = b(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function b(m::Decoder, ::Type{Symbol})
            return Symbol(b(m, String))
        end
    @inline function b(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, b(m)))[]
        end
    @inline function b(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, b(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function b!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            b_length!(m, len)
            pos = m.position_ptr[] + 2
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function b!(m::Encoder, src::Symbol)
            return b!(m, to_string(src))
        end
    @inline function b!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return b!(m, bytes)
        end
    @inline function b!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return b!(m, bytes)
        end
end
begin
    const b_id = UInt16(0x0002)
    const b_since_version = UInt16(0)
    const b_header_length = 2
end
begin
    export b, b!, b_length, b_length!, skip_b!
end
end
export Direction, Flags, MessageHeader, GroupSizeEncoding, VarDataEncoding, Point, MultipleVarLength, GroupAndVarLength, VarLengthInsideGroup, NestedGroups, CompositeInsideGroup, AddPrimitiveV0, AddPrimitiveV1, AddPrimitiveBeforeGroupV0, AddPrimitiveBeforeGroupV1, AddPrimitiveBeforeVarDataV0, AddPrimitiveBeforeVarDataV1, AddPrimitiveInsideGroupV0, AddPrimitiveInsideGroupV1, AddGroupBeforeVarDataV0, AddGroupBeforeVarDataV1, AddEnumBeforeGroupV0, AddEnumBeforeGroupV1, AddCompositeBeforeGroupV0, AddCompositeBeforeGroupV1, AddArrayBeforeGroupV0, AddArrayBeforeGroupV1, AddBitSetBeforeGroupV0, AddBitSetBeforeGroupV1, EnumInsideGroup, ArrayInsideGroup, BitSetInsideGroup, MultipleGroups, AddVarDataV0, AddVarDataV1, AddAsciiBeforeGroupV0, AddAsciiBeforeGroupV1, AsciiInsideGroup, NoBlock, GroupWithNoBlock, NestedGroupWithVarLength, SkipVersionAddPrimitiveV1, SkipVersionAddPrimitiveV2, SkipVersionAddGroupV1, SkipVersionAddGroupV2, SkipVersionAddVarDataV1, SkipVersionAddVarDataV2, SkipVersionAddGroupBeforeVarDataV2
end