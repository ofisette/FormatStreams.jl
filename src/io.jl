"""
    streamf(filename|io|formatted) -> ::FormattedStream
    streamf(f::Function, filename|io|formatted) -> f(s)

Wrap a resource as a stream of formatted objects, guessing format/coding
automatically if unspecified.

The second signature calls `f` with the opened stream as argument, then closes
the stream. This is intended to be called using `do` block syntax.

# Arguments

    filename::AbstractString
    io::IO
    formatted::Formatted

# Examples

```julia
julia> s = streamf("lysozyme.trr")
[...]

julia> s = streamf(open("lysozyme.trr"))
[...]

julia> s = streamf(specify("lysozyme.dat", "trajectory/x-trr"))
[...]
```
"""
function streamf(f::FormattedIO, args...; kwargs...)
    format = resolveformat(f)
	streamer = resolvestreamer(format)
    coding = resolvecoding(f)
	if coding == nothing
		io = f.resource
	else
		decoder = resolvedecoder(coding)
		io = TranscodingStream(decoder(), f.resource)
	end
	return streamf(streamer, format, io, args...; kwargs...)
end

streamf(f::FormattedFilename, args...; kwargs...) =
        streamf(open(f), args...; kwargs...)

streamf(filename::AbstractString, args...; kwargs...) =
        streamf(guess(filename), args...; kwargs...)

streamf(io::IO, args...; kwargs...) = streamf(guess(io), args...; kwargs...)

function streamf(f::Function,
        resource::Union{AbstractString,IO,Formats.FormattedFilename}, args...;
        kwargs...)
    s = streamf(resource, args...; kwargs...)
    results = f(s)
    close(s)
    return results
end

"""
    streamf(streamer, mime, io, args...; kwargs...)

Open `io` as a streamf of objects using a specific `streamer` for the `mime`
format.

This version should be specialised for streamers that wish to handle a specific
format. Arguments `args` and `kwargs` make it possible to customize streamer
behavior.

# Arguments

	streamer::FormatHandler
	mime::MIME
	io::IO

# Example

```julia
struct MyIO <: Formats.FormatHandler end

function streamf(::MyIO, ::MIME"image/apng", io::IO)
	# Open io and wrap it to provide a stream of objects
	return stream
end
```
"""
streamf

struct FormattedStreamIterator{T<:FormattedStream}
    s::T

    FormattedStreamIterator{T}(s::T) where {T<:FormattedStream} = new(s)
end

function Base.iterate(iter::FormattedStreamIterator)
    seekstart(iter.s)
    return iterate(iter, nothing)
end

function Base.iterate(iter::FormattedStreamIterator, ::Nothing)
    if eof(iter.s)
        return nothing
    else
        return read(iter.s), nothing
    end
end

Base.IteratorSize(::FormattedStreamIterator) = Base.SizeUnknown()

Base.eltype(::FormattedStreamIterator{<:FormattedStream{T}}) where {T} = T

"""
    eachval(s::FormattedStream)

Iterate over the values contained in the formatted stream `s`.
"""
eachval(s::T) where {T<:FormattedStream} = FormattedStreamIterator{T}(s)

struct PreallocatedFormattedStreamIterator{T1,T2<:FormattedStream{T1}}
    s::T2
    output::T1

    PreallocatedFormattedStreamIterator{T1,T2}(s::T2, output::T1) where
            {T1,T2<:FormattedStream{T1}} = new(s, output)
end

function Base.iterate(iter::PreallocatedFormattedStreamIterator)
    seekstart(iter.s)
    return iterate(iter, nothing)
end

function Base.iterate(iter::PreallocatedFormattedStreamIterator, ::Nothing)
    if eof(iter.s)
        return nothing
    else
        return read!(iter.s, iter.output), nothing
    end
end

Base.IteratorSize(::PreallocatedFormattedStreamIterator) = Base.SizeUnknown()

Base.eltype(::PreallocatedFormattedStreamIterator{T1,T2}) where
        {T1,T2<:FormattedStream{T1}} = T1

"""
    eachval!(s::FormattedStream, output)

Iterate over the values contained in the formatted stream `s`, reading into
pre-allocated `output`.
"""
eachval!(s::T2, output::T1) where {T1,T2<:FormattedStream{T1}} =
        PreallocatedFormattedStreamIterator{T1,T2}(s, output)
