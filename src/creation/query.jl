###################################################
## Create city graph from lonlat polygon
## Automatically download it from OSM overpass API
###################################################

"""
    Create the road network inside the defined box.
    query the osm database using the overpass API if no osm file is given
"""
function queryOsmBox(left::T, right::T, bottom::T, top::T; osmfile="") where T<:AbstractFloat
    if isempty(osmfile)
        url = "http://overpass-api.de/api/map?bbox=$(left),$(bottom),$(right),$(top)"
        osmfile = (@__DIR__) * "/../../.cache/data.osm"
        println("Downloading OSM file (may take time)...")
        download(url, osmfile)
    end
    println("Parsing OSM file...")
    n = osm2network(osmfile)
    println("Creating routing Network")
    n = removeNodes(n,singleNodes(n))
    n = subsetNetwork(n,inPolygon(n,[(left,bottom),(left,top),(right,top),(right,bottom)]))
    n = removeNodes(n,singleNodes(n))

    return n
end

"""
    Query a polygon
    right now, query the whole bounding-box and subset the polygon: not optimal
"""
function queryOsmPolygon(poly::Vector{Tuple{T,T}}; osmfile="") where T<:AbstractFloat
    (minLon,maxLon,minLat,maxLat) = boundingBox(poly)
    n = queryOsmBox(minLon,maxLon,minLat,maxLat,osmfile=osmfile)
    n = subsetNetwork(n,inPolygon(n,poly))
    n = removeNodes(n,singleNodes(n))
end
