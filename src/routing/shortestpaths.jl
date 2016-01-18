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
- parallel version, uses all available processors
- if batch_number is provided, use pmap method
"""
function parallelShortestPaths!(r::RoutingTimes; batch_number::Int=0)
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

    fullTimes = SharedArray(Float64, (nv(g), nv(g)))
    parents  = SharedArray(Int,(nv(g),nv(g)))

    @sync @parallel for orig in 1:nv(g)
        d = dijkstra_shortest_paths(g, orig, r.times)
        fullTimes[orig,:] = d.dists
        parents[orig,:] = d.parents
    end
    r.fullTimes=fullTimes
    r.previousNode=parents
    return r
end


"""
 another version, using pmap after grouping : usualy slower for now
"""
function parallelShortestPaths2!(r::RoutingTimes, batch_number::Int=10)

    if nworkers() <= 1
        println("Only one thread: use shortestPaths! instead")
    end
    g = r.network.graph
    if !is_strongly_connected(g)
        error("The network needs to be strongly connected")
    end

    fullTimes = SharedArray(Float64, (nv(g), nv(g)))
    parents  = SharedArray(Int,(nv(g),nv(g)))

    @sync for w in workers()
        @spawnat(w, eval(Main, Expr(:(=), :r, r)))
    end

    function range_dijkstra(range)
        for orig in range
            d = dijkstra_shortest_paths(r.network.graph, orig, r.times)
            fullTimes[orig,:] = d.dists
            parents[orig,:] = d.parents
        end
    end
    steps = round(Int,linspace(1,nv(g), batch_number+1))
    ranges = [steps[i]:steps[i+1] for i in 1:(length(steps)-1)]

    pmap(range_dijkstra, ranges)

    r.fullTimes=fullTimes
    r.previousNode=parents
    return r
end
