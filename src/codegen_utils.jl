# SBE Code Generation Utilities
#
# This file contains:
# 1. Abstract type definitions and runtime support for generated code
# 2. Code generation functions for creating SBE types and methods

using MappedArrays

# ============================================================================
# Abstract Type Definitions
# ============================================================================

"""
Base abstract type for all SBE message types.
Provides the interface for flyweight message wrappers that operate directly on byte buffers.
The type parameter T represents the buffer type (typically AbstractArray{UInt8}).
"""
abstract type AbstractSbeMessage{T} end

"""
Base abstract type for all SBE field accessors.
Represents individual fields within messages that can be read/written.
"""
abstract type AbstractSbeField end

"""
Base abstract type for all SBE group accessors.
Represents repeating groups within messages with iteration capabilities.
"""
abstract type AbstractSbeGroup end

"""
Base abstract type for all SBE variable-length data accessors.
Represents variable-length data fields like strings and binary data.
"""
abstract type AbstractSbeData end

"""
Base abstract type for SBE encoded type accessors.
Represents primitive types and arrays of primitives with endian conversion.
"""
abstract type AbstractSbeEncodedType <: AbstractSbeField end

"""
Base abstract type for SBE composite type accessors.
Represents composite types that contain multiple sub-fields.
"""
abstract type AbstractSbeCompositeType <: AbstractSbeField end

# ============================================================================
# Generic Interface Implementations for Abstract Types
# ============================================================================

"""
Common SBE interface functions implemented for all AbstractSbeMessage and AbstractSbeCompositeType types.
These provide the basic flyweight interface for accessing message properties.

All SBE message types must have these fields:
- `buffer::T` - The underlying byte buffer
- `offset::Int64` - Offset into the buffer where this message starts
- `position_ptr::PositionPointer` - Current read/write position (messages only)

All SBE composite types must have these fields:
- `buffer::T` - The underlying byte buffer
- `offset::Int64` - Offset into the buffer where this composite starts
- `acting_version::UInt16` - Version of the schema being used

These generic implementations work for any type following this pattern.
"""

# Buffer and offset access - works for all types with .buffer and .offset fields
@inline sbe_buffer(m::Union{AbstractSbeMessage, AbstractSbeCompositeType}) = m.buffer
@inline sbe_offset(m::Union{AbstractSbeMessage, AbstractSbeCompositeType}) = m.offset

# Position management - only for AbstractSbeMessage (composites don't have position_ptr)
@inline sbe_position_ptr(m::AbstractSbeMessage) = m.position_ptr
@inline sbe_position(m::AbstractSbeMessage) = m.position_ptr[]
@inline sbe_position!(m::AbstractSbeMessage, position) = (m.position_ptr[] = position)

@inline function sbe_rewind!(m::AbstractSbeMessage)
    sbe_position!(m, m.offset + sbe_acting_block_length(m))
    return m
end

@inline sbe_encoded_length(m::AbstractSbeMessage) = m.position_ptr[] - m.offset

# Acting version - different field names for messages vs composites
@inline sbe_acting_version(m::AbstractSbeCompositeType) = m.acting_version

# Note: Message-specific methods like sbe_acting_version(::AbstractSbeMessage),
# sbe_acting_block_length(::Union{AbstractSbeMessage,AbstractSbeGroup}), etc.
# are implemented by generated code for each message/group type.
# Julia will throw a MethodError if called on a type that doesn't implement them.

"""
Common group interface functions for AbstractSbeGroup types.

All SBE group types must have these fields:
- `buffer::T` - The underlying byte buffer
- `offset::Int64` - Current element offset
- `position_ptr::PositionPointer` - Shared position pointer with parent
- `count::UInt16` - Number of elements in the group
- `index::UInt16` - Current iteration index

For Decoder groups only:
- `block_length::UInt16` - Block length from dimension header
- `acting_version::UInt16` - Schema version

For Encoder groups only:
- `initial_position::Int64` - Position of dimension header

These generic implementations work for any type following this pattern.
"""

# Position management - works for all groups
@inline sbe_position(g::AbstractSbeGroup) = g.position_ptr[]
@inline sbe_position!(g::AbstractSbeGroup, position) = (g.position_ptr[] = position)
@inline sbe_position_ptr(g::AbstractSbeGroup) = g.position_ptr

# Header size is always 4 bytes for groupSizeEncoding (blockLength + numInGroup)
sbe_header_size(::AbstractSbeGroup) = 4

# Iterator protocol - works for all groups
Base.length(g::AbstractSbeGroup) = g.count
Base.isdone(g::AbstractSbeGroup, state=nothing) = g.index >= g.count

"""
    Base.iterate(g::AbstractSbeGroup, state=nothing)

Iterate over group elements, advancing position and index automatically.
Returns (group, state) for next element, or nothing when done.

IMPORTANT: Iteration must be done in order. Do not access vardata fields
from group elements after iteration completes, as the position pointer
will have moved. Use next!() for explicit control or process elements
immediately during iteration.
"""
function Base.iterate(g::AbstractSbeGroup, state=nothing)
    if g.index < g.count
        # Update decoder offset to point to current element
        current_offset = g.position_ptr[]
        g.offset = current_offset

        # Advance position to next element (fixed block only)
        # Vardata within this element will advance the position further
        g.position_ptr[] = current_offset + sbe_acting_block_length(g)
        g.index += 1

        # Return the group instance itself (like Java's next() returns 'this')
        return g, state
    else
        return nothing
    end
end

"""
    next!(g::AbstractSbeGroup)

Advance to the next element in the group (for encoding pattern).
Throws an error if already at the end of the group.
"""
@inline function next!(g::AbstractSbeGroup)
    if g.index >= g.count
        error("index >= count")
    end
    # Use direct field access for performance
    g.offset = g.position_ptr[]
    g.position_ptr[] = g.offset + sbe_acting_block_length(g)
    g.index += 1
    return g
end

# ============================================================================
# Encoding/Decoding Utility Functions
# ============================================================================

"""
    encode_value_le(::Type{T}, buffer, offset, value) where {T}

Encode a single value of type T into the buffer at the given offset (0-based).
Uses little-endian byte order (SBE default).
"""
@inline function encode_value_le(::Type{T}, buffer, offset, value) where {T}
    @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = htol(value)
end

"""
    decode_value_le(::Type{T}, buffer, offset) where {T}

Decode a single value of type T from the buffer at the given offset (0-based).
Uses little-endian byte order (SBE default).
"""
@inline function decode_value_le(::Type{T}, buffer, offset) where {T}
    @inbounds ltoh(reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[])
end

"""
    decode_array_le(::Type{T}, buffer, offset, length) where {T}

Create a read-only mapped array for decoding an array of values.
Uses little-endian byte order (SBE default).
"""
@inline function decode_array_le(::Type{T}, buffer, offset, length) where {T}
    raw_array = reinterpret(T, view(buffer, offset+1:offset+sizeof(T)*length))
    return mappedarray(ltoh, raw_array)
end

"""
    encode_array_le(::Type{T}, buffer, offset, length) where {T}

Create a mutable mapped array for encoding an array of values.
Uses little-endian byte order (SBE default).
"""
@inline function encode_array_le(::Type{T}, buffer, offset, length) where {T}
    raw_array = reinterpret(T, view(buffer, offset+1:offset+sizeof(T)*length))
    return mappedarray(ltoh, htol, raw_array)
end

"""
    encode_value_be(::Type{T}, buffer, offset, value) where {T}

Encode a single value of type T into the buffer at the given offset (0-based).
Uses big-endian byte order.
"""
@inline function encode_value_be(::Type{T}, buffer, offset, value) where {T}
    @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = hton(value)
end

"""
    decode_value_be(::Type{T}, buffer, offset) where {T}

Decode a single value of type T from the buffer at the given offset (0-based).
Uses big-endian byte order.
"""
@inline function decode_value_be(::Type{T}, buffer, offset) where {T}
    @inbounds ntoh(reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[])
end

"""
    decode_array_be(::Type{T}, buffer, offset, length) where {T}

Create a read-only mapped array for decoding an array of values.
Uses big-endian byte order.
"""
@inline function decode_array_be(::Type{T}, buffer, offset, length) where {T}
    raw_array = reinterpret(T, view(buffer, offset+1:offset+sizeof(T)*length))
    return mappedarray(ntoh, raw_array)
end

"""
    encode_array_be(::Type{T}, buffer, offset, length) where {T}

Create a mutable mapped array for encoding an array of values.
Uses big-endian byte order.
"""
@inline function encode_array_be(::Type{T}, buffer, offset, length) where {T}
    raw_array = reinterpret(T, view(buffer, offset+1:offset+sizeof(T)*length))
    return mappedarray(ntoh, hton, raw_array)
end

"""
    to_string(s::Symbol) -> StringView

Convert a Symbol to a StringView with zero allocations.
Uses unsafe pointer operations to create a view directly over the Symbol's internal string data.

# Examples
```julia
sym = :Hello
str = to_string(sym)  # Returns StringView, no allocation
println(str)  # "Hello"
```
"""
@inline function to_string(s::Symbol)
    p = Base.unsafe_convert(Ptr{UInt8}, s)
    len = @ccall strlen(p::Ptr{UInt8})::Csize_t
    return StringView(UnsafeArray(p, (unsafe_trunc(Int64, len),)))
end

# ============================================================================
# Code Generation Functions
# ============================================================================

# ============================================================================
# Shared Encode/Decode Functions for Consistent Endianness Handling
# ============================================================================

"""
    generateEncodedTypes!(target_module::Module, schema::Schema.MessageSchema)

Import the encoding/decoding utility functions from the SBE module.
These functions are now defined once in SBE.jl and imported by each generated module,
avoiding code duplication.

Creates const aliases with standard names that point to the appropriate
endianness-specific implementations (_le or _be suffix).

# Arguments
- `target_module::Module`: The module where the functions will be imported
- `schema::Schema.MessageSchema`: Schema containing byte order information

# Generated Functions (as const aliases)
- `encode_value`: Encode a single value
- `decode_value`: Decode a single value
- `encode_array`: Create mutable mapped array for encoding
- `decode_array`: Create read-only mapped array for decoding
"""
function generateEncodedTypes!(target_module::Module, schema::Schema.MessageSchema)
    if schema.byte_order == "bigEndian"
        # Import big-endian versions and create const aliases
        Core.eval(target_module, quote
            import SBE: encode_value_be, decode_value_be, encode_array_be, decode_array_be

            const encode_value = encode_value_be
            const decode_value = decode_value_be
            const encode_array = encode_array_be
            const decode_array = decode_array_be
        end)
    else
        # Import little-endian versions (SBE default) and create const aliases
        Core.eval(target_module, quote
            import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le

            const encode_value = encode_value_le
            const decode_value = decode_value_le
            const encode_array = encode_array_le
            const decode_array = decode_array_le
        end)
    end
end

"""
    generatePrimitiveProperty!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)

Generate value accessor functions that use the consistent encode/decode pattern.

This replaces both generate_value_accessors! and the duplicated logic in composite generation.
Creates `value()` and `value!()` methods for both single values and arrays, automatically
using the appropriate endianness-aware encode/decode functions.

# Arguments
- `target_module::Module`: The module where the functions will be generated
- `field_name::Symbol`: Name of the field type
- `type_def::Schema.EncodedType`: Type definition containing primitive type and length info

# Generated Functions
- `value(field)`: Get the current value (single or array)
- `value!(field, val)`: Set a new value (single values only)
- `value!(field)`: Get mutable array reference (arrays only)
- `value!(field, val)`: Copy values into array (arrays only)
"""
function generatePrimitiveProperty!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)

    if type_def.length == 1
        # Single value accessor
        Core.eval(target_module, quote
            function value(field::$field_name)
                decode_value($julia_type, field.buffer, field.offset)
            end

            function value!(field::$field_name, val::$julia_type)
                encode_value($julia_type, field.buffer, field.offset, val)
            end
        end)
    else
        # Array value accessor - use the endianness-aware array functions
        Core.eval(target_module, quote
            function value(field::$field_name)
                decode_array($julia_type, field.buffer, field.offset, $(type_def.length))
            end

            function value!(field::$field_name)
                encode_array($julia_type, field.buffer, field.offset, $(type_def.length))
            end

            function value!(field::$field_name, val)
                # Copy values into the mutable mapped array
                copyto!(value!(field), val)
            end
        end)
    end
end

# ============================================================================
# Shared Type Generation Functions
# ============================================================================

