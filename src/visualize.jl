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
        roads = Array{Line}(length(n.roads))
        for (i,r) in enumerate(edges(n.graph))
            road = Line(positions[src(r)],positions[dst(r)],node_radius/2)
            set_fillcolor(road,SFML.blue)
            roads[i] = road
        end
        return roads
    end

    function getPositions()
        minLon = minimum([node.lon for node in n.nodes])
        maxLon = maximum([node.lon for node in n.nodes])
        minLat = minimum([node.lat for node in n.nodes])
        maxLat = maximum([node.lat for node in n.nodes])
        shrink = max(maxLat-minLat,maxLon-minLon)

        function gps2pos(lon,lat)
            return 1000*(lon - (minLon + maxLon)/2)/shrink, -1000*(lat - (minLat + maxLat)/2)/shrink
        end
        positions = Array{Vector2f}(length(n.nodes))

        for i in 1:length(positions)
           x,y = gps2pos(n.nodes[i].lon, n.nodes[i].lat)
           positions[i] = Vector2f(x,y)
        end
        # KD-tree with positions
        dataPos = Array{Float64,2}(2,length(positions))
        for (i,p) in enumerate(positions)
           dataPos[1,i] = p.x
           dataPos[2,i] = p.y
        end
        return positions, KDTree(dataPos), gps2pos
    end

    function updateSelectedNode(x::Int32, y::Int32)
        coord = pixel2coords(window,Vector2i(x,y))
        id = knn(kdtree,[coord.x,coord.y],1)[1][1]
        set_fillcolor(nodes[selectedNode], SFML.Color(0,0,0,150))
        set_fillcolor(nodes[id], SFML.red)
        selectedNode = id
        set_title(window, "Node : $id in: $(in_neighbors(n.graph,id)) out: $(out_neighbors(n.graph,id))")
    end

    node_radius = 1.
    # Defines the window, an event listener, and view
    window = RenderWindow("Network Visualization", 1200, 1200)
    set_framerate_limit(window, 60)
    event = Event()
    view = View(Vector2f(0,0), Vector2f(1000, 1000))
    zoomLevel = 1.0


    positions, kdtree, gps2pos = getPositions()


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
                set_size(view, Vector2f(size.width, size.height))
                zoom(view, zoomLevel)
            end
            if get_type(event) == EventType.KEY_PRESSED && get_key(event).key_code == KeyCode.ESCAPE
                close(window)
            end
            if get_type(event) == EventType.MOUSE_BUTTON_PRESSED && get_mousebutton(event).button == MouseButton.LEFT
                updateSelectedNode(get_mousebutton(event).x, get_mousebutton(event).y)
            end
        end
		if is_key_pressed(KeyCode.LEFT)
			move(view, Vector2f(-600*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.RIGHT)
			move(view, Vector2f(600*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.UP)
			move(view, Vector2f(0.,-600*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.DOWN)
			move(view, Vector2f(0.,600*frameTime*zoomLevel))
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
