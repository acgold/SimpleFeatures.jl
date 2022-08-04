module SimpleFeatures

import ArchGDAL as AG
using DataFrames
using Tables
import GeoFormatTypes as GFT
using GeoInterface
using JSON
using DataFramesMeta
using Lazy
using LibGEOS
using RecipesBase
using ColorSchemes

include("simplefeature.jl")
include("sfgeom.jl")
include("from_gdf.jl")

include("utils.jl")
include("cast.jl")
include("conversions.jl")
include("measure.jl")
include("misc.jl")
include("nearest.jl")
include("predicates.jl")
include("geo_ops.jl")
include("plotting.jl")

end
