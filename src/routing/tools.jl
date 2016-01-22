###################################################
## tools.jl
## path tool functions
###################################################

"""
    `pathRoads`: get a list of roads for a list of path nodes id
"""
function pathRoads(n::Network,p::Vector{Int})
    return [n.roads[p[i],p[i+1]] for i in 1:length(p)-1]
end
