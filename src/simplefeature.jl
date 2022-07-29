# Define sfdf type
mutable struct SimpleFeature
    df::AbstractDataFrame
    crs::GFT.GeoFormat
    geomtype::AG.OGRwkbGeometryType
end


# Base.getindex(a::SimpleFeature, b) = Base.getindex(a.df, b)

DataFrames.select(df::SimpleFeature, args...; copycols::Bool=true, renamecols::Bool=true) = SimpleFeature(DataFrames.select(df.df, args...; copycols=copycols, renamecols=renamecols), df.crs, df.geomtype)
DataFrames.select!(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.select!(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.transform(df::SimpleFeature, args...; copycols::Bool=true, renamecols::Bool=true) = SimpleFeature(DataFrames.transform(df.df, args...; copycols=copycols, renamecols=renamecols), df.crs, df.geomtype)
DataFrames.transform!(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.transform!(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.combine(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.combine(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.subset(df::SimpleFeature, args...; skipmissing::Bool=false, view::Bool=false) = SimpleFeature(DataFrames.subset(df.df, args...; skipmissing=skipmissing, view=view), df.crs, df.geomtype)
DataFrames.subset!(df::SimpleFeature, args...; skipmissing::Bool=false) = SimpleFeature(DataFrames.subset(df.df, args...; skipmissing=skipmissing), df.crs, df.geomtype)

DataFrames.first(df::SimpleFeature, n::Core.Integer=5) = SimpleFeature(DataFrames.first(df.df, n), df.crs, df.geomtype)
DataFrames.last(df::SimpleFeature, n::Core.Integer=5) = SimpleFeature(DataFrames.last(df.df, n), df.crs, df.geomtype)

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