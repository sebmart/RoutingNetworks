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
distToProj(n::Network, pos::NetworkPosition) = error("The `distToProj` function has not been written for this NetworkPosition")

distanceGeo(p1::NetworkPosition, p2::NetworkPosition) =
    distanceGeo(lon(p1), lat(p1), lon(p2), lat(p2))


"""
    A simple nearest-node projection to the network. Fast to compute.
"""
immutable NodePosition <: NetworkPosition
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

function distToProj(n::Network, pos::NodePosition)
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
    return NodeProjector(n,KDTree(nodePos))
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
    return NodePosition(lat, lon, x, y, nearestNode(proj, x, y))
end

"""
    A more advanced projection to the network. project on a road and give position on this road.
"""
immutable RoadPosition <: NetworkPosition
    "Latitude"
    lat::Float64
    "Longitude"
    lon::Float64
    "x position (planar representation)"
    x::Float64
    "y position (planar representation)"
    y::Float64
    "node id of the origin of the road"
    nodeO::Int
    "node id of the destination of the road"
    nodeD::Int
    "fraction representing the position in between the node. 0=nodeO, 1.=nodeD"
    fraction::Float64
end

function node(pos::RoadPosition)
    if pos.fraction <=0.5
        return nodeO
    else
        return nodeD
    end
end
"""
    Each road is discretized into regularly spaced sub-nodes, used by the RoadProjector
"""
immutable RoadSubNode
    "Origin node id"
    nodeO::Int
    "Destination node id"
    nodeD::Int
    "x position"
    x::Float64
    "y position"
    y::Float64
end

"""
    More fancy projector, that project onto the exact nearest road.
"""
immutable RoadProjector
    "The routing network"
    network::Network
    "The KD-tree for all RoadSubNodes"
    tree::KDTree
    "The list of all subnodes"
    subnodes::Vector{RoadSubNode}
    "The discretization parameter, in meters: the max distance between 2 subnodes of same road"
    maxDistance::Float64
end

function RoadProjector(n::Network; maxDistance::Float64=50.)
    # Creating the subnodes.
    subnodes = RoadSubNode[]
    uniqueArcs = Set{Tuple{Int, Int}}()
    for r in values(n.roads)
        od = minmax(r.orig, r.dest)
        if !(od in uniqueArcs)
            push!(uniqueArcs, od)
            nSubNodes = ceil(Int, r.distance/maxDistance)+1
            nodeO = n.nodes[r.orig]
            nodeD = n.nodes[r.dest]
            for i = 1:nSubNodes
                frac = (i-1)/(nSubNodes-1)
                x = nodeO.x + frac*(nodeD.x-nodeO.x)
                y = nodeO.y + frac*(nodeD.y-nodeO.y)
                push!(subnodes, RoadSubNode(r.orig, r.dest, x, y))
            end
        end
    end
    # Constructing tree
    nodePos = Array(Float64,(2,length(subnodes)))
    for (i,subnode) in enumerate(subnodes)
       nodePos[1,i] = subnode.x
       nodePos[2,i] = subnode.y
    end
    return RoadProjector(n,KDTree(nodePos), subnodes, maxDistance)
end

"""
    Returns the Network Position, given latitude and longitude
    Use the subnodes to project on the road quickly.
"""
function NetworkPosition(proj::RoadProjector, lat, lon)
    x, y = toENU(lon, lat, proj.network)
    id, dist = knn(proj.tree,[x,y],1)
    closestSubNode = proj.subnodes[id[1]]

    candidateSubNodes = inrange(proj.tree, [closestSubNode.x, closestSubNode.y], dist[1] + proj.maxDistance)
    candidateRoads = Tuple{Int, Int}[] # using a vector as very small sets are inefficient
    for subNodeId in candidateSubNodes
        subnode = proj.subnodes[subNodeId]
        od = (subnode.nodeO, subnode.nodeD)
        if !(od in candidateRoads)
            push!(candidateRoads, od)
        end
    end
    length(candidateRoads) > 0 || error("Something is wrong here.")
    bestOD = (0, 0)
    bestFrac = -1.
    bestDist = Inf
    otherSide = false
    for od in candidateRoads
        dist, frac, side = roadProjection(proj.network.nodes[od[1]], proj.network.nodes[od[2]], x, y)
        if dist < bestDist
            bestOD = od
            bestFrac = frac
            bestDist = dist
            otherSide = side
        end
    end
    (o,d) = bestOD
    if otherSide && haskey(proj.network.roads, (d,o)) # Select the road direction
        bestFrac = 1.-bestFrac
        (o,d) = (d,o)
    end

    return RoadPosition(lat, lon, x, y, o, d, bestFrac)
end

"""
    Project a position onto a road segment.
"""
function roadProjection(nO::Node, nD::Node, x::Float64, y::Float64)
    O = Float64[nO.x, nO.y]
    D = Float64[nD.x, nD.y]
    p = Float64[x,y]

    OD = D - O
    ODsquared = dot(OD,OD)
    ODsquared == 0. && error("origin and destination are the same")

    Op = p - O
    # from http://stackoverflow.com/questions/849211/
    # Consider the line extending the segment, parameterized as O + frac (D - O)
    # We find projection of point p onto the line.
    # It falls where frac = [(p-O) . (D-O)] / |D-O|^2\
    frac = dot(Op,OD)/ODsquared

    if (frac < 0.0)
        frac = 0.
    elseif (frac > 1.0)
        frac = 1.
    end

    proj = O + frac * OD

    rotOD = [-OD[2], OD[1]] # rotate 90 degrees counter-clockwise
    otherSide = dot(rotOD, p-proj) > 0 # test the side of the street
    dist = norm(p-proj)

    return dist, frac, otherSide
end

function distToProj(n::Network, pos::RoadPosition)
    nO = n.nodes[pos.nodeO]
    nD = n.nodes[pos.nodeD]
    projlat = nO.lat + pos.fraction*(nD.x-nO.x)
    projlon = nO.lon + pos.fraction*(nD.y-nO.y)
    return distanceGeo(projlon, projlat, pos.lon, pos.lat)
end
