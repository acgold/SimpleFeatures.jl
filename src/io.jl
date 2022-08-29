"""
    read_parquet(fn::String; crs::Union{Nothing, GFT.GeoFormat}=nothing, geom_type::Union{Nothing, AG.OGRwkbGeometryType}=nothing, kwargs...)

Read a parquet file into a SimpleFeature object. The crs info must be provided, but planned updates to this function will automatically read crs from the file. The geom_type does not need to be provided, and will be guessed from the first unique value of the first 100 features.
"""
function read_parquet(fn::String; crs::Union{Nothing, GFT.GeoFormat}=nothing, geom_type::Union{Nothing, AG.OGRwkbGeometryType}=nothing, kwargs...)
    x = GeoParquet.read(fn; kwargs...)
    columns = Dict(eltype.(eachcol(x)) .=> names(x))
    geom_column = get(columns, GFT.WellKnownBinary{GFT.Geom, Vector{UInt8}}, :geom)
    x[!, geom_column] = to_sfgeom(x[:,geom_column])

    if crs === nothing
        crs = GFT.EPSG(4326)
        @warn "No crs provided, so the output has been assigned EPSG(4326)"
    end

    if geom_type === nothing
        nrows = nrow(x)
        row_index = min(1:nrows, 1:100)
        geom_type = unique(AG.getgeomtype.(from_sfgeom(x[min(1:nrows, 1:100), geom_column], to = "archgdal")))[1]
    end

    return SimpleFeature(x, crs, geom_type)
end


"""
    write_parquet(fn::AbstractString, x::SimpleFeature; geom_column = :geom)

Write a SimpleFeature object to a parquet file. Currently, the geom_colum input variable is ignored and only :geom is a valid column name.
"""
function write_parquet(fn::AbstractString, x::SimpleFeature; geom_column = :geom)
    new_df = deepcopy(x.df)
    new_df[!, geom_column] = from_sfgeom(new_df[:, geom_column], to = "GFT.WellKnownBinary")

    crs = GFT.ProjJSON(toProjJSON(AG.importCRS(x.crs)))

    GeoParquet.write(fn, new_df, (:geom,), crs)
end


