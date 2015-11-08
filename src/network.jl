immutable Node
  lon::Float64
  lat::Float64
end

immutable Road
  # Distance in meters
  distance::Float64
  roadType::Int
end

type Network
  graph::DiGraph
  nodes::Vector{Node}
  roads::Dict{Tuple{Int,Int},Road}
end

function Network(nodes::Vector{Node}, roads::Dict{Tuple{Int,Int},Road})
    g = DiGraph(length(nodes))
    for (s,d) in keys(roads)
        add_edge!(g,s,d)
    end
    return Network(g,nodes,roads)
end

function Base.show(io::IO, n::Network)
    println("Network with $(nv(n.graph)) nodes and $(ne(n.graph)) edges")
end
