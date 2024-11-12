using CSFML.LibCSFML, Base
window_w, window_h = 600,600
println("Initiate Render window")
window = sfRenderWindow_create(   sfVideoMode_getDesktopMode(), 
                                    "Network Visualization", 
                                    sfResize | sfClose, 
                                    C_NULL)
print("Initiate done")
sfRenderWindow_setVerticalSyncEnabled(window, true)
event_ref = Ref{sfEvent}()

# Set up the initial view
minX, maxX, minY, maxY = 0, 556, 0, 300
# Do the Y-axis transformation
minY, maxY = -maxY, -minY
networkLength = max(maxX-minX, maxY-minY)
viewWidth = max(maxX-minX, (maxY-minY)*window_w/window_h)
viewHeigth = max(maxY-minY, (maxX-minX)*window_h/window_w)

view = sfView_createFromRect(sfFloatRect((minX+maxX)/2,(minY+maxY)/2, viewWidth, viewHeigth))
sfRenderWindow_setView(window, view)
zoomLevel = 1.0
hideNodes = true
while Bool(sfRenderWindow_isOpen(window))
    # print()
    while  Bool(sfRenderWindow_pollEvent(window, event_ref))
        event_ptr = Base.unsafe_convert(Ptr{sfEvent}, event_ref)    
        GC.@preserve event_ref begin
            type = unsafe_load(event_ptr.type)
            type == sfEvtClosed && sfRenderWindow_close(window)
        end
    end
    sfRenderWindow_clear(window, sfColor_fromRGB(220, 200, 220))
    sfRenderWindow_display(window)
end

