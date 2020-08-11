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

    check_missing_args(cfg_user) && return

    cfg = init_cfg()
    update_cfg!(cfg, cfg_user)

    ## Parse commonly called integer arguments
    int_arguments = Dict{String, Int64}()

    int_arguments["block_size"] = Int64(round(parse(Float64,
                                                    cfg["block_size"])))

    check_block_size(int_arguments["block_size"]) &&
        (int_arguments["block_size"] = int_arguments["block_size"] + 1)

    int_arguments["block_radius"] = Int64((int_arguments["block_size"] - 1) / 2)
    int_arguments["radius"] = Int64(round(parse(Float64, cfg["radius"])))
    int_arguments["buffer"] = Int64(round(parse(Float64, cfg["buffer"])))
    int_arguments["n_conditions"] = Int64(round(parse(Float64, cfg["n_conditions"])))

    ## Parse other arguments
    compare_to_future = lowercase(cfg["compare_to_future"])
    precision = cfg["precision"] in SINGLE ? Float32 : Float64

    # flags
    calc_flow_potential = cfg["calc_flow_potential"] in TRUELIST
    calc_normalized_current = cfg["calc_normalized_current"] in TRUELIST
    write_raw_currmap = cfg["write_raw_currmap"] in TRUELIST
    parallelize = cfg["parallelize"] in TRUELIST
    correct_artifacts = cfg["correct_artifacts"] in TRUELIST
    source_from_resistance = cfg["source_from_resistance"] in TRUELIST
    conditional = cfg["conditional"] in TRUELIST
    mask_nodata = cfg["mask_nodata"] in TRUELIST
    resistance_file_is_conductance = cfg["resistance_file_is_conductance"] in TRUELIST
    write_as_tif = cfg["write_as_tif"] in TRUELIST
    allow_different_projections = cfg["allow_different_projections"] in TRUELIST
    reclassify = cfg["reclassify_resistance"] in TRUELIST
    write_reclassified_resistance = cfg["write_reclassified_resistance"] in TRUELIST

    if int_arguments["block_size"] == 1
        correct_artifacts = false
    end

    # other
    source_threshold = parse(Float64, cfg["source_threshold"])
    project_name = cfg["project_name"]
    r_cutoff = parse(Float64, cfg["r_cutoff"])
    file_format = write_as_tif ? "tif" : "asc"

    ## Set number of BLAS threads to 1
    BLAS.set_num_threads(1)

    ## Import sources and resistances
    resistance_raster = Circuitscape.read_raster("$(cfg["resistance_file"])", precision)

    resistance_raw = resistance_raster[1]
    wkt = resistance_raster[2]
    transform = resistance_raster[3]

    check_resistance_values(resistance_raw) && return

    # Reclassify resistance layer
    if reclassify
        resistance_old = deepcopy(resistance_raw)
        reclass_table = convert.(precision, readdlm("$(cfg["reclass_table"])"))

        for i in 1:(size(reclass_table)[1])
            resistance_raw[resistance_old .== reclass_table[i, 1]] .= reclass_table[i, 2]
        end

        resistance_old = nothing # remove from memory
    end

    # Compute source strengths from resistance if needed
    if source_from_resistance
        sources_raw = deepcopy(resistance_raw)
        if !resistance_file_is_conductance
            sources_raw = 1 ./ sources_raw
            sources_raw[resistance_raw .> r_cutoff] .= 0.0
            sources_raw[resistance_raw .== -9999] .= 0.0
        end
    else
        sources_raster = Circuitscape.read_raster("$(cfg["source_file"])", precision)
        sources_raw = sources_raster[1]

        # Check for raster alignment
        check_raster_alignment(resistance_raster, sources_raster,
                               "resistance_file", "sources_file",
                               allow_different_projections) && return

        # get rid of unneeded raster to save memory
        sources_raster = nothing

        # overwrite nodata with 0
        sources_raw[sources_raw .== -9999] .= 0.0

        # Set values < user-specified threshold to 0
        sources_raw[sources_raw .< source_threshold] .= 0.0
    end

    int_arguments["nrows"] = size(sources_raw, 1)
    int_arguments["ncols"] = size(sources_raw, 2)

    # Import conditional rasters and other conditional connectivity stuff
    if conditional
        condition1_raster = Circuitscape.read_raster("$(cfg["condition1_file"])", precision)
        condition1 = condition1_raster[1]

        # Check for raster alignment
        check_raster_alignment(resistance_raster, condition1_raster,
                               "resistance_file", "condition1_file",
                               allow_different_projections) && return

        # get rid of unneeded raster to save memory
        condition1_raster = nothing

        if compare_to_future == "1" || compare_to_future == "both"
            condition1_future_raster = Circuitscape.read_raster("$(cfg["condition1_future_file"])", precision)
            condition1_future = condition1_future_raster[1]

            # Check for raster alignment
            check_raster_alignment(resistance_raster, condition1_future_raster,
                                   "resistance_file", "condition1_future_file",
                                   allow_different_projections) && return

            # get rid of unneeded raster to save memory
            condition1_future_raster = nothing
        else
            condition1_future = condition1
        end

        if int_arguments["n_conditions"] == 2
            condition2_raster = Circuitscape.read_raster("$(cfg["condition2_file"])", precision)
            condition2 = condition2_raster[1]

            # Check for raster alignment
            check_raster_alignment(resistance_raster, condition2_raster,
                                   "resistance_file", "condition2_file",
                                   allow_different_projections) && return

            # get rid of unneeded raster to save memory
            condition2_raster = nothing

            if compare_to_future == "2" || compare_to_future == "both"
                condition2_future_raster = Circuitscape.read_raster("$(cfg["condition2_future_file"])", precision)
                condition2_future = condition2_future_raster[1]

                # Check for raster alignment
                check_raster_alignment(resistance_raster, condition2_future_raster,
                                       "resistance_file", "condition2_future_file",
                                       allow_different_projections) && return

                # get rid of unneeded raster to save memory
                condition2_future_raster = nothing
            else
                condition2_future = condition2
            end

        else
            condition2 = Array{Float64, 2}(undef, 1, 1)
            condition2_future = condition2
        end
    else
        condition1 = Array{Float64, 2}(undef, 1, 1)
        condition2 = Array{Float64, 2}(undef, 1, 1)
        condition1_future = condition1
        condition2_future = condition2
    end

    # get rid of unneeded raster to save memory
    resistance_raster = nothing

    comparison1 = cfg["comparison1"]
    comparison2 = cfg["comparison2"]
    condition1_lower = parse(Float64, cfg["condition1_lower"])
    condition2_lower = parse(Float64, cfg["condition2_lower"])
    condition1_upper = parse(Float64, cfg["condition1_upper"])
    condition2_upper = parse(Float64, cfg["condition2_upper"])

    ## Setup Circuitscape configuration
    cs_cfg_dict = init_csdict(cfg)
    cs_cfg = Circuitscape.init_config()
    Circuitscape.update!(cs_cfg, cs_cfg_dict)

    ## Calculate targets
    targets = get_targets(sources_raw,
                          int_arguments,
                          precision)

    ## Circuitscape calls in loop over targets
    n_targets = size(targets, 1)

    ## Define parameters for cs
    # Get flags
    o = Circuitscape.OutputFlags(false, false,
                                 false, false,
                                 false, false,
                                 false, false)

    precision_name = precision == Float64 ? "double" : "single"
    ## Add parallel workers
    if parallelize
        println("Starting up Omniscape. Using $(n_threads) workers in parallel. Using $(precision_name) precision...")

        cum_currmap = fill(convert(precision, 0.),
                           int_arguments["nrows"],
                           int_arguments["ncols"],
                           n_threads)

        if calc_flow_potential || calc_normalized_current
            fp_cum_currmap = fill(convert(precision, 0.),
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  n_threads)
        else
            # Hacky fix -- a later function needs fp_cum_currmap to be an array
            fp_cum_currmap = Array{precision, 3}(undef, 1, 1, 1)
        end
    else
        println("Starting up Omniscape. Running in serial using 1 worker. Using $(precision_name) precision...")
        cum_currmap = fill(convert(precision, 0.),
                          int_arguments["nrows"],
                          int_arguments["ncols"],
                          1)

        if calc_flow_potential || calc_normalized_current
            fp_cum_currmap = fill(convert(precision, 0.),
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  1)
        else
            fp_cum_currmap = Array{precision, 3}(undef, 1, 1, 1)
        end
    end

    if correct_artifacts
        println("Calculating block artifact correction array...")
        correction_array = calc_correction(int_arguments,
                                           cs_cfg,
                                           o,
                                           conditional,
                                           condition1,
                                           condition1_future,
                                           condition2,
                                           condition2_future,
                                           comparison1,
                                           comparison2,
                                           condition1_lower,
                                           condition1_upper,
                                           condition2_lower,
                                           condition2_upper,
                                           precision)

    else
        correction_array = Array{Float64, 2}(undef, 1, 1)
    end

    ## Calculate and accumulate currents on each worker
    println("Solving targets")
    if parallelize
        parallel_batch_size = Int64(round(parse(Float64, cfg["parallel_batch_size"])))
        n_batches = Int(ceil(n_targets / parallel_batch_size))

        @threads for i in 0:(n_batches - 1)
            start_ind = parallel_batch_size * i + 1
            end_ind = min(n_targets, start_ind + parallel_batch_size - 1)

            for j in start_ind:end_ind
                solve_target!(j,
                              n_targets,
                              int_arguments,
                              targets,
                              sources_raw,
                              resistance_raw,
                              cs_cfg,
                              o,
                              calc_flow_potential || calc_normalized_current,
                              correct_artifacts,
                              conditional,
                              condition1,
                              condition1_future,
                              condition2,
                              condition2_future,
                              comparison1,
                              comparison2,
                              condition1_lower,
                              condition1_upper,
                              condition2_lower,
                              condition2_upper,
                              correction_array,
                              cum_currmap,
                              fp_cum_currmap,
                              precision,
                              resistance_file_is_conductance)
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
                          calc_flow_potential || calc_normalized_current,
                          correct_artifacts,
                          conditional,
                          condition1,
                          condition1_future,
                          condition2,
                          condition2_future,
                          comparison1,
                          comparison2,
                          condition1_lower,
                          condition1_upper,
                          condition2_lower,
                          condition2_upper,
                          correction_array,
                          cum_currmap,
                          fp_cum_currmap,
                          precision,
                          resistance_file_is_conductance)
        end
    end

    ## Set some objects to nothing to free up memory
    sources_raw = nothing
    condition1 = nothing
    condition1_future = nothing
    condition2 = nothing
    condition2_future = nothing
    GC.gc()

    ## Collapse 3-dim cum current arrays to 2-dim via sum
    cum_currmap = dropdims(sum(cum_currmap, dims = 3), dims = 3)

    if calc_flow_potential || calc_normalized_current
        fp_cum_currmap = dropdims(sum(fp_cum_currmap, dims = 3), dims = 3)
    end

    ## Normalize by flow potential
    if calc_normalized_current
        normalized_cum_currmap = cum_currmap ./ fp_cum_currmap
        # replace NaNs with 0's
        normalized_cum_currmap[isnan.(normalized_cum_currmap)] .= 0
    end

    ## create new directory if project_name already exists
    dir_suffix = 1
    while isdir(string(project_name, "_$(dir_suffix)"))
        dir_suffix+=1
    end
    isdir(project_name) && (project_name = string(project_name, "_$(dir_suffix)"))

    mkpath(project_name)

    # Copy .ini file to output directory
    cp(path, "$(project_name)/config.ini")

    if reclassify && write_reclassified_resistance
        Circuitscape.write_raster("$(project_name)/classified_resistance",
                     resistance_raw,
                     wkt,
                     transform,
                     file_format)
    end

    ## Overwrite no data
    if mask_nodata
        if calc_normalized_current
            normalized_cum_currmap[resistance_raw .== -9999] .= -9999
        end
        if calc_flow_potential
            fp_cum_currmap[resistance_raw .== -9999] .= -9999
        end
        cum_currmap[resistance_raw .== -9999] .= -9999
    end

    # Get rid of resistance
    resistance_raw = nothing
    GC.gc()

    ## Write outputs
    if write_raw_currmap
        Circuitscape.write_raster("$(project_name)/cum_currmap",
                     cum_currmap,
                     wkt,
                     transform,
                     file_format)
    end

    if calc_flow_potential
        Circuitscape.write_raster("$(project_name)/flow_potential",
                     fp_cum_currmap,
                     wkt,
                     transform,
                     file_format)
    end


    if calc_normalized_current
        Circuitscape.write_raster("$(project_name)/normalized_cum_currmap",
                     normalized_cum_currmap,
                     wkt,
                     transform,
                     file_format)
    end

    println("Done")
    println("Time taken to complete job: $(round(time() - start_time; digits = 4)) seconds")

    println("Outputs written to $(string(pwd(),"/",project_name))")

    ## Return outputs, depending on user options
    if calc_normalized_current && !calc_flow_potential
        return cum_currmap, normalized_cum_currmap
    elseif !calc_normalized_current && calc_flow_potential
        return cum_currmap, fp_cum_currmap
    elseif calc_normalized_current && calc_flow_potential
        return cum_currmap, fp_cum_currmap, normalized_cum_currmap
    else
        return cum_currmap
    end
end

