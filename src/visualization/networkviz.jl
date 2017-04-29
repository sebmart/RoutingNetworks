###################################################
## networkviz.jl
## add point&click node information to visual (default visualizer)
###################################################

"""
    `NetworkViz`: Basic NetworkVisualizer. Shows node information in title bar after click
"""
type NetworkViz <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::RenderWindow
    view::View
    nodes::Vector{CircleShape}
    roads::Dict{Tuple{Int,Int},Line}
    nodeRadius::Float64
    colors::VizColors

    "node positions KD-tree"
    tree::KDTree
    "selected node"
    selectedNode::Int

    "contructor: initialize kd-tree"
    function NetworkViz(n::Network; colors::VizColors=RoadTypeColors())
        obj = new()
        # KD-tree with positions
        dataPos = Array{Float64,2}(2,length(n.nodes))
        for (i,node) in enumerate(n.nodes)
           dataPos[1,i] = node.x
           dataPos[2,i] = node.y
        end

        obj.network = n
        obj.tree = KDTree(dataPos)
        obj.selectedNode = 1
        obj.colors = colors
        return obj
    end
end

function visualEvent(v::NetworkViz, event::Event)
    if get_type(event) == EventType.MOUSE_BUTTON_PRESSED && get_mousebutton(event).button == MouseButton.LEFT
        x,y = get_mousebutton(event).x, get_mousebutton(event).y
        coord = pixel2coords(v.window,Vector2i(x,y))

        id = knn(v.tree,[Float64(coord.x),-Float64(coord.y)],1)[1][1]
        set_fillcolor(v.nodes[v.selectedNode], nodeColor(v.colors, v.network.nodes[v.selectedNode]))
        set_fillcolor(v.nodes[id], SFML.red)
        v.selectedNode = id
        set_title(v.window, "Node : $id in: $(in_neighbors(v.network.graph,id)) out: $(out_neighbors(v.network.graph,id))")
    end
end

function visualRedraw(v::NetworkViz)
    set_fillcolor(v.nodes[v.selectedNode], SFML.red)
end
