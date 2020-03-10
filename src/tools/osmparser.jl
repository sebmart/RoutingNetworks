###################################################
## osmparser.jl
## copy of OpenStreetMapParser code
###################################################
abstract type OSMElement end

# OSMNodes
# +-----+-------------------+---------------+
# | id  | lonlat            | tags...       |
# +-----+-------------------+---------------+
# | Int | (Float64,Float64) | String... |
# | .   | .                 | .             |
# | .   | .                 | .             |
# | .   | .                 | .             |
# +-----+-------------------+---------------+

mutable struct OSMNode <: OSMElement
    id::Int
    lonlat::Tuple{Float64,Float64}
    tags::Dict{String,String}
    OSMNode(id::Int, lonlat::Tuple{Float64,Float64}) = new(id, lonlat)
end

function tags(n::OSMNode) # lazily create tags
    isdefined(n, :tags) || (n.tags = Dict{String,String}())
    n.tags
end

# OSMNode(id::Int, lonlat::Tuple{Float64,Float64}) =
#     OSMNode(id, lonlat, Dict{String,String}())

# OSMWays
# +-----+-------------------+---------------+
# | id  | nodes (osm id)    | tags...       |
# +-----+-------------------+---------------+
# | Int | Vector{Int}       | String... |
# | .   | .                 | .             |
# | .   | .                 | .             |
# | .   | .                 | .             |
# +-----+-------------------+---------------+

mutable struct OSMWay <: OSMElement
    id::Int
    nodes::Vector{Int}
    tags::Dict{String,String}
    OSMWay(id::Int) = new(id, Vector{Int}(), Dict{String,String}())
end
tags(w::OSMWay) = w.tags

# OSMWay(id::Int) = OSMWay(id, Vector{Int}(), Dict{String,String}())

# Relations
# +-----+-----------------------+---------------+
# | id  | members               | tags...       |
# +-----+-----------------------+---------------+
# | Int | Vector{Dict{Str,Str}} | String... |
# | .   | .                     | .             |
# | .   | .                     | .             |
# | .   | .                     | .             |
# +-----+-----------------------+---------------+

mutable struct Relation <: OSMElement
    id::Int
    members::Vector{Dict{String,String}}
    tags::Dict{String,String}
    Relation(id::Int) = new(id, Vector{Dict{String,String}}(),
                            Dict{String,String}())
end
tags(r::Relation) = r.tags

# Relation(id::Int) = Relation(id, Vector{Dict{String,String}}(),
#                              Dict{String,String}())

mutable struct OSMData
    nodes::Vector{OSMNode}
    ways::Vector{OSMWay}
    relations::Vector{Relation}
    node_tags::Set{String}
    way_tags::Set{String}
    relation_tags::Set{String}
end
OSMData() = OSMData(Vector{OSMNode}(), Vector{OSMWay}(), Vector{Relation}(),
                    Set{String}(), Set{String}(), Set{String}())

mutable struct DataHandle
    element::Symbol
    osm::OSMData
    node::OSMNode # initially undefined
    way::OSMWay # initially undefined
    relation::Relation # initially undefined

    DataHandle() = new(:None, OSMData())
end

function parseElement(handler::LibExpat.XPStreamHandler,
                      name::AbstractString,
                      attr::Dict{AbstractString,AbstractString})
    data = handler.data::DataHandle
    if name == "node"
        data.element = :OSMNode
        data.node = OSMNode(parse(Int, attr["id"]),
                         (parse(Float64, attr["lon"]), parse(Float64, attr["lat"])))
    elseif name == "way"
        data.element = :OSMWay
        data.way = OSMWay(parse(Int, attr["id"]))
    elseif name == "relation"
        data.element = :Relation
        data.relation = Relation(parse(Int, attr["id"]))
    elseif name == "tag"
        k = attr["k"]; v = attr["v"]
        if data.element == :OSMNode
            data_tags = tags(data.node)
            push!(data.osm.node_tags, k)
        elseif data.element == :OSMWay
            data_tags = tags(data.way)
            push!(data.osm.way_tags, k)
        elseif data.element == :Relation
            data_tags = tags(data.relation)
            push!(data.osm.relation_tags, k)
        end
        data_tags[k] = v
    elseif name == "nd"
        push!(data.way.nodes, parse(Int, attr["ref"]))
    elseif name == "member"
        push!(data.relation.members, attr)
    end
end

function collectElement(handler::LibExpat.XPStreamHandler, name::AbstractString)
    if name == "node"
        push!(handler.data.osm.nodes, handler.data.node)
        handler.data.element = :None
    elseif name == "way"
        push!(handler.data.osm.ways, handler.data.way)
        handler.data.element = :None
    elseif name == "relation"
        push!(handler.data.osm.relations, handler.data.relation)
        handler.data.element = :None
    end
end

