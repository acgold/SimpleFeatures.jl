"""
    st_transform(x::DataFrame, crs::GFT.GeoFormat; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))

Create a new `DataFrame` that is projected to the provided `crs`. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_transform(x::SimpleFeature, crs::GFT.GeoFormat; geom_columns=(:geom,), src_crs::Union{Nothing, GFT.GeoFormat}=nothing, order=:compliant)::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df.geom)

    AG.reproject(geom_list, x.crs, crs; order=order)

    new_df = DataFrames.select(x.df, Not(:geom))
    new_df[:,:geom] = gdal_to_sfgeom.(geom_list)

    return SimpleFeature(new_df, crs, x.geomtype)
end

"""
    st_buffer(x::DataFrame, d::Number; geom_columns=(:geom,))

Create a new `DataFrame` that is buffered by the provided distance `d` in units of the crs. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_buffer(x::SimpleFeature, d::Number; geom_columns=(:geom,))::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df.geom)

    buffer_list = AG.buffer.(geom_list, d)

    new_df = DataFrames.select(x.df, Not(:geom))
    new_df[!,:geom] = gdal_to_sfgeom.(buffer_list)
        
    return SimpleFeature(new_df, x.crs, AG.getgeomtype(buffer_list[1]))
end

"""
    st_area(x::SimpleFeature; geom_columns=(:geom,))

Returns a vector of geometry areas in units of the crs. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_area(x::SimpleFeature)::Vector
    geom_list = sfgeom_to_gdal.(x.df.geom)
    return AG.geomarea.(geom_list)
end


"""
    st_segmentize(x::DataFrame, max_length::Number; geom_columns=(:geom,))

Create a new `DataFrame` that contains LineString geometries that have been sliced into lines of `max_length`. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_segmentize(x::SimpleFeature, max_length::Number; geom_columns=(:geom,))::SimpleFeature
    geom_list = sfgeom_to_gdal.(x.df.geom)

    segmented_list = AG.segmentize!.(geom_list, max_length)

    new_df = DataFrames.select(x.df, Not(:geom))
    new_df[!,:geom] = gdal_to_sfgeom.(segmented_list)
    
    return SimpleFeature(new_df, x.crs, x.geomtype)
end

"""
    st_combine(x::DataFrame; geom_columns=(:geom,))

Create a new SimpleFeature object that has combined all features into the relevant multigeometry type. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_combine(x::SimpleFeature)
    # breakdown into single geoms, then multigeom everything
    if occursin("Multi", string(x.geomtype)) === true
        geom_type = x.geomtype
        idx_from = findfirst(item -> item ==(geom_type), decompose_types)
        multi = decompose_names[idx_from]
        single = decompose_names[idx_from + 1]
    
        return st_cast(st_cast(x, single), multi; warn=false)

    elseif occursin("Multi", string(x.geomtype)) === false
        geom_type = x.geomtype
        idx_from = findfirst(item -> item ==(geom_type), decompose_types)
        multi = decompose_names[idx_from - 1]
    
        return st_cast(x, multi; warn=false)
    end
end