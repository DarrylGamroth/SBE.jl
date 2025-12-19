module Optional
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
        CANCELLED = UInt8(0x03)
        NULL_VALUE = UInt8(0xff)
    end
module OptionalUInt32
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
abstract type AbstractOptionalUInt32 <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractOptionalUInt32
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractOptionalUInt32
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
sbe_encoded_length(::AbstractOptionalUInt32) = begin
        UInt16(4)
    end
sbe_encoded_length(::Type{<:AbstractOptionalUInt32}) = begin
        UInt16(4)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractOptionalUInt32) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractOptionalUInt32)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractOptionalUInt32)
    print(io, "OptionalUInt32", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    optionalUInt32_id(::AbstractOptionalUInt32) = begin
            UInt16(0xffff)
        end
    optionalUInt32_id(::Type{<:AbstractOptionalUInt32}) = begin
            UInt16(0xffff)
        end
    optionalUInt32_since_version(::AbstractOptionalUInt32) = begin
            UInt16(0)
        end
    optionalUInt32_since_version(::Type{<:AbstractOptionalUInt32}) = begin
            UInt16(0)
        end
    optionalUInt32_in_acting_version(m::AbstractOptionalUInt32) = begin
            m.acting_version >= UInt16(0)
        end
    optionalUInt32_encoding_offset(::AbstractOptionalUInt32) = begin
            Int(0)
        end
    optionalUInt32_encoding_offset(::Type{<:AbstractOptionalUInt32}) = begin
            Int(0)
        end
    optionalUInt32_encoding_length(::AbstractOptionalUInt32) = begin
            Int(4)
        end
    optionalUInt32_encoding_length(::Type{<:AbstractOptionalUInt32}) = begin
            Int(4)
        end
    optionalUInt32_null_value(::AbstractOptionalUInt32) = begin
            UInt32(0xffffffff)
        end
    optionalUInt32_null_value(::Type{<:AbstractOptionalUInt32}) = begin
            UInt32(0xffffffff)
        end
    optionalUInt32_min_value(::AbstractOptionalUInt32) = begin
            UInt32(0x00000000)
        end
    optionalUInt32_min_value(::Type{<:AbstractOptionalUInt32}) = begin
            UInt32(0x00000000)
        end
    optionalUInt32_max_value(::AbstractOptionalUInt32) = begin
            UInt32(0xffffffff)
        end
    optionalUInt32_max_value(::Type{<:AbstractOptionalUInt32}) = begin
            UInt32(0xffffffff)
        end
end
begin
    @inline function optionalUInt32(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 0)
        end
    @inline optionalUInt32!(m::Encoder, val) = begin
                encode_value(UInt32, m.buffer, m.offset + 0, val)
            end
    export optionalUInt32, optionalUInt32!
end
export AbstractOptionalUInt32, Decoder, Encoder
end
module OptionalInt64
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
abstract type AbstractOptionalInt64 <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractOptionalInt64
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractOptionalInt64
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
sbe_encoded_length(::AbstractOptionalInt64) = begin
        UInt16(8)
    end
sbe_encoded_length(::Type{<:AbstractOptionalInt64}) = begin
        UInt16(8)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractOptionalInt64) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractOptionalInt64)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractOptionalInt64)
    print(io, "OptionalInt64", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    optionalInt64_id(::AbstractOptionalInt64) = begin
            UInt16(0xffff)
        end
    optionalInt64_id(::Type{<:AbstractOptionalInt64}) = begin
            UInt16(0xffff)
        end
    optionalInt64_since_version(::AbstractOptionalInt64) = begin
            UInt16(0)
        end
    optionalInt64_since_version(::Type{<:AbstractOptionalInt64}) = begin
            UInt16(0)
        end
    optionalInt64_in_acting_version(m::AbstractOptionalInt64) = begin
            m.acting_version >= UInt16(0)
        end
    optionalInt64_encoding_offset(::AbstractOptionalInt64) = begin
            Int(0)
        end
    optionalInt64_encoding_offset(::Type{<:AbstractOptionalInt64}) = begin
            Int(0)
        end
    optionalInt64_encoding_length(::AbstractOptionalInt64) = begin
            Int(8)
        end
    optionalInt64_encoding_length(::Type{<:AbstractOptionalInt64}) = begin
            Int(8)
        end
    optionalInt64_null_value(::AbstractOptionalInt64) = begin
            Int64(-9223372036854775808)
        end
    optionalInt64_null_value(::Type{<:AbstractOptionalInt64}) = begin
            Int64(-9223372036854775808)
        end
    optionalInt64_min_value(::AbstractOptionalInt64) = begin
            Int64(-9223372036854775808)
        end
    optionalInt64_min_value(::Type{<:AbstractOptionalInt64}) = begin
            Int64(-9223372036854775808)
        end
    optionalInt64_max_value(::AbstractOptionalInt64) = begin
            Int64(9223372036854775807)
        end
    optionalInt64_max_value(::Type{<:AbstractOptionalInt64}) = begin
            Int64(9223372036854775807)
        end
end
begin
    @inline function optionalInt64(m::Decoder)
            return decode_value(Int64, m.buffer, m.offset + 0)
        end
    @inline optionalInt64!(m::Encoder, val) = begin
                encode_value(Int64, m.buffer, m.offset + 0, val)
            end
    export optionalInt64, optionalInt64!
end
export AbstractOptionalInt64, Decoder, Encoder
end
module OptionalFloat
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
abstract type AbstractOptionalFloat <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractOptionalFloat
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractOptionalFloat
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
sbe_encoded_length(::AbstractOptionalFloat) = begin
        UInt16(4)
    end
sbe_encoded_length(::Type{<:AbstractOptionalFloat}) = begin
        UInt16(4)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractOptionalFloat) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractOptionalFloat)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractOptionalFloat)
    print(io, "OptionalFloat", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    optionalFloat_id(::AbstractOptionalFloat) = begin
            UInt16(0xffff)
        end
    optionalFloat_id(::Type{<:AbstractOptionalFloat}) = begin
            UInt16(0xffff)
        end
    optionalFloat_since_version(::AbstractOptionalFloat) = begin
            UInt16(0)
        end
    optionalFloat_since_version(::Type{<:AbstractOptionalFloat}) = begin
            UInt16(0)
        end
    optionalFloat_in_acting_version(m::AbstractOptionalFloat) = begin
            m.acting_version >= UInt16(0)
        end
    optionalFloat_encoding_offset(::AbstractOptionalFloat) = begin
            Int(0)
        end
    optionalFloat_encoding_offset(::Type{<:AbstractOptionalFloat}) = begin
            Int(0)
        end
    optionalFloat_encoding_length(::AbstractOptionalFloat) = begin
            Int(4)
        end
    optionalFloat_encoding_length(::Type{<:AbstractOptionalFloat}) = begin
            Int(4)
        end
    optionalFloat_null_value(::AbstractOptionalFloat) = begin
            Float32(NaN32)
        end
    optionalFloat_null_value(::Type{<:AbstractOptionalFloat}) = begin
            Float32(NaN32)
        end
    optionalFloat_min_value(::AbstractOptionalFloat) = begin
            Float32(-Inf32)
        end
    optionalFloat_min_value(::Type{<:AbstractOptionalFloat}) = begin
            Float32(-Inf32)
        end
    optionalFloat_max_value(::AbstractOptionalFloat) = begin
            Float32(Inf32)
        end
    optionalFloat_max_value(::Type{<:AbstractOptionalFloat}) = begin
            Float32(Inf32)
        end
end
begin
    @inline function optionalFloat(m::Decoder)
            return decode_value(Float32, m.buffer, m.offset + 0)
        end
    @inline optionalFloat!(m::Encoder, val) = begin
                encode_value(Float32, m.buffer, m.offset + 0, val)
            end
    export optionalFloat, optionalFloat!
end
export AbstractOptionalFloat, Decoder, Encoder
end
module Price
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
abstract type AbstractPrice <: AbstractSbeCompositeType end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractPrice
    buffer::T
    offset::Int64
    acting_version::UInt16
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractPrice
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
sbe_encoded_length(::AbstractPrice) = begin
        UInt16(9)
    end
sbe_encoded_length(::Type{<:AbstractPrice}) = begin
        UInt16(9)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0x0000)
    end
