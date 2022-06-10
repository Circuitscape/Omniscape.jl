using Test, Omniscape, Circuitscape

@testset "Internals" begin
    ### Unit tests for components
    ## source target matching
    source_subset = [1.0 1 1 1 1 1 1 1 1 1; # 6x10 array
                    1 1 1 1 1 1 1 1 1 1;
                    1 1 1 1 1 1 1 1 1 1;
                    1 1 1 1 1 1 1 1 1 1;
                    1 1 1 1 1 1 1 1 1 1;
                    1 1 1 1 1 1 1 1 1 1]

    con1pres =   [1.0 4 3 2 7 6 9 2 3 0;
                    4 2 6 5 3 9 4 5 3 3;
                    1 1 5 2 7 7 8 8 9 1;
                    8 7 6 5 5 5 0 0 1 1;
                    3 5 4 4 4 8 5 0 1 8;
                    1 2 8 2 1 6 5 5 8 7]

    con1fut =   [2.0 1 3 2 7 6 7 1 3 0;
                4 2 4 5 3 9 4 5 5 3;
                3 8 3 2 6 3 8 5 9 1;
                8 7 6 5 1 5 0 0 1 1;
                3 1 4 5 4 8 5 7 1 8;
                5 2 3 2 1 6 4 5 3 7]
    x = 5
    y = 4
    con1_lower = -1.0
    con1_upper = 1.0
    source_subset = convert(Array{Union{Float64, Missing}, 2}, source_subset)

    condition_layers = Omniscape.ConditionLayers(
        convert(Array{Union{Float64, Missing}, 2}, con1pres),
        convert(Array{Union{Float64, Missing}, 2}, con1fut),
        Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        Array{Union{Float64, Missing}, 2}(undef, 1, 1)
    )

    Omniscape.source_target_match!(source_subset,
                        1,
                        condition_layers,
                        Omniscape.Conditions(
                            "within",
                            "within",
                            con1_lower,
                            con1_upper,
                            0.0,
                            0.0
                        ),
                        y,
                        y,
                        x,
                        x,
                        1,
                        6,
                        1,
                        10
                        )
    target_val = con1fut[y, x]
    # Make sure no present day vals in con1 are outside of range
    @test sum((con1pres[source_subset .== 1] .< (target_val + con1_lower)) .|
        (con1pres[source_subset .== 1] .> (target_val + con1_upper))) == 0
    @info "conditional connectivity tests passed"

    ## Check that targets are IDed properly
    source_strength = Omniscape.read_raster("input/source.asc", Float64)[1]

    int_arguments = Dict{String, Int64}()
    int_arguments["block_size"] = 7
    int_arguments["block_radius"] = 3 # must be (size - 1) / 2
    int_arguments["nrows"] = size(source_strength)[1]
    int_arguments["ncols"] = size(source_strength)[2]
    targets = Omniscape.get_targets(source_strength,
                                    int_arguments,
                                    Float64)

    n_targets = floor(int_arguments["nrows"] / int_arguments["block_size"]) *
        floor(int_arguments["ncols"] / int_arguments["block_size"])

    # Correct number of targets
    @test size(targets)[1] == n_targets # would be less than if any sources
                                        # had 0 strength, but sources.asc does
                                        # not have 0's

    # correct source strength for a target
    block_sources = source_strength[
        Int(targets[1,2] - int_arguments["block_radius"]):Int(targets[1,2] + int_arguments["block_radius"]),
        Int(targets[1,1] - int_arguments["block_radius"]):Int(targets[1,1] + int_arguments["block_radius"])
    ]
    @test targets[1,3] ≈ sum(block_sources)
    @info "target tests passed"

    # Test error throws
    @info "Testing error throws"
    @test run_omniscape("input/config7.ini") === nothing
    @test run_omniscape("input/bad_config.ini") === nothing

    # Test chunk extent calculations
    include("chunks.jl")

end

