"""
    st_area(x::SimpleFeature; geom_column=:geom)

Returns a vector of geometry areas in units of the crs.
"""
function st_area(x::SimpleFeature; geom_column=:geom)::Vector
    geom_list = sfgeom_to_geos.(x.df[:, geom_column])
    return LibGEOS.area.(geom_list)
end

"""
    st_distance(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)

Returns a matrix of distances between each x and y geometry in units of the crs.
"""
function st_distance(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)::Matrix
    geom_list_x = sfgeom_to_geos.(x.df[:, geom_column])
    geom_list_y = sfgeom_to_geos.(y.df[:, geom_column])

    dist_mat =  Array{Real}(undef, length(geom_list_x), length(geom_list_y))

    for (x_index,x_value) in enumerate(geom_list_x)
        for (y_index, y_value) in enumerate(geom_list_y)
            dist_mat[x_index, y_index] = LibGEOS.distance(x_value, y_value)
        end
    end

    return dist_mat
end

"""
    st_length(x::SimpleFeature; geom_column=:geom)

Returns a vector of geometry lengths in units of the crs.
"""
function st_length(x::SimpleFeature; geom_column=:geom)::Vector
    geom_list = sfgeom_to_geos.(x.df[:, geom_column])
    return LibGEOS.geomLength.(geom_list)
end