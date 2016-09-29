###################################################
## routingviz.jl
## network visualizer - show a given path
## also add nodeInfo
###################################################

"""
    `RoutingViz`: Network visualizer that shows a given path. Also adds NodeInfo
"""
type RoutingViz <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    colors::VizColors
    nodesToView::Vector{Node}


    "path to show"
    path::Vector{Int}
    "basic visualizer"
    nodeinfo::NetworkViz

    "contructor"
    function RoutingViz(n::Network, path::Vector{Int})
        obj = new()
        obj.network  = n
        obj.path     = path
        obj.nodeinfo = NodeInfo(n)
        obj.nodesToView = n.nodes[path]
        return obj
    end
end

function visualInit(v::RoutingViz)
    #give visuals to nodeinfo
    copyVisualData(v,v.nodeinfo)
    #Change the path
    for r in pathRoads(v.network,v.path)
        line = v.roads[r.orig,r.dest]
        set_fillcolor(line,Color(255,0,0))
        set_thickness(line, get_thickness(line)*2)
    end
end

function visualScale(v::RoutingViz)
    # change the path
    for r in pathRoads(v.network, v.path)
        line = v.roads[r.orig, r.dest]
        set_thickness(line, get_thickness(line)*2)
    end
end

function visualEndUpdate(v::RoutingViz, frameTime::Float64)
    for road in pathRoads(v.network, v.path)
        line = v.roads[road.orig, road.dest]
        draw(v.window,line)
    end
end

visualEvent(v::RoutingViz, event::Event) = visualEvent(v.nodeinfo,event)
