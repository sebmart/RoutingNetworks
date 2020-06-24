###################################################
## Tools to subset networks
###################################################

"""
subset the network: only keep the given nodes
"""
function subsetNetwork(n::Network, keepN::Vector{Int})
    nodesIndices = Dict{Int,Int}()
    roads = Dict{Tuple{Int,Int},Road}()
    nodes = Array{Node}(undef, length(keepN))

    for (k,i) in enumerate(keepN)
        nodes[k] = n.nodes[i]
        nodesIndices[i] = k
    end

    g = DiGraph(length(nodes))
    for (s,d) in keys(n.roads)
        if haskey(nodesIndices,s) && haskey(nodesIndices,d)
            add_edge!(g,nodesIndices[s],nodesIndices[d])
            prevRoad = n.roads[s,d]
            roads[nodesIndices[s],nodesIndices[d]] = Road(nodesIndices[s], nodesIndices[d], prevRoad.distance, prevRoad.roadType)
        end
    end

    return updateProjection!(Network(g,nodes,roads))
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
    return subsetNetwork(n, keepN)
end


"""
Extract single nodes from network
"""
singleNodes(n::Network) = singleNodes(n.graph)
function singleNodes(g::DiGraph)
    singles = Int[]
    for i in vertices(g)
        if degree(g,i) == 0
            push!(singles, i)
        end
    end
    return singles
end

"""
Return strongly connected component starting from a node
"""
function stronglyConnected(n::Network, node::Int)
    indices  = singleNodes(bfs_tree(n.graph,node))
    indices2 = singleNodes(bfs_tree(LightGraphs.reverse(n.graph), node))
    return removeNodes(n,[indices;indices2])
end


"""
Returns nodes that are inside a Polygon
"""
function inPolygon(n::Network, poly::Vector{Tuple{T,T}}) where T<:AbstractFloat
    inPoly = Int[]
    for i in vertices(n.graph)
        if pointInsidePolygon(n.nodes[i].lon, n.nodes[i].lat, poly)
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
    n2 = Network(g,deepcopy(n.nodes), roads)
    n2.projcenter = n.projcenter
    return n2
end

"""
Only keep nodes that are intersections, suppose strong connectivity
"""
function intersections(n::Network)
    g = n.graph
    #################################
    # First pass: detect intersections nodes
    #################################
    nodes = Node[]
    index = Int[]
    revIndex = zeros(Int,nv(g))
    for i in vertices(n.graph)
        if length(all_neighbors(n.graph,i)) != 2 || indegree(n.graph,i) != outdegree(n.graph,i)
            push!(nodes,n.nodes[i])
            revIndex[i] = length(nodes)
            push!(index,i)
        end
    end

    #################################
    # second pass:  recreate graph
    #################################

    g2 = DiGraph(length(nodes))
    roads = Dict{Tuple{Int,Int},Road}()
    for i in vertices(g2)
        for j in outneighbors(g,index[i])
            dist = n.roads[index[i],j].distance
            roadType = n.roads[index[i],j].roadType
            k = j
            k2 = index[i]
            while revIndex[k] == 0
                next = outneighbors(g,k)[1]
                if next == k2
                    next = outneighbors(g,k)[2]
                end
                dist += n.roads[k,next].distance
                roadType = max(roadType, n.roads[k,next].roadType)
                k2 = k
                k = next
            end
            if i != revIndex[k]
                if has_edge(g2,i,revIndex[k])
                    dist = min(dist, roads[i,revIndex[k]].distance)
                    roadType = max(roadType, roads[i,revIndex[k]].roadType)
                else
                    add_edge!(g2, i, revIndex[k])
                end
                roads[i,revIndex[k]] = Road(i,revIndex[k],dist,roadType)
            end

        end
    end
    n2 = Network(g2,nodes,roads)
    updateProjection!(n2)
    return n2
end

"""
    Take a list of RoadPosition, and returns the list of nodes that are needed to
    drive/walk from any position to any other position.
"""
function connectingNodes(n::Network, positions::Vector{RoadPosition};
						 verbose::Bool = false)
    cartimes = maxSpeedTimes(n)
    dists = roadDistances(n)
    walktimes = max.(dists, dists')
    walkgraph = Graph(n.graph)
    allNodes = Set{Int}()
    for p in positions
        push!(allNodes, p.nodeO)
        push!(allNodes, p.nodeD)
    end
    allNodes = sort(collect(allNodes))

    seenNodes = Set{Int}()
    verbose && println("Computing shortest paths between $(length(allNodes)) nodes")
    for (i, origin) in enumerate(allNodes)
        verbose && print(i, "/", length(allNodes), "\r")
        union!(seenNodes, getConnectingNodes(n.graph, cartimes, origin, allNodes))
        union!(seenNodes, getConnectingNodes(walkgraph, walktimes, origin, allNodes))
    end
    return seenNodes
end

"""
    Take an origin node and a graph, with a set of destination nodes, and return all the
    nodes needed to take a shortest path.
"""
function getConnectingNodes(graph, times, origin, dests)
    dijkstraResult = dijkstra_shortest_paths(graph, origin, times)
    paths  = enumerate_paths(dijkstraResult, dests)
    nodes = Set{Int}()
    for p in paths
        union!(nodes, p)
    end
    return nodes
end
