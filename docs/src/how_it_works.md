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
- interface with GDAL and GEOS for fast I/O and operations (using using [ArchGDAL.jl](https://github.com/yeesian/ArchGDAL.jl/) and [LibGEOS.jl](https://github.com/JuliaGeo/LibGEOS.jl), respectively)
- provide a preview of the geometry's WKT for viewing
- represent geometries (`wkb`) in Julia without needing to define a new SimpleFeatures type for each type of geometry. SimpleFeatures uses ArchGDAL geometry types for geometry type info.

This package builds on existing Julia GIS packages [GeoDataFrames](https://github.com/evetion/GeoDataFrames.jl) and [ArchGDAL](https://github.com/yeesian/ArchGDAL.jl/).