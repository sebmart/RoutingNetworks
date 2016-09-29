###################################################
## routingviz.jl
## network and routing visualizer
###################################################

"""
    `RoutingViz`: Network visualizer that also shows routing information.
    If `P` is clicked, enters path visualization mode.

"""
type RoutingViz <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    colors::VizColors


    "basic visualizer"
    networkviz::NetworkViz
    "the routing information"
    routing::RoutingPaths
    "if path-mode is on"
    pathMode::Bool
    "path is frozen"
    pathFrozen::Bool
    "destination node (path destination)"
    destNode::Int
    "the path to show"
    pathRoads::Vector{Edge}

    "contructor"
    function RoutingViz(r::RoutingPaths)
        obj = new()
        obj.network  = r.network
        obj.routing = r
        obj.colors = SpeedColors(r)

        obj.networkviz = NetworkViz(r.network; colors=obj.colors)
        return obj
    end
end

function visualInit(v::RoutingViz)
    #give visuals to nodeinfo
    copyVisualData(v,v.networkviz)

    v.pathMode = false
    v.pathFrozen = false
    v.pathRoads = []
    v.destNode = 1
end

function visualStartUpdate(v::RoutingViz,frameTime::Float64)
    if v.pathMode && !v.pathFrozen
        mouseCoord = pixel2coords(v.window, get_mousepos(v.window))
        nodeId = knn(v.networkviz.tree,[Float64(mouseCoord.x),-Float64(mouseCoord.y)],1)[1][1]

        if nodeId != v.destNode
            if v.destNode != v.networkviz.selectedNode
                # normal color to previous node
                set_fillcolor(v.nodes[v.destNode], nodeColor(v.colors, v.network.nodes[v.destNode]))
                # red for new node
                set_fillcolor(v.nodes[nodeId], SFML.red)
            end
            v.destNode = nodeId
            set_title(v.window, string("Routing path: ", v.networkviz.selectedNode, " => ", v.destNode))
            resetPath(v)
            highlightPath(v)
        end
    end
end

function visualScale(v::RoutingViz)
    # redraw the path
    highlightPath(v)
end


function visualEvent(v::RoutingViz, event::Event)
    if get_type(event) == EventType.KEY_PRESSED && get_key(event).key_code == KeyCode.P
        if v.pathMode
            v.pathMode = false
            set_title(v.window, "")
            resetPath(v)
            # normal color to previous node
            set_fillcolor(v.nodes[v.destNode], nodeColor(v.colors, v.network.nodes[v.destNode]))
        else
            v.pathMode = true
            v.pathFrozen = false
            v.destNode = v.networkviz.selectedNode
            v.pathRoads = []
        end
    elseif v.pathMode
        if get_type(event) == EventType.MOUSE_BUTTON_PRESSED && get_mousebutton(event).button == MouseButton.LEFT
            v.pathFrozen = !v.pathFrozen
        end
    else
        visualEvent(v.networkviz,event)
    end
end

"""
    `resetPath` reset the previous path
"""
function resetPath(v::RoutingViz)
    for (o,d) in v.pathRoads
        set_thickness(v.roads[o,d], get_thickness(v.roads[o,d])/4.)
        set_fillcolor(v.roads[o,d], roadColor(v.colors, v.network.roads[o,d]))
    end
    v.pathRoads = []
end

"""
`highlightPath` colors the current path
"""
function highlightPath(v::RoutingViz)
    # first compute new path
    v.pathRoads = getPathEdges(v.routing, v.networkviz.selectedNode, v.destNode)
    for (o,d) in v.pathRoads
        set_thickness(v.roads[o,d], get_thickness(v.roads[o,d])*4)
        set_fillcolor(v.roads[o,d], SFML.Color(0,0,255))
    end
end
