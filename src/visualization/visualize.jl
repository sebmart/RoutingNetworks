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
    - attribute `view::View`
    - attribute `nodes::Vector{CircleShape}`
    - attribute `roads::Dict{Tuple{Int,Int},Line}`
    - attribute `nodeRadius::Float64` (to scale things)
    - attribute `colors::VizColors` to get all the colors of the visualization

    can implement
    - method `visualInit` => initialize things
    - method `visualEvent`  => receive one event (may be 0 or several per frame)
    - method `visualUpdate` => called each frame, to update and draw objects
    - method `visualRedraw` => called when redrawing
"""
abstract type NetworkVisualizer end

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
    `visualStartUpdate` => called each frame, to update and draw objects, is given frame-time
    (before other objects drawn)
"""
function visualStartUpdate(v::NetworkVisualizer,frameTime::Float64)
end

"""
    `visualEndUpdate` => called each frame, to update and draw objects, is given frame-time
     (after other objects drawn)
"""
function visualEndUpdate(v::NetworkVisualizer,frameTime::Float64)
end

"""
    `visualRedraw` => called when change in nodeRadius
"""
function visualRedraw(v::NetworkVisualizer)
end

function Base.show(io::IO, viz::NetworkVisualizer)
    typeName = split(string(typeof(viz)),".")[end]
    println(io,"Network Visualizer: $(typeName)")
end

"""
    `copyVisualData` : copy `ref` visual data into `v`
"""
function copyVisualData(ref::NetworkVisualizer,v::NetworkVisualizer)
    v.window = ref.window
    v.nodes  = ref.nodes
    v.roads  = ref.roads
    v.colors = ref.colors
end

"""
    `visualize`: visualize a network
    - specifics of the visualization are given by NetworkVisualizer object
    - if given network, calls `NodeInfo` visualizer is chosen
"""
function visualize(v::NetworkVisualizer)
    v.nodeRadius = 10.

    #create nodes
    v.nodes = CircleShape[CircleShape() for i in 1:length(v.network.nodes)]

    #create roads
    v.roads = Dict{Tuple{Int,Int},Line}()
    for ((o,d),r) in v.network.roads
        road = Line(Vector2f(0.,0.),Vector2f(1000.,0.))
        v.roads[o,d] = road
    end



    # Defines the window, an event listener, and view
    window_w, window_h = 1200,1200
    v.window = RenderWindow("Network Visualization", window_w, window_h)
    set_vsync_enabled(v.window, true)
    event = Event()

    # Set up the initial view
    minX, maxX, minY, maxY = boundingBox(Tuple{Float64,Float64}[(n.x,n.y) for n in v.network.nodes])
    # Do the Y-axis transformation
    minY, maxY = -maxY, -minY
    networkLength = max(maxX-minX, maxY-minY)
    viewWidth = max(maxX-minX, (maxY-minY)*window_w/window_h)
    viewHeigth = max(maxY-minY, (maxX-minX)*window_h/window_w)
    v.view = View(Vector2f((minX+maxX)/2,(minY+maxY)/2), Vector2f(viewWidth, viewHeigth))
    zoomLevel = 1.0
    hideNodes = true
    # init visualizer
    visualInit(v)
    redraw!(v)
    clock = Clock()
    # gc_enable(false)
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
                set_size(v.view, Vector2f(viewWidth, viewHeigth))
                zoom(v.view, zoomLevel)
            end
            if get_type(event) == EventType.KEY_PRESSED
                k = get_key(event).key_code
                if k == KeyCode.ESCAPE || k == KeyCode.Q
                    close(v.window)
                elseif k == KeyCode.A
                    v.nodeRadius *= 1.3
                    redraw!(v)
                elseif k == KeyCode.S
                    v.nodeRadius /= 1.3
                    redraw!(v)
                elseif k == KeyCode.D
                    hideNodes = !hideNodes
                end
            end
            # additional event processing
            visualEvent(v,event)
        end
		if is_key_pressed(KeyCode.LEFT)
			move(v.view, Vector2f(-networkLength/2*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.RIGHT)
			move(v.view, Vector2f(networkLength/2*frameTime*zoomLevel,0.))
		end
        if is_key_pressed(KeyCode.UP)
			move(v.view, Vector2f(0.,-networkLength/2*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.DOWN)
			move(v.view, Vector2f(0.,networkLength/2*frameTime*zoomLevel))
		end
        if is_key_pressed(KeyCode.Z)
            zoom(v.view, 0.6^frameTime)
            zoomLevel = get_size(v.view).x/viewWidth
		end
		if is_key_pressed(KeyCode.X)
			zoom(v.view, 1/(0.6^frameTime))
            zoomLevel = get_size(v.view).x/viewWidth
		end
        set_view(v.window,v.view)
        clear(v.window, CSFML.Color(210,210,210))
        # additional updates
        visualStartUpdate(v, frameTime)
        for road in values(v.roads)
            draw(v.window,road)
        end
        if !hideNodes
            for node in v.nodes
                draw(v.window,node)
            end
        end

        # additional updates
        visualEndUpdate(v, frameTime)

        display(v.window)
    end
    # gc_enable()
end

visualize(n::Network) = visualize(NetworkViz(n))
visualize(r::RoutingPaths) = visualize(RoutingViz(r))

"""
    `redraw!` is a helper function that updates all the coordinates
"""
function redraw!(v::NetworkVisualizer)
    n = v.network
    # create position vectors (inverse y axe for plotting)
    positions = Vector2f[Vector2f(node.x,-node.y) for node in n.nodes]
    for i in 1:length(positions)
       positions[i] = Vector2f(n.nodes[i].x,-n.nodes[i].y)
    end

    #positions nodes
    for (i, no) in enumerate(v.nodes)
        set_radius(no, v.nodeRadius)
        set_position(no, positions[i] - Vector2f(v.nodeRadius,v.nodeRadius))
        set_fillcolor(no, nodeColor(v.colors, v.network.nodes[i]))
    end

    #positions roads
    #CSFML bug with lines! have to recreate them...
    for ((o,d),r) in v.network.roads
        x = positions[o].y - positions[d].y
        y = positions[d].x - positions[o].x
        l = sqrt(x^2+y^2); x = x/l; y = y/l
        offset = Vector2f(x*v.nodeRadius*3.0/5.0,y*v.nodeRadius*3.0/5.)
        road = Line(positions[o]+offset,positions[d]+offset, 4*v.nodeRadius/5.)
        set_fillcolor(road,roadColor(v.colors, r))
        v.roads[o,d] = road
    end
    visualRedraw(v)
end
