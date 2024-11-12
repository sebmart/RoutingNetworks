###################################################
## visualization/vizcolors.jl
## colors for visualization
###################################################

"""
    `VizColors` : abstract type that represents the visualization's colors:
    two methods use it: `nodeColor` and `roadColor`, that are made to be overriden
"""
abstract type VizColors end

"""
    `nodeColor` returns a node's color.
"""
nodeColor(colors::VizColors, node::Node) = sfColor_fromRGB(0,0,0)

"""
    `roadColor` returns a road's color
"""
roadColor(colors::VizColors, road::Road) = sfColor_fromRGB(50,50,255)

function Base.show(io::IO, viz::VizColors)
    typeName = split(string(typeof(viz)),".")[end]
    println(io,"Visualization Colors: $(typeName)")
end



"""
    `RoadTypeColors` is a road-type based coloring scheme
"""
mutable struct RoadTypeColors <: VizColors
    typecolors::Vector{sfColor}
end

RoadTypeColors() = RoadTypeColors(
        [sfColor_fromRGB(0,255,0), sfColor_fromRGB(55,200,0), sfColor_fromRGB(105,150,0),
         sfColor_fromRGB(150,105,0), sfColor_fromRGB(0,0,125) , sfColor_fromRGB(0,0,125)  ,
         sfColor_fromRGB(0,0,125)  , sfColor_fromRGB(0,0,125)])

roadColor(colors::RoadTypeColors, road::Road) = colors.typecolors[road.roadType]

"""
    `FadedColors` is just road-type with custom transparency
"""
mutable struct FadedColors <: VizColors
    typecolors::Vector{sfColor}
    transp::Int
end
nodeColor(colors::FadedColors, node::Node) = sfColor(0,0,0, colors.transp)

function FadedColors(transp)
    a = round(Int, transp*255)
    FadedColors(
        [sfColor(0,255,0, a)  , sfColor(55,200,0, a), sfColor(105,150,0, a),
         sfColor(150,105,0, a), sfColor(0,0,125, a) , sfColor(0,0,125, a)  ,
         sfColor(0,0,125, a)  , sfColor(0,0,125, a)], a)
end
roadColor(colors::FadedColors, road::Road) = colors.typecolors[road.roadType]


"""
    `RoutingColors` colors that use road speed information.
    Must have a `roadtimes` attribute.
"""
abstract type RoutingColors <: VizColors end

"""
    `SpeedColors` colors road given their speed. Good for black and white printing
"""
mutable struct SpeedColors <: RoutingColors
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
    c = round(Int,max(0, min(1, (s - colors.minSpeed)/(colors.maxSpeed-colors.minSpeed))) * (length(colors.palette)-1)) +1

    color = colors.palette[c]
    return sfColor_fromRGB(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b))
end

"""
    `RelativeSpeedColors` colors road given set of reference times.
"""
mutable struct RelativeSpeedColors <: RoutingColors
    "Time of each road"
    roadtimes::AbstractArray{Float64,2}
    "reference time of each road"
    reftimes::AbstractArray{Float64,2}
    "color palette for slow roads"
    slowpalette::Vector{Colors.RGB{Float64}}
    "color palette for fast roads"
    fastpalette::Vector{Colors.RGB{Float64}}
    "ratio to baseline corresponding to extremes of color palette"
    maxRatio::Float64
end

function RelativeSpeedColors(network::Network,
                             roadtimes::AbstractArray{Float64,2},
                             reftimes::AbstractArray{Float64,2} = meanTimes(network, roadtimes);
                             maxRatio::Real=3)
    maxRatio = float(maxRatio)
    slow = HSL(0,1.,.3)
    normal = HSL(60, .5, 0.8)
    fast =  HSL(120,0.7,.5)
    slowpalette = linspace(normal, slow)
    fastpalette = linspace(normal, fast)
    return RelativeSpeedColors(roadtimes, reftimes, slowpalette, fastpalette, maxRatio)
end
RelativeSpeedColors(r::RoutingPaths, reftimes::AbstractArray{Float64,2} = meanTimes(r.network, r.times); args...) =
RelativeSpeedColors(r.network, r.times, reftimes; args...)


"""
    `meanTimes` return times corresponding to mean speed.
"""
function meanTimes(network::Network, roadtimes::AbstractArray{Float64,2})
    totalTime = 0.
    totalDist = 0.
    for e in edges(network.graph)   
        o = src(first(e)), dst(first(e))
        totalTime += roadtimes[o, d]
        totalDist += network.roads[o, d].distance
    end

    meanspeed = totalDist/totalTime
    reftimes = spzeros(nv(network.graph),nv(network.graph))
    for road in values(network.roads)
        reftimes[road.orig, road.dest] = road.distance/meanspeed
    end
    return reftimes
end


function roadColor(colors::RelativeSpeedColors, road::Road)
    speedratio = colors.roadtimes[road.orig, road.dest]/colors.reftimes[road.orig, road.dest]
    if speedratio >= 1
        palette = colors.slowpalette
    else
        palette = colors.fastpalette
        speedratio = 1/speedratio
    end

    paletteBin = round(Int, 1 + (length(palette)-1) * (min(speedratio,colors.maxRatio) - 1) / (colors.maxRatio - 1))
    color = palette[paletteBin]
    return sfColor_fromRGB(round(Int,color.r*255),round(Int,255*color.g),round(Int,255*color.b))
end
