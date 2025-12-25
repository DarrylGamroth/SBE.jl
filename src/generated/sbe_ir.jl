module UkCoRealLogicSbeIrGenerated
using EnumX
using StringViews
@inline function rstrip_nul(a::Union{AbstractString, AbstractArray})
        pos = findfirst(iszero, a)
        len = if pos !== nothing
                pos - 1
            else
                Base.length(a)
            end
        return view(a, 1:len)
    end
@enumx T = SbeEnum ByteOrderCodec::UInt8 begin
        SBE_LITTLE_ENDIAN = 0
        SBE_BIG_ENDIAN = 1
        NULL_VALUE = UInt8(0xff)
    end
@enumx T = SbeEnum PresenceCodec::UInt8 begin
        SBE_REQUIRED = 0
        SBE_OPTIONAL = 1
        SBE_CONSTANT = 2
        NULL_VALUE = UInt8(0xff)
    end
@enumx T = SbeEnum PrimitiveTypeCodec::UInt8 begin
        NONE = 0
        CHAR = 1
        INT8 = 2
        INT16 = 3
        INT32 = 4
        INT64 = 5
        UINT8 = 6
        UINT16 = 7
        UINT32 = 8
        UINT64 = 9
        FLOAT = 10
        DOUBLE = 11
        NULL_VALUE = UInt8(0xff)
    end
@enumx T = SbeEnum SignalCodec::UInt8 begin
        BEGIN_MESSAGE = 1
        END_MESSAGE = 2
        BEGIN_COMPOSITE = 3
        END_COMPOSITE = 4
        BEGIN_FIELD = 5
        END_FIELD = 6
        BEGIN_GROUP = 7
        END_GROUP = 8
        BEGIN_ENUM = 9
        VALID_VALUE = 10
        END_ENUM = 11
        BEGIN_SET = 12
        CHOICE = 13
        END_SET = 14
        BEGIN_VAR_DATA = 15
        END_VAR_DATA = 16
        ENCODING = 17
        NULL_VALUE = UInt8(0xff)
    end
module MessageHeader
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
import SBE: sbe_buffer, sbe_offset, sbe_acting_version, sbe_encoded_length
import SBE: sbe_schema_id, sbe_schema_version
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
        Decoder(buffer, Int64(0), UInt16(0))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_buffer(m::AbstractMessageHeader) = begin
        m.buffer
    end
sbe_offset(m::AbstractMessageHeader) = begin
        m.offset
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
        UInt16(0)
    end
sbe_schema_id(::AbstractMessageHeader) = begin
        UInt16(1)
    end
sbe_schema_id(::Type{<:AbstractMessageHeader}) = begin
        UInt16(1)
    end
sbe_schema_version(::AbstractMessageHeader) = begin
        UInt16(0)
    end
sbe_schema_version(::Type{<:AbstractMessageHeader}) = begin
        UInt16(0)
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
            UInt16(65535)
        end
    blockLength_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65535)
        end
    blockLength_min_value(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    blockLength_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    blockLength_max_value(::AbstractMessageHeader) = begin
            UInt16(65534)
        end
    blockLength_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65534)
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
            UInt16(65535)
        end
    templateId_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65535)
        end
    templateId_min_value(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    templateId_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    templateId_max_value(::AbstractMessageHeader) = begin
            UInt16(65534)
        end
    templateId_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65534)
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
            UInt16(65535)
        end
    schemaId_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65535)
        end
    schemaId_min_value(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    schemaId_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    schemaId_max_value(::AbstractMessageHeader) = begin
            UInt16(65534)
        end
    schemaId_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65534)
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
            UInt16(65535)
        end
    version_null_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65535)
        end
    version_min_value(::AbstractMessageHeader) = begin
            UInt16(0)
        end
    version_min_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(0)
        end
    version_max_value(::AbstractMessageHeader) = begin
            UInt16(65534)
        end
    version_max_value(::Type{<:AbstractMessageHeader}) = begin
            UInt16(65534)
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
module VarDataEncoding
using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
import SBE: value, value!
import SBE: sbe_buffer, sbe_offset, sbe_acting_version, sbe_encoded_length
import SBE: sbe_schema_id, sbe_schema_version
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
        Decoder(buffer, Int64(0), UInt16(0))
    end
@inline function Decoder(buffer::AbstractArray{UInt8}, offset::Integer)
        Decoder(buffer, Int64(offset), UInt16(0))
    end
@inline function Encoder(buffer::AbstractArray{UInt8})
        Encoder(buffer, Int64(0))
    end
sbe_buffer(m::AbstractVarDataEncoding) = begin
        m.buffer
    end
sbe_offset(m::AbstractVarDataEncoding) = begin
        m.offset
    end
sbe_encoded_length(::AbstractVarDataEncoding) = begin
        UInt16(-1)
    end
sbe_encoded_length(::Type{<:AbstractVarDataEncoding}) = begin
        UInt16(-1)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0)
    end
sbe_schema_id(::AbstractVarDataEncoding) = begin
        UInt16(1)
    end
sbe_schema_id(::Type{<:AbstractVarDataEncoding}) = begin
        UInt16(1)
    end
sbe_schema_version(::AbstractVarDataEncoding) = begin
        UInt16(0)
    end
sbe_schema_version(::Type{<:AbstractVarDataEncoding}) = begin
        UInt16(0)
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
            Int(2)
        end
    length_encoding_length(::Type{<:AbstractVarDataEncoding}) = begin
            Int(2)
        end
    length_null_value(::AbstractVarDataEncoding) = begin
            UInt16(65535)
        end
    length_null_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(65535)
        end
    length_min_value(::AbstractVarDataEncoding) = begin
            UInt16(0)
        end
    length_min_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(0)
        end
    length_max_value(::AbstractVarDataEncoding) = begin
            UInt16(65534)
        end
    length_max_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt16(65534)
        end
end
begin
    @inline function length(m::Decoder)
            return decode_value(UInt16, m.buffer, m.offset + 0)
        end
    @inline length!(m::Encoder, val) = begin
                encode_value(UInt16, m.buffer, m.offset + 0, val)
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
            Int(2)
        end
    varData_encoding_offset(::Type{<:AbstractVarDataEncoding}) = begin
            Int(2)
        end
    varData_encoding_length(::AbstractVarDataEncoding) = begin
            Int(-1)
        end
    varData_encoding_length(::Type{<:AbstractVarDataEncoding}) = begin
            Int(-1)
        end
    varData_null_value(::AbstractVarDataEncoding) = begin
            UInt8(255)
        end
    varData_null_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(255)
        end
    varData_min_value(::AbstractVarDataEncoding) = begin
            UInt8(0)
        end
    varData_min_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(0)
        end
    varData_max_value(::AbstractVarDataEncoding) = begin
            UInt8(254)
        end
    varData_max_value(::Type{<:AbstractVarDataEncoding}) = begin
            UInt8(254)
        end
