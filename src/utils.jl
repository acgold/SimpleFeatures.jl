"""
    toProjJSON(spref::AbstractSpatialRef)

Convert this SRS into ProjJSON format.
"""
function toProjJSON(spref::AG.AbstractSpatialRef)::Dict
    ppszReturn = Ref{Cstring}(C_NULL)
    papszOptions = Ref{Cstring}(C_NULL)
    result = AG.GDAL.osrexporttoprojjson(spref.ptr, ppszReturn, papszOptions)
    # @ogrerror result "Failed to convert this SRS into WKT format"
    return JSON.parse(unsafe_string(ppszReturn[]))
end


"""
    toWKT2(spref::AbstractSpatialRef)
    
Convert this SRS into WKT2 format.
"""
function toWKT2(spref::AG.AbstractSpatialRef)::String
    ppszReturn = Ref{Cstring}(C_NULL)
    papszOptions = Ref{Cstring}(["FORMAT=WKT2_2018", "MULTILINE=NO"])
    result = AG.GDAL.osrexporttowktex(spref.ptr, ppszReturn, papszOptions)
    # @ogrerror result "Failed to convert this SRS into WKT format"
    return unsafe_string(ppszReturn[])
end