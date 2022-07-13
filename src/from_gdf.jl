## Code within this file is from the GeoDataFrames.jl package or directly adapted from it (https://github.com/evetion/GeoDataFrames.jl). 
## Re-used functionality:
##      - `reexport` macro and associated AG methods
##      -  AG drivers
##      -  stringlist
## Modified functions:
##      - st_read (modified from `read`)
##      - st_write (modified from `write`)
## See the below MIT license for GDF code
## -----------------------------------------
## MIT License
##
## Copyright (c) 2020 Maarten Pronk <git@evetion.nl>, Julia Computing and contributors
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
## -----------------------------------------

# GDF: Taken from https://github.com/simonster/Reexport.jl/blob/master/src/Reexport.jl by https://github.com/simonster
# GDF: As no release has been made yet: https://github.com/simonster/Reexport.jl/pull/23
macro reexport(ex)
    isa(ex, Expr) && (ex.head == :module ||
                      ex.head == :using ||
                      (ex.head == :toplevel &&
                       all(e -> isa(e, Expr) && e.head == :using, ex.args))) ||
        error("@reexport: syntax error")

    if ex.head == :module
        modules = Any[ex.args[2]]
        ex = Expr(:toplevel, ex, :(using .$(ex.args[2])))
    elseif ex.head == :using && all(e -> isa(e, Symbol), ex.args)
        modules = Any[ex.args[end]]
    elseif ex.head == :using && ex.args[1].head == :(:)
        symbols = [e.args[end] for e in ex.args[1].args[2:end]]
        return esc(Expr(:toplevel, ex, :(eval(Expr(:export, $symbols...)))))
    else
        modules = Any[e.args[end] for e in ex.args]
    end

    esc(Expr(:toplevel, ex,
        [:(eval(Expr(:export, names($mod)...))) for mod in modules]...))
end


# @reexport using ArchGDAL: intersects, equals, disjoint, touches, crosses, within, contains, overlaps
# @reexport using ArchGDAL: boundary, convexhull, buffer
# @reexport using ArchGDAL: intersection, union, difference, symdifference, distance
# @reexport using ArchGDAL: geomlength, geomarea, centroid
# @reexport using ArchGDAL: isvalid, issimple, isring, geomarea, centroid
# @reexport using ArchGDAL: createpoint, createlinestring, createlinearring, createpolygon, createmultilinestring, createmultipolygon
# @reexport using ArchGDAL: reproject

# AG.intersects(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.intersects.(a, b)
# AG.equals(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.equals.(a, b)
# AG.disjoint(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.disjoint.(a, b)
# AG.touches(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.touches.(a, b)
# AG.crosses(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.crosses.(a, b)
# AG.within(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.within.(a, b)
# AG.contains(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.contains.(a, b)
# AG.overlaps(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.overlaps.(a, b)
# AG.intersection(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.intersection.(a, b)
# AG.union(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.union.(a, b)
# AG.difference(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.difference.(a, b)
# AG.symdifference(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.symdifference.(a, b)
# AG.distance(a::Vector{AG.IGeometry{T}}, b::Vector{AG.IGeometry{X}}) where {X,T} = AG.distance.(a, b)

# AG.boundary(v::Vector{AG.IGeometry{T}}) where {T} = AG.boundary.(v)
# AG.convexhull(v::Vector{AG.IGeometry{T}}) where {T} = AG.convexhull.(v)
# AG.buffer(v::Vector{AG.IGeometry{T}}, d) where {T} = AG.buffer.(v, d)
# AG.transform!(v::Vector{AG.IGeometry{T}}, d) where {T} = AG.buffer.(v, d)
# AG.geomlength(v::Vector{AG.IGeometry{T}}) where {T} = AG.geomlength.(v)
# AG.geomarea(v::Vector{AG.IGeometry{T}}) where {T} = AG.geomarea.(v)
# AG.centroid(v::Vector{AG.IGeometry{T}}) where {T} = AG.centroid.(v)
# AG.isempty(v::Vector{AG.IGeometry{T}}) where {T} = AG.isempty.(v)
# AG.isvalid(v::Vector{AG.IGeometry{T}}) where {T} = AG.isvalid.(v)
# AG.issimple(v::Vector{AG.IGeometry{T}}) where {T} = AG.issimple.(v)
# AG.isring(v::Vector{AG.IGeometry{T}}) where {T} = AG.isring.(v)


