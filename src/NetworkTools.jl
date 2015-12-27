module NetworkTools

using LightGraphs, SFML, NearestNeighbors, JLD
import OpenStreetMapParser

export Node, Road, Network

export osm2network, subsetNetwork, removeNodes, singleNodes, inPolygon, roadTypeSubset
export stronglyConnected, intersections, queryFromCoordinates
export loadTemplate, saveTemplate, createTemplates
export squareNetwork, centralizedNetwork

export visualize


include("network.jl")


include("creation/osm2network.jl")
include("creation/query.jl")
include("creation/reduceNetwork.jl")
include("creation/templates.jl")
include("creation/square.jl")
include("creation/centralized.jl")

include("visualization/visualize.jl")

include("tools/geometry.jl")
end
