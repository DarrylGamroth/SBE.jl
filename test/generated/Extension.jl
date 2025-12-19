module Extension
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
@enumx T = SbeEnum BoostType::UInt8 begin
        TURBO = UInt8(0x54)
        SUPERCHARGER = UInt8(0x53)
        NITROUS = UInt8(0x4e)
        KERS = UInt8(0x4b)
        NULL_VALUE = UInt8(0x00)
    end
@enumx T = SbeEnum BooleanType::UInt8 begin
        F = UInt8(0x00)
        T = UInt8(0x01)
        NULL_VALUE = UInt8(0xff)
    end
@enumx T = SbeEnum Model::UInt8 begin
        A = UInt8(0x41)
        B = UInt8(0x42)
        C = UInt8(0x43)
        NULL_VALUE = UInt8(0x00)
    end
@enumx T = SbeEnum BoostType::UInt8 begin
        TURBO = UInt8(0x54)
        SUPERCHARGER = UInt8(0x53)
        NITROUS = UInt8(0x4e)
        KERS = UInt8(0x4b)
        NULL_VALUE = UInt8(0x00)
    end
module OptionalExtras
using SBE: AbstractSbeEncodedType
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractOptionalExtras <: AbstractSbeEncodedType end
struct Decoder{T <: AbstractVector{UInt8}} <: AbstractOptionalExtras
    buffer::T
    offset::Int
    acting_version::UInt16
end
struct Encoder{T <: AbstractVector{UInt8}} <: AbstractOptionalExtras
    buffer::T
    offset::Int
end
@inline function Decoder(buffer::AbstractVector{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractVector{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractVector{UInt8})
        Encoder(buffer, Int64(0))
    end
id(::Type{<:AbstractOptionalExtras}) = begin
        UInt16(0xffff)
    end
id(::AbstractOptionalExtras) = begin
        UInt16(0xffff)
    end
since_version(::Type{<:AbstractOptionalExtras}) = begin
        UInt16(0)
    end
since_version(::AbstractOptionalExtras) = begin
        UInt16(0)
    end
encoding_offset(::Type{<:AbstractOptionalExtras}) = begin
        0
    end
encoding_offset(::AbstractOptionalExtras) = begin
        0
    end
encoding_length(::Type{<:AbstractOptionalExtras}) = begin
        1
    end
encoding_length(::AbstractOptionalExtras) = begin
        1
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.eltype(::Type{<:AbstractOptionalExtras}) = begin
        UInt8
    end
Base.eltype(::AbstractOptionalExtras) = begin
        UInt8
    end
@inline function clear!(set::Encoder)
        encode_value(UInt8, set.buffer, set.offset, zero(UInt8))
        return set
    end
@inline function is_empty(set::AbstractOptionalExtras)
        return decode_value(UInt8, set.buffer, set.offset) == zero(UInt8)
    end
@inline function raw_value(set::AbstractOptionalExtras)
        return decode_value(UInt8, set.buffer, set.offset)
    end
begin
    @inline function sunRoof(set::AbstractOptionalExtras)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 0 != 0
        end
end
begin
    @inline function sunRoof!(set::Encoder, value::Bool)
            bits = decode_value(UInt8, set.buffer, set.offset)
            bits = if value
                    bits | UInt8(0x01) << 0
                else
                    bits & ~(UInt8(0x01) << 0)
                end
            encode_value(UInt8, set.buffer, set.offset, bits)
            return set
        end
end
export sunRoof, sunRoof!
begin
    @inline function sportsPack(set::AbstractOptionalExtras)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 1 != 0
        end
end
begin
    @inline function sportsPack!(set::Encoder, value::Bool)
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
export sportsPack, sportsPack!
begin
    @inline function cruiseControl(set::AbstractOptionalExtras)
            return decode_value(UInt8, set.buffer, set.offset) & UInt8(0x01) << 2 != 0
        end
end
begin
    @inline function cruiseControl!(set::Encoder, value::Bool)
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
export cruiseControl, cruiseControl!
export AbstractOptionalExtras, Decoder, Encoder
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
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
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
        UInt16(0x0001)
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
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
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
        UInt16(0x0001)
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
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
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
        UInt16(0x0001)
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
module VarAsciiEncoding
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
abstract type AbstractVarAsciiEncoding <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractVarAsciiEncoding
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractVarAsciiEncoding
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractVarAsciiEncoding) = begin
        UInt16(5)
    end
sbe_encoded_length(::Type{<:AbstractVarAsciiEncoding}) = begin
        UInt16(5)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractVarAsciiEncoding) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractVarAsciiEncoding)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractVarAsciiEncoding)
    print(io, "VarAsciiEncoding", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    length_id(::AbstractVarAsciiEncoding) = begin
            UInt16(0xffff)
        end
    length_id(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt16(0xffff)
        end
    length_since_version(::AbstractVarAsciiEncoding) = begin
            UInt16(0)
        end
    length_since_version(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt16(0)
        end
    length_in_acting_version(m::AbstractVarAsciiEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    length_encoding_offset(::AbstractVarAsciiEncoding) = begin
            Int(0)
        end
    length_encoding_offset(::Type{<:AbstractVarAsciiEncoding}) = begin
            Int(0)
        end
    length_encoding_length(::AbstractVarAsciiEncoding) = begin
            Int(4)
        end
    length_encoding_length(::Type{<:AbstractVarAsciiEncoding}) = begin
            Int(4)
        end
    length_null_value(::AbstractVarAsciiEncoding) = begin
            UInt32(0xffffffff)
        end
    length_null_value(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt32(0xffffffff)
        end
    length_min_value(::AbstractVarAsciiEncoding) = begin
            UInt32(0x00000000)
        end
    length_min_value(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt32(0x00000000)
        end
    length_max_value(::AbstractVarAsciiEncoding) = begin
            UInt32(0x40000000)
        end
    length_max_value(::Type{<:AbstractVarAsciiEncoding}) = begin
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
    varData_id(::AbstractVarAsciiEncoding) = begin
            UInt16(0xffff)
        end
    varData_id(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt16(0xffff)
        end
    varData_since_version(::AbstractVarAsciiEncoding) = begin
            UInt16(0)
        end
    varData_since_version(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt16(0)
        end
    varData_in_acting_version(m::AbstractVarAsciiEncoding) = begin
            m.acting_version >= UInt16(0)
        end
    varData_encoding_offset(::AbstractVarAsciiEncoding) = begin
            Int(4)
        end
    varData_encoding_offset(::Type{<:AbstractVarAsciiEncoding}) = begin
            Int(4)
        end
    varData_encoding_length(::AbstractVarAsciiEncoding) = begin
            Int(1)
        end
    varData_encoding_length(::Type{<:AbstractVarAsciiEncoding}) = begin
            Int(1)
        end
    varData_null_value(::AbstractVarAsciiEncoding) = begin
            UInt8(0xff)
        end
    varData_null_value(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt8(0xff)
        end
    varData_min_value(::AbstractVarAsciiEncoding) = begin
            UInt8(0x00)
        end
    varData_min_value(::Type{<:AbstractVarAsciiEncoding}) = begin
            UInt8(0x00)
        end
    varData_max_value(::AbstractVarAsciiEncoding) = begin
            UInt8(0xff)
        end
    varData_max_value(::Type{<:AbstractVarAsciiEncoding}) = begin
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
export AbstractVarAsciiEncoding, Decoder, Encoder
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
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractVarDataEncoding) = begin
        UInt16(5)
    end
sbe_encoded_length(::Type{<:AbstractVarDataEncoding}) = begin
        UInt16(5)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
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
            Int(4)
        end
    length_encoding_length(::Type{<:AbstractVarDataEncoding}) = begin
            Int(4)
        end
    length_null_value(::AbstractVarDataEncoding) = begin
            UInt32(0xffffffff)
        end
    length_null_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt32(0xffffffff)
        end
    length_min_value(::AbstractVarDataEncoding) = begin
            UInt32(0x00000000)
        end
    length_min_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt32(0x00000000)
        end
    length_max_value(::AbstractVarDataEncoding) = begin
            UInt32(0x40000000)
        end
    length_max_value(::Type{<:AbstractVarDataEncoding}) = begin
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
            Int(4)
        end
    varData_encoding_offset(::Type{<:AbstractVarDataEncoding}) = begin
            Int(4)
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
            return decode_value(UInt8, m.buffer, m.offset + 4)
        end
    @inline varData!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 4, val)
            end
    export varData, varData!
end
export AbstractVarDataEncoding, Decoder, Encoder
end
module ModelYear
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
abstract type AbstractModelYear <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractModelYear
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractModelYear
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractModelYear) = begin
        UInt16(2)
    end
sbe_encoded_length(::Type{<:AbstractModelYear}) = begin
        UInt16(2)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractModelYear) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractModelYear)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractModelYear)
    print(io, "ModelYear", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    ModelYear_id(::AbstractModelYear) = begin
            UInt16(0xffff)
        end
    ModelYear_id(::Type{<:AbstractModelYear}) = begin
            UInt16(0xffff)
        end
    ModelYear_since_version(::AbstractModelYear) = begin
            UInt16(0)
        end
    ModelYear_since_version(::Type{<:AbstractModelYear}) = begin
            UInt16(0)
        end
    ModelYear_in_acting_version(m::AbstractModelYear) = begin
            m.acting_version >= UInt16(0)
        end
    ModelYear_encoding_offset(::AbstractModelYear) = begin
            Int(0)
        end
    ModelYear_encoding_offset(::Type{<:AbstractModelYear}) = begin
            Int(0)
        end
    ModelYear_encoding_length(::AbstractModelYear) = begin
            Int(2)
        end
    ModelYear_encoding_length(::Type{<:AbstractModelYear}) = begin
            Int(2)
        end
    ModelYear_null_value(::AbstractModelYear) = begin
            UInt16(0xffff)
        end
    ModelYear_null_value(::Type{<:AbstractModelYear}) = begin
            UInt16(0xffff)
        end
    ModelYear_min_value(::AbstractModelYear) = begin
            UInt16(0x0000)
        end
    ModelYear_min_value(::Type{<:AbstractModelYear}) = begin
            UInt16(0x0000)
        end
    ModelYear_max_value(::AbstractModelYear) = begin
            UInt16(0xffff)
        end
    ModelYear_max_value(::Type{<:AbstractModelYear}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function ModelYear(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline ModelYear!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, val)
            end
    export ModelYear, ModelYear!
end
export AbstractModelYear, Decoder, Encoder
end
module VehicleCode
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
abstract type AbstractVehicleCode <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractVehicleCode
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractVehicleCode
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractVehicleCode) = begin
        UInt16(6)
    end
sbe_encoded_length(::Type{<:AbstractVehicleCode}) = begin
        UInt16(6)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractVehicleCode) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractVehicleCode)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractVehicleCode)
    print(io, "VehicleCode", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    VehicleCode_id(::AbstractVehicleCode) = begin
            UInt16(0xffff)
        end
    VehicleCode_id(::Type{<:AbstractVehicleCode}) = begin
            UInt16(0xffff)
        end
    VehicleCode_since_version(::AbstractVehicleCode) = begin
            UInt16(0)
        end
    VehicleCode_since_version(::Type{<:AbstractVehicleCode}) = begin
            UInt16(0)
        end
    VehicleCode_in_acting_version(m::AbstractVehicleCode) = begin
            m.acting_version >= UInt16(0)
        end
    VehicleCode_encoding_offset(::AbstractVehicleCode) = begin
            Int(0)
        end
    VehicleCode_encoding_offset(::Type{<:AbstractVehicleCode}) = begin
            Int(0)
        end
    VehicleCode_encoding_length(::AbstractVehicleCode) = begin
            Int(6)
        end
    VehicleCode_encoding_length(::Type{<:AbstractVehicleCode}) = begin
            Int(6)
        end
    VehicleCode_null_value(::AbstractVehicleCode) = begin
            UInt8(0xff)
        end
    VehicleCode_null_value(::Type{<:AbstractVehicleCode}) = begin
            UInt8(0xff)
        end
    VehicleCode_min_value(::AbstractVehicleCode) = begin
            UInt8(0x00)
        end
    VehicleCode_min_value(::Type{<:AbstractVehicleCode}) = begin
            UInt8(0x00)
        end
    VehicleCode_max_value(::AbstractVehicleCode) = begin
            UInt8(0xff)
        end
    VehicleCode_max_value(::Type{<:AbstractVehicleCode}) = begin
            UInt8(0xff)
        end
end
using StringViews: StringView
begin
    @inline function VehicleCode(m::Decoder)
            bytes = decode_array(UInt8, m.buffer, m.offset + 0, 6)
            pos = findfirst(iszero, bytes)
            len = if pos !== nothing
                    pos - 1
                else
                    Base.length(bytes)
                end
            return StringView(view(bytes, 1:len))
        end
    @inline function VehicleCode!(m::Encoder)
            return encode_array(UInt8, m.buffer, m.offset + 0, 6)
        end
    @inline function VehicleCode!(m::Encoder, value::AbstractString)
            bytes = codeunits(value)
            dest = encode_array(UInt8, m.buffer, m.offset + 0, 6)
            len = min(length(bytes), length(dest))
            copyto!(dest, 1, bytes, 1, len)
            if len < length(dest)
                fill!(view(dest, len + 1:length(dest)), 0x00)
            end
        end
    @inline function VehicleCode!(m::Encoder, value::AbstractVector{UInt8})
            dest = encode_array(UInt8, m.buffer, m.offset + 0, 6)
            len = min(length(value), length(dest))
            copyto!(dest, 1, value, 1, len)
            if len < length(dest)
                fill!(view(dest, len + 1:length(dest)), 0x00)
            end
        end
    export VehicleCode, VehicleCode!
end
export AbstractVehicleCode, Decoder, Encoder
end
module Ron
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
abstract type AbstractRon <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractRon
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractRon
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractRon) = begin
        UInt16(1)
    end
sbe_encoded_length(::Type{<:AbstractRon}) = begin
        UInt16(1)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractRon) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractRon)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractRon)
    print(io, "Ron", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    Ron_id(::AbstractRon) = begin
            UInt16(0xffff)
        end
    Ron_id(::Type{<:AbstractRon}) = begin
            UInt16(0xffff)
        end
    Ron_since_version(::AbstractRon) = begin
            UInt16(0)
        end
    Ron_since_version(::Type{<:AbstractRon}) = begin
            UInt16(0)
        end
    Ron_in_acting_version(m::AbstractRon) = begin
            m.acting_version >= UInt16(0)
        end
    Ron_encoding_offset(::AbstractRon) = begin
            Int(0)
        end
    Ron_encoding_offset(::Type{<:AbstractRon}) = begin
            Int(0)
        end
    Ron_encoding_length(::AbstractRon) = begin
            Int(1)
        end
    Ron_encoding_length(::Type{<:AbstractRon}) = begin
            Int(1)
        end
    Ron_null_value(::AbstractRon) = begin
            UInt8(0xff)
        end
    Ron_null_value(::Type{<:AbstractRon}) = begin
            UInt8(0xff)
        end
    Ron_min_value(::AbstractRon) = begin
            UInt8(0x5a)
        end
    Ron_min_value(::Type{<:AbstractRon}) = begin
            UInt8(0x5a)
        end
    Ron_max_value(::AbstractRon) = begin
            UInt8(0x6e)
        end
    Ron_max_value(::Type{<:AbstractRon}) = begin
            UInt8(0x6e)
        end
end
begin
    @inline function Ron(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline Ron!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, val)
            end
    export Ron, Ron!
end
export AbstractRon, Decoder, Encoder
end
module SomeNumbers
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
abstract type AbstractSomeNumbers <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractSomeNumbers
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractSomeNumbers
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractSomeNumbers) = begin
        UInt16(16)
    end
