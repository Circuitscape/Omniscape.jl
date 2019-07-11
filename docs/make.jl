using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = ["assets/custom.css"],
    ),
]

makedocs(
	format = formats,
    modules = [Omniscape],
    authors = "Vincent A. Landau",
    sitename = "Omniscape.jl",
    pages = ["Home" => "index.md"],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git"
)