Base.sizeof(m::AbstractPrice) = begin
        sbe_encoded_length(m)
    end
function Base.convert(::Type{<:AbstractArray{UInt8}}, m::AbstractPrice)
    return view(m.buffer, m.offset + 1:m.offset + sbe_encoded_length(m))
end
function Base.show(io::IO, m::AbstractPrice)
    print(io, "Price", "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
end
begin
    mantissa_id(::AbstractPrice) = begin
            UInt16(0xffff)
        end
    mantissa_id(::Type{<:AbstractPrice}) = begin
            UInt16(0xffff)
        end
    mantissa_since_version(::AbstractPrice) = begin
            UInt16(0)
        end
    mantissa_since_version(::Type{<:AbstractPrice}) = begin
            UInt16(0)
        end
    mantissa_in_acting_version(m::AbstractPrice) = begin
            m.acting_version >= UInt16(0)
        end
    mantissa_encoding_offset(::AbstractPrice) = begin
            Int(0)
        end
    mantissa_encoding_offset(::Type{<:AbstractPrice}) = begin
            Int(0)
        end
    mantissa_encoding_length(::AbstractPrice) = begin
            Int(8)
        end
    mantissa_encoding_length(::Type{<:AbstractPrice}) = begin
            Int(8)
        end
    mantissa_null_value(::AbstractPrice) = begin
            Int64(-9223372036854775808)
        end
    mantissa_null_value(::Type{<:AbstractPrice}) = begin
            Int64(-9223372036854775808)
        end
    mantissa_min_value(::AbstractPrice) = begin
            Int64(-9223372036854775808)
        end
    mantissa_min_value(::Type{<:AbstractPrice}) = begin
            Int64(-9223372036854775808)
        end
    mantissa_max_value(::AbstractPrice) = begin
            Int64(9223372036854775807)
        end
    mantissa_max_value(::Type{<:AbstractPrice}) = begin
            Int64(9223372036854775807)
        end
end
begin
    @inline function mantissa(m::Decoder)
            return decode_value(Int64, m.buffer, m.offset + 0)
        end
    @inline mantissa!(m::Encoder, val) = begin
                encode_value(Int64, m.buffer, m.offset + 0, val)
            end
    export mantissa, mantissa!
end
begin
    exponent_id(::AbstractPrice) = begin
            UInt16(0xffff)
        end
    exponent_id(::Type{<:AbstractPrice}) = begin
            UInt16(0xffff)
        end
    exponent_since_version(::AbstractPrice) = begin
            UInt16(0)
        end
    exponent_since_version(::Type{<:AbstractPrice}) = begin
            UInt16(0)
        end
    exponent_in_acting_version(m::AbstractPrice) = begin
            m.acting_version >= UInt16(0)
        end
    exponent_encoding_offset(::AbstractPrice) = begin
            Int(8)
        end
    exponent_encoding_offset(::Type{<:AbstractPrice}) = begin
            Int(8)
        end
    exponent_encoding_length(::AbstractPrice) = begin
            Int(1)
        end
    exponent_encoding_length(::Type{<:AbstractPrice}) = begin
            Int(1)
        end
    exponent_null_value(::AbstractPrice) = begin
            Int8(-128)
        end
    exponent_null_value(::Type{<:AbstractPrice}) = begin
            Int8(-128)
        end
    exponent_min_value(::AbstractPrice) = begin
            Int8(-128)
        end
    exponent_min_value(::Type{<:AbstractPrice}) = begin
            Int8(-128)
        end
    exponent_max_value(::AbstractPrice) = begin
            Int8(127)
        end
    exponent_max_value(::Type{<:AbstractPrice}) = begin
            Int8(127)
        end
end
begin
    @inline function exponent(m::Decoder)
            return decode_value(Int8, m.buffer, m.offset + 8)
        end
    @inline exponent!(m::Encoder, val) = begin
                encode_value(Int8, m.buffer, m.offset + 8, val)
            end
    export exponent, exponent!
end
export AbstractPrice, Decoder, Encoder
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
module Order
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
using ..Price
using SBE: PositionPointer, to_string
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
export Decoder, Encoder
abstract type AbstractOrder{T <: AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
struct Decoder{T <: AbstractArray{UInt8}} <: AbstractOrder{T}
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
        position_ptr[] = offset + UInt16(46)
        new{T}(buffer, offset, position_ptr, UInt16(46), UInt16(0x0000))
    end
end
struct Encoder{T <: AbstractArray{UInt8}} <: AbstractOrder{T}
    buffer::T
    offset::Int64
    position_ptr::PositionPointer
    function Encoder(buffer::T, offset::Int64, position_ptr::PositionPointer) where T
        position_ptr[] = offset + 46
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
        MessageHeader.blockLength!(header, UInt16(46))
        MessageHeader.templateId!(header, UInt16(0x0001))
        MessageHeader.schemaId!(header, UInt16(0x0003))
        MessageHeader.version!(header, UInt16(0x0000))
        Encoder(buffer, Int64(offset) + Int64(MessageHeader.sbe_encoded_length(header)), position_ptr)
    end
begin
    orderId_id(::AbstractOrder) = begin
            UInt16(0x0001)
        end
    orderId_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    orderId_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    orderId_encoding_offset(::AbstractOrder) = begin
            0
        end
    orderId_encoding_length(::AbstractOrder) = begin
            8
        end
    orderId_null_value(::AbstractOrder) = begin
            0xffffffffffffffff
        end
    orderId_min_value(::AbstractOrder) = begin
            0x0000000000000000
        end
    orderId_max_value(::AbstractOrder) = begin
            0xfffffffffffffffe
        end
    orderId_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0001)
        end
    orderId_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    orderId_encoding_offset(::Type{<:AbstractOrder}) = begin
            0
        end
    orderId_encoding_length(::Type{<:AbstractOrder}) = begin
            8
        end
    orderId_null_value(::Type{<:AbstractOrder}) = begin
            0xffffffffffffffff
        end
    orderId_min_value(::Type{<:AbstractOrder}) = begin
            0x0000000000000000
        end
    orderId_max_value(::Type{<:AbstractOrder}) = begin
            0xfffffffffffffffe
        end
    function orderId_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function orderId_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export orderId_id, orderId_since_version, orderId_in_acting_version, orderId_encoding_offset, orderId_encoding_length
    export orderId_null_value, orderId_min_value, orderId_max_value, orderId_meta_attribute
end
begin
    @inline function orderId(m::Decoder)
            return decode_value(UInt64, m.buffer, m.offset + 0)
        end
    @inline orderId!(m::Encoder, value) = begin
                encode_value(UInt64, m.buffer, m.offset + 0, value)
            end
end
begin
    export orderId, orderId!
end
begin
    quantity_id(::AbstractOrder) = begin
            UInt16(0x0002)
        end
    quantity_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    quantity_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    quantity_encoding_offset(::AbstractOrder) = begin
            8
        end
    quantity_encoding_length(::AbstractOrder) = begin
            4
        end
    quantity_null_value(::AbstractOrder) = begin
            0xffffffff
        end
    quantity_min_value(::AbstractOrder) = begin
            0x00000000
        end
    quantity_max_value(::AbstractOrder) = begin
            0xfffffffe
        end
    quantity_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0002)
        end
    quantity_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    quantity_encoding_offset(::Type{<:AbstractOrder}) = begin
            8
        end
    quantity_encoding_length(::Type{<:AbstractOrder}) = begin
            4
        end
    quantity_null_value(::Type{<:AbstractOrder}) = begin
            0xffffffff
        end
    quantity_min_value(::Type{<:AbstractOrder}) = begin
            0x00000000
        end
    quantity_max_value(::Type{<:AbstractOrder}) = begin
            0xfffffffe
        end
    function quantity_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function quantity_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
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
    optionalPrice_id(::AbstractOrder) = begin
            UInt16(0x0003)
        end
    optionalPrice_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    optionalPrice_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    optionalPrice_encoding_offset(::AbstractOrder) = begin
            12
        end
    optionalPrice_encoding_length(::AbstractOrder) = begin
            4
        end
    optionalPrice_null_value(::AbstractOrder) = begin
            0xffffffff
        end
    optionalPrice_min_value(::AbstractOrder) = begin
            0x00000000
        end
    optionalPrice_max_value(::AbstractOrder) = begin
            0xfffffffe
        end
    optionalPrice_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0003)
        end
    optionalPrice_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    optionalPrice_encoding_offset(::Type{<:AbstractOrder}) = begin
            12
        end
    optionalPrice_encoding_length(::Type{<:AbstractOrder}) = begin
            4
        end
    optionalPrice_null_value(::Type{<:AbstractOrder}) = begin
            0xffffffff
        end
    optionalPrice_min_value(::Type{<:AbstractOrder}) = begin
            0x00000000
        end
    optionalPrice_max_value(::Type{<:AbstractOrder}) = begin
            0xfffffffe
        end
    function optionalPrice_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function optionalPrice_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export optionalPrice_id, optionalPrice_since_version, optionalPrice_in_acting_version, optionalPrice_encoding_offset, optionalPrice_encoding_length
    export optionalPrice_null_value, optionalPrice_min_value, optionalPrice_max_value, optionalPrice_meta_attribute
