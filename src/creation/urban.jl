###################################################
## complex virtual city, with main city and suburbs
###################################################

"""
Elaborate network, depending on parameters
- width = main city width
- nSub  = number of city's suburb (half the city width)
Represent whole city, with commuting effects
"""
function urbanNetwork(width::Int=8; distance::Float64=100.)
    subwidth = div(width,2)

    function coordToLoc(i::Int, j::Int, c::Int)
        if c ==0
            return j + (i-1)*width
        else
            return width^2 + (c-1)*subwidth^2 + j + (i-1)*subwidth
        end
    end
    function coordToLoc(k::Int, c::Int)
        if c ==0
            return k
        else
            return width^2 + (c-1)*subwidth^2 + k
        end
    end

    #square cities:
    urban = squareNetwork(width, distance=distance)
    suburbs = Network[squareNetwork(subwidth) for i in 1:8]
    resize!(urban.nodes, width^2 + 8*subwidth^2)

    # 4  3  2
    # 5  0  1
    # 6  7  8

    #Positionning the adjacent suburbs:
    for (i,a,b) in [(1,1,0), (3,0,1), (5,-1,0), (7,0,-1)]
        offset = rand()*width*0.55
        for (k,n) in enumerate(suburbs[i].nodes)
            #offset
            x =  n.x + a*distance*((width-1)/2 + (subwidth+1)/2 + offset)
            y =  n.y + b*distance*((width-1)/2 + (subwidth+1)/2 + offset)
            urban.nodes[coordToLoc(k,i)] =  Node(x,y)
        end
        for ((l,m),r) in suburbs[i].roads
            urban.roads[coordToLoc(l,i), coordToLoc(m,i)] = r
        end
    end

    #Positionning the diagonal suburbs:
    for (i,a,b) in [(2,1,1), (4,-1,1), (6,-1, -1), (8,1,-1)]
        offset = rand()*width*0.3
        for (k,n) in enumerate(suburbs[i].nodes)
            #rotation and offset
            x =  (n.x - n.y)/sqrt(2) + a*distance*((width-1)/2 + offset + (subwidth+1)/(2*sqrt(2)))
            y =  (n.y + n.x)/sqrt(2) + b*distance*((width-1)/2 + offset + (subwidth+1)/(2*sqrt(2)))
            urban.nodes[coordToLoc(k,i)] =  Node(x,y)
        end
        for ((l,m),r) in suburbs[i].roads
            n1, n2 = coordToLoc(l,i), coordToLoc(m,i)
            urban.roads[n1,n2] = r
            urban.roads[n2,n1] = r
        end
    end

    #Adding connecting roads
    connections = [ #city1, a1, b1, city2, a2, b2, type
        #perimeter
        (1, div(subwidth,2), subwidth       , 2, div(subwidth,2), 1              , 2),
        (2, div(subwidth,2), subwidth       , 3, subwidth       , div(subwidth,2), 2),
        (3, 1              , div(subwidth,2), 4, subwidth       , div(subwidth,2), 2),
        (4, 1              , div(subwidth,2), 5, div(subwidth,2), subwidth       , 2),
        (5, div(subwidth,2), 1              , 6, div(subwidth,2), subwidth       , 2),
        (6, div(subwidth,2), 1              , 7, 1              , div(subwidth,2), 2),
        (7, subwidth       , div(subwidth,2), 8, 1              , div(subwidth,2), 2),
        (8, subwidth       , div(subwidth,2), 1, div(subwidth,2), 1              , 2),
        # link to city
        (1, 1               , rand(1:subwidth), 0, width        , rand(1:width), 2),
        (2, 1               , rand(1:subwidth), 0, width        , width        , 2),
        (3, rand(1:subwidth), 1               , 0, rand(1:width), width        , 2),
        (4, rand(1:subwidth), 1               , 0, 1            , width        , 2),
        (5, subwidth        , rand(1:subwidth), 0, 1            , rand(1:width), 2),
        (6, subwidth        , rand(1:subwidth), 0, 1            , 1            , 2),
        (7, rand(1:subwidth), subwidth        , 0, rand(1:width), 1            , 2),
        (8, rand(1:subwidth), subwidth        , 0, width        , 1            , 2)
    ]
    for (c1,a1,b1,c2,a2,b2,t) in connections
        # if rand() <= 0.7
            n1, n2 = coordToLoc(a1,b1,c1), coordToLoc(a2,b2,c2)
            r = Road(distanceCoord(urban.nodes[n1],urban.nodes[n2]),t)
            urban.roads[n1,n2] = r
            urban.roads[n2,n1] = r
        # end
    end

    #Add highway around downtown
    for i in 1:(width-1), j in [1,width]
        n1, n2 = coordToLoc(j,i,0), coordToLoc(j,i+1,0)
        r = Road(distanceCoord(urban.nodes[n1],urban.nodes[n2]),1)
        urban.roads[n1,n2] = r
        urban.roads[n2,n1] = r

        n1, n2 = coordToLoc(i,j,0), coordToLoc(i+1,j,0)
        r = Road(distanceCoord(urban.nodes[n1],urban.nodes[n2]),1)
        urban.roads[n1,n2] = r
        urban.roads[n2,n1] = r
    end

    return Network(urban.nodes,urban.roads)


end
