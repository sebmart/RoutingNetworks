###################################################
## routingviz.jl
## network and routing visualizer
###################################################

"""
    `RoutingViz`: Network visualizer that also shows routing information.
    If `P` is clicked, enters path visualization mode.
    The shortest path will be shown, starting from the selected node. click to fix the path.

"""
mutable struct RoutingViz <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    view::View
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
    path::Vector{Line}

    "contructor"
    function RoutingViz(r::RoutingPaths; colors::VizColors=RelativeSpeedColors(r))
        obj = new()
        obj.network  = r.network
        obj.routing = r
        obj.colors = colors

        obj.networkviz = NetworkViz(r.network; colors=colors)
        return obj
    end
end

function visualInit(v::RoutingViz)
    #give visuals to nodeinfo
    copyVisualData(v,v.networkviz)

    v.pathMode = false
    v.pathFrozen = false
    v.destNode = 1
end

function visualStartUpdate(v::RoutingViz,frameTime::Float64)
    if v.pathMode && !v.pathFrozen
        mouseCoord = pixel2coords(v.window, get_mousepos(v.window))
        nodeId = knn(v.networkviz.tree,[Float64(mouseCoord.x),-Float64(mouseCoord.y)],1)[1][1]

        if nodeId != v.destNode
            if v.destNode != v.networkviz.selectedNode
                # normal color to previous node
                sfCircleShape_setFillColor(v.nodes[v.destNode], nodeColor(v.colors, v.network.nodes[v.destNode]))
                # red for new node
                sfCircleShape_setFillColor(v.nodes[nodeId], sfColor_fromRGB(255, 0, 0))
            end
            v.destNode = nodeId
            set_title(v.window, string("Routing path: ", v.networkviz.selectedNode, " => ", v.destNode))
            drawPath(v)
        end
    end
end

function visualEndUpdate(v::RoutingViz, frameTime::Float64)
    if v.pathMode #print the path on top of other roads
        for segment in v.path
            draw(v.window, segment)
        end
    end
end

function visualRedraw(v::RoutingViz)
    visualRedraw(v.networkviz)
    if v.pathMode
        # redraw the path
        drawPath(v)
        sfCircleShape_setFillColor(v.nodes[v.destNode], sfColor_fromRGB(255, 0, 0))
    end
end


function visualEvent(v::RoutingViz, event::Event)
    if get_type(event) == EventType.KEY_PRESSED && get_key(event).key_code == KeyCode.P
        if v.pathMode
            v.pathMode = false
            set_title(v.window, "")
            # normal color to previous node
            sfCircleShape_setFillColor(v.nodes[v.destNode], nodeColor(v.colors, v.network.nodes[v.destNode]))
        else
            v.pathMode = true
            v.pathFrozen = false
            v.destNode = v.networkviz.selectedNode
            v.path = []
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
    `drawPath` create the path drawings
"""
function drawPath(v::RoutingViz)
    v.path = [Line(copy(v.roads[o, d].rect)) for (o,d) in getPathEdges(v.routing, v.networkviz.selectedNode, v.destNode)]
    for line in v.path
        set_thickness(line, get_thickness(line)*4.)
        set_fillcolor(line, sfColor_fromRGB(0, 0, 125))
    end
end
