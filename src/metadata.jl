
"""
st_crs(x::DataFrame)
Extract the crs object from the DataFrame's metadata
"""
function st_crs(x::DataFrame)
if hasmetadata(x)
    return metadata(x)["crs"]
else
    error("No crs found in metadata")
end
end


"""
st_set_crs(x::DataFrame)
Set the crs object within the DataFrame's metadata. Metadata will be created if it does not exist. This does not do any projection and will overwrite any existing crs info. To project to a different crs, see `st_transform`
"""
function st_set_crs(x::DataFrame, crs::GFT.GeoFormat)
    meta_df = DataFrames.metadata(x)
    meta_df["crs"] = crs
    return x
end


"""
st_is_spdf(x::DataFrame)
Return if DataFrame contains crs metadata and geometry column (true) or is missing one or both items.
"""
function st_is_spdf(x::DataFrame)
has_crs = false
has_geom = false

if hasmetadata(x)
    has_crs = haskey(metadata(x), "crs")
end

for col in eachcol(DataFrame(first(x)))
    if GeoInterface.isgeometry(col) === true
        has_geom = true
    end
end

return has_crs && has_geom
end