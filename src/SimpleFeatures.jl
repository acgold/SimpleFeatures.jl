module SimpleFeatures

import ArchGDAL as AG
using DataFrames
import GeoDataFrames as GDF
using Tables
import GeoFormatTypes as GFT
using GeoInterface
using GDAL
using JSON
using Scratch
using UUIDs
using ProgressMeter

# This will be filled in inside `__init__()`
workspace = ""

function __init__()
    global workspace = @get_scratch!("temp_files")
end

include("from_gdf.jl")
include("metadata.jl")
include("utils.jl")
include("operations.jl")
include("cast.jl")

end
