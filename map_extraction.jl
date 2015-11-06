module NetworkTools

using LightGraphs

export Node, Road, Network, osm2network

include("definitions.jl")
include("osm2network.jl")

end
