module NetworkTools

using LightGraphs, SFML, NearestNeighbors, JLD
import OpenStreetMapParser

export Node, Road, Network

export osm2network, subsetNetwork, removeNodes, singleNodes, inPolygon, roadTypeSubset
export stronglyConnected, intersections, queryFromCoordinates
export loadTemplate, saveTemplate, createTemplates

export visualize


include("network.jl")


include("creation/osm2network.jl")
include("creation/fromCoordinates")
include("creation/reduceNetwork.jl")

include("visualization/visualize.jl")
end