end
begin
    @inline function optionalPrice(m::Decoder)
            return decode_value(UInt32, m.buffer, m.offset + 12)
        end
    @inline optionalPrice!(m::Encoder, value) = begin
                encode_value(UInt32, m.buffer, m.offset + 12, value)
            end
end
begin
    export optionalPrice, optionalPrice!
end
begin
    optionalVolume_id(::AbstractOrder) = begin
            UInt16(0x0004)
        end
    optionalVolume_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    optionalVolume_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    optionalVolume_encoding_offset(::AbstractOrder) = begin
            16
        end
    optionalVolume_encoding_length(::AbstractOrder) = begin
            8
        end
    optionalVolume_null_value(::AbstractOrder) = begin
            9223372036854775807
        end
    optionalVolume_min_value(::AbstractOrder) = begin
            -9223372036854775808
        end
    optionalVolume_max_value(::AbstractOrder) = begin
            9223372036854775807
        end
    optionalVolume_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0004)
        end
    optionalVolume_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    optionalVolume_encoding_offset(::Type{<:AbstractOrder}) = begin
            16
        end
    optionalVolume_encoding_length(::Type{<:AbstractOrder}) = begin
            8
        end
    optionalVolume_null_value(::Type{<:AbstractOrder}) = begin
            9223372036854775807
        end
    optionalVolume_min_value(::Type{<:AbstractOrder}) = begin
            -9223372036854775808
        end
    optionalVolume_max_value(::Type{<:AbstractOrder}) = begin
            9223372036854775807
        end
    function optionalVolume_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function optionalVolume_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export optionalVolume_id, optionalVolume_since_version, optionalVolume_in_acting_version, optionalVolume_encoding_offset, optionalVolume_encoding_length
    export optionalVolume_null_value, optionalVolume_min_value, optionalVolume_max_value, optionalVolume_meta_attribute