function parseOSM(filename::AbstractString; args...)
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseElement
    callbacks.end_element = collectElement
    data = DataHandle()
    LibExpat.parsefile(filename, callbacks, data=data; args...)
    data.osm::OSMData
end

function parseOSMNode(handler::LibExpat.XPStreamHandler,
                   name::AbstractString,
                   attr::Dict{AbstractString,AbstractString})
    data = handler.data
    if name == "node"
        data.element = :OSMNode
        data.curr = OSMNode(parse(Int, attr["id"]),
                         (parse(Float64, attr["lon"]), parse(Float64, attr["lat"])),
                         Dict{String,String}())
    elseif name == "tag" && data.element == :OSMNode
        data.curr.tags[attr["k"]] = attr["v"]
    end
end

function collectOSMNode(handler::LibExpat.XPStreamHandler, name::AbstractString)
    if name == "node"
        handler.data.element = :None
        push!(handler.data.nodes, handler.data.curr)
    end
end

function parseOSMNodes(filename::AbstractString; args...)
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseOSMNode
    callbacks.end_element = collectOSMNode
    nodehandle = OSMNodeHandle()
    LibExpat.parsefile(filename, callbacks, data=nodehandle; args...)
    nodehandle.nodes::Vector{OSMNode}
end

# Example (OSMWay)
# -------
# <way id="5090250" visible="true" timestamp="2009-01-19T19:07:25Z" version="8"
#      changeset="816806" user="Blumpsy" uid="64226">
#     <nd ref="822403"/>
#     <nd ref="21533912"/>
#     ...
#     <nd ref="135791608"/>
#     <nd ref="823771"/>
#     <tag k="highway" v="residential"/>
#     <tag k="name" v="Clipstone Street"/>
#     <tag k="oneway" v="yes"/>
#   </way>

mutable struct OSMWayHandle
    element::Symbol
    ways::Vector{OSMWay}
    curr::OSMWay # initially undefined
    OSMWayHandle(element::Symbol, ways::Vector{OSMWay}) = new(element, ways)
end

function parseOSMWay(handler::LibExpat.XPStreamHandler,
                  name::AbstractString,
                  attr::Dict{AbstractString,AbstractString})
    if name == "way"
        handler.data.element = :OSMWay
        handler.data.curr = OSMWay(parse(Int, attr["id"]),
                                Vector{Int}(),
                                Dict{String,String}())
    elseif handler.data.element == :OSMWay
        if name == "tag"
            handler.data.curr.tags[attr["k"]] = attr["v"]
        elseif name == "nd"
            push!(handler.data.curr.nodes, parse(Int, attr["ref"]))
        end
    end
end

function collectOSMWay(handler::LibExpat.XPStreamHandler, name::AbstractString)
    if name == "way"
        push!(handler.data.ways, handler.data.curr)
        handler.data.element = :None
    end
end

function parseOSMWays(filename::AbstractString; args...)
    wayhandle = OSMWayHandle(:None, Vector{OSMWay}())
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseOSMWay
    callbacks.end_element = collectOSMWay
    LibExpat.parsefile(filename, callbacks, data=wayhandle; args...)
    wayhandle.ways::Vector{OSMWay}
end

# Example (Relation)
# <relation id="1">
#   <tag k="type" v="multipolygon" />
#   <member type="way" id="1" role="outer" />
#   <member type="way" id="2" role="outer" />
#   ...
#   <member type="way" id="19" role="inner" />
#   <member type="way" id="20" role="outer" />
# </relation>

mutable struct RelationHandle
    element::Symbol
    relations::Vector{Relation}
    curr::Relation # initially undefined
    RelationHandle(e::Symbol, relations::Vector{Relation}) = new(e, relations)
end

function parseRelation(handler::LibExpat.XPStreamHandler,
                       name::AbstractString,
                       attr::Dict{AbstractString,AbstractString})
    if name == "relation"
        handler.data.element = :Relation
        handler.data.curr = Relation(parse(Int, attr["id"]),
                                     Vector{Dict{String,String}}(),
                                     Dict{String,String}())
    elseif handler.data.element == :Relation
        if name == "tag"
            handler.data.curr.tags[attr["k"]] = attr["v"]
        elseif name == "member"
            push!(handler.data.curr.members, attr)
        end
    end
end

function collectRelation(handler::LibExpat.XPStreamHandler, name::AbstractString)
    if name == "relation"
        push!(handler.data.relations, handler.data.curr)
        handler.data.element = :None
    end
end

function parseRelations(filename::AbstractString; args...)
    relationhandle = RelationHandle(:None, Vector{Relation}())
    callbacks = LibExpat.XPCallbacks()
    callbacks.start_element = parseRelation
    callbacks.end_element = collectRelation
    LibExpat.parsefile(filename, callbacks, data=relationhandle; args...)
    relationhandle.relations::Vector{Relation}
end
