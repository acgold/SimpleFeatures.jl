
"""
df_to_sf(x::DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)

Convert a DataFrame containing a column of ArchGDAL geometries to a new SimpleFeature object. 
"""
function df_to_sf(x::DataFrames.DataFrame, crs::GFT.GeoFormat=GFT.EPSG(4326); geom_column=:geom)
    geom_list = []

    geom_type = AG.getgeomtype(x[1, geom_column])

    for geom in x[:, geom_column]
        push!(geom_list, to_sfgeom(geom))
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
    new_df[!, geom_column] = from_sfgeom(new_df[:, geom_column], to = "archgdal")

    println("CRS: " * x.crs.val)
    println()

    return new_df
end


"""
rasterize(x::SimpleFeature, y::String; filename::String, value::Union{String, Real, Nothing}=nothing, touches::Bool = false,  geom_column = :geom)

Convert a SimpleFeature object to a raster

# Parameters

"""
function rasterize(x::SimpleFeature, y::Union{String, AG.AbstractDataset}; filename::String, scale::Number=1, value::Union{String, Number, Nothing}=nothing, touches::Bool = false, dtype::String = "Float64", nodataval::Number = 0, options::Vector{String}=Vector{String}(["COMPRESS=LZW", "BIGTIFF=YES", "TILED=YES"]),temp_dir::Union{String, Nothing}=nothing, geom_column = :geom)
    geom_list = from_sfgeom(x[:, geom_column], to = "archgdal")

    if typeof(value) === String
        # error("Using a column as a burn in value is not yet supported.")
        if value in names(x.df)
            burn = nothing
        else
            error(":" * value * " not found in column names. Set 'value' to valid column name, 'nothing', or a number")
        end
    elseif (typeof(value) <: Number) === true
        burn = string(value)
    else
        burn = string(1)
    end

    if typeof(y) === String
        rast = AG.read(y)
    else
        rast = y
    end

    driver = AG.extensiondriver(filename)

    if temp_dir === nothing
        ds_path = tempname(SF_tempdir)*".fgb"
    else
        ds_path = temp_dir*".fgb"
    end

    st_write(ds_path, x)

    size = [AG.width(rast), AG.height(rast)]
    geotransform = AG.getgeotransform(rast)

    minx = geotransform[1]
    miny = geotransform[4]
    maxx = minx + (geotransform[2] * size[1])
    maxy = miny + (geotransform[6] * size[2])    

    gdal_kws = ["-of", driver,  # Save as geotiff 
                "-te", string(minx), string(miny), string(maxx), string(maxy),   # Define image extent 
                "-ts", string(size[1]/scale), string(size[2]/scale),
                "-a_nodata", string(nodataval),
                "-ot", dtype
                ]  

    if touches === true
        push!(gdal_kws, "-at")
    end

    if burn === nothing
        push!(gdal_kws, "-l", "data")
        push!(gdal_kws, "-a", value)
    else
        push!(gdal_kws, "-burn", burn)
    end

    if length(options) > 0
        push!(gdal_kws, "-co", join(options, " ")) 
    end

    if temp_dir === nothing
        AG.gdalrasterize(AG.read(ds_path), gdal_kws) do ds_raster
            AG.write(ds_raster, filename)
        end
    else
        AG.gdalrasterize(AG.read(ds_path), gdal_kws; dest = tempname(temp_dir)) do ds_raster
            AG.write(ds_raster, filename)
        end
    end

    println("New raster at: \n"* filename)
    return 
end

# y = AG.read("/Users/adam/Documents/GitHub/htf-nc-commuting/data/NOAA_SLR_DEM.tif")
# filename = "/Users/adam/Documents/GitHub/htf-nc-commuting/data/testrasterize.tif"
# x = st_read("/Volumes/my_hd/osrm/nc_road_lines_proj_buff.gpkg")
# x = st_read("/Volumes/my_hd/osrm/nc_road_lines_proj.gpkg")
# y = "/Volumes/my_hd/htf_on_roads/noaa_elevation/water_level_modelling/zero_to_point4/class_error.tif"
# filename = "/Volumes/my_hd/osrm/nc_buff_roads.tif"
# value = "way_id"

# SF.rasterize(x, y, filename=filename, value = value, dtype = "Int64")
# rasterize(x, y, filename = "/Volumes/my_hd/osrm/buff_roads.tif", value = 1, dtype="Int16")