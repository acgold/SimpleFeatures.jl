# using Revise
import SimpleFeatures as sf
import GeoDataFrames as GDF
using DataFrames
import GeoFormatTypes as GFT
using Test
using Downloads
import ArchGDAL as AG
import BenchmarkTools

const testdatadir = joinpath(@__DIR__, "data")
isdir(testdatadir) || mkdir(testdatadir)

Downloads.download("https://github.com/acgold/SimpleFeatures.jl/raw/main/test/data/test.gpkg", joinpath(testdatadir, "test.gpkg"))

spdf = sf.st_read(joinpath(testdatadir, "test.gpkg"))

@testset "SimpleFeatures.jl" begin

    # IO
    @testset "Reading spatial DataFrame" begin
        @test DataFrames.nrow(spdf) == 1000
        @test typeof(sf.st_crs(spdf)) == GFT.WellKnownText2{GFT.Unknown}
        @test DataFrames.hasmetadata(spdf) == true
        @test sf.st_is_spdf(spdf) == true
    end

    @testset "Writing spatial DataFrame" begin
        sf.st_write(joinpath(testdatadir, "new_test.gpkg"), spdf)
        @test isfile(joinpath(testdatadir, "new_test.gpkg"))
        new_spdf = sf.st_read(joinpath(testdatadir, "new_test.gpkg"))
        @test sf.st_is_spdf(new_spdf)
        @test spdf == new_spdf
    end

    # Operations
    @testset "crs metadata related functions" begin
        original_crs = sf.st_crs(spdf)
        @test original_crs == GFT.WellKnownText2{GFT.Unknown}(GFT.Unknown(), "PROJCRS[\"NAD83(2011) / UTM zone 17N\",BASEGEOGCRS[\"NAD83(2011)\",DATUM[\"NAD83 (National Spatial Reference System 2011)\",ELLIPSOID[\"GRS 1980\",6378137,298.257222101,LENGTHUNIT[\"metre\",1]]],PRIMEM[\"Greenwich\",0,ANGLEUNIT[\"degree\",0.0174532925199433]],ID[\"EPSG\",6318]],CONVERSION[\"UTM zone 17N\",METHOD[\"Transverse Mercator\",ID[\"EPSG\",9807]],PARAMETER[\"Latitude of natural origin\",0,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8801]],PARAMETER[\"Longitude of natural origin\",-81,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8802]],PARAMETER[\"Scale factor at natural origin\",0.9996,SCALEUNIT[\"unity\",1],ID[\"EPSG\",8805]],PARAMETER[\"False easting\",500000,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8806]],PARAMETER[\"False northing\",0,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8807]]],CS[Cartesian,2],AXIS[\"(E)\",east,ORDER[1],LENGTHUNIT[\"metre\",1]],AXIS[\"(N)\",north,ORDER[2],LENGTHUNIT[\"metre\",1]],USAGE[SCOPE[\"Engineering survey, topographic mapping.\"],AREA[\"United States (USA) - between 84°W and 78°W onshore and offshore - Florida; Georgia; Kentucky; Maryland; Michigan; New York; North Carolina; Ohio; Pennsylvania; South Carolina; Tennessee; Virginia; West Virginia.\"],BBOX[23.81,-84,46.13,-78]],ID[\"EPSG\",6346]]")
        copy_spdf = deepcopy(spdf)
        sf.st_set_crs(copy_spdf, GFT.EPSG(5070))
        @test sf.st_crs(copy_spdf) == GFT.EPSG(5070)
    end

    @testset "projecting spatial DataFrame w/st_transform" begin        
        proj_spdf = sf.st_transform(spdf, GFT.EPSG(5070))
        new_crs = sf.st_crs(proj_spdf)
        @test new_crs == GFT.EPSG(5070)
        @test spdf.geom[1] !== proj_spdf.geom[1]
    end

    @testset "buffer spatial DataFrame" begin
        buff_spdf = sf.st_buffer(spdf, 10)
        original_area = sum(GDF.geomarea(sf.sfgeom_to_gdal.(spdf.geom)))
        @test original_area == 10133.0

        new_area = sum(GDF.geomarea(sf.sfgeom_to_gdal.(buff_spdf.geom)))
        @test new_area > 436490 && new_area < 436550
    end

    @testset "st_cast combine - full example" begin
        # aggregate from Point -> MultiPolygon by 1 step
        point_spdf = sf.st_cast(spdf, "point")

        multipoint_spdf = sf.st_cast(point_spdf, "multipoint"; groupid="_MultiPointID")
        ls_spdf = sf.st_cast(multipoint_spdf, "linestring")
        mls_spdf = sf.st_cast(ls_spdf, "multilinestring"; groupid="_MultiLineStringID")
        polygon_spdf = sf.st_cast(mls_spdf, "polygon")
        multipolygon_spdf = sf.st_cast(polygon_spdf, "multipolygon"; groupid="lyr.1")

        # check geom types following 1 step aggregate
        @test sf.st_geomtype(multipolygon_spdf) === AG.wkbMultiPolygon
        @test sf.st_geomtype(polygon_spdf) === AG.wkbPolygon
        @test sf.st_geomtype(mls_spdf) === AG.wkbMultiLineString
        @test sf.st_geomtype(ls_spdf) === AG.wkbLineString
        @test sf.st_geomtype(multipoint_spdf) === AG.wkbMultiPoint
        @test sf.st_geomtype(point_spdf) === AG.wkbPoint

        @test nrow(point_spdf) === 7572
        @test nrow(multipoint_spdf) === 1022
        @test nrow(ls_spdf) === 1022
        @test nrow(mls_spdf) === 1000
        @test nrow(polygon_spdf) === 1000
        @test nrow(multipolygon_spdf) === 2
    end

    @testset "replacing metadata" begin
        copy1 = deepcopy(spdf)
        copy2 = deepcopy(spdf)

        @test sf.st_crs(copy1) === sf.st_crs(copy2)
        @test sf.st_geomtype(copy1) === sf.st_geomtype(copy2)

        meta_x = DataFrames.metadata(copy1)
        sf.st_set_crs(copy1, GFT.EPSG(5070))
        sf.st_set_geomtype(copy1, AG.wkbLineString)

        @test sf.st_crs(copy1) === GFT.EPSG(5070)
        @test sf.st_geomtype(copy1) === AG.wkbLineString
        sf.replace_metadata!(copy1, copy2)

        @test sf.st_crs(copy1) === sf.st_crs(copy2)
        @test sf.st_geomtype(copy1) === sf.st_geomtype(copy2)
    end

    @testset "Cast multipolygon to point - full st_cast test" begin
        # setup
        @test sf.st_geomtype(spdf) === AG.wkbPolygon
        mp_spdf = sf.st_cast(spdf, "multipolygon")
        @test sf.st_geomtype(mp_spdf) === AG.wkbMultiPolygon

        # cast from MultiPolygon -> Point by 1 step
        p_spdf = sf.st_cast(mp_spdf, "polygon")
        mls_spdf = sf.st_cast(p_spdf, "multilinestring")
        ls_spdf = sf.st_cast(mls_spdf, "linestring")
        multipoint_spdf = sf.st_cast(ls_spdf, "multipoint")
        point_spdf = sf.st_cast(multipoint_spdf, "point")

        # check geom types following 1 step cast
        @test sf.st_geomtype(p_spdf) === AG.wkbPolygon
        @test sf.st_geomtype(mls_spdf) === AG.wkbMultiLineString
        @test sf.st_geomtype(ls_spdf) === AG.wkbLineString
        @test sf.st_geomtype(multipoint_spdf) === AG.wkbMultiPoint
        @test sf.st_geomtype(point_spdf) === AG.wkbPoint

        # cast from MultiPolygon to geometries more than 1 step down
        mls_spdf_2 = sf.st_cast(mp_spdf, "multilinestring")
        ls_spdf_2 = sf.st_cast(mp_spdf, "linestring")
        multipoint_spdf_2 = sf.st_cast(mp_spdf, "multipoint")
        point_spdf_2 = sf.st_cast(mp_spdf, "point")

        # check geom types following multi-step cast
        @test sf.st_geomtype(mls_spdf_2) === AG.wkbMultiLineString
        @test sf.st_geomtype(ls_spdf_2) === AG.wkbLineString
        @test sf.st_geomtype(multipoint_spdf_2) === AG.wkbMultiPoint
        @test sf.st_geomtype(point_spdf_2) === AG.wkbPoint
       
        # check if output is same from single and multistep cast
        @test mls_spdf == mls_spdf_2
        @test ls_spdf == ls_spdf_2
        @test multipoint_spdf == multipoint_spdf_2
        @test point_spdf == point_spdf_2
    end

    @testset "segmentize a line" begin
        ls_spdf = sf.st_cast(spdf, "linestring")
        segmented = sf.st_segmentize(ls_spdf, 1)

         segmented_pts = sf.st_cast(segmented, "point")
         original_pts = sf.st_cast(ls_spdf, "point")

        @test nrow(original_pts) === 7572
        @test nrow(segmented_pts) === 13950
    end
end