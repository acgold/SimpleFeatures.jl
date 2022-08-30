# https://stackoverflow.com/questions/72387803/how-to-use-a-continuous-color-scale-in-a-thematic-map-using-julia-and-plots-jl
@recipe function f(x::SimpleFeature; fill_col=nothing)
    aspect_ratio --> :equal
    if fill_col !== nothing
        fill_z --> reshape(x[:, fill_col], 1, nrow(x))
    end
    from_sfgeom(x.df.geom, to = "gdal")
end

@recipe function f(x::Vector{SimpleFeature})
    aspect_ratio --> :equal

    plot_data = Vector{AG.AbstractGeometry}()

    plot_colors = []
    for i in x
        append!(plot_data, from_sfgeom(i.df.geom, to = "gdal"))
    end
    plot_data
end