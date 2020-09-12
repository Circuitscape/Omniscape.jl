using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = [
    		"assets/custom.css"
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
    		 "User Guide" => "usage.md",],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git",
    devbranch = "main"
)