@testset "run_omnsicape()" begin
## Tests for run_omniscape()
    l, f, p = run_omniscape("input/config4a.ini")
    l_verify = Omniscape.read_raster("output_verify/test4a/cum_currmap.tif", Float64)[1]
    f_verify = Omniscape.read_raster("output_verify/test4a/flow_potential.tif", Float64)[1]
    p_verify = Omniscape.read_raster("output_verify/test4a/normalized_cum_currmap.tif", Float64)[1]
    @test Omniscape.arrays_equal(l, l_verify)
    @test Omniscape.arrays_equal(f, f_verify)
    @test Omniscape.arrays_equal(p, p_verify)

    # Syntax checks for various methods of conditional comparisons
    l1, f1 = run_omniscape("input/config4b.ini")
    l2 = run_omniscape("input/config4c.ini")

    g = run_omniscape("input/config5.ini")
    g_verify = Omniscape.read_raster("output_verify/test5/cum_currmap.tif", Float64)[1]
    @test Omniscape.arrays_equal(g, g_verify)

    h = run_omniscape("input/config6.ini")
    h_verify = Omniscape.read_raster("output_verify/test6/cum_currmap.tif", Float64)[1]
    @test Omniscape.arrays_equal(h, h_verify)

    a, b, c = run_omniscape("input/config.ini")
    a_verify = Omniscape.read_raster("output_verify/test1/cum_currmap.tif", Float64)[1]
    b_verify = Omniscape.read_raster("output_verify/test1/flow_potential.tif", Float64)[1]
    c_verify = Omniscape.read_raster("output_verify/test1/normalized_cum_currmap.tif", Float64)[1]
    @test Omniscape.arrays_equal(a, a_verify)
    @test Omniscape.arrays_equal(b, b_verify)
    @test Omniscape.arrays_equal(c, c_verify)

    a1, b1, c1 = run_omniscape("input/config_32bit.ini")
    a1_verify = Omniscape.read_raster("output_verify/test1_32bit/cum_currmap.tif", Float32)[1]
    b1_verify = Omniscape.read_raster("output_verify/test1_32bit/flow_potential.tif", Float32)[1]
    c1_verify = Omniscape.read_raster("output_verify/test1_32bit/normalized_cum_currmap.tif", Float32)[1]
    @test Omniscape.arrays_equal(a1, a1_verify)
    @test Omniscape.arrays_equal(b1, b1_verify)
    @test Omniscape.arrays_equal(c1, c1_verify)

    q, e = run_omniscape("input/config3.ini")
    q_verify = Omniscape.read_raster("output_verify/test3/cum_currmap.asc", Float64)[1]
    e_verify = Omniscape.read_raster("output_verify/test3/flow_potential.asc", Float64)[1]
    @test Omniscape.arrays_equal(q, q_verify)
    @test Omniscape.arrays_equal(e, e_verify)

    d = run_omniscape("input/config2.ini")
    d_verify = Omniscape.read_raster("output_verify/test2/cum_currmap.asc", Float64)[1]
    @test Omniscape.arrays_equal(d, d_verify)
    d_1 = run_omniscape("input/config2.ini")
    d_2 = run_omniscape("input/config2.ini")

    reclassed = run_omniscape("input/config_reclass.ini")
    reclassed_verify = Omniscape.read_raster("output_verify/test_reclass/cum_currmap.asc", Float64)[1]
    @test Omniscape.arrays_equal(reclassed, reclassed_verify)

    @test typeof(f) == Array{Union{Float64, Missing},2}
    @test typeof(g) == Array{Union{Float64, Missing},2}
    @test typeof(h) == Array{Union{Float64, Missing},2}
    @test typeof(a) == Array{Union{Float64, Missing},2}
    @test typeof(b) == Array{Union{Float64, Missing},2}
    @test typeof(c) == Array{Union{Float64, Missing},2}
    @test typeof(a1) == Array{Union{Float32, Missing},2}
    @test typeof(b1) == Array{Union{Float32, Missing},2}
    @test typeof(c1) == Array{Union{Float32, Missing},2}
    @test typeof(d) == Array{Union{Float64, Missing},2}
    @test typeof(e) == Array{Union{Float64, Missing},2}
    @test typeof(reclassed) == Array{Union{Float64, Missing},2}
    @test Omniscape.arrays_equal(a, d) #parallel and serial produce same result

    # Single and double produce similar results
    @test Omniscape.arrays_equal(a, a1)
    @test Omniscape.arrays_equal(b, b1)
    @test Omniscape.arrays_equal(c, c1)

    GC.gc()

    rm("test1", recursive = true)
    rm("test1_32bit", recursive = true)
    rm("test2", recursive = true)
    rm("test2_1", recursive = true)
    rm("test2_2", recursive = true)
    rm("test3", recursive = true)
    rm("test4a", recursive = true)
    rm("test4b", recursive = true)
    rm("test4c", recursive = true)
    rm("test5", recursive = true)
    rm("test6", recursive = true)
    rm("test_reclass", recursive = true)

end