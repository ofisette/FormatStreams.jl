# FormatStreams

Julia package to read, write and detect streams of formatted data.

The `FormatStreams` module provides the `streamf` function to wrap files and IO
streams that contain sequences of formatted objects. `streamf` returns a
`FormattedStream` object that can be used with the standard IO functions, such
as `read`, `write`, `seek` or `close`. This makes it easy to read/write
sequences of objects according to MIME types. `FormatStreams` extends `Formats`
and will automatically detect file formats/codings. Convenience functions are
also provided to iterate over the contents of formatted streams.

## License

You can use Formats under the terms of the MIT “Expat” License; see
`LICENSE.md`.

## Installation

FormatStreams is not a registered package. You can add it to your Julia
environment by giving the URL to its repository:

```julia
Pkg.add("https:://github.com/ofisette/FormatStreams.jl")
```

## Documentation

This documentation gives an overview of the types and functions that form
FormatStreams’s public interface. For details, refer to the documentation of
individual functions and types, available in the REPL. The *basic usage* section
of the documentation is also accessible from the REPL:

```julia
?FormatStreams
```

FormatStreams provides a basic framework to manage streams of formatted objects.
However, FormatStreams itself does not define any specific format or function to
read or write objects in specific formats. All examples below rely on Dorothy
for reading/writing TRR and XTC molecular trajectories.

### Basic usage

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

### Streaming formatted data

`FormatStreams` provides `streamf` as the single way to open a stream of
formatted objects. `streamf` operates on filenames, IO streams and `Formatted`
objects (usually created with the `guess` and `specify` functions from the
`Formats` package).

Objects returned by `streamf` specialize the `FormattedStream` abstract type.
These always support basic IO functions `position`, `eof`, `seekstart` and
`close`. In addition, they usually support `read`, and may also support `read!`,
`seek`, `seekend`, `length`, `write` or `truncate`.

### Iterating over formatted streams

Convenience functions `eachval` and `eachval!` provide an easy way to wrap
formatted streams and treat them as iterators.

### Implementing formatted streams

To integrate your own packages with `FormatStreams`, you first need to define
the formats you wish to support, register them, and define a singleton type to
identify your IO streamer. See the documentation of `Formats` for details.

You should then register your streamer using `addstreamer` (not exported by
default). Finally, you must specialize `streamf`; the specific signature is
documented. The object you return from `streamf` should specialize
`FormattedStream` and support the IO functions listed above.

### Registration inside a module must happen at initialization time

Calls to `addstreamer` should take place in your package’s `__init__` function
since they modify a global variable. See the documentation of `Formats` for a
more detailed explanation.

### Selecting a specific streamer

When multiple streamers are available for a given format, a specific streamer
can be selected, either for a single format or on a global basis. This is
done via `preferstreamer` (not exported by default).

## See also

* [Formats](https://github.com/ofisette/Formats.jl):
  Read, write and detect formatted data, based on MIME types (dependency).
