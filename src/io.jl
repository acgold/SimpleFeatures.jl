"""
    st_read_parquet(fn::String; crs::Union{Nothing, GFT.GeoFormat}=nothing, geom_type::Union{Nothing, AG.OGRwkbGeometryType}=nothing, kwargs...)

Read a parquet file into a SimpleFeature object. The crs info must be provided, but planned updates to this function will automatically read crs from the file. The geom_type does not need to be provided, and will be guessed from the first unique value of the first 100 features.
"""
function st_read_parquet(fn::String; crs::Union{Nothing, GFT.GeoFormat}=nothing, geom_type::Union{Nothing, AG.OGRwkbGeometryType}=nothing, kwargs...)
    x = GeoParquet.read(fn; kwargs...)
    columns = Dict(eltype.(eachcol(x)) .=> names(x))
    geom_column = get(columns, GFT.WellKnownBinary{GFT.Geom, Vector{UInt8}}, "geom")
    x[!, geom_column] = to_sfgeom(x[:,geom_column])

    if crs === nothing
        crs = GFT.EPSG(4326)
        @warn "No crs provided, so the output has been assigned EPSG(4326)"
    end

    if geom_type === nothing
        nrows = nrow(x)
        row_index = min(1:nrows, 1:100)
        geom_type = unique(AG.getgeomtype.(from_sfgeom(x[min(1:nrows, 1:100), geom_column], to = "gdal")))[1]
    end

    return SimpleFeature(x, crs, geom_type)
end


"""
    st_write_parquet(fn::AbstractString, x::SimpleFeature)

Write a SimpleFeature object to a parquet file. Geometry columns are automatically found, but only the first one is used.
"""
function st_write_parquet(fn::AbstractString, x::SimpleFeature)
    new_df = deepcopy(x.df)
    geom_column = GeoInterface.geometrycolumns(x)

    new_df[!, geom_column[1]] = from_sfgeom(getproperty(new_df, geom_column[1]), to = "gft.wkb")

    crs = GFT.ProjJSON(toProjJSON(AG.importCRS(x.crs)))

    GeoParquet.write(fn, new_df, geom_column, crs)
end


