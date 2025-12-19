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
# Expression to String Conversion Utilities
# ============================================================================

"""
    expr_to_code_string(expr::Expr) -> String

Convert a Julia expression to a clean code string suitable for writing to a file
or using with include_string.

This function:
1. Removes line number nodes for cleaner output
2. Unwraps single-element quote blocks
3. Converts the expression to a properly formatted string
4. Removes any remaining line number comments

# Arguments
- `expr::Expr`: The expression to convert (typically from a `quote` block)

# Returns
- `String`: Clean Julia code as a string

# Example
```julia
expr = quote
    module MyModule
        struct MyStruct
            field::Int
        end
    end
end

code = expr_to_code_string(expr)
# Returns: "module MyModule\\n    struct MyStruct\\n        field::Int\\n    end\\nend"
```
"""
function expr_to_code_string(expr::Expr)
    # Remove line numbers for cleaner output
    expr_clean = Base.remove_linenums!(deepcopy(expr))
    
    # Unwrap single-element quote blocks (quote...end becomes begin...end)
    # We need to extract the actual content
    code_str = if expr_clean.head == :block && length(expr_clean.args) == 1
        string(expr_clean.args[1])
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

# ============================================================================
# Helper Function for Expression Extraction
# ============================================================================

"""
    extract_expr_from_quote(quoted::Expr, expr_head::Symbol=:any) -> Expr

Extract the first non-LineNumberNode expression from a quote block.
If `expr_head` is specified, only return expressions with that head.

This is used to unwrap quote blocks without introducing begin...end wrappers
when generating code for file-based loading.
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
# Shared Encode/Decode Functions for Consistent Endianness Handling
# ============================================================================

"""
    generateEncodedTypes_expr(schema::Schema.MessageSchema) -> Expr

Generate endianness-specific encode/decode imports as an expression (for file-based generation).

This is the expression-returning version of `generateEncodedTypes!()`. Returns a quote block
that imports the appropriate endianness-specific functions and creates const aliases that
can be used throughout the generated code.

# Arguments
- `schema::Schema.MessageSchema`: Schema containing byte order information

# Returns
- `Expr`: Quote block with imports and const aliases for encode/decode functions

# Example
```julia
expr = generateEncodedTypes_expr(schema)
# Returns (for littleEndian):
# quote
#     import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le
#     const encode_value = encode_value_le
#     const decode_value = decode_value_le
#     const encode_array = encode_array_le
#     const decode_array = decode_array_le
# end
```
"""
function generateEncodedTypes_expr(schema::Schema.MessageSchema)
    if schema.byte_order == "bigEndian"
        return quote
            import SBE: encode_value_be, decode_value_be, encode_array_be, decode_array_be

            const encode_value = encode_value_be
            const decode_value = decode_value_be
            const encode_array = encode_array_be
            const decode_array = decode_array_be
        end
    else
        return quote
            import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le

            const encode_value = encode_value_le
            const decode_value = decode_value_le
            const encode_array = encode_array_le
            const decode_array = decode_array_le
        end
    end
end

# ============================================================================
# Shared Type Generation Functions
# ============================================================================

"""
    generateFields_expr(abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, field_def::Schema.FieldDefinition, parent_name::String, schema::Schema.MessageSchema) -> Vector{Expr}

Expression-returning version of `generateFields!()` for file-based generation.

Returns a vector of expressions that generate field accessors for a given field definition.
These expressions can be inserted into a module body for file-based code generation.

# Arguments
- `abstract_type_name::Symbol`: Name of the abstract type for the group/message
- `decoder_name::Symbol`: Name of the decoder struct (usually :Decoder)
- `encoder_name::Symbol`: Name of the encoder struct (usually :Encoder)
- `field_def::Schema.FieldDefinition`: Field definition from schema
- `parent_name::String`: Name of the parent message or group
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Vector{Expr}`: Vector of expressions for field accessors and metadata
"""
function generateFields_expr(abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, field_def::Schema.FieldDefinition, parent_name::String, schema::Schema.MessageSchema)
    # Use camelCase for field names (matches baseline)
    field_name = Symbol(toCamelCase(field_def.name))

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
        return Expr[]
    end

    field_offset = field_def.offset

    # Handle different type categories - return vector of expressions
    if type_def isa Schema.EncodedType
        # Primitive types (int, float, char arrays, etc.)
        result = generate_encoded_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name)
        return result === nothing ? Expr[] : result
    elseif type_def isa Schema.EnumType
        # Enum types
        result = generate_enum_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name, schema)
        return result === nothing ? Expr[] : result
    elseif type_def isa Schema.SetType
        # Set/BitSet types
        result = generate_set_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name)
        return result === nothing ? Expr[] : result
    elseif type_def isa Schema.CompositeType
        # Composite types
        result = generate_composite_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name, schema)
        return result === nothing ? Expr[] : result
    else
        @warn "Skipping field $(field_def.name): unsupported type $(typeof(type_def))"
        return Expr[]
    end
end

"""
    generateEnum_expr(enum_def::Schema.EnumType, schema::Schema.MessageSchema) -> Expr

Generate an enum type definition as an expression (for file-based generation).

This is the expression-returning version of `generateEnum!()`. Instead of evaluating
the code in a module with `Core.eval`, it returns the expression that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `enum_def::Schema.EnumType`: Enum definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Expr`: A quote block containing the complete enum definition

# Example
```julia
expr = generateEnum_expr(enum_def, schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
```julia
quote
    using EnumX
    
    @enumx T = SbeEnum EnumName::UInt8 begin
        VALUE1 = 0x00
        VALUE2 = 0x01
        NULL_VALUE = 0xff
    end
end
```
"""
function generateEnum_expr(enum_def::Schema.EnumType, schema::Schema.MessageSchema)
    enum_name = Symbol(to_pascal_case(enum_def.name))
    encoding_julia_type = to_julia_type(enum_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)

    # Build enum values
    enum_values = Expr[]

    for valid_value in enum_def.values
        value_name = Symbol(valid_value.name)

        # Parse the value - could be numeric or character
        if enum_def.encoding_type == "char"
            # Character values - convert to UInt8
            if length(valid_value.value) == 1
                char_val = UInt8(valid_value.value[1])
                push!(enum_values, :($value_name = $encoding_type_symbol($char_val)))
            else
                # Handle special values
                try
                    parsed_val = parse(encoding_julia_type, valid_value.value)
                    push!(enum_values, :($value_name = $encoding_type_symbol($parsed_val)))
                catch
                    # Default to the first character
                    char_val = UInt8(valid_value.value[1])
                    push!(enum_values, :($value_name = $encoding_type_symbol($char_val)))
                end
            end
        else
            # Numeric values
            try
                parsed_val = parse(encoding_julia_type, valid_value.value)
                push!(enum_values, :($value_name = $encoding_type_symbol($parsed_val)))
            catch
                # Fallback to 0
                push!(enum_values, :($value_name = $encoding_type_symbol(0)))
            end
        end
    end

    # Add NULL_VALUE - use the encoding's null value if available, otherwise default
    null_value = if enum_def.encoding_type == "char"
        UInt8(0x0)  # Standard SBE char null value
    else
        encoding_julia_type <: Unsigned ? typemax(encoding_julia_type) : typemin(encoding_julia_type)
    end

    push!(enum_values, :(NULL_VALUE = $encoding_type_symbol($null_value)))

    # Generate the enum expression (matching the baseline pattern)
    # Use quote to construct properly, but then extract the raw expression
    enum_quoted = quote
        @enumx T = SbeEnum $enum_name::$encoding_julia_type begin
            $(enum_values...)
        end
    end
    
    # Extract the expression without quote wrapping (avoids begin...end in output)
    return extract_expr_from_quote(enum_quoted, :macrocall)
end

"""
    generateSet_expr(set_def::Schema.SetType, schema::Schema.MessageSchema) -> Expr

Generate a set/bitset type definition as an expression (for file-based generation).

This is the expression-returning version of `generateChoiceSet!()`. Instead of evaluating
the code in a module with `Core.eval`, it returns the expression that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `set_def::Schema.SetType`: Set type definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Expr`: A quote block containing the complete set module definition