sbe_encoded_length(::Type{<:AbstractSomeNumbers}) = begin
        UInt16(16)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractSomeNumbers) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractSomeNumbers)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractSomeNumbers)
    print(io, "SomeNumbers", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    someNumbers_id(::AbstractSomeNumbers) = begin
            UInt16(0xffff)
        end
    someNumbers_id(::Type{<:AbstractSomeNumbers}) = begin
            UInt16(0xffff)
        end
    someNumbers_since_version(::AbstractSomeNumbers) = begin
            UInt16(0)
        end
    someNumbers_since_version(::Type{<:AbstractSomeNumbers}) = begin
            UInt16(0)
        end
    someNumbers_in_acting_version(m::AbstractSomeNumbers) = begin
            m.acting_version >= UInt16(0)
        end
    someNumbers_encoding_offset(::AbstractSomeNumbers) = begin
            Int(0)
        end
    someNumbers_encoding_offset(::Type{<:AbstractSomeNumbers}) = begin
            Int(0)
        end
    someNumbers_encoding_length(::AbstractSomeNumbers) = begin
            Int(16)
        end
    someNumbers_encoding_length(::Type{<:AbstractSomeNumbers}) = begin
            Int(16)
        end
    someNumbers_null_value(::AbstractSomeNumbers) = begin
            UInt32(0xffffffff)
        end
    someNumbers_null_value(::Type{<:AbstractSomeNumbers}) = begin
            UInt32(0xffffffff)
        end
    someNumbers_min_value(::AbstractSomeNumbers) = begin
            UInt32(0x00000000)
        end
    someNumbers_min_value(::Type{<:AbstractSomeNumbers}) = begin
            UInt32(0x00000000)
        end
    someNumbers_max_value(::AbstractSomeNumbers) = begin
            UInt32(0xffffffff)
        end
    someNumbers_max_value(::Type{<:AbstractSomeNumbers}) = begin
            UInt32(0xffffffff)
        end
end
begin
    @inline function someNumbers(m::Decoder)
            return decode_array(UInt32, m.buffer, m.offset + 0, 4)
        end
    @inline function someNumbers!(m::Encoder)
            return encode_array(UInt32, m.buffer, m.offset + 0, 4)
        end
    @inline function someNumbers!(m::Encoder, val)
            copyto!(someNumbers!(m), val)
        end
    export someNumbers, someNumbers!
end
export AbstractSomeNumbers, Decoder, Encoder
end
module Percentage
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
abstract type AbstractPercentage <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractPercentage
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractPercentage
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractPercentage) = begin
        UInt16(1)
    end
