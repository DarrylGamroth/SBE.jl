"""
SBE Runtime Utilities

This module provides zero-copy, zero-allocation utilities for SBE message encoding/decoding.
"""

using MappedArrays

"""
Abstract base type for all SBE messages.
"""
abstract type SBEMessage end

"""
    read_value(buffer::AbstractVector{UInt8}, offset::Int, ::Type{T}) where T -> T

Read a value of type T from the buffer at the given offset (1-based).
This is a zero-copy operation that directly interprets bytes.
"""
function read_value(buffer::AbstractVector{UInt8}, offset::Int, ::Type{T}) where T
    # Ensure we don't read past the buffer
    if offset + sizeof(T) - 1 > length(buffer)
        throw(BoundsError(buffer, offset + sizeof(T) - 1))
    end
    
    # Use unsafe_load for zero-copy reading
    ptr = pointer(buffer, offset)
    return unsafe_load(Ptr{T}(ptr))
end

"""
    write_value!(buffer::AbstractVector{UInt8}, offset::Int, value::T) where T

Write a value of type T to the buffer at the given offset (1-based).
This is a zero-copy operation that directly writes bytes.
"""
function write_value!(buffer::AbstractVector{UInt8}, offset::Int, value::T) where T
    # Ensure we don't write past the buffer
    if offset + sizeof(T) - 1 > length(buffer)
        throw(BoundsError(buffer, offset + sizeof(T) - 1))
    end
    
    # Use unsafe_store! for zero-copy writing
    ptr = pointer(buffer, offset)
    unsafe_store!(Ptr{T}(ptr), value)
    return buffer
end

"""
    read_string(buffer::AbstractVector{UInt8}, offset::Int, length::Int) -> String

Read a string from the buffer. Handles null-terminated strings properly.
"""
function read_string(buffer::AbstractVector{UInt8}, offset::Int, length::Int)
    # Ensure we don't read past the buffer
    if offset + length - 1 > length(buffer)
        throw(BoundsError(buffer, offset + length - 1))
    end
    
    # Read the bytes
    byte_range = offset:(offset + length - 1)
    bytes = view(buffer, byte_range)
    
    # Find the null terminator if it exists
    null_pos = findfirst(==(0x00), bytes)
    if null_pos !== nothing
        bytes = bytes[1:(null_pos-1)]
    end
    
    return String(bytes)
end

"""
    write_string!(buffer::AbstractVector{UInt8}, offset::Int, value::String, max_length::Int)

Write a string to the buffer, padding with zeros if necessary.
"""
function write_string!(buffer::AbstractVector{UInt8}, offset::Int, value::String, max_length::Int)
    # Ensure we don't write past the buffer
    if offset + max_length - 1 > length(buffer)
        throw(BoundsError(buffer, offset + max_length - 1))
    end
    
    # Convert string to bytes
    value_bytes = codeunits(value)
    write_length = min(length(value_bytes), max_length)
    
    # Write the string bytes
    byte_range = offset:(offset + write_length - 1)
    buffer[byte_range] = value_bytes[1:write_length]
    
    # Zero out remaining space
    if write_length < max_length
        zero_range = (offset + write_length):(offset + max_length - 1)
        buffer[zero_range] .= 0x00
    end
    
    return buffer
end

"""
    message_id(::Type{T}) where T <: SBEMessage -> UInt16

Get the message ID for a message type. Must be implemented by each message type.
"""
function message_id(::Type{T}) where T <: SBEMessage
    error("message_id not implemented for type $T")
end

"""
    encode_message_header!(buffer::AbstractVector{UInt8}, offset::Int, message_id::UInt16, 
                          block_length::UInt16, version::UInt16 = 0) -> Int

Encode a standard SBE message header at the given offset.
Returns the offset after the header.
"""
function encode_message_header!(buffer::AbstractVector{UInt8}, offset::Int, message_id::UInt16, 
                               block_length::UInt16, version::UInt16 = 0)
    write_value!(buffer, offset, block_length)
    write_value!(buffer, offset + 2, message_id) 
    write_value!(buffer, offset + 4, version)
    return offset + 6  # Standard header is 6 bytes
end

"""
    decode_message_header(buffer::AbstractVector{UInt8}, offset::Int) -> (UInt16, UInt16, UInt16, Int)

Decode a standard SBE message header at the given offset.
Returns (block_length, message_id, version, next_offset).
"""
function decode_message_header(buffer::AbstractVector{UInt8}, offset::Int)
    block_length = read_value(buffer, offset, UInt16)
    message_id = read_value(buffer, offset + 2, UInt16)
    version = read_value(buffer, offset + 4, UInt16)
    return (block_length, message_id, version, offset + 6)
end

"""
    validate_buffer_size(buffer::AbstractVector{UInt8}, required_size::Int)

Validate that a buffer is large enough for the required operation.
"""
function validate_buffer_size(buffer::AbstractVector{UInt8}, required_size::Int)
    if length(buffer) < required_size
        error("Buffer too small: required $required_size bytes, got $(length(buffer)) bytes")
    end
end

"""
SBE Group Iterator

Provides zero-allocation iteration over repeating groups.
"""
struct SBEGroupIterator{T}
    buffer::AbstractVector{UInt8}
    offset::Int
    count::Int
    block_length::Int
    element_constructor::Function
end

"""
    Base.iterate(iter::SBEGroupIterator, state::Int = 1)

Iterate over group elements without allocation.
"""
function Base.iterate(iter::SBEGroupIterator{T}, state::Int = 1) where T
    if state > iter.count
        return nothing
    end
    
    element_offset = iter.offset + (state - 1) * iter.block_length
    element = iter.element_constructor(iter.buffer, element_offset)
    return (element, state + 1)
end

Base.length(iter::SBEGroupIterator) = iter.count
Base.eltype(::SBEGroupIterator{T}) where T = T

"""
    create_group_iterator(::Type{T}, buffer::AbstractVector{UInt8}, offset::Int, 
                         count::Int, block_length::Int) where T

Create a group iterator for type T.
"""
function create_group_iterator(::Type{T}, buffer::AbstractVector{UInt8}, offset::Int, 
                              count::Int, block_length::Int) where T
    constructor = (buf, off) -> T(buf, off)
    return SBEGroupIterator{T}(buffer, offset, count, block_length, constructor)
end

# Note: Julia provides built-in endian conversion functions:
# ltoh() - little endian to host
# htol() - host to little endian  
# ntoh() - network (big endian) to host
# hton() - host to network (big endian)

"""
    identity_conversion(value::T) where T -> T

Identity function for when no endian conversion is needed.
"""
@inline identity_conversion(value::T) where T = value

"""
Get endian conversion functions based on schema byte order.
Uses Julia's built-in endian conversion functions for efficiency.
"""
function get_endian_functions(schema_byte_order::String)
    if schema_byte_order == "littleEndian"
        return (ltoh, htol)  # (read_conversion, write_conversion)
    elseif schema_byte_order == "bigEndian"
        return (ntoh, hton)  # (read_conversion, write_conversion)
    else
        # Default or unknown byte order
        return (identity_conversion, identity_conversion)
    end
end

# Endian conversion utilities are handled by Julia's built-in functions:
# ltoh, htol, ntoh, hton

# Generic function declarations for extensibility
"""
Generic interface function for getting values from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value end

"""
Generic interface function for setting values in SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function value! end

"""
Generic interface function for getting meta-attributes from SBE fields.
This is extended by generated types to provide type-specific implementations.
"""
function meta_attribute end
