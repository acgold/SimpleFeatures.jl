# Define sfgeom type
mutable struct sfgeom
    wkb::Vector{UInt8}
    preview::String
end

# Define printing behavior to show preview of WKT
function Base.show(io::IO, x::sfgeom)
    print(io, x.preview)
end


function Base.show(io::IO, ::MIME"text/plain", x::Vector{sfgeom})
    x_length = length(x)

    println(io, "Vector of sfgeom Geometries (n = $x_length):")

    if length(x) > 5
        printstyled(io, "First 5 geometries \n"; color=:blue)
        for i in eachindex(x)[1:5]
            println(io, "  ", x[i].preview)
        end

        println()
    else
        for i in eachindex(x)
            println(io, "  ", x[i].preview)
        end
    end
end

# Define equality test
Base.:(==)(a::sfgeom, b::sfgeom) = a.wkb == b.wkb && a.preview == b.preview


# Functions for parsing WKT from GDAL, GEOS, etc for when printing
function preview_wkt(x::AG.AbstractGeometry, n::Int=25)
    wkt = AG.toWKT(x)
    return wkt[1:min(length(wkt), n)] * "..."
end

function preview_wkt(x::LibGEOS.AbstractGeometry, n::Int=25)
    wkt = LibGEOS.writegeom(x)
    return wkt[1:min(length(wkt), n)] * "..."
end


# Functions below convert sfgeom types to/from:
# - gdal (ArchGDAL.jl)
# - geos (LibGEOS.jl)
# - GFT.WellKnownBinary

# Singular conversions to sfgeom
function to_sfgeom(x::sfgeom)
    return x
end

function to_sfgeom(x::GFT.WellKnownBinary{GFT.Geom,Vector{UInt8}})
    return sfgeom(x.val, "WellKnownBinary")
end

function to_sfgeom(x::AG.AbstractGeometry)
    return sfgeom(AG.toWKB(x), preview_wkt(x))
end

function to_sfgeom(x::LibGEOS.AbstractGeometry)
    return sfgeom(LibGEOS.writegeom(x, LibGEOS.WKBWriter(LibGEOS._context)), preview_wkt(x))
end

# Vector conversions to sfgeom
function to_sfgeom(x::Vector{sfgeom})
    return x
end

function to_sfgeom(x::Vector{GFT.WellKnownBinary{GFT.Geom,Vector{UInt8}}})
    geom_list = Vector{sfgeom}()

    for i in x
        push!(geom_list, sfgeom(i.val, "WellKnownBinary"))
    end

    return geom_list
end

function to_sfgeom(x::Vector{AG.AbstractGeometry})
    geom_list = Vector{sfgeom}()

    for i in x
        push!(geom_list, sfgeom(AG.toWKB(i), preview_wkt(i)))
    end

    return geom_list
end

function to_sfgeom(x::Vector{LibGEOS.AbstractGeometry})
    geom_list = Vector{sfgeom}()

    for i in x
        push!(geom_list, sfgeom(LibGEOS.writegeom(i, LibGEOS.WKBWriter(LibGEOS._context)), preview_wkt(i)))
    end

    return geom_list
end


# Singular conversions from sfgeom
function from_sfgeom(x::sfgeom; to::String)
    if lowercase(to) === "gft.wkb"
        return GFT.WellKnownBinary(GFT.Geom(), x.wkb)
    end

    if lowercase(to) === "gdal"
        return AG.fromWKB(x.wkb)
    end

    if lowercase(to) === "geos"
        return LibGEOS.readgeom(x.wkb)
    end
end

# Vector conversions from sfgeom
function from_sfgeom(x::Vector{sfgeom}; to::String)
    if lowercase(to) === "gft.wkb"
        geom_list = Vector{GFT.WellKnownBinary{GFT.Geom,Vector{UInt8}}}()

        for i in x
            push!(geom_list, GFT.WellKnownBinary(GFT.Geom(), i.wkb))
        end

        return geom_list
    end

    if lowercase(to) === "gdal"
        geom_list = Vector{AG.AbstractGeometry}()

        for i in x
            push!(geom_list, AG.fromWKB(i.wkb))
        end

        return geom_list
    end

    if lowercase(to) === "geos"
        geom_list = Vector{LibGEOS.AbstractGeometry}()

        for i in x
            push!(geom_list, LibGEOS.readgeom(i.wkb))
        end

        return geom_list
    end
end