end
begin
    @inline function optionalVolume(m::Decoder)
            return decode_value(Int64, m.buffer, m.offset + 16)
        end
    @inline optionalVolume!(m::Encoder, value) = begin
                encode_value(Int64, m.buffer, m.offset + 16, value)
            end
end
begin
    export optionalVolume, optionalVolume!
end
begin
    optionalDiscount_id(::AbstractOrder) = begin
            UInt16(0x0005)
        end
    optionalDiscount_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    optionalDiscount_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    optionalDiscount_encoding_offset(::AbstractOrder) = begin
            24
        end
    optionalDiscount_encoding_length(::AbstractOrder) = begin
            4
        end
    optionalDiscount_null_value(::AbstractOrder) = begin
            Inf32
        end
    optionalDiscount_min_value(::AbstractOrder) = begin
            -Inf32
        end
    optionalDiscount_max_value(::AbstractOrder) = begin
            Inf32
        end
    optionalDiscount_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0005)
        end
    optionalDiscount_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    optionalDiscount_encoding_offset(::Type{<:AbstractOrder}) = begin
            24
        end
    optionalDiscount_encoding_length(::Type{<:AbstractOrder}) = begin
            4
        end
    optionalDiscount_null_value(::Type{<:AbstractOrder}) = begin
            Inf32
        end
    optionalDiscount_min_value(::Type{<:AbstractOrder}) = begin
            -Inf32
        end
    optionalDiscount_max_value(::Type{<:AbstractOrder}) = begin
            Inf32
        end
    function optionalDiscount_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function optionalDiscount_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("optional")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export optionalDiscount_id, optionalDiscount_since_version, optionalDiscount_in_acting_version, optionalDiscount_encoding_offset, optionalDiscount_encoding_length
    export optionalDiscount_null_value, optionalDiscount_min_value, optionalDiscount_max_value, optionalDiscount_meta_attribute
