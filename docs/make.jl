# Fixes GR warnings in Travis
ENV["GKSwstype"] = "100"

using Documenter, Omniscape

const formats = Any[
    Documenter.HTML(
    	assets = [
    		"assets/custom.css"
    	],
	edit_link = :commit,
    ),
]

makedocs(
	format = formats,
    modules = [Omniscape],
    authors = "Vincent A. Landau",
    sitename = "Omniscape.jl",
    pages = ["About" => "index.md",
			 "How It Works" => "algorithm.md",
    		 "User Guide" => "usage.md",
			 "Examples" => "examples.md",
			 "API Documentation" => "apidocs.md"],
)

deploydocs(
    repo = "github.com/Circuitscape/Omniscape.jl.git",
    devbranch = "main",
    devurl = "latest"
)
