###################################################
## network/tools.jl
## network tools
###################################################

"""
    `nRoad`: returns number of roads in network (in both directions)
"""
nRoads(n::Network) = ne(n.graph)
"""
    `nNodes`: returns number of nodes in network
"""
nNodes(n::Network) = nv(n.graph)
