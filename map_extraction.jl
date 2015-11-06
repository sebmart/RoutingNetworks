using LightGraphs

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


include("osm2network.jl")
