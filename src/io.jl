"""
	streamf(filename|io|formatted) -> ::FormattedStream
	streamf(f::Function, filename|io|formatted) -> f(s)

Wrap a resource as a stream of formatted objects, inferring format/coding
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
function streamf(f::Formatted, args...; kwargs...)
	format = resolveformat(f)
	coding = resolvecoding(f)
	streamf(f.resource, format, coding, args...; kwargs...)
end

streamf(filename::AbstractString, format::MIME, coding::Union{MIME,Nothing},
		args...; kwargs...) =
		streamf(open(filename), format, coding, args...; kwargs...)

function streamf(io::IO, format::MIME, coding::Union{MIME,Nothing}, args...;
		kwargs...)
	streamer = resolvestreamer(format)
	if coding == nothing
		streamf(streamer, format, io, args...; kwargs...)
	else
		decoder = resolvedecoder(coding)
		io2 = TranscodingStream(decoder(), io)
		streamf(streamer, format, io2, args...; kwargs...)
	end
end

streamf(resource::Union{AbstractString,IO}, args...; kwargs...) =
		streamf(infer(resource), args...; kwargs...)

function streamf(f::Function,
		resource::Union{AbstractString,IO,Formats.FormattedFilename}, args...;
		kwargs...)
	s = streamf(resource, args...; kwargs...)
	results = f(s)
	close(s)
	results
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
	stream
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
	iterate(iter, nothing)
end

function Base.iterate(iter::FormattedStreamIterator, ::Nothing)
	if eof(iter.s)
		nothing
	else
		read(iter.s), nothing
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
	iterate(iter, nothing)
end

function Base.iterate(iter::PreallocatedFormattedStreamIterator, ::Nothing)
	if eof(iter.s)
		nothing
	else
		read!(iter.s, iter.output), nothing
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
