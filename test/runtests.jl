using Test, Omniscape

d = run_omniscape("input/config2.ini")
a, b, c = run_omniscape("input/config.ini")

e,f,g = run_omniscape("input/config3.ini")

@test typeof(a) == Array{Float64,2}
@test typeof(b) == Array{Float64,2}
@test typeof(c) == Array{Float64,2}
@test typeof(d) == Array{Float64,2}
@test typeof(f) == Array{Float64,2}
@test b ≈ d

rm("test1_output", recursive = true)
rm("test2_output", recursive = true)
rm("test3_output", recursive = true)