module FormatStreams

using Formats
using Formats:
		FormatHandler, Formatted, FormattedIO, FormattedFilename,
		resolveformat, resolvecoding

export FormattedStream, streamf, eachval, eachval!

"""
	FormattedStream{T}

Base type for formatted streams.

Parameter `T` is the type of the objects contained in the stream.
"""
abstract type FormattedStream{T} <: IO end

include("registry.jl")
include("io.jl")

"""
Read, write and detect streams of formatted data

```julia
using Formats        # Framework for data formats/codings (separate package)
using FormatCodecs   # Codecs for common codings (separate package)
using FormatStreams  # Streams of formatted data (this package)
```

To open a file as a stream of formatted objects, automatically guessing its
format/coding if unspecified:

```julia
s = streamf("trajectory.xtc")
```

An existing IO stream can be wrapped as a stream of formatted objects:

```julia
io = open("trajectory.xtc")
s = streamf(io)
```

Format/coding can be specified using functions from the `Formats` package:

```julia
s = streamf(specify("lysozyme.dat", "trajectory/x-trr"))
```

The `FormattedStream` returned by `streamf` can be used with standard IO
functions. Basic functions are always supported:

```julia
s = streamf("trajectory.xtc")
position(s)
eof(s)
seekstart(s)
close(s)
```

The `read` function is typically supported, allowing sequential reading:

```julia
s = streamf("trajectory.xtc")
while !eof(s)
	frame = read(s)
	[...]
end
close(s)
```

Function `read!` may be supported to read into a pre-allocated output buffer:

```julia
s = streamf("trajectory.xtc")
frame = MolecularModel()
while !eof(s)
	read!(s, frame)
	[...]
end
close(s)
```

Some formatted streams are seekable:

```julia
s = streamf("trajectory.trr")
seek(s, 500)
seekend(s)
```

Some have a known length:

```julia
n = length(s1)
```

Some allow replacing and/or appending values with `write`:

```julia
s1 = streamf("input.xtc")
s2 = streamf(openf("output.trr", "w"))
frame = MolecularModel()
while !eof(s1)
	read!(s1, frame)
	write(s2, frame)
end
close(s1)
close(s2)
```

And some can be truncated:

```julia
truncate(s, 5)
```

The `streamf` function supports `do` block syntax, automatically closing the
formatted stream upon completion:

```julia
streamf("trajectory.xtc") do s
	frame = MolecularModel()
	while !eof(s)
		read!(s, frame)
		[...]
	end
end
```

The convenience function `eachval` iterates over all values in a formatted
streamf:

```julia
s = streamf("trajectory.xtc")
for frame in eachval(s)
	[...]
end
```

The `eachval!` function iterates over a stream by reading into a pre-allocated
output buffer. Combined with a `do` block, it provides a compact and efficient
way to iterate over formatted objects:

```julia
streamf("trajectory.xtc") do s
	for frame in eachval!(s, MolecularModel())
		[...]
	end
end
```

Complete documentation is provided in `README.md`.
"""
FormatStreams

end # module