"""
    generateComposite!(target_module::Module, composite_def::Schema.CompositeType, schema::Schema.MessageSchema)

Generate a complete composite type in the given module.

This creates a separate module for the composite with clean field dispatch patterns.
The generated composite includes Decoder/Encoder types, SBE interface methods,
and field accessors for all members.

# Arguments
- `target_module::Module`: The parent module where the composite module will be created
- `composite_def::Schema.CompositeType`: Composite type definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: The name of the generated composite type

# Generated Structure
- Separate module named after the composite
- Abstract base type and concrete Decoder/Encoder types
- SBE interface methods (sbe_buffer, sbe_offset, etc.)
- Field accessor methods for each member
- Proper endianness handling via encode/decode functions
"""
function generateComposite!(target_module::Module, composite_def::Schema.CompositeType, schema::Schema.MessageSchema)
    composite_name = Symbol(to_pascal_case(composite_def.name))
    # Use <Name>Struct pattern for clarity (MessageHeader.MessageHeaderStruct)
    struct_name = Symbol(string(composite_name, "Struct"))
    decoder_name = :Decoder  # Type alias
    encoder_name = :Encoder  # Type alias

    # Create a separate module for this composite
    composite_module_name = composite_name  # Use the composite name directly as module name
    Core.eval(target_module, :(module $composite_module_name end))
    composite_module = getfield(target_module, composite_module_name)

    # Import necessary types into the composite module (only what exists)
    Core.eval(composite_module, :(using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType))
    Core.eval(composite_module, :(import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value))
    # Import value and value! so generated functions extend the main SBE interface
    Core.eval(composite_module, :(import SBE: value, value!))
    Core.eval(composite_module, :(using MappedArrays: mappedarray))

    # Generate the consistent encode/decode functions for this module
    generateEncodedTypes!(composite_module, schema)

    # Calculate the total encoded size
    total_size = 0
    for member in composite_def.members
        if member isa Schema.EncodedType
            # Skip constant members - they don't occupy space
            if member.presence == "constant"
                continue
            end
            julia_type = to_julia_type(member.primitive_type)
            total_size += sizeof(julia_type) * member.length
        elseif member isa Schema.RefType
            # Look up the referenced type and calculate its size
            ref_type_def = find_type_by_name(schema, member.type_ref)
            if ref_type_def !== nothing
                if ref_type_def isa Schema.EncodedType
                    # Skip constant refs
                    if ref_type_def.presence == "constant"
                        continue
                    end
                    ref_julia_type = to_julia_type(ref_type_def.primitive_type)
                    total_size += sizeof(ref_julia_type) * ref_type_def.length
                elseif ref_type_def isa Schema.CompositeType
                    # Recursively calculate composite size using get_field_size
                    total_size += get_field_size(schema, Schema.FieldDefinition(
                        member.name, UInt16(0), member.type_ref, 0, "", 0, "required",
                        nothing, "", nothing, nothing, nothing
                    ))
                elseif ref_type_def isa Schema.EnumType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    total_size += sizeof(encoding_type)
                elseif ref_type_def isa Schema.SetType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    total_size += sizeof(encoding_type)
                end
            end
        elseif member isa Schema.EnumType
            # Inline enum definition
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        elseif member isa Schema.SetType
            # Inline set definition
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        end
    end

    # Generate base type and concrete Decoder/Encoder types directly in module
    # Use unique names to avoid conflicts with module name
    # Generate composite struct using baseline pattern: single struct with type aliases
    # This eliminates allocations by having only one type (matches sbetool baseline)
    Core.eval(composite_module, quote
        export $decoder_name, $encoder_name

        # Single immutable struct for both encoding and decoding (matches sbetool baseline)
        struct $struct_name{T<:AbstractArray{UInt8}} <: AbstractSbeCompositeType
            buffer::T
            offset::Int64
            acting_version::UInt16
        end

        # Type aliases for Decoder and Encoder (matches sbetool baseline pattern)
        const $decoder_name = $struct_name
        const $encoder_name = $struct_name
    end)

    # Generate outer constructors for REPL convenience (provide defaults)
    # Only handle 1 and 2 argument cases - 3 arguments handled by inner constructor
    Core.eval(composite_module, quote
        # 1-argument: buffer only (use default offset and acting_version)
        @inline function $struct_name(buffer::AbstractArray{UInt8})
            $struct_name(buffer, Int64(0), UInt16(0))
        end

        # 2-argument: buffer + offset (use default acting_version)
        @inline function $struct_name(buffer::AbstractArray{UInt8}, offset::Integer)
            $struct_name(buffer, Int64(offset), UInt16(0))
        end
    end)

    # Generate SBE interface methods (only the ones specific to composites)
    # Note: sbe_buffer and sbe_offset are defined generically in metaprogramming.jl
    Core.eval(composite_module, quote
        # Encoded length - specific to this composite type
        sbe_encoded_length(::$struct_name) = UInt16($total_size)
        sbe_encoded_length(::Type{<:$struct_name}) = UInt16($total_size)

        # Base.sizeof compatibility
        Base.sizeof(m::$struct_name) = sbe_encoded_length(m)

        # Convert to byte array for writing
        function Base.convert(::Type{<:AbstractArray{UInt8}}, m::$struct_name)
            return view(m.buffer, m.offset+1:m.offset+sbe_encoded_length(m))
        end

        # User-friendly display method
        function Base.show(io::IO, m::$struct_name)
            print(io, $(string(composite_name)), "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
        end
    end)

    # Generate field accessors for each member in the composite module
    offset = 0
    for member in composite_def.members
        if member isa Schema.EncodedType
            generateCompositePropertyElements!(composite_module, struct_name, decoder_name, encoder_name, member, offset)
            julia_type = to_julia_type(member.primitive_type)
            offset += sizeof(julia_type) * member.length
        end
    end

    # Export the composite module itself so users can access Engine.Encoder and Engine.Decoder
    Core.eval(target_module, :(export $composite_module_name))

    return composite_name
end

"""
    generateCompositePropertyElements!(composite_module::Module, base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, member::Schema.EncodedType, offset::Int)

Generate field accessor methods for a composite member.

This creates clean field types with dispatch methods within the composite module.
Each member gets its own field type with proper SBE interface methods and
value accessors.

# Arguments
- `composite_module::Module`: The composite's module where field types are generated
- `base_type_name::Symbol`: Name of the composite's base type
- `decoder_name::Symbol`: Name of the decoder type
- `encoder_name::Symbol`: Name of the encoder type
- `member::Schema.EncodedType`: Member definition from the composite
- `offset::Int`: Byte offset of this member within the composite

# Generated Components
- Field type struct with buffer and offset
- SBE interface methods (id, since_version, encoding_*, etc.)
- Value accessor methods (value, value!)
- Proper type information (length, eltype)
"""
function generateCompositePropertyElements!(composite_module::Module, base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, member::Schema.EncodedType, offset::Int)
    member_name = Symbol(toCamelCase(member.name))
    julia_type = to_julia_type(member.primitive_type)
    is_constant = member.presence == "constant"

    # For constants, encoding_length is 0
    encoding_length = is_constant ? 0 : sizeof(julia_type) * member.length

    # Generate metadata functions (following sbetool baseline pattern)
    # These provide SBE field information without creating field objects
    Core.eval(composite_module, quote
        # SBE field attributes (metadata functions, matches baseline)
        $(Symbol(member_name, :_id))(::$base_type_name) = UInt16(0xffff)
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = UInt16(0xffff)
        $(Symbol(member_name, :_since_version))(::$base_type_name) = UInt16($(member.since_version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = UInt16($(member.since_version))
        # Use direct field access instead of sbe_acting_version() call
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= UInt16($(member.since_version))

        # Encoding information (0 for constants)
        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = $offset
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = $offset
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = $encoding_length
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = $encoding_length

        # Value limits (metadata)
        $(Symbol(member_name, :_null_value))(::$base_type_name) = $(get_null_value(julia_type, member))
        $(Symbol(member_name, :_null_value))(::Type{<:$base_type_name}) = $(get_null_value(julia_type, member))
        $(Symbol(member_name, :_min_value))(::$base_type_name) = $(get_min_value(julia_type, member))
        $(Symbol(member_name, :_min_value))(::Type{<:$base_type_name}) = $(get_min_value(julia_type, member))
        $(Symbol(member_name, :_max_value))(::$base_type_name) = $(get_max_value(julia_type, member))
        $(Symbol(member_name, :_max_value))(::Type{<:$base_type_name}) = $(get_max_value(julia_type, member))
    end)

    # Handle constant fields differently
    if is_constant
        # Parse constant value
        if member.constant_value === nothing
            error("Constant member $(member.name) has no constant value specified")
        end

        if member.length == 1
            # Single constant value
            const_val = parse_constant_value(julia_type, member.constant_value)
            Core.eval(composite_module, quote
                # Constant accessor: returns constant value directly (no buffer read)
                @inline $member_name(::$base_type_name) = $julia_type($const_val)
                @inline $member_name(::Type{<:$base_type_name}) = $julia_type($const_val)

                # Export the accessor (no setter for constants)
                export $member_name
            end)
        else
            # Array constant value
            if julia_type == UInt8  # Char array
                const_val = [UInt8(c) for c in member.constant_value]
            else
                error("Array constants only supported for char type")
            end
            Core.eval(composite_module, quote
                @inline $member_name(::$base_type_name) = $const_val
                @inline $member_name(::Type{<:$base_type_name}) = $const_val

                export $member_name
            end)
        end
    else
        # Generate direct accessor functions (following sbetool baseline pattern)
        # NO field objects - direct read/write operations
        if member.length == 1
            # Single value: direct decode/encode functions
            Core.eval(composite_module, quote
                # Direct decoder function: returns the value directly (matches baseline)
                @inline function $member_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $offset)
                end

                # Direct encoder function: writes the value directly (matches baseline)
                @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                    encode_value($julia_type, m.buffer, m.offset + $offset, convert($julia_type, val))
                end

                # Export the accessor functions
                export $member_name, $(Symbol(member_name, :!))
            end)
        else
            # Array value: direct array decode/encode functions
            Core.eval(composite_module, quote
                # Direct decoder function: returns array view directly (matches baseline)
                @inline function $member_name(m::$decoder_name)
                    return decode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                end

                # Direct encoder function: returns array view for writing (matches baseline)
                @inline function $(Symbol(member_name, :!))(m::$encoder_name)
                    return encode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                end

                # Convenience encoder with value
                @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                    copyto!($(Symbol(member_name, :!))(m), val)
                end

                # Export the accessor functions
                export $member_name, $(Symbol(member_name, :!))
            end)
        end
    end
end

"""
    generateMessageFlyweightStruct!(target_module::Module, message_def::Schema.MessageDefinition, schema::Schema.MessageSchema)

Generate a complete message type in the given module.

This creates a separate module for the message with clean field dispatch patterns.
The generated message includes Decoder/Encoder types, SBE interface methods,
and field accessors for all members.

# Arguments
- `target_module::Module`: The parent module where the message module will be created
- `message_def::Schema.MessageDefinition`: Message definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: The name of the generated message type

# Generated Structure
- Separate module named after the message
- Abstract base type and concrete Decoder/Encoder types
- MessageHeader-aware constructors
- SBE interface methods
- Field accessor methods for all message fields
"""
function generateMessageFlyweightStruct!(target_module::Module, message_def::Schema.MessageDefinition, schema::Schema.MessageSchema)
    message_name = Symbol(to_pascal_case(message_def.name))
    decoder_name = :Decoder  # Clean name within the message module
    encoder_name = :Encoder  # Clean name within the message module

    # Create a separate module for this message
    message_module_name = message_name  # Use the message name directly as module name
    Core.eval(target_module, :(module $message_module_name end))
    message_module = getfield(target_module, message_module_name)

    # Import necessary types into the message module
    Core.eval(message_module, :(using SBE: AbstractSbeMessage, AbstractSbeEncodedType, AbstractSbeData))
    Core.eval(message_module, :(using MappedArrays: mappedarray))
    Core.eval(message_module, :(import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value))
    Core.eval(message_module, :(import SBE: value, value!))
    Core.eval(message_module, :(import SBE: sbe_template_id, sbe_schema_id, sbe_schema_version, sbe_block_length))
    # Don't import sbe_acting_version - it's defined in parent module for this message type
    Core.eval(message_module, :(import SBE: sbe_acting_block_length, sbe_buffer, sbe_offset))
    Core.eval(message_module, :(import SBE: sbe_position_ptr, sbe_position, sbe_position!, sbe_rewind!, sbe_encoded_length))
    Core.eval(message_module, :(import SBE: sbe_semantic_type, sbe_description))

    # Generate the consistent encode/decode functions for this module
    generateEncodedTypes!(message_module, schema)

    # Handle potentially missing block_length
    block_length = if message_def.block_length !== nothing
        parse(Int, message_def.block_length)
    else
        # Calculate block length from fields if not specified
        max_offset = 0
        for field in message_def.fields
            field_end = field.offset + get_field_size(schema, field)
            max_offset = max(max_offset, field_end)
        end
        max_offset
    end

    # Import the header module that this message will use for constructors
    header_module_name = Symbol(to_pascal_case(schema.header_type))
    Core.eval(message_module, :(using ..$header_module_name))
    # Import PositionPointer from grandparent module (SBE)
    Core.eval(message_module, :(import ...PositionPointer))

    # Generate base type and concrete Decoder/Encoder types directly in module
    # Use AbstractSbeMessage{T} directly instead of creating a local MessageType
    Core.eval(message_module, quote
        export $decoder_name, $encoder_name

        # Decoder type - reads acting values from MessageHeader
        # Use immutable struct (like sbetool baseline) for better performance via aliasing analysis
        struct $decoder_name{T<:AbstractArray{UInt8}} <: AbstractSbeMessage{T}
            buffer::T
            offset::Int64
            position_ptr::PositionPointer
            acting_block_length::UInt16
            acting_version::UInt16

            # Inner constructor - matches sbetool baseline pattern (5-argument version)
            function $decoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer,
                acting_block_length::UInt16, acting_version::UInt16) where {T}
                position_ptr[] = offset + acting_block_length
                new{T}(buffer, offset, position_ptr, acting_block_length, acting_version)
            end

            # 3-argument constructor for symmetry with Encoder (uses schema defaults)
            function $decoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer) where {T}
                position_ptr[] = offset + UInt16($block_length)
                new{T}(buffer, offset, position_ptr, UInt16($block_length), UInt16($(schema.version)))
            end
        end

        # Encoder type - uses fixed schema values
        # Use immutable struct (like sbetool baseline) for better performance via aliasing analysis
        struct $encoder_name{T<:AbstractArray{UInt8}} <: AbstractSbeMessage{T}
            buffer::T
            offset::Int64
            position_ptr::PositionPointer

            # Inner constructor - matches sbetool baseline pattern
            function $encoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer) where {T}
                position_ptr[] = offset + $block_length
                new{T}(buffer, offset, position_ptr)
            end
        end
    end)

    # Generate MessageHeader-aware constructors (matches sbetool baseline pattern)
    header_decoder_name = :Decoder  # Clean name within the header module
    header_encoder_name = :Encoder   # Clean name within the header module

    Core.eval(message_module, quote
        # Outer constructor for decoder with MessageHeader validation (matches sbetool baseline)
        @inline function $decoder_name(buffer::AbstractArray, offset::Integer=0;
            position_ptr::PositionPointer=PositionPointer(),
            header::$header_module_name.$header_decoder_name=$header_module_name.$header_decoder_name(buffer, Int64(offset)))
            if $header_module_name.templateId(header) != UInt16($(message_def.id)) ||
               $header_module_name.schemaId(header) != UInt16($(schema.id))
                error("Template id or schema id mismatch")
            end
            $decoder_name(buffer, Int64(offset) + Int64($header_module_name.sbe_encoded_length(header)), position_ptr,
                $header_module_name.blockLength(header), $header_module_name.version(header))
        end

        # Outer constructor for encoder with MessageHeader initialization (matches sbetool baseline)
        @inline function $encoder_name(buffer::AbstractArray, offset::Integer=0;
            position_ptr::PositionPointer=PositionPointer(),
            header::$header_module_name.$header_encoder_name=$header_module_name.$header_encoder_name(buffer, Int64(offset)))
            $header_module_name.blockLength!(header, UInt16($block_length))
            $header_module_name.templateId!(header, UInt16($(message_def.id)))
            $header_module_name.schemaId!(header, UInt16($(schema.id)))
            $header_module_name.version!(header, UInt16($(schema.version)))
            $encoder_name(buffer, Int64(offset) + Int64($header_module_name.sbe_encoded_length(header)), position_ptr)
        end
    end)

    # Generate SBE interface methods in the PARENT module (not message module)
    # This allows Baseline.sbe_template_id(car) to work, not just Car.sbe_template_id(car)
    generateMessageFlyweightMethods!(target_module, message_module, message_module_name, message_def, schema)

    # Generate field accessors for each field in the message module
    for field in message_def.fields
        generateFields!(message_module, decoder_name, encoder_name, field, message_def.name, schema)
    end

    # Generate repeating groups
    for group_def in message_def.groups
        generateGroup!(message_module, group_def, message_def.name, schema)
    end

    # Generate variable data field accessors
    for data_def in message_def.var_data
        generateVarData!(message_module, data_def, message_def.name, schema)
    end

    # Export the message module itself so users can access Car.Encoder and Car.Decoder
    Core.eval(target_module, :(export $message_module_name))

    return message_name
