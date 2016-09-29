###################################################
## visualization/vizcolors.jl
## colors for visualization
###################################################

"""
    `VizColors` : abstract type that represents the visualization's colors:
    two methods use it: `nodeColor` and `roadColor`, that are made to be overriden
"""
abstract VizColors

"""
    `nodeColor` returns a node's color.
"""
nodeColor(colors::VizColors, node::Node) = SFML.Color(0,0,0)

"""
    `roadColor` returns a road's color
"""
roadColor(colors::VizColors, road::Road) = SFML.Color(50,50,255)

function Base.show(io::IO, viz::VizColors)
    typeName = split(string(typeof(viz)),".")[end]
    println(io,"Visualization Colors: $(typeName)")
end



"""
    `RoadTypeColors` is a road-type based coloring scheme
"""
type RoadTypeColors <: VizColors
    typecolors::Vector{SFML.Color}
end

RoadTypeColors() = RoadTypeColors(
        [SFML.Color(0,255,0)  , SFML.Color(55,200,0), SFML.Color(105,150,0),
         SFML.Color(150,105,0), SFML.Color(0,0,125) , SFML.Color(0,0,125)  ,
         SFML.Color(0,0,125)  , SFML.Color(0,0,125)])

roadColor(colors::RoadTypeColors, road::Road) = colors.typecolors[road.roadType]

"""
    `SpeedColors` colors road given their speed.
"""
type SpeedColors <: VizColors
    "Time of each road"
    roadtimes::AbstractArray{Float64,2}
    "speed corresponding to darkest color"
    minSpeed::Float64
    "speed corresponding to lightest color"
    maxSpeed::Float64
    "color palette"
    palette::Vector{Colors.RGB{Float64}}
end

function SpeedColors(network::Network, roadtimes::AbstractArray{Float64,2};
                     speedRange::Tuple{Real, Real} = (0,0))
    minSpeed, maxSpeed = speedRange
    minSpeed = float(minSpeed); maxSpeed = float(maxSpeed)

    # if not given, minSpeed is the minimal speed in network
    if minSpeed == maxSpeed
        minSpeed, maxSpeed = Inf, -Inf
        for ((o,d),r) in network.roads
            s = r.distance/roadtimes[o,d]
            s < minSpeed && (minSpeed = s)
            s > maxSpeed && (maxSpeed = s)
        end
        if minSpeed == maxSpeed
            minSpeed *= 0.99
        end
    end

    palette = Colors.colormap("Reds")
    return SpeedColors(roadtimes, minSpeed, maxSpeed, palette)
end

SpeedColors(routing::RoutingPaths; args...) =
SpeedColors(routing.network, routing.times; args...)

function roadColor(colors::SpeedColors, road::Road)
    s = road.distance/colors.roadtimes[road.orig, road.dest]
    c = round(Int,max(0, min(1, (colors.maxSpeed-s)/(colors.maxSpeed-colors.minSpeed))) * (length(colors.palette)-1)) +1

    color = colors.palette[c]
    return SFML.Color(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b))
end
