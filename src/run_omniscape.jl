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
    targets = get_targets(sources_raw, int_arguments, threshold = source_threshold)

    ## Initialize cumulative current map
    cum_currmap = fill(0., int_arguments["nrows"], int_arguments["ncols"])

    if calc_flow_potential == true
        fp_cum_currmap = fill(0., int_arguments["nrows"], int_arguments["ncols"])
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

    for i = 1:n_targets

        ## get source
        println("Solving target $(i) of $(n_targets)")
        x_coord = Int64(targets[i, 1])
        y_coord = Int64(targets[i, 2])
        source = get_source(sources_raw,
                            int_arguments,
                            x = x_coord,
                            y = y_coord,
                            strength = float(targets[i, 3]))

        ## get ground
        ground = get_ground(int_arguments,
                            x = x_coord,
                            y = y_coord)

        ## get resistance
        resistance = get_resistance(resistance_raw,
                                    int_arguments,
                                    x = x_coord,
                                    y = y_coord)

        grid_size = size(source)
        n_cells = prod(grid_size)

        solver = "cg+amg"

        # if n_cells <= 2000000
        #     solver = "cholmod" # FIXME: solver = "cholmod" has no effect on advanced mode
        # end

        flags = Circuitscape.RasterFlags(true, false, true,
                                         false, false,
                                         false, Symbol("keepall"),
                                         false, false, solver, o)

        ## Run circuitscape
        curr = calculate_current(resistance, source, ground, solver, flags, cs_cfg)

        ## If normalize = True, calculate null map and normalize
        if calc_flow_potential == true
            null_resistance = fill(1., grid_size)
            flow_potential = calculate_current(null_resistance, source, ground, solver, flags, cs_cfg)
        end

        ## TODO: figure out parallel solution for accumulating values
        xlower = max(x_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
        xupper = min(x_coord + int_arguments["radius"] + int_arguments["buffer"],  int_arguments["ncols"])
        ylower = max(y_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
        yupper = min(y_coord + int_arguments["radius"] + int_arguments["buffer"],  int_arguments["nrows"])

        cum_currmap[xlower:xupper, ylower:yupper] .=
            cum_currmap[xlower:xupper, ylower:yupper] .+ curr

        if calc_flow_potential == true
            fp_cum_currmap[xlower:xupper, ylower:yupper] .=
                fp_cum_currmap[xlower:xupper, ylower:yupper] .+ flow_potential
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
