"""
    st_nearest_points(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)

Returns a SimpleFeature object of lines between nearest points of each feature in `x` to `y` and columns indicating which row of x and y each line refers to.
"""
function st_nearest_points(x::SimpleFeature, y::SimpleFeature; geom_column=:geom)::SimpleFeature
    geom_list_x = from_sfgeom.(x.df[:, geom_column], to = "libgeos")
    geom_list_y = from_sfgeom.(y.df[:, geom_column], to = "libgeos")

    x_rownumbers = rownumber.(eachrow(x.df))
    y_rownumbers = rownumber.(eachrow(y.df))

    x_key = reduce(append!, fill.(x_rownumbers, length(y_rownumbers)), init=Int[])
    y_key = repeat(y_rownumbers, length(x_rownumbers))

    geom_list = []

    for i in geom_list_x
        for j in geom_list_y
            push!(geom_list, LibGEOS.nearestPoints(i, j))
        end
    end

    new_line_list = Vector{AG.AbstractGeometry}()

    for i in geom_list
        new_line = AG.createlinestring()
        pts = GeoInterface.coordinates.(i)
        AG.addpoint!(new_line, pts[1][1], pts[1][2])
        AG.addpoint!(new_line, pts[2][1], pts[2][2])

        push!(new_line_list, new_line)
    end

    return SimpleFeature(DataFrames.DataFrame(x_row = x_key, y_row = y_key, geom = to_sfgeom(new_line_list)), x.crs, AG.wkbLineString)
end