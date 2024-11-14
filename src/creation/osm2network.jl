#######################################
## Contains osm2network, to transform an osm file into a network
#######################################

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
highway(w::OSMWay) = haskey(w.tags, "highway")
roadway(w::OSMWay) = get(ROAD_CLASSES,w.tags["highway"],0.)
function oneway(w::OSMWay)
    v = get(w.tags,"oneway", "")

    if v == "false" || v == "no" || v == "0"
        return false
    elseif v == "-1" || v == "true" || v == "yes" || v == "1"
        return true
    end

    highway = get(w.tags,"highway", "")
    junction = get(w.tags,"junction", "")

    return (highway == "motorway" ||
            highway == "motorway_link" ||
            junction == "roundabout")
end

visible(obj::T) where {T <: OSMElement} = (get(obj.tags, "visible", "") != "false")
services(w::OSMWay) = (get(w.tags,"highway", "") == "services")
reverse(w::OSMWay) = (get(w.tags,"oneway", "") == "-1")
toradians(degree::AbstractFloat) = degree * π / 180.0



"""
Opens a OSM file,
and returns a network object from the OSM data
"""
function osm2network(filename::AbstractString)
  osm = parseOSM(filename);


  # fetch all nodes ids
  osm_id = Int[n.id for n in osm.nodes]
  # construct inverse dictionary
  node_id = Dict{Int,Int}()
  sizehint!(node_id, length(osm_id))
  for i in 1:length(osm_id)
      node_id[osm_id[i]] = i
  end
  #construct the "Node" objects
  lonlat = Tuple{Float64,Float64}[c.lonlat for c in osm.nodes]
  bounds = boundingBox(lonlat)
  center = ((bounds[2]+bounds[1])/2, (bounds[4]+bounds[3])/2)
  nodes = Array{Node}(length(lonlat))
  for (i,(lon,lat)) in enumerate(lonlat)
      x,y = toENU(lon,lat,center)
      nodes[i] = Node(x,y,lon,lat)
  end

  g = DiGraph(length(nodes))

  #We transform ways into edges
  roads = Dict{Tuple{Int,Int},Road}()
  for w in osm.ways
    if highway(w) && visible(w) && !(services(w)) && roadway(w) != 0
      for i in 2:length(w.nodes)
        if reverse(w)
          edge = Edge(node_id[w.nodes[i]],node_id[w.nodes[i-1]])
        else
          edge = Edge(node_id[w.nodes[i]],node_id[w.nodes[i-1]])
        end
        if !has_edge(g,edge)
          add_edge!(g,edge)
          roads[src(edge),dst(edge)] = Road(src(edge),dst(edge),distanceGeo(nodes[src(edge)],nodes[dst(edge)]), roadway(w))
        end
        if !oneway(w)
          edge = Edge(dst(edge),src(edge))
          if !has_edge(g,edge)
            add_edge!(g,edge)
            roads[src(edge),dst(edge)] = Road(src(edge),dst(edge),distanceGeo(nodes[src(edge)],nodes[dst(edge)]), roadway(w))
          end
        end
      end
    end
  end
  n = Network(g, nodes, roads)
  n.projcenter = center
  return n
end
