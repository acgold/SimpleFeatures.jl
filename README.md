# SimpleFeatures

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/stable/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/dev/)
[![Build Status](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/acgold/SimpleFeatures.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/acgold/SimpleFeatures.jl)

## Working with simple feature GIS data in Julia 

Fast reading, analyzing, manipulating, and writing vector GIS data in Julia. This package:
- Works with feature data as a [**DataFrame**](https://dataframes.juliadata.org/stable/) 
- Stores coordinate reference system (crs) info with the DataFrame and uses it automatically
- Uses a custom geometry type to interface with [**GDAL**](https://gdal.org) and [**GEOS**](https://libgeos.org) for fast I/O and operations

# About

The `SimpleFeatures` package aims to simplify working with geospatial data in Julia. 

This package currently offers some basic spatial operations, and more will be added in the future. [See docs for more info and examples](https://acgold.github.io/SimpleFeatures.jl/dev/).

This package creates a `SimpleFeature` custom type that effectively functions as a DataFrame containing feature data but also contains projection and geometry type info. 

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

> **Disclaimer**: This package is very young and under active development. More tests and checks (e.g., making sure projections match before performing operations) need to be added. See License.md for additional details. 

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