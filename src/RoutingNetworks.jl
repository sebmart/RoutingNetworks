__precompile__()

module RoutingNetworks

using LightGraphs, SFML, NearestNeighbors
import JLD, LibExpat

#main
export Node, Road, Network

#creation
export osm2network, subsetNetwork, removeNodes, singleNodes, inPolygon, roadTypeSubset
export stronglyConnected, intersections, queryOsmBox, queryOsmPolygon, updateProjection!
export loadTemplate, saveTemplate, isTemplate
export rectNetwork, squareNetwork, urbanNetwork

#routing
export RoutingPaths, roadDistances, getPathTimes, getPath, shortestPaths!, pathTime
export parallelShortestPaths!, pathRoads

#visualization
export NetworkVisualizer, NodeInfo, ShowPath
export visualize, visualInit, visualEvent, visualUpdate, copyVisualData

#tools
export boundingBox, distanceGeo, distanceCoord, pointInsidePolygon

include("network.jl")


include("tools/geometry.jl")
include("tools/geodesy.jl")
include("tools/osmparser.jl")

include("creation/osm2network.jl")
include("creation/query.jl")
include("creation/subsets.jl")
include("creation/templates.jl")
include("creation/rect.jl")
include("creation/urban.jl")

include("routing/routingpaths.jl")
include("routing/shortestpaths.jl")
include("routing/tools.jl")

include("visualization/visualize.jl")
include("visualization/nodeinfo.jl")
include("visualization/showpath.jl")

end
