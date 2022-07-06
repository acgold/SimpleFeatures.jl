```@meta
CurrentModule = SimpleFeatures
```

# SimpleFeatures

Documentation for [SimpleFeatures.jl](https://github.com/acgold/SimpleFeatures.jl).

## Working with simple feature GIS data in Julia. 

Builds on existing Julia GIS packages [GeoDataFrames.jl](https://github.com/evetion/GeoDataFrames.jl) and [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) to:
- Handle operations as a DataFrame (i.e., DataFrame in, DataFrame out)
- Store coordinate reference system info with the DataFrame and use it automatically
- Create new copies of underlying geographic data (GDAL) when performing functions (unless specified with a `!`)

## Long-term Goals
- To provide full support for [simple features access](https://en.wikipedia.org/wiki/Simple_Features)
- To provide an intuitive workflow for reading, analyzing, manipulating, and writing vector GIS data in Julia

Inspired by the R package [`sf`](https://r-spatial.github.io/sf/). This package is very much in Alpha and is currently intended for my personal use.

```@index
```

```@autodocs
Modules = [SimpleFeatures]
```
