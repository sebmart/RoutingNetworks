###################################################
## showpath.jl
## network visualizer - show a given path
## also add nodeInfo
###################################################

"""
    `ShowPath`: Network visualizer that shows a given path. Also adds NodeInfo
"""
type ShowPath <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    nodesToView::Vector{Node}


    "path to show"
    path::Vector{Int}
    "node information"
    nodeinfo::NodeInfo

    "contructor"
    function ShowPath(n::Network, path::Vector{Int})
        obj = new()
        obj.network  = n
        obj.path     = path
        obj.nodeinfo = NodeInfo(n)
        obj.nodesToView = n.nodes[path]
        return obj
    end
end

function visualInit(v::ShowPath)
    #give visuals to nodeinfo
    copyVisualData(v,v.nodeinfo)
    #Change the path
    for r in pathRoads(v.network,v.path)
        line = v.roads[r.orig,r.dest]
        set_fillcolor(line,Color(255,0,0))
        set_thickness(line, get_thickness(line)*2)
    end
end

function visualScale(v::ShowPath)
    # change the path
    for r in pathRoads(v.network, v.path)
        line = v.roads[r.orig, r.dest]
        set_thickness(line, get_thickness(line)*2)
    end
end

function visualEndUpdate(v::ShowPath, frameTime::Float64)
    for road in pathRoads(v.network, v.path)
        line = v.roads[road.orig, road.dest]
        draw(v.window,line)
    end
end

visualEvent(v::ShowPath, event::Event) = visualEvent(v.nodeinfo,event)
