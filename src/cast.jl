function multigeom_to_geom(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    geom_id = "_" * replace(replace(string(geom_type), "multi" => ""), "wkb" => "") * "ID"

    if geom_type === AG.wkbGeometryCollection
        error("GeometryCollections currently not supported")
    end

    collection = DataFrames.DataFrame()

    for row in eachrow(x)
        geometry = row[geom_column]
        n = AG.ngeom(geometry)

        geom_list = [AG.getgeom(geometry, i) for i in 0:(n-1)]
        new_df = deepcopy(repeat(DataFrames.DataFrame(row), n))
        new_df[:, geom_id] = fill(DataFrames.rownumber(row), nrow(new_df))
        new_df[!, geom_column] = geom_list
        DataFrames.select!(new_df, Not(geom_column), geom_column)

        append!(collection, new_df)
    end

    return collection
end

function _geom_to_multi(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    if geom_type in [AG.IGeometry{AG.wkbMultiLineString}, AG.IGeometry{AG.wkbMultiPoint}, AG.IGeometry{AG.wkbMultiPolygon}]
        return "Multigeometries not allowed. Check out 'st_union' to combine"
    elseif geom_type == AG.wkbLineString
        multigeom = AG.createmultilinestring()
    elseif geom_type == AG.wkbPoint
        multigeom = AG.createmultipoint()
    elseif geom_type == AG.wkbPolygon
        multigeom = AG.createmultipolygon()
    end

    for row in eachrow(x)
        geometry = row[geom_column]
        AG.addgeom!(multigeom, geometry)
    end

    new_df = DataFrames.DataFrame(x[1, :])
    new_df[!, geom_column] = [multigeom]
    DataFrames.select!(new_df, Not(geom_column), geom_column)

    return new_df
end


function geom_to_multigeom(x::DataFrame, geom_type::AG.OGRwkbGeometryType, groupid::Union{String,Nothing}=nothing; warn::Union{Bool,Nothing}=true, geom_column=:geom)
    if groupid === nothing
        if warn === true
            println("WARNING: No groupid provided. First attributes used.")
        end
        return _geom_to_multi(x, geom_type; geom_column)
    end

    if !(groupid in names(x))
        error("groupid does not match any column names")
    end

    new_df = DataFrames.DataFrame()
    for df in DataFrames.groupby(x, groupid)
        append!(new_df, _geom_to_multi(DataFrames.DataFrame(df), geom_type; geom_column=geom_column))
    end

    DataFrames.select!(new_df, Not(geom_column), geom_column)

    return new_df
end


function linestring_to_multipoint(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    if geom_type !== AG.wkbLineString
        error("Only LineStrings allowed")
    end

    geom_list = Vector{AG.IGeometry{AG.wkbMultiPoint}}()

    for row in eachrow(x)
        multigeom = AG.createmultipoint()
        geometry = row[geom_column]
        for i in 0:(AG.ngeom(geometry)-1)
            pt = AG.getgeom(geometry, i)
            AG.addgeom!(multigeom, pt)
        end

        push!(geom_list, multigeom)
    end

    new_df = deepcopy(x)
    new_df[!, geom_column] = geom_list
    DataFrames.select!(new_df, Not(geom_column), geom_column)

    return new_df
end

function multipoint_to_linestring(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    if geom_type !== AG.wkbMultiPoint
        error("Only MultiPoints allowed")
    end

    geom_list = Vector{AG.IGeometry{AG.wkbLineString}}()

    for row in eachrow(x)
        linestring = AG.createlinestring()
        geometry = row[geom_column]
        for i in 0:(AG.ngeom(geometry)-1)
            pt = GeoInterface.coordinates(AG.getgeom(geometry, i))
            AG.addpoint!(linestring, pt[1], pt[2])
        end

        push!(geom_list, linestring)
    end

    new_df = deepcopy(x)
    new_df[!, geom_column] = geom_list
    DataFrames.select!(new_df, Not(geom_column), geom_column)

    return new_df
end

function polygon_to_multilinestring(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    if geom_type !== AG.wkbPolygon
        error("Only Polygons allowed")
    end

    geom_list = Vector{AG.IGeometry{AG.wkbMultiLineString}}()

    for row in eachrow(x)
        multilinestring = AG.createmultilinestring()

        nrings = AG.ngeom(row[geom_column])

        for i in 0:(nrings-1)
            linestring = AG.createlinestring()
            linearrings = AG.getgeom(row[geom_column], i)

            for j in 0:(AG.ngeom(linearrings)-1)
                # line = AG.getgeom(linearrings, i)
                pt = GeoInterface.coordinates(AG.getpoint(linearrings, j))
                AG.addpoint!(linestring, pt[1], pt[2])
            end

            AG.addgeom!(multilinestring, linestring)
        end

        push!(geom_list, multilinestring)
    end

    new_df = deepcopy(x)
    new_df[!, geom_column] = geom_list
    DataFrames.select!(new_df, Not(geom_column), geom_column)

    return new_df
end

function linestring_to_linearring(x::AG.IGeometry{AG.wkbLineString})
    linearring = AG.createlinearring()
    for i in 0:(AG.ngeom(x)-1)
        pt = GeoInterface.coordinates(AG.getgeom(x, i))
        AG.addpoint!(linearring, pt[1], pt[2])
    end

    return linearring
end

function multilinestring_to_polygon(x::DataFrame, geom_type::AG.OGRwkbGeometryType; geom_column=:geom)
    if geom_type !== AG.wkbMultiLineString
        error("Only MultiLineStrings allowed")
    end

    geom_list = Vector{AG.IGeometry{AG.wkbPolygon}}()

    ring_warning = false

    for row in eachrow(x)
        polygon = AG.createpolygon()

        nrings = AG.ngeom(row[geom_column])

        for i in 0:(nrings-1)
            ring = linestring_to_linearring(AG.getgeom(row[geom_column], i))

            if GeoInterface.isring(ring) === false
                ring_warning = true
            end

            AG.addgeom!(polygon, ring)
        end

        push!(geom_list, polygon)
    end

    new_df = deepcopy(x)
    new_df[!, geom_column] = geom_list
    DataFrames.select!(new_df, Not(geom_column), geom_column)

    if ring_warning === true
        println("Warning: Some input lines were not valid rings. Polygons may include errors. See `GeoInterface.isring` to find invalid lines")
    end

    return new_df
end


decompose_types = [AG.wkbMultiPolygon, AG.wkbPolygon, AG.wkbMultiLineString, AG.wkbLineString, AG.wkbMultiPoint, AG.wkbPoint]
decompose_names = ["multipolygon", "polygon", "multilinestring", "linestring", "multipoint", "point"]
decompose_functions = ["multigeom_to_geom", "polygon_to_multilinestring", "multigeom_to_geom", "linestring_to_multipoint", "multigeom_to_geom"]

aggregate_types = [AG.wkbPoint, AG.wkbMultiPoint, AG.wkbLineString, AG.wkbMultiLineString, AG.wkbPolygon, AG.wkbMultiPolygon]
aggregate_names = ["point", "multipoint", "linestring", "multilinestring", "polygon", "multipolygon"]
aggregate_functions = ["geom_to_multigeom", "multipoint_to_linestring", "geom_to_multigeom", "multilinestring_to_polygon", "geom_to_multigeom"]

"""
    st_cast(x::SimpleFeature, to::String; groupid::Union{String,Nothing}=nothing, geom_column=:geom, kwargs...)
    
Cast features geometries to the requested type (`to`). See below for the ordered list of `to` values. Supply a `groupid` for aggregating geometries by a variable. Any decomposition from a multigeometry type to a single geometry type will add a unique ID of the multigeometry object as a column (e.g., `_MultiPolygonID`) so the original multigeometry can be re-created later. 

Hierarchy of `to` values:
- "multipolygon"
- "polygon"
- "multilinestring"
- "linestring"
- "multipoint"
- "point"
"""
function st_cast(x::SimpleFeature, to::String; groupid::Union{String,Nothing}=nothing, geom_column=:geom, kwargs...)::SimpleFeature
    geom_type = x.geomtype
    idx_from = findfirst(item -> item == (geom_type), decompose_types)
    idx_to = findfirst(item -> item == (to), decompose_names) - 1

    # If creating new higher level geometries (i.e., points -> linestring)
    if (idx_to - idx_from) < -1
        idx_from = findfirst(item -> item == (geom_type), aggregate_types)
        idx_to = findfirst(item -> item == (to), aggregate_names) - 1
        functions = aggregate_functions[idx_from:idx_to]

        # copy df and convert sfgeoms to AG
        cx = DataFrames.select(x.df, Not(geom_column))
        cx[:, geom_column] = from_sfgeom.(x.df[:, geom_column], to = "gdal")

        if length(functions) === 1
            f = getfield(SimpleFeatures, Symbol(functions[1]))

            if occursin("multigeom", functions[1]) === true
                cx = f(cx, geom_type, groupid; geom_column=geom_column, kwargs...)
                new_geom_type = AG.getgeomtype(cx[1, geom_column])
                cx[!, geom_column] = to_sfgeom.(cx[:, geom_column])

                return SimpleFeature(cx, x.crs, new_geom_type)
            end

            if occursin("multigeom", functions[1]) === false
                cx = f(cx, geom_type; geom_column=geom_column, kwargs...)
                new_geom_type = AG.getgeomtype(cx[1, geom_column])
                cx[!, geom_column] = to_sfgeom.(cx[:, geom_column])

                return SimpleFeature(cx, x.crs, new_geom_type)
            end
        else
            error("Only one transformation step allowed when composing geometries.")
        end

        # If decomposing geometries (i.e., linestring -> points)
    elseif (idx_to - idx_from) >= 0
        functions = decompose_functions[idx_from:idx_to]

        # copy df and convert sfgeoms to AG
        cx = DataFrames.select(x.df, Not(geom_column))
        cx[:, geom_column] = from_sfgeom.(x.df[:, geom_column], to = "gdal")

        if length(functions) < 1
            error("Requested transformation not possible - `st_cast` only decomposes geometries.  See `aggregate` for more.")
        end

        if length(functions) === 1
            f = getfield(SimpleFeatures, Symbol(functions[1]))

            cx = f(cx, geom_type; geom_column=geom_column, kwargs...)
            new_geom_type = AG.getgeomtype(cx[1, geom_column])
            cx[!, geom_column] = to_sfgeom.(cx[:, geom_column])

            return SimpleFeature(cx, x.crs, new_geom_type)
        end

        if length(functions) > 1
            f1 = popfirst!(functions)
            f = getfield(SimpleFeatures, Symbol(f1))

            cx = f(cx, geom_type; geom_column=geom_column, kwargs...)

            for fx in functions
                f = getfield(SimpleFeatures, Symbol(fx))
                cx = f(cx, AG.getgeomtype(cx[1, geom_column]); geom_column=geom_column, kwargs...)
            end

            new_geom_type = AG.getgeomtype(cx[1, geom_column])
            cx[!, geom_column] = to_sfgeom.(cx[:, geom_column])

            return SimpleFeature(cx, x.crs, new_geom_type)
        end

        # if geomtype is the same as the new geomtype requested
    else
        error("`to` is the same geomtype as the input `x`")
    end
end

# For reference
#https://cloud.githubusercontent.com/assets/520851/21387553/5f1edcaa-c778-11e6-92d0-2d735e4c8e40.png