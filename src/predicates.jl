function st_intersects(x::SimpleFeature, y::SimpleFeature; geom_column=:geom, sparse::Bool=true)
    geom_list_x = sfgeom_to_geos.(x[:, geom_column])
    geom_list_y = sfgeom_to_geos.(y[:, geom_column])

    tree = LibGEOS.STRtree(geom_list_x)

    int_mat = Array{Bool}(undef, length(geom_list_x), length(geom_list_y))

    for (index,value) in enumerate(geom_list_y)
        int = LibGEOS.query(tree, value)
        
        int_col = [i in int for i in geom_list_x]
        int_mat[:,index] = int_col
    end

    if sparse === true
        sparse_vector = Vector()
        
        for (index,value) in enumerate(int_mat[:,1])
            push!(sparse_vector,findall(int_mat[index,:]))
        end

        return sparse_vector
    end

    return int_mat
end

function st_intersection(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)::SimpleFeature
    geom_list_x = sfgeom_to_geos.(x[:, geom_column])
    geom_list_y = sfgeom_to_geos.(y[:, geom_column])

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

    x_vector = findall(isempty.(int_vector) .== false)

    new_x = x[x_vector,:]

    new_df = DataFrame()

    for (index, value) in enumerate(int_vector)
        [append!(new_df, hcat(DataFrame(x.df[index,:]),DataFrames.select(DataFrame(new_y), Not(geom_column)), makeunique=true)) for new_y in eachrow(y.df[sparse_vector[index],:])]
    end

    return SimpleFeature(new_df, x.crs, x.geomtype) # To-do: check geomtype after intersection
end