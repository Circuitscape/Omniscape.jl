using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = [
    		"assets/custom.css",
    		"figs/sources_block_of_1.png",
    		"figs/sources_block_of_3.png"
    	],
	edit_branch = "main",
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
