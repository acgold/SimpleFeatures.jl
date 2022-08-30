"""
    st_disjoint(x::SimpleFeature, y::SimpleFeature; geom_column=:geom, sparse::Bool=true)

Returns a sparse index list of disjoint features.
"""
function st_disjoint(x::SimpleFeature, y::SimpleFeature; geom_column=:geom, sparse::Bool=true)
    geom_list_x = from_sfgeom.(x[:, geom_column], to = "geos")
    geom_list_y = from_sfgeom.(y[:, geom_column], to = "geos")

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

    disjoint_vector = Vector()
    for (index,value) in enumerate(sparse_vector)
        push!(disjoint_vector,[LibGEOS.disjoint(geom_list_x[index], y) for y in geom_list_y[value]])
    end

    final_sparse = Vector()
    for i in 1:length(sparse_vector)
        push!(final_sparse, sparse_vector[i][disjoint_vector[i]])
    end

    disjoint_mat = int_mat .=== false    

    for i in 1:length(final_sparse)
        disjoint_mat[i, final_sparse[i]] .= 1
    end

    disjoint_sparse_vector = Vector()

    for (index,value) in enumerate(disjoint_mat[:,1])
        push!(disjoint_sparse_vector,findall(disjoint_mat[index,:]))
    end

    return disjoint_sparse_vector
end

"""
    st_intersects(x::SimpleFeature, y::SimpleFeature; geom_column=:geom, sparse::Bool=true)

Returns a sparse index list of intersecting features.
"""
function st_intersects(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)
    geom_list_x = from_sfgeom.(x[:, geom_column], to = "geos")
    geom_list_y = from_sfgeom.(y[:, geom_column], to = "geos")

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
        push!(int_vector,[LibGEOS.intersects(geom_list_x[index], y) for y in geom_list_y[value]])
    end

    final_sparse = Vector()
    for i in 1:length(sparse_vector)
        push!(final_sparse, sparse_vector[i][int_vector[i]])
    end

    return final_sparse
end