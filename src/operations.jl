"""
    st_transform(x::SimpleFeature, crs::GFT.GeoFormat; geom_column=:geom, order=:compliant)

Create a new SimpleFeature object that is projected to the provided `crs`.
"""
function st_transform(x::SimpleFeature, crs::GFT.GeoFormat; geom_column=:geom, order=:compliant)::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df[:, geom_column])

    AG.reproject(geom_list, x.crs, crs; order=order)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = gdal_to_sfgeom.(geom_list)

    return SimpleFeature(new_df, crs, x.geomtype)
end

"""
    st_buffer(x::SimpleFeature, d::Number; geom_column=:geom)
    st_buffer(x::SimpleFeature, d::String; geom_column=:geom)

Create a new SimpleFeature object that is buffered by the provided distance `d` in units of the crs. `d` can be a number or a string representing the column of the SimpleFeature DataFrame that contains numbers to use for the buffer distance.
"""
function st_buffer(x::SimpleFeature, d::Number; geom_column=:geom)::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df[:, geom_column])

    buffer_list = AG.buffer.(geom_list, d)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = gdal_to_sfgeom.(buffer_list)

    return SimpleFeature(new_df, x.crs, AG.getgeomtype(buffer_list[1]))
end

function st_buffer(x::SimpleFeature, d::Union{String,Symbol}; geom_column=:geom)::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df[:, geom_column])

    buffer_list = AG.buffer.(geom_list, x.df[:, d])

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = gdal_to_sfgeom.(buffer_list)

    return SimpleFeature(new_df, x.crs, AG.getgeomtype(buffer_list[1]))
end

"""
    st_area(x::SimpleFeature; geom_column=:geom)

Returns a vector of geometry areas in units of the crs.
"""
function st_area(x::SimpleFeature; geom_column=:geom)::Vector
    geom_list = sfgeom_to_gdal.(x.df[:, geom_column])
    return AG.geomarea.(geom_list)
end


"""
    st_segmentize(x::SimpleFeature, max_length::Number; geom_column=:geom)

Create a new SimpleFeature object whose segments have been sliced into segments no larger than the provided `max_length` in units of the crs. See `ArchGDAL.segmentize!` for more info
"""
function st_segmentize(x::SimpleFeature, max_length::Real; geom_column=:geom)::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df[:, geom_column])

    segmented_list = AG.segmentize!.(geom_list, max_length)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[!, geom_column] = gdal_to_sfgeom.(segmented_list)

    return SimpleFeature(new_df, x.crs, x.geomtype)
end

"""
    st_combine(x::SimpleFeature; geom_column=:geom)

Create a new SimpleFeature object that has combined all features into the relevant multigeometry type. No attributes of the original object are returned.
"""
function st_combine(x::SimpleFeature; geom_column=:geom)
    # breakdown into single geoms, then multigeom everything
    if occursin("Multi", string(x.geomtype)) === true
        geom_type = x.geomtype
        idx_from = findfirst(item -> item == (geom_type), decompose_types)
        multi = decompose_names[idx_from]
        single = decompose_names[idx_from+1]

        combined = st_cast(st_cast(x, single), multi; warn=false)
        combined.df = DataFrames.select!(combined.df, :geom)

        return combined

    elseif occursin("Multi", string(x.geomtype)) === false
        geom_type = x.geomtype
        idx_from = findfirst(item -> item == (geom_type), decompose_types)
        multi = decompose_names[idx_from-1]

        combined = st_cast(x, multi; warn=false)
        combined.df = DataFrames.select!(combined.df, :geom)

        return combined
    end
end

"""
    st_bbox(x::SimpleFeature; geom_column=:geom)

Create a bounding box polygon for the provided SimpleFeature object. Resulting polygon is and AG.wkbPolygon type.
"""
function st_bbox(x::SimpleFeature; geom_column=:geom)
    combined_x = st_combine(x)
    geom = sfgeom_to_gdal(combined_x.df[:, geom_column])
    return AG.boundingbox(geom[1])
end