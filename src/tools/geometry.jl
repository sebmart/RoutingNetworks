###################################################
## Geometry tools
###################################################

"""
    Return bounding box of polygon/ list of points
"""
function boundingBox(poly::Vector{Tuple{Float64,Float64}})
    minX = Inf; maxX = -Inf; minY = Inf; maxY = -Inf
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
function distanceGeo(pt1::Node, pt2::Node)
    dLat = toradians(pt2.lat - pt1.lat)
    dLon = toradians(pt2.lon - pt1.lon)
    lat1 = toradians(pt1.lat)
    lat2 = toradians(pt2.lat)
    a = sin(dLat/2)^2 + sin(dLon/2)^2 * cos(lat1) * cos(lat2)
    2.0 * atan2(sqrt(a), sqrt(1-a)) * 6373.0 * 1000
end

"""
    Distance between the two points in meters (from coordinates)
"""
function distanceCoord(pt1::Node, pt2::Node)
    return sqrt((pt2.x-pt1.x)^2+(pt2.y-pt1.y)^2)
end

"""
    Check is a point is inside a polygon
"""
function point_inside_polygon(x::Float64,y::Float64,poly::Vector{Tuple{Float64,Float64}})
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
    projects latitude and longitude to ENU coordinate system
"""
function toENU(lon::Float64, lat::Float64, center::Tuple{Float64,Float64})
    enu = Geodesy.ENU(Geodesy.LLA(lat,lon), Geodesy.LLA(center[2],center[1]))
    return enu.east, enu.north
end
