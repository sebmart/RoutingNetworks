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
