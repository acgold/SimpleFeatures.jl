using Revise
import SimpleFeatures as sf
import GeoDataFrames as GDF
using DataFrames
import GeoFormatTypes as GFT
using Test
using Downloads
import ArchGDAL as AG

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

    @testset "copy spatial DataFrame" begin
        copy_spdf = sf.st_copy(spdf)
        @test copy_spdf == spdf
    end

    # Operations
    @testset "crs metadata related functions" begin
        original_crs = sf.st_crs(spdf)
        @test original_crs == GFT.WellKnownText2{GFT.Unknown}(GFT.Unknown(), "PROJCRS[\"NAD83(2011) / UTM zone 17N\",BASEGEOGCRS[\"NAD83(2011)\",DATUM[\"NAD83 (National Spatial Reference System 2011)\",ELLIPSOID[\"GRS 1980\",6378137,298.257222101,LENGTHUNIT[\"metre\",1]]],PRIMEM[\"Greenwich\",0,ANGLEUNIT[\"degree\",0.0174532925199433]],ID[\"EPSG\",6318]],CONVERSION[\"UTM zone 17N\",METHOD[\"Transverse Mercator\",ID[\"EPSG\",9807]],PARAMETER[\"Latitude of natural origin\",0,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8801]],PARAMETER[\"Longitude of natural origin\",-81,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8802]],PARAMETER[\"Scale factor at natural origin\",0.9996,SCALEUNIT[\"unity\",1],ID[\"EPSG\",8805]],PARAMETER[\"False easting\",500000,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8806]],PARAMETER[\"False northing\",0,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8807]]],CS[Cartesian,2],AXIS[\"(E)\",east,ORDER[1],LENGTHUNIT[\"metre\",1]],AXIS[\"(N)\",north,ORDER[2],LENGTHUNIT[\"metre\",1]],USAGE[SCOPE[\"Engineering survey, topographic mapping.\"],AREA[\"United States (USA) - between 84°W and 78°W onshore and offshore - Florida; Georgia; Kentucky; Maryland; Michigan; New York; North Carolina; Ohio; Pennsylvania; South Carolina; Tennessee; Virginia; West Virginia.\"],BBOX[23.81,-84,46.13,-78]],ID[\"EPSG\",6346]]")
        copy_spdf = sf.st_copy(spdf)
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
        original_area = sum(GDF.geomarea(spdf.geom))
        @test original_area == 10133.0

        new_area = sum(GDF.geomarea(buff_spdf.geom))
        @test new_area > 438450 && new_area < 438460
    end

    @testset "turn single geom into multigeom" begin
        multi_spdf = sf.geom_to_multigeom(spdf)
        @test DataFrames.nrow(spdf) === 1000
        @test DataFrames.nrow(multi_spdf) === 1
        @test sf.st_crs(spdf) === sf.st_crs(multi_spdf)
        @test sf.st_geomtype(spdf) === AG.wkbPolygon
        @test sf.st_geomtype(multi_spdf) === AG.wkbMultiPolygon
    end

    @testset "turn multigeom into single geoms" begin
        multi_spdf = sf.geom_to_multigeom(spdf)
        @test DataFrames.nrow(spdf) === 1000
        @test DataFrames.nrow(multi_spdf) === 1

        new_spdf = sf.multigeom_to_geom(multi_spdf)
        @test sf.st_crs(spdf) === sf.st_crs(new_spdf)
        @test sf.st_geomtype(spdf) === AG.wkbPolygon
        @test sf.st_geomtype(multi_spdf) === AG.wkbMultiPolygon
    end

    @testset "linestring to multipoint" begin
        linestring = AG.createlinestring([(i,i+1) for i in 1.0:3.0])
        x = DataFrames.DataFrame(lyr1 = 1, geom = linestring)
        sf.st_set_crs(x, GFT.EPSG(5070))
        sf.st_set_geomtype(x, AG.getgeomtype(x.geom[1]))

        @test sf.st_is_spdf(x)
        @test sf.st_geomtype(x) === AG.wkbLineString
        @test AG.ngeom(x.geom[1]) == 3

        mp_x = sf.linestring_to_multipoint(x)
        @test sf.st_is_spdf(mp_x)
        @test sf.st_geomtype(mp_x) === AG.wkbMultiPoint
        @test AG.ngeom(mp_x.geom[1]) == 3

    end

    @testset "replacing metadata" begin
        copy1 = sf.st_copy(spdf)
        copy2 = sf.st_copy(spdf)

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
end