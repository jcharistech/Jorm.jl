using Jorm
using Documenter

DocMeta.setdocmeta!(Jorm, :DocTestSetup, :(using Jorm); recursive=true)

makedocs(;
    modules=[Jorm],
    authors="Jesse E.Agbe (Jcharis) <jcharistech@gmail.com> and contributors",
    sitename="Jorm.jl",
    format=Documenter.HTML(;
        canonical="https://jcharistech.github.io/Jorm.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Jorm.jl with WebApps" => "working_with_webapps.md",
        "API Reference" => "apireference.md",
    ],
)

deploydocs(;
    repo="github.com/jcharistech/Jorm.jl",
    devbranch="main",
)
