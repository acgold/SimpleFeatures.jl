var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = SimpleFeatures","category":"page"},{"location":"#SimpleFeatures","page":"Home","title":"SimpleFeatures","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"<!– (Image: Stable) –> <!– (Image: Dev) –> (Image: Build Status) (Image: Coverage)","category":"page"},{"location":"#Working-with-simple-feature-GIS-data-in-Julia","page":"Home","title":"Working with simple feature GIS data in Julia","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Fast reading, analyzing, manipulating, and writing vector GIS data in Julia. This package:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Handles operations as a DataFrame (i.e., DataFrame in, DataFrame out)\nStores coordinate reference system (crs) info with the DataFrame and uses it automatically\nInterfaces with GDAL and GEOS (coming soon!) for fast operations","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SimpleFeatures can be installed directly from GitHub using:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(\"https://github.com/acgold/SimpleFeatures.jl.git\")","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"#Load-SimpleFeatures.jl","page":"Home","title":"Load SimpleFeatures.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"import SimpleFeatures as sf","category":"page"},{"location":"#Read-and-write-data","page":"Home","title":"Read & write data","text":"","category":"section"},{"location":"#Read","page":"Home","title":"Read","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"df = sf.st_read(\"data/test.gpkg\")\n\n1000×2 DataFrame\n  Row │ geom                          lyr.1 \n      │ sfgeom                        Int32 \n──────┼─────────────────────────────────────\n    1 │ POLYGON ((853787 3905499,...      1\n    2 │ POLYGON ((853800 3905499,...      1\n    3 │ POLYGON ((853803 3905499,...      1\n  ⋮   │              ⋮                  ⋮\n  998 │ POLYGON ((904045 3905468,...      1\n  999 │ POLYGON ((905355 3905468,...      1\n 1000 │ POLYGON ((905561 3905469,...      1\n                            994 rows omitted","category":"page"},{"location":"#Write","page":"Home","title":"Write","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"df = sf.st_write(\"data/new_test.gpkg\", df)\n\n\"data/new_test.gpkg\"","category":"page"},{"location":"#Metadata","page":"Home","title":"Metadata","text":"","category":"section"},{"location":"#View-metadata-dictionary","page":"Home","title":"View metadata dictionary","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"DataFrames.metadata(df)\n\nDict{String, Any} with 3 entries:\n    \"geomtype\"    => wkbPolygon\n    \"description\" => \"description\"\n    \"crs\"         => WellKnownText2{Unknown}(Unknown(), \"PROJCRS[\\\"NAD83(2011)...","category":"page"},{"location":"#View-crs-info","page":"Home","title":"View crs info","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"sf.st_crs(df)\n\nGeoFormatTypes.WellKnownText2{GeoFormatTypes.Unknown}(GeoFormatTypes.Unknown(), \"PROJCRS[\\\"NAD83(2011) / UTM zone 17N\\\",BASEGEOGCRS[\\\"NAD83(2011)\\\",","category":"page"},{"location":"#View-geometry-type-info","page":"Home","title":"View geometry type info","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"sf.st_geomtype(df)\n\nwkbPolygon::OGRwkbGeometryType = 3","category":"page"},{"location":"#Operations","page":"Home","title":"Operations","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SimpleFeatures offers some basic functions and will offer more in future releases.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Current functionality is:","category":"page"},{"location":"","page":"Home","title":"Home","text":"Casting geometries to different types: sf.st_cast\nBuffering: sf.st_buffer (GDAL. Will be GEOS soon)\nReprojecting: sf.st_transform (GDAL)\nSegmentizing a line: sf.st_segmentize (GDAL)\nConverting between sfgeom objects and GDAL or GEOS (coming soon): sf.sfgeom_to_gdal, sf.gdal_to_sfgeom ","category":"page"},{"location":"#Cast-polygons-to-linestrings","page":"Home","title":"Cast polygons to linestrings","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SimpleFeatures casts each polygon to a multilinestring and then casts those to linestrings. Some polygons had holes (multiple lines per polygon), so the resulting DataFrame has more rows than the original. In cases such as this, SimpleFeatures adds a column of the geometry type + \"ID\" (e.g. _MultiLineStringID) that preserves which multigeometry type the split geometry belonged to.","category":"page"},{"location":"","page":"Home","title":"Home","text":"df.geom # to see original geom\nsf.st_cast(df, \"linestring\")\n\nVector of sfgeom Geometries (n = 1000):\nFirst 5 geometries \n  POLYGON ((853787 3905499,...\n  POLYGON ((853800 3905499,...\n  POLYGON ((853803 3905499,...\n  POLYGON ((853810 3905499,...\n  POLYGON ((857114 3905499,...\n  \n1022×3 DataFrame\n  Row │ lyr.1  _MultiLineStringID  geom                         \n      │ Int32  Int64               sfgeom                       \n──────┼─────────────────────────────────────────────────────────\n    1 │     1                   1  LINESTRING (853787 390549...\n    2 │     1                   2  LINESTRING (853800 390549...\n    3 │     1                   3  LINESTRING (853803 390549...\n  ⋮   │   ⋮            ⋮                        ⋮\n 1020 │     1                 998  LINESTRING (904045 390546...\n 1021 │     1                 999  LINESTRING (905355 390546...\n 1022 │     1                1000  LINESTRING (905561 390546...\n                                               1016 rows omitted","category":"page"},{"location":"#Buffer","page":"Home","title":"Buffer","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"mls_df = sf.st_cast(df, \"multilinestring\") # make a df with multilinestrings so we can see our buffer work\nsf.st_buffer(mls_df, 10) # buffer distance is in units of the crs. Meters in this example\n\n1000×2 DataFrame\n  Row │ lyr.1  geom                         \n      │ Int32  sfgeom                       \n──────┼─────────────────────────────────────\n    1 │     1  MULTILINESTRING ((853787 ...\n    2 │     1  MULTILINESTRING ((853800 ...\n    3 │     1  MULTILINESTRING ((853803 ...\n  ⋮   │   ⋮                 ⋮\n  998 │     1  MULTILINESTRING ((904045 ...\n  999 │     1  MULTILINESTRING ((905355 ...\n 1000 │     1  MULTILINESTRING ((905561 ...\n                            994 rows omitted\n\n1000×2 DataFrame\n  Row │ lyr.1  geom                         \n      │ Int32  sfgeom                       \n──────┼─────────────────────────────────────\n    1 │     1  POLYGON ((853787 3905509,...\n    2 │     1  POLYGON ((853800 3905509,...\n    3 │     1  POLYGON ((853803 3905509,...\n  ⋮   │   ⋮                 ⋮\n  998 │     1  POLYGON ((904045 3905478,...\n  999 │     1  POLYGON ((905355 3905478,...\n 1000 │     1  POLYGON ((905556.66461072...\n                            994 rows omitted","category":"page"},{"location":"#Reproject","page":"Home","title":"Reproject","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"df.geom # to see original geom\nproj_df = sf.st_transform(df, GeoFormatTypes.EPSG(5070))\n\nVector of sfgeom Geometries (n = 1000):\nFirst 5 geometries \n  POLYGON ((853787 3905499,...\n  POLYGON ((853800 3905499,...\n  POLYGON ((853803 3905499,...\n  POLYGON ((853810 3905499,...\n  POLYGON ((857114 3905499,...\n\n1000×2 DataFrame\n  Row │ lyr.1  geom                         \n      │ Int32  sfgeom                       \n──────┼─────────────────────────────────────\n    1 │     1  POLYGON ((1693276.9257186...\n    2 │     1  POLYGON ((1693289.637015 ...\n    3 │     1  POLYGON ((1693292.5703908...\n  ⋮   │   ⋮                 ⋮\n  998 │     1  POLYGON ((1742412.4620032...\n  999 │     1  POLYGON ((1743692.7581942...\n 1000 │     1  POLYGON ((1743893.9246629...\n                            994 rows omitted","category":"page"},{"location":"#How-it-works","page":"Home","title":"How it works","text":"","category":"section"},{"location":"#GIS-data-as-a-DataFrame","page":"Home","title":"GIS data as a DataFrame","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"SimpleFeatures reads vector GIS data from files and creates a DataFrame containing geometries and their attributes. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Each row is a feature, and geometry data for each feature are stored in the geom column. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Example","category":"page"},{"location":"","page":"Home","title":"Home","text":"1000×2 DataFrame\n  Row │ geom                          lyr.1 \n      │ sfgeom                        Int32 \n──────┼─────────────────────────────────────\n    1 │ POLYGON ((853787 3905499,...      1\n    2 │ POLYGON ((853800 3905499,...      1\n    3 │ POLYGON ((853803 3905499,...      1\n  ⋮   │              ⋮                  ⋮\n  998 │ POLYGON ((904045 3905468,...      1\n  999 │ POLYGON ((905355 3905468,...      1\n 1000 │ POLYGON ((905561 3905469,...      1\n                            994 rows omitted","category":"page"},{"location":"#Metadata-2","page":"Home","title":"Metadata","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Stores information about the GIS data in DataFrame metadata (from upcoming release of DataFrames.jl).","category":"page"},{"location":"","page":"Home","title":"Home","text":"Metadata are stored as a Dictionary, and there are numerous SimpleFeatures functions that handling viewing, copying, and updating this metadata (e.g., st_crs, st_geomtype, etc.)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Currently supports:","category":"page"},{"location":"","page":"Home","title":"Home","text":"crs info (type: GeoFormatTypes.GeoFormat)\ngeometry type (type: ArchGDAL.OGRwkbGeometryType)\ndescription (not yet implemented)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Example","category":"page"},{"location":"","page":"Home","title":"Home","text":"Dict{String, Any} with 3 entries:\n  \"geomtype\"    => wkbPolygon\n  \"description\" => \"description\"\n  \"crs\"         => WellKnownText2{Unknown}(Unknown(), \"PROJCRS[\\\"NAD83(2011)...","category":"page"},{"location":"#sfgeom-objects","page":"Home","title":"sfgeom objects","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Each row of the geom column is a SimpleFeatures sfgeom object that has two attributes:","category":"page"},{"location":"","page":"Home","title":"Home","text":"wkb: A vector (type Vector{UInt8}) of the Well-known binary (WKB) representation of the geometry.\nExample:   julia   93-element Vector{UInt8}:   0x01   0x03   0x00   0x00   0x00       ⋮   0x80   0xed   0xcb   0x4d   0x41\npreview: A string that shows an abbreviated Well-known text (WKT) string. \nExample: \njulia   POLYGON ((853787 3905499,...","category":"page"},{"location":"","page":"Home","title":"Home","text":"This data structure allows SimpleFeatures to:","category":"page"},{"location":"","page":"Home","title":"Home","text":"interface with GDAL and GEOS (coming soon) for fast operations (using using ArchGDAL.jl and LibGEOS.jl, respectively)\nprovide a preview of the geometry's WKT for viewing\nrepresent geometries (wkb) in Julia without needing to define a new SimpleFeatures type for each type of geometry. SimpleFeatures uses ArchGDAL geometry types for geometry type info.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package builds on existing Julia GIS packages GeoDataFrames and ArchGDAL.","category":"page"},{"location":"#Long-term-Goals","page":"Home","title":"Long-term Goals","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To provide full support for simple features access\nTo provide an intuitive workflow for reading, analyzing, manipulating, and writing vector GIS data in Julia","category":"page"},{"location":"","page":"Home","title":"Home","text":"Inspired by the R package sf. This package is in Alpha and will change significantly in the future.","category":"page"},{"location":"#Reference","page":"Home","title":"Reference","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [SimpleFeatures]","category":"page"},{"location":"#SimpleFeatures.replace_metadata!-Tuple{DataFrames.DataFrame, DataFrames.DataFrame}","page":"Home","title":"SimpleFeatures.replace_metadata!","text":"replace_metadata!(x::DataFrame, y::DataFrame) Erases metadata from x and replaces with metadata from y\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_buffer-Tuple{DataFrames.DataFrame, Number}","page":"Home","title":"SimpleFeatures.st_buffer","text":"st_buffer(x::DataFrame, d::Number; geom_columns=(:geom,))\n\nCreate a new DataFrame that is buffered by the provided distance d in units of the crs. The resulting object is stored in memory as a GeoPackage by default, but a filename fn can be provided. The geom_column is expected to hold ArchGDAL geometries.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_cast-Tuple{DataFrames.DataFrame, String}","page":"Home","title":"SimpleFeatures.st_cast","text":"stcast(x::DataFrame, to::String) Cast features geometries to the requested type. See below for the ordered list of to values. Any decomposition from a multigeometry type to a single geometry type will add a unique ID of the multigeometry object as a column (e.g., `MultiPolygonID`) so the original multigeometry can be re-created later. \n\nHierarchy of to values:\n\n\"multipolygon\"\n\"polygon\"\n\"multilinestring\"\n\"linestring\"\n\"multipoint\"\n\"point\"\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_crs-Tuple{DataFrames.DataFrame}","page":"Home","title":"SimpleFeatures.st_crs","text":"st_crs(x::DataFrame) Extract the crs object from the DataFrame's metadata\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_geomtype-Tuple{DataFrames.DataFrame}","page":"Home","title":"SimpleFeatures.st_geomtype","text":"st_geomtype(x::DataFrame) Extract the geometry type of the DataFrame from the DataFrame's metadata\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_is_spdf-Tuple{DataFrames.DataFrame}","page":"Home","title":"SimpleFeatures.st_is_spdf","text":"stisspdf(x::DataFrame) Return if DataFrame contains crs metadata and geometry column (true) or is missing one or both items.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_read-Tuple{AbstractString}","page":"Home","title":"SimpleFeatures.st_read","text":"st_read(fn::AbstractString; kwargs...)\nst_read(fn::AbstractString, layer::Union{Integer,AbstractString}; kwargs...)\n\nRead a file into a DataFrame. Any kwargs are passed onto ArchGDAL here. By default you only get the first layer, unless you specify either the index (0 based) or name (string) of the layer.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_segmentize-Tuple{DataFrames.DataFrame, Number}","page":"Home","title":"SimpleFeatures.st_segmentize","text":"st_segmentize(x::DataFrame, max_length::Number; geom_columns=(:geom,))\n\nCreate a new DataFrame that contains LineString geometries that have been sliced into lines of max_length. The resulting object is stored in memory as a GeoPackage by default, but a filename fn can be provided. The geom_column is expected to hold ArchGDAL geometries.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_set_crs-Tuple{DataFrames.DataFrame, GeoFormatTypes.GeoFormat}","page":"Home","title":"SimpleFeatures.st_set_crs","text":"stsetcrs(x::DataFrame, crs::GFT.GeoFormat) Set the crs object within the DataFrame's metadata. Metadata will be created if it does not exist. This does not do any projection and will overwrite any existing crs info. To project to a different crs, see st_transform\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_set_geomtype-Tuple{DataFrames.DataFrame, ArchGDAL.OGRwkbGeometryType}","page":"Home","title":"SimpleFeatures.st_set_geomtype","text":"stsetgeomtype(x::DataFrame, geomtype::AG.OGRwkbGeometryType) Set the geometry type of the DataFrame from the DataFrame's metadata\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_transform-Tuple{DataFrames.DataFrame, GeoFormatTypes.GeoFormat}","page":"Home","title":"SimpleFeatures.st_transform","text":"st_transform(x::DataFrame, crs::GFT.GeoFormat; fn::Union{Nothing, AbstractString}=nothing, layer_name::AbstractString=\"data\", driver::Union{Nothing,AbstractString}=\"GPKG\", options::Dict{String,String}=Dict{String,String}(), geom_columns=(:geom,))\n\nCreate a new DataFrame that is projected to the provided crs. The resulting object is stored in memory as a GeoPackage by default, but a filename fn can be provided. The geom_column is expected to hold ArchGDAL geometries.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.st_write-Tuple{AbstractString, DataFrames.DataFrame}","page":"Home","title":"SimpleFeatures.st_write","text":"st_write(fn::AbstractString, table; layer_name=\"data\", geom_column=:geometry, crs::Union{GFT.GeoFormat,Nothing}=nothing, driver::Union{Nothing,AbstractString}=nothing, options::Vector{AbstractString}=[], geom_columns::Set{Symbol}=(:geometry))\n\nWrite the provided table to fn. The geom_column is expected to hold ArchGDAL geometries.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.toProjJSON-Tuple{ArchGDAL.AbstractSpatialRef}","page":"Home","title":"SimpleFeatures.toProjJSON","text":"toProjJSON(spref::AbstractSpatialRef)\n\nConvert this SRS into ProjJSON format.\n\n\n\n\n\n","category":"method"},{"location":"#SimpleFeatures.toWKT2-Tuple{ArchGDAL.AbstractSpatialRef}","page":"Home","title":"SimpleFeatures.toWKT2","text":"toWKT2(spref::AbstractSpatialRef)\n\nConvert this SRS into WKT2 format.\n\n\n\n\n\n","category":"method"}]
}
