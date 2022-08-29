#------------ SimpleFeature type --------------------
mutable struct SimpleFeature
    df::DataFrames.AbstractDataFrame
    crs::GFT.GeoFormat
    geomtype::AG.OGRwkbGeometryType
end

# equality testing
Base.:(==)(a::SimpleFeature, b::SimpleFeature) = a.df == b.df && a.crs == b.crs && a.geomtype == b.geomtype

# Define printing behavior 
function Base.show(io::IO, x::SimpleFeature)
    ds = displaysize(io)

    printstyled(io, "SimpleFeature" * "\n", bold=true)
    println(io, "---------")

    printstyled(io, "geomtype:  "; color=:yellow)
    println(io, x.geomtype)

    if length(x.crs.val) < 100
        printstyled(io, "crs:   "; color=:yellow)
        println(io, x.crs.val)
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    elseif length(x.crs.val) >= 100
        printstyled(io, "crs:       "; color=:yellow)
        println(io, x.crs.val[1:100] * "...")
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    else
        println(io, "NO CRS INFO")
        println(io, "---------")
        printstyled(io, "features:  " * "\n"; color=:yellow)
        DataFrames.show(IOContext(io, :displaysize => (ds[1] - 6, ds[2])), x.df;)
    end
end


#------------ Indexing --------------------
Base.getindex(a::SimpleFeature, b) = SimpleFeature(DataFrames.getindex(a.df, b), a.crs, a.geomtype)

# Rows
Base.getindex(a::SimpleFeature, b::Int, c::Colon) = SimpleFeature(DataFrames.DataFrame(DataFrames.getindex(a.df, b, c)), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Int, c::typeof(!)) = SimpleFeature(DataFrames.DataFrame(DataFrames.getindex(a.df, b, c)), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Colon, c::Colon) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::typeof(!), c::typeof(!)) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Union{UnitRange{Int64},Vector{Int64}}, c::Colon) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Union{UnitRange{Int64},Vector{Int64}}, c::typeof(!)) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)

# Values
Base.getindex(a::SimpleFeature, b::Union{UnitRange{Int64},Vector{Int64}}, c::Union{Int,Symbol,String}) = DataFrames.getindex(a.df, b, c)
Base.getindex(a::SimpleFeature, b::Colon, c::Union{Int,Symbol,String}) = DataFrames.getindex(a.df, b, c)
Base.getindex(a::SimpleFeature, b::typeof(!), c::Union{Int,Symbol,String}) = DataFrames.getindex(a.df, b, c)
Base.getindex(a::SimpleFeature, b::Int, c::Union{Int,Symbol,String}) = DataFrames.getindex(a.df, b, c)

# Columns
Base.getindex(a::SimpleFeature, b::Colon, c::Union{UnitRange{Int64},Vector{Symbol},Vector{String},Vector{Int64}}) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::typeof(!), c::Union{UnitRange{Int64},Vector{Symbol},Vector{String},Vector{Int64}}) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Union{UnitRange{Int64},Vector{Int64}}, c::Union{UnitRange{Int64},Vector{Symbol},Vector{String},Vector{Int64}}) = SimpleFeature(DataFrames.getindex(a.df, b, c), a.crs, a.geomtype)
Base.getindex(a::SimpleFeature, b::Int64, c::Union{UnitRange{Int64},Vector{Symbol},Vector{String},Vector{Int64}}) = SimpleFeature(DataFrames.DataFrame(DataFrames.getindex(a.df, b, c)), a.crs, a.geomtype)

# Using Lazy.jl, forward setindex! to the df attribute of SimpleFeature b/c it modifies inplace - we don't want a SimpleFeature back
@forward SimpleFeature.df DataFrames.setindex!

#------------ Iteration & append! --------------------
# To avoid accomodating DataFrameRows (DFRs), we will force DFRs to DFs. This means we can iterate rows without using eachrow
DataFrames.eachrow(df::SimpleFeature) = SimpleFeature(DataFrames.DataFrame(DataFrames.eachrow(df.df)), df.crs, df.geomtype)
DataFrames.eachcol(df::SimpleFeature) = DataFrames.eachcol(df.df)

Base.iterate(r::SimpleFeature) = iterate(r, 1)

function Base.iterate(r::SimpleFeature, st)
    st > nrow(r.df) && return nothing
    return (SimpleFeature(DataFrames.DataFrame(r.df[st, :]), r.crs, r.geomtype), st + 1)
end

Base.first(df::SimpleFeature, n::Core.Integer=5) = SimpleFeature(DataFrames.first(df.df, n), df.crs, df.geomtype)
Base.last(df::SimpleFeature, n::Core.Integer=5) = SimpleFeature(DataFrames.last(df.df, n), df.crs, df.geomtype)

function Base.append!(x::SimpleFeature, y::SimpleFeature; kwargs...)
    if x.crs !== y.crs || x.geomtype !== y.geomtype
        error("CRS or geomtype are not equal between x and y")
    end

    SimpleFeature(DataFrames.append!(x.df, y.df), x.crs, x.geomtype)
end

#------------ Copy --------------------
Base.copy(x::SimpleFeature; copycols::Bool=true) = SimpleFeature(DataFrames.copy(x.df; copycols), x.crs, x.geomtype)
Base.deepcopy(x::SimpleFeature) = SimpleFeature(DataFrames.deepcopy(x.df), x.crs, x.geomtype)

#------------ DataFrames misc --------------------
DataFrames.nrow(df::SimpleFeature) = DataFrames.nrow(df.df)
DataFrames.ncol(df::SimpleFeature) = DataFrames.ncol(df.df)

DataFrames.select(df::SimpleFeature, args...; copycols::Bool=true, renamecols::Bool=true) = SimpleFeature(DataFrames.select(df.df, args...; copycols=copycols, renamecols=renamecols), df.crs, df.geomtype)
DataFrames.select!(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.select!(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.transform(df::SimpleFeature, args...; copycols::Bool=true, renamecols::Bool=true) = SimpleFeature(DataFrames.transform(df.df, args...; copycols=copycols, renamecols=renamecols), df.crs, df.geomtype)
DataFrames.transform!(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.transform!(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.combine(df::SimpleFeature, args...; renamecols::Bool=true) = SimpleFeature(DataFrames.combine(df.df, args...; renamecols=renamecols), df.crs, df.geomtype)

DataFrames.rename(df::SimpleFeature, d::AbstractDict) = SimpleFeature(DataFrames.rename(df.df, d), df.crs, df.geomtype)
DataFrames.rename!(df::SimpleFeature, d::AbstractDict) = DataFrames.rename!(df.df, d)

DataFrames.subset(df::SimpleFeature, args...; skipmissing::Bool=false, view::Bool=false) = SimpleFeature(DataFrames.subset(df.df, args...; skipmissing=skipmissing, view=view), df.crs, df.geomtype)
DataFrames.subset!(df::SimpleFeature, args...; skipmissing::Bool=false) = SimpleFeature(DataFrames.subset(df.df, args...; skipmissing=skipmissing), df.crs, df.geomtype)

#------------ DataFramesMeta misc --------------------
function DataFramesMeta.orderby(x::SimpleFeature, @nospecialize(args...))
    t = DataFrames.select(x.df, args...; copycols=false)
    SimpleFeature(x.df[sortperm(t), :], x.crs, x.geomtype)
end

DataFrames.names(itr::SimpleFeature) = DataFrames.names(itr.df)
DataFrames.propertynames(df::SimpleFeature) = DataFrames.propertynames(df.df)