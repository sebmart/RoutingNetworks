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
        d = dijkstra_shortest_paths(g,i, distmx=r.times)
        fullTimes[i,:] = d.dists
        parents[i,:] = d.parents        
    end

end