end

"""
    generateMessageFlyweightMethods!(parent_module::Module, message_module::Module, message_module_name::Symbol, message_def::Schema.MessageDefinition, schema::Schema.MessageSchema)

Generate the common SBE interface methods for a message type.

This function generates methods in the PARENT module (e.g., Baseline), not the message module (e.g., Car).
Message-specific metadata dispatch on concrete types like `Car.Encoder` and `Car.Decoder`.

The approach allows both:
- `Baseline.sbe_template_id(car)` - calling from parent module
- `Car.sbe_template_id(car)` - calling from message module (via import)

# Arguments
- `parent_module::Module`: Parent module (e.g., Baseline) where methods are generated
- `message_module::Module`: Message-specific module (e.g., Car)
- `message_module_name::Symbol`: Name of message module for type references (e.g., :Car)
- `message_def::Schema.MessageDefinition`: Message definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Generated Methods in Parent Module
Message-specific metadata that dispatches on concrete types:
- sbe_template_id, sbe_schema_id, sbe_schema_version
- sbe_block_length, sbe_acting_block_length, sbe_acting_version
- sbe_semantic_type, sbe_description
"""
function generateMessageFlyweightMethods!(parent_module::Module, message_module::Module, message_module_name::Symbol, message_def::Schema.MessageDefinition, schema::Schema.MessageSchema)
    # These names match the struct definitions in the message module
    decoder_name = :Decoder
    encoder_name = :Encoder

    # Handle potentially missing block_length
    block_length = if message_def.block_length !== nothing
        parse(Int, message_def.block_length)
    else
        # Calculate block length from fields if not specified
        max_offset = 0
        for field in message_def.fields
            field_end = field.offset + get_field_size(schema, field)
            max_offset = max(max_offset, field_end)
        end
        max_offset
    end

    # Generate message-specific metadata in PARENT module
    # These dispatch on the concrete types from the nested message module
    Core.eval(parent_module, quote
        # Message-specific metadata - dispatch on concrete types from nested module
        @inline sbe_template_id(::Type{<:$message_module_name.$decoder_name}) = UInt16($(message_def.id))
        @inline sbe_template_id(::$message_module_name.$decoder_name) = UInt16($(message_def.id))
        @inline sbe_template_id(::Type{<:$message_module_name.$encoder_name}) = UInt16($(message_def.id))
        @inline sbe_template_id(::$message_module_name.$encoder_name) = UInt16($(message_def.id))

        @inline sbe_schema_id(::$message_module_name.$decoder_name) = UInt16($(schema.id))
        @inline sbe_schema_id(::$message_module_name.$encoder_name) = UInt16($(schema.id))

        @inline sbe_schema_version(::$message_module_name.$decoder_name) = UInt16($(schema.version))
        @inline sbe_schema_version(::$message_module_name.$encoder_name) = UInt16($(schema.version))

        @inline sbe_block_length(::Type{<:$message_module_name.$decoder_name}) = UInt16($block_length)
        @inline sbe_block_length(::$message_module_name.$decoder_name) = UInt16($block_length)
        @inline sbe_block_length(::Type{<:$message_module_name.$encoder_name}) = UInt16($block_length)
        @inline sbe_block_length(::$message_module_name.$encoder_name) = UInt16($block_length)

        # Acting version and block length differ between decoder/encoder
        @inline sbe_acting_block_length(m::$message_module_name.$decoder_name) = m.acting_block_length
        @inline sbe_acting_block_length(::$message_module_name.$encoder_name) = UInt16($block_length)
        @inline sbe_acting_version(m::$message_module_name.$decoder_name) = m.acting_version
        @inline sbe_acting_version(::$message_module_name.$encoder_name) = UInt16($(schema.version))

        # Semantic information (constants for zero runtime cost)
        @inline sbe_semantic_type(::$message_module_name.$decoder_name) = "$(something(message_def.semantic_type, ""))"
        @inline sbe_semantic_type(::$message_module_name.$encoder_name) = "$(something(message_def.semantic_type, ""))"
        @inline sbe_description(::$message_module_name.$decoder_name) = "$(something(message_def.description, ""))"
        @inline sbe_description(::$message_module_name.$encoder_name) = "$(something(message_def.description, ""))"

        # User-friendly display methods
        function Base.show(io::IO, m::$message_module_name.$decoder_name)
            print(io, $(string(message_module_name)), ".Decoder(")
            print(io, "template_id=", sbe_template_id(m), ", ")
            print(io, "schema_id=", sbe_schema_id(m), ", ")
            print(io, "version=", sbe_acting_version(m))
            print(io, ")")
        end

        function Base.show(io::IO, m::$message_module_name.$encoder_name)
            print(io, $(string(message_module_name)), ".Encoder(")
            print(io, "template_id=", sbe_template_id(m), ", ")
            print(io, "schema_id=", sbe_schema_id(m), ", ")
            print(io, "version=", sbe_schema_version(m))
            print(io, ")")
        end
    end)

    # Note: The methods are defined in the parent module and will be accessible via:
    # - Baseline.sbe_template_id(car) - from parent module
    # - Car instances will dispatch to parent module methods automatically
    # We don't need to import them into the message module to avoid warnings
end

"""
    generatePrimitiveFieldMetaData!(target_module::Module, field_name::Symbol, field_def::Schema.FieldDefinition, type_def::Schema.EncodedType)

Generate attribute functions for a field type in the given module.

This includes id, since_version, encoding_offset, encoding_length, length, and eltype
methods that provide metadata about the field according to the SBE specification.

# Arguments
- `target_module::Module`: Module where the methods will be generated
- `field_name::Symbol`: Name of the field type
- `field_def::Schema.FieldDefinition`: Field definition from schema
- `type_def::Schema.EncodedType`: Type definition containing encoding info

# Generated Methods
- `id(::Type{<:FieldType})`, `id(::FieldType)` - Field ID from schema
- `since_version(::Type{<:FieldType})`, `since_version(::FieldType)` - Version introduced
- `encoding_offset(::Type{<:FieldType})`, `encoding_offset(::FieldType)` - Byte offset
- `encoding_length(::Type{<:FieldType})`, `encoding_length(::FieldType)` - Total byte length
- `Base.length(::Type{<:FieldType})`, `Base.length(::FieldType)` - Array length
- `Base.eltype(::Type{<:FieldType})`, `Base.eltype(::FieldType)` - Element type
"""
function generatePrimitiveFieldMetaData!(target_module::Module, field_name::Symbol, field_def::Schema.FieldDefinition, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)
    total_length = sizeof(julia_type) * type_def.length

    Core.eval(target_module, quote
        # SBE field attributes
        id(::Type{<:$field_name}) = UInt16($(field_def.id))
        id(::$field_name) = UInt16($(field_def.id))
        since_version(::Type{<:$field_name}) = UInt16($(field_def.since_version))
        since_version(::$field_name) = UInt16($(field_def.since_version))

        # Encoding information
        encoding_offset(::Type{<:$field_name}) = $(field_def.offset)
        encoding_offset(::$field_name) = $(field_def.offset)
        encoding_length(::Type{<:$field_name}) = $total_length
        encoding_length(::$field_name) = $total_length

        # Array/type information
        Base.length(::Type{<:$field_name}) = $(type_def.length)
        Base.length(::$field_name) = $(type_def.length)
        Base.eltype(::Type{<:$field_name}) = $julia_type
        Base.eltype(::$field_name) = $julia_type
    end)
end

"""
    generatePrimitivePropertyMethods!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)

Generate value accessor functions for a field type in the given module.

This includes value() and value!() methods for both single values and arrays,
using the appropriate endianness-aware encode/decode functions generated by
generateEncodedTypes!.

# Arguments
- `target_module::Module`: Module where the methods will be generated
- `field_name::Symbol`: Name of the field type
- `type_def::Schema.EncodedType`: Type definition containing primitive type and length

# Generated Methods for Single Values (length == 1)
- `value(field)` - Decode and return the current value
- `value!(field, val)` - Encode and store a new value

# Generated Methods for Arrays (length > 1)
- `value(field)` - Return read-only mapped array with proper endianness
- `value!(field)` - Return mutable mapped array for writing
- `value!(field, val)` - Copy values from source into the field array
"""
function generatePrimitivePropertyMethods!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)

    if type_def.length == 1
        # Single value accessor
        Core.eval(target_module, quote
            @inline function value(field::$field_name)
                decode_value($julia_type, field.buffer, field.offset)
            end

            @inline function value!(field::$field_name, val::$julia_type)
                encode_value($julia_type, field.buffer, field.offset, val)
            end
        end)
    else
        # Array value accessor - use the endianness-aware array functions
        Core.eval(target_module, quote
            @inline function value(field::$field_name)
                decode_array($julia_type, field.buffer, field.offset, $(type_def.length))
            end

            @inline function value!(field::$field_name)
                encode_array($julia_type, field.buffer, field.offset, $(type_def.length))
            end

            @inline function value!(field::$field_name, val)
                copyto!(value!(field), val)
            end
        end)
    end
end

"""
    generateFieldMetaAttributeMethod!(target_module::Module, field_name::Symbol, field_def)

Generate meta attribute function for a field in the given module.

Creates a `meta_attribute(::FieldType, meta_attribute)` function that returns
metadata about the field based on the SBE specification. This includes epoch,
time_unit, semantic_type, and presence information.

# Arguments
- `target_module::Module`: Module where the function will be generated
- `field_name::Symbol`: Name of the field type
- `field_def`: Field definition (either `Schema.FieldDefinition` or `Schema.VarDataDefinition`)

# Generated Function
- `meta_attribute(::FieldType, meta_attribute::Symbol)` - Returns Symbol with requested metadata

# Supported Meta Attributes
- `:epoch` - Temporal epoch (defaults to field definition)
- `:time_unit` - Time unit for temporal fields
- `:semantic_type` - Semantic type information
- `:presence` - Field presence (required, optional, etc.)
"""
function generateFieldMetaAttributeMethod!(target_module::Module, field_name::Symbol, field_def)
    # Generate meta_attribute function for the field type itself
    # e.g., meta_attribute(::SerialNumberField, meta_attribute)

    # Extract metadata based on field type
    epoch_val = if hasfield(typeof(field_def), :epoch) && field_def.epoch !== nothing
        field_def.epoch
    else
        ""  # Default epoch
    end

    time_unit_val = if hasfield(typeof(field_def), :time_unit) && field_def.time_unit !== nothing
        field_def.time_unit
    else
        ""
    end

    semantic_type_val = if hasfield(typeof(field_def), :semantic_type) && field_def.semantic_type !== nothing
        field_def.semantic_type
    else
        ""
    end

    presence_val = if hasfield(typeof(field_def), :presence) && field_def.presence !== nothing
        field_def.presence
    else
        "required"  # Default for variable data
    end

    # Build the function body based on the actual field definition values
    checks = Expr[]

    # Epoch - defaults to "unix" according to SBE spec
    push!(checks, :(meta_attribute === :epoch && return Symbol($epoch_val)))

    # Time unit - only add if not empty
    if !isempty(time_unit_val)
        push!(checks, :(meta_attribute === :time_unit && return Symbol($time_unit_val)))
    else
        push!(checks, :(meta_attribute === :time_unit && return Symbol("")))
    end

    # Semantic type - only add if not empty
    if !isempty(semantic_type_val)
        push!(checks, :(meta_attribute === :semantic_type && return Symbol($semantic_type_val)))
    else
        push!(checks, :(meta_attribute === :semantic_type && return Symbol("")))
    end

    # Presence
    push!(checks, :(meta_attribute === :presence && return Symbol($presence_val)))

    # Default case
    push!(checks, :(return Symbol("")))

    # Generate meta_attribute function for the field type
    Core.eval(target_module, quote
        @inline function meta_attribute(::$field_name, meta_attribute)
            $(checks...)
        end
    end)
