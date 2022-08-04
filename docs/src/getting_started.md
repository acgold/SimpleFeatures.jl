# Getting Started

## Load SimpleFeatures.jl

We'll load the package in these examples as `SF`, shorthand for `SimpleFeatures`

```julia
import SimpleFeatures as SF
```

## Read & write data

Most GIS types can be read and written using the functions `st_read` and `st_write`, respectively.

```julia
x = SF.st_read("data/test.gpkg")

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
SF.st_write("data/new_test.gpkg", x)

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

Check out [Reference](@ref) for a full list of functions available functions. Below are a few examples.

### Cast polygons to linestrings

In this example, `SimpleFeatures` will cast each polygon to a **multilinestring** and then to a **linestrings**. Some polygons had holes (multiple lines per polygon), so the resulting DataFrame has more rows than the original. In cases such as this, `SimpleFeatures` adds a column of the geometry type + "ID" (e.g. `_MultiLineStringID`) that preserves which multigeometry type the split geometry belonged to.

```julia
lines = SF.st_cast(df, "linestring")

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
buffered_lines = SF.st_buffer(lines, 10) # buffer distance is in units of the crs. Meters in this example

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
reprojected_buffer = SF.st_transform(x, GeoFormatTypes.EPSG(5070))

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

### Intersection
Say we have two sets of features (two different SimpleFeature objects, `x` and `y`), and we'd like to find their intersection and preserve their traits. We can do this with `st_intersection`.

```julia
intersection = SF.st_intersection(x, y)

SimpleFeature
---------
geomtype:  wkbPolygon
crs:       PROJCRS["NAD83(2011) / UTM zone 17N",BASEGEOGCRS["NAD83(2011)",DATUM["NAD83 (National Spatial Refere..."
---------
features:  
357×3 DataFrame
 Row │ lyr.1  lyr.1_1  geom                         
     │ Int32  Int32    sfgeom                       
─────┼──────────────────────────────────────────────
   1 │     1        1  POLYGON ((853789 3905499,...
  ⋮  │   ⋮       ⋮                  ⋮
 357 │     0        0  POLYGON ((857155 3905468,...
                                    355 rows omitted
```

In this example, `y` is a buffered subset of `x`, so both input objects had the same column "lyr.1". When this happens, a suffix will be added to the column from `y` and it will be joined with `x`.

### Area

I wonder what the area of overlap was from the Intersection example? Let's check it out! The result is in units of the crs.

```julia
area_list = SF.st_area(intersection)

357-element Vector{Float64}:
  2.0
  2.0
  2.0
  2.0
  1.0
  1.0
  ⋮
 36.0
  1.0
  1.0
  1.0
  1.0
  1.0
```

## Plotting

Plot a `SimpleFeature` object using Plots. It will use an equal aspect ratio.

```julia
using Plots

x = SF.st_read("example.gpkg")

plot(x)
```

 If you want to specify the fill of geometries based on a column, pass the name of the column to `fill_col`. 
 
 Specify a color palette from [ColorSchemes](https://juliagraphics.github.io/ColorSchemes.jl/stable/basics/#Pre-defined-schemes-1) by passing a palette to `fill`.

 ```julia
 plot(x, fill = palette(:viridis), fill_col = :cool_value)
 ```