const drivers = AG.listdrivers()
const drivermapping = Dict(
    ".shp" => "ESRI Shapefile",
    ".gpkg" => "GPKG",
    ".geojson" => "GeoJSON",
    ".vrt" => "VRT",
    ".csv" => "CSV",
    ".fgb" => "FlatGeobuf",
    ".gml" => "GML",
    ".nc" => "netCDF",
)

const lookup_type = Dict{DataType,AG.OGRwkbGeometryType}(
    AG.GeoInterface.PointTrait => AG.wkbPoint,
    AG.GeoInterface.MultiPointTrait => AG.wkbMultiPoint,
    AG.GeoInterface.LineStringTrait => AG.wkbLineString,
    AG.GeoInterface.LinearRingTrait => AG.wkbMultiLineString,
    AG.GeoInterface.MultiLineStringTrait => AG.wkbMultiLineString,
    AG.GeoInterface.PolygonTrait => AG.wkbPolygon,
    AG.GeoInterface.MultiPolygonTrait => AG.wkbMultiPolygon,
)

function stringlist(dict::Dict{String,String})
    sv = Vector{String}()
    for (k, v) in pairs(dict)
        push!(sv, uppercase(string(k)) * "=" * string(v))
    end
    return sv
end

"""
    st_read(fn::AbstractString; kwargs...)
    st_read(fn::AbstractString, layer::Union{Integer,AbstractString}; kwargs...)

Read a file into a DataFrame. Any kwargs are passed onto ArchGDAL [here](https://yeesian.com/ArchGDAL.jl/stable/reference/#ArchGDAL.read-Tuple{AbstractString}).
By default you only get the first layer, unless you specify either the index (0 based) or name (string) of the layer.
"""
function st_read(fn::AbstractString; kwargs...)
    t = AG.read(fn; kwargs...) do ds
        if AG.nlayer(ds) > 1
            @warn "This file has multiple layers, you only get the first layer by default now."
        end

        return st_read(ds, 0)
    end
    return t
end

function st_read(fn::AbstractString, layer::Union{Integer,AbstractString}; kwargs...)
    t = AG.read(fn; kwargs...) do ds
        return st_read(ds, layer)
    end
    return t
end

function st_read(ds, layer)
    df = AG.getlayer(ds, layer) do table
        if table.ptr == C_NULL
            throw(ArgumentError("Given layer id/name doesn't exist. For reference this is the dataset:\n$ds"))
        end

        crs = GFT.WellKnownText2(toWKT2(AG.getspatialref(table)))
        geomtype = AG.getgeomtype(table)
        df = DataFrame(table)

        sfgeom_list = Vector{sfgeom}()

        for row in eachrow(df)
            push!(sfgeom_list, sfgeom(AG.toWKB(row.geom), preview_wkt_gdal(row.geom)))
        end

        # df = DataFrames.select(df, Not(:geom))
        df[!,:geom] = sfgeom_list

        meta_df = metadata(df)
        meta_df["crs"] = crs; meta_df["geomtype"] = geomtype; meta_df["description"] = "description"

        return df
    end
    "" in names(df) && rename!(df, Dict(Symbol("") => :geometry,))  # needed for now
    return df
end

