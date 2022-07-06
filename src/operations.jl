"""
    st_copy(fn::AbstractString, table; layer_name="data", geom_column=:geometry, crs::Union{GFT.GeoFormat,Nothing}=nothing, driver::Union{Nothing,AbstractString}=nothing, options::Vector{AbstractString}=[], geom_columns::Set{Symbol}=(:geometry))

Copy the provided `table` to `fn`. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_copy(table::DataFrame; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,), kwargs...)    
    rows = Tables.rows(table)
    sch = Tables.schema(rows)
    
    if hasmetadata(table) === true
        meta_df = metadata(table)
        crs = meta_df["crs"]
    elseif crs !== nothing
        crs = crs
    else
        crs = nothing
        println("No crs found!")
    end

    # Determine geometry columns
    isnothing(geom_columns) && error("Please set `geom_columns` or define `GeoInterface.geometrycolumns` for $(typeof(table))")
    if :geom_column in keys(kwargs)  # backwards compatible
        geom_columns = (kwargs[:geom_column],)
    end

    geom_types = []
    for geom_column in geom_columns
        trait = AG.GeoInterface.geomtrait(getproperty(first(rows), geom_column))
        geom_type = get(lookup_type, typeof(trait), nothing)
        isnothing(geom_type) && throw(ArgumentError("Can't convert $trait of column $geom_column to ArchGDAL yet."))
        push!(geom_types, geom_type)
    end

    # Set geometry name in options
    if !("geometry_name" in keys(options))
        options["geometry_name"] = "geom"
    end

    # Find driver
    if driver !== nothing
        driver = AG.getdriver(driver)
    elseif extension in keys(drivermapping)
        driver = AG.getdriver(drivermapping[extension])
    else
        error("Couldn't determine driver for $extension. Please provide one of $(keys(drivermapping))")
    end

    # Figure out attributes
    fields = Vector{Tuple{Symbol,DataType}}()
    for (name, type) in zip(sch.names, sch.types)
        if !(name in geom_columns)
            AG.GeoInterface.isgeometry(type) && error("Did you mean to use the `geom_columns` argument to specify $name is a geometry?")
            types = Base.uniontypes(type)
            if length(types) == 1
                push!(fields, (Symbol(name), type))
            elseif length(types) == 2 && Missing in types
                push!(fields, (Symbol(name), types[2]))
            else
                error("Can't convert to GDAL type from $type. Please file an issue.")
            end
        end
    end

    # create fn if not supplied
    if fn === nothing
        fn = joinpath(workspace, string(uuid4()) * ".gpkg")
    end

    AG.create(
        fn,
        driver=driver
    ) do ds
        AG.newspatialref() do spatialref
            crs !== nothing && AG.importCRS!(spatialref, crs)
            AG.createlayer(
                name=layer_name,
                geom=first(geom_types),  # how to set the name though?
                spatialref=spatialref,
                options=stringlist(options)
            ) do layer
                for (i, (geom_column, geom_type)) in enumerate(zip(geom_columns, geom_types))
                    if i > 1
                        AG.writegeomdefn!(layer, string(geom_column), geom_type)
                    end
                end
                for (name, type) in fields
                    AG.createfielddefn(String(name), convert(AG.OGRFieldType, type)) do fd
                        AG.setsubtype!(fd, convert(AG.OGRFieldSubType, type))
                        AG.addfielddefn!(layer, fd)
                    end
                end
                for row in rows
                    AG.createfeature(layer) do feature
                        for (i, (geom_column)) in enumerate(geom_columns)
                            AG.setgeom!(feature, i - 1, convert(AG.IGeometry, getproperty(row, geom_column)))
                        end
                        for (name, _) in fields
                            field = getproperty(row, name)
                            if !ismissing(field)
                                AG.setfield!(feature, AG.findfieldindex(feature, name), getproperty(row, name))
                            else
                                AG.GDAL.ogr_f_setfieldnull(feature.ptr, AG.findfieldindex(feature, name))
                            end
                        end
                    end
                end
                AG.copy(layer, dataset=ds, name=layer_name, options=stringlist(options))
            end
        end
    end
    
    return st_read(fn)
end

"""
    st_transform(x::DataFrame, crs::GFT.GeoFormat; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))

Create a new `DataFrame` that is projected to the provided `crs`. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_transform(x::DataFrame, crs::GFT.GeoFormat; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,), src_crs::Union{Nothing, GFT.GeoFormat}=nothing)::DataFrame
    cx = st_copy(x; fn=fn, layer_name=layer_name, driver=driver, options=options, geom_columns=geom_columns)
    
    if st_is_spdf(cx) === true
        cx_crs = st_crs(cx)
    elseif src_crs !== nothing
        cx_crs = src_crs
    else
        error("No crs found! Either add crs to metadata or provide the crs with `src_crs")
    end


    GDF.reproject(cx.geom, cx_crs, crs)  
    st_set_crs(cx, crs)
    return cx
end

"""
    st_buffer(x::DataFrame, d::Number; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))

Create a new `DataFrame` that is buffered by the provided distance `d` in units of the crs. The resulting object is stored in memory as a GeoPackage by default, but a filename `fn` can be provided. The `geom_column` is expected to hold ArchGDAL geometries.
"""
function st_buffer(x::DataFrame, d::Number; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString="data", driver::Union{Nothing,AbstractString}="GPKG", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))::DataFrame
    if st_is_spdf(x) !== true
        error("Input does not contain the required metadata or geometry column")
    end

    cx = st_copy(x; fn=fn, layer_name=layer_name, driver=driver, options=options, geom_columns=geom_columns)

    cx.geom = GDF.buffer(cx.geom, d)
    
    return cx
end