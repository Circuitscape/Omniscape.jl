using Test, Omniscape

a, b, c = run_omniscape("input/config.ini")

d = run_omniscape("input/config2.ini")

@test typeof(a) == Array{Float64,2}
@test typeof(b) == Array{Float64,2}
@test typeof(c) == Array{Float64,2}
@test typeof(d) == Array{Float64,2}
@test b ≈ d

rm("test1_output", recursive = true)
rm("test2_output", recursive = true)