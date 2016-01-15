###################################################
## Store timings in a network
###################################################

"""
    Stores timing information for a network
"""
type RoutingTimes
    # Required attributes
    "A reference to the network"
    network::Network

    "road timing list: usually sparse matrix"
    times::AbstractArray{Float64,2}

    # optional attributes
    "if computed, contains timings from anywhere to anywhere"
    fullTimes::AbstractArray{Float64,2}
    "if computed, contains information to recontruct the paths"
    previousNode::AbstractArray{Int64,2}

    "Constructor: reference to network and timing information"
    function RoutingTimes(n::Network, times::AbstractArray{Float64,2})
        obj = new()
        obj.network = n
        if size(times) != (length(n.nodes),length(n.nodes))
            error("The given timings do not fit the network")
        end
        obj.times = times
        for (i,j) in keys(n.roads)
            if obj.times[i,j] < 0.
                error("$i => $j : negative timing $(obj.times[i,j])")
            end
        end
        return obj
    end
end

function Base.show(io::IO, r::RoutingTimes)
    g = r.network.graph
    println("Network routing times")
    if isdefined(r,:fullTimes)
        println("with path and time for all $(nv(g)*(nv(g)-1)) possible trips")
    else
        println("for all $(ne(g)) roads (no path computed yet)")
    end
end


"""
    Returns a RoutingTimes object where the "timings" are the distances
"""
function routingDistances(n::Network)
    dists = spzeros(length(n.nodes), length(n.nodes))
    for ((i,j),r) in n.roads
        dists[i,j] = r.distance
    end
    return RoutingTimes(n,dists)
end

"""
    Gives access to the timing matrix of the graph after path computation
"""
function getRoutingTimes(r::RoutingTimes)
    if !isdefined(r,:fullTimes)
        error("The paths have not been computed yet")
    end
    return r.fullTimes
end


"""
    Returns path between origin and destination (list of node ids)
"""
function getPath(r::RoutingTimes, orig::Int, dest::Int)
    path = Int[dest]
    lastNode = dest
    while lastNode != orig
        lastNode = r.previousNode[orig,lastNode]
        push!(path, lastNode)
    end
    return path[end:-1:1]
end
