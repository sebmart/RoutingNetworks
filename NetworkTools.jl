module NetworkTools

using LightGraphs
import OpenStreetMapParser

export Node, Road, Network, osm2network

include("src/definitions.jl")
include("src/osm2network.jl")

end
