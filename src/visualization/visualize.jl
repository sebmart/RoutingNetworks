function visualize(n::Network)

    function createNodes()
        nodes = CircleShape[CircleShape() for i in 1:length(n.nodes)]
        for (i, no) in enumerate(nodes)
            set_radius(no, node_radius)
            set_fillcolor(no, SFML.Color(0,0,0,150))
            set_position(no, positions[i] - Vector2f(node_radius,node_radius))
        end
        return nodes
    end

    function createRoads()
        roads = Line[]
        typecolors= [Color(0,255,0), Color(55,200,0), Color(105,150,0), Color(150,105,0),
                 Color(0,0,125), Color(0,0,125), Color(0,0,125), Color(0,0,125)]
        for ((s,d),r) in n.roads
            road = Line(positions[s],positions[d],node_radius/2)
            set_fillcolor(road,typecolors[r.roadType])
            push!(roads,road)
        end
        return roads
    end

    function getPositions()
        positions = Array{Vector2f}(length(n.nodes))

        for i in 1:length(positions)
           positions[i] = Vector2f(n.nodes[i].x,-n.nodes[i].y)
        end
        # KD-tree with positions
        dataPos = Array{Float64,2}(2,length(positions))
        for (i,p) in enumerate(positions)
           dataPos[1,i] = p.x
           dataPos[2,i] = -p.y
        end
        return positions, KDTree(dataPos)
    end

    function updateSelectedNode(x::Int32, y::Int32)
        coord = pixel2coords(window,Vector2i(x,y))
        id = knn(kdtree,[coord.x,-coord.y],1)[1][1]
        set_fillcolor(nodes[selectedNode], SFML.Color(0,0,0,150))
        set_fillcolor(nodes[id], SFML.red)
        selectedNode = id
        set_title(window, "Node : $id in: $(in_neighbors(n.graph,id)) out: $(out_neighbors(n.graph,id))")
    end

    node_radius = 10.
    # Defines the window, an event listener, and view
    window_w, window_h = 1200,1200
    window = RenderWindow("Network Visualization", window_w, window_h)
    set_framerate_limit(window, 60)
    event = Event()





    positions, kdtree = getPositions()

    minX, maxX, minY, maxY = boundingBox(Tuple{Float64,Float64}[(p.x,p.y) for p in positions])
    networkLength = max(maxX-minX, maxY-minY)
    viewWidth = max(maxX-minX, (maxY-minY)*window_w/window_h)
    viewHeigth = max(maxY-minY, (maxX-minX)*window_h/window_w)
    view = View(Vector2f((minX+maxX)/2,(minY+maxY)/2), Vector2f(viewWidth, viewHeigth))
    zoomLevel = 1.0
    nodes = createNodes()
    roads = createRoads()
    selectedNode = 1


    clock = Clock()
    while isopen(window)
        frameTime = as_seconds(restart(clock))
        while pollevent(window, event)
            if get_type(event) == EventType.CLOSED
                close(window)
            end
            if get_type(event) == EventType.RESIZED
                size = get_size(event)
                set_size(view, Vector2f(size.width * zoomLevel, size.height * zoomLevel))
                zoom(view, zoomLevel)
            end
            if get_type(event) == EventType.KEY_PRESSED && (get_key(event).key_code == KeyCode.ESCAPE || get_key(event).key_code == KeyCode.Q)
                close(window)
            end
            if get_type(event) == EventType.MOUSE_BUTTON_PRESSED && get_mousebutton(event).button == MouseButton.LEFT
                updateSelectedNode(get_mousebutton(event).x, get_mousebutton(event).y)
            end
        end
		if is_key_pressed(KeyCode.LEFT)
			move(view, Vector2f(-networkLength/3*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.RIGHT)
			move(view, Vector2f(networkLength/3*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.UP)
			move(view, Vector2f(0.,-networkLength/3*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.DOWN)
			move(view, Vector2f(0.,networkLength/3*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.Z)
            zoom(view, 0.7^frameTime)
            zoomLevel = get_size(view).x/get_size(window).x
		end
		if is_key_pressed(KeyCode.X)
			zoom(view, 1/(0.7^frameTime))
            zoomLevel = get_size(view).x/get_size(window).x
		end
        set_view(window,view)
        clear(window, SFML.white)
        for road in roads
            draw(window,road)
        end
        for node in nodes
            draw(window,node)
        end

        display(window)
    end
end