# Example
```julia
expr = generateSet_expr(set_def, schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
Creates a nested module with:
- Decoder/Encoder type (single struct with aliases)
- SBE interface methods
- Bit manipulation operations (clear!, is_empty, raw_value)
- Individual choice accessor functions (getter/setter for each bit)
"""
function generateSet_expr(set_def::Schema.SetType, schema::Schema.MessageSchema)
    set_name = Symbol(to_pascal_case(set_def.name))
    abstract_type_name = Symbol(string("Abstract", set_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    
    # Get the underlying primitive type for the bitset
    encoding_julia_type = to_julia_type(set_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    encoding_size = sizeof(encoding_julia_type)
    
    # Build choice accessor functions
    choice_exprs = Expr[]
    for choice in set_def.choices
        choice_func_name = Symbol(toCamelCase(choice.name))
        choice_func_name_set = Symbol(string(choice_func_name, "!"))
        bit_position = choice.bit_position
        
        # Getter function (works on both Decoder and Encoder via abstract type)
        push!(choice_exprs, quote
            @inline function $choice_func_name(set::$abstract_type_name)
                return decode_value($encoding_type_symbol, set.buffer, set.offset) & ($encoding_type_symbol(0x1) << $bit_position) != 0
            end
        end)
        
        # Setter function (only for Encoder)
        push!(choice_exprs, quote
            @inline function $choice_func_name_set(set::$encoder_name, value::Bool)
                bits = decode_value($encoding_type_symbol, set.buffer, set.offset)
                bits = value ? (bits | ($encoding_type_symbol(0x1) << $bit_position)) : (bits & ~($encoding_type_symbol(0x1) << $bit_position))
                encode_value($encoding_type_symbol, set.buffer, set.offset, bits)
                return set
            end
        end)
        
        # Export statements
        push!(choice_exprs, :(export $choice_func_name, $choice_func_name_set))
    end
    
    # Get endianness-specific imports (same as generateEncodedTypes! but returns Expr)
    endian_imports = generateEncodedTypes_expr(schema)
    
    # Generate the complete set module expression
    # Use quote to build properly, then extract the module expression
    set_quoted = quote
        module $set_name
            using SBE: AbstractSbeEncodedType
            
            # Endianness-specific encode/decode functions
            $endian_imports
            
            # Abstract type for this set
            abstract type $abstract_type_name <: AbstractSbeEncodedType end
            
            # Decoder structure (includes acting_version for version-aware access)
            struct $decoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
                acting_version::UInt16
            end
            
            # Encoder structure (simpler, no versioning)
            struct $encoder_name{T<:AbstractVector{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int
            end
            
            # Convenience constructors for Decoder
            @inline function $decoder_name(buffer::AbstractVector{UInt8})
                $decoder_name(buffer, Int64(0), $(version_expr(schema, schema.version)))
            end
            
            @inline function $decoder_name(buffer::AbstractVector{UInt8}, offset::Integer)
                $decoder_name(buffer, Int64(offset), $(version_expr(schema, schema.version)))
            end
            
            # Convenience constructors for Encoder
            @inline function $encoder_name(buffer::AbstractVector{UInt8})
                $encoder_name(buffer, Int64(0))
            end
            
            # SBE interface methods (dispatch on abstract type)
            id(::Type{<:$abstract_type_name}) = $(template_id_expr(schema, 0xffff))
            id(::$abstract_type_name) = $(template_id_expr(schema, 0xffff))
            since_version(::Type{<:$abstract_type_name}) = $(version_expr(schema, set_def.since_version))
            since_version(::$abstract_type_name) = $(version_expr(schema, set_def.since_version))
            
            encoding_offset(::Type{<:$abstract_type_name}) = $(something(set_def.offset, 0))
            encoding_offset(::$abstract_type_name) = $(something(set_def.offset, 0))
            encoding_length(::Type{<:$abstract_type_name}) = $encoding_size
            encoding_length(::$abstract_type_name) = $encoding_size
            
            # Acting version accessors
            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(schema, schema.version))
            
            Base.eltype(::Type{<:$abstract_type_name}) = $encoding_julia_type
            Base.eltype(::$abstract_type_name) = $encoding_julia_type
            
            # Basic set operations
            @inline function clear!(set::$encoder_name)
                encode_value($encoding_julia_type, set.buffer, set.offset, zero($encoding_julia_type))
                return set
            end
            
            @inline function is_empty(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset) == zero($encoding_julia_type)
            end
            
            @inline function raw_value(set::$abstract_type_name)
                return decode_value($encoding_julia_type, set.buffer, set.offset)
            end
            
            # Individual choice accessors
            $(choice_exprs...)
            
            # Exports
            export $abstract_type_name, $decoder_name, $encoder_name
            export clear!, is_empty, raw_value
        end
    end
    
    # Extract the module expression without quote wrapping (avoids begin...end in output)
    return extract_expr_from_quote(set_quoted, :module)
end

"""
    generateComposite_expr(composite_def::Schema.CompositeType, schema::Schema.MessageSchema) -> Expr

Generate a composite type definition as an expression (for file-based generation).
"""
function generateComposite_expr(composite_def::Schema.CompositeType, schema::Schema.MessageSchema, skip_nested_generation::Bool=false)
    composite_name = Symbol(to_pascal_case(composite_def.name))
    abstract_type_name = Symbol(string("Abstract", composite_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    
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
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        elseif member isa Schema.SetType
            encoding_type = to_julia_type(member.encoding_type)
            total_size += sizeof(encoding_type)
        end
    end
    
    # Build nested type definitions and field accessor expressions
    nested_type_exprs = Expr[]  # Module-level enum and set definitions
    field_exprs = Expr[]  # Field accessor functions
    export_symbols = Symbol[]  # Additional exports for nested types
    
    offset = 0
    for member in composite_def.members
        if member isa Schema.EncodedType
            member_exprs = generate_composite_member_expr(member, offset, abstract_type_name, decoder_name, encoder_name, schema)
            append!(field_exprs, member_exprs)
            # Constants don't occupy space in the encoding
            if member.presence != "constant"
                julia_type = to_julia_type(member.primitive_type)
                offset += sizeof(julia_type) * member.length
            end
        elseif member isa Schema.RefType
            # Handle referenced types (e.g., <ref name="efficiency" type="Percentage"/>)
            ref_member_exprs = generate_composite_ref_member_expr(member, offset, abstract_type_name, decoder_name, encoder_name, schema)
            append!(field_exprs, ref_member_exprs)
            # Calculate offset advancement based on referenced type
            ref_type_def = find_type_by_name(schema, member.type_ref)
            if ref_type_def !== nothing
                if ref_type_def isa Schema.EncodedType
                    if ref_type_def.presence != "constant"
                        julia_type = to_julia_type(ref_type_def.primitive_type)
                        offset += sizeof(julia_type) * ref_type_def.length
                    end
                elseif ref_type_def isa Schema.CompositeType
                    # Get composite size
                    composite_size = get_field_size(schema, Schema.FieldDefinition(
                        member.name, UInt16(0), member.type_ref, 0, "", 0, "required",
                        nothing, "", nothing, nothing, nothing
                    ))
                    offset += composite_size
                elseif ref_type_def isa Schema.EnumType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    offset += sizeof(encoding_type)
                elseif ref_type_def isa Schema.SetType
                    encoding_type = to_julia_type(ref_type_def.encoding_type)
                    offset += sizeof(encoding_type)
                end
            end
        elseif member isa Schema.EnumType
            # Handle nested enum definitions (e.g., <enum name="BoostType" encodingType="char">)
            # NOTE: Nested enums are generated at top-level in generate_module_expr, not here
            # We only generate the accessor for this enum field
            enum_name = Symbol(to_pascal_case(member.name))
            
            # Generate field accessor for this enum (references the top-level enum module)
            accessor_exprs = generate_composite_nested_enum_accessor(member, offset, abstract_type_name, decoder_name, encoder_name, schema)
            append!(field_exprs, accessor_exprs)
            
            # Update offset
            encoding_type = to_julia_type(member.encoding_type)
            offset += sizeof(encoding_type)
        elseif member isa Schema.SetType
            # Handle nested set definitions (e.g., <set name="Options" encodingType="uint8">)
            # NOTE: Nested sets are generated at top-level in generate_module_expr, not here
            # We only generate the accessor for this set field
            set_name = Symbol(to_pascal_case(member.name))
            
            # Generate field accessor for this set (references the top-level set module)
            accessor_exprs = generate_composite_nested_set_accessor(member, offset, abstract_type_name, decoder_name, encoder_name, schema)
            append!(field_exprs, accessor_exprs)
            
            # Update offset
            encoding_type = to_julia_type(member.encoding_type)
            offset += sizeof(encoding_type)
        elseif member isa Schema.CompositeType
            # Handle nested composite definitions (e.g., <composite name="inner">)
            # NOTE: Nested composites are generated at top-level in generate_module_expr, not here
            # We only generate the accessor for this composite field
            composite_name = Symbol(to_pascal_case(member.name))
            
            # Generate field accessor for this composite (references the top-level composite module)
            accessor_exprs = generate_composite_nested_composite_accessor(member, offset, abstract_type_name, decoder_name, encoder_name, schema)
            append!(field_exprs, accessor_exprs)
            
            # Update offset - calculate the nested composite's size
            nested_composite_size = 0
            for nested_member in member.members
                if nested_member isa Schema.EncodedType
                    if nested_member.presence != "constant"
                        julia_type = to_julia_type(nested_member.primitive_type)
                        nested_composite_size += sizeof(julia_type) * nested_member.length
                    end
                elseif nested_member isa Schema.RefType
                    ref_type_def = find_type_by_name(schema, nested_member.type_ref)
                    if ref_type_def !== nothing && ref_type_def isa Schema.EncodedType
                        if ref_type_def.presence != "constant"
                            julia_type = to_julia_type(ref_type_def.primitive_type)
                            nested_composite_size += sizeof(julia_type) * ref_type_def.length
                        end
                    end
                elseif nested_member isa Schema.EnumType
                    encoding_type = to_julia_type(nested_member.encoding_type)
                    nested_composite_size += sizeof(encoding_type)
                elseif nested_member isa Schema.SetType
                    encoding_type = to_julia_type(nested_member.encoding_type)
                    nested_composite_size += sizeof(encoding_type)
                end
            end
            offset += nested_composite_size
        end
    end
    
    # Get endianness-specific imports
    endian_imports = generateEncodedTypes_expr(schema)
    
    # Determine if we need EnumX import (check if any nested types are enums)
    needs_enumx = any(m -> m isa Schema.EnumType, composite_def.members)
    
    # Collect external enum and composite types used by this composite for imports
    # This includes both referenced types AND nested types (which are now siblings at top-level)
    enum_imports = Set{Symbol}()
    composite_imports = Set{Symbol}()
    
    for member in composite_def.members
        # Add nested enums and sets as imports (they're generated as siblings now)
        if member isa Schema.EnumType
            enum_type_name = Symbol(to_pascal_case(member.name))
            push!(enum_imports, enum_type_name)
        elseif member isa Schema.SetType
            set_type_name = Symbol(to_pascal_case(member.name))
            push!(enum_imports, set_type_name)  # Sets go in enum_imports
        elseif member isa Schema.CompositeType
            composite_type_name = Symbol(to_pascal_case(member.name))
            push!(composite_imports, composite_type_name)
        end
        
        # Also add referenced external types
        if member isa Schema.RefType && member.type_ref !== nothing
            # Find the referenced type
            type_idx = findfirst(t -> t.name == member.type_ref, schema.types)
            if type_idx !== nothing
                type_obj = schema.types[type_idx]
                if type_obj isa Schema.EnumType
                    # External enum reference - need to import it
                    enum_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(enum_imports, enum_type_name)
                elseif type_obj isa Schema.SetType
                    # External set reference - need to import it
                    set_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(enum_imports, set_type_name)  # Sets also go in enum_imports
                elseif type_obj isa Schema.CompositeType
                    # External composite reference - need to import it
                    composite_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(composite_imports, composite_type_name)
                end
            end
        end
    end
    
    # Generate the complete composite module expression
    composite_quoted = quote
        module $composite_name
            using SBE: AbstractSbeCompositeType, AbstractSbeEncodedType
            import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
            import SBE: value, value!
            using MappedArrays: mappedarray
            $(needs_enumx ? :(using EnumX) : nothing)
            
            # Import external enum/set types referenced by fields
            $([:($using_stmt) for using_stmt in [:(using ..$enum_name) for enum_name in enum_imports]]...)
            
            # Import external composite types referenced by fields
            $([:($using_stmt) for using_stmt in [:(using ..$composite_name) for composite_name in composite_imports]]...)
            
            # Endianness-specific encode/decode functions
            $endian_imports
            
            # Abstract type for this composite
            abstract type $abstract_type_name <: AbstractSbeCompositeType end
            
            # Decoder structure (includes acting_version for version-aware decoding)
            struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int64
                acting_version::UInt16
            end
            
            # Encoder structure (simpler, no versioning fields)
            struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name
                buffer::T
                offset::Int64
            end
            
            # Convenience constructors for Decoder
            @inline function $decoder_name(buffer::AbstractArray{UInt8})
                $decoder_name(buffer, Int64(0), $(version_expr(schema, schema.version)))
            end
            
            @inline function $decoder_name(buffer::AbstractArray{UInt8}, offset::Integer)
                $decoder_name(buffer, Int64(offset), $(version_expr(schema, schema.version)))
            end
            
            # Convenience constructors for Encoder
            @inline function $encoder_name(buffer::AbstractArray{UInt8})
                $encoder_name(buffer, Int64(0))
            end
            
            # SBE interface methods (common to both Decoder and Encoder)
            sbe_encoded_length(::$abstract_type_name) = $(block_length_expr(schema, total_size))
            sbe_encoded_length(::Type{<:$abstract_type_name}) = $(block_length_expr(schema, total_size))
            
            # Acting version accessors
            sbe_acting_version(m::$decoder_name) = m.acting_version
            sbe_acting_version(::$encoder_name) = $(version_expr(schema, schema.version))
            
            Base.sizeof(m::$abstract_type_name) = sbe_encoded_length(m)
            
            function Base.convert(::Type{<:AbstractArray{UInt8}}, m::$abstract_type_name)
                return view(m.buffer, m.offset+1:m.offset+sbe_encoded_length(m))
            end
            
            function Base.show(io::IO, m::$abstract_type_name)
                print(io, $(string(composite_name)), "(offset=", m.offset, ", size=", sbe_encoded_length(m), ")")
            end
            
            # Field accessors
            $(field_exprs...)
            
            export $abstract_type_name, $decoder_name, $encoder_name
        end
    end
    
    # Extract the module expression without quote wrapping (avoids begin...end in output)
    return extract_expr_from_quote(composite_quoted, :module)
end

"""
Helper function to generate expressions for a composite member field.
Returns an array of expressions for all the accessor functions and metadata.
"""
function generate_composite_member_expr(member::Schema.EncodedType, offset::Int, 
                                       base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    member_name = Symbol(toCamelCase(member.name))
    julia_type = to_julia_type(member.primitive_type)
    julia_type_symbol = Symbol(julia_type)
    is_constant = member.presence == "constant"
    encoding_length = is_constant ? 0 : sizeof(julia_type) * member.length
    
    exprs = Expr[]
    
    # Generate metadata functions
    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(schema, member.since_version))
        
        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($encoding_length)
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($encoding_length)
        
        $(Symbol(member_name, :_null_value))(::$base_type_name) = $julia_type_symbol($(get_null_value(julia_type, member)))
        $(Symbol(member_name, :_null_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_null_value(julia_type, member)))
        $(Symbol(member_name, :_min_value))(::$base_type_name) = $julia_type_symbol($(get_min_value(julia_type, member)))
        $(Symbol(member_name, :_min_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_min_value(julia_type, member)))
        $(Symbol(member_name, :_max_value))(::$base_type_name) = $julia_type_symbol($(get_max_value(julia_type, member)))
        $(Symbol(member_name, :_max_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_max_value(julia_type, member)))
    end)
    
    # Generate accessors based on constant/value type
    if is_constant
        if member.constant_value === nothing
            error("Constant member $(member.name) has no constant value specified")
        end
        
        if member.length == 1
            const_val = parse_constant_value(julia_type, member.constant_value)
            julia_type_symbol = Symbol(julia_type)
            push!(exprs, quote
                @inline $member_name(::$base_type_name) = $julia_type_symbol($const_val)
                @inline $member_name(::Type{<:$base_type_name}) = $julia_type_symbol($const_val)
                export $member_name
            end)
        else
            # Array constant
            if julia_type == UInt8  # Char array - return as string
                push!(exprs, quote
                    @inline $member_name(::$base_type_name) = $(member.constant_value)
                    @inline $member_name(::Type{<:$base_type_name}) = $(member.constant_value)
                    export $member_name
                end)
            else
                error("Array constants only supported for char type")
            end
        end
    else
        # Non-constant field
        if member.length == 1
            # Single value
            push!(exprs, quote
                @inline function $member_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $offset)
                end
                
                @inline $(Symbol(member_name, :!))(m::$encoder_name, val) = encode_value($julia_type, m.buffer, m.offset + $offset, val)
                
                export $member_name, $(Symbol(member_name, :!))
            end)
        else
            # Array value
            # Special case: character arrays return String (matches SBE baseline behavior)
            is_character_array = (julia_type == UInt8 && member.primitive_type == "char")
            
            if is_character_array
                # Character arrays return String by default
                push!(exprs, :(using StringViews: StringView))
                
                push!(exprs, quote
                    # Direct decoder function: returns StringView with null-byte trimming
                    @inline function $member_name(m::$decoder_name)
                        bytes = decode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                        # Remove trailing null bytes - use findfirst to avoid allocation
                        pos = findfirst(iszero, bytes)
                        len = pos !== nothing ? pos - 1 : Base.length(bytes)
                        return StringView(view(bytes, 1:len))
                    end

                    # Direct encoder function: returns array view for writing (matches baseline)
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                    end

                    # Convenience encoder with AbstractString (copies with null padding)
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractString)
                        bytes = codeunits(value)
                        dest = encode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                        len = min(length(bytes), length(dest))
                        copyto!(dest, 1, bytes, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end

                    # Convenience encoder with UInt8 vector (copies as-is)
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name, value::AbstractVector{UInt8})
                        dest = encode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                        len = min(length(value), length(dest))
                        copyto!(dest, 1, value, 1, len)
                        # Zero out the rest
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end

                    export $member_name, $(Symbol(member_name, :!))
                end)
            else
                # Non-character arrays: return numeric array view
                push!(exprs, quote
                    @inline function $member_name(m::$decoder_name)
                        return decode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                    end
                    
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $offset, $(member.length))
                    end
                    
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                        copyto!($(Symbol(member_name, :!))(m), val)
                    end
                    
                    export $member_name, $(Symbol(member_name, :!))
                end)
            end
        end
    end
    
    return exprs
end

"""
Helper function to generate expressions for a composite ref member field (e.g., <ref name="efficiency" type="Percentage"/>).
Returns an array of expressions for all the accessor functions and metadata.
"""
function generate_composite_ref_member_expr(member::Schema.RefType, offset::Int,
                                           base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol,
                                           schema::Schema.MessageSchema)
    member_name = Symbol(toCamelCase(member.name))
    exprs = Expr[]
    
    # Look up the referenced type
    ref_type_def = find_type_by_name(schema, member.type_ref)
    if ref_type_def === nothing
        error("Referenced type $(member.type_ref) not found for member $(member.name)")
    end
    
    if ref_type_def isa Schema.EncodedType
        # Handle primitive type references (e.g., <type name="Percentage" primitiveType="int8"/>)
        julia_type = to_julia_type(ref_type_def.primitive_type)
        julia_type_symbol = Symbol(julia_type)
        is_constant = ref_type_def.presence == "constant"
        encoding_length = is_constant ? 0 : sizeof(julia_type) * ref_type_def.length
        
        # Generate metadata functions (RefType doesn't have since_version, use 0)
        push!(exprs, quote
            $(Symbol(member_name, :_id))(::$base_type_name) = UInt16(0xffff)
            $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = UInt16(0xffff)
            $(Symbol(member_name, :_since_version))(::$base_type_name) = UInt16(0)
            $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = UInt16(0)
            $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= UInt16(0)
            
            $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
            $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
            $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($encoding_length)
            $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($encoding_length)
            
            $(Symbol(member_name, :_null_value))(::$base_type_name) = $julia_type_symbol($(get_null_value(julia_type, ref_type_def)))
            $(Symbol(member_name, :_null_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_null_value(julia_type, ref_type_def)))
            $(Symbol(member_name, :_min_value))(::$base_type_name) = $julia_type_symbol($(get_min_value(julia_type, ref_type_def)))
            $(Symbol(member_name, :_min_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_min_value(julia_type, ref_type_def)))
            $(Symbol(member_name, :_max_value))(::$base_type_name) = $julia_type_symbol($(get_max_value(julia_type, ref_type_def)))
            $(Symbol(member_name, :_max_value))(::Type{<:$base_type_name}) = $julia_type_symbol($(get_max_value(julia_type, ref_type_def)))
        end)
        
        # Generate value accessors (non-constant only, as ref types shouldn't be constant)
        if !is_constant
            if ref_type_def.length == 1
                # Single value
                push!(exprs, quote
                    @inline function $member_name(m::$decoder_name)
                        return decode_value($julia_type, m.buffer, m.offset + $offset)
                    end
                    
                    @inline $(Symbol(member_name, :!))(m::$encoder_name, val) = encode_value($julia_type, m.buffer, m.offset + $offset, val)
                    
                    export $member_name, $(Symbol(member_name, :!))
                end)
            else
                # Array value
                push!(exprs, quote
                    @inline function $member_name(m::$decoder_name)
                        return decode_array($julia_type, m.buffer, m.offset + $offset, $(ref_type_def.length))
                    end
                    
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $offset, $(ref_type_def.length))
                    end
                    
                    @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                        copyto!($(Symbol(member_name, :!))(m), val)
                    end
                    
                    export $member_name, $(Symbol(member_name, :!))
                end)
            end
        end
    elseif ref_type_def isa Schema.CompositeType
        # Handle composite type references (e.g., <ref name="booster" type="Booster"/>)
        composite_module_name = Symbol(to_pascal_case(member.type_ref))
        
        # Generate separate methods for Decoder and Encoder
        # Decoder gets acting_version, Encoder uses default version 0
        push!(exprs, quote
            @inline function $member_name(m::$decoder_name)
                return $composite_module_name.Decoder(m.buffer, m.offset + $offset, m.acting_version)
            end
            
            @inline function $member_name(m::$encoder_name)
                return $composite_module_name.Encoder(m.buffer, m.offset + $offset)
            end
            
            export $member_name
        end)
    elseif ref_type_def isa Schema.EnumType
        # Handle enum type references (e.g., <ref name="boosterEnabled" type="BooleanType"/>)
        enum_module_name = Symbol(to_pascal_case(member.type_ref))
        julia_type = to_julia_type(ref_type_def.encoding_type)
        julia_type_symbol = Symbol(julia_type)
        
        # Generate metadata
        push!(exprs, quote
            $(Symbol(member_name, :_id))(::$base_type_name) = UInt16(0xffff)
            $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = UInt16(0xffff)
            $(Symbol(member_name, :_since_version))(::$base_type_name) = UInt16(0)
            $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = UInt16(0)
            $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= UInt16(0)
            
            $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
            $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
            $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
            $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
        end)
        
        # Generate enum accessors using direct reference
        push!(exprs, quote
            @inline function $member_name(m::$decoder_name)
                raw_value = decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
                return $enum_module_name.SbeEnum(raw_value)
            end
            
            @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
                encode_value($julia_type_symbol, m.buffer, m.offset + $offset, $julia_type_symbol(val))
            end
            
            export $member_name, $(Symbol(member_name, :!))
        end)
    elseif ref_type_def isa Schema.SetType
        # Handle set type references (e.g., <ref name="extras" type="OptionalExtras"/>)
        set_module_name = Symbol(to_pascal_case(member.type_ref))
        julia_type = to_julia_type(ref_type_def.encoding_type)
        
        # Generate metadata
        push!(exprs, quote
            $(Symbol(member_name, :_id))(::$base_type_name) = UInt16(0xffff)
            $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = UInt16(0xffff)
            $(Symbol(member_name, :_since_version))(::$base_type_name) = UInt16(0)
            $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = UInt16(0)
            $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= UInt16(0)
            
            $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
            $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
            $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
            $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
        end)
        
        # Generate set accessors using direct reference
        push!(exprs, quote
            @inline function $member_name(m::$decoder_name)
                return $set_module_name.Decoder(m.buffer, m.offset + $offset)
            end
            
            @inline function $member_name(m::$encoder_name)
                return $set_module_name.Encoder(m.buffer, m.offset + $offset)
            end
            
            export $member_name
        end)
    end
    
    return exprs
end

"""
Helper function to generate field accessor expressions for nested enum members in composites.
These are enums defined directly inside the composite, not referenced from external types.
"""
function generate_composite_nested_enum_accessor(member::Schema.EnumType, offset::Int, 
                                                   base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    # For nested enums, convert the name to camelCase (lowercase first letter)
    raw_name = toCamelCase(member.name)
    member_name = Symbol(lowercase(raw_name[1:1]) * raw_name[2:end])
    enum_name = Symbol(to_pascal_case(member.name))
    julia_type = to_julia_type(member.encoding_type)
    julia_type_symbol = Symbol(julia_type)
    
    exprs = Expr[]
    
    # Generate metadata functions
    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(schema, member.since_version))
        
        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
    end)
    
    # Generate enum field accessors (reads/writes the nested enum defined in this module)
    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            raw_value = decode_value($julia_type_symbol, m.buffer, m.offset + $offset)
            return $enum_name.SbeEnum(raw_value)
        end
        
        @inline function $(Symbol(member_name, :!))(m::$encoder_name, val)
            encode_value($julia_type_symbol, m.buffer, m.offset + $offset, $julia_type_symbol(val))
        end
    end)
    
    return exprs
end

"""
Helper function to generate field accessor expressions for nested set members in composites.
These are sets defined directly inside the composite, not referenced from external types.
"""
function generate_composite_nested_set_accessor(member::Schema.SetType, offset::Int, 
                                                  base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    # For nested sets, convert the name to camelCase (lowercase first letter)
    raw_name = toCamelCase(member.name)
    member_name = Symbol(lowercase(raw_name[1:1]) * raw_name[2:end])
    set_name = Symbol(to_pascal_case(member.name))
    julia_type = to_julia_type(member.encoding_type)
    
    exprs = Expr[]
    
    # Generate metadata functions
    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(schema, member.since_version))
        
        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($(sizeof(julia_type)))
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($(sizeof(julia_type)))
    end)
    
    # Generate set field accessors (reads/writes the nested set defined in this module)
    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            return $set_name.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end
        
        @inline function $member_name(m::$encoder_name)
            return $set_name.Encoder(m.buffer, m.offset + $offset)
        end
    end)
    
    return exprs
end

"""
Helper function to generate field accessor expressions for nested composite members in composites.
These are composites defined directly inside the composite, not referenced from external types.
"""
function generate_composite_nested_composite_accessor(member::Schema.CompositeType, offset::Int, 
                                                       base_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    # For nested composites, convert the name to camelCase (lowercase first letter)
    raw_name = toCamelCase(member.name)
    member_name = Symbol(lowercase(raw_name[1:1]) * raw_name[2:end])
    composite_name = Symbol(to_pascal_case(member.name))
    
    # Calculate the nested composite's encoded length
    nested_size = 0
    for nested_member in member.members
        if nested_member isa Schema.EncodedType
            if nested_member.presence != "constant"
                julia_type = to_julia_type(nested_member.primitive_type)
                nested_size += sizeof(julia_type) * nested_member.length
            end
        elseif nested_member isa Schema.RefType
            ref_type_def = find_type_by_name(schema, nested_member.type_ref)
            if ref_type_def !== nothing && ref_type_def isa Schema.EncodedType
                if ref_type_def.presence != "constant"
                    julia_type = to_julia_type(ref_type_def.primitive_type)
                    nested_size += sizeof(julia_type) * ref_type_def.length
                end
            end
        elseif nested_member isa Schema.EnumType
            encoding_type = to_julia_type(nested_member.encoding_type)
            nested_size += sizeof(encoding_type)
        elseif nested_member isa Schema.SetType
            encoding_type = to_julia_type(nested_member.encoding_type)
            nested_size += sizeof(encoding_type)
        end
    end
    
    exprs = Expr[]
    
    # Generate metadata functions
    push!(exprs, quote
        $(Symbol(member_name, :_id))(::$base_type_name) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_id))(::Type{<:$base_type_name}) = $(template_id_expr(schema, 0xffff))
        $(Symbol(member_name, :_since_version))(::$base_type_name) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_since_version))(::Type{<:$base_type_name}) = $(version_expr(schema, member.since_version))
        $(Symbol(member_name, :_in_acting_version))(m::$base_type_name) = m.acting_version >= $(version_expr(schema, member.since_version))
        
        $(Symbol(member_name, :_encoding_offset))(::$base_type_name) = Int($offset)
        $(Symbol(member_name, :_encoding_offset))(::Type{<:$base_type_name}) = Int($offset)
        $(Symbol(member_name, :_encoding_length))(::$base_type_name) = Int($nested_size)
        $(Symbol(member_name, :_encoding_length))(::Type{<:$base_type_name}) = Int($nested_size)
    end)
    
    # Generate composite field accessors (reads/writes the nested composite defined in this module)
    push!(exprs, quote
        @inline function $member_name(m::$decoder_name)
            return $composite_name.Decoder(m.buffer, m.offset + $offset, m.acting_version)
        end
        
        @inline function $member_name(m::$encoder_name)
            return $composite_name.Encoder(m.buffer, m.offset + $offset)
        end
    end)
    
    return exprs
end

"""
    generateMessage_expr(message_def::Schema.MessageDefinition, schema::Schema.MessageSchema) -> Expr

Generate a message type definition as an expression (for file-based generation).

This is the expression-returning version of `generateMessageFlyweightStruct!()`. Instead of evaluating
the code in a module with `Core.eval`, it returns the expression that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `message_def::Schema.MessageDefinition`: Message definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Expr`: A quote block containing the complete message module definition

