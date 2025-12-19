module Versioned
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
@enumx T = SbeEnum Status::UInt8 begin
        PENDING = UInt8(0x00)
        ACTIVE = UInt8(0x01)
        COMPLETED = UInt8(0x02)
        NULL_VALUE = UInt8(0xff)
    end
module Features
using SBE: AbstractSbeEncodedType
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractFeatures <: AbstractSbeEncodedType end
struct Decoder{T <: AbstractVector{UInt8}} <: AbstractFeatures
    buffer::T
    offset::Int
    acting_version::UInt16
end
struct Encoder{T <: AbstractVector{UInt8}} <: AbstractFeatures
    buffer::T
    offset::Int
end
@inline function Decoder(buffer::AbstractVector{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0002))
    end
@inline function Decoder(buffer::AbstractVector{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0002))
    end
@inline function Encoder(buffer::AbstractVector{UInt8})
        Encoder(buffer, Int64(0))
    end
id(::Type{<:AbstractFeatures}) = begin
        UInt16(0xffff)
    end
id(::AbstractFeatures) = begin
        UInt16(0xffff)
    end
since_version(::Type{<:AbstractFeatures}) = begin
        UInt16(2)
    end
since_version(::AbstractFeatures) = begin
        UInt16(2)
    end
encoding_offset(::Type{<:AbstractFeatures}) = begin
        0
    end
encoding_offset(::AbstractFeatures) = begin
        0
    end
encoding_length(::Type{<:AbstractFeatures}) = begin
        2
    end
encoding_length(::AbstractFeatures) = begin
        2
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0002)
    end
Base.eltype(::Type{<:AbstractFeatures}) = begin
        UInt16
    end
Base.eltype(::AbstractFeatures) = begin
        UInt16
    end
@inline function clear!(set::Encoder)
        encode_value(UInt16, set.buffer, set.offset, zero(UInt16))
        return set
    end
@inline function is_empty(set::AbstractFeatures)
        return decode_value(UInt16, set.buffer, set.offset) == zero(UInt16)
    end
@inline function raw_value(set::AbstractFeatures)
        return decode_value(UInt16, set.buffer, set.offset)
    end
begin
    @inline function wifi(set::AbstractFeatures)
            return decode_value(UInt16, set.buffer, set.offset) & UInt16(0x01) << 0 != 0
        end
end
begin
    @inline function wifi!(set::Encoder, value::Bool)
            bits = decode_value(UInt16, set.buffer, set.offset)
            bits = if value
                    bits | UInt16(0x01) << 0
                else
                    bits & ~(UInt16(0x01) << 0)
                end
            encode_value(UInt16, set.buffer, set.offset, bits)
            return set
        end
end
export wifi, wifi!
begin
    @inline function bluetooth(set::AbstractFeatures)
            return decode_value(UInt16, set.buffer, set.offset) & UInt16(0x01) << 1 != 0
        end
end
begin
    @inline function bluetooth!(set::Encoder, value::Bool)
            bits = decode_value(UInt16, set.buffer, set.offset)
            bits = if value
                    bits | UInt16(0x01) << 1
                else
                    bits & ~(UInt16(0x01) << 1)
                end
            encode_value(UInt16, set.buffer, set.offset, bits)
            return set
        end
end
export bluetooth, bluetooth!
begin
    @inline function gps(set::AbstractFeatures)
            return decode_value(UInt16, set.buffer, set.offset) & UInt16(0x01) << 2 != 0
        end
end
begin
    @inline function gps!(set::Encoder, value::Bool)
            bits = decode_value(UInt16, set.buffer, set.offset)
            bits = if value
                    bits | UInt16(0x01) << 2
                else
                    bits & ~(UInt16(0x01) << 2)
                end
            encode_value(UInt16, set.buffer, set.offset, bits)
            return set
        end
end
export gps, gps!
export AbstractFeatures, Decoder, Encoder
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
        Decoder(buffer, Int64(0), UInt16(0x0002))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0002))
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
        UInt16(0x0002)
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
        Decoder(buffer, Int64(0), UInt16(0x0002))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0002))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractGroupSizeEncoding) = begin
        UInt16(4)
    end
