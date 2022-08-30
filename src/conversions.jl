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
    new_df[!, geom_column] = from_sfgeom(new_df[:, geom_column], to = "gdal")

    println("CRS: " * string(x.crs.val))
    println()

    return new_df
end


"""
    st_rasterize(x::SimpleFeature, y::Union{String, AG.AbstractDataset}; filename::String, scale::Number=1, value::Union{String, Number, Nothing}=nothing, touches::Bool = false, dtype::String = "Float64", nodataval::Number = 0, options::Vector{String}=Vector{String}(["COMPRESS=LZW", "BIGTIFF=YES", "TILED=YES"]),temp_dir::Union{String, Nothing}=nothing, geom_column = :geom)

Convert a SimpleFeature object to a raster file. 

# Parameters
- `x` A SimpleFeature object
- `y` The raster used as a template for rasterization. Either the path to the raster or an ArchGDAL raster dataset.

# Keyword Parameters
- `filename` The output raster path.  The output raster format is derived from the filename extension.
- `scale` Factor to reduce resolution of template raster.
- `value` The value written to the output raster. Either a single number or the string name of a column in the SimpleFeature object.
- `touches` Should the output raster should include "all pixels touched by lines or polygons, not just those on the line render path, or whose center point is within the polygon" - gdal_rasterize (https://gdal.org/programs/gdal_rasterize.html)
- `dtype` Data type of output raster
- `nodataval` Specify the value to be used as NoData in the output raster
- `options` Additional options passed to gdal_rasterize. See [Creation Options](https://gdal.org/drivers/raster/gtiff.html#creation-options) for the desired output raster driver
- `temp_dir` Specify an alternative location to create temporary files while performing rasterization. The default locations are the Scratch space for the SF package and /vsimem/ from GDAL.
- `geom_column` = :geom
"""
function st_rasterize(x::SimpleFeature, y::Union{String, AG.AbstractDataset}; filename::String, scale::Number=1, value::Union{String, Number, Nothing}=nothing, touches::Bool = false, dtype::String = "Float64", nodataval::Number = 0, options::Vector{String}=Vector{String}(["COMPRESS=LZW", "BIGTIFF=YES", "TILED=YES"]),temp_dir::Union{String, Nothing}=nothing, geom_column = :geom)
    geom_list = from_sfgeom(x[:, geom_column], to = "gdal")

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