end
begin
    @inline function optionalDiscount(m::Decoder)
            return decode_value(Float32, m.buffer, m.offset + 24)
        end
    @inline optionalDiscount!(m::Encoder, value) = begin
                encode_value(Float32, m.buffer, m.offset + 24, value)
            end
end
begin
    export optionalDiscount, optionalDiscount!
end
begin
    status_id(::AbstractOrder) = begin
            UInt16(0x0006)
        end
    status_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    status_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    status_encoding_offset(::AbstractOrder) = begin
            28
        end
    status_encoding_length(::AbstractOrder) = begin
            1
        end
    status_null_value(::AbstractOrder) = begin
            0xff
        end
    status_min_value(::AbstractOrder) = begin
            0x00
        end
    status_max_value(::AbstractOrder) = begin
            0xff
        end
    status_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0006)
        end
    status_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    status_encoding_offset(::Type{<:AbstractOrder}) = begin
            28
        end
    status_encoding_length(::Type{<:AbstractOrder}) = begin
            1
        end
    status_null_value(::Type{<:AbstractOrder}) = begin
            0xff
        end
    status_min_value(::Type{<:AbstractOrder}) = begin
            0x00
        end
    status_max_value(::Type{<:AbstractOrder}) = begin
            0xff
        end
    function status_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function status_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export status_id, status_since_version, status_in_acting_version, status_encoding_offset, status_encoding_length
    export status_null_value, status_min_value, status_max_value, status_meta_attribute
