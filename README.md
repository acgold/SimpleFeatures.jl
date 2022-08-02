# SimpleFeatures

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/stable/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/dev/)
[![Build Status](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/acgold/SimpleFeatures.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/acgold/SimpleFeatures.jl)

## Working with simple feature GIS data in Julia 

Fast reading, analyzing, manipulating, and writing vector GIS data in Julia. This package:
- Works with feature data as a [**DataFrame**](https://dataframes.juliadata.org/stable/) 
- Stores coordinate reference system (crs) info with the DataFrame and uses it automatically
- Uses a custom geometry type to interface with [**GDAL**](https://gdal.org) and [**GEOS**](https://libgeos.org) (*coming soon!*) for fast operations

# About

The `SimpleFeatures` package aims to simplify working with geospatial data in Julia. 

This package currently offers some basic spatial operations (see **Getting started**), and more will be added in the future.

This package creates a `SimpleFeature` custom type that effectively functions as a DataFrame containing feature data but also contains projection and geometry type info. See more below in the section "**How it works**".

**Example:**

```julia
SimpleFeature
---------
geomtype:  wkbPolygon
crs:       PROJCRS["NAD83(2011) / UTM zone 17N",BASEGEOGCRS["NAD83(2011)",DATUM["NAD83 (National Spatial Refere..."
---------
features:  
1000×2 DataFrame
  Row │ geom                          lyr.1 
      │ sfgeom                        Int32 
──────┼─────────────────────────────────────
    1 │ POLYGON ((853787 3905499,...      1
    2 │ POLYGON ((853800 3905499,...      1
    3 │ POLYGON ((853803 3905499,...      1
  ⋮   │              ⋮                  ⋮
  998 │ POLYGON ((904045 3905468,...      1
  999 │ POLYGON ((905355 3905468,...      1
 1000 │ POLYGON ((905561 3905469,...      1
                            994 rows omitted
```


To directly access the DataFrame, crs info, or geometry info, just add `.df`, `.crs`, or `.geomtype` at the end of your `SimpleFeature` object's name.

# Installation

`SimpleFeatures` can be installed from the Pkg REPL (press `]` in the Julia REPL):

```julia
pkg> add SimpleFeatures
```

Or install from GitHub for the latest:

```julia
using Pkg
Pkg.add("https://github.com/acgold/SimpleFeatures.jl.git")
```

# Getting Started

## Load SimpleFeatures.jl

We'll load the package in these examples as `sf`, shorthand for `SimpleFeatures`

```julia
import SimpleFeatures as sf
```

## Read & write data

Most GIS types can be read and written using the functions `st_read` and `st_write`, respectively.

```julia
x = sf.st_read("data/test.gpkg")

SimpleFeature
---------
geomtype:  wkbPolygon
crs:       PROJCRS["NAD83(2011) / UTM zone 17N",BASEGEOGCRS["NAD83(2011)",DATUM["NAD83 (National Spatial Refere..."
---------
features:  
1000×2 DataFrame
  Row │ geom                          lyr.1 
      │ sfgeom                        Int32 
──────┼─────────────────────────────────────
    1 │ POLYGON ((853787 3905499,...      1
    2 │ POLYGON ((853800 3905499,...      1
    3 │ POLYGON ((853803 3905499,...      1
  ⋮   │              ⋮                  ⋮
  998 │ POLYGON ((904045 3905468,...      1
  999 │ POLYGON ((905355 3905468,...      1
 1000 │ POLYGON ((905561 3905469,...      1
                            994 rows omitted
```


```julia
sf.st_write("data/new_test.gpkg", x)

"data/new_test.gpkg"
```
## DataFrame operations

Many common [DataFrames](https://dataframes.juliadata.org/stable/) operations work with `SimpleFeature` objects. If the operation you want (e.g., Grouped DataFrames operations) isn't offered yet, you can access and manipulate the DataFrame of the `SimpleFeature` object directly by appending `.df` to your object.

Supported operations:
- Indexing
- select(!)
- transform(!)
- rename(!)
- subset(!)
- nrow, ncol
- combine
- first, last
- eachrow (but you can just iterate on a `SimpleFeature` object b/c we internally convert DataFrameRows to DataFrames.)

------------

Check out [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl) for some nice macros for many of these functions - they should work directly on `SimpleFeature` objects!

## Spatial operations

`SimpleFeatures` offers some basic spatial functions and will offer more in future releases.

Current functionality is:
- `sf.st_area` : Calculate the area of geometries
- `st_bbox` : Return a bounding box geometry for the entire `SimpleFeature`
- `sf.st_buffer` : Buffering (*GDAL. Will be GEOS soon*)
- `sf.st_cast` : Casting geometries to different types
- `sf.st_combine` : Combine all geometries in a `SimpleFeature` and drop attributes
- `sf.st_segmentize` : Segmentizing a line (*GDAL*)
- `sf.sfgeom_to_gdal`, `sf.gdal_to_sfgeom` : Converting between `sfgeom` objects and GDAL or GEOS (coming soon)
- `sf.st_transform` : Reprojecting (*GDAL*)

### Cast polygons to linestrings

In this example, `SimpleFeatures` will cast each polygon to a **multilinestring** and then to a **linestrings**. Some polygons had holes (multiple lines per polygon), so the resulting DataFrame has more rows than the original. In cases such as this, `SimpleFeatures` adds a column of the geometry type + "ID" (e.g. `_MultiLineStringID`) that preserves which multigeometry type the split geometry belonged to.

```julia
lines = sf.st_cast(df, "linestring")

SimpleFeature
---------
geomtype:  wkbLineString
crs:       PROJCRS["NAD83(2011) / UTM zone 17N",BASEGEOGCRS["NAD83(2011)",DATUM["NAD83 (National Spatial Refere..."
---------
features:  
1022×3 DataFrame
  Row │ lyr.1  _MultiLineStringID  geom                         
      │ Int32  Int64               sfgeom                       
──────┼─────────────────────────────────────────────────────────
    1 │     1                   1  LINESTRING (853787 390549...
    2 │     1                   2  LINESTRING (853800 390549...
    3 │     1                   3  LINESTRING (853803 390549...
  ⋮   │   ⋮            ⋮                        ⋮
 1020 │     1                 998  LINESTRING (904045 390546...
 1021 │     1                 999  LINESTRING (905355 390546...
 1022 │     1                1000  LINESTRING (905561 390546...
                                               1016 rows omitted
```
### Buffer
Using the linestrings from the `st_cast` example above, we will add a 10m buffer.

```julia
buffered_lines = sf.st_buffer(lines, 10) # buffer distance is in units of the crs. Meters in this example

SimpleFeature
---------
geomtype:  wkbPolygon
crs:       PROJCRS["NAD83(2011) / UTM zone 17N",BASEGEOGCRS["NAD83(2011)",DATUM["NAD83 (National Spatial Refere..."
---------
features:  
1022×3 DataFrame
  Row │ lyr.1  _MultiLineStringID  geom                         
      │ Int32  Int64               sfgeom                       
──────┼─────────────────────────────────────────────────────────
    1 │     1                   1  POLYGON ((853787 3905509,...
    2 │     1                   2  POLYGON ((853800 3905509,...
    3 │     1                   3  POLYGON ((853803 3905509,...
  ⋮   │   ⋮            ⋮                        ⋮
 1020 │     1                 998  POLYGON ((904045 3905478,...
 1021 │     1                 999  POLYGON ((905355 3905478,...
 1022 │     1                1000  POLYGON ((905556.62823740...
                                               1016 rows omitted
```

### Reproject
Let's reproject the polygons we just made with `st_buffer`.

```julia
reprojected_buffer = sf.st_transform(x, GeoFormatTypes.EPSG(5070))

SimpleFeature
---------
geomtype:  wkbPolygon
crs:   5070
---------
features:  
1000×2 DataFrame
  Row │ lyr.1  geom                         
      │ Int32  sfgeom                       
──────┼─────────────────────────────────────
    1 │     1  POLYGON ((1693276.9257186...
    2 │     1  POLYGON ((1693289.637015 ...
    3 │     1  POLYGON ((1693292.5703908...
  ⋮   │   ⋮                 ⋮
  998 │     1  POLYGON ((1742412.4620032...
  999 │     1  POLYGON ((1743692.7581942...
 1000 │     1  POLYGON ((1743893.9246629...
                            994 rows omitted
```


# How it works

## GIS data as a DataFrame

`SimpleFeatures` reads vector GIS data from files and creates a [DataFrame](https://dataframes.juliadata.org/stable/) containing geometries and their attributes. 

Each row is a feature, and geometry data for each feature are stored in the `geom` column. 

**Example:**

```julia
1000×2 DataFrame
  Row │ geom                          lyr.1 
      │ sfgeom                        Int32 
──────┼─────────────────────────────────────
    1 │ POLYGON ((853787 3905499,...      1
    2 │ POLYGON ((853800 3905499,...      1
    3 │ POLYGON ((853803 3905499,...      1
  ⋮   │              ⋮                  ⋮
  998 │ POLYGON ((904045 3905468,...      1
  999 │ POLYGON ((905355 3905468,...      1
 1000 │ POLYGON ((905561 3905469,...      1
                            994 rows omitted
```

## Metadata: crs and geomtype

These metadata (`.crs`, `.geomtype`) are stored as a attributes within a `SimpleFeature` object and can be modified or accessed directly.

**Example:**:
```julia
x.crs 

GeoFormatTypes.WellKnownText2{GeoFormatTypes.Unknown}(GeoFormatTypes.Unknown(), "PROJCRS[\"NAD83(2011) / UTM zone 17N\",BASEGEOGCRS[\"NAD83(2011)\",DATUM[...
```

```julia
x.geomtype

wkbPolygon::OGRwkbGeometryType = 3
```
Types:
- crs: [`GeoFormatTypes.GeoFormat`](https://juliageo.org/GeoFormatTypes.jl/stable/#GeoFormatTypes.GeoFormat)
- geomtype: [`ArchGDAL.OGRwkbGeometryType`](https://yeesian.com/ArchGDAL.jl/latest/reference/#ArchGDAL.OGRwkbGeometryType)

## Geometries as `sfgeom` objects

Each row of the `geom` column is an `sfgeom` object that has two attributes:
- `wkb`: A vector (type `Vector{UInt8}`) of the [Well-known binary (WKB)](https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry#Well-known_binary) representation of the geometry.

    **Example:**
    ```julia
    93-element Vector{UInt8}:
    0x01
    0x03
    0x00
    0x00
    0x00
        ⋮
    0x80
    0xed
    0xcb
    0x4d
    0x41
    ```
- `preview`: A string that shows an abbreviated [Well-known text (WKT)](https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry) string. 

    **Example:** 
    
    ```julia
    POLYGON ((853787 3905499,...
    ```


This data structure allows `SimpleFeatures` to:
- interface with GDAL and GEOS (coming soon) for fast operations (using using [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) and [LibGEOS.jl](https://github.com/JuliaGeo/LibGEOS.jl), respectively)
- provide a preview of the geometry's WKT for viewing
- represent geometries (`wkb`) in Julia without needing to define a new SimpleFeatures type for each type of geometry. SimpleFeatures uses ArchGDAL geometry types for geometry type info.

This package builds on existing Julia GIS packages [GeoDataFrames](https://github.com/evetion/GeoDataFrames.jl) and [ArchGDAL](https://github.com/yeesian/ArchGDAL.jl/).

# Goals

- Provide full support for [simple features access](https://en.wikipedia.org/wiki/Simple_Features)
- Provide an intuitive workflow for reading, analyzing, manipulating, and writing vector GIS data in Julia
- Allow SimpleFeature objects to effectively function as DataFrames for most simple use cases

Inspired by the R package [`sf`](https://r-spatial.github.io/sf/). This package is in Alpha and will change significantly in the future.