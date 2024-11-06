using Distributed

###################################################
## Use timings to compute shortest paths
###################################################

"""
Compute shortest path using the given timings
"""
function shortestPaths!(r::RoutingPaths)
    g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    pathTimes = zeros(nv(g), nv(g))
    parents  = zeros(Int,nv(g),nv(g))

    for orig in 1:nv(g)
        d = dijkstra_shortest_paths(g, orig, r.times)
        pathTimes[orig,:] = d.dists
        parents[orig,:] = d.parents
    end
    r.pathTimes=pathTimes
    r.pathPrevious=parents
    return r
end

"""
Compute shortest path using the given timings
- parallel version, uses all available processors
- if batch_number is provided, use pmap method
"""
function parallelShortestPaths!(r::RoutingPaths; batch_number::Int=0)
    if batch_number > 0
        return parallelShortestPaths2(r,batch_number)
    end

    if nprocs() <= 1
        println("Only one thread: use shortestPaths! instead")
    end


    g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    pathTimes = SharedArray(Float64, (nv(g), nv(g)))
    parents  = SharedArray(Int,(nv(g),nv(g)))

    @sync @distributed for orig in 1:nv(g)
        d = dijkstra_shortest_paths(g, orig, r.times)
        pathTimes[orig,:] = d.dists
        parents[orig,:] = d.parents
    end
    r.pathTimes=pathTimes
    r.pathPrevious=parents
    return r
end


"""
 another version, using pmap after grouping : usualy slower for now
"""
function parallelShortestPaths2!(r::RoutingPaths, batch_number::Int=10)

    if nworkers() <= 1
        println("Only one thread: use shortestPaths! instead")
    end
    g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    pathTimes = SharedArray(Float64, (nv(g), nv(g)))
    parents  = SharedArray(Int,(nv(g),nv(g)))

    @sync for w in workers()
        @spawnat(w, eval(Main, Expr(:(=), :r, r)))
    end

    function range_dijkstra(range)
        for orig in range
            d = dijkstra_shortest_paths(r.network.graph, orig, r.times)
            pathTimes[orig,:] = d.dists
            parents[orig,:] = d.parents
        end
    end
    steps = round(Int,linspace(1,nv(g), batch_number+1))
    ranges = [steps[i]:steps[i+1] for i in 1:(length(steps)-1)]

    pmap(range_dijkstra, ranges)

    r.pathTimes=sdata(pathTimes)
    r.pathPrevious=sdata(parents)
    return r
end

"""
    walking time between i and j, doesn't use routing paths,
    applies dijkstra to undirected version of graph
"""
function walkingtime(n::Network, i::Int, j::Int,
                     times::AbstractArray{Float64,2} = walkingDistances(n))
    d = dijkstra_shortest_paths(Graph(n.graph), i, times)
    return d.dists[j]
end

"""
    returns nodes that are within provided walkingTime of node i, along 
    with all walking times computed by dijkstra
    doesn't use routing paths and applies dijkstra to undirected version of graph
"""
function walkingNodes(n::Network, i::Int, walkingTime::Float64,
                      times::AbstractArray{Float64,2} = walkingDistances(n))
    d = dijkstra_shortest_paths(Graph(n.graph), i, times)
    nodes = find(d.dists .< walkingTime)
    return nodes, d.dists[nodes]
end


"""
    Using Dijkstra, returns the all pair shortest path for a subset of the nodes as
    origins and destinations
"""
function allPairTimes(n::Network, origins::Vector{Int}, dests::Vector{Int}, times::AbstractArray{Float64, 2})
    result = Matrix{Float64}(length(origins), length(dests))
    for (i,o) in enumerate(origins)
        d = dijkstra_shortest_paths(n.graph, o, times)
        result[i,:] = d.dists[dests]
    end
    return result
end