sbe_encoded_length(::Type{<:AbstractPercentage}) = begin
        UInt16(1)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractPercentage) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractPercentage)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractPercentage)
    print(io, "Percentage", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    Percentage_id(::AbstractPercentage) = begin
            UInt16(0xffff)
        end
    Percentage_id(::Type{<:AbstractPercentage}) = begin
            UInt16(0xffff)
        end
    Percentage_since_version(::AbstractPercentage) = begin
            UInt16(0)
        end
    Percentage_since_version(::Type{<:AbstractPercentage}) = begin
            UInt16(0)
        end
    Percentage_in_acting_version(m::AbstractPercentage) = begin
            m.acting_version >= UInt16(0)
        end
    Percentage_encoding_offset(::AbstractPercentage) = begin
            Int(0)
        end
    Percentage_encoding_offset(::Type{<:AbstractPercentage}) = begin
            Int(0)
        end
    Percentage_encoding_length(::AbstractPercentage) = begin
            Int(1)
        end
    Percentage_encoding_length(::Type{<:AbstractPercentage}) = begin
            Int(1)
        end
    Percentage_null_value(::AbstractPercentage) = begin
            Int8(-128)
        end
    Percentage_null_value(::Type{<:AbstractPercentage}) = begin
            Int8(-128)
        end
    Percentage_min_value(::AbstractPercentage) = begin
            Int8(0)
        end
    Percentage_min_value(::Type{<:AbstractPercentage}) = begin
            Int8(0)
        end
    Percentage_max_value(::AbstractPercentage) = begin
            Int8(100)
        end
    Percentage_max_value(::Type{<:AbstractPercentage}) = begin
            Int8(100)
        end
end
begin
    @inline function Percentage(m::Decoder)
            return decode_value(Int8, m.buffer, m.offset + 0)
        end
    @inline Percentage!(m::Encoder, val) = begin
                encode_value(Int8, m.buffer, m.offset + 0, val)
            end
    export Percentage, Percentage!
end
export AbstractPercentage, Decoder, Encoder
end
module Booster
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
using MappedArrays: mappedarray
using EnumX
using ..BoostType
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractBooster <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractBooster
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractBooster
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractBooster) = begin
        UInt16(2)
    end
sbe_encoded_length(::Type{<:AbstractBooster}) = begin
        UInt16(2)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractBooster) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractBooster)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractBooster)
    print(io, "Booster", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    boostType_id(::AbstractBooster) = begin
            UInt16(0xffff)
        end
    boostType_id(::Type{<:AbstractBooster}) = begin
            UInt16(0xffff)
        end
    boostType_since_version(::AbstractBooster) = begin
            UInt16(0)
        end
    boostType_since_version(::Type{<:AbstractBooster}) = begin
            UInt16(0)
        end
    boostType_in_acting_version(m::AbstractBooster) = begin
            m.acting_version >= UInt16(0)
        end
    boostType_encoding_offset(::AbstractBooster) = begin
            Int(0)
        end
    boostType_encoding_offset(::Type{<:AbstractBooster}) = begin
            Int(0)
        end
    boostType_encoding_length(::AbstractBooster) = begin
            Int(1)
        end
    boostType_encoding_length(::Type{<:AbstractBooster}) = begin
            Int(1)
        end
end
begin
    @inline function boostType(m::Decoder)
            raw_value = decode_value(UInt8, m.buffer, m.offset + 0)
            return BoostType.SbeEnum(raw_value)
        end
    @inline function boostType!(m::Encoder, val)
            encode_value(UInt8, m.buffer, m.offset + 0, UInt8(val))
        end
end
begin
    horsePower_id(::AbstractBooster) = begin
            UInt16(0xffff)
        end
    horsePower_id(::Type{<:AbstractBooster}) = begin
            UInt16(0xffff)
        end
    horsePower_since_version(::AbstractBooster) = begin
            UInt16(0)
        end
    horsePower_since_version(::Type{<:AbstractBooster}) = begin
            UInt16(0)
        end
    horsePower_in_acting_version(m::AbstractBooster) = begin
            m.acting_version >= UInt16(0)
        end
    horsePower_encoding_offset(::AbstractBooster) = begin
            Int(1)
        end
    horsePower_encoding_offset(::Type{<:AbstractBooster}) = begin
            Int(1)
        end
    horsePower_encoding_length(::AbstractBooster) = begin
            Int(1)
        end
    horsePower_encoding_length(::Type{<:AbstractBooster}) = begin
            Int(1)
        end
    horsePower_null_value(::AbstractBooster) = begin
            UInt8(0xff)
        end
    horsePower_null_value(::Type{<:AbstractBooster}) = begin
            UInt8(0xff)
        end
    horsePower_min_value(::AbstractBooster) = begin
            UInt8(0x00)
        end
    horsePower_min_value(::Type{<:AbstractBooster}) = begin
            UInt8(0x00)
        end
    horsePower_max_value(::AbstractBooster) = begin
            UInt8(0xff)
        end
    horsePower_max_value(::Type{<:AbstractBooster}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function horsePower(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 1)
        end
    @inline horsePower!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 1, val)
            end
    export horsePower, horsePower!
end
export AbstractBooster, Decoder, Encoder
end
module Engine
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
using MappedArrays: mappedarray
nothing
using ..BooleanType
using ..Percentage
using ..Booster
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
abstract type AbstractEngine <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractEngine
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractEngine
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractEngine) = begin
        UInt16(10)
    end
