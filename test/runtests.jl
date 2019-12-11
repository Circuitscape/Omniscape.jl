using Test, Omniscape

f = run_omniscape("input/config4.ini")
g = run_omniscape("input/config5.ini")
a, b, c = run_omniscape("input/config.ini")
e = run_omniscape("input/config3.ini")
d = run_omniscape("input/config2.ini")

rm("test1_output", recursive = true)
rm("test2_output", recursive = true)
rm("test3_output", recursive = true)
rm("test4_output", recursive = true)
rm("test5_output", recursive = true)

@test typeof(f) == Array{Float64,2}
@test typeof(g) == Array{Float64,2}
@test typeof(a) == Array{Float64,2}
@test typeof(b) == Array{Float64,2}
@test typeof(c) == Array{Float64,2}
@test typeof(d) == Array{Float64,2}
@test typeof(e) == Array{Float64,2}
@test b ≈ d