end

"""
    generateValueLimits!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)

Generate value limit functions (null_value, min_value, max_value) for a field type in the given module.

Creates functions that return the valid range and null value for the field type
based on the schema definition and Julia type constraints.

# Arguments
- `target_module::Module`: Module where the functions will be generated
- `field_name::Symbol`: Name of the field type
- `type_def::Schema.EncodedType`: Type definition containing limit values

# Generated Methods
- `null_value(::Type{<:FieldType})`, `null_value(::FieldType)` - Null/invalid value
- `min_value(::Type{<:FieldType})`, `min_value(::FieldType)` - Minimum valid value
- `max_value(::Type{<:FieldType})`, `max_value(::FieldType)` - Maximum valid value

# Default Behavior
- Uses schema-defined limits if available
- Falls back to Julia type limits (typemin/typemax)
- Null values follow SBE conventions (max for unsigned, min for signed)
"""
function generateValueLimits!(target_module::Module, field_name::Symbol, type_def::Schema.EncodedType)
    julia_type = to_julia_type(type_def.primitive_type)

    # Null value
    if type_def.null_value !== nothing
        null_val = parse_typed_value(type_def.null_value, julia_type)
        Core.eval(target_module, quote
            null_value(::Type{<:$field_name}) = $null_val
            null_value(::$field_name) = $null_val
        end)
    end

    # Min value
    if type_def.min_value !== nothing
        min_val = parse_typed_value(type_def.min_value, julia_type)
        Core.eval(target_module, quote
            min_value(::Type{<:$field_name}) = $min_val
            min_value(::$field_name) = $min_val
        end)
    else
        Core.eval(target_module, quote
            min_value(::Type{<:$field_name}) = typemin($julia_type)
            min_value(::$field_name) = typemin($julia_type)
        end)
    end

    # Max value
    if type_def.max_value !== nothing
        max_val = parse_typed_value(type_def.max_value, julia_type)
        Core.eval(target_module, quote
            max_value(::Type{<:$field_name}) = $max_val
            max_value(::$field_name) = $max_val
        end)
    else
        Core.eval(target_module, quote
            max_value(::Type{<:$field_name}) = typemax($julia_type)
            max_value(::$field_name) = typemax($julia_type)
        end)
    end
end

"""
    generateFields!(target_module::Module, field_def::Schema.FieldDefinition, message_name::String, schema::Schema.MessageSchema)

Generate high-performance direct field accessor functions (baseline-style).

This generates ultra-low-latency field accessors with static dispatch and aggressive inlining,
matching the baseline sbetool output for maximum performance in financial messaging applications.

# Arguments
- `target_module::Module`: Module where the field accessors will be generated
- `field_def::Schema.FieldDefinition`: Field definition from schema
- `message_name::String`: Name of the containing message (for constructor)
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: Name of the generated field accessor, or `nothing` if type not found

# Generated Components
- Direct @inline accessor functions (zero-allocation field access)
- Direct @inline mutator functions (zero-allocation field writes)
- Static metadata constants (compile-time dispatch)
- No intermediate field objects (matches baseline performance)

# Performance Characteristics
- Zero allocations for field access
- Static dispatch at compile time
- Aggressive inlining for minimum overhead
- Direct memory access pattern
"""
function generateFields!(target_module::Module, decoder_name::Symbol, encoder_name::Symbol, field_def::Schema.FieldDefinition, message_name::String, schema::Schema.MessageSchema)
    # Use camelCase for field names (matches baseline)
    field_name = Symbol(toCamelCase(field_def.name))
    field_name_setter = Symbol(string(field_name, "!"))

    # Get the type definition - check if it's a named type or a primitive type
    type_def = find_type_by_name(schema, field_def.type_ref)

    # If not found in schema, check if it's a built-in primitive type
    if type_def === nothing && is_primitive_type(field_def.type_ref)
        # Create synthetic EncodedType for primitive type
        type_def = create_primitive_encoded_type(field_def.type_ref, 1)  # Assume scalar for now
    end

    # Skip if type not found
    if type_def === nothing
        @warn "Skipping field $(field_def.name): type $(field_def.type_ref) not found"
        return nothing
    end

    field_offset = field_def.offset

    # Handle different type categories
    if type_def isa Schema.EncodedType
        # Primitive types (int, float, char arrays, etc.)
        generate_encoded_field!(target_module, decoder_name, encoder_name, field_name, field_def, type_def, field_offset)
    elseif type_def isa Schema.EnumType
        # Enum types
        generate_enum_field!(target_module, decoder_name, encoder_name, field_name, field_def, type_def, field_offset, schema)
    elseif type_def isa Schema.SetType
        # Set/BitSet types
        generate_set_field!(target_module, decoder_name, encoder_name, field_name, field_def, type_def, field_offset)
    elseif type_def isa Schema.CompositeType
        # Composite types
        generate_composite_field!(target_module, decoder_name, encoder_name, field_name, field_def, type_def, field_offset, schema)
    else
        @warn "Skipping field $(field_def.name): unsupported type $(typeof(type_def))"
        return nothing
    end

    return field_name
end

