
"""
    st_buffer(x::SimpleFeature, d::Number; geom_column=:geom)
    st_buffer(x::SimpleFeature, d::String; geom_column=:geom)

Create a new SimpleFeature object that is buffered by the provided distance `d` in units of the crs. `d` can be a number or a string representing the column of the SimpleFeature DataFrame that contains numbers to use for the buffer distance.
"""
function st_buffer(x::SimpleFeature, d::Real; geom_column=:geom, quadsegs::Int = 32)::SimpleFeature    
    geom_list = from_sfgeom.(x.df[:, geom_column], to = "libgeos")

    buffer_list = LibGEOS.buffer.(geom_list, d, quadsegs)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = to_sfgeom.(buffer_list)

    geom_type = AG.getgeomtype(from_sfgeom(new_df[1, geom_column], to = "archgdal"))

    return SimpleFeature(new_df, x.crs, geom_type)
end

function st_buffer(x::SimpleFeature, d::Union{String,Symbol}; geom_column=:geom, quadsegs::Int = 32)::SimpleFeature
    geom_list = from_sfgeom.(x.df[:, geom_column], to = "libgeos")

    buffer_list = LibGEOS.buffer.(geom_list, x.df[:, d], quadsegs)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[:, geom_column] = to_sfgeom.(buffer_list)

    geom_type = AG.getgeomtype(from_sfgeom(new_df[1, geom_column], to = "archgdal"))

    return SimpleFeature(new_df, x.crs, geom_type)
end


"""
    st_centroid(x::SimpleFeature; geom_column=:geom)

Create a SimpleFeature object of point centroids of the input geometries.
"""
function st_centroid(x::SimpleFeature; geom_column=:geom)
    geom_list = from_sfgeom.(x.df[:, geom_column], to = "libgeos")

    cx = copy(x)
    cx[!,:geom] = to_sfgeom.(LibGEOS.centroid.(geom_list))
    cx.geomtype = AG.wkbPoint

    return cx
end

"""
    st_combine(x::SimpleFeature; geom_column=:geom)

Create a new SimpleFeature object that has combined all features into the relevant multigeometry type. No attributes of the original object are returned.
"""
function st_combine(x::SimpleFeature; geom_column=:geom)
    # breakdown into single geoms, then multigeom everything
    if occursin("Multi", string(x.geomtype)) === true
        geom_type = x.geomtype
        idx_from = findfirst(item -> item == (geom_type), decompose_types)
        multi = decompose_names[idx_from]
        single = decompose_names[idx_from+1]

        combined = st_cast(st_cast(x, single), multi; warn=false)
        combined.df = DataFrames.select!(combined.df, :geom)

        return combined

    elseif occursin("Multi", string(x.geomtype)) === false
        geom_type = x.geomtype
        idx_from = findfirst(item -> item == (geom_type), decompose_types)
        multi = decompose_names[idx_from-1]

        combined = st_cast(x, multi; warn=false)
        combined.df = DataFrames.select!(combined.df, :geom)

        return combined
    end
end

"""
    st_difference(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)

Create a new SimpleFeature object that is the difference of `x` and `y` in the geometry type of `x`.
"""
function st_difference(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)::SimpleFeature
    geom_list_x = from_sfgeom.(x[:, geom_column], to = "libgeos")
    geom_list_y = from_sfgeom.(y[:, geom_column], to = "libgeos")

    tree = LibGEOS.STRtree(geom_list_x)

    int_mat = Array{Bool}(undef, length(geom_list_x), length(geom_list_y))

    for (index,value) in enumerate(geom_list_y)
        int = LibGEOS.query(tree, value)
        
        int_col = [i in int for i in geom_list_x]
        int_mat[:,index] = int_col
    end

    sparse_vector = Vector()
        
    for (index,value) in enumerate(int_mat[:,1])
        push!(sparse_vector,findall(int_mat[index,:]))
    end

    diff_vector = Vector()
    for (index,value) in enumerate(sparse_vector)
        push!(diff_vector,[LibGEOS.difference(geom_list_x[index], y) for y in geom_list_y[value]])
    end

    x_vector = []

    for (index,value) in enumerate(sparse_vector)
        if isempty(value) === false
            push!(x_vector, index)
        else
            push!(x_vector,nothing)
        end
    end

    new_df = copy(x)

    combined = @subset(DataFrame(x = x_vector, sparse = sparse_vector, diffs = diff_vector), @byrow :x !== nothing)

    for row in eachrow(combined)

        for (index,value) in enumerate(row.sparse)
            geos_diffs = row.diffs[index]

            if LibGEOS.isEmpty(geos_diffs) === false
                new_df[row.x,geom_column] = to_sfgeom(geos_diffs)
            end
        end
    end

    geomtype = AG.getgeomtype(from_sfgeom(new_df[1,geom_column], to = "archgdal"))

    return new_df
