###################################################
## network.jl
## the network basics
###################################################

"""
`Node`, represents one network node. `x` and `y` are projections of `lon` and `lat`
- `lon` and `lat` do not have to be defined
"""
immutable Node
    x::Float64
    y::Float64
    lon::Float32
    lat::Float32
end
Node(x::Float64,y::Float64) = Node(x,y,0.,0.)

"""
`Road`, represents a road in the network. roadType from 1 to 8
"""
immutable Road
    orig::Int
    dest::Int
    # Distance in meters
    distance::Float64
    roadType::Int
end

"""
`Network`, represents a routing network
"""
type Network
    "Graph of network"
    graph::DiGraph
    "Nodes information"
    nodes::Vector{Node}
    "Roads information"
    roads::Dict{Tuple{Int,Int},Road}
    "Center coordinates for ENU projection (only defined if used)"
    projcenter::Tuple{Float32,Float32}

    function Network(graph::DiGraph, nodes::Vector{Node}, roads::Dict{Tuple{Int,Int},Road})
        n = new()
        n.graph = graph; n.nodes = nodes; n.roads = roads;
    end
end

function Network(nodes::Vector{Node}, roads::Dict{Tuple{Int,Int},Road})
    g = DiGraph(length(nodes))
    for (s,d) in keys(roads)
        add_edge!(g,s,d)
    end
    return Network(g,nodes,roads)
end

function Base.show(io::IO, n::Network)
    println("Network with $(nNodes(n)) nodes and $(nRoads(n)) edges")
end

"""
`nRoads`: returns number of roads in network (in both directions)
"""
nRoads(n::Network) = ne(n.graph)
"""
`nNodes`: returns number of nodes in network
"""
nNodes(n::Network) = nv(n.graph)
