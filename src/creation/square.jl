###################################################
## Square virtual city
###################################################

"""
 n*n points randomized  square network
 - all road same type (5)

"""
function squareNetwork(width::Int = 5; distance::Float64=100.)
        #nodes are indexed as follow :
        #  12
        #  34 (for width=2)

        function coordToLoc(i,j)
            return j + (i-1)*width
        end
        function locToCoord(n)
            return (div((n-1),width) + 1, ((n-1) % width) + 1)
        end

        #Create nodes
        nodes = Array{Nodes}(width^2)
        for i in 1:width, j in 1:width
            nodes[coordToLoc(i,j)] = Node((i-(width+1)/2)*distance, (j-(width+1)/2)*distance)
        end
        roads = Dict{Tuple{Int,Int},Road}()

        for i in 1:(width-1), j in 1:width
            #Vertical roads
            n1 = coordToLoc(i,j); n2 = coordToLoc(i+1,j);
            dist = distanceCoord(nodes[n1],nodes[n2]);
            roads[(n1,n2)] = Road(dist, 5)
            roads[(n2,n1)] = Road(dist, 5)

            #Horizontal roads
            n1 = coordToLoc(j,i); n2 = coordToLoc(j,i+1)
            dist = distanceCoord(nodes[n1],nodes[n2]);
            roads[(n1,n2)] = Road(dist, 5)
            roads[(n2,n1)] = Road(dist, 5)
        end
        return Network(nodes, roads)
end