"""
Generate accessors for encoded (primitive) field types.
"""
function generate_encoded_field!(target_module::Module, decoder_name::Symbol, encoder_name::Symbol,
                                  field_name::Symbol, field_def::Schema.FieldDefinition,
                                  type_def::Schema.EncodedType, field_offset::Int)
    field_name_setter = Symbol(string(field_name, "!"))
    julia_type = to_julia_type(type_def.primitive_type)
    since_version = field_def.since_version
    is_optional = field_def.presence == "optional" || type_def.presence == "optional"

    # Generate null_value() function for optional fields
    # This matches Java SBE pattern: always return T, never Union{T, Nothing}
    if is_optional && type_def.length == 1
        null_val = get_null_value(julia_type, type_def)
        field_null_value = Symbol(string(field_name, "_null_value"))

        # Get parent module name at runtime, not compile time
        parent_mod_symbol = Symbol(parentmodule(target_module))

        Core.eval(target_module, quote
            @inline $field_null_value() = $null_val
        end)
    end

    # Generate direct accessor functions with concrete type dispatch (matches baseline, zero allocations)
    if type_def.length == 1
        # Single value - direct decode/encode
        if since_version > 0
            # Version-aware accessor - check acting version before reading (matches Java: parentMessage.actingVersion)
            null_val = get_null_value(julia_type, type_def)
            Core.eval(target_module, quote
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        return $null_val
                    end
                    return decode_value($julia_type, m.buffer, m.offset + $field_offset)
                end

                @inline function $field_name_setter(m::$encoder_name, value)
                    encode_value($julia_type, m.buffer, m.offset + $field_offset, convert($julia_type, value))
                    return m
                end
            end)
        else
            # No version check needed (field in version 0)
            Core.eval(target_module, quote
                @inline function $field_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $field_offset)
                end

                @inline function $field_name_setter(m::$encoder_name, value)
                    encode_value($julia_type, m.buffer, m.offset + $field_offset, convert($julia_type, value))
                    return m
                end
            end)
        end
    else
        # Array value - return mapped array view (zero-copy)
        # Matches baseline: decoder returns array, encoder has two versions:
        # - someNumbers!(m) returns mutable view
        # - someNumbers!(m, value) copies value into buffer
        # Special case: character arrays return String (matches SBE baseline behavior)
        is_character_array = (type_def.primitive_type == "char")

        if is_character_array
            # Character arrays return String by default
            Core.eval(target_module, :(using StringViews: StringView))

            if since_version > 0
                Core.eval(target_module, quote
                    @inline function $field_name(m::$decoder_name)
                        if m.acting_version < UInt16($since_version)
                            return ""
                        end
                        bytes = decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        # Remove trailing null bytes - use findfirst to avoid allocation
                        pos = findfirst(iszero, bytes)
                        len = pos !== nothing ? pos - 1 : Base.length(bytes)
                        return StringView(view(bytes, 1:len))
                    end

                    @inline function $field_name_setter(m::$encoder_name, value::AbstractString)
                        bytes = codeunits(value)
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(bytes), length(dest))
                        copyto!(dest, 1, bytes, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                        return m
                    end

                    @inline function $field_name_setter(m::$encoder_name, value::AbstractVector{UInt8})
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(value), length(dest))
                        copyto!(dest, 1, value, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                        return m
                    end
                end)
            else
                Core.eval(target_module, quote
                    @inline function $field_name(m::$decoder_name)
                        bytes = decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        # Remove trailing null bytes - use findfirst to avoid allocation
                        pos = findfirst(iszero, bytes)
                        len = pos !== nothing ? pos - 1 : Base.length(bytes)
                        return StringView(view(bytes, 1:len))
                    end

                    @inline function $field_name_setter(m::$encoder_name, value::AbstractString)
                        bytes = codeunits(value)
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(bytes), length(dest))
                        copyto!(dest, 1, bytes, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                        return m
                    end

                    @inline function $field_name_setter(m::$encoder_name, value::AbstractVector{UInt8})
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(value), length(dest))
                        copyto!(dest, 1, value, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                        return m
                    end
                end)
            end
        else
            # Non-character arrays: return numeric array view
            if since_version > 0
                # For arrays with version check, return an array filled with null values when not in version.
                # Note: This allocates, but only on the version-mismatch path (rare). The alternative
                # would be returning an empty view, but that changes the array length semantically.
                null_val = get_null_value(julia_type, type_def)
                Core.eval(target_module, quote
                    @inline function $field_name(m::$decoder_name)
                        if m.acting_version < UInt16($since_version)
                            return fill($null_val, $(type_def.length))
                        end
                        return decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end

                    @inline function $field_name_setter(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end

                    @inline function $field_name_setter(m::$encoder_name, value)
                        copyto!($field_name_setter(m), value)
                    end
                end)
            else
                # No version check needed
                Core.eval(target_module, quote
                    @inline function $field_name(m::$decoder_name)
                        return decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end

                    @inline function $field_name_setter(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end

                    @inline function $field_name_setter(m::$encoder_name, value)
                        copyto!($field_name_setter(m), value)
                    end
                end)
            end
        end
    end

    # Generate static metadata constants
    generate_field_metadata!(target_module, field_name, field_def, type_def, field_offset, julia_type)
end

"""
Generate accessors for enum field types.
"""
function generate_enum_field!(target_module::Module, decoder_name::Symbol, encoder_name::Symbol,
                               field_name::Symbol, field_def::Schema.FieldDefinition,
                               type_def::Schema.EnumType, field_offset::Int, schema::Schema.MessageSchema)
    field_name_setter = Symbol(string(field_name, "!"))
    enum_type_name = Symbol(to_pascal_case(type_def.name))
    encoding_julia_type = to_julia_type(type_def.encoding_type)
    is_constant = field_def.presence == "constant"
    is_optional = field_def.presence == "optional"
    since_version = field_def.since_version

    # Enum types are generated at the schema root level
    # Navigate up the module hierarchy to find the schema root module
    schema_root_module = parentmodule(target_module)
    if !isdefined(schema_root_module, enum_type_name)
        # We're in a group, go up one more level
        schema_root_module = parentmodule(schema_root_module)
    end
    enum_type = getfield(schema_root_module, enum_type_name)

    # Get null value for versioned or optional fields
    # For enums, use typemin/typemax of encoding type as null
    null_val = if since_version > 0 || is_optional
        # Use typemin of encoding type as null value
        if encoding_julia_type <: Unsigned
            encoding_julia_type(typemax(encoding_julia_type))
        else
            encoding_julia_type(typemin(encoding_julia_type))
        end
    else
        nothing
    end

    # Generate null_value() function for optional enum fields
    if is_optional
        field_null_value = Symbol(string(field_name, "_null_value"))

        Core.eval(target_module, quote
            @inline $field_null_value() = $null_val
        end)
    end

    if is_constant
        # Constant enum field - resolve valueRef
        if field_def.value_ref === nothing
            error("Constant enum field $(field_def.name) has no valueRef specified")
        end

        # Parse valueRef (e.g., "Model.C" -> enum_type.C)
        parts = split(field_def.value_ref, '.')
        if length(parts) != 2
            error("Invalid valueRef format: $(field_def.value_ref). Expected EnumType.Value")
        end
        value_name = Symbol(parts[2])

        # Generate constant accessor (matches baseline pattern)
        Core.eval(target_module, quote
            # Return raw integer value
            @inline function $field_name(::$decoder_name, ::Type{Integer})
                return $encoding_julia_type($enum_type.$value_name)
            end

            # Return enum value (default) - no buffer read, returns constant
            @inline function $field_name(::$decoder_name)
                return $enum_type.$value_name
            end

            # No setter for constant fields
        end)
    else
        # Regular enum field - read from buffer with version check
        if since_version > 0
            # Version-aware enum field
            Core.eval(target_module, quote
                # Return raw integer value
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    if m.acting_version < UInt16($since_version)
                        return $null_val
                    end
                    return decode_value($encoding_julia_type, m.buffer, m.offset + $field_offset)
                end

                # Return enum value (default) - wrapped in SbeEnum
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        return $enum_type.SbeEnum($null_val)
                    end
                    return $enum_type.SbeEnum(decode_value($encoding_julia_type, m.buffer, m.offset + $field_offset))
                end

                # Setter accepts enum value
                @inline function $field_name_setter(m::$encoder_name, value::$enum_type.SbeEnum)
                    encode_value($encoding_julia_type, m.buffer, m.offset + $field_offset, $encoding_julia_type(value))
                    return m
                end
            end)
        else
            # Non-versioned enum field (version 0)
            Core.eval(target_module, quote
                # Return raw integer value
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    return decode_value($encoding_julia_type, m.buffer, m.offset + $field_offset)
                end

                # Return enum value (default)
                @inline function $field_name(m::$decoder_name)
                    return $enum_type.SbeEnum(decode_value($encoding_julia_type, m.buffer, m.offset + $field_offset))
                end

                # Setter accepts enum value
                @inline function $field_name_setter(m::$encoder_name, value::$enum_type.SbeEnum)
                    encode_value($encoding_julia_type, m.buffer, m.offset + $field_offset, $encoding_julia_type(value))
                    return m
                end
            end)
        end
    end

    # Generate metadata (encoding_length=0 for constants)
    encoding_length = is_constant ? 0 : sizeof(encoding_julia_type)
    generate_field_metadata!(target_module, field_name, field_def, nothing, field_offset, encoding_julia_type, encoding_length)
end

"""
Generate accessors for set/bitset field types.
"""
function generate_set_field!(target_module::Module, decoder_name::Symbol, encoder_name::Symbol,
                              field_name::Symbol, field_def::Schema.FieldDefinition,
                              type_def::Schema.SetType, field_offset::Int)
    set_type_name = Symbol(to_pascal_case(type_def.name))
    encoding_julia_type = to_julia_type(type_def.encoding_type)
    since_version = field_def.since_version

    # Set types are generated at the schema root level
    # Navigate up the module hierarchy to find the schema root module
    schema_root_module = parentmodule(target_module)
    if !isdefined(schema_root_module, set_type_name)
        # We're in a group, go up one more level
        schema_root_module = parentmodule(schema_root_module)
    end
    set_module = getfield(schema_root_module, set_type_name)
    set_struct_name = Symbol(string(set_type_name, "Struct"))

    field_name_setter = Symbol(string(field_name, "!"))

    # Generate set accessors
    if since_version > 0
        # Version-aware set field - check acting_version
        # For null value, we need to allocate a small buffer with zeros
        Core.eval(target_module, quote
            @inline function $field_name(m::Union{$decoder_name, $encoder_name})
                if m.acting_version < UInt16($since_version)
                    # Return empty set (all bits zero) when field not in version
                    # Create temporary buffer with zero value for this set
                    temp_buffer = zeros(UInt8, sizeof($encoding_julia_type))
                    return getfield($(QuoteNode(schema_root_module)), $(QuoteNode(set_type_name))).$set_struct_name(temp_buffer, 0)
                end
                return getfield($(QuoteNode(schema_root_module)), $(QuoteNode(set_type_name))).$set_struct_name(m.buffer, m.offset + $field_offset)
            end

            @inline function $field_name_setter(m::$encoder_name, choices::Set)
                if m.acting_version < UInt16($since_version)
                    return m  # Don't write if field not in version
                end
                set_inst = $field_name(m)
                set_mod = getfield($(QuoteNode(schema_root_module)), $(QuoteNode(set_type_name)))
                set_mod.clear!(set_inst)
                for choice in choices
                    # Extract choice name from the function (e.g., "Flags.guacamole" -> "guacamole")
                    choice_name = Symbol(split(string(choice), ".")[end])
                    choice_setter = getfield(set_mod, Symbol(string(choice_name, "!")))
                    choice_setter(set_inst, true)
                end
                return m
            end
        end)
    else
        # Non-versioned set field (version 0)
        Core.eval(target_module, quote
            @inline function $field_name(m::Union{$decoder_name, $encoder_name})
                return getfield($(QuoteNode(schema_root_module)), $(QuoteNode(set_type_name))).$set_struct_name(m.buffer, m.offset + $field_offset)
            end

            @inline function $field_name_setter(m::$encoder_name, choices::Set)
                set_inst = $field_name(m)
                set_mod = getfield($(QuoteNode(schema_root_module)), $(QuoteNode(set_type_name)))
                set_mod.clear!(set_inst)
                for choice in choices
                    # Extract choice name from the function (e.g., "Flags.guacamole" -> "guacamole")
                    choice_name = Symbol(split(string(choice), ".")[end])
                    choice_setter = getfield(set_mod, Symbol(string(choice_name, "!")))
                    choice_setter(set_inst, true)
                end
                return m
            end
        end)
    end

    # Generate metadata
    generate_field_metadata!(target_module, field_name, field_def, nothing, field_offset, encoding_julia_type)
end

"""
Generate accessors for composite field types.
"""
function generate_composite_field!(target_module::Module, decoder_name::Symbol, encoder_name::Symbol,
                                    field_name::Symbol, field_def::Schema.FieldDefinition,
                                    type_def::Schema.CompositeType, field_offset::Int, schema::Schema.MessageSchema)
    composite_type_name = Symbol(to_pascal_case(type_def.name))

    # Composite types are generated as modules at the schema root level
    # Navigate up the module hierarchy to find the schema root module
    # For groups: target_module -> message module -> schema root
    # For messages: target_module -> schema root
    schema_root_module = parentmodule(target_module)
    if !isdefined(schema_root_module, composite_type_name)
        # We're in a group, go up one more level
        schema_root_module = parentmodule(schema_root_module)
    end
    composite_module = getfield(schema_root_module, composite_type_name)
    composite_decoder_type = getfield(composite_module, :Decoder)

    # Generate composite accessors (matches baseline pattern - returns composite instance)
    # For Car.Decoder, use Engine.Decoder; for Car.Encoder, use Engine.Encoder
    # Optimize by using direct field access (decoder) and compile-time constant (encoder)

    # Evaluate schema version outside the quote to avoid scope issues
    schema_version = UInt16(schema.version)

    Core.eval(target_module, quote
        @inline function $field_name(m::$decoder_name)
            # Use direct field access for performance - decoder has acting_version field
            return $composite_decoder_type(m.buffer, m.offset + $field_offset, m.acting_version)
        end

        @inline function $field_name(m::$encoder_name)
            # For encoder, acting_version is always the schema version (constant)
            # Use compile-time constant instead of function call for performance
            return $composite_decoder_type(m.buffer, m.offset + $field_offset, $schema_version)
        end
    end)    # Generate metadata (composite types don't have null/min/max values)
    metadata_prefix = Symbol(string(field_name, "_"))
    Core.eval(target_module, quote
        const $(Symbol(string(metadata_prefix, "encoding_offset"))) = $field_offset
        const $(Symbol(string(metadata_prefix, "id"))) = UInt16($(field_def.id))
        const $(Symbol(string(metadata_prefix, "since_version"))) = UInt16($(field_def.since_version))
    end)
end

"""
Generate metadata constants for a field.
"""
function generate_field_metadata!(target_module::Module, field_name::Symbol, field_def::Schema.FieldDefinition,
                                   type_def::Union{Schema.EncodedType, Nothing}, field_offset::Int, julia_type::Type,
                                   encoding_length::Union{Int, Nothing} = nothing)
    metadata_prefix = Symbol(string(field_name, "_"))
    # Use provided encoding_length if given, otherwise calculate from type_def
    if encoding_length === nothing
        encoding_length = type_def !== nothing ? (sizeof(julia_type) * type_def.length) : sizeof(julia_type)
    end

    Core.eval(target_module, quote
        # Static constants for metadata (zero runtime cost)
        const $(Symbol(string(metadata_prefix, "encoding_offset"))) = $field_offset
        const $(Symbol(string(metadata_prefix, "encoding_length"))) = $encoding_length
        const $(Symbol(string(metadata_prefix, "id"))) = UInt16($(field_def.id))
        const $(Symbol(string(metadata_prefix, "since_version"))) = UInt16($(field_def.since_version))
    end)

    # Generate array-specific metadata for array fields
    if type_def !== nothing && type_def.length > 1
        Core.eval(target_module, quote
            const $(Symbol(string(metadata_prefix, "length"))) = $(type_def.length)
            const $(Symbol(string(metadata_prefix, "eltype"))) = $julia_type
        end)
    end

    # Generate value limit constants if specified (only for encoded types)
    if type_def !== nothing
        if type_def.null_value !== nothing
            null_val = parse_typed_value(type_def.null_value, julia_type)
            null_const_name = Symbol(string(metadata_prefix, "null_value"))
            if !isdefined(target_module, null_const_name)
                Core.eval(target_module, quote
                    const $null_const_name = $null_val
                end)
            end
        end

        if type_def.min_value !== nothing
            min_val = parse_typed_value(type_def.min_value, julia_type)
            min_const_name = Symbol(string(metadata_prefix, "min_value"))
            if !isdefined(target_module, min_const_name)
                Core.eval(target_module, quote
                    const $min_const_name = $min_val
                end)
            end
        end

        if type_def.max_value !== nothing
            max_val = parse_typed_value(type_def.max_value, julia_type)
            max_const_name = Symbol(string(metadata_prefix, "max_value"))
            if !isdefined(target_module, max_const_name)
                Core.eval(target_module, quote
                    const $max_const_name = $max_val
                end)
            end
        end
    end
end

"""
    generateEnum!(target_module::Module, enum_def::Schema.EnumType, schema::Schema.MessageSchema)

Generate a complete enum type in the given module.

This creates the enum structure with all valid choices and exports it using EnumX.jl
following the SBE baseline pattern with @enumx and SbeEnum trait.

# Arguments
- `target_module::Module`: Module where the enum will be generated
- `enum_def::Schema.EnumType`: Enum definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: Name of the generated enum type

# Generated Structure
- EnumX enum with proper underlying type
- All valid values from schema definition
- NULL_VALUE following SBE conventions
- Proper handling of character vs numeric encodings

# Example
```julia
@enumx T=SbeEnum BooleanType::UInt8 begin
    FALSE = 0x0
    TRUE = 0x1
    NULL_VALUE = 0xff
end
```
"""
function generateEnum!(target_module::Module, enum_def::Schema.EnumType, schema::Schema.MessageSchema)
    enum_name = Symbol(to_pascal_case(enum_def.name))
    encoding_julia_type = to_julia_type(enum_def.encoding_type)

    # Ensure EnumX is available in the target module
    Core.eval(target_module, :(using EnumX))

    # Build enum values
    enum_values = Expr[]

    for valid_value in enum_def.values
        value_name = Symbol(valid_value.name)

        # Parse the value - could be numeric or character
        if enum_def.encoding_type == "char"
            # Character values - convert to UInt8
            if length(valid_value.value) == 1
                char_val = UInt8(valid_value.value[1])
                push!(enum_values, :($value_name = $encoding_julia_type($char_val)))
            else
                # Handle special values
                try
                    parsed_val = parse(encoding_julia_type, valid_value.value)
                    push!(enum_values, :($value_name = $encoding_julia_type($parsed_val)))
                catch
                    # Default to the first character
                    char_val = UInt8(valid_value.value[1])
                    push!(enum_values, :($value_name = $encoding_julia_type($char_val)))
                end
            end
        else
            # Numeric values
            try
                parsed_val = parse(encoding_julia_type, valid_value.value)
                push!(enum_values, :($value_name = $encoding_julia_type($parsed_val)))
            catch
                # Fallback to 0
                push!(enum_values, :($value_name = $encoding_julia_type(0)))
            end
        end
    end

    # Add NULL_VALUE - use the encoding's null value if available, otherwise default
    null_value = if enum_def.encoding_type == "char"
        UInt8(0x0)  # Standard SBE char null value
    else
        encoding_julia_type <: Unsigned ? typemax(encoding_julia_type) : typemin(encoding_julia_type)
    end

    push!(enum_values, :(NULL_VALUE = $encoding_julia_type($null_value)))

    # Generate the simple EnumX enum (matching the baseline pattern)
    Core.eval(target_module, quote
        @enumx T = SbeEnum $enum_name::$encoding_julia_type begin
            $(enum_values...)
        end
    end)

    return enum_name
end

"""
    generateVarData!(target_module::Module, data_def::Schema.VarDataDefinition, message_name::String, schema::Schema.MessageSchema)

Generate direct variable-length data accessor functions (baseline-style).

This creates zero-allocation direct accessors that read/write variable-length data
with automatic position management, matching the baseline sbetool pattern.

# Arguments
- `target_module::Module`: Module where the accessors will be generated
- `data_def::Schema.VarDataDefinition`: Variable data definition from schema
- `message_name::String`: Name of the containing message
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: Name of the generated accessor, or `nothing` if encoding type not found

# Generated Components
- Direct length accessor (reads UInt8/16/32 header at current position)
- Direct skip method (advances position past var data)
- Direct reader (returns view, advances position)
- Type conversion methods (String, AbstractArray, Symbol, etc.)
- Direct writer (writes length + data, advances position)
- Metadata constants (id, since_version, header_length)

# Character Encoding Support
Character-encoded vardata (primitiveType="char") automatically returns StringView
with null-byte trimming for zero-allocation string access. Supported encodings:
- **ASCII** - Standard ASCII encoding (fully supported)
- **UTF-8** - UTF-8 encoding (fully supported)
- Other encodings (ISO-8859-1, etc.) - May work but not explicitly tested

# Supported Value Types
- `AbstractVector{UInt8}` - Raw byte data (default)
- `AbstractString` - String data (UTF-8 or ASCII)
- `AbstractArray{T}` - Typed arrays
- `Symbol` - Symbol data
- `Real` - Numeric values
- `NTuple` - Tuples
"""
function generateVarData!(target_module::Module, data_def::Schema.VarDataDefinition, message_name::String, schema::Schema.MessageSchema)
    accessor_name = Symbol(toCamelCase(data_def.name))
    accessor_name_setter = Symbol(string(accessor_name, "!"))
    length_name = Symbol(string(accessor_name, "_length"))
    length_name_setter = Symbol(string(accessor_name, "_length!"))
    skip_name = Symbol(string("skip_", accessor_name, "!"))
    since_version = data_def.since_version

    # Get the variable data encoding type (e.g., varStringEncoding, varAsciiEncoding)
    encoding_type_def = find_type_by_name(schema, data_def.type_ref)
    if encoding_type_def === nothing || !(encoding_type_def isa Schema.CompositeType)
        @warn "Skipping var data field $(data_def.name): encoding type $(data_def.type_ref) not found"
        return nothing
    end

    # Calculate header length and extract length field type from the composite
    # VarData encoding composites typically have: <type name="length" primitiveType="uint8/uint16/uint32"/>
    header_length = calculate_composite_size(encoding_type_def, schema)

    # Find the length field (first member) and get its primitive type
    length_primitive_type = :UInt32  # Default fallback
    is_character_encoded = false
    if !isempty(encoding_type_def.members)
        first_member = encoding_type_def.members[1]
        if first_member isa Schema.EncodedType
            length_primitive_type = to_julia_type(first_member.primitive_type)
        end
        # Check if second member (varData field) is character-encoded
        if length(encoding_type_def.members) >= 2
            second_member = encoding_type_def.members[2]
            if second_member isa Schema.EncodedType && second_member.primitive_type == "char"
                is_character_encoded = true
            end
        end
    end

    # Import necessary types for var data accessors
    Core.eval(target_module, :(using SBE: AbstractSbeMessage, AbstractSbeGroup, to_string))
    Core.eval(target_module, :(using StringViews: StringView))

    # Generate length accessor (reads length field at current position)
    # Works for both messages and groups via shared position_ptr interface
    if since_version > 0
        # Version-aware length accessor
        Core.eval(target_module, quote
            @inline function $length_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                if m.acting_version < UInt16($since_version)
                    return UInt32(0)  # Return 0 length when field not in version
                end
                return decode_value($length_primitive_type, m.buffer, m.position_ptr[])
            end
        end)
    else
        # Non-versioned length accessor
        Core.eval(target_module, quote
            @inline function $length_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                return decode_value($length_primitive_type, m.buffer, m.position_ptr[])
            end
        end)
    end

    # Generate length setter (for encoder)
    # Note: Only checks SBE spec limit (1GB), not buffer bounds (matches Java SBE behavior)
    # This allows scatter-gather patterns where buffer size may not be known at encode time
    Core.eval(target_module, quote
        @inline function $length_name_setter(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            # SBE spec: varData length is limited to 2^30 (1GB)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value($length_primitive_type, m.buffer, m.position_ptr[], convert($length_primitive_type, n))
        end
    end)

    # Generate skip method (advances position past var data without reading)
    if since_version > 0
        # Version-aware skip
        Core.eval(target_module, quote
            @inline function $skip_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                if m.acting_version < UInt16($since_version)
                    return UInt32(0)  # Don't skip if field not in version
                end
                len = $length_name(m)
                pos = m.position_ptr[] + $header_length
                m.position_ptr[] = pos + len
                return len
            end
        end)
    else
        # Non-versioned skip
        Core.eval(target_module, quote
            @inline function $skip_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                len = $length_name(m)
                pos = m.position_ptr[] + $header_length
                m.position_ptr[] = pos + len
                return len
            end
        end)
    end

    # Generate reader (returns view or string, advances position)
    decoder_name = :Decoder
    if since_version > 0
        # Version-aware reader
        if is_character_encoded
            # For character-encoded vardata, return String by default
            Core.eval(target_module, quote
                @inline function $accessor_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        # Return empty string when field not in version
                        return ""
                    end
                    len = $length_name(m)
                    pos = m.position_ptr[] + $header_length
                    m.position_ptr[] = pos + len
                    bytes = view(m.buffer, pos+1:pos+len)
                    # Remove trailing null bytes for C-style strings
                    last_nonzero = findlast(!iszero, bytes)
                    return StringView(last_nonzero === nothing ? "" : view(bytes, 1:last_nonzero))
                end
            end)
        else
            # For binary vardata, return byte view
            Core.eval(target_module, quote
                @inline function $accessor_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        # Return empty view when field not in version
                        return view(m.buffer, 1:0)
                    end
                    len = $length_name(m)
                    pos = m.position_ptr[] + $header_length
                    m.position_ptr[] = pos + len
                    return view(m.buffer, pos+1:pos+len)
                end
            end)
        end
    else
        # Non-versioned reader
        if is_character_encoded
            # For character-encoded vardata, return String by default
            Core.eval(target_module, quote
                @inline function $accessor_name(m::$decoder_name)
                    len = $length_name(m)
                    pos = m.position_ptr[] + $header_length
                    m.position_ptr[] = pos + len
                    bytes = view(m.buffer, pos+1:pos+len)
                    # Remove trailing null bytes for C-style strings
                    last_nonzero = findlast(!iszero, bytes)
                    return StringView(last_nonzero === nothing ? "" : view(bytes, 1:last_nonzero))
                end
            end)
        else
            # For binary vardata, return byte view
            Core.eval(target_module, quote
                @inline function $accessor_name(m::$decoder_name)
                    len = $length_name(m)
                    pos = m.position_ptr[] + $header_length
                    m.position_ptr[] = pos + len
                    return view(m.buffer, pos+1:pos+len)
                end
            end)
        end
    end

    # Generate type conversion methods for reader
    Core.eval(target_module, quote
        # Convert to typed array (e.g., AbstractArray{UInt32})
        @inline function $accessor_name(m::$decoder_name, ::Type{AbstractArray{T}}) where {T<:Real}
            return reinterpret(T, $accessor_name(m))
        end

        # Convert to string (handles both String and StringView)
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:AbstractString}
            bytes = $accessor_name(m)
            # Remove trailing null bytes for C-style strings
            last_nonzero = findlast(!iszero, bytes)
            # Return StringView to avoid allocation
            return StringView(last_nonzero === nothing ? "" : view(bytes, 1:last_nonzero))
        end

        # Convert to symbol
        @inline function $accessor_name(m::$decoder_name, ::Type{Symbol})
            return Symbol($accessor_name(m, String))
        end

        # Convert to single numeric value
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:Real}
            return reinterpret(T, $accessor_name(m))[]
        end

        # Convert to tuple
        @inline function $accessor_name(m::$decoder_name, ::Type{NTuple{N,T}}) where {N,T<:Real}
            arr = reinterpret(T, $accessor_name(m))
            return ntuple(i -> arr[i], Val(N))
        end
    end)

    # Generate writer (writes length + data, advances position)
    encoder_name = :Encoder
    Core.eval(target_module, quote
        # Write raw bytes
        @inline function $accessor_name_setter(m::$encoder_name, src::AbstractVector{UInt8})
            len = Base.length(src)
            $length_name_setter(m, len)
            pos = m.position_ptr[] + $header_length
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, src)
            return m
        end

        # Write string
        @inline function $accessor_name_setter(m::$encoder_name, src::AbstractString)
            bytes = codeunits(src)
            len = Base.length(bytes)
            $length_name_setter(m, len)
            pos = m.position_ptr[] + $header_length
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, bytes)
            return m
        end

        # Write typed array
        @inline function $accessor_name_setter(m::$encoder_name, src::AbstractArray{T}) where {T<:Real}
            bytes = reinterpret(UInt8, src)
            len = Base.length(bytes)
            $length_name_setter(m, len)
            pos = m.position_ptr[] + $header_length
            m.position_ptr[] = pos + len
            dest = view(m.buffer, pos+1:pos+len)
            copyto!(dest, bytes)
            return m
        end

        # Write symbol
        @inline function $accessor_name_setter(m::$encoder_name, src::Symbol)
            return $accessor_name_setter(m, to_string(src))
        end

        # Write tuple
        @inline function $accessor_name_setter(m::$encoder_name, src::NTuple{N,T}) where {N,T<:Real}
            bytes = reinterpret(UInt8, collect(src))
            return $accessor_name_setter(m, bytes)
        end

        # Write single numeric value
        @inline function $accessor_name_setter(m::$encoder_name, src::T) where {T<:Real}
            bytes = reinterpret(UInt8, [src])
            return $accessor_name_setter(m, bytes)
        end
    end)

    # Generate metadata constants
    metadata_prefix = Symbol(string(accessor_name, "_"))
    Core.eval(target_module, quote
        const $(Symbol(string(metadata_prefix, "id"))) = UInt16($(data_def.id))
        const $(Symbol(string(metadata_prefix, "since_version"))) = UInt16($(data_def.since_version))
        const $(Symbol(string(metadata_prefix, "header_length"))) = $header_length
    end)

    # Export the accessor functions
    Core.eval(target_module, quote
        export $accessor_name, $accessor_name_setter, $length_name, $length_name_setter, $skip_name
    end)

    return accessor_name