sbe_encoded_length(::Type{<:AbstractEngine}) = begin
        UInt16(10)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractEngine) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractEngine)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractEngine)
    print(io, "Engine", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    capacity_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    capacity_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    capacity_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    capacity_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    capacity_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    capacity_encoding_offset(::AbstractEngine) = begin
            Int(0)
        end
    capacity_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(0)
        end
    capacity_encoding_length(::AbstractEngine) = begin
            Int(2)
        end
    capacity_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(2)
        end
    capacity_null_value(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    capacity_null_value(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    capacity_min_value(::AbstractEngine) = begin
            UInt16(0x0000)
        end
    capacity_min_value(::Type{<:AbstractEngine}) = begin
            UInt16(0x0000)
        end
    capacity_max_value(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    capacity_max_value(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline function capacity(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline capacity!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, val)
            end
    export capacity, capacity!
end
begin
    numCylinders_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    numCylinders_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    numCylinders_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    numCylinders_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    numCylinders_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    numCylinders_encoding_offset(::AbstractEngine) = begin
            Int(2)
        end
    numCylinders_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(2)
        end
    numCylinders_encoding_length(::AbstractEngine) = begin
            Int(1)
        end
    numCylinders_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(1)
        end
    numCylinders_null_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    numCylinders_null_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
    numCylinders_min_value(::AbstractEngine) = begin
            UInt8(0x00)
        end
    numCylinders_min_value(::Type{<:AbstractEngine}) = begin
            UInt8(0x00)
        end
    numCylinders_max_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    numCylinders_max_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function numCylinders(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 2)
        end
    @inline numCylinders!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 2, val)
            end
    export numCylinders, numCylinders!
end
begin
    maxRpm_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    maxRpm_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    maxRpm_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    maxRpm_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    maxRpm_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    maxRpm_encoding_offset(::AbstractEngine) = begin
            Int(3)
        end
    maxRpm_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(3)
        end
    maxRpm_encoding_length(::AbstractEngine) = begin
            Int(0)
        end
    maxRpm_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(0)
        end
    maxRpm_null_value(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    maxRpm_null_value(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    maxRpm_min_value(::AbstractEngine) = begin
            UInt16(0x0000)
        end
    maxRpm_min_value(::Type{<:AbstractEngine}) = begin
            UInt16(0x0000)
        end
    maxRpm_max_value(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    maxRpm_max_value(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
end
begin
    @inline maxRpm(::AbstractEngine) = begin
                UInt16(0x2328)
            end
    @inline maxRpm(::Type{<:AbstractEngine}) = begin
                UInt16(0x2328)
            end
    export maxRpm
end
begin
    manufacturerCode_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    manufacturerCode_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    manufacturerCode_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    manufacturerCode_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    manufacturerCode_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    manufacturerCode_encoding_offset(::AbstractEngine) = begin
            Int(3)
        end
    manufacturerCode_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(3)
        end
    manufacturerCode_encoding_length(::AbstractEngine) = begin
            Int(3)
        end
    manufacturerCode_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(3)
        end
    manufacturerCode_null_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    manufacturerCode_null_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
    manufacturerCode_min_value(::AbstractEngine) = begin
            UInt8(0x00)
        end
    manufacturerCode_min_value(::Type{<:AbstractEngine}) = begin
            UInt8(0x00)
        end
    manufacturerCode_max_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    manufacturerCode_max_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
end
using StringViews: StringView
begin
    @inline function manufacturerCode(m::Decoder)
            bytes = decode_array(UInt8, m.buffer, m.offset + 3, 3)
            pos = findfirst(iszero, bytes)
            len = if pos !== nothing
                    pos - 1
                else
                    Base.length(bytes)
                end
            return StringView(view(bytes, 1:len))
        end
    @inline function manufacturerCode!(m::Encoder)
            return encode_array(UInt8, m.buffer, m.offset + 3, 3)
        end
    @inline function manufacturerCode!(m::Encoder, value::AbstractString)
            bytes = codeunits(value)
            dest = encode_array(UInt8, m.buffer, m.offset + 3, 3)
            len = min(length(bytes), length(dest))
            copyto!(dest, 1, bytes, 1, len)
            if len < length(dest)
                fill!(view(dest, len + 1:length(dest)), 0x00)
            end
        end
    @inline function manufacturerCode!(m::Encoder, value::AbstractVector{UInt8})
            dest = encode_array(UInt8, m.buffer, m.offset + 3, 3)
            len = min(length(value), length(dest))
            copyto!(dest, 1, value, 1, len)
            if len < length(dest)
                fill!(view(dest, len + 1:length(dest)), 0x00)
            end
        end
    export manufacturerCode, manufacturerCode!
end
begin
    fuel_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    fuel_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    fuel_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    fuel_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    fuel_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    fuel_encoding_offset(::AbstractEngine) = begin
            Int(6)
        end
    fuel_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(6)
        end
    fuel_encoding_length(::AbstractEngine) = begin
            Int(0)
        end
    fuel_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(0)
        end
    fuel_null_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    fuel_null_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
    fuel_min_value(::AbstractEngine) = begin
            UInt8(0x00)
        end
    fuel_min_value(::Type{<:AbstractEngine}) = begin
            UInt8(0x00)
        end
    fuel_max_value(::AbstractEngine) = begin
            UInt8(0xff)
        end
    fuel_max_value(::Type{<:AbstractEngine}) = begin
            UInt8(0xff)
        end
end
begin
    @inline fuel(::AbstractEngine) = begin
                "Petrol"
            end
    @inline fuel(::Type{<:AbstractEngine}) = begin
                "Petrol"
            end
    export fuel
end
begin
    @inline function efficiency(m::Decoder)
            return Percentage.Decoder(m.buffer, m.offset + 6, m.acting_version)
        end
    @inline function efficiency(m::Encoder)
            return Percentage.Encoder(m.buffer, m.offset + 6)
        end
    export efficiency
end
begin
    boosterEnabled_id(::AbstractEngine) = begin
            UInt16(0xffff)
        end
    boosterEnabled_id(::Type{<:AbstractEngine}) = begin
            UInt16(0xffff)
        end
    boosterEnabled_since_version(::AbstractEngine) = begin
            UInt16(0)
        end
    boosterEnabled_since_version(::Type{<:AbstractEngine}) = begin
            UInt16(0)
        end
    boosterEnabled_in_acting_version(m::AbstractEngine) = begin
            m.acting_version >= UInt16(0)
        end
    boosterEnabled_encoding_offset(::AbstractEngine) = begin
            Int(7)
        end
    boosterEnabled_encoding_offset(::Type{<:AbstractEngine}) = begin
            Int(7)
        end
    boosterEnabled_encoding_length(::AbstractEngine) = begin
            Int(1)
        end
    boosterEnabled_encoding_length(::Type{<:AbstractEngine}) = begin
            Int(1)
        end
end
begin
    @inline function boosterEnabled(m::Decoder)
            raw_value = decode_value(UInt8, m.buffer, m.offset + 7)
            return BooleanType.SbeEnum(raw_value)
        end
    @inline function boosterEnabled!(m::Encoder, val)
            encode_value(UInt8, m.buffer, m.offset + 7, UInt8(val))
        end
    export boosterEnabled, boosterEnabled!
end
begin
    @inline function booster(m::Decoder)
            return Booster.Decoder(m.buffer, m.offset + 8, m.acting_version)
        end
    @inline function booster(m::Encoder)
            return Booster.Encoder(m.buffer, m.offset + 8)
        end
    export booster
end
export AbstractEngine, Decoder, Encoder
end
module UuidT
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
abstract type AbstractUuidT <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractUuidT
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractUuidT
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractUuidT) = begin
        UInt16(16)
    end
sbe_encoded_length(::Type{<:AbstractUuidT}) = begin
        UInt16(16)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractUuidT) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractUuidT)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractUuidT)
    print(io, "UuidT", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    uuidT_id(::AbstractUuidT) = begin
            UInt16(0xffff)
        end
    uuidT_id(::Type{<:AbstractUuidT}) = begin
            UInt16(0xffff)
        end
    uuidT_since_version(::AbstractUuidT) = begin
            UInt16(1)
        end
    uuidT_since_version(::Type{<:AbstractUuidT}) = begin
            UInt16(1)
        end
    uuidT_in_acting_version(m::AbstractUuidT) = begin
            m.acting_version >= UInt16(1)
        end
    uuidT_encoding_offset(::AbstractUuidT) = begin
            Int(0)
        end
    uuidT_encoding_offset(::Type{<:AbstractUuidT}) = begin
            Int(0)
        end
    uuidT_encoding_length(::AbstractUuidT) = begin
            Int(16)
        end
    uuidT_encoding_length(::Type{<:AbstractUuidT}) = begin
            Int(16)
        end
    uuidT_null_value(::AbstractUuidT) = begin
            Int64(-9223372036854775808)
        end
    uuidT_null_value(::Type{<:AbstractUuidT}) = begin
            Int64(-9223372036854775808)
        end
    uuidT_min_value(::AbstractUuidT) = begin
            Int64(-9223372036854775808)
        end
    uuidT_min_value(::Type{<:AbstractUuidT}) = begin
            Int64(-9223372036854775808)
        end
    uuidT_max_value(::AbstractUuidT) = begin
            Int64(9223372036854775807)
        end
    uuidT_max_value(::Type{<:AbstractUuidT}) = begin
            Int64(9223372036854775807)
        end
end
begin
    @inline function uuidT(m::Decoder)
            return decode_array(Int64, m.buffer, m.offset + 0, 2)
        end
    @inline function uuidT!(m::Encoder)
            return encode_array(Int64, m.buffer, m.offset + 0, 2)
        end
    @inline function uuidT!(m::Encoder, val)
            copyto!(uuidT!(m), val)
        end
    export uuidT, uuidT!
end
export AbstractUuidT, Decoder, Encoder
end
module CupHolderCountT
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
abstract type AbstractCupHolderCountT <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractCupHolderCountT
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractCupHolderCountT
    buffer::T
    offset::Int64
end
@inline function Decoder(buffer::AbstractArray{UInt8})
        Decoder(buffer, Int64(0), UInt16(0x0001))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0x0001))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_encoded_length(::AbstractCupHolderCountT) = begin
        UInt16(1)
    end
sbe_encoded_length(::Type{<:AbstractCupHolderCountT}) = begin
        UInt16(1)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0001)
    end
Base.sizeof(m::AbstractCupHolderCountT) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractCupHolderCountT)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractCupHolderCountT)
    print(io, "CupHolderCountT", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    cupHolderCountT_id(::AbstractCupHolderCountT) = begin
            UInt16(0xffff)
        end
    cupHolderCountT_id(::Type{<:AbstractCupHolderCountT}) = begin
            UInt16(0xffff)
        end
    cupHolderCountT_since_version(::AbstractCupHolderCountT) = begin
            UInt16(1)
        end
    cupHolderCountT_since_version(::Type{<:AbstractCupHolderCountT}) = begin
            UInt16(1)
        end
    cupHolderCountT_in_acting_version(m::AbstractCupHolderCountT) = begin
            m.acting_version >= UInt16(1)
        end
    cupHolderCountT_encoding_offset(::AbstractCupHolderCountT) = begin
            Int(0)
        end
    cupHolderCountT_encoding_offset(::Type{<:AbstractCupHolderCountT}) = begin
            Int(0)
        end
    cupHolderCountT_encoding_length(::AbstractCupHolderCountT) = begin
            Int(1)
        end
    cupHolderCountT_encoding_length(::Type{<:AbstractCupHolderCountT}) = begin
            Int(1)
        end
    cupHolderCountT_null_value(::AbstractCupHolderCountT) = begin
            UInt8(0xff)
        end
    cupHolderCountT_null_value(::Type{<:AbstractCupHolderCountT}) = begin
            UInt8(0xff)
        end
    cupHolderCountT_min_value(::AbstractCupHolderCountT) = begin
            UInt8(0x00)
        end
    cupHolderCountT_min_value(::Type{<:AbstractCupHolderCountT}) = begin
            UInt8(0x00)
        end
    cupHolderCountT_max_value(::AbstractCupHolderCountT) = begin
            UInt8(0xff)
        end
    cupHolderCountT_max_value(::Type{<:AbstractCupHolderCountT}) = begin
            UInt8(0xff)
        end
end
begin
    @inline function cupHolderCountT(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline cupHolderCountT!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, val)
            end
    export cupHolderCountT, cupHolderCountT!
end
export AbstractCupHolderCountT, Decoder, Encoder
end
module Car
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
using ..Model
using ..BooleanType
using ..GroupSizeEncoding
using ..Engine
using ..OptionalExtras
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractCar{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractCar{T}
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
        position_ptr[] = offset + UInt16(62)
        new{T}(buffer, offset, position_ptr, UInt16(62), UInt16(0x0001))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractCar{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 62
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
        MessageHeader.blockLength!(header, UInt16(62))
        MessageHeader.templateId!(header, UInt16(0x0001))
        MessageHeader.schemaId!(header, UInt16(0x0001))
        MessageHeader.version!(header, UInt16(0x0001))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    serialNumber_id(::AbstractCar) = begin
            UInt16(0x0001)
        end
    serialNumber_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    serialNumber_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    serialNumber_encoding_offset(::AbstractCar) = begin
            0
        end
    serialNumber_encoding_length(::AbstractCar) = begin
            8
        end
    serialNumber_null_value(::AbstractCar) = begin
            0xffffffffffffffff
        end
    serialNumber_min_value(::AbstractCar) = begin
            0x0000000000000000
        end
    serialNumber_max_value(::AbstractCar) = begin
            0xfffffffffffffffe
        end
    serialNumber_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0001)
        end
    serialNumber_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    serialNumber_encoding_offset(::Type{<:AbstractCar}) = begin
            0
        end
    serialNumber_encoding_length(::Type{<:AbstractCar}) = begin
            8
        end
    serialNumber_null_value(::Type{<:AbstractCar}) = begin
            0xffffffffffffffff
        end
    serialNumber_min_value(::Type{<:AbstractCar}) = begin
            0x0000000000000000
        end
    serialNumber_max_value(::Type{<:AbstractCar}) = begin
            0xfffffffffffffffe
        end
    function serialNumber_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function serialNumber_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export serialNumber_id, serialNumber_since_version, serialNumber_in_acting_version, serialNumber_encoding_offset, serialNumber_encoding_length
    export serialNumber_null_value, serialNumber_min_value, serialNumber_max_value, serialNumber_meta_attribute
end
begin
    @inline function serialNumber(m::Decoder)
            return decode_value(UInt64, m.buffer, m.offset + 0)
        end
    @inline serialNumber!(m::Encoder, value) = begin
                encode_value(UInt64, m.buffer, m.offset + 0, value)
            end
end
begin
    export serialNumber, serialNumber!
end
begin
    modelYear_id(::AbstractCar) = begin
            UInt16(0x0002)
        end
    modelYear_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    modelYear_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    modelYear_encoding_offset(::AbstractCar) = begin
            8
        end
    modelYear_encoding_length(::AbstractCar) = begin
            2
        end
    modelYear_null_value(::AbstractCar) = begin
            0xffff
        end
    modelYear_min_value(::AbstractCar) = begin
            0x0000
        end
    modelYear_max_value(::AbstractCar) = begin
            0xfffe
        end
    modelYear_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0002)
        end
    modelYear_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    modelYear_encoding_offset(::Type{<:AbstractCar}) = begin
            8
        end
    modelYear_encoding_length(::Type{<:AbstractCar}) = begin
            2
        end
    modelYear_null_value(::Type{<:AbstractCar}) = begin
            0xffff
        end
    modelYear_min_value(::Type{<:AbstractCar}) = begin
            0x0000
        end
    modelYear_max_value(::Type{<:AbstractCar}) = begin
            0xfffe
        end
    function modelYear_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function modelYear_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export modelYear_id, modelYear_since_version, modelYear_in_acting_version, modelYear_encoding_offset, modelYear_encoding_length
    export modelYear_null_value, modelYear_min_value, modelYear_max_value, modelYear_meta_attribute
end
begin
    @inline function modelYear(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 8)
        end
    @inline modelYear!(m::Encoder, value) = begin
                encode_value(UInt16, m.buffer, m.offset + 8, value)
            end
end
begin
    export modelYear, modelYear!
end
begin
    available_id(::AbstractCar) = begin
            UInt16(0x0003)
        end
    available_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    available_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    available_encoding_offset(::AbstractCar) = begin
            10
        end
    available_encoding_length(::AbstractCar) = begin
            1
        end
    available_null_value(::AbstractCar) = begin
            0xff
        end
    available_min_value(::AbstractCar) = begin
            0x00
        end
    available_max_value(::AbstractCar) = begin
            0xff
        end
    available_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0003)
        end
    available_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    available_encoding_offset(::Type{<:AbstractCar}) = begin
            10
        end
    available_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    available_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    available_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    available_max_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    function available_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function available_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export available_id, available_since_version, available_in_acting_version, available_encoding_offset, available_encoding_length
    export available_null_value, available_min_value, available_max_value, available_meta_attribute
