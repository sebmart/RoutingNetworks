module RoutingNetworks

using LightGraphs, SFML, NearestNeighbors
import OpenStreetMapParser, Geodesy, JLD

#main
export Node, Road, Network

#creation
export osm2network, subsetNetwork, removeNodes, singleNodes, inPolygon, roadTypeSubset
export stronglyConnected, intersections, queryOsmBox, queryOsmPolygon
export loadTemplate, saveTemplate, isTemplate
export squareNetwork, urbanNetwork

#routing
export RoutingPaths, roadDistances, getPathTimes, getPath, shortestPaths!
export parallelShortestPaths!

#visualization
export NetworkVisualizer, NodeInfo, visualize, visualInit, visualEvent, visualUpdate
export copyVisualData


include("network.jl")


include("creation/osm2network.jl")
include("creation/query.jl")
include("creation/subsets.jl")
include("creation/templates.jl")
include("creation/square.jl")
include("creation/urban.jl")

include("routing/routingpaths.jl")
include("routing/shortestpaths.jl")

include("visualization/visualize.jl")
include("visualization/nodeinfo.jl")

include("tools/geometry.jl")
end