end
begin
    @inline function status(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 28)
        end
    @inline function status(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 28)
            return Status.SbeEnum(raw)
        end
    @inline function status!(m::Encoder, value::Status.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 28, UInt8(value))
        end
    export status, status!
end
begin
    limitPrice_id(::AbstractOrder) = begin
            UInt16(0x0007)
        end
    limitPrice_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    limitPrice_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    limitPrice_encoding_offset(::AbstractOrder) = begin
            29
        end
    limitPrice_encoding_length(::AbstractOrder) = begin
            9
        end
    limitPrice_null_value(::AbstractOrder) = begin
            0xff
        end
    limitPrice_min_value(::AbstractOrder) = begin
            0x00
        end
    limitPrice_max_value(::AbstractOrder) = begin
            0xff
        end
    limitPrice_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0007)
        end
    limitPrice_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    limitPrice_encoding_offset(::Type{<:AbstractOrder}) = begin
            29
        end
    limitPrice_encoding_length(::Type{<:AbstractOrder}) = begin
            9
        end
    limitPrice_null_value(::Type{<:AbstractOrder}) = begin
            0xff
        end
    limitPrice_min_value(::Type{<:AbstractOrder}) = begin
            0x00
        end
    limitPrice_max_value(::Type{<:AbstractOrder}) = begin
            0xff
        end
    function limitPrice_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function limitPrice_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export limitPrice_id, limitPrice_since_version, limitPrice_in_acting_version, limitPrice_encoding_offset, limitPrice_encoding_length
    export limitPrice_null_value, limitPrice_min_value, limitPrice_max_value, limitPrice_meta_attribute
    @inline function limitPrice(m::Decoder)
            return Price.Decoder(m.buffer, m.offset + 29, m.acting_version)
        end
    @inline function limitPrice(m::Encoder)
            return Price.Encoder(m.buffer, m.offset + 29)
        end
    export limitPrice
