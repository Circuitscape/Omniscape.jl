function Omniscape(path::String)
    cfg = parse_cfg(path)

    ## Parse settings
    block_size = Int64(round(parse(Float64, cfg["block_size"])))
    radius = Int64(round(parse(Float64, cfg["radius"])))
    buffer = Int64(round(parse(Float64, cfg["buffer"])))
    source_threshold = Float64(parse(Float64, cfg["source_threshold"]))
    project_name = cfg["project_name"]
    normalize = cfg["normalize"]
    ## Make output directory
    mkdir("$(project_name)_output")

    ## Store ascii header
    final_header = parse_ascii_header("$(cfg["resistance_file"])")

    ## Import sources and resistances
    sources_raw = float(read_ascii("$(cfg["source_file"])"))
    resistance_raw = float(read_ascii("$(cfg["resistance_file"])"))

    ## Derived variables
    if iseven(block_size)
        @warn "Block_size is even, but must be odd. Using block_size + 1."
        block_size = block_size + 1
    end
    nrows = size(sources_raw, 1)
    ncols = size(sources_raw, 2)
    block_radius = Int64((block_size - 1) / 2))
    ## end dervied variables

    ## Make scratch directly
    mkdir("$(project_name)_scratch")

    ## Setup Circuitscape configurations
    cs_cfg_dict = init_csdict()
    cs_cfg = Circuitscape.init_config()
    Circuitscape.update!(cfg, cs_cfg_dict)

    ## Calculate targets
    targets = get_targets(sources_raw, threshold = source_threshold, block_radius = block_radius)

    ## Initialize cumulative current map
    cum_currmap = fill(0., nrows, ncols)

    if normalize == true
        fp_cum_currmap = fill(0., nrows, ncols)
    end

    ## Initialize temporary ascii header for CS advanced mode
    temp_header = init_ascii_header()

    ## Circuitscape calls in loop over targets
    for i = 1:size(targets, 1)
        ## get source

        x_coord = Int64(targets[i, 1])
        y_coord = Int64(targets[i, 2])
        source = get_source(sources_raw,
                            x = x_coord,
                            y = y_coord,
                            strength = float(targets[i, 3]))

        ## get ground
        ground = get_ground(x = x_coord,
                            y = y_coord)

        ## get resistance
        resistance = get_resistance(resistance_raw,
                                    x = x_coord,
                                    y = y_coord)

        grid_size = size(source)
        n_cells = prod(grid_size)

        if n_cells <= 2000000
            cfg["solver"] = "cholmod"
        end

        ## Update temp ascii header
        update_ascii_header!(source, temp_header)

        ## Write source, ground, and resistance asciis
        write_ascii(source, "$(project_name)_scratch/temp_source.asc", temp_header)
        write_ascii(ground, "$(project_name)_scratch/temp_ground.asc", temp_header)
        write_ascii(resistance, "$(project_name)_scratch/temp_resistance.asc", temp_header)

        ## Run circuitscape
        curr = calculate_current(cs_cfg)

        ## If normalize = True, calculate null map and normalize
        if normalize == true
            rm("$(project_name)_scratch/temp_resistance.asc")
            null_resistance = fill(1, grid_size)
            write_ascii(null_resistance, "$(project_name)_scratch/temp_resistance.asc", temp_header)
            flow_potential = calculate_current(cfg)
        end

        # flow_potential = currmap ./ null_currmap
        rm("$(project_name)_scratch/temp_resistance.asc")
        rm("$(project_name)_scratch/temp_source.asc")
        rm("$(project_name)_scratch/temp_ground.asc")

        ## TODO: figure out parallel solution for accumulating values
        xlower = max(x_coord - radius - buffer, 1)
        xupper = max(x_coord + radius + buffer, 1)
        ylower = max(y_coord - radius - buffer, 1)
        yupper = max(y_coord + radius + buffer, 1)

        cum_currmap[xlower:xupper, ylower:yupper] .=
            cum_currmap[xlower:xupper, ylower:yupper] .+ curr

        if normalize == TRUE
            fp_cum_currmap[xlower:xupper, ylower:yupper] .=
                fp_cum_currmap[xlower:xupper, ylower:yupper] .+ flow_potential
        end
    end

    rm("$(project_name)_scratch/")

    if normalize == true
        normalized_cum_currmap = cum_currmap ./ fp_cum_currmap
    end

    ## Write outputs
    if write_raw_currmap == true
        write_ascii(cum_currmap, "$(project_name)_output/cum_currmap.asc", final_header)
    end
    if write_flow_potential == true
        write_ascii(fp_cum_currmap, "$(project_name)_output/flow_potential.asc", final_header)
    end
    if write_normalized_currmap == true
        write_ascii(normalized_cum_currmap, "$(project_name)_output/normalized_cum_currmap.asc", final_header)
    end

    ## Return outputs
    if normalize == true
        return normalized_cum_curmap, cum_currmap, fp_cum_currmap
    else
        return cum_currmap
    end
end