end
begin
    @inline function available(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 10)
        end
    @inline function available(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 10)
            return BooleanType.SbeEnum(raw)
        end
    @inline function available!(m::Encoder, value::BooleanType.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 10, UInt8(value))
        end
    export available, available!
end
begin
    code_id(::AbstractCar) = begin
            UInt16(0x0004)
        end
    code_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    code_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    code_encoding_offset(::AbstractCar) = begin
            11
        end
    code_encoding_length(::AbstractCar) = begin
            1
        end
    code_null_value(::AbstractCar) = begin
            0xff
        end
    code_min_value(::AbstractCar) = begin
            0x00
        end
    code_max_value(::AbstractCar) = begin
            0xff
        end
    code_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0004)
        end
    code_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    code_encoding_offset(::Type{<:AbstractCar}) = begin
            11
        end
    code_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    code_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    code_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    code_max_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    function code_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function code_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export code_id, code_since_version, code_in_acting_version, code_encoding_offset, code_encoding_length
    export code_null_value, code_min_value, code_max_value, code_meta_attribute
end
begin
    @inline function code(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 11)
        end
    @inline function code(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 11)
            return Model.SbeEnum(raw)
        end
    @inline function code!(m::Encoder, value::Model.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 11, UInt8(value))
        end
    export code, code!
end
begin
    someNumbers_id(::AbstractCar) = begin
            UInt16(0x0005)
        end
    someNumbers_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    someNumbers_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    someNumbers_encoding_offset(::AbstractCar) = begin
            12
        end
    someNumbers_encoding_length(::AbstractCar) = begin
            4
        end
    someNumbers_null_value(::AbstractCar) = begin
            0xffffffff
        end
    someNumbers_min_value(::AbstractCar) = begin
            0x00000000
        end
    someNumbers_max_value(::AbstractCar) = begin
            0xfffffffe
        end
    someNumbers_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0005)
        end
    someNumbers_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    someNumbers_encoding_offset(::Type{<:AbstractCar}) = begin
            12
        end
    someNumbers_encoding_length(::Type{<:AbstractCar}) = begin
            4
        end
    someNumbers_null_value(::Type{<:AbstractCar}) = begin
            0xffffffff
        end
    someNumbers_min_value(::Type{<:AbstractCar}) = begin
            0x00000000
        end
    someNumbers_max_value(::Type{<:AbstractCar}) = begin
            0xfffffffe
        end
    function someNumbers_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function someNumbers_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export someNumbers_id, someNumbers_since_version, someNumbers_in_acting_version, someNumbers_encoding_offset, someNumbers_encoding_length
    export someNumbers_null_value, someNumbers_min_value, someNumbers_max_value, someNumbers_meta_attribute
end
begin
    @inline function someNumbers(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 12)
        end
    @inline someNumbers!(m::Encoder, value) = begin
                encode_value(UInt32, m.buffer, m.offset + 12, value)
            end
end
begin
    export someNumbers, someNumbers!
end
begin
    vehicleCode_id(::AbstractCar) = begin
            UInt16(0x0006)
        end
    vehicleCode_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    vehicleCode_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    vehicleCode_encoding_offset(::AbstractCar) = begin
            28
        end
    vehicleCode_encoding_length(::AbstractCar) = begin
            1
        end
    vehicleCode_null_value(::AbstractCar) = begin
            0xff
        end
    vehicleCode_min_value(::AbstractCar) = begin
            0x00
        end
    vehicleCode_max_value(::AbstractCar) = begin
            0xfe
        end
    vehicleCode_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0006)
        end
    vehicleCode_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    vehicleCode_encoding_offset(::Type{<:AbstractCar}) = begin
            28
        end
    vehicleCode_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    vehicleCode_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    vehicleCode_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    vehicleCode_max_value(::Type{<:AbstractCar}) = begin
            0xfe
        end
    function vehicleCode_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function vehicleCode_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export vehicleCode_id, vehicleCode_since_version, vehicleCode_in_acting_version, vehicleCode_encoding_offset, vehicleCode_encoding_length
    export vehicleCode_null_value, vehicleCode_min_value, vehicleCode_max_value, vehicleCode_meta_attribute
