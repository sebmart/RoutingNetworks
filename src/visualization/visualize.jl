###################################################
## visualize.jl
## visualize network (made to be extended)
###################################################

"""
    `NetworkVisualizer` : abstract type that represents visualization in a network
    has to implement ands initialize:
    - attribute `network::Network`
    has to implement, automatically initialized
    - attribute `window::RenderWindow`
    - attribute `nodes::Vector{CircleShape}`
    - attribute `roads::Dict{Tuple{Int,Int},Line}`

    can implement
    - method `visualInit` => initialize things
    - method `visualEvent`  => receive one event (may be 0 or several per frame)
    - method `visualUpdate` => called each frame, to update and draw objects
"""
abstract NetworkVisualizer

"""
    `visualInit` initialize things
"""
function visualInit(v::NetworkVisualizer)
end

"""
    `visualEvent` => called each frame, is given the events
"""
function visualEvent(v::NetworkVisualizer, event::Event)
end

"""
    `updateVisual` => called each frame, to update and draw objects, is given frame-time
"""
function visualUpdate(v::NetworkVisualizer,frameTime::Float64)
end

"""
    `copyVisualData` : copy `ref` visual data into `v`
"""
function copyVisualData(ref::NetworkVisualizer,v::NetworkVisualizer)
    v.window = ref.window
    v.nodes  = ref.nodes
    v.roads  = ref.roads
end

"""
    `visualize`: visualize a network
    - specifics of the visualization are given by NetworkVisualizer object
    - if given network, calls `NodeInfo` visualizer is chosen
"""
function visualize(v::NetworkVisualizer)
    n = v.network
    node_radius = 10.

    # create position vectors (inverse y axe for plotting)
    positions = Array{Vector2f}(length(n.nodes))
    for i in 1:length(positions)
       positions[i] = Vector2f(n.nodes[i].x,-n.nodes[i].y)
    end

    #create nodes
    v.nodes = CircleShape[CircleShape() for i in 1:length(n.nodes)]
    for (i, no) in enumerate(v.nodes)
        set_radius(no, node_radius)
        set_fillcolor(no, SFML.Color(0,0,0,150))
        set_position(no, positions[i] - Vector2f(node_radius,node_radius))
    end


    #create roads
    v.roads = Dict{Tuple{Int,Int},Line}()
    typecolors= [Color(0,255,0), Color(55,200,0), Color(105,150,0), Color(150,105,0),
             Color(0,0,125), Color(0,0,125), Color(0,0,125), Color(0,0,125)]
    for ((o,d),r) in n.roads
        road = Line(positions[o],positions[d],node_radius/2)
        set_fillcolor(road,typecolors[r.roadType])
        v.roads[o,d] = road
    end



    # Defines the window, an event listener, and view
    window_w, window_h = 1200,1200
    v.window = RenderWindow("Network Visualization", window_w, window_h)
    set_framerate_limit(v.window, 60)
    event = Event()

    # Set up the initial view
    minX, maxX, minY, maxY = boundingBox(Tuple{Float64,Float64}[(p.x,p.y) for p in positions])
    networkLength = max(maxX-minX, maxY-minY)
    viewWidth = max(maxX-minX, (maxY-minY)*window_w/window_h)
    viewHeigth = max(maxY-minY, (maxX-minX)*window_h/window_w)
    view = View(Vector2f((minX+maxX)/2,(minY+maxY)/2), Vector2f(viewWidth, viewHeigth))
    zoomLevel = 1.0

    # init visualizer
    visualInit(v)

    clock = Clock()
    while isopen(v.window)
        frameTime = Float64(as_seconds(restart(clock)))
        while pollevent(v.window, event)
            if get_type(event) == EventType.CLOSED
                close(v.window)
            end
            if get_type(event) == EventType.RESIZED
                size = get_size(event)
                window_w, window_h = size.width, size.height
                viewWidth = max(maxX-minX, (maxY-minY)*window_w/window_h)
                viewHeigth = max(maxY-minY, (maxX-minX)*window_h/window_w)
                set_size(view, Vector2f(viewWidth, viewHeigth))
                zoom(view, zoomLevel)
            end
            if get_type(event) == EventType.KEY_PRESSED && (get_key(event).key_code == KeyCode.ESCAPE || get_key(event).key_code == KeyCode.Q)
                close(v.window)
            end
            # additional event processing
            visualEvent(v,event)
        end
		if is_key_pressed(KeyCode.LEFT)
			move(view, Vector2f(-networkLength/2*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.RIGHT)
			move(view, Vector2f(networkLength/2*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.UP)
			move(view, Vector2f(0.,-networkLength/2*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.DOWN)
			move(view, Vector2f(0.,networkLength/2*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.Z)
            zoom(view, 0.6^frameTime)
            zoomLevel = get_size(view).x/viewWidth
		end
		if is_key_pressed(KeyCode.X)
			zoom(view, 1/(0.6^frameTime))
            zoomLevel = get_size(view).x/viewWidth
		end
        set_view(v.window,view)
        clear(v.window, SFML.white)
        for road in values(v.roads)
            draw(v.window,road)
        end
        for node in v.nodes
            draw(v.window,node)
        end

        # additional updates
        visualUpdate(v, frameTime)

        display(v.window)
    end
end

visualize(n::Network) = visualize(NodeInfo(n))
