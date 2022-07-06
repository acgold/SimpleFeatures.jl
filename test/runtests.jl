import SimpleFeatures as sf
import GeoDataFrames as GDF
using DataFrames
import GeoFormatTypes as GFT
using Test

spdf = sf.st_read("test/data/test.gpkg")

@testset "SimpleFeatures.jl" begin
    @testset "Reading spatial DataFrame" begin
        @test DataFrames.nrow(spdf) == 1000
        @test typeof(sf.st_crs(spdf)) == GFT.WellKnownText2{GFT.Unknown}
        @test DataFrames.hasmetadata(spdf) == true
        @test sf.st_is_spdf(spdf) == true
    end

    @testset "copy spatial DataFrame" begin
        copy_spdf = sf.st_copy(spdf)
        @test copy_spdf == spdf
    end

    @testset "projecting spatial DataFrame w/st_transform" begin
        original_crs = sf.st_crs(spdf)
        @test original_crs == GFT.WellKnownText2{GFT.Unknown}(GFT.Unknown(), "PROJCRS[\"NAD83(2011) / UTM zone 17N\",BASEGEOGCRS[\"NAD83(2011)\",DATUM[\"NAD83 (National Spatial Reference System 2011)\",ELLIPSOID[\"GRS 1980\",6378137,298.257222101,LENGTHUNIT[\"metre\",1]]],PRIMEM[\"Greenwich\",0,ANGLEUNIT[\"degree\",0.0174532925199433]],ID[\"EPSG\",6318]],CONVERSION[\"UTM zone 17N\",METHOD[\"Transverse Mercator\",ID[\"EPSG\",9807]],PARAMETER[\"Latitude of natural origin\",0,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8801]],PARAMETER[\"Longitude of natural origin\",-81,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8802]],PARAMETER[\"Scale factor at natural origin\",0.9996,SCALEUNIT[\"unity\",1],ID[\"EPSG\",8805]],PARAMETER[\"False easting\",500000,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8806]],PARAMETER[\"False northing\",0,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8807]]],CS[Cartesian,2],AXIS[\"(E)\",east,ORDER[1],LENGTHUNIT[\"metre\",1]],AXIS[\"(N)\",north,ORDER[2],LENGTHUNIT[\"metre\",1]],USAGE[SCOPE[\"Engineering survey, topographic mapping.\"],AREA[\"United States (USA) - between 84°W and 78°W onshore and offshore - Florida; Georgia; Kentucky; Maryland; Michigan; New York; North Carolina; Ohio; Pennsylvania; South Carolina; Tennessee; Virginia; West Virginia.\"],BBOX[23.81,-84,46.13,-78]],ID[\"EPSG\",6346]]")
        
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
        @test new_area == 438453.3303676341
    end
end