end
begin
    @inline function vehicleCode(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 28)
        end
    @inline vehicleCode!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 28, value)
            end
end
begin
    export vehicleCode, vehicleCode!
end
begin
    extras_id(::AbstractCar) = begin
            UInt16(0x0007)
        end
    extras_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    extras_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    extras_encoding_offset(::AbstractCar) = begin
            34
        end
    extras_encoding_length(::AbstractCar) = begin
            1
        end
    extras_null_value(::AbstractCar) = begin
            0xff
        end
    extras_min_value(::AbstractCar) = begin
            0x00
        end
    extras_max_value(::AbstractCar) = begin
            0xff
        end
    extras_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0007)
        end
    extras_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    extras_encoding_offset(::Type{<:AbstractCar}) = begin
            34
        end
    extras_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    extras_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    extras_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    extras_max_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    function extras_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function extras_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export extras_id, extras_since_version, extras_in_acting_version, extras_encoding_offset, extras_encoding_length
    export extras_null_value, extras_min_value, extras_max_value, extras_meta_attribute
end
begin
    @inline function extras(m::Decoder)
            return OptionalExtras.Decoder(m.buffer, m.offset + 34)
        end
    @inline function extras(m::Encoder)
            return OptionalExtras.Encoder(m.buffer, m.offset + 34)
        end
    export extras
end
begin
    discountedModel_id(::AbstractCar) = begin
            UInt16(0x0008)
        end
    discountedModel_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    discountedModel_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    discountedModel_encoding_offset(::AbstractCar) = begin
            35
        end
    discountedModel_encoding_length(::AbstractCar) = begin
            1
        end
    discountedModel_null_value(::AbstractCar) = begin
            0xff
        end
    discountedModel_min_value(::AbstractCar) = begin
            0x00
        end
    discountedModel_max_value(::AbstractCar) = begin
            0xff
        end
    discountedModel_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0008)
        end
    discountedModel_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    discountedModel_encoding_offset(::Type{<:AbstractCar}) = begin
            35
        end
    discountedModel_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    discountedModel_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    discountedModel_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    discountedModel_max_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    function discountedModel_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function discountedModel_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export discountedModel_id, discountedModel_since_version, discountedModel_in_acting_version, discountedModel_encoding_offset, discountedModel_encoding_length
    export discountedModel_null_value, discountedModel_min_value, discountedModel_max_value, discountedModel_meta_attribute
end
begin
    @inline function discountedModel(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 35)
        end
    @inline function discountedModel(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 35)
            return Model.SbeEnum(raw)
        end
    @inline function discountedModel!(m::Encoder, value::Model.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 35, UInt8(value))
        end
    export discountedModel, discountedModel!
end
begin
    engine_id(::AbstractCar) = begin
            UInt16(0x0009)
        end
    engine_since_version(::AbstractCar) = begin
            UInt16(0)
        end
    engine_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    engine_encoding_offset(::AbstractCar) = begin
            35
        end
    engine_encoding_length(::AbstractCar) = begin
            10
        end
    engine_null_value(::AbstractCar) = begin
            0xff
        end
    engine_min_value(::AbstractCar) = begin
            0x00
        end
    engine_max_value(::AbstractCar) = begin
            0xff
        end
    engine_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0009)
        end
    engine_since_version(::Type{<:AbstractCar}) = begin
            UInt16(0)
        end
    engine_encoding_offset(::Type{<:AbstractCar}) = begin
            35
        end
    engine_encoding_length(::Type{<:AbstractCar}) = begin
            10
        end
    engine_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    engine_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    engine_max_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    function engine_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function engine_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export engine_id, engine_since_version, engine_in_acting_version, engine_encoding_offset, engine_encoding_length
    export engine_null_value, engine_min_value, engine_max_value, engine_meta_attribute
    @inline function engine(m::Decoder)
            return Engine.Decoder(m.buffer, m.offset + 35, m.acting_version)
        end
    @inline function engine(m::Encoder)
            return Engine.Encoder(m.buffer, m.offset + 35)
        end
    export engine
end
begin
    uuid_id(::AbstractCar) = begin
            UInt16(0x0064)
        end
    uuid_since_version(::AbstractCar) = begin
            UInt16(1)
        end
    uuid_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    uuid_encoding_offset(::AbstractCar) = begin
            45
        end
    uuid_encoding_length(::AbstractCar) = begin
            8
        end
    uuid_null_value(::AbstractCar) = begin
            9223372036854775807
        end
    uuid_min_value(::AbstractCar) = begin
            -9223372036854775808
        end
    uuid_max_value(::AbstractCar) = begin
            9223372036854775807
        end
    uuid_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0064)
        end
    uuid_since_version(::Type{<:AbstractCar}) = begin
            UInt16(1)
        end
    uuid_encoding_offset(::Type{<:AbstractCar}) = begin
            45
        end
    uuid_encoding_length(::Type{<:AbstractCar}) = begin
            8
        end
    uuid_null_value(::Type{<:AbstractCar}) = begin
            9223372036854775807
        end
    uuid_min_value(::Type{<:AbstractCar}) = begin
            -9223372036854775808
        end
    uuid_max_value(::Type{<:AbstractCar}) = begin
            9223372036854775807
        end
    function uuid_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function uuid_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export uuid_id, uuid_since_version, uuid_in_acting_version, uuid_encoding_offset, uuid_encoding_length
    export uuid_null_value, uuid_min_value, uuid_max_value, uuid_meta_attribute
end
begin
    @inline function uuid(m::Decoder)
            if m.acting_version < UInt16(1)
                return 9223372036854775807
            end
            return decode_value(Int64, m.buffer, m.offset + 45)
        end
    @inline uuid!(m::Encoder, value) = begin
                encode_value(Int64, m.buffer, m.offset + 45, value)
            end
end
begin
    export uuid, uuid!
end
begin
    cupHolderCount_id(::AbstractCar) = begin
            UInt16(0x0065)
        end
    cupHolderCount_since_version(::AbstractCar) = begin
            UInt16(1)
        end
    cupHolderCount_in_acting_version(m::AbstractCar) = begin
            sbe_acting_version(m) >= UInt16(1)
        end
    cupHolderCount_encoding_offset(::AbstractCar) = begin
            61
        end
    cupHolderCount_encoding_length(::AbstractCar) = begin
            1
        end
    cupHolderCount_null_value(::AbstractCar) = begin
            0xff
        end
    cupHolderCount_min_value(::AbstractCar) = begin
            0x00
        end
    cupHolderCount_max_value(::AbstractCar) = begin
            0xfe
        end
    cupHolderCount_id(::Type{<:AbstractCar}) = begin
            UInt16(0x0065)
        end
    cupHolderCount_since_version(::Type{<:AbstractCar}) = begin
            UInt16(1)
        end
    cupHolderCount_encoding_offset(::Type{<:AbstractCar}) = begin
            61
        end
    cupHolderCount_encoding_length(::Type{<:AbstractCar}) = begin
            1
        end
    cupHolderCount_null_value(::Type{<:AbstractCar}) = begin
            0xff
        end
    cupHolderCount_min_value(::Type{<:AbstractCar}) = begin
            0x00
        end
    cupHolderCount_max_value(::Type{<:AbstractCar}) = begin
            0xfe
        end
    function cupHolderCount_meta_attribute(::AbstractCar, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function cupHolderCount_meta_attribute(::Type{<:AbstractCar}, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export cupHolderCount_id, cupHolderCount_since_version, cupHolderCount_in_acting_version, cupHolderCount_encoding_offset, cupHolderCount_encoding_length
    export cupHolderCount_null_value, cupHolderCount_min_value, cupHolderCount_max_value, cupHolderCount_meta_attribute
end
begin
    @inline function cupHolderCount(m::Decoder)
            if m.acting_version < UInt16(1)
                return 0xff
            end
            return decode_value(UInt8, m.buffer, m.offset + 61)
        end
    @inline cupHolderCount!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 61, value)
            end
end
begin
    export cupHolderCount, cupHolderCount!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractCar) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_id(::AbstractCar) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_version(::AbstractCar) = begin
            UInt16(0x0001)
        end
    SBE.sbe_block_length(::AbstractCar) = begin
            UInt16(62)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractCar) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractCar) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractCar) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractCar) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractCar, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
