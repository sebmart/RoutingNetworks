###################################################
## Create city graph from lonlat polygon
## Automatically download it from OSM overpass API
###################################################

"""
    Create the road network inside the defined polygon.
    - query the osm database using the overpass API if no osm file is given
    - clean and subset the network to the desired polygon
"""
function queryFromCoordinates(poly::Vector{Tuple{Float64,Float64}}; osmfile="")
    (minLon,maxLon,minLat,maxLat) = boundingBox(poly)
    if isempty(osmfile)
        url = "http://overpass-api.de/api/map?bbox=$(minLon),$(minLat),$(maxLon),$(maxLat)"
        osmfile = "$(Pkg.dir("NetworkTools"))/.cache/data.osm"
        download(url, osmfile)
    end
    n = osm2network(osmfile)
    n = removeNodes(n,singleNodes(n))
    n = subsetNetwork(n,inPolygon(n,poly))
    n = removeNodes(n,singleNodes(n))
end
