function visualize(n::Network)
    # Defines the window, an event listener, and view
    window = RenderWindow("Network Visualization", 1200, 1200)
    set_framerate_limit(window, 60)
    event = Event()
    view = View(Vector2f(0,0), Vector2f(1000, 1000))
    zoomLevel = 1.0
    clock = Clock()

    minLon = minimum([node.lon for node in n.nodes])
    maxLon = maximum([node.lon for node in n.nodes])
    minLat = minimum([node.lat for node in n.nodes])
    maxLat = maximum([node.lat for node in n.nodes])
    shrink = max(maxLat-minLat,maxLon-minLon)

    nodes = CircleShape[CircleShape() for i in 1:length(n.nodes)]
    tic()
    for (i, no) in enumerate(nodes)
        set_radius(no, 0.05)
        set_fillcolor(no, SFML.black)
        x = 1000*(n.nodes[i].lon - (minLon + maxLon)/2)/shrink
        y = -1000*(n.nodes[i].lat - (minLat + maxLat)/2)/shrink
        set_position(no, Vector2f(x,y))
    end
    println(shrink)
    println(n.nodes[1])
    println(get_position(nodes[1]))
    println(get_position(nodes[5]))
    println(get_position(nodes[2]))
    toc()
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
        end
        if is_key_pressed(KeyCode.ESCAPE)
			close(window)
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
        for node in nodes
            draw(window,node)
        end
        display(window)
    end
end