module FuelFigures
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
    abstract type AbstractFuelFigures{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractFuelFigures{T}
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
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractFuelFigures{T}
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
    SBE.sbe_block_length(::AbstractFuelFigures) = begin
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
            UInt16(0x0001)
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
    speed_id(::AbstractFuelFigures) = begin
            UInt16(0x000b)
        end
    speed_since_version(::AbstractFuelFigures) = begin
            UInt16(0)
        end
    speed_in_acting_version(m::AbstractFuelFigures) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    speed_encoding_offset(::AbstractFuelFigures) = begin
            0
        end
    speed_encoding_length(::AbstractFuelFigures) = begin
            2
        end
    speed_null_value(::AbstractFuelFigures) = begin
            0xffff
        end
    speed_min_value(::AbstractFuelFigures) = begin
            0x0000
        end
    speed_max_value(::AbstractFuelFigures) = begin
            0xfffe
        end
    speed_id(::Type{<:AbstractFuelFigures}) = begin
            UInt16(0x000b)
        end
    speed_since_version(::Type{<:AbstractFuelFigures}) = begin
            UInt16(0)
        end
    speed_encoding_offset(::Type{<:AbstractFuelFigures}) = begin
            0
        end
    speed_encoding_length(::Type{<:AbstractFuelFigures}) = begin
            2
        end
    speed_null_value(::Type{<:AbstractFuelFigures}) = begin
            0xffff
        end
    speed_min_value(::Type{<:AbstractFuelFigures}) = begin
            0x0000
        end
    speed_max_value(::Type{<:AbstractFuelFigures}) = begin
            0xfffe
        end
    function speed_meta_attribute(::AbstractFuelFigures, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function speed_meta_attribute(::Type{<:AbstractFuelFigures}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export speed_id, speed_since_version, speed_in_acting_version, speed_encoding_offset, speed_encoding_length
    export speed_null_value, speed_min_value, speed_max_value, speed_meta_attribute
end
begin
    @inline function speed(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline speed!(m::Encoder, value) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, value)
            end
end
begin
    export speed, speed!
end
begin
    mpg_id(::AbstractFuelFigures) = begin
            UInt16(0x000c)
        end
    mpg_since_version(::AbstractFuelFigures) = begin
            UInt16(0)
        end
    mpg_in_acting_version(m::AbstractFuelFigures) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    mpg_encoding_offset(::AbstractFuelFigures) = begin
            2
        end
    mpg_encoding_length(::AbstractFuelFigures) = begin
            4
        end
    mpg_null_value(::AbstractFuelFigures) = begin
            Inf32
        end
    mpg_min_value(::AbstractFuelFigures) = begin
            -Inf32
        end
    mpg_max_value(::AbstractFuelFigures) = begin
            Inf32
        end
    mpg_id(::Type{<:AbstractFuelFigures}) = begin
            UInt16(0x000c)
        end
    mpg_since_version(::Type{<:AbstractFuelFigures}) = begin
            UInt16(0)
        end
    mpg_encoding_offset(::Type{<:AbstractFuelFigures}) = begin
            2
        end
    mpg_encoding_length(::Type{<:AbstractFuelFigures}) = begin
            4
        end
    mpg_null_value(::Type{<:AbstractFuelFigures}) = begin
            Inf32
        end
    mpg_min_value(::Type{<:AbstractFuelFigures}) = begin
            -Inf32
        end
    mpg_max_value(::Type{<:AbstractFuelFigures}) = begin
            Inf32
        end
    function mpg_meta_attribute(::AbstractFuelFigures, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function mpg_meta_attribute(::Type{<:AbstractFuelFigures}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export mpg_id, mpg_since_version, mpg_in_acting_version, mpg_encoding_offset, mpg_encoding_length
    export mpg_null_value, mpg_min_value, mpg_max_value, mpg_meta_attribute
end
begin
    @inline function mpg(m::Decoder)
            return decode_value(Float32, m.buffer, m.offset + 2)
        end
    @inline mpg!(m::Encoder, value) = begin
                encode_value(Float32, m.buffer, m.offset + 2, value)
            end
end
begin
    export mpg, mpg!
end
begin
    @inline function usageDescription_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function usageDescription_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_usageDescription!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = usageDescription_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function usageDescription(m::Decoder)
            len = usageDescription_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function usageDescription(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, usageDescription(m))
        end
    @inline function usageDescription(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = usageDescription(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function usageDescription(m::Decoder, ::Type{Symbol})
            return Symbol(usageDescription(m, String))
        end
    @inline function usageDescription(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, usageDescription(m)))[]
        end
    @inline function usageDescription(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, usageDescription(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function usageDescription!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            usageDescription_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function usageDescription!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            usageDescription_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function usageDescription!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            usageDescription_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function usageDescription!(m::Encoder, src::Symbol)
            return usageDescription!(m, to_string(src))
        end
    @inline function usageDescription!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return usageDescription!(m, bytes)
        end
    @inline function usageDescription!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return usageDescription!(m, bytes)
        end
end
begin
    const usageDescription_id = UInt16(0x00c8)
    const usageDescription_since_version = UInt16(0)
    const usageDescription_header_length = 5
end
begin
    export usageDescription, usageDescription!, usageDescription_length, usageDescription_length!, skip_usageDescription!
end
end
@inline function fuelFigures(m::Decoder)
        return FuelFigures.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function fuelFigures!(m::Encoder, count)
        return FuelFigures.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
fuelFigures_id(::AbstractCar) = begin
        UInt16(0x000a)
    end
fuelFigures_since_version(::AbstractCar) = begin
        UInt16(0)
    end
fuelFigures_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
fuelFigures_in_acting_version(m::Encoder) = begin
        UInt16(0x0001) >= UInt16(0)
    end
export fuelFigures, fuelFigures!, FuelFigures
module PerformanceFigures
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
    abstract type AbstractPerformanceFigures{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractPerformanceFigures{T}
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
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractPerformanceFigures{T}
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
            GroupSizeEncoding.blockLength!(dimensions, UInt16(1))
            GroupSizeEncoding.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += 4
            return Encoder(buffer, 0, position_ptr, initial_position, count, 0)
        end
end
begin
    import SBE
    using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!
    SBE.sbe_block_length(::AbstractPerformanceFigures) = begin
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
            UInt16(0x0001)
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
    octaneRating_id(::AbstractPerformanceFigures) = begin
            UInt16(0x000e)
        end
    octaneRating_since_version(::AbstractPerformanceFigures) = begin
            UInt16(0)
        end
    octaneRating_in_acting_version(m::AbstractPerformanceFigures) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    octaneRating_encoding_offset(::AbstractPerformanceFigures) = begin
            0
        end
    octaneRating_encoding_length(::AbstractPerformanceFigures) = begin
            1
        end
    octaneRating_null_value(::AbstractPerformanceFigures) = begin
            0xff
        end
    octaneRating_min_value(::AbstractPerformanceFigures) = begin
            0x00
        end
    octaneRating_max_value(::AbstractPerformanceFigures) = begin
            0xfe
        end
    octaneRating_id(::Type{<:AbstractPerformanceFigures}) = begin
            UInt16(0x000e)
        end
    octaneRating_since_version(::Type{<:AbstractPerformanceFigures}) = begin
            UInt16(0)
        end
    octaneRating_encoding_offset(::Type{<:AbstractPerformanceFigures}) = begin
            0
        end
    octaneRating_encoding_length(::Type{<:AbstractPerformanceFigures}) = begin
            1
        end
    octaneRating_null_value(::Type{<:AbstractPerformanceFigures}) = begin
            0xff
        end
    octaneRating_min_value(::Type{<:AbstractPerformanceFigures}) = begin
            0x00
        end
    octaneRating_max_value(::Type{<:AbstractPerformanceFigures}) = begin
            0xfe
        end
    function octaneRating_meta_attribute(::AbstractPerformanceFigures, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function octaneRating_meta_attribute(::Type{<:AbstractPerformanceFigures}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export octaneRating_id, octaneRating_since_version, octaneRating_in_acting_version, octaneRating_encoding_offset, octaneRating_encoding_length
    export octaneRating_null_value, octaneRating_min_value, octaneRating_max_value, octaneRating_meta_attribute
end
begin
    @inline function octaneRating(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 0)
        end
    @inline octaneRating!(m::Encoder, value) = begin
                encode_value(UInt8, m.buffer, m.offset + 0, value)
            end
end
begin
    export octaneRating, octaneRating!
end
module Acceleration
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
    abstract type AbstractAcceleration{T} <: AbstractSbeGroup end
end
begin
    mutable struct Decoder{T <: AbstractArray{UInt8}} <: AbstractAcceleration{T}
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
    mutable struct Encoder{T <: AbstractArray{UInt8}} <: AbstractAcceleration{T}
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
    SBE.sbe_block_length(::AbstractAcceleration) = begin
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
            UInt16(0x0001)
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
    mph_id(::AbstractAcceleration) = begin
            UInt16(0x0010)
        end
    mph_since_version(::AbstractAcceleration) = begin
            UInt16(0)
        end
    mph_in_acting_version(m::AbstractAcceleration) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    mph_encoding_offset(::AbstractAcceleration) = begin
            0
        end
    mph_encoding_length(::AbstractAcceleration) = begin
            2
        end
    mph_null_value(::AbstractAcceleration) = begin
            0xffff
        end
    mph_min_value(::AbstractAcceleration) = begin
            0x0000
        end
    mph_max_value(::AbstractAcceleration) = begin
            0xfffe
        end
    mph_id(::Type{<:AbstractAcceleration}) = begin
            UInt16(0x0010)
        end
    mph_since_version(::Type{<:AbstractAcceleration}) = begin
            UInt16(0)
        end
    mph_encoding_offset(::Type{<:AbstractAcceleration}) = begin
            0
        end
    mph_encoding_length(::Type{<:AbstractAcceleration}) = begin
            2
        end
    mph_null_value(::Type{<:AbstractAcceleration}) = begin
            0xffff
        end
    mph_min_value(::Type{<:AbstractAcceleration}) = begin
            0x0000
        end
    mph_max_value(::Type{<:AbstractAcceleration}) = begin
            0xfffe
        end
    function mph_meta_attribute(::AbstractAcceleration, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function mph_meta_attribute(::Type{<:AbstractAcceleration}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export mph_id, mph_since_version, mph_in_acting_version, mph_encoding_offset, mph_encoding_length
    export mph_null_value, mph_min_value, mph_max_value, mph_meta_attribute
end
begin
    @inline function mph(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline mph!(m::Encoder, value) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, value)
            end
end
begin
    export mph, mph!
end
begin
    seconds_id(::AbstractAcceleration) = begin
            UInt16(0x0011)
        end
    seconds_since_version(::AbstractAcceleration) = begin
            UInt16(0)
        end
    seconds_in_acting_version(m::AbstractAcceleration) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    seconds_encoding_offset(::AbstractAcceleration) = begin
            2
        end
    seconds_encoding_length(::AbstractAcceleration) = begin
            4
        end
    seconds_null_value(::AbstractAcceleration) = begin
            Inf32
        end
    seconds_min_value(::AbstractAcceleration) = begin
            -Inf32
        end
    seconds_max_value(::AbstractAcceleration) = begin
            Inf32
        end
    seconds_id(::Type{<:AbstractAcceleration}) = begin
            UInt16(0x0011)
        end
    seconds_since_version(::Type{<:AbstractAcceleration}) = begin
            UInt16(0)
        end
    seconds_encoding_offset(::Type{<:AbstractAcceleration}) = begin
            2
        end
    seconds_encoding_length(::Type{<:AbstractAcceleration}) = begin
            4
        end
    seconds_null_value(::Type{<:AbstractAcceleration}) = begin
            Inf32
        end
    seconds_min_value(::Type{<:AbstractAcceleration}) = begin
            -Inf32
        end
    seconds_max_value(::Type{<:AbstractAcceleration}) = begin
            Inf32
        end
    function seconds_meta_attribute(::AbstractAcceleration, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function seconds_meta_attribute(::Type{<:AbstractAcceleration}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export seconds_id, seconds_since_version, seconds_in_acting_version, seconds_encoding_offset, seconds_encoding_length
    export seconds_null_value, seconds_min_value, seconds_max_value, seconds_meta_attribute
end
begin
    @inline function seconds(m::Decoder)
            return decode_value(Float32, m.buffer, m.offset + 2)
        end
    @inline seconds!(m::Encoder, value) = begin
                encode_value(Float32, m.buffer, m.offset + 2, value)
            end
end
begin
    export seconds, seconds!
end
end
@inline function acceleration(m::Decoder)
        return Acceleration.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function acceleration!(m::Encoder, count)
        return Acceleration.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
acceleration_id(::AbstractPerformanceFigures) = begin
        UInt16(0x000f)
    end
acceleration_since_version(::AbstractPerformanceFigures) = begin
        UInt16(0)
    end
acceleration_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
acceleration_in_acting_version(m::Encoder) = begin
        UInt16(0x0001) >= UInt16(0)
    end
export acceleration, acceleration!, Acceleration
end
@inline function performanceFigures(m::Decoder)
        return PerformanceFigures.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
    end
@inline function performanceFigures!(m::Encoder, count)
        return PerformanceFigures.Encoder(m.buffer, count, sbe_position_ptr(m))
    end
performanceFigures_id(::AbstractCar) = begin
        UInt16(0x000d)
    end
performanceFigures_since_version(::AbstractCar) = begin
        UInt16(0)
    end
performanceFigures_in_acting_version(m::Decoder) = begin
        m.acting_version >= UInt16(0)
    end
performanceFigures_in_acting_version(m::Encoder) = begin
        UInt16(0x0001) >= UInt16(0)
    end
export performanceFigures, performanceFigures!, PerformanceFigures
begin
    @inline function manufacturer_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function manufacturer_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_manufacturer!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = manufacturer_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function manufacturer(m::Decoder)
            len = manufacturer_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function manufacturer(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, manufacturer(m))
        end
    @inline function manufacturer(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = manufacturer(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function manufacturer(m::Decoder, ::Type{Symbol})
            return Symbol(manufacturer(m, String))
        end
    @inline function manufacturer(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, manufacturer(m)))[]
        end
    @inline function manufacturer(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, manufacturer(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function manufacturer!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            manufacturer_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function manufacturer!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            manufacturer_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function manufacturer!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            manufacturer_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function manufacturer!(m::Encoder, src::Symbol)
            return manufacturer!(m, to_string(src))
        end
    @inline function manufacturer!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return manufacturer!(m, bytes)
        end
    @inline function manufacturer!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return manufacturer!(m, bytes)
        end
end
begin
    const manufacturer_id = UInt16(0x0012)
    const manufacturer_since_version = UInt16(0)
    const manufacturer_header_length = 5
end
begin
    export manufacturer, manufacturer!, manufacturer_length, manufacturer_length!, skip_manufacturer!
end
begin
    @inline function model_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function model_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_model!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = model_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function model(m::Decoder)
            len = model_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function model(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, model(m))
        end
    @inline function model(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = model(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function model(m::Decoder, ::Type{Symbol})
            return Symbol(model(m, String))
        end
    @inline function model(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, model(m)))[]
        end
    @inline function model(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, model(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function model!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            model_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function model!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            model_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function model!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            model_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function model!(m::Encoder, src::Symbol)
            return model!(m, to_string(src))
        end
    @inline function model!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return model!(m, bytes)
        end
    @inline function model!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return model!(m, bytes)
        end
end
begin
    const model_id = UInt16(0x0013)
    const model_since_version = UInt16(0)
    const model_header_length = 5
end
begin
    export model, model!, model_length, model_length!, skip_model!
end
begin
    @inline function activationCode_length(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            return decode_value(UInt32, m.buffer, m.position_ptr[])
        end
end
begin
    @inline function activationCode_length!(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value(UInt32, m.buffer, m.position_ptr[], convert(UInt32, n))
        end
end
begin
    @inline function skip_activationCode!(m::Union{AbstractSbeMessage, AbstractSbeGroup})
            len = activationCode_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return len
        end
end
begin
    @inline function activationCode(m::Decoder)
            len = activationCode_length(m)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function activationCode(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, activationCode(m))
        end
    @inline function activationCode(m::Decoder, ::Type{T}) where T <: AbstractString
            bytes = activationCode(m)
            last_nonzero = findlast(!iszero, bytes)
            return StringView(if last_nonzero === nothing
                        ""
                    else
                        view(bytes, 1:last_nonzero)
                    end)
        end
    @inline function activationCode(m::Decoder, ::Type{Symbol})
            return Symbol(activationCode(m, String))
        end
    @inline function activationCode(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, activationCode(m)))[]
        end
    @inline function activationCode(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            arr = reinterpret(T, activationCode(m))
            return ntuple((i->begin
                            arr[i]
                        end), Val(N))
        end
end
begin
    @inline function activationCode!(m::Encoder, src::AbstractVector{UInt8})
            len = Base.length(src)
            activationCode_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, src)
            return m
        end
    @inline function activationCode!(m::Encoder, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            activationCode_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function activationCode!(m::Encoder, src::AbstractArray{T}) where T <: Real
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            activationCode_length!(m, len)
            pos = m.position_ptr[] + 5
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, bytes)
            return m
        end
    @inline function activationCode!(m::Encoder, src::Symbol)
            return activationCode!(m, to_string(src))
        end
    @inline function activationCode!(m::Encoder, src::NTuple{N, T}) where {N, T <: Real}
            bytes = reinterpret(UInt8, collect(src))
            return activationCode!(m, bytes)
        end
    @inline function activationCode!(m::Encoder, src::T) where T <: Real
            bytes = reinterpret(UInt8, [src])
            return activationCode!(m, bytes)
        end
end
begin
    const activationCode_id = UInt16(0x0014)
    const activationCode_since_version = UInt16(0)
    const activationCode_header_length = 5
end
begin
    export activationCode, activationCode!, activationCode_length, activationCode_length!, skip_activationCode!
end
end
export BoostType, BooleanType, Model, BoostType, OptionalExtras, MessageHeader, GroupSizeEncoding, VarStringEncoding, VarAsciiEncoding, VarDataEncoding, ModelYear, VehicleCode, Ron, SomeNumbers, Percentage, Booster, Engine, UuidT, CupHolderCountT, Car
end