# SimpleFeatures

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/stable/) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://acgold.github.io/SimpleFeatures.jl/dev/)
[![Build Status](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/acgold/SimpleFeatures.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/acgold/SimpleFeatures.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/acgold/SimpleFeatures.jl)

## Working with simple feature GIS data in Julia 

Reading, analyzing, manipulating, and writing vector GIS data in Julia. This package:
- Handles operations as a DataFrame (i.e., DataFrame in, DataFrame out)
- Stores coordinate reference system (crs) info with the DataFrame and uses it automatically (DataFrames metadata)
- Creates new copies of Julia objects when performing functions (unless specified with a `!`)

This package builds on existing Julia GIS packages [GeoDataFrames](https://github.com/evetion/GeoDataFrames.jl) and [ArchGDAL](https://github.com/yeesian/ArchGDAL.jl/).

## Long-term Goals

- To provide full support for [simple features access](https://en.wikipedia.org/wiki/Simple_Features)
- To provide an intuitive workflow for reading, analyzing, manipulating, and writing vector GIS data in Julia

Inspired by the R package [`sf`](https://r-spatial.github.io/sf/). This package is in Alpha and will change significantly in the future.
