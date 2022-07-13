module SimpleFeatures

import ArchGDAL as AG
using DataFrames
using Tables
import GeoFormatTypes as GFT
using GeoInterface
using GDAL
using JSON
using UUIDs
using ProgressMeter
# using LibGEOS

include("sfgeom.jl")
include("from_gdf.jl")
include("metadata.jl")
include("utils.jl")
include("operations.jl")
include("cast.jl")


end
