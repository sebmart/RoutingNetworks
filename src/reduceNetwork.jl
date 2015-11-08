"""
subset the network: only keep the given nodes
"""
function subsetNetwork(n::Network, keepN::Vector{Int})
    nodesIndices = Dict{Int,Int}()
    roads = Dict{Tuple{Int,Int},Road}()
    nodes = Array{Node}(length(keepN))

    for (k,i) in enumerate(keepN)
        nodes[k] = n.nodes[i]
        nodesIndices[i] = k
    end

    g = DiGraph(length(nodes))
    for (s,d) in keys(n.roads)
        if haskey(nodesIndices,s) && haskey(nodesIndices,d)
            add_edge!(g,nodesIndices[s],nodesIndices[d])
            roads[nodesIndices[s],nodesIndices[d]] = n.roads[s,d]
        end
    end
    return Network(g,nodes,roads)
end


"""
Remove nodes from network
"""
function removeNodes(n::Network, rem::Vector{Int})
    keep = ones(Bool, length(n.nodes))
    for i in rem
        keep[i] = false
    end
    keepN = collect(1:length(n.nodes))[keep]
    return subsetNetwork(n,keepN)
end


"""
Extract single nodes from network
"""
function singleNodes(n::Network)
    singles = Int[]
    for i in vertices(n.graph)
        if degree(n.graph,i) == 0
            push!(singles, i)
        end
    end
    return singles
end

"""
Return strongly-connected graph with
"""
function stronglyConnected(n::Network)
    c = strongly_connected_components(n.graph)
    indices =  c[indmax(Int[length(i) for i in c])]
    return subsetNetwork(n,indices)
end


"""
Returns nodes that are inside a Polygon
"""
function inPolygon(n::Network, poly::Vector{Tuple{Float64,Float64}})
    inPoly = Int[]
    for i in vertices(n.graph)
        if point_inside_polygon(n.nodes[i].lat, n.nodes[i].lon, poly)
            push!(inPoly,i)
        end
    end
    return inPoly
end

"""
Only keep roads that are of some types
"""
function roadTypeSubset(n::Network, roadTypes::AbstractArray{Int})
    keep = Bool[(i in roadTypes) for i in 1:8]
    roads = Dict{Tuple{Int,Int},Road}()
    g = DiGraph(length(n.nodes))

    for (o,d) in keys(n.roads)
        if keep[n.roads[o,d].roadType]
            roads[o,d] = n.roads[o,d]
            add_edge!(g,o,d)
        end
    end
    return Network(g,deepcopy(n.nodes), roads)
end

function point_inside_polygon(x::Float64,y::Float64,poly::Vector{Tuple{Float64,Float64}})
  n = length(poly)
  inside =false

  p1x,p1y = poly[1]
  for i in 0:n
    p2x,p2y = poly[i % n + 1]
    if y > min(p1y,p2y)
      if y <= max(p1y,p2y)
        if x <= max(p1x,p2x)
          if p1y != p2y
            xinters = (y-p1y)*(p2x-p1x)/(p2y-p1y)+p1x
          end
          if p1x == p2x || x <= xinters
            inside = !inside
          end
        end
      end
    end
    p1x,p1y = p2x,p2y
  end
  return inside
end
