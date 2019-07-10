using Documenter, Omniscape

makedocs(
    modules = [Omniscape],
    authors = "Vincent A. Landau",
    sitename = "Omniscape.jl",
    pages = Any["index.md"],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git"
)