using Revise
import SimpleFeatures as sf
using DataFrames
import GeoFormatTypes as GFT
using Test
using Downloads
import ArchGDAL as AG
using GeoInterface

const testdatadir = joinpath(@__DIR__, "data")
isdir(testdatadir) || mkdir(testdatadir)

Downloads.download("https://github.com/acgold/SimpleFeatures.jl/raw/main/test/data/test.gpkg", joinpath(testdatadir, "test.gpkg"))

spdf = sf.st_read(joinpath(testdatadir, "test.gpkg"))

@testset "SimpleFeatures.jl" begin
    # IO
    @testset "Reading spatial DataFrame" begin
        @test DataFrames.nrow(spdf.df) === 1000
        @test typeof(spdf.crs) === GFT.WellKnownText2{GFT.Unknown}
        @test typeof(spdf) === sf.SimpleFeature
    end

    @testset "Writing spatial DataFrame" begin
        sf.st_write(joinpath(testdatadir, "new_test.gpkg"), spdf)
        @test isfile(joinpath(testdatadir, "new_test.gpkg"))
        new_spdf = sf.st_read(joinpath(testdatadir, "new_test.gpkg"))
        @test typeof(new_spdf) === sf.SimpleFeature
        @test spdf == new_spdf
    end

    # sfgeom conversions
    @testset "Converting geoms from sfgeom to gdal and back" begin
        geom = spdf.df.geom[1]
        @test typeof(geom) === sf.sfgeom

        gdal_geom = sf.sfgeom_to_gdal(geom)
        @test typeof(gdal_geom) === AG.IGeometry{AG.wkbPolygon}

        new_geom = sf.gdal_to_sfgeom(gdal_geom)
        @test typeof(new_geom) === sf.sfgeom

        geoms = spdf.df.geom[1:10]
        @test typeof(geoms) === Vector{sf.sfgeom}

        gdal_geoms = sf.sfgeom_to_gdal(geoms)
        @test typeof(gdal_geoms) === Vector{AG.AbstractGeometry}

        new_geoms = sf.gdal_to_sfgeom(gdal_geoms)
        @test typeof(new_geoms) === Vector{sf.sfgeom}

        prev_wkt = sf.preview_wkt_gdal(gdal_geom)
        @test length(prev_wkt) === 28
        @test typeof(prev_wkt) === String
    end


    # Operations
    @testset "projecting SimpleFeature w/st_transform" begin
        proj_spdf = sf.st_transform(spdf, GFT.EPSG(5070))
        @test proj_spdf.crs === GFT.EPSG(5070)
        @test spdf.df.geom[1] !== proj_spdf.df.geom[1]
    end

    @testset "buffer spatial DataFrame" begin
        buff_spdf = sf.st_buffer(spdf, 10)
        original_area = sum(sf.st_area(spdf))
        @test original_area == 10133.0

        new_area = sum(sf.st_area(buff_spdf))
        @test new_area > 438440 && new_area < 438470
    end

    @testset "st_cast combine - full example" begin
        # aggregate from Point -> MultiPolygon by 1 step
        point_spdf = sf.st_cast(spdf, "point")

        multipoint_spdf = sf.st_cast(point_spdf, "multipoint", groupid="_MultiPointID")
        ls_spdf = sf.st_cast(multipoint_spdf, "linestring")
        mls_spdf = sf.st_cast(ls_spdf, "multilinestring"; groupid="_MultiLineStringID")
        polygon_spdf = sf.st_cast(mls_spdf, "polygon")
        multipolygon_spdf = sf.st_cast(polygon_spdf, "multipolygon"; groupid="lyr.1")

        # check geom types following 1 step aggregate
        @test multipolygon_spdf.geomtype === AG.wkbMultiPolygon
        @test polygon_spdf.geomtype === AG.wkbPolygon
        @test mls_spdf.geomtype === AG.wkbMultiLineString
        @test ls_spdf.geomtype === AG.wkbLineString
        @test multipoint_spdf.geomtype === AG.wkbMultiPoint
        @test point_spdf.geomtype === AG.wkbPoint

        @test nrow(point_spdf.df) === 7572
        @test nrow(multipoint_spdf.df) === 1022
        @test nrow(ls_spdf.df) === 1022
        @test nrow(mls_spdf.df) === 1000
        @test nrow(polygon_spdf.df) === 1000
        @test nrow(multipolygon_spdf.df) === 2
    end

    @testset "Cast multipolygon to point - full st_cast test" begin
        # setup
        @test spdf.geomtype === AG.wkbPolygon
        mp_spdf = sf.st_cast(spdf, "multipolygon")
        @test mp_spdf.geomtype === AG.wkbMultiPolygon

        # cast from MultiPolygon -> Point by 1 step
        p_spdf = sf.st_cast(mp_spdf, "polygon")
        mls_spdf = sf.st_cast(p_spdf, "multilinestring")
        ls_spdf = sf.st_cast(mls_spdf, "linestring")
        multipoint_spdf = sf.st_cast(ls_spdf, "multipoint")
        point_spdf = sf.st_cast(multipoint_spdf, "point")

        # check geom types following 1 step cast
        @test p_spdf.geomtype === AG.wkbPolygon
        @test mls_spdf.geomtype === AG.wkbMultiLineString
        @test ls_spdf.geomtype === AG.wkbLineString
        @test multipoint_spdf.geomtype === AG.wkbMultiPoint
        @test point_spdf.geomtype === AG.wkbPoint

        # cast from MultiPolygon to geometries more than 1 step down
        mls_spdf_2 = sf.st_cast(mp_spdf, "multilinestring")
        ls_spdf_2 = sf.st_cast(mp_spdf, "linestring")
        multipoint_spdf_2 = sf.st_cast(mp_spdf, "multipoint")
        point_spdf_2 = sf.st_cast(mp_spdf, "point")

        # check geom types following multi-step cast
        @test mls_spdf_2.geomtype === AG.wkbMultiLineString
        @test ls_spdf_2.geomtype === AG.wkbLineString
        @test multipoint_spdf_2.geomtype === AG.wkbMultiPoint
        @test point_spdf_2.geomtype === AG.wkbPoint

        # check if output is same from single and multistep cast
        @test mls_spdf == mls_spdf_2
        @test ls_spdf == ls_spdf_2
        @test multipoint_spdf == multipoint_spdf_2
        @test point_spdf == point_spdf_2
    end

    @testset "combine geometries" begin
        @test DataFrames.nrow(spdf.df) === 1000
        combined_spdf = sf.st_combine(spdf)
        @test DataFrames.nrow(combined_spdf.df) === 1
        @test occursin("Multi", string(combined_spdf.geomtype))

    end

    @testset "segmentize a line" begin
        ls_spdf = sf.st_cast(spdf, "linestring")
        segmented = sf.st_segmentize(ls_spdf, 1)

        segmented_pts = sf.st_cast(segmented, "point")
        original_pts = sf.st_cast(ls_spdf, "point")

        @test nrow(original_pts.df) === 7572
        @test nrow(segmented_pts.df) === 13950
    end

    @testset "create bounding box" begin
        bbox = sf.st_bbox(spdf)
        @test AG.getgeomtype(bbox) === AG.wkbPolygon
        @test length(GeoInterface.coordinates(bbox)[1]) === 5
    end

    @testset "df to sf test" begin
        df = DataFrames.select(spdf.df, Not(:geom))
        df.geom = sf.sfgeom_to_gdal(spdf.df.geom)

        @test typeof(df) === DataFrame
        @test typeof(df.geom[1]) === AG.IGeometry{AG.wkbPolygon}

        copy_spdf = sf.df_to_sf(df, spdf.crs)
        @test typeof(copy_spdf) === sf.SimpleFeature
        @test copy_spdf == spdf
    end
end