end

"""
    st_intersection(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)

Create a new SimpleFeature object that is the intersection of `x` and `y` in the geometry type of `y`.
"""
function st_intersection(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)::SimpleFeature
    geom_list_x = from_sfgeom.(x[:, geom_column], to = "libgeos")
    geom_list_y = from_sfgeom.(y[:, geom_column], to = "libgeos")

    tree = LibGEOS.STRtree(geom_list_x)

    int_mat = Array{Bool}(undef, length(geom_list_x), length(geom_list_y))

    for (index,value) in enumerate(geom_list_y)
        int = LibGEOS.query(tree, value)
        
        int_col = [i in int for i in geom_list_x]
        int_mat[:,index] = int_col
    end

    sparse_vector = Vector()
        
    for (index,value) in enumerate(int_mat[:,1])
        push!(sparse_vector,findall(int_mat[index,:]))
    end

    int_vector = Vector()
    for (index,value) in enumerate(sparse_vector)
        push!(int_vector,[LibGEOS.intersection(geom_list_x[index], y) for y in geom_list_y[value]])
    end

    x_vector = []

    for (index,value) in enumerate(sparse_vector)
        if isempty(value) === false
            push!(x_vector, index)
        else
            push!(x_vector,nothing)
        end
    end

    new_df = DataFrame()

    combined = @subset(DataFrame(x = x_vector, sparse = sparse_vector, ints = int_vector), @byrow :x !== nothing)

    for row in eachrow(combined)

        x_df = DataFrames.select(DataFrame(x.df[row.x,:]), Not(geom_column))

        for (index,value) in enumerate(row.sparse)
            y_df = DataFrames.select(DataFrame(y.df[value,:]), Not(geom_column))

            geos_int = row.ints[index]

            if LibGEOS.isEmpty(geos_int) === false
                y_df[!,geom_column] = [to_sfgeom(geos_int)]
                append!(new_df, hcat(x_df, y_df, makeunique = true))
            end
        end
    end

    geomtype = AG.getgeomtype(from_sfgeom(new_df[1,geom_column], to = "archgdal"))

    return SimpleFeature(new_df, x.crs, geomtype) 
end


"""
    st_segmentize(x::SimpleFeature, max_length::Number; geom_column=:geom)

Create a new SimpleFeature object whose segments have been sliced into segments no larger than the provided `max_length` in units of the crs. See `ArchGDAL.segmentize!` for more info
"""
function st_segmentize(x::SimpleFeature, max_length::Real; geom_column=:geom)::SimpleFeature
    geom_list = from_sfgeom.(x.df[:, geom_column], to = "archgdal")

    segmented_list = AG.segmentize!.(geom_list, max_length)

    new_df = DataFrames.select(x.df, Not(geom_column))
    new_df[!, geom_column] = to_sfgeom.(segmented_list)

    return SimpleFeature(new_df, x.crs, x.geomtype)
end

"""
    st_simplify(x::SimpleFeature; geom_column=:geom)

Create a SimpleFeature object with simplified input geometries.
"""
function st_simplify(x::SimpleFeature, tol::Real=0, preserve_topology::Bool=true; geom_column=:geom)
    cx = copy(x)
    geom_list = from_sfgeom.(cx.df[:, geom_column], to = "libgeos")

    if preserve_topology === true
        cx[!,:geom] = to_sfgeom.(LibGEOS.topologyPreserveSimplify.(geom_list, tol))
    elseif preserve_topology === false
        cx[!,:geom] = to_sfgeom.(LibGEOS.simplify.(geom_list, tol))
    else
        error("preserve_topology is invalid value")
    end

    return cx
end

"""
    st_union(x::SimpleFeature; geom_column=:geom)

Create a SimpleFeature object that unions all input geometries.
"""
function st_union(x::SimpleFeature; geom_column=:geom)
    combined_x = st_combine(x)
    geom_list = from_sfgeom.(combined_x.df[:, geom_column], to = "libgeos")

    combined_x[!,:geom] = [to_sfgeom(LibGEOS.unaryUnion(geom_list[1]))]
    combined_x.geomtype = AG.getgeomtype(from_sfgeom(combined_x.df.geom[1], to = "archgdal"))
    
    return combined_x
end