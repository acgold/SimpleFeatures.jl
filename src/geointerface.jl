# Implementing GeoInterface for geometries
GeoInterface.isgeometry(geom::sfgeom)::Bool = true
GeoInterface.geomtrait(geom::sfgeom)::AbstractGeometryTrait = AG.GeoInterface.geomtrait(from_sfgeom(geom, to = "archgdal")) # <: AbstractGeometryTrait

# for PointTraits
GeoInterface.ncoord(geom::sfgeom)::Integer = AG.GeoInterface.ncoord(from_sfgeom(geom, to = "archgdal"))
GeoInterface.getcoord(geom::sfgeom, i::Integer)::Real = AG.GeoInterface.getcoord(from_sfgeom(geom, to = "archgdal"), i)

# for non PointTraits
GeoInterface.ngeom(geom::sfgeom)::Integer = AG.GeoInterface.ngeom(from_sfgeom(geom, to = "archgdal"))
GeoInterface.getgeom(geom::sfgeom, i::Integer) = AG.GeoInterface.getgeom(from_sfgeom(geom, to = "archgdal"), i)

# Implementing GeoInterface for features/feature collection
GeoInterface.isfeature(::Type{SimpleFeature})::Bool = true
GeoInterface.properties(feat::SimpleFeature) = select(feat, Not(:geom))
GeoInterface.geometry(feat::SimpleFeature) = feat[:,:geom]

GeoInterface.isfeaturecollection(::Type{SimpleFeature}) = true
GeoInterface.getfeature(collection::SimpleFeature, i::Integer) = collection[i,:]
GeoInterface.getfeature(collection::SimpleFeature) = eachrow(collection)
GeoInterface.nfeature(collection::SimpleFeature) = nrow(collection)
GeoInterface.geometrycolumns(collection::SimpleFeature) = propertynames(collection)[eltype.(DataFrames.eachcol(collections)) .== sfgeom]

Base.length(x::SimpleFeature) = DataFrames.nrow(x)