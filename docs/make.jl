using SnakeGames
using Documenter

makedocs(;
    modules=[SnakeGames],
    authors="Jun Tian <tianjun.cpp@gmail.com> and contributors",
    repo="https://github.com/JuliaReinforcementLearning/SnakeGames.jl/blob/{commit}{path}#L{line}",
    sitename="SnakeGames.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaReinforcementLearning.github.io/SnakeGames.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaReinforcementLearning/SnakeGames.jl",
)