sbe_encoded_length(::Type{<:AbstractGroupSizeEncoding}) = begin
        UInt16(4)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0002)
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
            Int(2)
        end
    blockLength_encoding_length(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(2)
        end
    blockLength_null_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    blockLength_null_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0xffff)
        end
    blockLength_min_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0x0000)
        end
    blockLength_min_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0x0000)
        end
    blockLength_max_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    blockLength_max_value(::Type{<:AbstractGroupSizeEncoding}) = begin
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
            Int(2)
        end
    numInGroup_encoding_offset(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(2)
        end
    numInGroup_encoding_length(::AbstractGroupSizeEncoding) = begin
            Int(2)
        end
    numInGroup_encoding_length(::Type{<:AbstractGroupSizeEncoding}) = begin
            Int(2)
        end
    numInGroup_null_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    numInGroup_null_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0xffff)
        end
    numInGroup_min_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0x0000)
        end
    numInGroup_min_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0x0000)
        end
    numInGroup_max_value(::AbstractGroupSizeEncoding) = begin
            UInt16(0xffff)
        end
    numInGroup_max_value(::Type{<:AbstractGroupSizeEncoding}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function numInGroup(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 2)
        end
    @inline numInGroup!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 2, val)
            end
    export numInGroup, numInGroup!
end
export AbstractGroupSizeEncoding, Decoder, Encoder
end
module VarStringEncoding
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
abstract type AbstractVarStringEncoding <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractVarStringEncoding
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractVarStringEncoding
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0002))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0002))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractVarStringEncoding) = begin
        UInt16(5)
    end
sbe_encoded_length(::Type{<:AbstractVarStringEncoding}) = begin
        UInt16(5)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0002)
    end
Base.sizeof(m::AbstractVarStringEncoding) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractVarStringEncoding)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractVarStringEncoding)
    print(io, "VarStringEncoding", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    length_id(::AbstractVarStringEncoding) = begin
            UInt16(0xffff)
        end
    length_id(::Type{<:AbstractVarStringEncoding}) = begin
            UInt16(0xffff)
        end
    length_since_version(::AbstractVarStringEncoding) = begin
            UInt16(0)
        end
    length_since_version(::Type{<:AbstractVarStringEncoding}) = begin
            UInt16(0)
        end
    length_in_acting_version(m::AbstractVarStringEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    length_encoding_offset(::AbstractVarStringEncoding) = begin
            Int(0)
        end
    length_encoding_offset(::Type{<:AbstractVarStringEncoding}) = begin
            Int(0)
        end
    length_encoding_length(::AbstractVarStringEncoding) = begin
            Int(4)
        end
    length_encoding_length(::Type{<:AbstractVarStringEncoding}) = begin
            Int(4)
        end
    length_null_value(::AbstractVarStringEncoding) = begin
            UInt32(0xffffffff)
        end
    length_null_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt32(0xffffffff)
        end
    length_min_value(::AbstractVarStringEncoding) = begin
            UInt32(0x00000000)
        end
    length_min_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt32(0x00000000)
        end
    length_max_value(::AbstractVarStringEncoding) = begin
            UInt32(0x40000000)
        end
    length_max_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt32(0x40000000)
        end
end
begin
    @inline function length(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 0)
        end
    @inline length!(m::Encoder, val) = begin
                encode_value(UInt32, m.buffer, m.offset + 0, val)
            end
    export length, length!
end
begin
    varData_id(::AbstractVarStringEncoding) = begin
            UInt16(0xffff)
        end
    varData_id(::Type{<:AbstractVarStringEncoding}) = begin
            UInt16(0xffff)
        end
    varData_since_version(::AbstractVarStringEncoding) = begin
            UInt16(0)
        end
    varData_since_version(::Type{<:AbstractVarStringEncoding}) = begin
            UInt16(0)
        end
    varData_in_acting_version(m::AbstractVarStringEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    varData_encoding_offset(::AbstractVarStringEncoding) = begin
            Int(4)
        end
    varData_encoding_offset(::Type{<:AbstractVarStringEncoding}) = begin
            Int(4)
        end
    varData_encoding_length(::AbstractVarStringEncoding) = begin
            Int(1)
        end
    varData_encoding_length(::Type{<:AbstractVarStringEncoding}) = begin
            Int(1)
        end
    varData_null_value(::AbstractVarStringEncoding) = begin
            UInt8(0xff)
        end
    varData_null_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt8(0xff)
        end
    varData_min_value(::AbstractVarStringEncoding) = begin
            UInt8(0x00)
        end
    varData_min_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt8(0x00)
        end
    varData_max_value(::AbstractVarStringEncoding) = begin
            UInt8(0xff)
        end
    varData_max_value(::Type{<:AbstractVarStringEncoding}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function varData(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 4)
        end
    @inline varData!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 4, val)
            end
    export varData, varData!
end
export AbstractVarStringEncoding, Decoder, Encoder
end
module BaseNumber
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
abstract type AbstractBaseNumber <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractBaseNumber
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractBaseNumber
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0002))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0002))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractBaseNumber) = begin
        UInt16(4)
    end
