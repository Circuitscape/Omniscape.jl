function run_omniscape(path::String)
    cfg = parse_cfg(path)
    int_arguments = Dict{String, Int64}()
    int_arguments["block_size"] = Int64(round(parse(Float64, cfg["block_size"])))
    if iseven(int_arguments["block_size"])
        @warn "Block_size is even, but must be odd. Using block_size + 1."
        int_arguments["block_size"] = int_arguments["block_size"] + 1
    end
    int_arguments["block_radius"] = Int64((int_arguments["block_size"] - 1) / 2)
    int_arguments["radius"] = Int64(round(parse(Float64, cfg["radius"])))
    int_arguments["buffer"] = Int64(round(parse(Float64, cfg["buffer"])))

    source_threshold = Float64(parse(Float64, cfg["source_threshold"]))
    project_name = cfg["project_name"]
    calc_flow_potential = cfg["calc_flow_potential"] == "true"
    write_flow_potential = cfg["write_flow_potential"] == "true"
    write_normalized_currmap = cfg["write_normalized_currmap"] == "true"
    write_raw_currmap = cfg["write_raw_currmap"] == "true"

    parallelize = cfg["parallelize"] == "true"
    n_workers = parse(Int64, cfg["max_parallel"]))

    if parallelize
        println("Starting up Omniscape to use $(n_workers) processes in parallel")
        myaddprocs(n_workers)
    end

    ## Make output directory
    mkdir("$(project_name)_output")

    ## Store ascii header
    final_header = parse_ascii_header("$(cfg["resistance_file"])")

    ## Import sources and resistances
    sources_raw = float(read_ascii("$(cfg["source_file"])"))
    resistance_raw = float(read_ascii("$(cfg["resistance_file"])"))
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

    ## Initialize cumulative current maps
    if parallelize
        for i in workers()
            @spawnat i eval(:(cum_currmap = fill(0.,
                                                 int_arguments["nrows"],
                                                 int_arguments["ncols"])))
        end

        if calc_flow_potential
            for i in workers()
                @spawnat i eval(:(fp_cum_currmap = fill(0.,
                                                        int_arguments["nrows"],
                                                        int_arguments["ncols"]))
            end
        end
    else
        if calc_flow_potential
            fp_cum_currmap = fill(0.,
                                  int_arguments["nrows"],
                                  int_arguments["ncols"])
        end
        cum_currmap = fill(0., int_arguments["nrows"], int_arguments["ncols"])
    end

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

    ## Calculate and accumulate currents on each worker
    pmap(solve_target!, 1:n_targets; distributed = parallelize)

    ## Add together remote cumulative maps
    if parallelize
        cum_currmap_local = fill(0.,
                                 int_arguments["nrows"],
                                 int_arguments["ncols"])

        for i in workers()
            cum_currmap_local = cum_currmap_local .+ @fetchfrom i cum_currmap
        end

        cum_currmap = cum_currmap_local

        if calc_flow_potential
            fp_cum_currmap_local = fill(0.,
                                        int_arguments["nrows"],
                                        int_arguments["ncols"])
            for i in workers()
                fp_cum_currmap_local = fp_cum_currmap_local .+
                                           @fetchfrom i fp_ cum_currmap
            end
            fp_cum_currmap = fp_cum_currmap
        end
    end

    if calc_flow_potential == true
        normalized_cum_currmap = cum_currmap ./ fp_cum_currmap
    end

    ## Write outputs
    if write_raw_currmap == true
        write_ascii(cum_currmap, "$(project_name)_output/cum_currmap.asc", final_header)
    end

    if calc_flow_potential == true
        if write_flow_potential == true
            write_ascii(fp_cum_currmap, "$(project_name)_output/flow_potential.asc", final_header)
        end

        if write_normalized_currmap == true
            write_ascii(normalized_cum_currmap, "$(project_name)_output/normalized_cum_currmap.asc", final_header)
        end
    end

    ## Return outputs
    if calc_flow_potential == true
        return normalized_cum_currmap, cum_currmap, fp_cum_currmap
    else
        return cum_currmap
    end
end