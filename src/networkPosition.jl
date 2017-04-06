###################################################
## networkposition.jl
##     Location information with respect to the network (projection onto the network...)
## Authors: Sébastien Martin, 2017
###################################################
"""
    KD-tree wrapper to project real locations onto network
"""
immutable NetworkProjector
    "The routing network"
    network::Network
    "The KD-tree of nodes"
    tree::KDTree
end
function NetworkProjector(n::Network)
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
nearestNode(proj::NetworkProjector, x, y) = knn(proj.tree,[x,y],1)[1][1]


"""
    A type representing a position in the network
"""
immutable NetworkPosition
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

"""
    Returns the Network Position, given latitude and longitude
"""
function NetworkPosition(proj::NetworkProjector, lat, lon)
    x, y = toENU(lon, lat, proj.network)
    return NetworkPosition(lat, lon, x, y, nearestNode(proj, x, y))
end
