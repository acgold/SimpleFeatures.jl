"""
    st_transform(x::DataFrame, crs::GFT.GeoFormat; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))

Create a new `DataFrame` that is projected to the provided `crs`. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_transform(x::DataFrame, crs::GFT.GeoFormat; geom_columns=(:geom,), src_crs::Union{Nothing, GFT.GeoFormat}=nothing)::DataFrame
    if st_is_spdf(x) === true
        x_crs = st_crs(x)
    elseif src_crs !== nothing
        x_crs = src_crs
    else
        error("No crs found! Either add crs to metadata or provide the crs with `src_crs")
    end

    geom_list = sfgeom_to_gdal.(x.geom)

    AG.reproject(geom_list, x_crs, crs)

    new_df = DataFrames.select(x, Not(:geom))
    new_df[:,:geom] = gdal_to_sfgeom.(geom_list)

    st_set_crs(new_df, crs)
    return new_df
end

"""
    st_buffer(x::DataFrame, d::Number; geom_columns=(:geom,))

Create a new `DataFrame` that is buffered by the provided distance `d` in units of the crs. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_buffer(x::DataFrame, d::Number; geom_columns=(:geom,))::DataFrame
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end

    geom_list = sfgeom_to_gdal.(x.geom)

    buffer_list = AG.buffer.(geom_list, d)

    new_df = DataFrames.select(x, Not(:geom))
    new_df[!,:geom] = gdal_to_sfgeom.(buffer_list)
        
    return new_df
end

"""
    st_segmentize(x::DataFrame, max_length::Number; geom_columns=(:geom,))

Create a new `DataFrame` that contains LineString geometries that have been sliced into lines of `max_length`. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_segmentize(x::DataFrame, max_length::Number; geom_columns=(:geom,))::DataFrame
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end

    geom_list = sfgeom_to_gdal.(x.geom)

    segmented_list = AG.segmentize!.(geom_list, max_length)

    new_df = DataFrames.select(x, Not(:geom))
    new_df[!,:geom] = gdal_to_sfgeom.(segmented_list)
    
    return new_df
end