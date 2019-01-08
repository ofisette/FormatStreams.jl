struct StreamerRegistry
	streamers::Dict{MIME,Vector{FormatHandler}}
	favorites::Dict{MIME,FormatHandler}
	global_favorites::Vector{FormatHandler}
end

StreamerRegistry() = StreamerRegistry(
		Dict{MIME,Vector{FormatHandler}}(),
		Dict{MIME,FormatHandler}(),
		Vector{FormatHandler}())

Base.copy(registry::StreamerRegistry) = StreamerRegistry(
		copy(registry.streamers),
		copy(registry.favorites),
		copy(registry.global_favorites))

function Base.empty!(registry::StreamerRegistry)
	empty!(registry.streamers)
	empty!(registry.favorites)
	empty!(registry.global_favorites)
end

function Base.merge!(registry::StreamerRegistry, other::StreamerRegistry)
	merge!(registry.streamers, other.streamers)
	merge!(registry.favorites, other.favorites)
	append!(registry.global_favorites, other.global_favorites)
end

const registry = StreamerRegistry()

function newregistry(f::Function)
	tmp_registry = copy(registry)
	empty!(registry)
	f()
	merge!(registry, tmp_registry)
end

"""
	addstreamer(format::AbstractString, streamer::FormatHandler)

Register a `streamer` for the specified `format`.

# Example

```julia
struct MyIO <: Formats.FormatHandler end
Formats.addstreamer("image/png", MyIO())
```
"""
function addstreamer(format::AbstractString, streamer::FormatHandler)
	mime = MIME{Symbol(format)}()
	streamers = get!(registry.streamers, mime, [])
	if streamer in streamers
		error("streamer $(streamer) already registered for $(format)")
	else
		push!(streamers, streamer)
	end
	if length(streamers) > 1
		@info("$(format) has multiple registered streamers")
	end
end

"""
	preferstreamer(streamer::FormatHandler, [format::AbstractString])

Register `streamer` as the preferred alternative for the specified `format`.

If `format` is omitted, `streamer` becomes a globally preferred alternative: it
is used for all the formats it can stream.
```
"""
function preferstreamer(streamer::FormatHandler)
	if streamer in registry.global_favorites
		error("streamer $(streamer) is already globally preferred")
	end
	push!(registry.global_favorites, streamer)
end

function preferstreamer(streamer::FormatHandler, format::AbstractString)
	mime = MIME{Symbol(format)}()
	streamers = get(registry.streamers, mime, [])
	if ! (streamer in streamers)
		error("streamer $(streamer) is not registered for $(format)")
	end
	if haskey(registry.favorites, mime)
		@warn("replacing preferred streamer for $(format)")
	end
	registry.favorites[mime] = streamer
end

resolvestreamer(mime::MIME) =
		Formats.resolvehandler(mime, "streamer", registry.streamers,
		registry.favorites, registry.global_favorites)
