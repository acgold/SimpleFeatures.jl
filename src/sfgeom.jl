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

# functions for parsing WKT from GDAL and GEOS for preview
function preview_wkt_gdal(x::AG.AbstractGeometry, n::Int=25)
    wkt = AG.toWKT(x)
    return wkt[1:min(length(wkt), n)] * "..."
end

# function preview_wkt_geos(x::LibGEOS.AbstractGeometry, n::Int=25)
#     wkt = LibGEOS.writegeom(x)
#     return wkt[1:min(length(wkt),n)] * "..."
# end

# convert sfgeom type to GDAL, and reverse
function sfgeom_to_gdal(x::Vector{sfgeom})
    geom_list = Vector{AG.AbstractGeometry}()

    for i in x
        push!(geom_list, AG.fromWKB(i.wkb))
    end

    return geom_list
end

function sfgeom_to_gdal(x::sfgeom)
    return AG.fromWKB(x.wkb)
end

function gdal_to_sfgeom(x::Vector{AG.AbstractGeometry})
    geom_list = Vector{sfgeom}()

    for i in x
        push!(geom_list, sfgeom(AG.toWKB(i), preview_wkt_gdal(i)))
    end

    return geom_list
end

function gdal_to_sfgeom(x::AG.AbstractGeometry)
    return sfgeom(AG.toWKB(x), preview_wkt_gdal(x))
end

# # convert sfgeom type to GEOS, and reverse
# function sfgeom_to_geos(x::Vector{sfgeom})
#     geom_list = Vector{LibGEOS.AbstractGeometry}()

#     for i in x
#         push!(geom_list, LibGEOS.readgeom(i.wkb))
#     end

#     return geom_list
# end

# function sfgeom_to_geos(x::sfgeom)
#     return LibGEOS.readgeom(x.wkb)
# end

# function geos_to_sfgeom(x::Vector{LibGEOS.AbstractGeometry})
#     geom_list = Vector{sfgeom}()

#     for i in x
#         push!(geom_list, sfgeom(LibGEOS.writegeom(i, LibGEOS.WKBWriter(LibGEOS._context)), preview_wkt_geos(i)))
#     end

#     return geom_list
# end

# function geos_to_sfgeom(x::LibGEOS.AbstractGeometry)
#     return sfgeom(LibGEOS.writegeom(x, LibGEOS.WKBWriter(LibGEOS._context)), preview_wkt_geos(x))
# end
