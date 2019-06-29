using DelimitedFiles, Test, Circuitscape
using Omniscape

@test typeof(run_omniscape("input/config.ini")) == Tuple{Array{Float64,2},Array{Float64,2},Array{Float64,2}}

rm("test1_output", recursive = true)