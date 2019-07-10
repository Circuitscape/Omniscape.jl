using Documenter, Omniscape

makedocs(
    modules = [Omniscape],
    authors = "Vincent A. Landau",
    sitename = "Omniscape.jl",
    pages = ["Home" => "index.md"],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git"
)