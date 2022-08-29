"""
    st_bbox(x::SimpleFeature; geom_column=:geom)

Create a bounding box polygon for the provided SimpleFeature object. Resulting polygon is and AG.wkbPolygon type.
"""
function st_bbox(x::SimpleFeature; geom_column=:geom)
    combined_x = st_combine(x)
    geom = from_sfgeom(combined_x.df[:, geom_column], to = "archgdal")
    return AG.boundingbox(geom[1])
end


"""
    st_transform(x::SimpleFeature, crs::GFT.GeoFormat; geom_column=:geom, order=:compliant)

Create a new SimpleFeature object that is projected to the provided `crs`.
"""
function st_transform(x::SimpleFeature, crs::GFT.GeoFormat; geom_column=:geom, order=:compliant)::SimpleFeature
    geom_list = from_sfgeom.(x.df[:, geom_column], to = "archgdal")

    AG.reproject(geom_list, x.crs, crs; order=order)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = to_sfgeom.(geom_list)

    return SimpleFeature(new_df, crs, x.geomtype)
end



