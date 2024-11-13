###################################################
## networkviz.jl
## add point&click node information to visual (default visualizer)
###################################################

"""
    `NetworkViz`: Basic NetworkVisualizer. Shows node information in title bar after click
"""
mutable struct NetworkViz <: NetworkVisualizer
    # Mandatory attributes
    network::Network
    window::sfRenderWindow
    view::sfView
    nodes::Vector{Ptr{sfCircleShape}}
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

function visualEvent(v::NetworkViz, event::Ptr{sfEvent})
    type = unsafe_load(event.type)
    if type == sfEvtMouseButtonPressed 
        if unsafe_load(event.mouseButton).button == sfMouseLeft
            x = unsafe_load(event.mouseButton).x
            y =  unsafe_load(event.mouseButton).y
            coord = sfRenderWindow_mapPixelToCoords(v.window,sfVector2i(x, y),sfRenderWindow_getView(v.window))

            id = knn(v.tree,[Float64(coord.x),-Float64(coord.y)],1)[1][1]
            sfCircleShape_setFillColor(v.nodes[v.selectedNode], nodeColor(v.colors, v.network.nodes[v.selectedNode]))
            sfCircleShape_setFillColor(v.nodes[id], sfColor_fromRGB(255, 0, 0))
            v.selectedNode = id
            sfRenderWindow_setTitle(v.window, "Node : $id in: $(in_neighbors(v.network.graph,id)) out: $(out_neighbors(v.network.graph,id))")
        end
    end
end

function visualRedraw(v::NetworkViz)
    sfCircleShape_setFillColor(v.nodes[v.selectedNode], sfColor_fromRGB(255, 0, 0))
end
