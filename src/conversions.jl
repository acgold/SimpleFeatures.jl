
"""
df_to_sf(x::DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)

Convert a DataFrame containing a column of ArchGDAL geometries to a new SimpleFeature object. 
"""
function df_to_sf(x::DataFrames.DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)
    geom_list = []

    geom_type = AG.getgeomtype(x[1, geom_column])

    for geom in x[:, geom_column]
        push!(geom_list, gdal_to_sfgeom(geom))
    end

    new_df = DataFrames.select(x, Not(geom_column))
    new_df[:, geom_column] = geom_list

    return SimpleFeature(new_df, crs, geom_type)
end

"""
sf_to_df(x::SimpleFeature; geom_column=:geom)

Convert a SimpleFeature object to a DataFrame containing a column of ArchGDAL geometries. 
"""
function sf_to_df(x::SimpleFeature; geom_column=:geom)

    new_df = deepcopy(x.df)
    new_df[!, geom_column] = sfgeom_to_gdal(new_df[:, geom_column])

    println("CRS: " * x.crs.val)
    println()

    return new_df
end