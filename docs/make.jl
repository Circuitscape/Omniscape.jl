using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = [
    		"assets/custom.css",
    		asset("figs/sources_block_of_1.png", class = :css, islocal = true),
    		asset("figs/sources_block_of_3.png", class = :css, islocal = true)
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
