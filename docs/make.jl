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
        "Getting started" => "getting_started.md",
        "How it works" => "how_it_works.md",
        "Long-term goals" => "long_term_goals.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/acgold/SimpleFeatures.jl",
    devbranch="main",
)