end
begin
    @inline function varData(m::Decoder)
            return decode_value(UInt8, m.buffer, m.offset + 2)
        end
    @inline varData!(m::Encoder, val) = begin
                encode_value(UInt8, m.buffer, m.offset + 2, val)
            end
    export varData, varData!
end
export AbstractVarDataEncoding, Decoder, Encoder
end
module TokenCodec
export AbstractTokenCodec, Decoder, Encoder
using SBE: AbstractSbeMessage, PositionPointer, to_string
import SBE: sbe_buffer, sbe_offset, sbe_position_ptr, sbe_position, sbe_position!
import SBE: sbe_block_length, sbe_template_id, sbe_schema_id, sbe_schema_version
import SBE: sbe_acting_block_length, sbe_acting_version, sbe_rewind!
import SBE: sbe_encoded_length, sbe_decoded_length, sbe_semantic_type
abstract type AbstractTokenCodec{T} <: AbstractSbeMessage{T} end
using ..MessageHeader
using StringViews: StringView
using ..PrimitiveTypeCodec
using ..SignalCodec
using ..ByteOrderCodec
using ..PresenceCodec
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
@inline function rstrip_nul(a::Union{AbstractString, AbstractArray})
        pos = findfirst(iszero, a)
        len = if pos !== nothing
                pos - 1
            else
                Base.length(a)
            end
        return view(a, 1:len)
    end
struct Decoder{T <: AbstractArray{UInt8}, P} <: AbstractTokenCodec{T}
    buffer::T
    offset::Int64
    position_ptr::P
    acting_block_length::UInt16
    acting_version::UInt16
    function Decoder(buffer::T, offset::Integer, position_ptr::P, acting_block_length::Integer, acting_version::Integer) where {T, P}
        position_ptr[] = offset + acting_block_length
        new{T, P}(buffer, offset, position_ptr, acting_block_length, acting_version)
    end
end
struct Encoder{T <: AbstractArray{UInt8}, P, HasSbeHeader} <: AbstractTokenCodec{T}
    buffer::T
    offset::Int64
    position_ptr::P
    function Encoder(buffer::T, offset::Integer, position_ptr::P, hasSbeHeader::Bool = false) where {T, P}
        position_ptr[] = offset + UInt16(28)
        new{T, P, hasSbeHeader}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr = Ref(0), header = MessageHeader.Decoder(buffer, offset))
        if MessageHeader.templateId(header) != UInt16(2) || MessageHeader.schemaId(header) != UInt16(1)
            throw(DomainError("Template id or schema id mismatch"))
        end
        Decoder(buffer, offset + sbe_encoded_length(header), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr = Ref(0), header = MessageHeader.Encoder(buffer, offset))
        MessageHeader.blockLength!(header, UInt16(28))
        MessageHeader.templateId!(header, UInt16(2))
        MessageHeader.schemaId!(header, UInt16(1))
        MessageHeader.version!(header, UInt16(0))
        Encoder(buffer, offset + sbe_encoded_length(header), position_ptr, true)
    end
@inline function Decoder(buffer::AbstractArray, offset::Integer, position_ptr::PositionPointer)
        return Decoder(buffer, offset; position_ptr = position_ptr)
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer, position_ptr::PositionPointer)
        return Encoder(buffer, offset, position_ptr, false)
    end
sbe_buffer(m::AbstractTokenCodec) = begin
        m.buffer
    end
sbe_offset(m::AbstractTokenCodec) = begin
        m.offset
    end
sbe_position_ptr(m::AbstractTokenCodec) = begin
        m.position_ptr
    end
sbe_position(m::AbstractTokenCodec) = begin
        m.position_ptr[]
    end
sbe_position!(m::AbstractTokenCodec, position) = begin
        m.position_ptr[] = position
    end
sbe_block_length(::AbstractTokenCodec) = begin
        UInt16(28)
    end
sbe_block_length(::Type{<:AbstractTokenCodec}) = begin
        UInt16(28)
    end
sbe_template_id(::AbstractTokenCodec) = begin
        UInt16(2)
    end
sbe_template_id(::Type{<:AbstractTokenCodec}) = begin
        UInt16(2)
    end
sbe_schema_id(::AbstractTokenCodec) = begin
        UInt16(1)
    end
sbe_schema_id(::Type{<:AbstractTokenCodec}) = begin
        UInt16(1)
    end
sbe_schema_version(::AbstractTokenCodec) = begin
        UInt16(0)
    end
sbe_schema_version(::Type{<:AbstractTokenCodec}) = begin
        UInt16(0)
    end
sbe_semantic_type(::AbstractTokenCodec) = begin
        ""
    end
sbe_acting_block_length(m::Decoder) = begin
        m.acting_block_length
    end
sbe_acting_block_length(::Encoder) = begin
        UInt16(28)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0)
    end
sbe_rewind!(m::AbstractTokenCodec) = begin
        sbe_position!(m, m.offset + sbe_acting_block_length(m))
    end
sbe_encoded_length(m::AbstractTokenCodec) = begin
        sbe_position(m) - m.offset
    end
Base.sizeof(m::AbstractTokenCodec) = begin
        sbe_encoded_length(m)
    end
begin
    tokenOffset_id(::AbstractTokenCodec) = begin
            UInt16(1)
        end
    tokenOffset_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(1)
        end
    tokenOffset_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    tokenOffset_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    tokenOffset_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    tokenOffset_encoding_offset(::AbstractTokenCodec) = begin
            Int(0)
        end
    tokenOffset_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(0)
        end
    tokenOffset_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    tokenOffset_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    tokenOffset_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    tokenOffset_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    tokenOffset_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    tokenOffset_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    tokenOffset_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    tokenOffset_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function tokenOffset_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function tokenOffset_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function tokenOffset(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline tokenOffset!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 0, val)
            end
    export tokenOffset, tokenOffset!
end
begin
    tokenSize_id(::AbstractTokenCodec) = begin
            UInt16(2)
        end
    tokenSize_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(2)
        end
    tokenSize_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    tokenSize_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    tokenSize_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    tokenSize_encoding_offset(::AbstractTokenCodec) = begin
            Int(4)
        end
    tokenSize_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    tokenSize_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    tokenSize_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    tokenSize_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    tokenSize_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    tokenSize_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    tokenSize_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    tokenSize_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    tokenSize_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function tokenSize_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function tokenSize_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function tokenSize(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline tokenSize!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 4, val)
            end
    export tokenSize, tokenSize!
end
begin
    fieldId_id(::AbstractTokenCodec) = begin
            UInt16(3)
        end
    fieldId_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(3)
        end
    fieldId_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    fieldId_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    fieldId_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    fieldId_encoding_offset(::AbstractTokenCodec) = begin
            Int(8)
        end
    fieldId_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(8)
        end
    fieldId_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    fieldId_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    fieldId_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    fieldId_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    fieldId_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    fieldId_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    fieldId_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    fieldId_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function fieldId_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function fieldId_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function fieldId(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 8)
        end
    @inline fieldId!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 8, val)
            end
    export fieldId, fieldId!
