struct SbeRegions{R <: Tuple} <: AbstractVector{AbstractVector{UInt8}}
    regions::R
end

Base.IndexStyle(::Type{<:SbeRegions}) = IndexLinear()
Base.size(regions::SbeRegions) = (length(regions.regions),)
Base.length(regions::SbeRegions) = length(regions.regions)
Base.axes(regions::SbeRegions) = (Base.OneTo(length(regions)),)
Base.firstindex(::SbeRegions) = 1
Base.lastindex(regions::SbeRegions) = length(regions)
Base.eltype(::Type{<:SbeRegions}) = AbstractVector{UInt8}

@inline function Base.getindex(regions::SbeRegions, index::Int)
    @boundscheck checkbounds(regions, index)
    return @inbounds regions.regions[index]
end

Base.Tuple(regions::SbeRegions) = regions.regions

@inline _sbe_region_tuple(region::AbstractVector{UInt8}) = (region,)

"""
    SbeFrame(prefix, tail)
    SbeFrame(first, second, remaining...)

A logical SBE byte sequence backed by two or more ordered byte regions.

`SbeFrame` does not concatenate or copy its regions. It retains them so borrowed
buffer owners remain reachable for as long as the frame is reachable. The
logical byte sequence is equivalent to concatenating [`sbe_regions`](@ref) in
order.

Generated terminal variable-data encoders return an `SbeFrame`. Frames can also
be constructed directly for decoding data carried in separate transport
regions, such as a fixed user header followed by a dynamic payload.

For generated terminal variable-data access, the top-level split must be at the
field boundary: `prefix` ends after the variable-data length header and `tail`
contains exactly the field bytes. Either side may itself be an `SbeFrame`, so
each side can still contain multiple physical regions.

All regions must use one-based indexing. A frame is not physically contiguous;
pass `sbe_regions(frame)` to scatter/gather transports instead of requesting a
pointer to the frame itself. `view(frame, range)` returns another zero-copy
`SbeFrame`.
"""
struct SbeFrame{
        P <: AbstractVector{UInt8},
        T <: AbstractVector{UInt8},
        R <: SbeRegions
    } <: AbstractVector{UInt8}
    prefix::P
    tail::T
    wire_length::Int
    regions::R

    function SbeFrame(prefix::P, tail::T) where {
            P <: AbstractVector{UInt8},
            T <: AbstractVector{UInt8}
        }
        Base.require_one_based_indexing(prefix, tail)
        wire_length = Base.Checked.checked_add(length(prefix), length(tail))
        region_tuple = (
            _sbe_region_tuple(prefix)...,
            _sbe_region_tuple(tail)...
        )
        regions = SbeRegions(region_tuple)
        return new{P, T, typeof(regions)}(
            prefix,
            tail,
            wire_length,
            regions
        )
    end
end

@inline _sbe_region_tuple(frame::SbeFrame) = frame.regions.regions

function SbeFrame(
    first::AbstractVector{UInt8},
    second::AbstractVector{UInt8},
    remaining::AbstractVector{UInt8}...
)
    isempty(remaining) && return SbeFrame(first, second)
    return SbeFrame(SbeFrame(first, second), remaining...)
end

Base.IndexStyle(::Type{<:SbeFrame}) = IndexLinear()
Base.size(frame::SbeFrame) = (frame.wire_length,)
Base.length(frame::SbeFrame) = frame.wire_length
Base.axes(frame::SbeFrame) = (Base.OneTo(frame.wire_length),)
Base.firstindex(::SbeFrame) = 1
Base.lastindex(frame::SbeFrame) = frame.wire_length
Base.eltype(::Type{<:SbeFrame}) = UInt8
Base.elsize(::Type{<:SbeFrame}) = 1
Base.iscontiguous(::SbeFrame) = false
Base.iscontiguous(::Type{<:SbeFrame}) = false
Base.similar(frame::SbeFrame) = Vector{UInt8}(undef, length(frame))

@inline function Base.getindex(frame::SbeFrame, index::Int)
    @boundscheck checkbounds(frame, index)
    prefix_length = length(frame.prefix)
    if index <= prefix_length
        return @inbounds frame.prefix[index]
    end
    return @inbounds frame.tail[index - prefix_length]
end

@inline function Base.setindex!(frame::SbeFrame, value::UInt8, index::Int)
    @boundscheck checkbounds(frame, index)
    prefix_length = length(frame.prefix)
    if index <= prefix_length
        @inbounds frame.prefix[index] = value
    else
        @inbounds frame.tail[index - prefix_length] = value
    end
    return value
end

function Base.view(frame::SbeFrame, indices::UnitRange{<:Integer})
    checkbounds(frame, indices)
    prefix_length = length(frame.prefix)
    first_index = Int(first(indices))
    last_index = Int(last(indices))

    if isempty(indices)
        if first_index <= prefix_length
            prefix_indices = first_index:first_index - 1
            tail_indices = 1:0
        else
            prefix_indices = 1:0
            tail_index = first_index - prefix_length
            tail_indices = tail_index:tail_index - 1
        end
    elseif last_index <= prefix_length
        prefix_indices = first_index:last_index
        tail_indices = 1:0
    elseif first_index > prefix_length
        prefix_indices = 1:0
        tail_indices =
            first_index - prefix_length:last_index - prefix_length
    else
        prefix_indices = first_index:prefix_length
        tail_indices = 1:last_index - prefix_length
    end

    prefix_view = view(frame.prefix, prefix_indices)
    tail_view = view(frame.tail, tail_indices)
    return SbeFrame(prefix_view, tail_view)
end

"""
    sbe_prefix(frame::SbeFrame)

Return the prefix in the frame's top-level split.
"""
@inline sbe_prefix(frame::SbeFrame) = frame.prefix

"""
    sbe_tail(frame::SbeFrame)

Return the logical tail of the frame. The tail may itself be an `SbeFrame` when
frames have been composed.
"""
@inline sbe_tail(frame::SbeFrame) = frame.tail

@inline function sbe_external_tail(
    frame::SbeFrame,
    payload_position::Integer,
    payload_length::Integer
)
    payload_position == length(frame.prefix) || throw(ArgumentError(
        "SbeFrame split does not align with the terminal variable-data payload"
    ))
    payload_length == length(frame.tail) || throw(ArgumentError(
        "SbeFrame tail length does not match the encoded variable-data length"
    ))
    return frame.tail
end

"""
    sbe_regions(frame_or_region) -> AbstractVector{AbstractVector{UInt8}}

Return the ordered physical byte regions that form a logical SBE frame.
Nested frames are flattened without copying their contents. The returned
tuple-backed vector can be supplied directly to APIs that accept a collection
of byte buffers; use `Tuple(sbe_regions(frame))` when a tuple is required.
"""
@inline sbe_regions(region::AbstractVector{UInt8}) =
    SbeRegions(_sbe_region_tuple(region))
@inline sbe_regions(frame::SbeFrame) = frame.regions

"""
    sbe_wire_length(frame_or_region) -> Int

Return the total number of bytes in a logical frame or byte region.
"""
@inline sbe_wire_length(region::AbstractVector{UInt8}) = length(region)
@inline sbe_wire_length(frame::SbeFrame) = frame.wire_length
