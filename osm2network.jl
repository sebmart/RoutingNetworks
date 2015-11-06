import OpenStreetMapParser
const OSM = OpenStreetMapParser

const ROAD_CLASSES = Dict(
    "motorway" => 1,
    "trunk" => 2,
    "primary" => 3,
    "secondary" => 4,
    "tertiary" => 5,
    "unclassified" => 6,
    "residential" => 6,
    "service" => 7,
    "motorway_link" => 1,
    "trunk_link" => 2,
    "primary_link" => 3,
    "secondary_link" => 4,
    "tertiary_link" => 5,
    "living_street" => 8,
    "pedestrian" => 8,
    "road" => 6)

#TOOLS from OpenStreetMapParser
highway(w::OSM.Way) = haskey(w.tags, "highway")
roadway(w::OSM.Way) = get(ROAD_CLASSES,w.tags["highway"],0.)                                                                            

visible{T <: OSM.OSMElement}(obj::T) = (get(obj.tags, "visible", "") != "false")
services(w::OSM.Way) = (get(w.tags,"highway", "") == "services")
reverse(w::OSM.Way) = (get(w.tags,"oneway", "") == "-1")

function osm2network(filename::AbstractString)
  @time osm = OSM.parseOSM(filename);

  ways = filter(highway, osm.ways)
  ways = ways[map(visible, ways) & ~(map(services, ways))]
  road_class = map(roadway, ways)
  ways = ways[~(road_class .== 0)]

  road_class = road_class
      speed = [road_speed[c] for c in road_class[~(road_class .== 0)]]
  nodes = array(Node, nv(n.g))
  roads = Dict{Tuple{Int,Int},Road}()
  for i in 1:length(nodes)
    lon, lat = osm.nodes[n.osm_id[i]].lonlat
    nodes[i] = Node(lo)
  end
  for e in edges(n.g)
    roads[src(e),dst(e)] = Road(OSM.distance(()))
  end
end