sbe_encoded_length(::Type{<:AbstractBaseNumber}) = begin
        UInt16(4)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0002)
    end
Base.sizeof(m::AbstractBaseNumber) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractBaseNumber)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractBaseNumber)
    print(io, "BaseNumber", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    baseNumber_id(::AbstractBaseNumber) = begin
            UInt16(0xffff)
        end
    baseNumber_id(::Type{<:AbstractBaseNumber}) = begin
            UInt16(0xffff)
        end
    baseNumber_since_version(::AbstractBaseNumber) = begin
            UInt16(0)
        end
    baseNumber_since_version(::Type{<:AbstractBaseNumber}) = begin
            UInt16(0)
        end
    baseNumber_in_acting_version(m::AbstractBaseNumber) = begin
            m.acting_version >= UInt16(0)
        end
    baseNumber_encoding_offset(::AbstractBaseNumber) = begin
            Int(0)
        end
    baseNumber_encoding_offset(::Type{<:AbstractBaseNumber}) = begin
            Int(0)
        end
    baseNumber_encoding_length(::AbstractBaseNumber) = begin
            Int(4)
        end
    baseNumber_encoding_length(::Type{<:AbstractBaseNumber}) = begin
            Int(4)
        end
    baseNumber_null_value(::AbstractBaseNumber) = begin
            UInt32(0xffffffff)
        end
    baseNumber_null_value(::Type{<:AbstractBaseNumber}) = begin
            UInt32(0xffffffff)
        end
    baseNumber_min_value(::AbstractBaseNumber) = begin
            UInt32(0x00000000)
        end
    baseNumber_min_value(::Type{<:AbstractBaseNumber}) = begin
            UInt32(0x00000000)
        end
    baseNumber_max_value(::AbstractBaseNumber) = begin
            UInt32(0xffffffff)
        end
    baseNumber_max_value(::Type{<:AbstractBaseNumber}) = begin
            UInt32(0xffffffff)
        end
end
begin
    @inline function baseNumber(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 0)
        end
    @inline baseNumber!(m::Encoder, val) = begin
                encode_value(UInt32, m.buffer, m.offset + 0, val)
            end
    export baseNumber, baseNumber!
end
export AbstractBaseNumber, Decoder, Encoder
end
module Product
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
using ..Status
using ..GroupSizeEncoding
using ..Features
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractProduct{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractProduct{T}
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
        position_ptr[] = offset + UInt16(16)
        new{T}(buffer, offset, position_ptr, UInt16(16), UInt16(0x0002))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractProduct{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 16
        new{T}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Decoder = MessageHeader.Decoder(buffer, Int64(offset)))
        if MessageHeader.templateId(header) != UInt16(0x0001) || MessageHeader.schemaId(header) != UInt16(0x0002)
            error("Template id or schema id mismatch")
        end
        Decoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr::PositionPointer = PositionPointer(), header::MessageHeader.Encoder = MessageHeader.Encoder(buffer, Int64(offset)))
        MessageHeader.blockLength!(header, UInt16(16))
        MessageHeader.templateId!(header, UInt16(0x0001))
        MessageHeader.schemaId!(header, UInt16(0x0002))
        MessageHeader.version!(header, UInt16(0x0002))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    id_id(::AbstractProduct) = begin
            UInt16(0x0001)
        end
    id_since_version(::AbstractProduct) = begin
            UInt16(0)
        end
    id_in_acting_version(m::AbstractProduct) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    id_encoding_offset(::AbstractProduct) = begin
            0
        end
    id_encoding_length(::AbstractProduct) = begin
            8
        end
    id_null_value(::AbstractProduct) = begin
            0xffffffffffffffff
        end
    id_min_value(::AbstractProduct) = begin
            0x0000000000000000
        end
    id_max_value(::AbstractProduct) = begin
            0xfffffffffffffffe
        end
    id_id(::Type{<:AbstractProduct}) = begin
            UInt16(0x0001)
        end
    id_since_version(::Type{<:AbstractProduct}) = begin
            UInt16(0)
        end
    id_encoding_offset(::Type{<:AbstractProduct}) = begin
            0
        end
    id_encoding_length(::Type{<:AbstractProduct}) = begin
            8
        end
    id_null_value(::Type{<:AbstractProduct}) = begin
            0xffffffffffffffff
        end
    id_min_value(::Type{<:AbstractProduct}) = begin
            0x0000000000000000
        end
    id_max_value(::Type{<:AbstractProduct}) = begin
            0xfffffffffffffffe
        end
    function id_meta_attribute(::AbstractProduct, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function id_meta_attribute(::Type{<:AbstractProduct}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export id_id, id_since_version, id_in_acting_version, id_encoding_offset, id_encoding_length
    export id_null_value, id_min_value, id_max_value, id_meta_attribute
end
begin
    @inline function id(m::Decoder)
            return decode_value(UInt64, m.buffer, m.offset + 0)
        end
    @inline id!(m::Encoder, value) = begin
                encode_value(UInt64, m.buffer, m.offset + 0, value)
            end
end
begin
    export id, id!
end
begin
    quantity_id(::AbstractProduct) = begin
            UInt16(0x0002)
        end
    quantity_since_version(::AbstractProduct) = begin
            UInt16(0)
        end
    quantity_in_acting_version(m::AbstractProduct) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    quantity_encoding_offset(::AbstractProduct) = begin
            8
        end
    quantity_encoding_length(::AbstractProduct) = begin
            4
        end
    quantity_null_value(::AbstractProduct) = begin
            0xffffffff
        end
    quantity_min_value(::AbstractProduct) = begin
            0x00000000
        end
    quantity_max_value(::AbstractProduct) = begin
            0xfffffffe
        end
    quantity_id(::Type{<:AbstractProduct}) = begin
            UInt16(0x0002)
        end
    quantity_since_version(::Type{<:AbstractProduct}) = begin
            UInt16(0)
        end
    quantity_encoding_offset(::Type{<:AbstractProduct}) = begin
            8
        end
    quantity_encoding_length(::Type{<:AbstractProduct}) = begin
            4
        end
    quantity_null_value(::Type{<:AbstractProduct}) = begin
            0xffffffff
        end
    quantity_min_value(::Type{<:AbstractProduct}) = begin
            0x00000000
        end
    quantity_max_value(::Type{<:AbstractProduct}) = begin
            0xfffffffe
        end
    function quantity_meta_attribute(::AbstractProduct, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function quantity_meta_attribute(::Type{<:AbstractProduct}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export quantity_id, quantity_since_version, quantity_in_acting_version, quantity_encoding_offset, quantity_encoding_length
    export quantity_null_value, quantity_min_value, quantity_max_value, quantity_meta_attribute
end
begin
    @inline function quantity(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 8)
        end
    @inline quantity!(m::Encoder, value) = begin
                encode_value(UInt32, m.buffer, m.offset + 8, value)
            end
end
begin
    export quantity, quantity!
end
begin
    status_id(::AbstractProduct) = begin
            UInt16(0x0003)
        end
    status_since_version(::AbstractProduct) = begin
            UInt16(1)
        end
    status_in_acting_version(m::AbstractProduct) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    status_encoding_offset(::AbstractProduct) = begin
            12
        end
    status_encoding_length(::AbstractProduct) = begin
            1
        end
    status_null_value(::AbstractProduct) = begin
            0xff
        end
    status_min_value(::AbstractProduct) = begin
            0x00
        end
    status_max_value(::AbstractProduct) = begin
            0xff
        end
    status_id(::Type{<:AbstractProduct}) = begin
            UInt16(0x0003)
        end
    status_since_version(::Type{<:AbstractProduct}) = begin
            UInt16(1)
        end
    status_encoding_offset(::Type{<:AbstractProduct}) = begin
            12
        end
    status_encoding_length(::Type{<:AbstractProduct}) = begin
            1
        end
    status_null_value(::Type{<:AbstractProduct}) = begin
            0xff
        end
    status_min_value(::Type{<:AbstractProduct}) = begin
            0x00
        end
    status_max_value(::Type{<:AbstractProduct}) = begin
            0xff
        end
    function status_meta_attribute(::AbstractProduct, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function status_meta_attribute(::Type{<:AbstractProduct}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export status_id, status_since_version, status_in_acting_version, status_encoding_offset, status_encoding_length
    export status_null_value, status_min_value, status_max_value, status_meta_attribute
end
begin
    @inline function status(m::Decoder, ::Type{Integer})
            if m.acting_version < UInt16(1)
                return 0xff
            end
            return decode_value(UInt8, m.buffer, m.offset + 12)
        end
    @inline function status(m::Decoder)
            if m.acting_version < UInt16(1)
                return Status.SbeEnum(0xff)
            end
            raw = decode_value(UInt8, m.buffer, m.offset + 12)
            return Status.SbeEnum(raw)
        end
    @inline function status!(m::Encoder, value::Status.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 12, UInt8(value))
        end
    export status, status!
end
begin
    priority_id(::AbstractProduct) = begin
            UInt16(0x0004)
        end
    priority_since_version(::AbstractProduct) = begin
            UInt16(1)
        end
    priority_in_acting_version(m::AbstractProduct) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    priority_encoding_offset(::AbstractProduct) = begin
            13
        end
    priority_encoding_length(::AbstractProduct) = begin
            1
        end
    priority_null_value(::AbstractProduct) = begin
            0xff
        end
    priority_min_value(::AbstractProduct) = begin
            0x00
        end
    priority_max_value(::AbstractProduct) = begin
            0xfe
        end
    priority_id(::Type{<:AbstractProduct}) = begin
            UInt16(0x0004)
        end
    priority_since_version(::Type{<:AbstractProduct}) = begin
            UInt16(1)
        end
    priority_encoding_offset(::Type{<:AbstractProduct}) = begin
            13
        end
    priority_encoding_length(::Type{<:AbstractProduct}) = begin
            1
        end
    priority_null_value(::Type{<:AbstractProduct}) = begin
            0xff
        end
    priority_min_value(::Type{<:AbstractProduct}) = begin
            0x00
        end
    priority_max_value(::Type{<:AbstractProduct}) = begin
            0xfe
        end
    function priority_meta_attribute(::AbstractProduct, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function priority_meta_attribute(::Type{<:AbstractProduct}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export priority_id, priority_since_version, priority_in_acting_version, priority_encoding_offset, priority_encoding_length
    export priority_null_value, priority_min_value, priority_max_value, priority_meta_attribute
end
begin
    @inline function priority(m::Decoder)
            if m.acting_version < UInt16(1)
                return 0xff
            end
            return decode_value(UInt8, m.buffer, m.offset + 13)
        end
    @inline priority!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 13, value)
            end
end
begin
    export priority, priority!
end
begin
    features_id(::AbstractProduct) = begin
            UInt16(0x0005)
        end
    features_since_version(::AbstractProduct) = begin
            UInt16(2)
        end
    features_in_acting_version(m::AbstractProduct) = begin
            sbe_acting_version(m) >= UInt16(2)
        end
    features_encoding_offset(::AbstractProduct) = begin
            14
        end
    features_encoding_length(::AbstractProduct) = begin
            2
        end
    features_null_value(::AbstractProduct) = begin
            0xffff
        end
    features_min_value(::AbstractProduct) = begin
            0x0000
        end
    features_max_value(::AbstractProduct) = begin
            0xffff
        end
    features_id(::Type{<:AbstractProduct}) = begin
            UInt16(0x0005)
        end
    features_since_version(::Type{<:AbstractProduct}) = begin
            UInt16(2)
        end
    features_encoding_offset(::Type{<:AbstractProduct}) = begin
            14
        end
    features_encoding_length(::Type{<:AbstractProduct}) = begin
            2
        end
    features_null_value(::Type{<:AbstractProduct}) = begin
            0xffff
        end
    features_min_value(::Type{<:AbstractProduct}) = begin
            0x0000
        end
    features_max_value(::Type{<:AbstractProduct}) = begin
            0xffff
        end
    function features_meta_attribute(::AbstractProduct, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function features_meta_attribute(::Type{<:AbstractProduct}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export features_id, features_since_version, features_in_acting_version, features_encoding_offset, features_encoding_length
    export features_null_value, features_min_value, features_max_value, features_meta_attribute
end
begin
    @inline function features(m::Decoder)
            return Features.Decoder(m.buffer, m.offset + 14)
        end
    @inline function features(m::Encoder)
            return Features.Encoder(m.buffer, m.offset + 14)
        end
    export features
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractProduct) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_id(::AbstractProduct) = begin
            UInt16(0x0002)
        end
    SBE.sbe_schema_version(::AbstractProduct) = begin
            UInt16(0x0002)
        end
    SBE.sbe_block_length(::AbstractProduct) = begin
            UInt16(16)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractProduct) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractProduct) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractProduct) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractProduct) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractProduct, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module Tags
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
    abstract type AbstractTags{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractTags{T}
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
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractTags{T}
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
            position_ptr[] += 4
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
            position_ptr[] += 4
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractTags) = begin
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
            UInt16(0x0002)
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
    key_id(::AbstractTags) = begin
            UInt16(0x000b)
        end
    key_since_version(::AbstractTags) = begin
            UInt16(0)
        end
    key_in_acting_version(m::AbstractTags) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    key_encoding_offset(::AbstractTags) = begin
            0
        end
    key_encoding_length(::AbstractTags) = begin
            2
        end
    key_null_value(::AbstractTags) = begin
            0xffff
        end
    key_min_value(::AbstractTags) = begin
            0x0000
        end
    key_max_value(::AbstractTags) = begin
            0xfffe
        end
    key_id(::Type{<:AbstractTags}) = begin
            UInt16(0x000b)
        end
    key_since_version(::Type{<:AbstractTags}) = begin
            UInt16(0)
        end
    key_encoding_offset(::Type{<:AbstractTags}) = begin
            0
        end
    key_encoding_length(::Type{<:AbstractTags}) = begin
            2
        end
    key_null_value(::Type{<:AbstractTags}) = begin
            0xffff
        end
    key_min_value(::Type{<:AbstractTags}) = begin
            0x0000
        end
    key_max_value(::Type{<:AbstractTags}) = begin
            0xfffe
        end
    function key_meta_attribute(::AbstractTags, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function key_meta_attribute(::Type{<:AbstractTags}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export key_id, key_since_version, key_in_acting_version, key_encoding_offset, key_encoding_length
    export key_null_value, key_min_value, key_max_value, key_meta_attribute
end
begin
    @inline function key(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline key!(m::Encoder, value) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, value)
            end
end
begin
    export key, key!
end
begin
    value_id(::AbstractTags) = begin
            UInt16(0x000c)
        end
    value_since_version(::AbstractTags) = begin
            UInt16(0)
        end
    value_in_acting_version(m::AbstractTags) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    value_encoding_offset(::AbstractTags) = begin
            2
        end
    value_encoding_length(::AbstractTags) = begin
            4
        end
    value_null_value(::AbstractTags) = begin
            0xffffffff
        end
    value_min_value(::AbstractTags) = begin
            0x00000000
        end
    value_max_value(::AbstractTags) = begin
            0xfffffffe
        end
    value_id(::Type{<:AbstractTags}) = begin
            UInt16(0x000c)
        end
    value_since_version(::Type{<:AbstractTags}) = begin
            UInt16(0)
        end
    value_encoding_offset(::Type{<:AbstractTags}) = begin
            2
        end
    value_encoding_length(::Type{<:AbstractTags}) = begin
            4
        end
    value_null_value(::Type{<:AbstractTags}) = begin
            0xffffffff
        end
    value_min_value(::Type{<:AbstractTags}) = begin
            0x00000000
        end
    value_max_value(::Type{<:AbstractTags}) = begin
            0xfffffffe
        end
    function value_meta_attribute(::AbstractTags, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function value_meta_attribute(::Type{<:AbstractTags}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export value_id, value_since_version, value_in_acting_version, value_encoding_offset, value_encoding_length
    export value_null_value, value_min_value, value_max_value, value_meta_attribute
end
begin
    @inline function value(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 2)
        end
    @inline value!(m::Encoder, value) = begin
                encode_value(UInt32, m.buffer, m.offset + 2, value)
            end
end
begin
    export value, value!
end
end
@inline function tags(m::Decoder)
        if m.acting_version < UInt16(1)
            return Tags.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version, UInt16(0), UInt16(0))
        end
        return Tags.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function tags!(m::Encoder, count)
        return Tags.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
tags_id(::AbstractProduct) = begin
        UInt16(0x000a)
    end
tags_since_version(::AbstractProduct) = begin
        UInt16(1)
    end
tags_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(1)
    end
tags_in_acting_version(m::Encoder) = begin
        UInt16(0x0002) >= UInt16(1)
    end
export tags, tags!, Tags
begin
    @inline function name_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function name_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_name!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = name_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function name(m::Decoder)
            len = name_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function name(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, name(m))
        end
    @inline function name(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = name(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function name(m::Decoder, ::Type{Symbol})
            return Symbol(name(m, String))
        end
    @inline function name(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, name(m)))[]
        end
    @inline function name(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, name(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function name!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            name_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function name!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            name_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function name!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            name_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function name!(m::Encoder, src::Symbol)
            return name!(m, to_string(src))
        end
    @inline function name!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return name!(m, bytes)
        end
    @inline function name!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return name!(m, bytes)
        end
end
begin
    const name_id = UInt16(0x0014)
    const name_since_version = UInt16(0)
    const name_header_length = 5
end
begin
    export name, name!, name_length, name_length!, skip_name!
end
begin
    @inline function description_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(2)
                return (UInt32)(0)
            end
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function description_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_description!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            if m.acting_version < UInt16(2)
                return 0
            end
            len = description_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function description(m::Decoder)
            if m.acting_version < UInt16(2)
                return view(m.buffer, 1:0)
            end
            len = description_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function description(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, description(m))
        end
    @inline function description(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = description(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function description(m::Decoder, ::Type{Symbol})
            return Symbol(description(m, String))
        end
    @inline function description(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, description(m)))[]
        end
    @inline function description(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, description(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function description!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            description_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function description!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            description_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function description!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            description_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function description!(m::Encoder, src::Symbol)
            return description!(m, to_string(src))
        end
    @inline function description!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return description!(m, bytes)
        end
    @inline function description!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return description!(m, bytes)
        end
end
begin
    const description_id = UInt16(0x0015)
    const description_since_version = UInt16(2)
    const description_header_length = 5
end
begin
    export description, description!, description_length, description_length!, skip_description!
end
end
export Status, Features, MessageHeader, GroupSizeEncoding, VarStringEncoding, BaseNumber, Product
end