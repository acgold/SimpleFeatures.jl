using Revise
import SimpleFeatures as SF
using DataFrames
import GeoFormatTypes as GFT
using Test
import ArchGDAL as AG
using GeoInterface
using DataFramesMeta

const testdatadir = joinpath(@__DIR__, "data")
isdir(testdatadir) || mkdir(testdatadir)

# create SimpleFeature objects from file
include("generate_SFs.jl");

@testset "SimpleFeatures.jl" begin
    # IO
    @testset "Writing SimpleFeature object" begin
        SF.st_write(joinpath(testdatadir, "test.gpkg"), polygons)
        @test isfile(joinpath(testdatadir, "test.gpkg"))
    end

    @testset "Reading SimpleFeature object" begin
        polygons = SF.st_read(joinpath(testdatadir, "test.gpkg"))
        @test typeof(polygons) === SF.SimpleFeature
        @test DataFrames.nrow(polygons) === 4
        @test typeof(polygons.crs) === GFT.WellKnownText2{GFT.Unknown}
    end

    # sfgeom conversions
    @testset "Converting geoms from sfgeom to gdal and back" begin
        geom = polygons.df.geom[1]
        @test typeof(geom) === SF.sfgeom

        gdal_geom = SF.from_sfgeom(geom, to = "archgdal")
        @test typeof(gdal_geom) === AG.IGeometry{AG.wkbPolygon}

        new_geom = SF.to_sfgeom(gdal_geom)
        @test typeof(new_geom) === SF.sfgeom

        geoms = polygons.df.geom[1:2]
        @test typeof(geoms) === Vector{SF.sfgeom}

        gdal_geoms = SF.from_sfgeom(geoms, to = "archgdal")
        @test typeof(gdal_geoms) === Vector{AG.AbstractGeometry}

        new_geoms = SF.to_sfgeom(gdal_geoms)
        @test typeof(new_geoms) === Vector{SF.sfgeom}

        prev_wkt = SF.preview_wkt(gdal_geom)
        @test length(prev_wkt) === 28
        @test typeof(prev_wkt) === String
    end

    # Operations
    @testset "projecting SimpleFeature w/st_transform" begin
        proj_polygons = SF.st_transform(polygons, GFT.EPSG(5070))
        @test proj_polygons.crs === GFT.EPSG(5070)
        @test polygons.df.geom[1] !== proj_polygons.df.geom[1]
    end

    @testset "buffer spatial DataFrame" begin
        buff_polygons = SF.st_buffer(polygons, 10)
        original_area = sum(SF.st_area(polygons))
        @test isapprox(original_area, 39271.80464290353)

        new_area = sum(SF.st_area(buff_polygons))
        @test isapprox(new_area, 66529.84952521359)
    end

    @testset "st_cast combine - full example" begin
        # aggregate from Point -> MultiPolygon by 1 step
        point_polygons = SF.st_cast(polygons, "point")

        multipoint_polygons = SF.st_cast(point_polygons, "multipoint", groupid="_MultiPointID")
        ls_polygons = SF.st_cast(multipoint_polygons, "linestring")
        mls_polygons = SF.st_cast(ls_polygons, "multilinestring"; groupid="_MultiLineStringID")
        polygon_polygons = SF.st_cast(mls_polygons, "polygon")
        multipolygon_polygons = SF.st_cast(polygon_polygons, "multipolygon"; groupid="way_id")

        # check geom types following 1 step aggregate
        @test multipolygon_polygons.geomtype === AG.wkbMultiPolygon
        @test polygon_polygons.geomtype === AG.wkbPolygon
        @test mls_polygons.geomtype === AG.wkbMultiLineString
        @test ls_polygons.geomtype === AG.wkbLineString
        @test multipoint_polygons.geomtype === AG.wkbMultiPoint
        @test point_polygons.geomtype === AG.wkbPoint

        @test nrow(point_polygons.df) === 492
        @test nrow(multipoint_polygons.df) === 4
        @test nrow(ls_polygons.df) === 4
        @test nrow(mls_polygons.df) === 4
        @test nrow(polygon_polygons.df) === 4
        @test nrow(multipolygon_polygons.df) === 2
    end

    @testset "Cast multipolygon to point - full st_cast test" begin
        # setup
        @test polygons.geomtype === AG.wkbPolygon
        mp_polygons = SF.st_cast(polygons, "multipolygon")
        @test mp_polygons.geomtype === AG.wkbMultiPolygon

        # cast from MultiPolygon -> Point by 1 step
        p_polygons = SF.st_cast(mp_polygons, "polygon")
        mls_polygons = SF.st_cast(p_polygons, "multilinestring")
        ls_polygons = SF.st_cast(mls_polygons, "linestring")
        multipoint_polygons = SF.st_cast(ls_polygons, "multipoint")
        point_polygons = SF.st_cast(multipoint_polygons, "point")

        # check geom types following 1 step cast
        @test p_polygons.geomtype === AG.wkbPolygon
        @test mls_polygons.geomtype === AG.wkbMultiLineString
        @test ls_polygons.geomtype === AG.wkbLineString
        @test multipoint_polygons.geomtype === AG.wkbMultiPoint
        @test point_polygons.geomtype === AG.wkbPoint

        # cast from MultiPolygon to geometries more than 1 step down
        mls_polygons_2 = SF.st_cast(mp_polygons, "multilinestring")
        ls_polygons_2 = SF.st_cast(mp_polygons, "linestring")
        multipoint_polygons_2 = SF.st_cast(mp_polygons, "multipoint")
        point_polygons_2 = SF.st_cast(mp_polygons, "point")

        # check geom types following multi-step cast
        @test mls_polygons_2.geomtype === AG.wkbMultiLineString
        @test ls_polygons_2.geomtype === AG.wkbLineString
        @test multipoint_polygons_2.geomtype === AG.wkbMultiPoint
        @test point_polygons_2.geomtype === AG.wkbPoint

        # check if output is same from single and multistep cast
        @test mls_polygons == mls_polygons_2
        @test ls_polygons == ls_polygons_2
        @test multipoint_polygons == multipoint_polygons_2
        @test point_polygons == point_polygons_2
    end

    @testset "combine and union geometries" begin
        @test DataFrames.nrow(polygons.df) === 4
        combined_polygons = SF.st_combine(polygons)
        
        @test DataFrames.nrow(combined_polygons.df) === 1
        @test combined_polygons.geomtype === AG.wkbMultiPolygon

        unioned_polygons = SF.st_union(polygons)
        @test DataFrames.nrow(unioned_polygons.df) === 1
        @test unioned_polygons.geomtype === AG.wkbPolygon
    end

    @testset "segmentize and simplify a line" begin
        segmented = SF.st_segmentize(lines, 1)

        segmented_pts = SF.st_cast(segmented, "point")
        original_pts = SF.st_cast(lines, "point")

        @test nrow(original_pts) === 8
        @test nrow(segmented_pts) === 1100

        simplified = SF.st_simplify(segmented, 5)
        simplified_pts = SF.st_cast(simplified, "point")
        @test nrow(simplified_pts) === 8
    end

    @testset "create bounding box" begin
        bbox = SF.st_bbox(polygons)
        @test AG.getgeomtype(bbox) === AG.wkbPolygon
        @test length(GeoInterface.coordinates(bbox)[1]) === 5
    end

    @testset "df to sf test" begin
        df = DataFrames.select(polygons.df, Not(:geom))
        df.geom = SF.from_sfgeom(polygons.df.geom, to = "archgdal")

        @test typeof(df) === DataFrame
        @test typeof(df.geom[1]) === AG.IGeometry{AG.wkbPolygon}

        copy_polygons = SF.df_to_sf(df, polygons.crs)
        @test typeof(copy_polygons) === SF.SimpleFeature
        @test copy_polygons == polygons
    end

    @testset "Indexing test" begin
        @test typeof(polygons[:, :geom]) === Vector{SF.sfgeom}
        @test typeof(polygons[1, :geom]) === SF.sfgeom
        @test typeof(polygons[1:3, :geom]) === Vector{SF.sfgeom}

        @test typeof(polygons[:, :]) === SF.SimpleFeature
        @test typeof(polygons[1, :]) === SF.SimpleFeature
        @test typeof(polygons[1:3, :]) === SF.SimpleFeature

        @test typeof(polygons[:, 1:2]) === SF.SimpleFeature
        @test typeof(polygons[:, ["way_id","geom"]]) === SF.SimpleFeature

        copy_polygons = deepcopy(polygons)
        copy_polygons[!, :new_col] = copy_polygons[:,"way_id"] .+ 1;
        @test ncol(copy_polygons) === 5

        first_rows = first(polygons, 2)
        @test nrow(first_rows) === 2

        last_rows = last(polygons, 2)
        @test nrow(last_rows) === 2
    end

    @testset "DataFrames functions" begin
        copy_polygons = rename(polygons, Dict("way_id" => "new_way_id"))
        @test names(copy_polygons.df)[1] === "new_way_id"

        col = @select(copy_polygons, :geom)
        @test ncol(col) == 1

        new_col = @transform(copy_polygons, :new_col = :new_way_id * 2)
        @test sum(new_col.df.new_col) === 1801571088

        subset_col = @subset(copy_polygons, :new_way_id .== 16461591)
        @test nrow(subset_col) === 1
    end

    @testset "Find centroid" begin
        centroids = SF.st_centroid(polygons)

        @test AG.getgeomtype(SF.from_sfgeom(centroids.df.geom[1], to = "archgdal")) === AG.wkbPoint
        @test nrow(centroids) === 4
    end

    @testset "Find nearest points" begin
        polygon_1 = polygons[1,:]
        line_4 = lines[4,:]

        nrst_pts = SF.st_nearest_points(polygon_1, line_4)

        @test AG.getgeomtype(SF.from_sfgeom(nrst_pts.df.geom[1], to = "archgdal")) === AG.wkbLineString
        @test isapprox(SF.st_length(nrst_pts)[1], 20.885955693556273)
    end

    @testset "distance matrix" begin
        polygon_1 = polygons[1,:]

        distances = SF.st_distance(polygon_1, lines)
        @test typeof(distances) === Matrix{Real}
        @test length(distances) == 4
        @test sum(distances) > 20 
    end

    @testset "Calculate intersection" begin
        polygon_1 = polygons[1,:]
        line_2 = lines[2,:]

        # Calc intersection
        int = SF.st_intersection(polygon_1, line_2)

        # Make sure geomtype is a line and length is approx \
        @test AG.getgeomtype(SF.from_sfgeom(int.df.geom[1], to = "archgdal")) === AG.wkbLineString
        @test isapprox(SF.st_length(int)[1], 16.402552599279197)

        # Do intersection w/polygons
        buffered_line_2 = SF.st_buffer(line_2, 10)
        int_buffered = SF.st_intersection(polygon_1, buffered_line_2)

        # Check that it returns polygons and area is about right
        @test AG.getgeomtype(SF.from_sfgeom(int_buffered.df.geom[1], to = "archgdal")) === AG.wkbPolygon
        @test isapprox(SF.st_area(int_buffered)[1], 474.0340208116075)

        # Check that attributes were combined from the two inputs
        @test int_buffered.df.line_number[1] == 2
    end

    @testset "Calculate difference" begin
        polygon_1 = polygons[1,:]
        line_2 = lines[2,:]
        buffered_line_2 = SF.st_buffer(line_2, 10)

        difference = SF.st_difference(polygon_1, buffered_line_2)

        @test AG.getgeomtype(SF.from_sfgeom(difference.df.geom[1], to = "archgdal")) === AG.wkbPolygon
        @test SF.st_area(difference)[1] < SF.st_area(polygon_1)[1]
    end

    @testset "Binary predicates" begin
        polygon_1 = polygons[1,:]

        intersects = SF.st_intersects(polygon_1, lines)
        @test intersects == [[1, 2, 3]]

        disjoint = SF.st_disjoint(polygon_1, lines)
        @test disjoint == [[4]]
    end
end