###################################################
## Create city graph from lonlat polygon
## Automatically download it from OSM overpass API
###################################################

"""
    Create the road network inside the defined box.
    query the osm database using the overpass API if no osm file is given
"""
function queryOsmBox(left::Float64, right::Float64, bottom::Float64, top::Float64; osmfile="")
    if isempty(osmfile)
        url = "http://overpass-api.de/api/map?bbox=$(left),$(bottom),$(right),$(top)"
        osmfile = "$(Pkg.dir("RoutingNetworks"))/.cache/data.osm"
        print("Downloading OSM file (may take time)...")
        download(url, osmfile)
    end
    n = osm2network(osmfile)
    n = removeNodes(n,singleNodes(n))
    n = subsetNetwork(n,inPolygon(n,[(bottom,left),(top,left),(top,right),(bottom,right),(bottom,left)]))
    n = removeNodes(n,singleNodes(n))

    return n
end

"""
    Query a polygon
    right now, query the whole bounding-box and subset the polygon: not optimal
"""
function queryOsmPolygon(poly::Vector{Tuple{Float64,Float64}}; osmfile="")
    (minLon,maxLon,minLat,maxLat) = boundingBox(poly)
    n = queryOsmBox(minLon,maxLon,minLat,maxLat,osmfile=osmfile)
    n = subsetNetwork(n,inPolygon(n,poly))
    n = removeNodes(n,singleNodes(n))
end
