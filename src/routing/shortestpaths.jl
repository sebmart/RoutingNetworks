###################################################
## Use timings to compute shortest paths
###################################################

"""
    Compute shortest path using the given timings
"""
function shortestPaths!(r::RoutingTimes)
    g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    fullTimes = zeros(nv(g), nv(g))
    parents  = zeros(Int,nv(g),nv(g))

    for orig in 1:nv(g)
        d = dijkstra_shortest_paths(g, orig, r.times)
        fullTimes[orig,:] = d.dists
        parents[orig,:] = d.parents
    end
    r.fullTimes=fullTimes
    r.previousNode=parents
    return r
end

"""
    Compute shortest path using the given timings
    --parallel version, uses all available processors by default
"""
function parallelShortestPaths!(r::RoutingTimes)

    if length(workers()) <= 1
        println("Only one thread: use shortestPaths! instead")
    end

    @everywhere using LightGraphs


    @everywhere g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    #creating the workers

    fullTimes = SharedArray(Float64, (nv(g), nv(g)))
    parents  = SharedArray(Int,(nv(g),nv(g)))

     @sync @parallel for orig in 1:nv(g)
        d = dijkstra_shortest_paths(g, orig, r.times)
        fullTimes[orig,:] = d.dists
        parents[orig,:] = d.parents
    end
    rmpro
    r.fullTimes=fullTimes
    r.previousNode=parents
    return r
end