end
begin
    tokenVersion_id(::AbstractTokenCodec) = begin
            UInt16(4)
        end
    tokenVersion_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(4)
        end
    tokenVersion_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    tokenVersion_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    tokenVersion_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    tokenVersion_encoding_offset(::AbstractTokenCodec) = begin
            Int(12)
        end
    tokenVersion_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(12)
        end
    tokenVersion_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    tokenVersion_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    tokenVersion_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    tokenVersion_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    tokenVersion_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    tokenVersion_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    tokenVersion_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    tokenVersion_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function tokenVersion_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function tokenVersion_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function tokenVersion(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 12)
        end
    @inline tokenVersion!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 12, val)
            end
    export tokenVersion, tokenVersion!
end
begin
    componentTokenCount_id(::AbstractTokenCodec) = begin
            UInt16(5)
        end
    componentTokenCount_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(5)
        end
    componentTokenCount_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    componentTokenCount_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    componentTokenCount_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    componentTokenCount_encoding_offset(::AbstractTokenCodec) = begin
            Int(16)
        end
    componentTokenCount_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(16)
        end
    componentTokenCount_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    componentTokenCount_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    componentTokenCount_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    componentTokenCount_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    componentTokenCount_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    componentTokenCount_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    componentTokenCount_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    componentTokenCount_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function componentTokenCount_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function componentTokenCount_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function componentTokenCount(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 16)
        end
    @inline componentTokenCount!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 16, val)
            end
    export componentTokenCount, componentTokenCount!
end
begin
    signal_id(::AbstractTokenCodec) = begin
            UInt16(6)
        end
    signal_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(6)
        end
    signal_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    signal_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    signal_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    signal_encoding_offset(::AbstractTokenCodec) = begin
            Int(20)
        end
    signal_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(20)
        end
    signal_encoding_length(::AbstractTokenCodec) = begin
            Int(1)
        end
    signal_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(1)
        end
    signal_null_value(::AbstractTokenCodec) = begin
            UInt8(255)
        end
    signal_null_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(255)
        end
    signal_min_value(::AbstractTokenCodec) = begin
            UInt8(0)
        end
    signal_min_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(0)
        end
    signal_max_value(::AbstractTokenCodec) = begin
            UInt8(254)
        end
    signal_max_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(254)
        end
end
begin
    function signal_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function signal_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function signal(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 20)
        end
    @inline function signal(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 20)
            return SignalCodec.SbeEnum(raw)
        end
    @inline function signal!(m::Encoder, value::SignalCodec.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 20, UInt8(value))
        end
    export signal, signal!
end
begin
    primitiveType_id(::AbstractTokenCodec) = begin
            UInt16(7)
        end
    primitiveType_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(7)
        end
    primitiveType_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    primitiveType_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    primitiveType_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    primitiveType_encoding_offset(::AbstractTokenCodec) = begin
            Int(21)
        end
    primitiveType_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(21)
        end
    primitiveType_encoding_length(::AbstractTokenCodec) = begin
            Int(1)
        end
    primitiveType_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(1)
        end
    primitiveType_null_value(::AbstractTokenCodec) = begin
            UInt8(255)
        end
    primitiveType_null_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(255)
        end
    primitiveType_min_value(::AbstractTokenCodec) = begin
            UInt8(0)
        end
    primitiveType_min_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(0)
        end
    primitiveType_max_value(::AbstractTokenCodec) = begin
            UInt8(254)
        end
    primitiveType_max_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(254)
        end
end
begin
    function primitiveType_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function primitiveType_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function primitiveType(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 21)
        end
    @inline function primitiveType(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 21)
            return PrimitiveTypeCodec.SbeEnum(raw)
        end
    @inline function primitiveType!(m::Encoder, value::PrimitiveTypeCodec.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 21, UInt8(value))
        end
    export primitiveType, primitiveType!
end
begin
    byteOrder_id(::AbstractTokenCodec) = begin
            UInt16(8)
        end
    byteOrder_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(8)
        end
    byteOrder_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    byteOrder_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    byteOrder_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    byteOrder_encoding_offset(::AbstractTokenCodec) = begin
            Int(22)
        end
    byteOrder_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(22)
        end
    byteOrder_encoding_length(::AbstractTokenCodec) = begin
            Int(1)
        end
    byteOrder_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(1)
        end
    byteOrder_null_value(::AbstractTokenCodec) = begin
            UInt8(255)
        end
    byteOrder_null_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(255)
        end
    byteOrder_min_value(::AbstractTokenCodec) = begin
            UInt8(0)
        end
    byteOrder_min_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(0)
        end
    byteOrder_max_value(::AbstractTokenCodec) = begin
            UInt8(254)
        end
    byteOrder_max_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(254)
        end
end
begin
    function byteOrder_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function byteOrder_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function byteOrder(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 22)
        end
    @inline function byteOrder(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 22)
            return ByteOrderCodec.SbeEnum(raw)
        end
    @inline function byteOrder!(m::Encoder, value::ByteOrderCodec.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 22, UInt8(value))
        end
    export byteOrder, byteOrder!
end
begin
    presence_id(::AbstractTokenCodec) = begin
            UInt16(9)
        end
    presence_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(9)
        end
    presence_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    presence_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    presence_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    presence_encoding_offset(::AbstractTokenCodec) = begin
            Int(23)
        end
    presence_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(23)
        end
    presence_encoding_length(::AbstractTokenCodec) = begin
            Int(1)
        end
    presence_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(1)
        end
    presence_null_value(::AbstractTokenCodec) = begin
            UInt8(255)
        end
    presence_null_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(255)
        end
    presence_min_value(::AbstractTokenCodec) = begin
            UInt8(0)
        end
    presence_min_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(0)
        end
    presence_max_value(::AbstractTokenCodec) = begin
            UInt8(254)
        end
    presence_max_value(::Type{<:AbstractTokenCodec}) = begin
            UInt8(254)
        end
end
begin
    function presence_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function presence_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function presence(m::Decoder, ::Type{Integer})
            return decode_value(UInt8, m.buffer, m.offset + 23)
        end
    @inline function presence(m::Decoder)
            raw = decode_value(UInt8, m.buffer, m.offset + 23)
            return PresenceCodec.SbeEnum(raw)
        end
    @inline function presence!(m::Encoder, value::PresenceCodec.SbeEnum)
            encode_value(UInt8, m.buffer, m.offset + 23, UInt8(value))
        end
    export presence, presence!
