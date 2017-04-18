###################################################
## networkposition.jl
##     Location information with respect to the network (projection onto the network...)
## Authors: Sébastien Martin, 2017
###################################################

"""
    Types that represent positions in the network, always contain.
"""
abstract NetworkPosition

" Returns the exact latitude of the position"
lat(pos::NetworkPosition) = pos.lat
" Returns the exact longitude of the position"
lon(pos::NetworkPosition) = pos.lon
" Returns the x position in the ENU coordinate system of the network"
x(pos::NetworkPosition) = pos.x
" Returns the y position in the ENU coordinate system of the network"
y(pos::NetworkPosition) = pos.y
" Return the id of the best node approximation of the position"
node(pos::NetworkPosition) = error("The `node` function has not been written for this NetworkPosition")
" Returns the distance from the node given by the `node` function"
distToNode(n::Network, pos::NetworkPosition) = error("The `distToNode` function has not been written for this NetworkPosition")

distanceGeo(p1::NetworkPosition, p2::NetworkPosition) =
    distanceGeo(lon(p1), lat(p1), lon(p2), lat(p2))


"""
    A simple nearest-node projection to the network. Fast to compute.
"""
immutable NodePosition
    "Latitude"
    lat::Float64
    "Longitude"
    lon::Float64
    "x position (planar representation)"
    x::Float64
    "y position (planar representation)"
    y::Float64
    "node id in the routing graph (0 if not computed)"
    node::Int
end

node(pos::NodePosition) = pos.node > 0 ? pos.node : error("Node not computed")

function distToNode(n::Network, pos::NodePosition)
    node = n.nodes[pos.node]
    distanceGeo(node.lon, node.lat, pos.lon, pos.lat)
end

"""
    KD-tree wrapper to project real locations onto network, (on nearest nodes only)
"""
immutable NodeProjector
    "The routing network"
    network::Network
    "The KD-tree of nodes"
    tree::KDTree
end
function NodeProjector(n::Network)
    # Constructing tree
    nodePos = Array(Float64,(2,length(n.nodes)))
    for (i,node) in enumerate(n.nodes)
       nodePos[1,i] = node.x
       nodePos[2,i] = node.y
    end
    return NetworkProjector(n,KDTree(nodePos))
end
"""
    Returns the nearest node id with respect to a x/y position
"""
nearestNode(proj::NodeProjector, x, y) = knn(proj.tree,[x,y],1)[1][1]

"""
    Returns the Network Position, given latitude and longitude
"""
function NetworkPosition(proj::NodeProjector, lat, lon)
    x, y = toENU(lon, lat, proj.network)
    return NodeProjector(lat, lon, x, y, nearestNode(proj, x, y))
end
