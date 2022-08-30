# The following code is modified From ArchGDAL - https://github.com/yeesian/ArchGDAL.jl/blob/master/src/geointerface.jl
# See below for the ArchGDAL.jl license information
#
# The ArchGDAL.jl package is licensed under the MIT "Expat" License:
#
# > Copyright (c) 2019: Yeesian Ng, Maarten Pronk, Martijn Visser, and contributors
# >
# > Permission is hereby granted, free of charge, to any person obtaining
# > a copy of this software and associated documentation files (the
# > "Software"), to deal in the Software without restriction, including
# > without limitation the rights to use, copy, modify, merge, publish,
# > distribute, sublicense, and/or sell copies of the Software, and to
# > permit persons to whom the Software is furnished to do so, subject to
# > the following conditions:
# >
# > The above copyright notice and this permission notice shall be
# > included in all copies or substantial portions of the Software.
# >
# > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# > EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# > MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# > IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# > CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# > TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# > SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const lookup_method = Dict{DataType,Function}(
    GeoInterface.PointTrait => AG.createpoint,
    GeoInterface.MultiPointTrait => AG.createmultipoint,
    GeoInterface.LineStringTrait => AG.createlinestring,
    GeoInterface.LinearRingTrait => AG.createlinearring,
    GeoInterface.MultiLineStringTrait => AG.createmultilinestring,
    GeoInterface.PolygonTrait => AG.createpolygon,
    GeoInterface.MultiPolygonTrait => AG.createmultipolygon,
)

let pointtypes = (AG.wkbPoint, AG.wkbPoint25D, AG.wkbPointM, AG.wkbPointZM),
    multipointtypes =
        (AG.wkbMultiPoint, AG.wkbMultiPoint25D, AG.wkbMultiPointM, AG.wkbMultiPointZM),
    linetypes =
        (AG.wkbLineString, AG.wkbLineString25D, AG.wkbLineStringM, AG.wkbLineStringZM),
    multilinetypes = (
        AG.wkbMultiLineString,
        AG.wkbMultiLineString25D,
        AG.wkbMultiLineStringM,
        AG.wkbMultiLineStringZM,
    ),
    polygontypes = (AG.wkbPolygon, AG.wkbPolygon25D, AG.wkbPolygonM, AG.wkbPolygonZM),
    multipolygontypes = (
        AG.wkbMultiPolygon,
        AG.wkbMultiPolygon25D,
        AG.wkbMultiPolygonM,
        AG.wkbMultiPolygonZM,
    ),
    collectiontypes = (
        AG.wkbGeometryCollection,
        AG.wkbGeometryCollection25D,
        AG.wkbGeometryCollectionM,
        AG.wkbGeometryCollectionZM,
    )

end

const GeometryTraits = Union{
    GeoInterface.PointTrait,
    GeoInterface.MultiPointTrait,
    GeoInterface.LineStringTrait,
    GeoInterface.LinearRingTrait,
    GeoInterface.MultiLineStringTrait,
    GeoInterface.PolygonTrait,
    GeoInterface.MultiPolygonTrait,
    GeoInterface.GeometryCollectionTrait,
    GeoInterface.CircularStringTrait,
    GeoInterface.CompoundCurveTrait,
    GeoInterface.CurvePolygonTrait,
    GeoInterface.MultiSurfaceTrait,
    GeoInterface.PolyhedralSurfaceTrait,
    GeoInterface.TINTrait,
    GeoInterface.TriangleTrait,
}

# Conversion by converting GeoInterface geoms to ArchGDAL, and then to sfgeom
function Base.convert(::Type{T}, geom::X) where {T<:sfgeom,X}
    return Base.convert(T, GeoInterface.geomtrait(geom), geom)
end

function Base.convert(::Type{T}, ::GeometryTraits, geom::T) where {T<:sfgeom}
    return geom
end  # fast fallthrough without conversion

function Base.convert(::Type{T}, ::Nothing, geom::T) where {T<:sfgeom}
    return geom
end  # fast fallthrough without conversion

