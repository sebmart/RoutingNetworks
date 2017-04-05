###################################################
## geometry.jl
## Geometry tools
###################################################

"""
    Return bounding box of polygon/ list of points
"""
function boundingBox{T<:AbstractFloat}(poly::Vector{Tuple{T,T}})
    minX::T = Inf; maxX::T = -Inf; minY::T = Inf; maxY::T = -Inf
    for (x,y) in poly
        minX = min(minX,x)
        maxX = max(maxX,x)
        minY = min(minY,y)
        maxY = max(maxY,y)
    end
    return (minX,maxX,minY,maxY)
end

"""
    Distance between the two points in meters (true geodesic distance from LLA coordinates)
"""
distanceGeo(pt1::Node, pt2::Node) = distanceGeo(pt1.lon, pt1.lat, pt2.lon, pt2.lat)

function distanceGeo{T<:AbstractFloat}(lon1::T, lat1::T, lon2::T, lat2::T)
    dLat = toradians(lat2 - lat1)
    dLon = toradians(lon2 - lon1)
    lat1 = toradians(lat1)
    lat2 = toradians(lat2)
    a = sin(dLat/2)^2 + sin(dLon/2)^2 * cos(lat1) * cos(lat2)
    2.0 * atan2(sqrt(a), sqrt(1-a)) * 6373.0 * 1000
end

"""
    Distance between the two points in meters (from coordinates)
"""
distanceCoord(pt1::Node, pt2::Node) = distanceCoord(pt1.x, pt1.y, pt2.x, pt2.y)

function distanceCoord{T<:AbstractFloat}(x1::T, y1::T, x2::T, y2::T)
    return sqrt((x2-x1)^2+(y2-y1)^2)
end

"""
    Check is a point is inside a polygon
"""
function pointInsidePolygon{T<:AbstractFloat}(x::AbstractFloat,y::AbstractFloat,poly::Vector{Tuple{T,T}})
    n = length(poly)
    inside =false

    p1x,p1y = poly[1]
    for i in 0:n
        p2x,p2y = poly[i % n + 1]
        if y > min(p1y,p2y) && y <= max(p1y,p2y) && x <= max(p1x,p2x)
            if p1y != p2y
                xinters = (y-p1y)*(p2x-p1x)/(p2y-p1y)+p1x
            end
            if p1x == p2x || x <= xinters
                inside = !inside
            end
        end
        p1x,p1y = p2x,p2y
    end
    return inside
end

"""
    `toENU`, projects latitude and longitude to ENU coordinate system
"""
function toENU(lon, lat, center)
    enu = ENU(LLA(lat,lon), LLA(center[2],center[1]))
    return enu.east, enu.north
end
toENU(lon, lat, n::Network) = toENU(lon, lat, n.projcenter)
"""
    `updateProjection`
    updates the (x,y) projection of the nodes of the network given their latitude/longitude
"""
function updateProjection!(n::Network)
    bounds = boundingBox([(n.lon,n.lat) for n in n.nodes])
    n.projcenter = ((bounds[2]+bounds[1])/2, (bounds[4]+bounds[3])/2)
    nodes = Array{Node}(length(n.nodes))
    for (i,no) in enumerate(n.nodes)
        x,y = toENU(no.lon,no.lat,n.projcenter)
        nodes[i] = Node(x,y,no.lon,no.lat)
    end
    n.nodes = nodes
    n
end