# Example
```julia
expr = generateMessage_expr(message_def, schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
Creates a nested module with:
- Decoder/Encoder types with MessageHeader integration
- SBE interface methods
- Field accessor functions (primitives, enums, sets, composites)
- Group accessors (if any groups defined)
- VarData accessors (if any variable-length data defined)

Note: This function generates the message module structure but does NOT generate
nested types (groups, enums, sets, composites). Those must be generated separately
and included in the parent module before the message definition.
"""
function generateMessage_expr(message_def::Schema.MessageDefinition, schema::Schema.MessageSchema)
    message_name = Symbol(to_pascal_case(message_def.name))
    abstract_type_name = Symbol(string("Abstract", message_name))
    decoder_name = :Decoder
    encoder_name = :Encoder
    
    # Calculate block length
    block_length = if message_def.block_length !== nothing
        parse(Int, message_def.block_length)
    else
        # Calculate from fields
        max_offset = 0
        for field in message_def.fields
            field_end = field.offset + get_field_size(schema, field)
            max_offset = max(max_offset, field_end)
        end
        max_offset
    end
    
    # Get header module name
    header_module_name = Symbol(to_pascal_case(schema.header_type))
    
    # Collect enum types used in constant fields for imports
    enum_imports = Set{Symbol}()
    for field in message_def.fields
        if field.presence == "constant" && field.value_ref !== nothing
            parts = split(field.value_ref, '.')
            if length(parts) == 2
                enum_type_name = Symbol(parts[1])
                push!(enum_imports, enum_type_name)
            end
        end
        # Also collect enum types from regular field references
        if field.type_ref !== nothing
            type_def = findfirst(t -> t.name == field.type_ref, schema.types)
            if type_def !== nothing
                type_obj = schema.types[type_def]
                if isa(type_obj, Schema.EnumType)
                    enum_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(enum_imports, enum_type_name)
                end
            end
        end
    end
    
    # Collect composite types used in fields for imports
    composite_imports = Set{Symbol}()
    for field in message_def.fields
        if field.type_ref !== nothing
            # Find the type definition
            type_def = findfirst(t -> t.name == field.type_ref, schema.types)
            if type_def !== nothing
                type_obj = schema.types[type_def]
                if isa(type_obj, Schema.CompositeType)
                    composite_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(composite_imports, composite_type_name)
                end
            end
        end
    end
    
    # Collect set types used in fields for imports
    set_imports = Set{Symbol}()
    for field in message_def.fields
        if field.type_ref !== nothing
            # Find the type definition
            type_def = findfirst(t -> t.name == field.type_ref, schema.types)
            if type_def !== nothing
                type_obj = schema.types[type_def]
                if isa(type_obj, Schema.SetType)
                    set_type_name = Symbol(to_pascal_case(type_obj.name))
                    push!(set_imports, set_type_name)
                end
            end
        end
    end
    
    # Collect dimension types used by groups for imports
    # Groups reference dimension composite types (e.g., GroupSizeEncoding)
    if !isempty(message_def.groups)
        for group in message_def.groups
            dimension_type = group.dimension_type !== nothing ? group.dimension_type : "groupSizeEncoding"
            dimension_type_name = Symbol(uppercasefirst(dimension_type))
            push!(composite_imports, dimension_type_name)
        end
    end
    
    # Generate field accessor expressions
    field_exprs = Expr[]
    for field in message_def.fields
        field_expr = generate_message_field_expr(field, abstract_type_name, decoder_name, encoder_name, message_def.name, schema)
        if field_expr !== nothing
            append!(field_exprs, field_expr)
        end
    end
    
    # Get endianness-specific imports
    endian_imports = generateEncodedTypes_expr(schema)
    
    # Generate SBE interface method expressions (dispatch on abstract type)
    sbe_interface_exprs = [
        :(import SBE),
        :(SBE.sbe_template_id(::$abstract_type_name) = $(template_id_expr(schema, message_def.id))),
        :(SBE.sbe_schema_id(::$abstract_type_name) = $(schema_id_expr(schema, schema.id))),
        :(SBE.sbe_schema_version(::$abstract_type_name) = $(version_expr(schema, schema.version))),
        :(SBE.sbe_block_length(::$abstract_type_name) = $(block_length_expr(schema, block_length))),
        :(SBE.sbe_acting_block_length(m::$decoder_name) = m.acting_block_length),
        :(SBE.sbe_buffer(m::$abstract_type_name) = m.buffer),
        :(SBE.sbe_offset(m::$abstract_type_name) = m.offset),
        :(SBE.sbe_position_ptr(m::$abstract_type_name) = m.position_ptr),
        :(SBE.sbe_position(m::$abstract_type_name) = m.position_ptr[]),
        :(SBE.sbe_position!(m::$abstract_type_name, pos::Integer) = (m.position_ptr[] = pos))
    ]
    
    # Generate the complete message module expression
    message_quoted = quote
        module $message_name
            # Import necessary types
            using SBE: AbstractSbeMessage, AbstractSbeEncodedType, AbstractSbeData, AbstractSbeGroup
            using MappedArrays: mappedarray
            using StringViews: StringView
            import SBE: id, since_version, encoding_offset, encoding_length, null_value, min_value, max_value
            import SBE: value, value!
            import SBE: sbe_template_id, sbe_schema_id, sbe_schema_version, sbe_block_length
            import SBE: sbe_acting_block_length, sbe_buffer, sbe_offset
            import SBE: sbe_position_ptr, sbe_position, sbe_position!, sbe_rewind!, sbe_encoded_length
            import SBE: sbe_semantic_type, sbe_description
            
            # Import header module from parent
            using ..$header_module_name
            
            # Import enum types used in constant fields from parent module
            $([:(using ..$enum_name) for enum_name in enum_imports]...)
            
            # Import composite types used in fields from parent module
            $([:(using ..$composite_name) for composite_name in composite_imports]...)
            
            # Import set types used in fields from parent module
            $([:(using ..$set_name) for set_name in set_imports]...)
            
            # Import helper functions from SBE
            using SBE: PositionPointer, to_string
            
            # Generate endianness-specific encode/decode functions
            $endian_imports
            
            # Export decoder and encoder
            export $decoder_name, $encoder_name
            
            # Abstract type for this message (allows shared metadata dispatch)
            abstract type $abstract_type_name{T<:AbstractArray{UInt8}} <: AbstractSbeMessage{T} end
            
            # Decoder type - reads acting values from MessageHeader
            struct $decoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                buffer::T
                offset::Int64
                position_ptr::PositionPointer
                acting_block_length::UInt16
                acting_version::UInt16
                
                # Inner constructor - 5-argument version
                function $decoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer,
                    acting_block_length::UInt16, acting_version::UInt16) where {T}
                    position_ptr[] = offset + acting_block_length
                    new{T}(buffer, offset, position_ptr, acting_block_length, acting_version)
                end
                
                # 3-argument constructor (uses schema defaults)
                function $decoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer) where {T}
                    position_ptr[] = offset + $(block_length_expr(schema, block_length))
                    new{T}(buffer, offset, position_ptr, $(block_length_expr(schema, block_length)), $(version_expr(schema, schema.version)))
                end
            end
            
            # Encoder type - uses fixed schema values
            struct $encoder_name{T<:AbstractArray{UInt8}} <: $abstract_type_name{T}
                buffer::T
                offset::Int64
                position_ptr::PositionPointer
                
                # Inner constructor
                function $encoder_name(buffer::T, offset::Int64, position_ptr::PositionPointer) where {T}
                    position_ptr[] = offset + $block_length
                    new{T}(buffer, offset, position_ptr)
                end
            end
            
            # Outer constructor for decoder with MessageHeader validation
            @inline function $decoder_name(buffer::AbstractArray, offset::Integer=0;
                position_ptr::PositionPointer=PositionPointer(),
                header::$header_module_name.Decoder=$header_module_name.Decoder(buffer, Int64(offset)))
                if $header_module_name.templateId(header) != $(template_id_expr(schema, message_def.id)) ||
                   $header_module_name.schemaId(header) != $(schema_id_expr(schema, schema.id))
                    error("Template id or schema id mismatch")
                end
                $decoder_name(buffer, Int64(offset) + Int64($header_module_name.sbe_encoded_length(header)), position_ptr,
                    $header_module_name.blockLength(header), $header_module_name.version(header))
            end
            
            # Outer constructor for encoder with MessageHeader initialization
            @inline function $encoder_name(buffer::AbstractArray, offset::Integer=0;
                position_ptr::PositionPointer=PositionPointer(),
                header::$header_module_name.Encoder=$header_module_name.Encoder(buffer, Int64(offset)))
                $header_module_name.blockLength!(header, $(block_length_expr(schema, block_length)))
                $header_module_name.templateId!(header, $(template_id_expr(schema, message_def.id)))
                $header_module_name.schemaId!(header, $(schema_id_expr(schema, schema.id)))
                $header_module_name.version!(header, $(version_expr(schema, schema.version)))
                $encoder_name(buffer, Int64(offset) + Int64($header_module_name.sbe_encoded_length(header)), position_ptr)
            end
            
            # Field accessor functions
            $(field_exprs...)
            
            # Message-level SBE interface methods
            begin
                $(sbe_interface_exprs...)
            end
        end
    end
    
    # Extract the module expression without quote wrapping (avoids begin...end in output)
    message_module_expr = extract_expr_from_quote(message_quoted, :module)
    
    # Generate groups and var data
    # These need to be inserted into the module body after extraction
    if message_module_expr.head == :module
        module_body = message_module_expr.args[3]  # Module body is 3rd argument
        
        # Generate groups as nested modules with parent accessors
        for group_def in message_def.groups
            (group_module_expr, parent_accessor_exprs) = generateGroup_expr(group_def, message_def.name, abstract_type_name, schema)
            # Insert group module into message module
            push!(module_body.args, group_module_expr)
            # Insert parent accessor functions
            append!(module_body.args, parent_accessor_exprs)
        end
        
        # Generate var data accessors
        for var_data_def in message_def.var_data
            var_data_expr = generateVarData_expr(var_data_def, schema)
            # Extract expressions from the returned quote block, filtering out LineNumberNodes
            if var_data_expr isa Expr && var_data_expr.head == :block
                for arg in var_data_expr.args
                    if arg isa Expr
                        push!(module_body.args, arg)
                    end
                end
            else
                push!(module_body.args, var_data_expr)
            end
        end
    end
    
    return message_module_expr
end

"""
Helper function to generate field accessor expressions for a message field.
Returns an array of expressions for the accessor functions and metadata.
"""
function generate_message_field_expr(field_def::Schema.FieldDefinition, abstract_type_name::Symbol, 
                                     decoder_name::Symbol, encoder_name::Symbol,
                                     message_name::String, schema::Schema.MessageSchema)
    field_name = Symbol(toCamelCase(field_def.name))
    field_name_setter = Symbol(string(field_name, "!"))
    field_offset = field_def.offset
    
    # Check if it's a primitive type
    if is_primitive_type(field_def.type_ref)
        type_def = create_primitive_encoded_type(field_def.type_ref, 1)
        return generate_encoded_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name)
    end
    
    # Look up type in schema
    type_def = find_type_by_name(schema, field_def.type_ref)
    if type_def === nothing
        @warn "Skipping field $(field_def.name): type $(field_def.type_ref) not found"
        return nothing
    end
    
    # Dispatch based on type
    if type_def isa Schema.EncodedType
        return generate_encoded_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name)
    elseif type_def isa Schema.EnumType
        return generate_enum_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name, schema)
    elseif type_def isa Schema.SetType
        return generate_set_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name)
    elseif type_def isa Schema.CompositeType
        return generate_composite_field_expr(field_name, field_def, type_def, field_offset, abstract_type_name, decoder_name, encoder_name, schema)
    else
        @warn "Skipping field $(field_def.name): unsupported type $(typeof(type_def))"
        return nothing
    end
end

"""
Helper function to generate encoded (primitive) field accessor expressions.
"""
function generate_encoded_field_expr(field_name::Symbol, field_def::Schema.FieldDefinition,
                                     type_def::Schema.EncodedType, field_offset::Int,
                                     abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol)
    field_name_setter = Symbol(string(field_name, "!"))
    julia_type = to_julia_type(type_def.primitive_type)
    since_version = field_def.since_version
    is_optional = field_def.presence == "optional" || type_def.presence == "optional"
    
    exprs = Expr[]
    
    # Generate metadata
    push!(exprs, generate_field_metadata_expr(field_name, field_def, type_def, field_offset, julia_type, abstract_type_name))
    
    # Generate accessors based on length
    if type_def.length == 1
        # Single value accessor
        null_val = get_null_value(julia_type, type_def)
        
        if since_version > 0
            # Version-aware accessor
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        return $null_val
                    end
                    return decode_value($julia_type, m.buffer, m.offset + $field_offset)
                end
                
                @inline $field_name_setter(m::$encoder_name, value) = encode_value($julia_type, m.buffer, m.offset + $field_offset, value)
            end)
        else
            # Non-versioned accessor
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name)
                    return decode_value($julia_type, m.buffer, m.offset + $field_offset)
                end
                
                @inline $field_name_setter(m::$encoder_name, value) = encode_value($julia_type, m.buffer, m.offset + $field_offset, value)
            end)
        end
        
        # Export accessors
        push!(exprs, quote
            export $field_name, $field_name_setter
        end)
    else
        # Array accessor
        is_character_array = (type_def.primitive_type == "char")
        
        if is_character_array
            # Character arrays return String
            null_val = get_null_value(julia_type, type_def)
            
            if since_version > 0
                push!(exprs, quote
                    using StringViews: StringView
                    
                    @inline function $field_name(m::$decoder_name)
                        if m.acting_version < UInt16($since_version)
                            return ""
                        end
                        bytes = decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        pos = findfirst(iszero, bytes)
                        len = pos !== nothing ? pos - 1 : Base.length(bytes)
                        return StringView(view(bytes, 1:len))
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name, value::AbstractString)
                        bytes = codeunits(value)
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(bytes), length(dest))
                        copyto!(dest, 1, bytes, 1, len)
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name, value::AbstractVector{UInt8})
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(value), length(dest))
                        copyto!(dest, 1, value, 1, len)
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end
                    
                    export $field_name, $field_name_setter
                end)
            else
                push!(exprs, quote
                    using StringViews: StringView
                    
                    @inline function $field_name(m::$decoder_name)
                        bytes = decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        pos = findfirst(iszero, bytes)
                        len = pos !== nothing ? pos - 1 : Base.length(bytes)
                        return StringView(view(bytes, 1:len))
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name, value::AbstractString)
                        bytes = codeunits(value)
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(bytes), length(dest))
                        copyto!(dest, 1, bytes, 1, len)
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name, value::AbstractVector{UInt8})
                        dest = encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                        len = min(length(value), length(dest))
                        copyto!(dest, 1, value, 1, len)
                        if len < length(dest)
                            fill!(view(dest, len+1:length(dest)), 0x00)
                        end
                    end
                    
                    export $field_name, $field_name_setter
                end)
            end
        else
            # Non-character arrays
            null_val = get_null_value(julia_type, type_def)
            
            if since_version > 0
                push!(exprs, quote
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
                    
                    export $field_name, $field_name_setter
                end)
            else
                push!(exprs, quote
                    @inline function $field_name(m::$decoder_name)
                        return decode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name)
                        return encode_array($julia_type, m.buffer, m.offset + $field_offset, $(type_def.length))
                    end
                    
                    @inline function $field_name_setter(m::$encoder_name, value)
                        copyto!($field_name_setter(m), value)
                    end
                    
                    export $field_name, $field_name_setter
                end)
            end
        end
    end
    
    return exprs
end

"""
Helper function to generate field metadata expressions.
"""
function generate_field_metadata_expr(field_name::Symbol, field_def::Schema.FieldDefinition,
                                     type_def::Union{Schema.EncodedType, Nothing}, field_offset::Int,
                                     julia_type::Type, abstract_type::Symbol)
    total_length = type_def !== nothing ? sizeof(julia_type) * type_def.length : sizeof(julia_type)
    array_length = type_def !== nothing ? type_def.length : 1
    
    null_val = type_def !== nothing ? get_null_value(julia_type, type_def) : typemax(julia_type)
    min_val = type_def !== nothing ? get_min_value(julia_type, type_def) : typemin(julia_type)
    max_val = type_def !== nothing ? get_max_value(julia_type, type_def) : typemax(julia_type)
    
    # Generate metadata function expressions
    field_id_fn = Symbol(field_name, :_id)
    field_since_fn = Symbol(field_name, :_since_version)
    field_in_acting_fn = Symbol(field_name, :_in_acting_version)
    field_offset_fn = Symbol(field_name, :_encoding_offset)
    field_length_fn = Symbol(field_name, :_encoding_length)
    field_null_fn = Symbol(field_name, :_null_value)
    field_min_fn = Symbol(field_name, :_min_value)
    field_max_fn = Symbol(field_name, :_max_value)
    field_meta_fn = Symbol(field_name, :_meta_attribute)
    
    # Get presence and semantic type for meta_attribute
    presence = field_def.presence === nothing ? "required" : field_def.presence
    semantic_type = field_def.semantic_type === nothing ? "" : field_def.semantic_type
    
    return quote
        # Instance dispatch - works for both Decoder and Encoder via abstract type
        $field_id_fn(::$abstract_type) = UInt16($(field_def.id))
        $field_since_fn(::$abstract_type) = UInt16($(field_def.since_version))
        $field_in_acting_fn(m::$abstract_type) = sbe_acting_version(m) >= UInt16($(field_def.since_version))
        $field_offset_fn(::$abstract_type) = $field_offset
        $field_length_fn(::$abstract_type) = $total_length
        $field_null_fn(::$abstract_type) = $null_val
        $field_min_fn(::$abstract_type) = $min_val
        $field_max_fn(::$abstract_type) = $max_val
        
        # Type dispatch - works for both Decoder and Encoder types via abstract type
        $field_id_fn(::Type{<:$abstract_type}) = UInt16($(field_def.id))
        $field_since_fn(::Type{<:$abstract_type}) = UInt16($(field_def.since_version))
        $field_offset_fn(::Type{<:$abstract_type}) = $field_offset
        $field_length_fn(::Type{<:$abstract_type}) = $total_length
        $field_null_fn(::Type{<:$abstract_type}) = $null_val
        $field_min_fn(::Type{<:$abstract_type}) = $min_val
        $field_max_fn(::Type{<:$abstract_type}) = $max_val
        
        # Meta attribute function
        function $field_meta_fn(::$abstract_type, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
        function $field_meta_fn(::Type{<:$abstract_type}, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
        
        export $field_id_fn, $field_since_fn, $field_in_acting_fn, $field_offset_fn, $field_length_fn
        export $field_null_fn, $field_min_fn, $field_max_fn, $field_meta_fn
    end
end

"""
Helper function to generate enum field accessor expressions.
"""
function generate_enum_field_expr(field_name::Symbol, field_def::Schema.FieldDefinition,
                                  type_def::Schema.EnumType, field_offset::Int,
                                  abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    field_name_setter = Symbol(string(field_name, "!"))
    enum_type_name = Symbol(to_pascal_case(type_def.name))
    encoding_julia_type = to_julia_type(type_def.encoding_type)
    encoding_type_symbol = Symbol(encoding_julia_type)
    is_constant = field_def.presence == "constant"
    since_version = field_def.since_version
    
    exprs = Expr[]
    
    # Generate metadata
    push!(exprs, generate_field_metadata_expr(field_name, field_def, nothing, field_offset, encoding_julia_type, abstract_type_name))
    
    # Get null value
    null_val = encoding_julia_type <: Unsigned ? typemax(encoding_julia_type) : typemin(encoding_julia_type)
    
    if is_constant
        # Constant enum - resolve valueRef
        if field_def.value_ref === nothing
            error("Constant enum field $(field_def.name) has no valueRef specified")
        end
        
        parts = split(field_def.value_ref, '.')
        if length(parts) != 2
            error("Invalid valueRef format: $(field_def.value_ref)")
        end
        enum_type_name = Symbol(parts[1])
        value_name = Symbol(parts[2])
        
        encoding_julia_type_symbol = Symbol(encoding_julia_type)
        
        push!(exprs, quote
            # Constant enum field - enum is imported at module level
            @inline function $field_name(::$decoder_name, ::Type{Integer})
                return $encoding_julia_type_symbol($enum_type_name.$value_name)
            end
            
            @inline function $field_name(::$decoder_name)
                return $enum_type_name.$value_name
            end
            
            export $field_name
        end)
    else
        # Regular enum field
        if since_version > 0
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    if m.acting_version < UInt16($since_version)
                        return $null_val
                    end
                    return decode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset)
                end
                
                @inline function $field_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
                        return $enum_type_name.SbeEnum($null_val)
                    end
                    raw = decode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset)
                    return $enum_type_name.SbeEnum(raw)
                end
                
                @inline function $field_name_setter(m::$encoder_name, value::$enum_type_name.SbeEnum)
                    encode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset, $encoding_type_symbol(value))
                end
                
                export $field_name, $field_name_setter
            end)
        else
            push!(exprs, quote
                @inline function $field_name(m::$decoder_name, ::Type{Integer})
                    return decode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset)
                end
                
                @inline function $field_name(m::$decoder_name)
                    raw = decode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset)
                    return $enum_type_name.SbeEnum(raw)
                end
                
                @inline function $field_name_setter(m::$encoder_name, value::$enum_type_name.SbeEnum)
                    encode_value($encoding_type_symbol, m.buffer, m.offset + $field_offset, $encoding_type_symbol(value))
                end
                
                export $field_name, $field_name_setter
            end)
        end
    end
    
    return exprs
end

"""
Helper function to generate set field accessor expressions.
"""
function generate_set_field_expr(field_name::Symbol, field_def::Schema.FieldDefinition,
                                 type_def::Schema.SetType, field_offset::Int,
                                 abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol)
    set_type_name = Symbol(to_pascal_case(type_def.name))
    encoding_julia_type = to_julia_type(type_def.encoding_type)
    field_name_setter = Symbol(field_name, :!)
    
    exprs = Expr[]
    
    # Generate metadata
    push!(exprs, generate_field_metadata_expr(field_name, field_def, nothing, field_offset, encoding_julia_type, abstract_type_name))
    
    # Generate accessor that returns set type (using imported set module)
    push!(exprs, quote
        @inline function $field_name(m::$decoder_name)
            return $set_type_name.Decoder(m.buffer, m.offset + $field_offset)
        end
        
        @inline function $field_name(m::$encoder_name)
            return $set_type_name.Encoder(m.buffer, m.offset + $field_offset)
        end
        
        export $field_name
    end)
    
    return exprs
end

"""
Helper function to generate composite field accessor expressions.
"""
function generate_composite_field_expr(field_name::Symbol, field_def::Schema.FieldDefinition,
                                       type_def::Schema.CompositeType, field_offset::Int,
                                       abstract_type_name::Symbol, decoder_name::Symbol, encoder_name::Symbol, schema::Schema.MessageSchema)
    composite_type_name = Symbol(to_pascal_case(type_def.name))
    
    exprs = Expr[]
    
    # Calculate composite size
    composite_size = calculate_composite_size(type_def, schema)
    
    # Generate metadata for composite field with type dispatch
    field_id_fn = Symbol(field_name, :_id)
    field_since_fn = Symbol(field_name, :_since_version)
    field_in_acting_fn = Symbol(field_name, :_in_acting_version)
    field_offset_fn = Symbol(field_name, :_encoding_offset)
    field_length_fn = Symbol(field_name, :_encoding_length)
    field_null_fn = Symbol(field_name, :_null_value)
    field_min_fn = Symbol(field_name, :_min_value)
    field_max_fn = Symbol(field_name, :_max_value)
    field_meta_fn = Symbol(field_name, :_meta_attribute)
    
    # Get presence and semantic type for meta_attribute
    presence = field_def.presence === nothing ? "required" : field_def.presence
    semantic_type = field_def.semantic_type === nothing ? "" : field_def.semantic_type
    
    push!(exprs, quote
        # Instance dispatch
        $field_id_fn(::$abstract_type_name) = UInt16($(field_def.id))
        $field_since_fn(::$abstract_type_name) = UInt16($(field_def.since_version))
        $field_in_acting_fn(m::$abstract_type_name) = sbe_acting_version(m) >= UInt16($(field_def.since_version))
        $field_offset_fn(::$abstract_type_name) = $field_offset
        $field_length_fn(::$abstract_type_name) = $composite_size
        $field_null_fn(::$abstract_type_name) = $(typemax(UInt8))
        $field_min_fn(::$abstract_type_name) = $(typemin(UInt8))
        $field_max_fn(::$abstract_type_name) = $(typemax(UInt8))
        
        # Type dispatch
        $field_id_fn(::Type{<:$abstract_type_name}) = UInt16($(field_def.id))
        $field_since_fn(::Type{<:$abstract_type_name}) = UInt16($(field_def.since_version))
        $field_offset_fn(::Type{<:$abstract_type_name}) = $field_offset
        $field_length_fn(::Type{<:$abstract_type_name}) = $composite_size
        $field_null_fn(::Type{<:$abstract_type_name}) = $(typemax(UInt8))
        $field_min_fn(::Type{<:$abstract_type_name}) = $(typemin(UInt8))
        $field_max_fn(::Type{<:$abstract_type_name}) = $(typemax(UInt8))
        
        # Meta attribute function
        function $field_meta_fn(::$abstract_type_name, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
        function $field_meta_fn(::Type{<:$abstract_type_name}, meta_attribute)
            meta_attribute === :presence && return Symbol($presence)
            meta_attribute === :semanticType && return Symbol($semantic_type)
            return Symbol("")
        end
        
        export $field_id_fn, $field_since_fn, $field_in_acting_fn, $field_offset_fn, $field_length_fn
        export $field_null_fn, $field_min_fn, $field_max_fn, $field_meta_fn
        
        # Generate accessor that returns composite type (in same block to avoid overwrite warnings)
        @inline function $field_name(m::$decoder_name)
            return $composite_type_name.Decoder(m.buffer, m.offset + $field_offset, m.acting_version)
        end
        
        @inline function $field_name(m::$encoder_name)
            return $composite_type_name.Encoder(m.buffer, m.offset + $field_offset)
        end
        
        export $field_name
    end)
    
    return exprs
end

"""
    generateGroup_expr(group_def::Schema.GroupDefinition, parent_name::String, schema::Schema.MessageSchema) -> Expr

Generate a repeating group type definition as an expression (for file-based generation).

This is the expression-returning version of `generateGroup!()`. Instead of evaluating
the code in a module with `Core.eval`, it returns the expression that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `group_def::Schema.GroupDefinition`: Group definition from schema
- `parent_name::String`: Name of the parent message or group
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Expr`: A quote block containing the complete group module definition

