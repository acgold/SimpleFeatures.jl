using SimpleFeatures
using Documenter

DocMeta.setdocmeta!(SimpleFeatures, :DocTestSetup, :(using SimpleFeatures); recursive=true)

makedocs(;
    modules=[SimpleFeatures],
    authors="Adam Gold",
    repo="https://github.com/acgold/SimpleFeatures.jl/blob/{commit}{path}#{line}",
    sitename="SimpleFeatures.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://acgold.github.io/SimpleFeatures.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/acgold/SimpleFeatures.jl",
    devbranch="main",
)
