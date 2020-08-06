using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = ["assets/custom.css"],
	edit_link = "main",
    ),
]

makedocs(
	format = formats,
    modules = [Omniscape],
    authors = "Vincent A. Landau",
    sitename = "Omniscape.jl",
    pages = ["Home" => "index.md",
    		 "Usage" => "usage.md",],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git",
    devbranch = "main"
)
