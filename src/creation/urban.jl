###################################################
## complex virtual city, with main city and suburbs
###################################################

"""
Elaborate network, depending on parameters
- width = main city width
- nSub  = number of city's suburb (half the city width)
Represents whole city, with commuting effects
"""
function urbanNetwork(width::Int=8; distance::Float64=200.)
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
            n1,n2 = coordToLoc(l,i), coordToLoc(m,i)
            urban.roads[n1,n2] = Road(n1,n2, r.distance, r.roadType)
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
            urban.roads[n1,n2] = Road(n1, n2, r.distance, r.roadType)
        end
    end

    #Adding connecting roads
    connections = [ #city1, i1, j1, city2, i2, j2, type
        #perimeter
        (1, 1              , div(subwidth,2), 2, subwidth       , div(subwidth,2), 2),
        (2, 1              , div(subwidth,2), 3, div(subwidth,2), subwidth       , 2),
        (3, div(subwidth,2), 1              , 4, div(subwidth,2), subwidth       , 2),
        (4, div(subwidth,2), 1              , 5, 1              , div(subwidth,2), 2),
        (5, subwidth       , div(subwidth,2), 6, 1              , div(subwidth,2), 2),
        (6, subwidth       , div(subwidth,2), 7, div(subwidth,2), 1              , 2),
        (7, div(subwidth,2), subwidth       , 8, div(subwidth,2), 1              , 2),
        (8, div(subwidth,2), subwidth       , 1, subwidth       , div(subwidth,2), 2),
        # link to city
        (1, rand(1:subwidth), 1               , 0, rand(1:width), width        , 2),
        (2, rand(1:subwidth), 1               , 0, 1            , width        , 2),
        (3, subwidth        , rand(1:subwidth), 0, 1            , rand(1:width), 2),
        (4, subwidth        , rand(1:subwidth), 0, 1            , 1            , 2),
        (5, rand(1:subwidth), subwidth        , 0, rand(1:width), 1            , 2),
        (6, rand(1:subwidth), subwidth        , 0, width        , 1            , 2),
        (7, 1               , rand(1:subwidth), 0, width        , rand(1:width), 2),
        (8, 1               , rand(1:subwidth), 0, width        , width        , 2)
    ]
    for (c1,a1,b1,c2,a2,b2,t) in connections
        # if rand() <= 0.7
            n1, n2 = coordToLoc(a1,b1,c1), coordToLoc(a2,b2,c2)
            d = distanceCoord(urban.nodes[n1],urban.nodes[n2])
            urban.roads[n1,n2] = Road(n1,n2,d,t)
            urban.roads[n2,n1] = Road(n2,n1,d,t)
        # end
    end

    #Add highway around downtown
    for i in 1:(width-1), j in [1,width]
        n1, n2 = coordToLoc(j,i,0), coordToLoc(j,i+1,0)
        d = distanceCoord(urban.nodes[n1],urban.nodes[n2])
        urban.roads[n1,n2] = Road(n1,n2,d,1)
        urban.roads[n2,n1] = Road(n2,n1,d,1)

        n1, n2 = coordToLoc(i,j,0), coordToLoc(i+1,j,0)
        d = distanceCoord(urban.nodes[n1],urban.nodes[n2])
        urban.roads[n1,n2] = Road(n1,n2,d,1)
        urban.roads[n2,n1] = Road(n2,n1,d,1)
    end

    return Network(urban.nodes,urban.roads)
end
