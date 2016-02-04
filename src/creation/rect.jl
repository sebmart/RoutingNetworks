###################################################
## Rectangular virtual city
###################################################

"""
  `rectNetwork` : n*m points rectangular network
 - all road same type (5)
 - `distX` and `distY` are the width and height of a block (in meters)
"""
function rectNetwork(width::Int = 5, height::Int = 10; distX::Float64=200., distY::Float64 = 200.)
        #nodes are indexed as follow :
        #  12
        #  34 (for width=2,2)

        function coordToLoc(i,j) # matrix indexation, i= row j=column
            return j + (i-1)*width
        end
        function locToCoord(n)
            return (div((n-1),width) + 1, ((n-1) % width) + 1)
        end

        #Create nodes
        nodes = Array{Node}(width*height)
        for i in 1:height, j in 1:width
            nodes[coordToLoc(i,j)] = Node((j-(width+1)/2)*distX, ((height+1)/2 - i)*distY)
        end
        roads = Dict{Tuple{Int,Int},Road}()

        #Vertical roads
        for i in 1:(height-1), j in 1:width
            n1 = coordToLoc(i,j); n2 = coordToLoc(i+1,j)
            dist = distanceCoord(nodes[n1],nodes[n2])
            roads[(n1,n2)] = Road(n1,n2,dist, 5)
            roads[(n2,n1)] = Road(n1,n2,dist, 5)
        end

        #Horizontal roads
        for i in 1:height, j in 1:width - 1
            n1 = coordToLoc(i,j); n2 = coordToLoc(i,j+1)
            dist = distanceCoord(nodes[n1],nodes[n2])
            roads[(n1,n2)] = Road(n1,n2,dist, 5)
            roads[(n2,n1)] = Road(n1,n2,dist, 5)
        end
        return Network(nodes, roads)
end

squareNetwork(width::Int = 5; distance::Float64=200.) = rectNetwork(width, width, distX=distance, distY=distance)
