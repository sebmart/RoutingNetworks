###################################################
## RoutingPaths type
###################################################

"""
    Stores path information in network
    - for now, just compute the shortest paths
    - if no_sp = true, returns an incomplete object (in case want to run shortest paths later)
"""
type RoutingPaths
    # Required attributes
    "A reference to the network"
    network::Network

    "road timing list: usually sparse matrix"
    times::AbstractArray{Float64,2}

    # optional attributes
    "if computed, contains timings from anywhere to anywhere"
    pathTimes::AbstractArray{Float64,2}
    "if computed, contains information to recontruct the paths"
    pathPrevious::AbstractArray{Int64,2}

    "Constructor: reference to network and timing information"
    function RoutingPaths(n::Network, times::AbstractArray{Float64,2}; no_sp=false)
        # a few tests
        if size(times) != (length(n.nodes),length(n.nodes))
            error("The given timings do not fit the network")
        end
        for (i,j) in keys(n.roads)
            if times[i,j] < 0.
                error("$i => $j : negative timing $(times[i,j])")
            end
        end
        obj = new()
        obj.network = n
        obj.times = times

        if !no_sp
            if nworkers() > 1
                parallelShortestPaths!(obj)
            else
                shortestPaths!(obj)
            end
        end
        return obj
    end
end

"""
    Without timings, uses distances
"""
RoutingPaths(n::Network) = RoutingPaths(n,roadDistances(n))


function Base.show(io::IO, r::RoutingPaths)
    g = r.network.graph
    println("Network routing times")
    if isdefined(r,:pathTimes)
        println(io, "with path and time for all $(nv(g)*(nv(g)-1)) possible trips")
    else
        println(io, "for all $(ne(g)) roads (no path computed yet)")
    end
end


"""
    Returns a RoutingTimes object where the "timings" are the distances
"""
function roadDistances(n::Network)
    dists = spzeros(length(n.nodes), length(n.nodes))
    for ((i,j),r) in n.roads
        dists[i,j] = r.distance
    end
    return dists
end

"""
    Gives access to the timing matrix of the graph after path computation
"""
function getPathTimes(r::RoutingPaths)
    if !isdefined(r,:pathTimes)
        error("The paths have not been computed yet")
    end
    return r.pathTimes
end


"""
    Returns path between origin and destination (list of node ids)
"""
function getPath(r::RoutingPaths, orig::Int, dest::Int)
    path = Int[dest]
    lastNode = dest
    while lastNode != orig
        lastNode = r.pathPrevious[orig,lastNode]
        push!(path, lastNode)
    end
    return path[end:-1:1]
end

"""
    Returns the given path time (just sum the link times on path)
"""
function pathTime(r::RoutingPaths, path::Vector{Int})
    time = 0.
    for i in 1:length(path) - 1
        time+=r.times[path[i],path[i+1]]
    end
    return time
end