end
begin
    deprecated_id(::AbstractTokenCodec) = begin
            UInt16(10)
        end
    deprecated_id(::Type{<:AbstractTokenCodec}) = begin
            UInt16(10)
        end
    deprecated_since_version(::AbstractTokenCodec) = begin
            UInt16(0)
        end
    deprecated_since_version(::Type{<:AbstractTokenCodec}) = begin
            UInt16(0)
        end
    deprecated_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    deprecated_encoding_offset(::AbstractTokenCodec) = begin
            Int(24)
        end
    deprecated_encoding_offset(::Type{<:AbstractTokenCodec}) = begin
            Int(24)
        end
    deprecated_encoding_length(::AbstractTokenCodec) = begin
            Int(4)
        end
    deprecated_encoding_length(::Type{<:AbstractTokenCodec}) = begin
            Int(4)
        end
    deprecated_null_value(::AbstractTokenCodec) = begin
            Int32(-2147483648)
        end
    deprecated_null_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483648)
        end
    deprecated_min_value(::AbstractTokenCodec) = begin
            Int32(-2147483647)
        end
    deprecated_min_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(-2147483647)
        end
    deprecated_max_value(::AbstractTokenCodec) = begin
            Int32(2147483647)
        end
    deprecated_max_value(::Type{<:AbstractTokenCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function deprecated_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function deprecated_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function deprecated(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 24)
        end
    @inline deprecated!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 24, val)
            end
    export deprecated, deprecated!
end
begin
    function name_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function name_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    name_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    name_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const name_id = UInt16(11)
    const name_since_version = UInt16(0)
    const name_header_length = 2
    name_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function name_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function name_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_name!(m::Decoder)
            len = name_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function name(m::Decoder)
            len = name_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function name_buffer!(m::Encoder, len)
            name_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function name!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            name_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function name!(m::Encoder, src::NTuple)
            len = sizeof(src)
            name_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function name!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            name_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline name!(m::Encoder, src::Symbol) = begin
                name!(m, to_string(src))
            end
    @inline name!(m::Encoder, src::Real) = begin
                name!(m, Tuple(src))
            end
    @inline name!(m::Encoder, ::Nothing) = begin
                name_buffer!(m, 0)
            end
end
begin
    @inline function name(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(name(m))))
        end
    @inline function name(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(name(m, StringView))
        end
    @inline function name(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, name(m)))[]
        end
    @inline function name(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, name(m))
        end
    @inline function name(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, name(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function name(m::Decoder, ::Type{T}) where T <: Nothing
            skip_name!(m)
            return nothing
        end
end
begin
    function constValue_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function constValue_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    constValue_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    constValue_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const constValue_id = UInt16(12)
    const constValue_since_version = UInt16(0)
    const constValue_header_length = 2
    constValue_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function constValue_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function constValue_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_constValue!(m::Decoder)
            len = constValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function constValue(m::Decoder)
            len = constValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function constValue_buffer!(m::Encoder, len)
            constValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function constValue!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            constValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function constValue!(m::Encoder, src::NTuple)
            len = sizeof(src)
            constValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function constValue!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            constValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline constValue!(m::Encoder, src::Symbol) = begin
                constValue!(m, to_string(src))
            end
    @inline constValue!(m::Encoder, src::Real) = begin
                constValue!(m, Tuple(src))
            end
    @inline constValue!(m::Encoder, ::Nothing) = begin
                constValue_buffer!(m, 0)
            end
end
begin
    @inline function constValue(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(constValue(m))))
        end
    @inline function constValue(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(constValue(m, StringView))
        end
    @inline function constValue(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, constValue(m)))[]
        end
    @inline function constValue(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, constValue(m))
        end
    @inline function constValue(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, constValue(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function constValue(m::Decoder, ::Type{T}) where T <: Nothing
            skip_constValue!(m)
            return nothing
        end
end
begin
    function minValue_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function minValue_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    minValue_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    minValue_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const minValue_id = UInt16(13)
    const minValue_since_version = UInt16(0)
    const minValue_header_length = 2
    minValue_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function minValue_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function minValue_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_minValue!(m::Decoder)
            len = minValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function minValue(m::Decoder)
            len = minValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function minValue_buffer!(m::Encoder, len)
            minValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function minValue!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            minValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function minValue!(m::Encoder, src::NTuple)
            len = sizeof(src)
            minValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function minValue!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            minValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline minValue!(m::Encoder, src::Symbol) = begin
                minValue!(m, to_string(src))
            end
    @inline minValue!(m::Encoder, src::Real) = begin
                minValue!(m, Tuple(src))
            end
    @inline minValue!(m::Encoder, ::Nothing) = begin
                minValue_buffer!(m, 0)
            end
end
begin
    @inline function minValue(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(minValue(m))))
        end
    @inline function minValue(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(minValue(m, StringView))
        end
    @inline function minValue(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, minValue(m)))[]
        end
    @inline function minValue(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, minValue(m))
        end
    @inline function minValue(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, minValue(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function minValue(m::Decoder, ::Type{T}) where T <: Nothing
            skip_minValue!(m)
            return nothing
        end
end
begin
    function maxValue_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function maxValue_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    maxValue_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    maxValue_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const maxValue_id = UInt16(14)
    const maxValue_since_version = UInt16(0)
    const maxValue_header_length = 2
    maxValue_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function maxValue_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function maxValue_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_maxValue!(m::Decoder)
            len = maxValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function maxValue(m::Decoder)
            len = maxValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function maxValue_buffer!(m::Encoder, len)
            maxValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function maxValue!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            maxValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function maxValue!(m::Encoder, src::NTuple)
            len = sizeof(src)
            maxValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function maxValue!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            maxValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline maxValue!(m::Encoder, src::Symbol) = begin
                maxValue!(m, to_string(src))
            end
    @inline maxValue!(m::Encoder, src::Real) = begin
                maxValue!(m, Tuple(src))
            end
    @inline maxValue!(m::Encoder, ::Nothing) = begin
                maxValue_buffer!(m, 0)
            end
end
begin
    @inline function maxValue(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(maxValue(m))))
        end
    @inline function maxValue(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(maxValue(m, StringView))
        end
    @inline function maxValue(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, maxValue(m)))[]
        end
    @inline function maxValue(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, maxValue(m))
        end
    @inline function maxValue(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, maxValue(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function maxValue(m::Decoder, ::Type{T}) where T <: Nothing
            skip_maxValue!(m)
            return nothing
        end
end
begin
    function nullValue_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function nullValue_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    nullValue_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    nullValue_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const nullValue_id = UInt16(15)
    const nullValue_since_version = UInt16(0)
    const nullValue_header_length = 2
    nullValue_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function nullValue_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function nullValue_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_nullValue!(m::Decoder)
            len = nullValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function nullValue(m::Decoder)
            len = nullValue_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function nullValue_buffer!(m::Encoder, len)
            nullValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function nullValue!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            nullValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function nullValue!(m::Encoder, src::NTuple)
            len = sizeof(src)
            nullValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function nullValue!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            nullValue_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline nullValue!(m::Encoder, src::Symbol) = begin
                nullValue!(m, to_string(src))
            end
    @inline nullValue!(m::Encoder, src::Real) = begin
                nullValue!(m, Tuple(src))
            end
    @inline nullValue!(m::Encoder, ::Nothing) = begin
                nullValue_buffer!(m, 0)
            end
end
begin
    @inline function nullValue(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(nullValue(m))))
        end
    @inline function nullValue(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(nullValue(m, StringView))
        end
    @inline function nullValue(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, nullValue(m)))[]
        end
    @inline function nullValue(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, nullValue(m))
        end
    @inline function nullValue(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, nullValue(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function nullValue(m::Decoder, ::Type{T}) where T <: Nothing
            skip_nullValue!(m)
            return nothing
        end
end
begin
    function characterEncoding_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function characterEncoding_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    characterEncoding_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    characterEncoding_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const characterEncoding_id = UInt16(16)
    const characterEncoding_since_version = UInt16(0)
    const characterEncoding_header_length = 2
    characterEncoding_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function characterEncoding_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function characterEncoding_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_characterEncoding!(m::Decoder)
            len = characterEncoding_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function characterEncoding(m::Decoder)
            len = characterEncoding_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function characterEncoding_buffer!(m::Encoder, len)
            characterEncoding_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function characterEncoding!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            characterEncoding_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function characterEncoding!(m::Encoder, src::NTuple)
            len = sizeof(src)
            characterEncoding_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function characterEncoding!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            characterEncoding_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline characterEncoding!(m::Encoder, src::Symbol) = begin
                characterEncoding!(m, to_string(src))
            end
    @inline characterEncoding!(m::Encoder, src::Real) = begin
                characterEncoding!(m, Tuple(src))
            end
    @inline characterEncoding!(m::Encoder, ::Nothing) = begin
                characterEncoding_buffer!(m, 0)
            end
end
begin
    @inline function characterEncoding(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(characterEncoding(m))))
        end
    @inline function characterEncoding(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(characterEncoding(m, StringView))
        end
    @inline function characterEncoding(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, characterEncoding(m)))[]
        end
    @inline function characterEncoding(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, characterEncoding(m))
        end
    @inline function characterEncoding(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, characterEncoding(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function characterEncoding(m::Decoder, ::Type{T}) where T <: Nothing
            skip_characterEncoding!(m)
            return nothing
        end
end
begin
    function epoch_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function epoch_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    epoch_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    epoch_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const epoch_id = UInt16(17)
    const epoch_since_version = UInt16(0)
    const epoch_header_length = 2
    epoch_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function epoch_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function epoch_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_epoch!(m::Decoder)
            len = epoch_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function epoch(m::Decoder)
            len = epoch_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function epoch_buffer!(m::Encoder, len)
            epoch_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function epoch!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            epoch_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function epoch!(m::Encoder, src::NTuple)
            len = sizeof(src)
            epoch_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function epoch!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            epoch_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline epoch!(m::Encoder, src::Symbol) = begin
                epoch!(m, to_string(src))
            end
    @inline epoch!(m::Encoder, src::Real) = begin
                epoch!(m, Tuple(src))
            end
    @inline epoch!(m::Encoder, ::Nothing) = begin
                epoch_buffer!(m, 0)
            end
end
begin
    @inline function epoch(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(epoch(m))))
        end
    @inline function epoch(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(epoch(m, StringView))
        end
    @inline function epoch(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, epoch(m)))[]
        end
    @inline function epoch(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, epoch(m))
        end
    @inline function epoch(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, epoch(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function epoch(m::Decoder, ::Type{T}) where T <: Nothing
            skip_epoch!(m)
            return nothing
        end
end
begin
    function timeUnit_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function timeUnit_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    timeUnit_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    timeUnit_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const timeUnit_id = UInt16(18)
    const timeUnit_since_version = UInt16(0)
    const timeUnit_header_length = 2
    timeUnit_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function timeUnit_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function timeUnit_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_timeUnit!(m::Decoder)
            len = timeUnit_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function timeUnit(m::Decoder)
            len = timeUnit_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function timeUnit_buffer!(m::Encoder, len)
            timeUnit_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function timeUnit!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            timeUnit_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function timeUnit!(m::Encoder, src::NTuple)
            len = sizeof(src)
            timeUnit_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function timeUnit!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            timeUnit_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline timeUnit!(m::Encoder, src::Symbol) = begin
                timeUnit!(m, to_string(src))
            end
    @inline timeUnit!(m::Encoder, src::Real) = begin
                timeUnit!(m, Tuple(src))
            end
    @inline timeUnit!(m::Encoder, ::Nothing) = begin
                timeUnit_buffer!(m, 0)
            end
end
begin
    @inline function timeUnit(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(timeUnit(m))))
        end
    @inline function timeUnit(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(timeUnit(m, StringView))
        end
    @inline function timeUnit(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, timeUnit(m)))[]
        end
    @inline function timeUnit(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, timeUnit(m))
        end
    @inline function timeUnit(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, timeUnit(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function timeUnit(m::Decoder, ::Type{T}) where T <: Nothing
            skip_timeUnit!(m)
            return nothing
        end
end
begin
    function semanticType_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function semanticType_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    semanticType_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    semanticType_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const semanticType_id = UInt16(19)
    const semanticType_since_version = UInt16(0)
    const semanticType_header_length = 2
    semanticType_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function semanticType_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function semanticType_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_semanticType!(m::Decoder)
            len = semanticType_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function semanticType(m::Decoder)
            len = semanticType_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function semanticType_buffer!(m::Encoder, len)
            semanticType_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function semanticType!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            semanticType_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function semanticType!(m::Encoder, src::NTuple)
            len = sizeof(src)
            semanticType_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function semanticType!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            semanticType_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline semanticType!(m::Encoder, src::Symbol) = begin
                semanticType!(m, to_string(src))
            end
    @inline semanticType!(m::Encoder, src::Real) = begin
                semanticType!(m, Tuple(src))
            end
    @inline semanticType!(m::Encoder, ::Nothing) = begin
                semanticType_buffer!(m, 0)
            end
end
begin
    @inline function semanticType(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(semanticType(m))))
        end
    @inline function semanticType(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(semanticType(m, StringView))
        end
    @inline function semanticType(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, semanticType(m)))[]
        end
    @inline function semanticType(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, semanticType(m))
        end
    @inline function semanticType(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, semanticType(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function semanticType(m::Decoder, ::Type{T}) where T <: Nothing
            skip_semanticType!(m)
            return nothing
        end
end
begin
    function description_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function description_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    description_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    description_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const description_id = UInt16(20)
    const description_since_version = UInt16(0)
    const description_header_length = 2
    description_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function description_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function description_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_description!(m::Decoder)
            len = description_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function description(m::Decoder)
            len = description_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function description_buffer!(m::Encoder, len)
            description_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function description!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            description_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function description!(m::Encoder, src::NTuple)
            len = sizeof(src)
            description_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function description!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            description_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline description!(m::Encoder, src::Symbol) = begin
                description!(m, to_string(src))
            end
    @inline description!(m::Encoder, src::Real) = begin
                description!(m, Tuple(src))
            end
    @inline description!(m::Encoder, ::Nothing) = begin
                description_buffer!(m, 0)
            end
end
begin
    @inline function description(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(description(m))))
        end
    @inline function description(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(description(m, StringView))
        end
    @inline function description(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, description(m)))[]
        end
    @inline function description(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, description(m))
        end
    @inline function description(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, description(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function description(m::Decoder, ::Type{T}) where T <: Nothing
            skip_description!(m)
            return nothing
        end
end
begin
    function referencedName_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function referencedName_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    referencedName_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    referencedName_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const referencedName_id = UInt16(21)
    const referencedName_since_version = UInt16(0)
    const referencedName_header_length = 2
    referencedName_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function referencedName_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function referencedName_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_referencedName!(m::Decoder)
            len = referencedName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function referencedName(m::Decoder)
            len = referencedName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function referencedName_buffer!(m::Encoder, len)
            referencedName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function referencedName!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            referencedName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function referencedName!(m::Encoder, src::NTuple)
            len = sizeof(src)
            referencedName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function referencedName!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            referencedName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline referencedName!(m::Encoder, src::Symbol) = begin
                referencedName!(m, to_string(src))
            end
    @inline referencedName!(m::Encoder, src::Real) = begin
                referencedName!(m, Tuple(src))
            end
    @inline referencedName!(m::Encoder, ::Nothing) = begin
                referencedName_buffer!(m, 0)
            end
end
begin
    @inline function referencedName(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(referencedName(m))))
        end
    @inline function referencedName(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(referencedName(m, StringView))
        end
    @inline function referencedName(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, referencedName(m)))[]
        end
    @inline function referencedName(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, referencedName(m))
        end
    @inline function referencedName(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, referencedName(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function referencedName(m::Decoder, ::Type{T}) where T <: Nothing
            skip_referencedName!(m)
            return nothing
        end
end
begin
    function packageName_meta_attribute(::AbstractTokenCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function packageName_meta_attribute(::Type{<:AbstractTokenCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    packageName_character_encoding(::AbstractTokenCodec) = begin
            "UTF-8"
        end
    packageName_character_encoding(::Type{<:AbstractTokenCodec}) = begin
            "UTF-8"
        end
end
begin
    const packageName_id = UInt16(22)
    const packageName_since_version = UInt16(0)
    const packageName_header_length = 2
    packageName_in_acting_version(m::AbstractTokenCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function packageName_length(m::AbstractTokenCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function packageName_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_packageName!(m::Decoder)
            len = packageName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function packageName(m::Decoder)
            len = packageName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function packageName_buffer!(m::Encoder, len)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function packageName!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function packageName!(m::Encoder, src::NTuple)
            len = sizeof(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function packageName!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline packageName!(m::Encoder, src::Symbol) = begin
                packageName!(m, to_string(src))
            end
    @inline packageName!(m::Encoder, src::Real) = begin
                packageName!(m, Tuple(src))
            end
    @inline packageName!(m::Encoder, ::Nothing) = begin
                packageName_buffer!(m, 0)
            end
end
begin
    @inline function packageName(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(packageName(m))))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(packageName(m, StringView))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, packageName(m)))[]
        end
    @inline function packageName(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, packageName(m))
        end
    @inline function packageName(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, packageName(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Nothing
            skip_packageName!(m)
            return nothing
        end
end
@inline function sbe_decoded_length(m::AbstractTokenCodec)
        skipper = Decoder(sbe_buffer(m), sbe_offset(m), Ref(0), sbe_acting_block_length(m), sbe_acting_version(m))
        sbe_skip!(skipper)
        return sbe_encoded_length(skipper)
    end
@inline function sbe_skip!(m::Decoder)
        sbe_rewind!(m)
        begin
            skip_name!(m)
            skip_constValue!(m)
            skip_minValue!(m)
            skip_maxValue!(m)
            skip_nullValue!(m)
            skip_characterEncoding!(m)
            skip_epoch!(m)
            skip_timeUnit!(m)
            skip_semanticType!(m)
            skip_description!(m)
            skip_referencedName!(m)
            skip_packageName!(m)
        end
        return
    end
end
module FrameCodec
export AbstractFrameCodec, Decoder, Encoder
using SBE: AbstractSbeMessage, PositionPointer, to_string
import SBE: sbe_buffer, sbe_offset, sbe_position_ptr, sbe_position, sbe_position!
import SBE: sbe_block_length, sbe_template_id, sbe_schema_id, sbe_schema_version
import SBE: sbe_acting_block_length, sbe_acting_version, sbe_rewind!
import SBE: sbe_encoded_length, sbe_decoded_length, sbe_semantic_type
abstract type AbstractFrameCodec{T} <: AbstractSbeMessage{T} end
using ..MessageHeader
using StringViews: StringView
begin
    import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
    const encode_value = encode_value_le
    const decode_value = decode_value_le
    const encode_array = encode_array_le
    const decode_array = decode_array_le
end
@inline function rstrip_nul(a::Union{AbstractString, AbstractArray})
        pos = findfirst(iszero, a)
        len = if pos !== nothing
                pos - 1
            else
                Base.length(a)
            end
        return view(a, 1:len)
    end
struct Decoder{T <: AbstractArray{UInt8}, P} <: AbstractFrameCodec{T}
    buffer::T
    offset::Int64
    position_ptr::P
    acting_block_length::UInt16
    acting_version::UInt16
    function Decoder(buffer::T, offset::Integer, position_ptr::P, acting_block_length::Integer, acting_version::Integer) where {T, P}
        position_ptr[] = offset + acting_block_length
        new{T, P}(buffer, offset, position_ptr, acting_block_length, acting_version)
    end
end
struct Encoder{T <: AbstractArray{UInt8}, P, HasSbeHeader} <: AbstractFrameCodec{T}
    buffer::T
    offset::Int64
    position_ptr::P
    function Encoder(buffer::T, offset::Integer, position_ptr::P, hasSbeHeader::Bool = false) where {T, P}
        position_ptr[] = offset + UInt16(12)
        new{T, P, hasSbeHeader}(buffer, offset, position_ptr)
    end
end
@inline function Decoder(buffer::AbstractArray, offset::Integer = 0; position_ptr = Ref(0), header = MessageHeader.Decoder(buffer, offset))
        if MessageHeader.templateId(header) != UInt16(1) || MessageHeader.schemaId(header) != UInt16(1)
            throw(DomainError("Template id or schema id mismatch"))
        end
        Decoder(buffer, offset + sbe_encoded_length(header), position_ptr, MessageHeader.blockLength(header), MessageHeader.version(header))
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer = 0; position_ptr = Ref(0), header = MessageHeader.Encoder(buffer, offset))
        MessageHeader.blockLength!(header, UInt16(12))
        MessageHeader.templateId!(header, UInt16(1))
        MessageHeader.schemaId!(header, UInt16(1))
        MessageHeader.version!(header, UInt16(0))
        Encoder(buffer, offset + sbe_encoded_length(header), position_ptr, true)
    end
@inline function Decoder(buffer::AbstractArray, offset::Integer, position_ptr::PositionPointer)
        return Decoder(buffer, offset; position_ptr = position_ptr)
    end
@inline function Encoder(buffer::AbstractArray, offset::Integer, position_ptr::PositionPointer)
        return Encoder(buffer, offset, position_ptr, false)
    end
sbe_buffer(m::AbstractFrameCodec) = begin
        m.buffer
    end
sbe_offset(m::AbstractFrameCodec) = begin
        m.offset
    end
sbe_position_ptr(m::AbstractFrameCodec) = begin
        m.position_ptr
    end
sbe_position(m::AbstractFrameCodec) = begin
        m.position_ptr[]
    end
sbe_position!(m::AbstractFrameCodec, position) = begin
        m.position_ptr[] = position
    end
sbe_block_length(::AbstractFrameCodec) = begin
        UInt16(12)
    end
sbe_block_length(::Type{<:AbstractFrameCodec}) = begin
        UInt16(12)
    end
sbe_template_id(::AbstractFrameCodec) = begin
        UInt16(1)
    end
sbe_template_id(::Type{<:AbstractFrameCodec}) = begin
        UInt16(1)
    end
sbe_schema_id(::AbstractFrameCodec) = begin
        UInt16(1)
    end
sbe_schema_id(::Type{<:AbstractFrameCodec}) = begin
        UInt16(1)
    end
sbe_schema_version(::AbstractFrameCodec) = begin
        UInt16(0)
    end
sbe_schema_version(::Type{<:AbstractFrameCodec}) = begin
        UInt16(0)
    end
sbe_semantic_type(::AbstractFrameCodec) = begin
        ""
    end
sbe_acting_block_length(m::Decoder) = begin
        m.acting_block_length
    end
sbe_acting_block_length(::Encoder) = begin
        UInt16(12)
    end
sbe_acting_version(m::Decoder) = begin
        m.acting_version
    end
sbe_acting_version(::Encoder) = begin
        UInt16(0)
    end
sbe_rewind!(m::AbstractFrameCodec) = begin
        sbe_position!(m, m.offset + sbe_acting_block_length(m))
    end
sbe_encoded_length(m::AbstractFrameCodec) = begin
        sbe_position(m) - m.offset
    end
Base.sizeof(m::AbstractFrameCodec) = begin
        sbe_encoded_length(m)
    end
begin
    irId_id(::AbstractFrameCodec) = begin
            UInt16(1)
        end
    irId_id(::Type{<:AbstractFrameCodec}) = begin
            UInt16(1)
        end
    irId_since_version(::AbstractFrameCodec) = begin
            UInt16(0)
        end
    irId_since_version(::Type{<:AbstractFrameCodec}) = begin
            UInt16(0)
        end
    irId_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    irId_encoding_offset(::AbstractFrameCodec) = begin
            Int(0)
        end
    irId_encoding_offset(::Type{<:AbstractFrameCodec}) = begin
            Int(0)
        end
    irId_encoding_length(::AbstractFrameCodec) = begin
            Int(4)
        end
    irId_encoding_length(::Type{<:AbstractFrameCodec}) = begin
            Int(4)
        end
    irId_null_value(::AbstractFrameCodec) = begin
            Int32(-2147483648)
        end
    irId_null_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483648)
        end
    irId_min_value(::AbstractFrameCodec) = begin
            Int32(-2147483647)
        end
    irId_min_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483647)
        end
    irId_max_value(::AbstractFrameCodec) = begin
            Int32(2147483647)
        end
    irId_max_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function irId_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function irId_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function irId(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 0)
        end
    @inline irId!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 0, val)
            end
    export irId, irId!
end
begin
    irVersion_id(::AbstractFrameCodec) = begin
            UInt16(2)
        end
    irVersion_id(::Type{<:AbstractFrameCodec}) = begin
            UInt16(2)
        end
    irVersion_since_version(::AbstractFrameCodec) = begin
            UInt16(0)
        end
    irVersion_since_version(::Type{<:AbstractFrameCodec}) = begin
            UInt16(0)
        end
    irVersion_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    irVersion_encoding_offset(::AbstractFrameCodec) = begin
            Int(4)
        end
    irVersion_encoding_offset(::Type{<:AbstractFrameCodec}) = begin
            Int(4)
        end
    irVersion_encoding_length(::AbstractFrameCodec) = begin
            Int(4)
        end
    irVersion_encoding_length(::Type{<:AbstractFrameCodec}) = begin
            Int(4)
        end
    irVersion_null_value(::AbstractFrameCodec) = begin
            Int32(-2147483648)
        end
    irVersion_null_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483648)
        end
    irVersion_min_value(::AbstractFrameCodec) = begin
            Int32(-2147483647)
        end
    irVersion_min_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483647)
        end
    irVersion_max_value(::AbstractFrameCodec) = begin
            Int32(2147483647)
        end
    irVersion_max_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function irVersion_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function irVersion_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function irVersion(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 4)
        end
    @inline irVersion!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 4, val)
            end
    export irVersion, irVersion!
end
begin
    schemaVersion_id(::AbstractFrameCodec) = begin
            UInt16(3)
        end
    schemaVersion_id(::Type{<:AbstractFrameCodec}) = begin
            UInt16(3)
        end
    schemaVersion_since_version(::AbstractFrameCodec) = begin
            UInt16(0)
        end
    schemaVersion_since_version(::Type{<:AbstractFrameCodec}) = begin
            UInt16(0)
        end
    schemaVersion_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
    schemaVersion_encoding_offset(::AbstractFrameCodec) = begin
            Int(8)
        end
    schemaVersion_encoding_offset(::Type{<:AbstractFrameCodec}) = begin
            Int(8)
        end
    schemaVersion_encoding_length(::AbstractFrameCodec) = begin
            Int(4)
        end
    schemaVersion_encoding_length(::Type{<:AbstractFrameCodec}) = begin
            Int(4)
        end
    schemaVersion_null_value(::AbstractFrameCodec) = begin
            Int32(-2147483648)
        end
    schemaVersion_null_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483648)
        end
    schemaVersion_min_value(::AbstractFrameCodec) = begin
            Int32(-2147483647)
        end
    schemaVersion_min_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(-2147483647)
        end
    schemaVersion_max_value(::AbstractFrameCodec) = begin
            Int32(2147483647)
        end
    schemaVersion_max_value(::Type{<:AbstractFrameCodec}) = begin
            Int32(2147483647)
        end
end
begin
    function schemaVersion_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function schemaVersion_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    @inline function schemaVersion(m::Decoder)
            return decode_value(Int32, m.buffer, m.offset + 8)
        end
    @inline schemaVersion!(m::Encoder, val) = begin
                encode_value(Int32, m.buffer, m.offset + 8, val)
            end
    export schemaVersion, schemaVersion!
end
begin
    function packageName_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function packageName_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    packageName_character_encoding(::AbstractFrameCodec) = begin
            "UTF-8"
        end
    packageName_character_encoding(::Type{<:AbstractFrameCodec}) = begin
            "UTF-8"
        end
end
begin
    const packageName_id = UInt16(4)
    const packageName_since_version = UInt16(0)
    const packageName_header_length = 2
    packageName_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function packageName_length(m::AbstractFrameCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function packageName_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_packageName!(m::Decoder)
            len = packageName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function packageName(m::Decoder)
            len = packageName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function packageName_buffer!(m::Encoder, len)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function packageName!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function packageName!(m::Encoder, src::NTuple)
            len = sizeof(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function packageName!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            packageName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline packageName!(m::Encoder, src::Symbol) = begin
                packageName!(m, to_string(src))
            end
    @inline packageName!(m::Encoder, src::Real) = begin
                packageName!(m, Tuple(src))
            end
    @inline packageName!(m::Encoder, ::Nothing) = begin
                packageName_buffer!(m, 0)
            end
end
begin
    @inline function packageName(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(packageName(m))))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(packageName(m, StringView))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, packageName(m)))[]
        end
    @inline function packageName(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, packageName(m))
        end
    @inline function packageName(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, packageName(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function packageName(m::Decoder, ::Type{T}) where T <: Nothing
            skip_packageName!(m)
            return nothing
        end
end
begin
    function namespaceName_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function namespaceName_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    namespaceName_character_encoding(::AbstractFrameCodec) = begin
            "UTF-8"
        end
    namespaceName_character_encoding(::Type{<:AbstractFrameCodec}) = begin
            "UTF-8"
        end
end
begin
    const namespaceName_id = UInt16(5)
    const namespaceName_since_version = UInt16(0)
    const namespaceName_header_length = 2
    namespaceName_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function namespaceName_length(m::AbstractFrameCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function namespaceName_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_namespaceName!(m::Decoder)
            len = namespaceName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function namespaceName(m::Decoder)
            len = namespaceName_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function namespaceName_buffer!(m::Encoder, len)
            namespaceName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function namespaceName!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            namespaceName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function namespaceName!(m::Encoder, src::NTuple)
            len = sizeof(src)
            namespaceName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function namespaceName!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            namespaceName_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline namespaceName!(m::Encoder, src::Symbol) = begin
                namespaceName!(m, to_string(src))
            end
    @inline namespaceName!(m::Encoder, src::Real) = begin
                namespaceName!(m, Tuple(src))
            end
    @inline namespaceName!(m::Encoder, ::Nothing) = begin
                namespaceName_buffer!(m, 0)
            end
end
begin
    @inline function namespaceName(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(namespaceName(m))))
        end
    @inline function namespaceName(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(namespaceName(m, StringView))
        end
    @inline function namespaceName(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, namespaceName(m)))[]
        end
    @inline function namespaceName(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, namespaceName(m))
        end
    @inline function namespaceName(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, namespaceName(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function namespaceName(m::Decoder, ::Type{T}) where T <: Nothing
            skip_namespaceName!(m)
            return nothing
        end
end
begin
    function semanticVersion_meta_attribute(::AbstractFrameCodec, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
    function semanticVersion_meta_attribute(::Type{<:AbstractFrameCodec}, meta_attribute)
        meta_attribute === :presence && return Symbol("required")
        meta_attribute === :semanticType && return Symbol("")
        return Symbol("")
    end
end
begin
    semanticVersion_character_encoding(::AbstractFrameCodec) = begin
            "UTF-8"
        end
    semanticVersion_character_encoding(::Type{<:AbstractFrameCodec}) = begin
            "UTF-8"
        end
end
begin
    const semanticVersion_id = UInt16(6)
    const semanticVersion_since_version = UInt16(0)
    const semanticVersion_header_length = 2
    semanticVersion_in_acting_version(m::AbstractFrameCodec) = begin
            sbe_acting_version(m) >= UInt16(0)
        end
end
begin
    @inline function semanticVersion_length(m::AbstractFrameCodec)
            return decode_value(UInt16, m.buffer, sbe_position(m))
        end
end
begin
    @inline function semanticVersion_length!(m::Encoder, n)
            @boundscheck n > 65534 && throw(ArgumentError("length exceeds schema limit"))
            @boundscheck checkbounds(m.buffer, sbe_position(m) + 2 + n)
            return encode_value(UInt16, m.buffer, sbe_position(m), n)
        end
end
begin
    @inline function skip_semanticVersion!(m::Decoder)
            len = semanticVersion_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return len
        end
end
begin
    @inline function semanticVersion(m::Decoder)
            len = semanticVersion_length(m)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function semanticVersion_buffer!(m::Encoder, len)
            semanticVersion_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            return view(m.buffer, pos + 1:pos + len)
        end
end
begin
    @inline function semanticVersion!(m::Encoder, src::AbstractArray)
            len = sizeof(eltype(src)) * Base.length(src)
            semanticVersion_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(UInt8, src))
        end
end
begin
    @inline function semanticVersion!(m::Encoder, src::NTuple)
            len = sizeof(src)
            semanticVersion_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, reinterpret(NTuple{len, UInt8}, src))
        end
end
begin
    @inline function semanticVersion!(m::Encoder, src::AbstractString)
            len = sizeof(src)
            semanticVersion_length!(m, len)
            pos = sbe_position(m) + 2
            sbe_position!(m, pos + len)
            dest = view(m.buffer, pos + 1:pos + len)
            copyto!(dest, codeunits(src))
        end
end
begin
    @inline semanticVersion!(m::Encoder, src::Symbol) = begin
                semanticVersion!(m, to_string(src))
            end
    @inline semanticVersion!(m::Encoder, src::Real) = begin
                semanticVersion!(m, Tuple(src))
            end
    @inline semanticVersion!(m::Encoder, ::Nothing) = begin
                semanticVersion_buffer!(m, 0)
            end
end
begin
    @inline function semanticVersion(m::Decoder, ::Type{T}) where T <: AbstractString
            return T(StringView(rstrip_nul(semanticVersion(m))))
        end
    @inline function semanticVersion(m::Decoder, ::Type{T}) where T <: Symbol
            return Symbol(semanticVersion(m, StringView))
        end
    @inline function semanticVersion(m::Decoder, ::Type{T}) where T <: Real
            return (reinterpret(T, semanticVersion(m)))[]
        end
    @inline function semanticVersion(m::Decoder, ::Type{AbstractArray{T}}) where T <: Real
            return reinterpret(T, semanticVersion(m))
        end
    @inline function semanticVersion(m::Decoder, ::Type{NTuple{N, T}}) where {N, T <: Real}
            x = reinterpret(T, semanticVersion(m))
            return ntuple((i->begin
                            x[i]
                        end), Val(N))
        end
    @inline function semanticVersion(m::Decoder, ::Type{T}) where T <: Nothing
            skip_semanticVersion!(m)
            return nothing
        end
end
@inline function sbe_decoded_length(m::AbstractFrameCodec)
        skipper = Decoder(sbe_buffer(m), sbe_offset(m), Ref(0), sbe_acting_block_length(m), sbe_acting_version(m))
        sbe_skip!(skipper)
        return sbe_encoded_length(skipper)
    end
@inline function sbe_skip!(m::Decoder)
        sbe_rewind!(m)
        begin
            skip_packageName!(m)
            skip_namespaceName!(m)
            skip_semanticVersion!(m)
        end
        return
    end
end
end

const Uk_co_real_logic_sbe_ir_generated = UkCoRealLogicSbeIrGenerated