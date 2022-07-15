module SimpleFeatures

import ArchGDAL as AG
using DataFrames
using Tables
import GeoFormatTypes as GFT
using GeoInterface
using GDAL
using JSON

include("simplefeature.jl")
include("sfgeom.jl")
include("from_gdf.jl")
include("utils.jl")
include("operations.jl")
include("cast.jl")

end