# Example
```julia
expr = generateGroup_expr(group_def, "Car", schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
Creates a nested module with:
- Mutable Decoder/Encoder structs with iteration state
- Constructors that read/write dimension headers
- Iterator protocol (iterate, length, eltype)
- SBE interface methods (sbe_block_length, sbe_acting_version, etc.)
- Field accessor functions for group members
- reset_count_to_index! for encoders
- Support for nested groups (recursive)
- Support for variable-length data

Note: Due to the complexity of groups (iteration state, dimension headers, recursive nesting,
position management), and the current focus on getting basic types working first, this
function currently returns an error. Groups will be implemented in a future phase after
the core message, enum, set, and composite generators are fully validated.
"""
function generateGroup_expr(group_def::Schema.GroupDefinition, parent_name::String, parent_abstract_type::Symbol, schema::Schema.MessageSchema)
    # Extract group metadata
    group_name = group_def.name
    group_id = group_def.id
    dimension_type = group_def.dimension_type
    since_version = group_def.since_version

    # Create module name for the group: fuelFigures -> FuelFigures
    group_module_name = Symbol(uppercasefirst(group_name))
    
    # Inside the module, we use simple names
    decoder_name = :Decoder
    encoder_name = :Encoder
    base_type_name = Symbol("Abstract", group_module_name)  # AbstractFuelFigures

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

    dimension_module = Symbol(uppercasefirst(dimension_type))
    
    # Build the group module expression as a block of statements
    module_body_exprs = Expr[]
    
    # 1. Import statements
    push!(module_body_exprs, :(using SBE: PositionPointer))
    push!(module_body_exprs, :(using SBE: AbstractSbeGroup))
    push!(module_body_exprs, :(using SBE: AbstractSbeMessage))
    push!(module_body_exprs, :(using SBE: to_string))
    push!(module_body_exprs, :(using StringViews: StringView))
    # Import dimension encoding from parent module
    push!(module_body_exprs, :(using ..$(dimension_module)))
    
    # Import composites, enums, and sets referenced by group fields
    imported_types = Set{Symbol}()
    for field in group_def.fields
        type_def = find_type_by_name(schema, field.type_ref)
        if type_def !== nothing
            if type_def isa Schema.CompositeType || type_def isa Schema.EnumType || type_def isa Schema.SetType
                type_module_name = Symbol(to_pascal_case(field.type_ref))
                if type_module_name ∉ imported_types
                    push!(module_body_exprs, :(using ..$(type_module_name)))
                    push!(imported_types, type_module_name)
                end
            end
        end
    end
    
    # 2. Generate consistent encode/decode function imports and aliases
    push!(module_body_exprs, :(import SBE: encode_value_le, decode_value_le, encode_array_le, decode_array_le))
    push!(module_body_exprs, :(const encode_value = encode_value_le))
    push!(module_body_exprs, :(const decode_value = decode_value_le))
    push!(module_body_exprs, :(const encode_array = encode_array_le))
    push!(module_body_exprs, :(const decode_array = decode_array_le))
    
    # 3. Generate abstract type
    push!(module_body_exprs, quote
        abstract type $base_type_name{T} <: AbstractSbeGroup end
    end)
    
    # 4. Generate Decoder struct (mutable for iteration state)
    push!(module_body_exprs, quote
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
    
    # 5. Generate Encoder struct (mutable for iteration state)
    push!(module_body_exprs, quote
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
    
    # 6. Generate Decoder constructor (reads dimension header)
    push!(module_body_exprs, quote
        @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version)
            dimensions = $dimension_module.Decoder(buffer, position_ptr[])
            position_ptr[] += $dimension_header_size  # Skip dimension header
            block_len = $dimension_module.blockLength(dimensions)
            num_in_group = $dimension_module.numInGroup(dimensions)
            return $decoder_name(buffer, 0, position_ptr, block_len, acting_version, num_in_group, 0)
        end

        # Decoder constructor for empty group (version handling)
        @inline function $decoder_name(buffer, position_ptr::PositionPointer, acting_version, block_length, count)
            return $decoder_name(buffer, 0, position_ptr, block_length, acting_version, count, 0)
        end
    end)
    
    # 7. Generate Encoder constructor (writes dimension header)
    push!(module_body_exprs, quote
        @inline function $encoder_name(buffer, count::Integer, position_ptr::PositionPointer)
            if count > 65534
                error("count outside of allowed range [0, 65534]")
            end
            dimensions = $dimension_module.Encoder(buffer, position_ptr[])
            $dimension_module.blockLength!(dimensions, UInt16($block_length))
            $dimension_module.numInGroup!(dimensions, UInt16(count))
            initial_position = position_ptr[]
            position_ptr[] += $dimension_header_size  # Skip dimension header
            return $encoder_name(buffer, 0, position_ptr, initial_position, count, 0)
        end
    end)
    
    # 8. Generate SBE interface methods (extend functions from SBE module)
    push!(module_body_exprs, quote
        # Import SBE module and shared group functions
        import SBE
        using SBE: sbe_position, sbe_position!, sbe_position_ptr, sbe_header_size, sbe_acting_block_length, sbe_acting_version, next!

        # Block length metadata (extend SBE.sbe_acting_block_length)
        SBE.sbe_block_length(::$base_type_name) = UInt16($block_length)
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
    
    # 9. Import iterator protocol from AbstractSbeGroup (NOT in quote block!)
    # This must be a direct Expr at module scope, not wrapped in begin...end
    push!(module_body_exprs, :(using SBE: Base.iterate, Base.length, Base.isdone))
    
    # 10. Generate reset_count_to_index! for encoders
    push!(module_body_exprs, quote
        function reset_count_to_index!(g::$encoder_name)
            g.count = g.index
            dimensions = $dimension_module.Encoder(g.buffer, g.initial_position)
            $dimension_module.numInGroup!(dimensions, g.count)
            return g.count
        end

        # Export reset_count_to_index!
        export reset_count_to_index!
    end)
    
    # 11. Generate field accessors for group members
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

        field_exprs = generateFields_expr(base_type_name, decoder_name, encoder_name, modified_field, group_name, schema)
        append!(module_body_exprs, field_exprs)

        # Advance offset for next field
        field_size = get_field_size(schema, field)
        current_offset = actual_offset + field_size
    end
    
    # 12. Generate nested groups recursively
    if !isempty(group_def.groups)
        for nested_group_def in group_def.groups
            (nested_group_expr, nested_parent_accessor_exprs) = generateGroup_expr(nested_group_def, group_name, base_type_name, schema)
            # Insert nested group module
            push!(module_body_exprs, nested_group_expr)
            # Insert parent accessor functions for nested group
            append!(module_body_exprs, nested_parent_accessor_exprs)
        end
    end
    
    # 13. Generate var data accessors for group members
    if !isempty(group_def.var_data)
        for var_data_def in group_def.var_data
            var_data_expr = generateVarData_expr(var_data_def, schema)
            # Extract expressions from the returned quote block, filtering out LineNumberNodes
            if var_data_expr isa Expr && var_data_expr.head == :block
                for arg in var_data_expr.args
                    if arg isa Expr
                        push!(module_body_exprs, arg)
                    end
                end
            else
                push!(module_body_exprs, var_data_expr)
            end
        end
    end
    
    # Build the complete module expression
    module_expr = Expr(:module, true, group_module_name, Expr(:block, module_body_exprs...))
    
    # Build parent accessor expressions (to be inserted in the parent module)
    accessor_name = Symbol(toCamelCase(group_name))
    accessor_name_encoder = Symbol(string(accessor_name, "!"))
    parent_accessor_exprs = Expr[]
    
    if since_version > 0
        # Version-aware group accessor
        accessor_quote = quote
            # Decoder accessor: Returns group decoder instance or empty group if not in version
            @inline function $accessor_name(m::Decoder)
                if m.acting_version < $(version_expr(schema, since_version))
                    # Return empty group (count=0) when group not in version
                    return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version, $(version_expr(schema, 0)), $(version_expr(schema, 0)))
                end
                # Access acting_version field directly from decoder
                return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
            end

            # Encoder accessor: Returns group encoder instance with specified count
            @inline function $accessor_name_encoder(m::Encoder, count)
                return $group_module_name.Encoder(m.buffer, count, sbe_position_ptr(m))
            end

            # Metadata functions for the group
            $(Symbol(accessor_name, :_id))(::$parent_abstract_type) = $(template_id_expr(schema, group_id))
            $(Symbol(accessor_name, :_since_version))(::$parent_abstract_type) = $(version_expr(schema, since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::Decoder) = m.acting_version >= $(version_expr(schema, since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::Encoder) = $(version_expr(schema, schema.version)) >= $(version_expr(schema, since_version))

            # Export the accessor functions
            export $accessor_name, $accessor_name_encoder, $group_module_name
        end
        # Extract only Expr items, filter out LineNumberNodes
        for arg in accessor_quote.args
            if arg isa Expr
                push!(parent_accessor_exprs, arg)
            end
        end
    else
        # Non-versioned group accessor (version 0)
        accessor_quote = quote
            # Decoder accessor: Returns group decoder instance
            @inline function $accessor_name(m::Decoder)
                # Access acting_version field directly from decoder
                return $group_module_name.Decoder(m.buffer, sbe_position_ptr(m), m.acting_version)
            end

            # Encoder accessor: Returns group encoder instance with specified count
            @inline function $accessor_name_encoder(m::Encoder, count)
                return $group_module_name.Encoder(m.buffer, count, sbe_position_ptr(m))
            end

            # Metadata functions for the group
            $(Symbol(accessor_name, :_id))(::$parent_abstract_type) = $(template_id_expr(schema, group_id))
            $(Symbol(accessor_name, :_since_version))(::$parent_abstract_type) = $(version_expr(schema, group_def.since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::Decoder) = m.acting_version >= $(version_expr(schema, group_def.since_version))
            $(Symbol(accessor_name, :_in_acting_version))(m::Encoder) = $(version_expr(schema, schema.version)) >= $(version_expr(schema, group_def.since_version))

            # Export the accessor functions
            export $accessor_name, $accessor_name_encoder, $group_module_name
        end
        # Extract only Expr items, filter out LineNumberNodes
        for arg in accessor_quote.args
            if arg isa Expr
                push!(parent_accessor_exprs, arg)
            end
        end
    end
    
    # Return both the group module and the parent accessor expressions
    # The group module should be inserted first, then the parent accessors
    return (module_expr, parent_accessor_exprs)
end

"""
    generateVarData_expr(data_def::Schema.VarDataDefinition, schema::Schema.MessageSchema) -> Expr

Generate variable-length data accessor functions as an expression (for file-based generation).

This is the expression-returning version of `generateVarData!()`. Instead of evaluating
the code in a module with `Core.eval`, it returns the expression that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `data_def::Schema.VarDataDefinition`: Variable data definition from schema
- `schema::Schema.MessageSchema`: Complete schema for context

# Returns
- `Expr`: A quote block containing all variable-length data accessor functions

# Example
```julia
expr = generateVarData_expr(data_def, schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
Creates accessor functions for variable-length data:
- Length accessor (reads UInt8/16/32 header)
- Length setter (writes length header)
- Skip function (advances position past var data)
- Reader (returns view or string, advances position)
- Type conversion methods (String, AbstractArray, Symbol, NTuple, Real)
- Writer (writes length + data, advances position)
- Metadata constants (id, since_version, header_length)

# Character Encoding Support
Character-encoded vardata (primitiveType="char") automatically returns StringView
with null-byte trimming for zero-allocation string access. Supported encodings:
- **ASCII** - Standard ASCII encoding (fully supported)
- **UTF-8** - UTF-8 encoding (fully supported)
- Other encodings (ISO-8859-1, etc.) - May work but not explicitly tested
"""
function generateVarData_expr(data_def::Schema.VarDataDefinition, schema::Schema.MessageSchema)
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
        return quote
            # VarData field $(data_def.name) skipped: encoding type not found
        end
    end
    
    # Calculate header length and extract length field type from the composite
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
    
    decoder_name = :Decoder
    encoder_name = :Encoder
    
    # Build all accessor functions
    exprs = Expr[]
    
    # Generate length accessor
    if since_version > 0
        push!(exprs, quote
            @inline function $length_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                if m.acting_version < UInt16($since_version)
                    return $length_primitive_type(0)
                end
                return decode_value($length_primitive_type, m.buffer, m.position_ptr[])
            end
        end)
    else
        push!(exprs, quote
            @inline function $length_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                return decode_value($length_primitive_type, m.buffer, m.position_ptr[])
            end
        end)
    end
    
    # Generate length setter
    push!(exprs, quote
        @inline function $length_name_setter(m::Union{AbstractSbeMessage, AbstractSbeGroup}, n::Integer)
            # SBE spec: varData length is limited to 2^30 (1GB)
            @boundscheck n > 1073741824 && throw(ArgumentError("length exceeds SBE schema limit (1GB)"))
            return encode_value($length_primitive_type, m.buffer, m.position_ptr[], convert($length_primitive_type, n))
        end
    end)
    
    # Generate skip method
    if since_version > 0
        push!(exprs, quote
            @inline function $skip_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                if m.acting_version < UInt16($since_version)
                    return 0
                end
                len = $length_name(m)
                pos = m.position_ptr[] + $header_length
                m.position_ptr[] = pos + len
                return len
            end
        end)
    else
        push!(exprs, quote
            @inline function $skip_name(m::Union{AbstractSbeMessage, AbstractSbeGroup})
                len = $length_name(m)
                pos = m.position_ptr[] + $header_length
                m.position_ptr[] = pos + len
                return len
            end
        end)
    end
    
    # Generate reader (returns view or string, advances position)
    if since_version > 0
        if is_character_encoded
            # Character-encoded vardata returns String by default
            push!(exprs, quote
                @inline function $accessor_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
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
            # Binary vardata returns byte view
            push!(exprs, quote
                @inline function $accessor_name(m::$decoder_name)
                    if m.acting_version < UInt16($since_version)
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
        if is_character_encoded
            # Character-encoded vardata returns String by default
            push!(exprs, quote
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
            # Binary vardata returns byte view
            push!(exprs, quote
                @inline function $accessor_name(m::$decoder_name)
                    len = $length_name(m)
                    pos = m.position_ptr[] + $header_length
                    m.position_ptr[] = pos + len
                    return view(m.buffer, pos+1:pos+len)
                end
            end)
        end
    end
    
    # Generate type conversion methods
    push!(exprs, quote
        # Convert to typed array
        @inline function $accessor_name(m::$decoder_name, ::Type{AbstractArray{T}}) where {T<:Real}
            return reinterpret(T, $accessor_name(m))
        end
        
        # Convert to string
        @inline function $accessor_name(m::$decoder_name, ::Type{T}) where {T<:AbstractString}
            bytes = $accessor_name(m)
            last_nonzero = findlast(!iszero, bytes)
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
    
    # Generate writer methods
    push!(exprs, quote
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
    push!(exprs, quote
        const $(Symbol(string(metadata_prefix, "id"))) = UInt16($(data_def.id))
        const $(Symbol(string(metadata_prefix, "since_version"))) = UInt16($(data_def.since_version))
        const $(Symbol(string(metadata_prefix, "header_length"))) = $header_length
    end)
    
    # Generate exports
    push!(exprs, quote
        export $accessor_name, $accessor_name_setter, $length_name, $length_name_setter, $skip_name
    end)
    
    # Wrap everything in a quote block
    return quote
        $(exprs...)
    end
end

"""
    generate_module_expr(schema::Schema.MessageSchema) -> Expr

Generate a complete schema module as an expression (for file-based generation).

This is the main orchestrator function that assembles all type definitions into a
complete module. It generates types in dependency order and returns an expression
that can be:
1. Converted to a string with `expr_to_code_string()`
2. Written to a file
3. Loaded with `include()` or `include_string()`

# Arguments
- `schema::Schema.MessageSchema`: Complete schema definition

# Returns
- `Expr`: A quote block containing the complete module definition

# Example
```julia
schema = parse_sbe_schema(xml_content)
expr = generate_module_expr(schema)
code = expr_to_code_string(expr)
write("generated.jl", code)
```

# Generated Expression Structure
Creates a complete module with all types in dependency order:
1. Module declaration with name from schema.package
2. Import statements (SBE interfaces, dependencies)
3. Endianness helper functions (encode_value, decode_value)
4. Enum types (using @enumx with SbeEnum trait)
5. Set types (as nested modules with bitset operations)
6. Composite types (as nested modules with field accessors)
7. Message types (as nested modules with MessageHeader integration)
8. Group types (if any - currently stubbed)
9. Export statements for all generated types

# Dependency Ordering
Types are generated in this order to ensure dependencies exist:
- Enums first (no dependencies)
- Sets second (no dependencies except primitives)
- Composites third (may reference enums/sets)
- Messages last (may reference all other types)
- Groups would be last (may contain nested groups recursively)

Note: This function currently handles messages WITHOUT groups. Messages with
groups will generate but groups will be stubbed. Full group support will be
added in Phase 2B after core integration is validated.
"""
function generate_module_expr(schema::Schema.MessageSchema)
    # Create module name from package
    # Convert package name to PascalCase (e.g., "composite.elements" -> "CompositeElements")
    # Split on dots and underscores, then capitalize each part
    package_parts = split(replace(schema.package, "." => "_"), "_")
    module_name = Symbol(join([uppercasefirst(part) for part in package_parts]))
    
    # Collect all type expressions in dependency order
    type_exprs = Expr[]
    export_symbols = Symbol[]
    
    # Helper to unwrap expressions from quote blocks
    # Generator functions return quote blocks, but we need the raw expressions
    unwrap_expr(expr::Expr) = (expr.head == :block && length(expr.args) == 1) ? expr.args[1] : expr
    
    # Helper to recursively extract nested types from composites
    function extract_nested_types!(composite_def::Schema.CompositeType, extracted_types::Vector)
        for member in composite_def.members
            if member isa Schema.EnumType
                push!(extracted_types, member)
            elseif member isa Schema.SetType
                push!(extracted_types, member)
            elseif member isa Schema.CompositeType
                # Recursively extract from nested composite
                extract_nested_types!(member, extracted_types)
                # Add the nested composite itself
                push!(extracted_types, member)
            end
        end
    end
    
    # 1. Generate enum types (no dependencies)
    #    First pass: extract nested enums from composites and generate them
    nested_enums = Schema.EnumType[]
    for type_def in schema.types
        if type_def isa Schema.CompositeType
            extract_nested_types!(type_def, nested_enums)
        end
    end
    
    # Generate top-level enums
    for type_def in schema.types
        if type_def isa Schema.EnumType
            enum_name = Symbol(to_pascal_case(type_def.name))
            enum_expr = generateEnum_expr(type_def, schema)
            push!(type_exprs, unwrap_expr(enum_expr))
            push!(export_symbols, enum_name)
        end
    end
    
    # Generate nested enums that were extracted
    for enum_def in nested_enums
        if enum_def isa Schema.EnumType
            enum_name = Symbol(to_pascal_case(enum_def.name))
            enum_expr = generateEnum_expr(enum_def, schema)
            push!(type_exprs, unwrap_expr(enum_expr))
            push!(export_symbols, enum_name)
        end
    end
    
    # 2. Generate set types (no dependencies except primitives)
    for type_def in schema.types
        if type_def isa Schema.SetType
            set_name = Symbol(to_pascal_case(type_def.name))
            set_expr = generateSet_expr(type_def, schema)
            push!(type_exprs, unwrap_expr(set_expr))
            push!(export_symbols, set_name)
        end
    end
    
    # Generate nested sets that were extracted
    for set_def in nested_enums  # Reuse the same array since we extracted all types
        if set_def isa Schema.SetType
            set_name = Symbol(to_pascal_case(set_def.name))
            set_expr = generateSet_expr(set_def, schema)
            push!(type_exprs, unwrap_expr(set_expr))
            push!(export_symbols, set_name)
        end
    end
    
    # 3. Generate nested composites that were extracted (before their parents)
    for nested_def in nested_enums
        if nested_def isa Schema.CompositeType
            composite_name = Symbol(to_pascal_case(nested_def.name))
            composite_expr = generateComposite_expr(nested_def, schema, true)  # true = is_nested, don't recurse
            push!(type_exprs, unwrap_expr(composite_expr))
            push!(export_symbols, composite_name)
        end
    end
    
    # 4. Generate top-level composite types (may reference enums/sets/nested composites)
    for type_def in schema.types
        if type_def isa Schema.CompositeType
            composite_name = Symbol(to_pascal_case(type_def.name))
            composite_expr = generateComposite_expr(type_def, schema, false)  # false = top-level, DO recurse but don't nest
            push!(type_exprs, unwrap_expr(composite_expr))
            push!(export_symbols, composite_name)
        end
    end
    
    # 4. Generate message types (may reference all other types)
    for message_def in schema.messages
        message_name = Symbol(to_pascal_case(message_def.name))
        
        # Generate the message module
        message_expr = generateMessage_expr(message_def, schema)
        push!(type_exprs, unwrap_expr(message_expr))
        push!(export_symbols, message_name)
        
        # TODO: Generate groups within messages (Phase 2B)
        # for group_def in message_def.groups
        #     group_expr = generateGroup_expr(group_def, message_def.name, schema)
        #     # Groups are nested inside message module, handled in generateMessage_expr
        # end
    end
    
    # Get endianness-specific imports
    endian_imports = generateEncodedTypes_expr(schema)
    
    # Build the complete module expression
    # We return an Expr(:module, ...) which can be:
    # 1. Converted to string with expr_to_code_string()
    # 2. Written to a file
    # 3. Loaded with include()
    # Note: Cannot be directly Core.eval'd because Julia doesn't allow
    # module expressions at non-top-level. Must write to file first.
    
    # Build module body as a block expression (NOT using quote!)
    # quote would wrap everything in begin...end which prevents nested modules
    module_body = Expr(:block,
        # Import required packages
        :(using SBE: AbstractSbeMessage, AbstractSbeField, AbstractSbeGroup),
        :(using SBE: PositionPointer, to_string),
        :(using EnumX),
        :(using MappedArrays),
        :(using StringViews),
        
        # Import endianness functions
        endian_imports,
        
        # Generate all types in dependency order
        type_exprs...,
        
        # Export all generated types
        Expr(:export, export_symbols...)
    )
    
    return Expr(:module, true, module_name, module_body)
end



"""
    generate(xml_path::String, output_path::String) -> String

Generate Julia code from an SBE XML schema and write it to a file.

This is the main public API function for file-based code generation. It:
1. Parses the SBE XML schema
2. Generates a complete module with all types
3. Writes the generated code to the specified output file
4. Returns the path to the generated file

To load the generated module, use `include()`:
```julia
SBE.generate("schema.xml", "generated/Schema.jl")
include("generated/Schema.jl")  # Loads into Main
```

# Arguments
- `xml_path::String`: Path to the SBE XML schema file
- `output_path::String`: Path where the generated Julia code will be written

# Returns
- `String`: The path to the generated file (same as `output_path`)

# Example
```julia
# Generate code to file
output_file = SBE.generate("schema.xml", "generated/Schema.jl")
println("Generated: ", output_file)

# Load the generated module
include(output_file)

# Use the module (module name comes from schema package attribute)
buffer = zeros(UInt8, 1024)
msg = Baseline.Car.Encoder(buffer, 0)  # "Baseline" from package="baseline"
```

# Generated File Structure
The output file will contain a complete Julia module with:
- All enum types (using @enumx)
- All set types (as nested modules)
- All composite types (as nested modules)
- All message types (as nested modules)
- Proper imports and exports

# Notes
- Generated code is fully precompilable (no world age issues)
- Output directory will be created if it doesn't exist
- Any existing file at output_path will be overwritten
- Generated module will be named after the schema package (capitalized)
- You must use `include()` to load the module into your session
"""
function generate(xml_path::String, output_path::String)
    # Verify input file exists
    if !isfile(xml_path)
        error("Schema file not found: $xml_path")
    end
    
    # Parse the schema (Step 1: XML → Schema)
    xml_content = read(xml_path, String)
    schema = parse_sbe_schema(xml_content)
    
    # Generate IR (Step 2: Schema → IR)
    ir = schema_to_ir(schema)
    
    # Reconstruct schema from IR (Step 3: IR → Schema)
    # This ensures the IR is the canonical representation
    schema_from_ir = ir_to_schema(ir)
    
    # Generate the module expression (Step 4: Schema → Julia Code)
    module_expr = generate_module_expr(schema_from_ir)
    
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
    generate(xml_path::String) -> String

Generate Julia code from an SBE schema XML file and return it as a string.

This version generates the code in-memory without writing to a file. The returned
string can be used with `Base.include_string()` to load the module dynamically.

The generation process follows: XML → Schema → IR → Julia Code
The IR (Intermediate Representation) is compatible with the reference SBE implementation.

# Arguments
- `xml_path::String`: Path to the SBE XML schema file

# Returns
- `String`: Complete Julia module code ready for `include_string()`

# Example
```julia
# Generate code as string
code = SBE.generate("schema.xml")

# Load with include_string (no world age issues!)
Base.include_string(Main, code)

# Use the module
buffer = zeros(UInt8, 1024)
msg = Main.Baseline.Car.Encoder(buffer, 0)
```

# Use with Macro
For the most convenient usage, see `@load_schema` which combines generation
and loading in a single macro call.

# Notes
- Generated code is identical to file-based generation
- No temporary files are created
- `include_string()` evaluates at parse time, avoiding world age issues
- Generated module will be named after the schema package (capitalized)
"""
function generate(xml_path::String)
    # Verify input file exists
    if !isfile(xml_path)
        error("Schema file not found: $xml_path")
    end
    
    # Parse the schema (Step 1: XML → Schema)
    xml_content = read(xml_path, String)
    schema = parse_sbe_schema(xml_content)
    
    # Generate IR (Step 2: Schema → IR)
    ir = schema_to_ir(schema)
    
    # Reconstruct schema from IR (Step 3: IR → Schema)
    # This ensures the IR is the canonical representation
    schema_from_ir = ir_to_schema(ir)
    
    # Generate the complete module expression (Step 4: Schema → Julia Code)
    module_expr = generate_module_expr(schema_from_ir)
    
    # Convert to code string and return
    return expr_to_code_string(module_expr)
end

"""
    generate_ir(xml_path::String) -> IR.IntermediateRepresentation

Generate an Intermediate Representation (IR) from an SBE schema XML file.

The IR is compatible with the reference SBE implementation and can be:
- Inspected programmatically
- Serialized to binary format using the SBE IR schema
- Used for cross-implementation compatibility testing

# Arguments
- `xml_path::String`: Path to the SBE XML schema file

# Returns
- `IR.IntermediateRepresentation`: The IR containing frame header and tokens

# Example
```julia
ir = SBE.generate_ir("example-schema.xml")
println("Schema: ", ir.frame.package_name)
println("Number of tokens: ", length(ir.tokens))
```
"""
function generate_ir(xml_path::String)
    # Verify input file exists
    if !isfile(xml_path)
        error("Schema file not found: $xml_path")
    end
    
    # Parse the schema
    xml_content = read(xml_path, String)
    schema = parse_sbe_schema(xml_content)
    
    # Generate and return IR
    return schema_to_ir(schema)
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
    value = if member.null_value !== nothing
        try
            parse(julia_type, member.null_value)
        catch
            # Fallback to default
            nothing
        end
    else
        nothing
    end
    
    # Return the bare value (will be wrapped at call site)
    if value !== nothing
        return value
    elseif julia_type <: AbstractFloat
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
    value = if member.min_value !== nothing
        try
            parse(julia_type, member.min_value)
        catch
            # Fallback to default
            nothing
        end
    else
        nothing
    end
    
    # Return the bare value (will be wrapped at call site)
    if value !== nothing
        return value
    else
        return typemin(julia_type)
    end
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
    value = if member.max_value !== nothing
        try
            parse(julia_type, member.max_value)
        catch
            # Fallback to default
            nothing
        end
    else
        nothing
    end
    
    # Return the bare value (will be wrapped at call site)
    if value !== nothing
        return value
    else
        return typemax(julia_type)
    end
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
    get_header_field_type(schema::Schema.MessageSchema, field_name::String) -> Type

Get the Julia type for a field in the messageHeader composite.

# Arguments
- `schema::Schema.MessageSchema`: Schema containing the header definition
- `field_name::String`: Name of the header field (e.g., "templateId", "version", "schemaId")

# Returns
- `Type`: Julia type for the field (e.g., UInt16, UInt32)

# Example
```julia
template_id_type = get_header_field_type(schema, "templateId")  # Returns UInt16
```
"""
function get_header_field_type(schema::Schema.MessageSchema, field_name::String)
    # Find the messageHeader composite
    header_type = find_type_by_name(schema, schema.header_type)
    if header_type === nothing || !(header_type isa Schema.CompositeType)
        @warn "Header type $(schema.header_type) not found, defaulting to UInt16"
        return UInt16
    end
    
    # Find the field in the header
    for member in header_type.members
        if member isa Schema.EncodedType && member.name == field_name
            return to_julia_type(member.primitive_type)
        end
    end
    
    @warn "Field $field_name not found in header $(schema.header_type), defaulting to UInt16"
    return UInt16
end

"""
    get_schema_id_type(schema::Schema.MessageSchema) -> Type

Get the Julia type for schemaId from the messageHeader composite.
"""
get_schema_id_type(schema::Schema.MessageSchema) = get_header_field_type(schema, "schemaId")

"""
    get_template_id_type(schema::Schema.MessageSchema) -> Type

Get the Julia type for templateId from the messageHeader composite.
"""
get_template_id_type(schema::Schema.MessageSchema) = get_header_field_type(schema, "templateId")

"""
    get_version_type(schema::Schema.MessageSchema) -> Type

Get the Julia type for version from the messageHeader composite.
"""
get_version_type(schema::Schema.MessageSchema) = get_header_field_type(schema, "version")

"""
    get_block_length_type(schema::Schema.MessageSchema) -> Type

Get the Julia type for blockLength from the messageHeader composite.
"""
get_block_length_type(schema::Schema.MessageSchema) = get_header_field_type(schema, "blockLength")

"""
    type_expr(schema::Schema.MessageSchema, field_name::String, value) -> Expr

Create a typed expression for a schema field value using the correct type from the schema.
Returns an Expr like `UInt16(value)` where UInt16 comes from the schema's messageHeader.

# Arguments
- `schema::Schema.MessageSchema`: Schema containing type definitions
- `field_name::String`: Header field name ("templateId", "version", "schemaId", "blockLength")  
- `value`: The value to wrap in the type constructor

# Returns
- `Expr`: Expression like `:UInt16(value)` with proper type from schema

# Example
```julia
# Creates: UInt16(5)
expr = type_expr(schema, "templateId", 5)
```
"""
function type_expr(schema::Schema.MessageSchema, field_name::String, value)
    field_type = get_header_field_type(schema, field_name)
    return Expr(:call, Symbol(field_type), value)
end

"""
    template_id_expr(schema::Schema.MessageSchema, value) -> Expr

Create a typed expression for a template ID using the schema's templateId type.
"""
template_id_expr(schema::Schema.MessageSchema, value) = type_expr(schema, "templateId", value)

"""
    schema_id_expr(schema::Schema.MessageSchema, value) -> Expr

Create a typed expression for a schema ID using the schema's schemaId type.
"""
schema_id_expr(schema::Schema.MessageSchema, value) = type_expr(schema, "schemaId", value)

"""
    version_expr(schema::Schema.MessageSchema, value) -> Expr

Create a typed expression for a version using the schema's version type.
"""
version_expr(schema::Schema.MessageSchema, value) = type_expr(schema, "version", value)

"""
    block_length_expr(schema::Schema.MessageSchema, value) -> Expr

Create a typed expression for a block length using the schema's blockLength type.
"""
block_length_expr(schema::Schema.MessageSchema, value) = type_expr(schema, "blockLength", value)
