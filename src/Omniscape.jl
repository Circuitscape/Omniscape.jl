module Omniscape
using Circuitscape
using DelimitedFiles
using Base.Threads


include("config.jl")
include("functions.jl")
include("io.jl")
include("run_omniscape.jl")
export run_omniscape

end