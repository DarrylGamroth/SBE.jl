# SBE Code Generation Utilities
#
# This file contains:
# 1. Abstract type definitions and runtime support for generated code
# 2. Code generation helpers for IR-based generation

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

"""
Common group interface functions for AbstractSbeGroup types.
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
    @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = htol(T(value))
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
    @inbounds reinterpret(T, view(buffer, offset+1:offset+sizeof(T)))[] = hton(T(value))
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
"""
@inline function to_string(s::Symbol)
    p = Base.unsafe_convert(Ptr{UInt8}, s)
    len = @ccall strlen(p::Ptr{UInt8})::Csize_t
    return StringView(UnsafeArray(p, (unsafe_trunc(Int64, len),)))
end

# ============================================================================
# Expression to String Conversion Utilities
# ============================================================================

"""
    expr_to_code_string(expr::Expr) -> String

Convert a Julia expression to a clean code string suitable for writing to a file
or using with include_string.
"""
function expr_to_code_string(expr::Expr)
    # Remove line numbers for cleaner output
    expr_clean = Base.remove_linenums!(deepcopy(expr))

    # Unwrap blocks when possible to avoid top-level begin...end wrappers.
    code_str = if expr_clean.head == :block
        args = [arg for arg in expr_clean.args if !(arg isa LineNumberNode)]
        if length(args) == 1
            string(args[1])
        elseif !isempty(args) && args[1] isa Expr && args[1].head == :module
            join(string.(args), "\n\n")
        else
            string(expr_clean)
        end
    else
        string(expr_clean)
    end

    # Remove any remaining line number comments (e.g., "#= file.jl:123 =#")
    # This is a simple regex-based cleanup for generated code
    code_str = replace(code_str, r"#=.*?=#\s*"s => "")

    # Remove excessive blank lines (more than 2 consecutive newlines)
    code_str = replace(code_str, r"\n{3,}" => "\n\n")

    return String(strip(code_str))
end

"""
    extract_expr_from_quote(quoted::Expr, expr_head::Symbol=:any) -> Expr

Extract the first non-LineNumberNode expression from a quote block.
If `expr_head` is specified, only return expressions with that head.
"""
function extract_expr_from_quote(quoted::Expr, expr_head::Symbol=:any)
    for arg in quoted.args
        if arg isa Expr
            if expr_head == :any || arg.head == expr_head
                return arg
            end
        end
    end
    if expr_head == :any
        error("Failed to extract expression from quote block")
    else
        error("Failed to extract :$expr_head expression from quote block")
    end
end

# ============================================================================
# IR-based Code Generation
# ============================================================================

"""
    generate(xml_path::String, output_path::String; module_name=nothing) -> String

Generate Julia code from an SBE schema XML file and write it to `output_path`.
"""
function generate(xml_path::String, output_path::String; module_name::Union{Nothing, Symbol, String}=nothing)
    # Verify input file exists
    if !isfile(xml_path)
        error("Schema file not found: $xml_path")
    end

    # Parse XML and generate IR
    xml_content = read(xml_path, String)
    schema = parse_xml_schema(xml_content)
    ir = generate_ir(schema)

    # Generate the module expression from IR
    module_expr = generate_ir_module_expr(ir; module_name=module_name)

    # Convert to code string
    module_code = expr_to_code_string(module_expr)

    # Create output directory if needed
    output_dir = dirname(output_path)
    if !isempty(output_dir) && !isdir(output_dir)
        mkpath(output_dir)
    end

    # Write to output file
    write(output_path, module_code)

    # Return the output path
    return output_path
end

"""
    generate(xml_path::String; module_name=nothing) -> String

Generate Julia code from an SBE schema XML file and return it as a string.
"""
function generate(xml_path::String; module_name::Union{Nothing, Symbol, String}=nothing)
    # Verify input file exists
    if !isfile(xml_path)
        error("Schema file not found: $xml_path")
    end

    # Parse XML and generate IR
    xml_content = read(xml_path, String)
    schema = parse_xml_schema(xml_content)
    ir = generate_ir(schema)

    # Generate the complete module expression from IR
    module_expr = generate_ir_module_expr(ir; module_name=module_name)

    # Convert to code string and return
    return expr_to_code_string(module_expr)
end