function Base.convert(::Type{T}, type::GeometryTraits, geom) where {T<:sfgeom,X}
    f = get(lookup_method, typeof(type), nothing)
    isnothing(f) && error(
        "Cannot convert an object of $(typeof(geom)) with the $(typeof(type)) trait (yet). Please report an issue.",
    )
    return to_sfgeom(f(GeoInterface.coordinates(geom)))
end

# Operations on single geometries that return non-geometry values
function GeoInterface.intersects(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.intersects(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.equals(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.equals(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.disjoint(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.disjoint(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.touches(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.touches(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.crosses(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.crosses(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.within(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.within(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.contains(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.contains(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.overlaps(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.overlaps(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.distance(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return LibGEOS.distance(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos"))
end

function GeoInterface.length(::GeometryTraits, a::sfgeom)
    return LibGEOS.geomLength(from_sfgeom(a, to="geos"))
end

function GeoInterface.area(::GeometryTraits, a::sfgeom)
    return LibGEOS.area(from_sfgeom(a, to="geos"))
end

# Operations on single geometries that return geometry values
function GeoInterface.union(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return to_sfgeom(LibGEOS.union(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos")))
end

function GeoInterface.intersection(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return to_sfgeom(LibGEOS.intersection(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos")))
end

function GeoInterface.difference(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return to_sfgeom(LibGEOS.difference(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos")))
end

function GeoInterface.symdifference(
    ::GeometryTraits,
    ::GeometryTraits,
    a::sfgeom,
    b::sfgeom,
)
    return to_sfgeom(LibGEOS.symmetricDifference(from_sfgeom(a, to="geos"), from_sfgeom(b, to="geos")))
end

function GeoInterface.buffer(::GeometryTraits, a::sfgeom, d)
    return to_sfgeom(LibGEOS.buffer(from_sfgeom(a, to="geos"), d))
end

function GeoInterface.convexhull(::GeometryTraits, a::sfgeom)
    return to_sfgeom(LibGEOS.convexhull(from_sfgeom(a, to="geos")))
end


# The following code is original to SimpleFeatures

# Implementing GeoInterface for geometries
GeoInterface.isgeometry(geom::sfgeom)::Bool = true
GeoInterface.geomtrait(geom::sfgeom)::AbstractGeometryTrait = GeoInterface.geomtrait(from_sfgeom(geom, to="gdal"))
GeoInterface.asbinary(geom::sfgeom) = geom.wkb
GeoInterface.astext(geom::sfgeom) = AG.toWKT(from_sfgeom(geom, to="gdal"))
GeoInterface.extent(::GeometryTraits, geom::sfgeom) = GeoInterface.extent(from_sfgeom(geom, to="gdal"))
GeoInterface.bbox(geom::sfgeom) = GeoInterface.extent(from_sfgeom(geom, to="gdal"))
GeoInterface.ncoord(geom::sfgeom)::Integer = GeoInterface.ncoord(from_sfgeom(geom, to="gdal"))
GeoInterface.coordnames(::GeometryTraits, geom::sfgeom) = GeoInterface.coordnames(from_sfgeom(geom, to = "gdal"))
GeoInterface.isempty(::GeometryTraits, geom::sfgeom) = GeoInterface.isempty(from_sfgeom(geom, to="gdal"))
GeoInterface.issimple(::GeometryTraits, geom::sfgeom) = GeoInterface.issimple(from_sfgeom(geom, to="gdal"))
GeoInterface.npoint(t::GeometryTraits, geom::sfgeom) = GeoInterface.npoint(from_sfgeom(geom, to="gdal"))
GeoInterface.getpoint(geom::sfgeom, i) = GeoInterface.getpoint(from_sfgeom(geom, to="gdal"), i)
GeoInterface.getpoint(geom::sfgeom) = (to_sfgeom(GeoInterface.getpoint(from_sfgeom(geom, to="gdal"), i)) for i in range(1, GeoInterface.npoint(geom)))
GeoInterface.startpoint(t::GeometryTraits, geom::sfgeom) = to_sfgeom(GeoInterface.startpoint(from_sfgeom(geom, to = "gdal")))
GeoInterface.endpoint(t::GeometryTraits, geom::sfgeom) = to_sfgeom(GeoInterface.endpoint(from_sfgeom(geom, to = "gdal")))
GeoInterface.isclosed(t::GeometryTraits, geom::sfgeom) = GeoInterface.isclosed(from_sfgeom(geom, to="gdal"))
GeoInterface.isring(t::GeometryTraits, geom::sfgeom) = GeoInterface.isring(from_sfgeom(geom, to="gdal"))

GeoInterface.centroid(geom::sfgeom) = to_sfgeom(LibGEOS.centroid(from_sfgeom(geom, to="geos")))
GeoInterface.pointonsurface(geom::sfgeom) = to_sfgeom(LibGEOS.pointOnSurface(from_sfgeom(geom, to = "geos")))
GeoInterface.boundary(geom::sfgeom) = to_sfgeom(LibGEOS.boundary(from_sfgeom(geom, to = "geos")))

GeoInterface.getcoord(geom::sfgeom, i::Integer)::Real = GeoInterface.getcoord(from_sfgeom(geom, to="gdal"), i)
GeoInterface.getcoord(geom::sfgeom) = GeoInterface.coordinates(from_sfgeom(geom, to="gdal"))
GeoInterface.coordinates(::GeometryTraits, geom::sfgeom) = GeoInterface.getcoord(geom)
GeoInterface.x(::GeometryTraits, geom::sfgeom) = GeoInterface.x(from_sfgeom(geom, to="gdal"))
GeoInterface.y(::GeometryTraits, geom::sfgeom) = GeoInterface.y(from_sfgeom(geom, to="gdal"))
GeoInterface.z(::GeometryTraits, geom::sfgeom) = GeoInterface.z(from_sfgeom(geom, to="gdal"))
GeoInterface.m(::GeometryTraits, geom::sfgeom) = GeoInterface.m(from_sfgeom(geom, to="gdal"))
GeoInterface.is3d(::GeometryTraits, geom::sfgeom) = GeoInterface.is3d(from_sfgeom(geom, to="gdal"))
GeoInterface.ismeasured(::GeometryTraits, geom::sfgeom) = GeoInterface.ismeasured(from_sfgeom(geom, to="gdal"))
GeoInterface.ngeom(geom::sfgeom)::Integer = GeoInterface.ngeom(from_sfgeom(geom, to="gdal"))
GeoInterface.getgeom(geom::sfgeom, i::Integer) = to_sfgeom(GeoInterface.getgeom(from_sfgeom(geom, to="gdal"), i))
GeoInterface.getgeom(geom::sfgeom) = (to_sfgeom(GeoInterface.getgeom(from_sfgeom(geom, to="gdal"), i)) for i in range(1, GeoInterface.ngeom(geom)))


# Implementing GeoInterface for Features
GeoInterface.isfeature(::Type{SimpleFeature})::Bool = true
GeoInterface.properties(feat::SimpleFeature) = select(feat, Not(:geom))
GeoInterface.geometry(feat::SimpleFeature) = feat[:, :geom]
GeoInterface.geomtrait(feat::SimpleFeature) = GeoInterface.geomtrait.(feat[:, GeoInterface.geometrycolumns(feat)[1]]) # only uses first geomcolumn to determine type

# Implementing GeoInterface for FeatureCollection
GeoInterface.isfeaturecollection(::Type{SimpleFeature}) = true
GeoInterface.getfeature(collection::SimpleFeature, i::Integer) = collection[i, :]
GeoInterface.getfeature(collection::SimpleFeature) = eachrow(collection)
GeoInterface.nfeature(collection::SimpleFeature) = nrow(collection)
GeoInterface.geometrycolumns(featurecollection::SimpleFeature) = propertynames(featurecollection)[eltype.(DataFrames.eachcol(featurecollection)).=== sfgeom]

Base.length(x::SimpleFeature) = DataFrames.nrow(x)