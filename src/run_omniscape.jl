"""
    run_omniscape("path/to/config.ini")

Run the Omniscape algorithm using the files and options specified in a .ini file

Visit https://circuitscape.github.io/Omniscape.jl/stable for detailed
documentation
"""
function run_omniscape(path::String)
    start_time = time()
    n_threads = nthreads()
    cfg_user = parse_cfg(path)
    cfg = init_cfg()
    update_cfg!(cfg, cfg_user)

    ## Set number of BLAS threads to 1
    BLAS.set_num_threads(1)

    ## Parse commonly called integer arguments
    int_arguments = Dict{String, Int64}()

    int_arguments["block_size"] = Int64(round(parse(Float64,
                                                    cfg["block_size"])))

    if iseven(int_arguments["block_size"])
        @warn "block_size is even, but must be odd. Using block_size + 1."
        int_arguments["block_size"] = int_arguments["block_size"] + 1
    end

    int_arguments["block_radius"] = Int64((int_arguments["block_size"] - 1) / 2)
    int_arguments["radius"] = Int64(round(parse(Float64, cfg["radius"])))
    int_arguments["buffer"] = Int64(round(parse(Float64, cfg["buffer"])))

    ## Parse other arguments
    # flags
    calc_flow_potential = lowercase(cfg["calc_flow_potential"]) == "true"
    write_flow_potential = lowercase(cfg["write_flow_potential"]) == "true"
    write_normalized_currmap = lowercase(cfg["write_normalized_currmap"]) == "true"
    write_raw_currmap = lowercase(cfg["write_raw_currmap"]) == "true"
    parallelize = lowercase(cfg["parallelize"]) == "true"
    correct_artifacts = lowercase(cfg["correct_artifacts"]) == "true"
    source_from_resistance = lowercase(cfg["source_from_resistance"]) == "true"
    if int_arguments["block_size"] == 1
        correct_artifacts = false
    end

    # other
    source_threshold = parse(Float64, cfg["source_threshold"])
    project_name = cfg["project_name"]
    r_cutoff = parse(Float64, cfg["r_cutoff"])

    ## Store ascii header
    final_header = parse_ascii_header("$(cfg["resistance_file"])")

    ## Import sources and resistances
    resistance_raw = float(read_ascii("$(cfg["resistance_file"])"))

    # Adjust nodata value if not already -9999
    if parse(Float64, final_header["nodata_value"]) != -9999
        no_data_val = parse(Float64, final_header["nodata_value"])
        resistance_raw[resistance_raw .== no_data_val] .= -9999
        final_header["nodata_value"] = "-9999"
    end

    if source_from_resistance
        sources_raw = deepcopy(resistance_raw)
        sources_raw = 1.0 ./ sources_raw
        sources_raw[resistance_raw .> r_cutoff] .= 0.0
        sources_raw[resistance_raw .== -9999] .= 0.0
    else
        sources_raw = float(read_ascii("$(cfg["source_file"])"))
    end

    int_arguments["nrows"] = size(sources_raw, 1)
    int_arguments["ncols"] = size(sources_raw, 2)

    ## Setup Circuitscape configuration
    cs_cfg_dict = init_csdict(cfg)
    cs_cfg = Circuitscape.init_config()
    Circuitscape.update!(cs_cfg, cs_cfg_dict)

    ## Calculate targets
    targets = get_targets(sources_raw,
                          int_arguments,
                          threshold = source_threshold)


    ## Initialize temporary ascii header for CS advanced mode
    temp_header = init_ascii_header()

    ## Circuitscape calls in loop over targets
    n_targets = size(targets, 1)

    ## Define parameters for cs
    # Get flags
    o = Circuitscape.OutputFlags(false, false,
                                 false, false,
                                 false, false,
                                 false, false)

    ## Add parallel workers
    if parallelize
        println("Starting up Omniscape. Using $(n_threads) processes in parallel")

        cum_currmap = fill(0.,
                           int_arguments["nrows"],
                           int_arguments["ncols"],
                           n_threads)

        if calc_flow_potential
            fp_cum_currmap = fill(0.,
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  n_threads)
        else
            # Hacky fix -- a later function needs fp_cum_currmap to be an array
            fp_cum_currmap = Array{Float64, 3}(undef, 1, 1, 1)
        end
    else
        cum_currmap = fill(0.,
                          int_arguments["nrows"],
                          int_arguments["ncols"],
                          1)

        if calc_flow_potential
            fp_cum_currmap = fill(0.,
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  1)
        else
            fp_cum_currmap = Array{Float64, 3}(undef, 1, 1, 1)
        end
    end

    if correct_artifacts
        art_start = time()
        correction_array = calc_correction(int_arguments,
                                           cs_cfg,
                                           o)
        println("time taken to calculate artifact correction array: $(time()- art_start) seconds")
    else
        correction_array = Array{Float64, 2}(undef, 1, 1)
    end

    ## Calculate and accumulate currents on each worker
    println("Solving targets")
    if parallelize
        batch_size = Int64(round(parse(Float64, cfg["batch_size"])))
        n_batches = Int(ceil(n_targets / batch_size))

        @threads for i in 0:(n_batches - 1)
            start_ind = batch_size * i + 1
            end_ind = min(n_targets, start_ind + batch_size - 1)

            for j in start_ind:end_ind
                solve_target!(j,
                              n_targets,
                              int_arguments,
                              targets,
                              sources_raw,
                              resistance_raw,
                              cs_cfg,
                              o,
                              calc_flow_potential,
                              correct_artifacts,
                              correction_array,
                              cum_currmap,
                              fp_cum_currmap)
            end
        end
    else
        for i in 1:n_targets
            solve_target!(i,
                          n_targets,
                          int_arguments,
                          targets,
                          sources_raw,
                          resistance_raw,
                          cs_cfg,
                          o,
                          calc_flow_potential,
                          correct_artifacts,
                          correction_array,
                          cum_currmap,
                          fp_cum_currmap)
        end
    end

    ## Collapse 3-dim cum current arrays to 2-dim via sum
    cum_currmap = dropdims(sum(cum_currmap, dims = 3), dims = 3)

    if calc_flow_potential
        fp_cum_currmap = dropdims(sum(fp_cum_currmap, dims = 3), dims = 3)
    end

    ## Normalize by flow potential
    if calc_flow_potential == true
        normalized_cum_currmap = cum_currmap ./ fp_cum_currmap
    end

    ## Make output directory
    mkdir("$(project_name)_output")

    ## Write outputs
    if write_raw_currmap == true
        write_ascii(cum_currmap,
                    "$(project_name)_output/cum_currmap.asc",
                    final_header)
    end

    if calc_flow_potential == true
        if write_flow_potential == true
            write_ascii(fp_cum_currmap,
                        "$(project_name)_output/flow_potential.asc",
                        final_header)
        end

        if write_normalized_currmap == true
            write_ascii(normalized_cum_currmap,
                        "$(project_name)_output/normalized_cum_currmap.asc",
                        final_header)
        end
    end

    println("Done")
    println("Time taken to complete job: $(round(time() - start_time; digits = 1)) seconds")

    ## Return outputs
    if calc_flow_potential == true
        return normalized_cum_currmap, cum_currmap, fp_cum_currmap
    else
        return cum_currmap
    end
end