"""
    st_write(fn::AbstractString, table; layer_name="data", geom_column=:geometry, crs::Union{GFT.GeoFormat,Nothing}=nothing, driver::Union{Nothing,AbstractString}=nothing, options::Vector{AbstractString}=[], geom_columns::Set{Symbol}=(:geometry))

Write the provided `table` to `fn`. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_write(fn::AbstractString, table::DataFrame; layer_name::AbstractString="data", crs::Union{GFT.GeoFormat,Nothing}=nothing, driver::Union{Nothing,AbstractString}=nothing, options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,), kwargs...)
    if(typeof(table.geom[1]) !== sfgeom)
        error("Geometries are not type `sfgeom` and cannot be written with this function")
    end
    
    geom_list = Vector{AG.AbstractGeometry}()

    for row in eachrow(table)
        push!(geom_list, AG.fromWKB(row.geom.wkb))
    end

    new_df = DataFrames.select(table, Not(:geom))
    new_df[:,:geom] = geom_list
    
    rows = Tables.rows(new_df)
    sch = Tables.schema(rows)
    
    if hasmetadata(new_df) === true
        meta_df = metadata(new_df)
        crs = meta_df["crs"]
    elseif crs !== nothing
        crs = crs
    else
        crs = nothing
        println("No crs found!")
    end

    # Determine geometry columns
    isnothing(geom_columns) && error("Please set `geom_columns` or define `GeoInterface.geometrycolumns` for $(typeof(new_df))")
    if :geom_column in keys(kwargs)  # backwards compatible
        geom_columns = (kwargs[:geom_column],)
    end

    geom_types = []
    for geom_column in geom_columns
        trait = AG.GeoInterface.geomtrait(getproperty(first(rows), geom_column))
        geom_type = get(lookup_type, typeof(trait), nothing)
        isnothing(geom_type) && throw(ArgumentError("Can't convert $trait of column $geom_column to ArchGDAL yet."))
        push!(geom_types, geom_type)
    end

    # Set geometry name in options
    if !("geometry_name" in keys(options))
        options["geometry_name"] = "geom"
    end

    # Find driver
    _, extension = splitext(fn)
    if driver !== nothing
        driver = AG.getdriver(driver)
    elseif extension in keys(drivermapping)
        driver = AG.getdriver(drivermapping[extension])
    else
        error("Couldn't determine driver for $extension. Please provide one of $(keys(drivermapping))")
    end

    # Figure out attributes
    fields = Vector{Tuple{Symbol,DataType}}()
    for (name, type) in zip(sch.names, sch.types)
        if !(name in geom_columns)
            AG.GeoInterface.isgeometry(type) && error("Did you mean to use the `geom_columns` argument to specify $name is a geometry?")
            types = Base.uniontypes(type)
            if length(types) == 1
                push!(fields, (Symbol(name), type))
            elseif length(types) == 2 && Missing in types
                push!(fields, (Symbol(name), types[2]))
            else
                error("Can't convert to GDAL type from $type. Please file an issue.")
            end
        end
    end
    AG.create(
        fn,
        driver=driver
    ) do ds
        AG.newspatialref() do spatialref
            crs !== nothing && AG.importCRS!(spatialref, crs)
            AG.createlayer(
                name=layer_name,
                geom=first(geom_types),  # how to set the name though?
                spatialref=spatialref,
                options=stringlist(options)
            ) do layer
                for (i, (geom_column, geom_type)) in enumerate(zip(geom_columns, geom_types))
                    if i > 1
                        AG.writegeomdefn!(layer, string(geom_column), geom_type)
                    end
                end
                for (name, type) in fields
                    AG.createfielddefn(String(name), convert(AG.OGRFieldType, type)) do fd
                        AG.setsubtype!(fd, convert(AG.OGRFieldSubType, type))
                        AG.addfielddefn!(layer, fd)
                    end
                end
                for row in rows
                    AG.createfeature(layer) do feature
                        for (i, (geom_column)) in enumerate(geom_columns)
                            AG.setgeom!(feature, i - 1, convert(AG.IGeometry, getproperty(row, geom_column)))
                        end
                        for (name, _) in fields
                            field = getproperty(row, name)
                            if !ismissing(field)
                                AG.setfield!(feature, AG.findfieldindex(feature, name), getproperty(row, name))
                            else
                                AG.GDAL.ogr_f_setfieldnull(feature.ptr, AG.findfieldindex(feature, name))
                            end
                        end
                    end
                end
                AG.copy(layer, dataset=ds, name=layer_name, options=stringlist(options))
            end
        end
    end
    fn
end