end
begin
    timestamp_id(::AbstractOrder) = begin
            UInt16(0x0008)
        end
    timestamp_since_version(::AbstractOrder) = begin
            UInt16(0)
        end
    timestamp_in_acting_version(m::AbstractOrder) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    timestamp_encoding_offset(::AbstractOrder) = begin
            38
        end
    timestamp_encoding_length(::AbstractOrder) = begin
            8
        end
    timestamp_null_value(::AbstractOrder) = begin
            0xffffffffffffffff
        end
    timestamp_min_value(::AbstractOrder) = begin
            0x0000000000000000
        end
    timestamp_max_value(::AbstractOrder) = begin
            0xfffffffffffffffe
        end
    timestamp_id(::Type{<:AbstractOrder}) = begin
            UInt16(0x0008)
        end
    timestamp_since_version(::Type{<:AbstractOrder}) = begin
            UInt16(0)
        end
    timestamp_encoding_offset(::Type{<:AbstractOrder}) = begin
            38
        end
    timestamp_encoding_length(::Type{<:AbstractOrder}) = begin
            8
        end
    timestamp_null_value(::Type{<:AbstractOrder}) = begin
            0xffffffffffffffff
        end
    timestamp_min_value(::Type{<:AbstractOrder}) = begin
            0x0000000000000000
        end
    timestamp_max_value(::Type{<:AbstractOrder}) = begin
            0xfffffffffffffffe
        end
    function timestamp_meta_attribute(::AbstractOrder, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function timestamp_meta_attribute(::Type{<:AbstractOrder}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    export timestamp_id, timestamp_since_version, timestamp_in_acting_version, timestamp_encoding_offset, timestamp_encoding_length
    export timestamp_null_value, timestamp_min_value, timestamp_max_value, timestamp_meta_attribute
end
begin
    @inline function timestamp(m::Decoder)
            return decode_value(UInt64, m.buffer, m.offset + 38)
        end
    @inline timestamp!(m::Encoder, value) = begin
                encode_value(UInt64, m.buffer, m.offset + 38, value)
            end
end
begin
    export timestamp, timestamp!
end
begin
    import SBE
    SBE.sbe_template_id(::AbstractOrder) = begin
            UInt16(0x0001)
        end
    SBE.sbe_schema_id(::AbstractOrder) = begin
            UInt16(0x0003)
        end
    SBE.sbe_schema_version(::AbstractOrder) = begin
            UInt16(0x0000)
        end
    SBE.sbe_block_length(::AbstractOrder) = begin
            UInt16(46)
        end
    SBE.sbe_acting_block_length(m::Decoder) = begin
            m.acting_block_length
        end
    SBE.sbe_buffer(m::AbstractOrder) = begin
            m.buffer
        end
    SBE.sbe_offset(m::AbstractOrder) = begin
            m.offset
        end
    SBE.sbe_position_ptr(m::AbstractOrder) = begin
            m.position_ptr
        end
    SBE.sbe_position(m::AbstractOrder) = begin
            m.position_ptr[]
        end
    SBE.sbe_position!(m::AbstractOrder, pos::Integer) = begin
            m.position_ptr[] = pos
        end
end
end
export Status, OptionalUInt32, OptionalInt64, OptionalFloat, Price, MessageHeader, Order
end