end

"""
    generateGroup!(target_module::Module, group_def::Schema.GroupDefinition, parent_name::String, schema::Schema.MessageSchema)

Generate code for a repeating group within a message or another group.

Groups are mutable structs that support the Julia iterator protocol, allowing
iteration over repeating elements in an SBE message.

# Arguments
- `target_module::Module`: Module where the group will be generated (usually the message module)
- `group_def::Schema.GroupDefinition`: Group definition from schema
- `parent_name::String`: Name of the parent message or group
- `schema::Schema.MessageSchema`: Complete schema for context

# Generated Components
1. Abstract type for the group
2. Mutable Decoder struct with iteration state
3. Mutable Encoder struct with iteration state
4. Constructor functions (read dimension header)
5. Iterator protocol (iterate, length, eltype)
6. next! function for encoding
7. Field accessors for group members
8. Nested group support (recursive)
9. Var data support within groups
"""
function generateGroup!(target_module::Module, group_def::Schema.GroupDefinition, parent_name::String, schema::Schema.MessageSchema)
    # Extract group metadata
    group_name = group_def.name
    group_id = group_def.id
    dimension_type = group_def.dimension_type

    # Create module for the group: fuelFigures -> FuelFigures module
    # Inside the module we'll have Decoder and Encoder types (like Car.Decoder, Car.Encoder)
    group_module_name = Symbol(uppercasefirst(group_name))

    # Create a separate module for this group (matching message and composite pattern)
    Core.eval(target_module, :(module $group_module_name end))
    group_module = getfield(target_module, group_module_name)

    # Import PositionPointer from SBE (not from parent module)
    # Groups are in Car module, so need to go up two levels: Car -> Baseline -> SBE
    Core.eval(group_module, :(using SBE: PositionPointer))

    # Generate the consistent encode/decode functions for this group module
    generateEncodedTypes!(group_module, schema)

    # Inside the module, we use simple names
    decoder_name = :Decoder
    encoder_name = :Encoder
    base_type_name = Symbol(group_module_name, "Type")  # FuelFiguresType

    # Calculate block length
    block_length = if group_def.block_length !== nothing
        parse(Int, group_def.block_length)
    else
        # Calculate from fields by summing their sizes
        total_size = 0
        for field in group_def.fields
            field_size = get_field_size(schema, field)
            total_size += field_size
        end
        total_size
    end

    # Calculate dimension header size from the composite type
    dimension_type_def = find_type_by_name(schema, dimension_type)
    dimension_header_size = if dimension_type_def !== nothing && dimension_type_def isa Schema.CompositeType
        calculate_composite_size(dimension_type_def, schema)
    else
        4  # Default fallback (2 UInt16s)
    end

    # Step 1: Import AbstractSbeGroup and generate concrete abstract type in group module
    Core.eval(group_module, :(using SBE: AbstractSbeGroup))

    Core.eval(group_module, quote
        abstract type $base_type_name{T} <: AbstractSbeGroup end
    end)

    # Step 2: Generate Decoder struct (mutable for iteration state)
    Core.eval(group_module, quote
        mutable struct $decoder_name{T<:AbstractArray{UInt8}} <: $base_type_name{T}
            const buffer::T
            offset::Int64
            const position_ptr::PositionPointer
            const block_length::UInt16
            const acting_version::UInt16
            const count::UInt16
            index::UInt16

            function $decoder_name(buffer::T, offset::Integer, position_ptr::PositionPointer,
                block_length::Integer, acting_version::Integer,
                count::Integer, index::Integer) where {T}
                new{T}(buffer, Int64(offset), position_ptr, UInt16(block_length),
                       UInt16(acting_version), UInt16(count), UInt16(index))
            end
        end
    end)

    # Step 3: Generate Encoder struct (mutable for iteration state)
    Core.eval(group_module, quote
        mutable struct $encoder_name{T<:AbstractArray{UInt8}} <: $base_type_name{T}
            const buffer::T
            offset::Int64
            const position_ptr::PositionPointer
            const initial_position::Int64
            count::UInt16  # NOT const - can be updated by reset_count_to_index!
            index::UInt16

            function $encoder_name(buffer::T, offset::Integer, position_ptr::PositionPointer,
                initial_position::Int64, count::Integer, index::Integer) where {T}
                new{T}(buffer, Int64(offset), position_ptr, initial_position,
                       UInt16(count), UInt16(index))
            end
        end
    end)

    # Step 4: Generate constructors that read dimension header
    # Find the dimension type (usually GroupSizeEncoding)
    dimension_module = Symbol(uppercasefirst(dimension_type))

    # Decoder constructor: reads dimension header from buffer
    Core.eval(group_module, quote
        @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version)
            # Access dimension module from schema module (walk up to find it)
            # For top-level groups: Car.FuelFigures -> Car -> Baseline
            # For nested groups: Car.PerformanceFigures.Acceleration -> PerformanceFigures -> Car -> Baseline
            schema_module = parentmodule(parentmodule(@__MODULE__))
            # Check if we're nested (if parent's parent has a parent that's not Main/SBE)
            if isdefined(parentmodule(schema_module), :SCHEMA)
                # We're nested, go up one more level
                schema_module = parentmodule(schema_module)
            end
            dimensions = getfield(schema_module, $(QuoteNode(dimension_module))).Decoder(buffer, position_ptr[])
            position_ptr[] += $dimension_header_size  # Skip dimension header
            block_len = getfield(schema_module, $(QuoteNode(dimension_module))).blockLength(dimensions)
            num_in_group = getfield(schema_module, $(QuoteNode(dimension_module))).numInGroup(dimensions)
            return $decoder_name(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end

        # Decoder constructor for empty group (version handling)
        # This constructor is used when the group is not in the acting version
        @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return $decoder_name(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
    end)

    # Encoder constructor: writes dimension header to buffer
    Core.eval(group_module, quote
        @inline function $encoder_name(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            # Access dimension module from schema module (same logic as decoder)
            schema_module = parentmodule(parentmodule(@__MODULE__))
            if isdefined(parentmodule(schema_module), :SCHEMA)
                schema_module = parentmodule(schema_module)
            end
            dimensions = getfield(schema_module, $(QuoteNode(dimension_module))).Encoder(buffer, position_ptr[])
            getfield(schema_module, $(QuoteNode(dimension_module))).blockLength!(dimensions, UInt16($block_length))
            getfield(schema_module, $(QuoteNode(dimension_module))).numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += $dimension_header_size  # Skip dimension header
            return $encoder_name(buffer, 0, position_ptr, initial_position, count, 0)
        end
    end)

    # Step 5: Generate group accessor functions in parent message/group
    # These allow accessing the group from the parent: car.fuelFigures() or car.fuelFigures!(count)
    accessor_name = Symbol(toCamelCase(group_name))  # fuelFigures
    accessor_name_encoder = Symbol(string(accessor_name, "!"))  # fuelFigures!
    since_version = group_def.since_version

    # The parent type is the Decoder/Encoder from the containing module
    # If we're in Car module, parent is Car.Decoder/Car.Encoder
    parent_decoder = :Decoder
    parent_encoder = :Encoder

    if since_version > 0
        # Version-aware group accessor
        Core.eval(target_module, quote
            # Decoder accessor: Returns group decoder instance or empty group if not in version
            @inline function $accessor_name(m::$parent_decoder)
                if m.acting_version < UInt16($since_version)
                    # Return empty group (count=0) when group not in version
                    return $group_module_name.$decoder_name(m.buffer, sbe_position_ptr(m), m.acting_version, UInt16(0), UInt16(0))
                end
                # Access acting_version field directly from decoder
                return $group_module_name.$decoder_name(m.buffer, sbe_position_ptr(m), m.acting_version)
            end

            # Encoder accessor: Returns group encoder instance with specified count
            @inline function $accessor_name_encoder(m::$parent_encoder, count)
                return $group_module_name.$encoder_name(m.buffer, count, sbe_position_ptr(m))
            end

            # Metadata functions for the group
            $(Symbol(accessor_name, :_id))(::Union{$parent_decoder, $parent_encoder}) = $group_id
            $(Symbol(accessor_name, :_since_version))(::Union{$parent_decoder, $parent_encoder}) = $since_version
            $(Symbol(accessor_name, :_in_acting_version))(m::Union{$parent_decoder, $parent_encoder}) = begin
                # Access acting_version directly for decoder, use schema version for encoder
                acting_ver = m isa $parent_decoder ? m.acting_version : UInt16($(schema.version))
                acting_ver >= $since_version
            end

            # Export the accessor functions
            export $accessor_name, $accessor_name_encoder
        end)
    else
        # Non-versioned group accessor (version 0)
        Core.eval(target_module, quote
            # Decoder accessor: Returns group decoder instance
            @inline function $accessor_name(m::$parent_decoder)
                # Access acting_version field directly from decoder
                return $group_module_name.$decoder_name(m.buffer, sbe_position_ptr(m), m.acting_version)
            end

            # Encoder accessor: Returns group encoder instance with specified count
            @inline function $accessor_name_encoder(m::$parent_encoder, count)
                return $group_module_name.$encoder_name(m.buffer, count, sbe_position_ptr(m))
            end

            # Metadata functions for the group
            $(Symbol(accessor_name, :_id))(::Union{$parent_decoder, $parent_encoder}) = $group_id
            $(Symbol(accessor_name, :_since_version))(::Union{$parent_decoder, $parent_encoder}) = $(group_def.since_version)
            $(Symbol(accessor_name, :_in_acting_version))(m::Union{$parent_decoder, $parent_encoder}) = begin
                # Access acting_version directly for decoder, use schema version for encoder
                acting_ver = m isa $parent_decoder ? m.acting_version : UInt16($(schema.version))
                acting_ver >= $(group_def.since_version)
            end

            # Export the accessor functions
            export $accessor_name, $accessor_name_encoder
        end)
    end

    # Step 6: Generate SBE interface methods for groups (in group module)
    # Only generate group-specific metadata, position/iteration come from AbstractSbeGroup
    Core.eval(group_module, quote
        # Import SBE module and shared group functions
        import SBE
        using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!

        # Block length metadata (extend SBE.sbe_acting_block_length)
        SBE.sbe_block_length(::Union{$decoder_name, $encoder_name}) = UInt16($block_length)
        SBE.sbe_acting_block_length(g::$decoder_name) = g.block_length
        SBE.sbe_acting_block_length(::$encoder_name) = UInt16($block_length)

        # Acting version metadata (extend SBE.sbe_acting_version)
        SBE.sbe_acting_version(g::$decoder_name) = g.acting_version
        SBE.sbe_acting_version(::$encoder_name) = UInt16($(schema.version))

        # Element type for iteration
        Base.eltype(::Type{<:$decoder_name}) = $decoder_name
        Base.eltype(::Type{<:$encoder_name}) = $encoder_name

        # Export next! for encoding pattern
        export next!
    end)

    # Step 7: Iterator protocol now comes from AbstractSbeGroup
    # Only need to import the Base methods here
    Core.eval(group_module, quote
        # Import iterator protocol from AbstractSbeGroup
        using SBE: Base.iterate, Base.length, Base.isdone
    end)

    # Step 8: Generate reset_count_to_index! for encoders (in group module)
    # This updates the dimension header with the actual number of elements written
    Core.eval(group_module, quote
        function reset_count_to_index!(g::$encoder_name)
            g.count = g.index
            # Access dimension module from schema module (same logic as constructors)
            schema_module = parentmodule(parentmodule(@__MODULE__))
            if isdefined(parentmodule(schema_module), :SCHEMA)
                schema_module = parentmodule(schema_module)
            end
            dimensions = getfield(schema_module, $(QuoteNode(dimension_module))).Encoder(g.buffer, g.initial_position)
            getfield(schema_module, $(QuoteNode(dimension_module))).numInGroup!(dimensions, g.count)
            return g.count
        end

        # Export reset_count_to_index!
        export reset_count_to_index!
    end)

    # Step 9: Generate field accessors for group members (in group module)
    # Fields in groups use relative offsets from the current group element's position (m.offset)
    # Calculate cumulative offsets for fields that don't have explicit offsets
    current_offset = 0
    for field in group_def.fields
        # Use explicit offset if non-zero, otherwise use cumulative offset
        actual_offset = field.offset != 0 ? field.offset : current_offset

        # Create a modified field definition with the calculated offset
        modified_field = Schema.FieldDefinition(
            field.name, field.id, field.type_ref, actual_offset, field.description,
            field.since_version, field.presence, field.value_ref, field.epoch,
            field.time_unit, field.semantic_type, field.deprecated
        )

        generateFields!(group_module, decoder_name, encoder_name, modified_field, group_name, schema)

        # Advance offset for next field
        field_size = get_field_size(schema, field)
        current_offset = actual_offset + field_size
    end

    # Step 10: Generate nested groups recursively
    # Nested groups follow the same pattern but are scoped within the parent group module
    if !isempty(group_def.groups)
        for nested_group_def in group_def.groups
            generateGroup!(group_module, nested_group_def, group_name, schema)
        end
    end

    # Step 11: Generate var data accessors for group members
    # Variable-length data in groups uses the shared position pointer
    if !isempty(group_def.var_data)
        for var_data_def in group_def.var_data
            generateVarData!(group_module, var_data_def, group_name, schema)
        end
    end

    # Export the group module itself so users can access FuelFigures.Decoder and FuelFigures.Encoder
    Core.eval(target_module, quote
        export $group_module_name
    end)

    return group_module_name
end

"""
    calculate_composite_size(composite_def::Schema.CompositeType, schema::Schema.MessageSchema)

Calculate the size of a composite type (for variable data headers).

# Arguments
- `composite_def::Schema.CompositeType`: Composite type definition
- `schema::Schema.MessageSchema`: Complete schema for resolving RefTypes

# Returns
- `Int`: Total size in bytes of the composite
"""
function calculate_composite_size(composite_def::Schema.CompositeType, schema::Schema.MessageSchema)
    total_size = 0
    for member in composite_def.members
        if member isa Schema.EncodedType
            # Skip constant members - they don't occupy space
            if member.presence == "constant"
                continue
            end
            julia_type = to_julia_type(member.primitive_type)
            total_size += sizeof(julia_type) * member.length
        elseif member isa Schema.RefType
            # Recursively calculate size of referenced type
            ref_type_def = find_type_by_name(schema, member.type_ref)
            if ref_type_def !== nothing
                if ref_type_def isa Schema.EncodedType
                    # Skip constant refs
                    if ref_type_def.presence == "constant"
                        continue
                    end
                    ref_julia_type = to_julia_type(ref_type_def.primitive_type)
                    total_size += sizeof(ref_julia_type) * ref_type_def.length
                elseif ref_type_def isa Schema.CompositeType
                    # Recursively calculate composite size
                    total_size += calculate_composite_size(ref_type_def, schema)
                elseif ref_type_def isa Schema.EnumType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    total_size += sizeof(encoding_type)
                elseif ref_type_def isa Schema.SetType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    total_size += sizeof(encoding_type)
                end
            end
        elseif member isa Schema.EnumType
            # Inline enum definition
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        elseif member isa Schema.SetType
            # Inline set definition
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        end
    end
    return total_size
end

"""
    to_pascal_case(name::String)

Convert snake_case to PascalCase for type names.

# Arguments
- `name::String`: Snake case string (e.g., "my_field_name")

# Returns
- `String`: PascalCase string (e.g., "MyFieldName")
"""
function to_pascal_case(name::String)
    parts = split(name, '_')
    return join([uppercasefirst(part) for part in parts])
end

"""
    to_julia_type(primitive_type::String)

Convert SBE primitive type name to Julia type.

# Arguments
- `primitive_type::String`: SBE primitive type name (e.g., "uint32", "float")

# Returns
- `Type`: Corresponding Julia type (e.g., `UInt32`, `Float32`)
"""
function to_julia_type(primitive_type::String)
    type_map = Dict(
        "char" => UInt8,
        "int8" => Int8,
        "uint8" => UInt8,
        "int16" => Int16,
        "uint16" => UInt16,
        "int32" => Int32,
        "uint32" => UInt32,
        "int64" => Int64,
        "uint64" => UInt64,
        "float" => Float32,
        "double" => Float64
    )

    return get(type_map, primitive_type, UInt8)
end

"""
    parse_typed_value(value_str::String, julia_type::Type)

Parse a typed value from string representation.

# Arguments
- `value_str::String`: String representation of the value
- `julia_type::Type`: Target Julia type for parsing

# Returns
- `julia_type`: Parsed value of the specified type, or fallback value if parsing fails
"""
function parse_typed_value(value_str::String, julia_type::Type)
    try
        return parse(julia_type, value_str)
    catch
        # Fallback for special values
        if julia_type <: Unsigned
            return typemax(julia_type)
        else
            return zero(julia_type)
        end
    end
end

"""
    find_type_by_name(schema::Schema.MessageSchema, type_name::String)

Find a type definition by name in the schema.

# Arguments
- `schema::Schema.MessageSchema`: Schema to search in
- `type_name::String`: Name of the type to find

# Returns
- Type definition object if found, `nothing` otherwise
"""
function find_type_by_name(schema::Schema.MessageSchema, type_name::String)
    for type_def in schema.types
        if type_def.name == type_name
            return type_def
        end
    end
    return nothing
end

"""
    is_primitive_type(type_name::String)

Check if a type name is a built-in SBE primitive type.

# Arguments
- `type_name::String`: Type name to check

# Returns
- `Bool`: true if it's a primitive type (uint8, uint16, etc.)
"""
function is_primitive_type(type_name::String)
    return type_name in ["uint8", "uint16", "uint32", "uint64",
                         "int8", "int16", "int32", "int64",
                         "float", "double", "char"]
end

"""
    create_primitive_encoded_type(primitive_type::String, length::Int=1)

Create a synthetic EncodedType for a primitive type reference.

This is used when fields reference built-in types directly (e.g., type="uint64")
rather than named types in the schema.

# Arguments
- `primitive_type::String`: Primitive type name (uint64, int32, etc.)
- `length::Int`: Array length (1 for scalar, >1 for array)

# Returns
- `Schema.EncodedType`: Synthetic encoded type definition
"""
function create_primitive_encoded_type(primitive_type::String, length::Int=1)
    # Get default values for this primitive type
    julia_type = to_julia_type(primitive_type)

    return Schema.EncodedType(
        primitive_type,                          # name
        primitive_type,                          # primitive_type
        length,                                  # length
        string(typemax(julia_type)),            # null_value - SBE convention: max value is null
        string(typemin(julia_type)),            # min_value
        string(typemax(julia_type) - (julia_type <: Unsigned ? 1 : 0)),  # max_value - max valid is max-1 for unsigned
        primitive_type == "char" ? "ASCII" : nothing,  # character_encoding
        nothing,                                 # offset (will be set by field)
        "required",                              # presence
        nothing,                                 # constant_value
        nothing,                                 # semantic_type
        "",                                      # description
        0,                                       # since_version
        nothing                                  # deprecated
    )
end

"""
    toCamelCase(name::String)

Convert snake_case to camelCase for field names.

# Arguments
- `name::String`: Snake case string (e.g., "my_field_name")

# Returns
- `String`: camelCase string (e.g., "myFieldName")
"""
function toCamelCase(name::String)
    parts = split(name, '_')
    if length(parts) == 1
        return name
    end
    return parts[1] * join([uppercasefirst(part) for part in parts[2:end]])
end

"""
    parse_constant_value(julia_type::Type, value_str::String)

Parse a constant value string into the appropriate Julia type.

# Arguments
- `julia_type::Type`: Julia type for the constant
- `value_str::String`: String representation of the constant value

# Returns
- Parsed constant value of the specified type
"""
function parse_constant_value(julia_type::Type, value_str::String)
    if julia_type <: Integer
        # Parse integer values (handles decimal, hex, etc.)
        return parse(julia_type, value_str)
    elseif julia_type == UInt8  # char
        # For single char, take first character
        if length(value_str) == 1
            return UInt8(value_str[1])
        else
            error("Single char constant must be exactly one character, got: $value_str")
        end
    elseif julia_type <: AbstractFloat
        return parse(julia_type, value_str)
    else
        error("Unsupported constant type: $julia_type")
    end
end

"""
    get_null_value(julia_type::Type, member::Schema.EncodedType)

Get null value for a type and member.

# Arguments
- `julia_type::Type`: Julia type for the member
- `member::Schema.EncodedType`: Schema member definition

# Returns
- Null value following SBE conventions (max for unsigned, min for signed)
"""
function get_null_value(julia_type::Type, member::Schema.EncodedType)
    if member.null_value !== nothing
        try
            return parse(julia_type, member.null_value)
        catch
            # Fallback
        end
    end

    # Default null values based on SBE spec
    if julia_type <: AbstractFloat
        # For floating point types, use NaN as null value
        return julia_type(NaN)
    elseif julia_type <: Unsigned
        return typemax(julia_type)
    else
        return typemin(julia_type)
    end
end

"""
    get_min_value(julia_type::Type, member::Schema.EncodedType)

Get min value for a type and member.

# Arguments
- `julia_type::Type`: Julia type for the member
- `member::Schema.EncodedType`: Schema member definition

# Returns
- Minimum value from schema or type minimum
"""
function get_min_value(julia_type::Type, member::Schema.EncodedType)
    if member.min_value !== nothing
        try
            return parse(julia_type, member.min_value)
        catch
            # Fallback
        end
    end
    return typemin(julia_type)
end

"""
    get_max_value(julia_type::Type, member::Schema.EncodedType)

Get max value for a type and member.

# Arguments
- `julia_type::Type`: Julia type for the member
- `member::Schema.EncodedType`: Schema member definition

# Returns
- Maximum value from schema or type maximum
"""
function get_max_value(julia_type::Type, member::Schema.EncodedType)
    if member.max_value !== nothing
        try
            return parse(julia_type, member.max_value)
        catch
            # Fallback
        end
    end
    return typemax(julia_type)
end

"""
    get_field_size(schema::Schema.MessageSchema, field::Schema.FieldDefinition)

Get the size in bytes of a field based on its type definition.

# Arguments
- `schema::Schema.MessageSchema`: Schema containing type definitions
- `field::Schema.FieldDefinition`: Field to calculate size for

# Returns
- `Int`: Size in bytes, or 0 if type unknown/non-encoded
"""
function get_field_size(schema::Schema.MessageSchema, field::Schema.FieldDefinition)
    # Constant fields don't occupy space in the message block
    if field.presence == "constant"
        return 0
    end

    # Check if it's a built-in primitive type first
    if is_primitive_type(field.type_ref)
        julia_type = to_julia_type(field.type_ref)
        return sizeof(julia_type)
    end

    # Otherwise look it up in the schema
    type_def = find_type_by_name(schema, field.type_ref)
    if type_def === nothing
        return 0  # Unknown type, assume no size
    end

    if type_def isa Schema.EncodedType
        julia_type = to_julia_type(type_def.primitive_type)
        return sizeof(julia_type) * type_def.length
    elseif type_def isa Schema.CompositeType
        # Calculate composite size by summing all member sizes (excluding constants)
        total_size = 0
        for member in type_def.members
            if member isa Schema.EncodedType
                # Skip constant members - they don't occupy space
                if member.presence == "constant"
                    continue
                end
                member_type = to_julia_type(member.primitive_type)
                total_size += sizeof(member_type) * member.length
            elseif member isa Schema.RefType
                # Recursively calculate size of referenced type
                ref_type_def = find_type_by_name(schema, member.type_ref)
                if ref_type_def !== nothing
                    if ref_type_def isa Schema.EncodedType
                        # Skip constant refs
                        if ref_type_def.presence == "constant"
                            continue
                        end
                        ref_julia_type = to_julia_type(ref_type_def.primitive_type)
                        total_size += sizeof(ref_julia_type) * ref_type_def.length
                    elseif ref_type_def isa Schema.CompositeType
                        # Recursively calculate composite size
                        total_size += get_field_size(schema, Schema.FieldDefinition(
                            member.name, UInt16(0), member.type_ref, 0, "", 0, "required",
                            nothing, "", nothing, nothing, nothing
                        ))
                    elseif ref_type_def isa Schema.EnumType
                        encoding_type = to_julia_type(ref_type_def.encoding_type)
                        total_size += sizeof(encoding_type)
                    elseif ref_type_def isa Schema.SetType
                        encoding_type = to_julia_type(ref_type_def.encoding_type)
                        total_size += sizeof(encoding_type)
                    end
                end
            elseif member isa Schema.EnumType
                # Inline enum definition
                encoding_type = to_julia_type(member.encoding_type)
                total_size += sizeof(encoding_type)
            elseif member isa Schema.SetType
                # Inline set definition
                encoding_type = to_julia_type(member.encoding_type)
                total_size += sizeof(encoding_type)
            end
        end
        return total_size
    elseif type_def isa Schema.EnumType
        # Enum size is determined by its encoding type
        encoding_type = to_julia_type(type_def.encoding_type)
        return sizeof(encoding_type)
    elseif type_def isa Schema.SetType
        # Set size is determined by its encoding type
        encoding_type = to_julia_type(type_def.encoding_type)
        return sizeof(encoding_type)
    else
        return 0  # Unknown type
    end
end

"""
    generateChoiceSet!(target_module::Module, set_def::Schema.SetType, schema::Schema.MessageSchema)

Generate a complete Set type implementation with decoder/encoder and all choice methods.

Set types in SBE are encoded as bitsets where each choice corresponds to a bit position.
Following the baseline OptionalExtras pattern, this creates decoder/encoder types,
bit manipulation functions, and individual choice accessor functions.

# Arguments
- `target_module::Module`: Module to generate the type in
- `set_def::Schema.SetType`: Set type definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Symbol`: Name of the generated set type

# Generated Components
- Main set type with buffer and offset
- Decoder/Encoder type aliases
- SBE interface methods (id, since_version, encoding_*, etc.)
- Bit manipulation functions (clear!, is_empty, raw_value)
- Individual choice accessor functions

# Example Generated Interface
```julia
# For OptionalExtras with choices sunRoof(0), sportsPack(1), cruiseControl(2)
extras = OptionalExtras(buffer, offset)
clear!(extras)              # Set all bits to 0
is_empty(extras)             # Check if no bits are set
raw_value(extras)            # Get raw underlying value
sunRoof(extras)              # Check if sunRoof bit is set
sunRoof!(extras, true)       # Set/clear sunRoof bit
sportsPack(extras)           # Check if sportsPack bit is set
sportsPack!(extras, false)   # Set/clear sportsPack bit
```

# Bit Position Mapping
Each choice in the schema maps to a specific bit position in the underlying integer type.
The bit operations use proper endianness-aware encoding/decoding via the generated
encode_value/decode_value functions.
"""
function generateChoiceSet!(target_module::Module, set_def::Schema.SetType, schema::Schema.MessageSchema)
    set_name = Symbol(to_pascal_case(set_def.name))

    # Create a nested module for the set type (consistent with message/composite pattern)
    set_module_name = set_name
    Core.eval(target_module, :(module $set_module_name end))
    set_module = getfield(target_module, set_module_name)

    # Use <Name>Struct pattern for clarity (OptionalExtras.OptionalExtrasStruct)
    struct_name = Symbol(string(set_name, "Struct"))
    decoder_name = :Decoder
    encoder_name = :Encoder

    # Get the underlying primitive type for the bitset
    encoding_julia_type = to_julia_type(set_def.encoding_type)
    encoding_size = sizeof(encoding_julia_type)

    # Import necessary utilities into the set module
    Core.eval(set_module, :(using SBE: AbstractSbeEncodedType))

    # Generate the consistent encode/decode functions for this module
    generateEncodedTypes!(set_module, schema)

    # Generate the main Set type structure in the set module
    Core.eval(set_module, quote
        struct $struct_name{T<:AbstractVector{UInt8}} <: AbstractSbeEncodedType
            buffer::T
            offset::Int
        end

        # Create decoder and encoder aliases (following SBE patterns)
        const $decoder_name = $struct_name
        const $encoder_name = $struct_name

        export $decoder_name, $encoder_name
    end)

    # Generate outer constructor for convenience (provide default offset)
    # Only handle 1-argument case - 2 arguments handled by default constructor
    Core.eval(set_module, quote
        # 1-argument: buffer only (use default offset of 0)
        @inline function $struct_name(buffer::AbstractVector{UInt8})
            $struct_name(buffer, Int64(0))
        end
    end)

    # Generate SBE interface methods in the set module
    Core.eval(set_module, quote
        # SBE interface - Set types have no specific id/since_version typically
        id(::Type{<:$struct_name}) = UInt16(0xffff)  # Default for composite elements
        id(::$struct_name) = UInt16(0xffff)
        since_version(::Type{<:$struct_name}) = UInt16($(set_def.since_version))
        since_version(::$struct_name) = UInt16($(set_def.since_version))

        # Encoding information
        encoding_offset(::Type{<:$struct_name}) = $(something(set_def.offset, 0))
        encoding_offset(::$struct_name) = $(something(set_def.offset, 0))
        encoding_length(::Type{<:$struct_name}) = $encoding_size
        encoding_length(::$struct_name) = $encoding_size

        # Type information
        Base.eltype(::Type{<:$struct_name}) = $encoding_julia_type
        Base.eltype(::$struct_name) = $encoding_julia_type
    end)

    # Generate basic set operations (clear, empty check, raw access) in the set module
    Core.eval(set_module, quote
        # Clear all bits (set to zero)
        @inline function clear!(set::$encoder_name)
            encode_value($encoding_julia_type, set.buffer, set.offset, zero($encoding_julia_type))
            return set
        end

        # Check if the set is empty (no bits set)
        @inline function is_empty(set::$decoder_name)
            return decode_value($encoding_julia_type, set.buffer, set.offset) == zero($encoding_julia_type)
        end

        # Get the raw underlying value
        @inline function raw_value(set::$decoder_name)
            return decode_value($encoding_julia_type, set.buffer, set.offset)
        end

        export clear!, is_empty, raw_value
    end)

    # Generate individual choice accessor functions in the set module
    for choice in set_def.choices
        choice_func_name = Symbol(toCamelCase(choice.name))
        choice_func_name_set = Symbol(string(choice_func_name, "!"))
        bit_position = choice.bit_position

        Core.eval(set_module, quote
            # Check if this choice bit is set
            @inline function $choice_func_name(set::$decoder_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset) & ($encoding_julia_type(0x1) << $bit_position) != 0
            end

            # Set or clear this choice bit
            @inline function $choice_func_name_set(set::$encoder_name, value::Bool)
                bits = decode_value($encoding_julia_type, set.buffer, set.offset)
                bits = value ? (bits | ($encoding_julia_type(0x1) << $bit_position)) : (bits & ~($encoding_julia_type(0x1) << $bit_position))
                encode_value($encoding_julia_type, set.buffer, set.offset, bits)
                return set
            end

            export $choice_func_name, $choice_func_name_set
        end)
    end

    # Export the set module itself from the parent module
    Core.eval(target_module, :(export $set_module_name))

    return set_name
end
