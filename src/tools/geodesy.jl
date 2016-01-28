###################################################
## geodesy.jl
## fork of some code in geodesy.jl
###################################################

### Ellipsoid
# Specify datum for translation between LLA and other coordinate systems
immutable Ellipsoid
    a::Float64        # Semi-major axis
    b::Float64        # Semi-minor axis
    e²::Float64       # Eccentricity squared
    e′²::Float64      # Second eccentricity squared
end

function Ellipsoid(; a::AbstractString="", b::AbstractString="", f_inv::AbstractString="")
    if isempty(a) || isempty(b) == isempty(f_inv)
        throw(ArgumentError("Specify parameter 'a' and either 'b' or 'f_inv'"))
    end
    if isempty(b)
        _ellipsoid_af(parse(BigFloat,a), parse(BigFloat,f_inv))
    else
        _ellipsoid_ab(parse(BigFloat,a), parse(BigFloat,b))
    end
end

function _ellipsoid_ab(a::BigFloat, b::BigFloat)
    e² = (a^2 - b^2) / a^2
    e′² = (a^2 - b^2) / b^2

    Ellipsoid(a, b, e², e′²)
end
function _ellipsoid_af(a::BigFloat, f_inv::BigFloat)
    b = a * (1 - inv(f_inv))

    _ellipsoid_ab(a, b)
end

### World Geodetic Coordinate System of 1984 (WGS 84)
# Standardized coordinate system for Earth
# Global ellipsoidal reference surface
const WGS84  = Ellipsoid(a = "6378137.0", f_inv = "298.257223563")

### Point in Latitude-Longitude-Altitude (LLA) coordinates
# Used to store node data in OpenStreetMap XML files
immutable LLA
    lat::Float64
    lon::Float64
    alt::Float64
end
LLA(lat, lon) = LLA(lat, lon, 0.0)

### Point in Earth-Centered-Earth-Fixed (ECEF) coordinates
# Global cartesian coordinate system rotating with the Earth
immutable ECEF
    x::Float64
    y::Float64
    z::Float64
end

### Point in East-North-Up (ENU) coordinates
# Local cartesian coordinate system
# Linearized about a reference point
immutable ENU
    east::Float64
    north::Float64
    up::Float64
end
ENU(x, y) = ENU(x, y, 0.0)


# Given a reference point for linarization
function ENU(lla::LLA, lla_ref::LLA, datum::Ellipsoid = WGS84)
    ecef = ECEF(lla, datum)
    return ENU(ecef, lla_ref, datum)
end

###############################
### LLA to ECEF coordinates ###
###############################

function ECEF(lla::LLA, datum::Ellipsoid = WGS84)
    ϕdeg, λdeg, h = lla.lat, lla.lon, lla.alt
    d = datum

    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)
    sinλ, cosλ = sind(λdeg), cosd(λdeg)

    N = d.a / sqrt(1 - d.e² * sinϕ^2)  # Radius of curvature (meters)

    x = (N + h) * cosϕ * cosλ
    y = (N + h) * cosϕ * sinλ
    z = (N * (1 - d.e²) + h) * sinϕ

    return ECEF(x, y, z)
end

function ENU(ecef::ECEF, lla_ref::LLA, datum::Ellipsoid = WGS84)
    ϕdeg, λdeg = lla_ref.lat, lla_ref.lon

    ecef_ref = ECEF(lla_ref, datum)
    ∂x = ecef.x - ecef_ref.x
    ∂y = ecef.y - ecef_ref.y
    ∂z = ecef.z - ecef_ref.z

    # Compute rotation matrix
    sinλ, cosλ = sind(λdeg), cosd(λdeg)
    sinϕ, cosϕ = sind(ϕdeg), cosd(ϕdeg)

    # R = [     -sinλ       cosλ  0.0
    #      -cosλ*sinϕ -sinλ*sinϕ cosϕ
    #       cosλ*cosϕ  sinλ*cosϕ sinϕ]
    #
    # east, north, up = R * [∂x, ∂y, ∂z]
    east  = ∂x * -sinλ      + ∂y * cosλ       + ∂z * 0.0
    north = ∂x * -cosλ*sinϕ + ∂y * -sinλ*sinϕ + ∂z * cosϕ
    up    = ∂x * cosλ*cosϕ  + ∂y * sinλ*cosϕ  + ∂z * sinϕ

    return ENU(east, north, up)
end
