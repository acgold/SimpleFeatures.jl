# Define sfdf type
mutable struct SimpleFeature
    df::DataFrame
    crs::GFT.GeoFormat
    geomtype::AG.OGRwkbGeometryType
end

Base.:(==)(a::SimpleFeature, b::SimpleFeature) = a.df == b.df && a.crs == b.crs && a.geomtype == b.geomtype

# Define printing behavior 
function Base.show(io::IO, x::SimpleFeature)
    ds = displaysize(io)

    printstyled(io, "SimpleFeature" * "\n", bold=true)
    println(io, "---------")

    printstyled(io, "geomtype:  "; color=:yellow)
    println(io, x.geomtype)

    if length(x.crs.val) < 100
        printstyled(io, "crs:   "; color=:yellow)
        println(io, x.crs.val)
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.Base.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    elseif length(x.crs.val) >= 100
        printstyled(io, "crs:       "; color=:yellow)
        println(io, x.crs.val[1:100] * "...")
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.Base.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    else
        println(io, "NO CRS INFO")
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.Base.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    end
end

"""
    df_to_sf(x::DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)

Convert a DataFrame containing a column of ArchGDAL geometries to a new SimpleFeature object. 
"""
function df_to_sf(x::DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)
    geom_list = []

    geom_type = AG.getgeomtype(x[1,geom_column])

    for geom in x[:,geom_column]
        push!(geom_list, gdal_to_sfgeom(geom))
    end

    new_df = DataFrames.select(x, Not(geom_column))
    new_df[:, geom_column] = geom_list

    return SimpleFeature(new_df, crs, geom_type)
end