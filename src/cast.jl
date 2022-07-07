function multigeom_to_geom(x::DataFrame)
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end
    
    geom_type = st_geomtype(x)

    if geom_type === AG.wkbGeometryCollection
        error("GeometryCollections currently not supported")
    end

    collection = DataFrames.DataFrame()

    @showprogress for row in eachrow(x)
        geometry = row.geom
        n = AG.ngeom(geometry)

        geom_list = [AG.getgeom(geometry,i) for i in 0:(n-1)]
        new_df = DataFrames.select(repeat(DataFrames.DataFrame(row), n), Not(:geom))
        new_df[:,:geom] = geom_list
        append!(collection, new_df)
    end

    replace_metadata!(collection, x)
    st_set_geomtype(collection, AG.getgeomtype(collection.geom[1]))

    return collection
end

function _geom_to_multi(x::DataFrame)    
    geom_type = st_geomtype(x)

    if geom_type in [AG.IGeometry{AG.wkbMultiLineString},AG.IGeometry{AG.wkbMultiPoint},AG.IGeometry{AG.wkbMultiPolygon}]
        return "Multigeometries not allowed. Check out 'st_union' to combine"
    elseif geom_type == AG.wkbLineString
        multigeom = AG.createmultilinestring()
    elseif geom_type == AG.wkbPoint
        multigeom = AG.createmultipoint()
    elseif geom_type == AG.wkbPolygon
        multigeom = AG.createmultipolygon()
    end

    for row in eachrow(x)
        geometry = row.geom
        AG.addgeom!(multigeom, geometry)
    end

    new_df = DataFrames.select(DataFrames.DataFrame(x[1,:]), Not(:geom))
    new_df[:,:geom] = [multigeom]

    replace_metadata!(new_df, x)
    st_set_geomtype(new_df, AG.getgeomtype(new_df.geom[1]))

    return new_df
end


function geom_to_multigeom(x::DataFrame, groupid::String)
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end

    if !(groupid in names(x))
        error("groupid does not match any column names")
    end
    
    if groupid === nothing
        println("WARNING: No groupid provided. First attributes used.")
        return _geom_to_multi(x)
    end

    new_df = DataFrames.DataFrame()
    @showprogress for df in groupby(x, groupid)
        append!(new_df, _geom_to_multi(DataFrames.DataFrame(df)))
    end
    
    return new_df
end

function geom_to_multigeom(x::DataFrame)
    println("WARNING: No groupid provided. First attributes used.")
    return _geom_to_multi(x)
end

function linestring_to_multipoint(x::DataFrame)
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end

    geom_type = st_geomtype(x)

    if geom_type !== AG.wkbLineString
        error("Only LineStrings allowed")
    end

    geom_list = Vector{AG.IGeometry{AG.wkbMultiPoint}}()

    for row in eachrow(x)
        multigeom = AG.createmultipoint()
        geometry = row.geom
        for i in 0:(AG.ngeom(geometry)-1)
            pt = AG.getgeom(geometry,i)
            AG.addgeom!(multigeom, pt)
        end

        push!(geom_list, multigeom)
    end
    
    new_df = DataFrames.select(x, Not(:geom))
    new_df[:,:geom] = geom_list

    replace_metadata!(new_df, x)
    st_set_geomtype(new_df, AG.getgeomtype(new_df.geom[1]))

    return new_df
end