"""
INI method:

    run_omniscape(path::String)

In-memory method:

    run_omniscape(
        cfg::Dict{String, String}
        resistance::Array{Union{Float64, Missing}, 2};
        reclass_table = Array{Union{Float64, Missing}, 2}(undef, 1, 2),
        source_strength = source_from_resistance(resistance, cfg, reclass_table),
        condition1 = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        condition2 = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        condition1_future = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        condition2_future = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        wkt = "",
        geotransform = [0.0, 1.0, 0.0, 0.0, 0.0, -1.0],
        write_outputs = false
    )

Compute omnidirectional current flow. All array inputs for the in-memory method
should be of type `Array{Union{T, Missing}, 2} where T <: Number`, with
`missing` used for NoData pixels.

# Parameters
**`path`**: The path to an INI file containing run parameters. See the
[Settings and Options](@ref) section of the User Guide for descriptions of the run
parameters.

**`cfg`**: A dictionary of Omniscape run parameters. See the [Settings and Options](@ref)
section of the User Guide for descriptions of the run parameters and their
default values. The in-memory method of `run_omniscape` ignores the following
keys: `resistance_file`, `source_file`, `reclass_table`, `condition1_file`,
`condition2_file`, `condition1_future_file`, and `condition2_future_file`. These
all specify file paths, so they do not apply to the in-memory method
of `run_omniscape`.

**`resistance`**: A 2D, north-oriented array of resistance values. Use
`missing` for NoData (infinite resistance). `resistance` cannot contain zeros or
negative values.

# Keyword Arguments

**`reclass_table`**:  A two column array. The first column contains the original
resistance values in the resistance surface, and the second column specifies
what those values should be changed to. You can reclassify values to `missing`
to replace them with infinite resistance (NoData).

**`source_strength`**: A 2D, north-oriented array (with size equal to
`size(resistance)`) of source strength values. `source_strength` is only
required if `source_from_resistance` in `cfg` is set to "false"
(the default value).

**`condition1`**: Optional. Required if `conditional` in`cfg` is set to "true".
A 2D, north-oriented array (with size equal to `size(resistance)`). See
[Climate Connectivity](@ref) and [Conditional Connectivity Options](@ref) for
more information.

**`condition2`**: Optional. Required if `conditional` in`cfg` is set to "true"
and `n_conditions` in `cfg` is set to "2". A 2D, north-oriented array (with size
equal to `size(resistance)`). See [Climate Connectivity](@ref) and
[Conditional Connectivity Options](@ref) for more information.

**`condition1_future`**: Optional. Required if `conditional` in `cfg` is set
to "true" and `compare_to_future` in `cfg` is set to "1" or "both".
A 2D, north-oriented array (with size equal to `size(resistance)`). See
[Climate Connectivity](@ref) and [Conditional Connectivity Options](@ref) for
more information.

**`condition2_future`**: Optional. A 2D, north-oriented array (with size equal to
`size(resistance)`). See [Climate Connectivity](@ref) and
[Conditional Connectivity Options](@ref) for more information. Required if
`conditional` in`cfg` is set to "true", `n_conditions` in `cfg` is set to "2",
and `compare_to_future` in `cfg` is set to "2" or "both".

**`wkt`**: Optionally specify a Well Known Text representation of the projection
used for your spatial data inputs. Only used if Omniscape writes raster
outputs to disk.

**`geotransform`**: In addition to `wkt`, optionally specify a geotransform.
The geotransform is a 6-element vector with elements as follows for a north up
oriented image: `[<x coord of upper left orner>, <pixel width>,
<row rotation (typically 0)>, <y coord of upper left corner>,
<column rotation (typically 0)>, <pixel height (negative number)>]`.
Only used when writing raster outputs to disk.

**`write_outputs`**: Boolean specifying if outputs should be written to disk.
Defaults to `false`. If `true`, `cfg` must contain a value for the `project_name`
key.

"""
function run_omniscape_lock(
        cfg::Dict{String, String},
        resistance::Array{Union{T, Missing}, 2} where T <: Number;
        reclass_table::Array{Union{T, Missing}, 2} where T <: Number = Array{Union{Float64, Missing}, 2}(undef, 1, 2),
        source_strength::Array{Union{T, Missing}, 2} where T <: Number = source_from_resistance(resistance, cfg, reclass_table),
        condition1::Array{Union{T, Missing}, 2} where T <: Number = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        condition2::Array{Union{T, Missing}, 2} where T <: Number = Array{Union{Float64, Missing}, 2}(undef, 1, 1),
        condition1_future::Array{Union{T, Missing}, 2} where T <: Number = condition1,
        condition2_future::Array{Union{T, Missing}, 2} where T <: Number = condition2,
        wkt::String = "",
        geotransform::Array{Float64, 1} = [0., 1., 0., 0., 0., -1.0],
        write_outputs::Bool = false)

    start_time = time()
    n_threads = nthreads()
    cfg_user = cfg

    # Check for unsupported or missing arguments
    check_unsupported_args(cfg)
    check_missing_args_dict(cfg_user) && return

    cfg = init_cfg()
    update_cfg!(cfg, cfg_user)

    ## Parse commonly called integer arguments
    int_arguments = Dict{String, Int64}()

    int_arguments["block_size"] = Int64(round(parse(Float64,
                                                    cfg["block_size"])))

    check_block_size!(int_arguments)

    int_arguments["block_radius"] = Int64((int_arguments["block_size"] - 1) / 2)
    int_arguments["radius"] = Int64(round(parse(Float64, cfg["radius"])))
    int_arguments["buffer"] = Int64(round(parse(Float64, cfg["buffer"])))
    int_arguments["n_conditions"] = Int64(round(parse(Float64, cfg["n_conditions"])))

    ## Parse other arguments
    compare_to_future = lowercase(cfg["compare_to_future"])
    precision = cfg["precision"] in SINGLE ? Float32 : Float64

    # flags
    os_flags = get_omniscape_flags(cfg)

    # other
    source_threshold = parse(Float64, cfg["source_threshold"])
    project_name = cfg["project_name"]
    file_format = os_flags.write_as_tif ? "tif" : "asc"

    check_solver!(cfg)
    solver = cfg["solver"]

    ## Set number of BLAS threads to 1 when parallel processing
    if os_flags.parallelize && nthreads() != 1
        BLAS.set_num_threads(1)
    end

    check_resistance_values(resistance) && return

    # Reclassify resistance layer
    if os_flags.reclassify
        reclassify_resistance!(resistance, reclass_table)
    end

    int_arguments["nrows"] = size(source_strength, 1)
    int_arguments["ncols"] = size(source_strength, 2)

    # Set up conditional connctivity stuff
    conditions = Conditions(cfg["comparison1"],
                            cfg["comparison2"],
                            parse(Float64, cfg["condition1_lower"]),
                            parse(Float64, cfg["condition1_upper"]),
                            parse(Float64, cfg["condition2_lower"]),
                            parse(Float64, cfg["condition2_upper"]))

    condition_layers = ConditionLayers(condition1, condition1_future, condition2, condition2_future)

    ## Setup Circuitscape configuration
    cs_cfg_dict = init_csdict(cfg)
    cs_cfg_dict["solver"] = solver
    cs_cfg = Circuitscape.init_config()
    Circuitscape.update!(cs_cfg, cs_cfg_dict)

    ## Calculate targets
    targets = get_targets(source_strength,
                          int_arguments,
                          precision)

    ## Circuitscape calls in loop over targets
    n_targets = size(targets, 1)

    # Permute targets randomly (to get better estimate of ProgressMeter ETA)
    targets = targets[randperm(n_targets), :]

    ## Define parameters for cs
    # Get flags
    o = Circuitscape.OutputFlags(false, false,
                                 false, false,
                                 false, false,
                                 false, false)

    precision_name = precision == Float64 ? "double" : "single"
    ## Add parallel workers
    if os_flags.parallelize
        @info("Starting up Omniscape with $(n_threads) workers and $(precision_name) precision")
        @info("Using Circuitscape with the $(uppercase(solver)) solver...")

        cum_currmap = fill(convert(precision, 0.),
                           int_arguments["nrows"],
                           int_arguments["ncols"],
                           1)

        if os_flags.calc_flow_potential || os_flags.calc_normalized_current
            fp_cum_currmap = fill(convert(precision, 0.),
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  1)
        else
            # Hacky fix -- a later function needs fp_cum_currmap to be an array
            fp_cum_currmap = Array{precision, 3}(undef, 1, 1, 1)
        end
    else
        @info("Starting up Omniscape with 1 worker and $(precision_name) precision")
        @info("Using Circuitscape with the $(uppercase(solver)) solver...")
        cum_currmap = fill(convert(precision, 0.),
                          int_arguments["nrows"],
                          int_arguments["ncols"],
                          1)

        if os_flags.calc_flow_potential || os_flags.calc_normalized_current
            fp_cum_currmap = fill(convert(precision, 0.),
                                  int_arguments["nrows"],
                                  int_arguments["ncols"],
                                  1)
        else
            fp_cum_currmap = Array{precision, 3}(undef, 1, 1, 1)
        end
    end

    cs_flags = Circuitscape.RasterFlags(true, false, true,
                                        false, false,
                                        false, Symbol("rmvsrc"),
                                        cfg["connect_four_neighbors_only"] in TRUELIST,
                                        false, solver, o)

    if os_flags.correct_artifacts && !(int_arguments["block_size"] == 1)
        @info("Calculating block artifact correction array...")
        correction_array = calc_correction(int_arguments,
                                           os_flags,
                                           cs_cfg,
                                           cs_flags,
                                           condition_layers,
                                           conditions,
                                           precision)

    else
        correction_array = Array{precision, 2}(undef, 1, 1)
    end

    ## Calculate and accumulate currents on each worker
    @info("Solving moving window targets...")

    ## Create progress object
    p = Progress(n_targets; dt = 0.25, barlen = min(50, displaysize(stdout)[2] - length("Progress: 100%  Time: 00:00:00")))

    if os_flags.parallelize
        parallel_batch_size = Int64(round(parse(Float64, cfg["parallel_batch_size"])))
        n_batches = Int(ceil(n_targets / parallel_batch_size))

        @threads for i in 0:(n_batches - 1)
            start_ind = parallel_batch_size * i + 1
            end_ind = min(n_targets, start_ind + parallel_batch_size - 1)
            
            for j in start_ind:end_ind
                target = Target(Int64(targets[j, 1]), Int64(targets[j, 2]), float(targets[j, 3]))
                try 
                    solve_target_lock!(target,
                                    int_arguments,
                                    source_strength,
                                    resistance,
                                    os_flags,
                                    cs_cfg,
                                    cs_flags,
                                    condition_layers,
                                    conditions,
                                    correction_array,
                                    cum_currmap,
                                    fp_cum_currmap,
                                    precision)
                catch error
                    println("Omniscape failed on the moving window centered on row $(target.y_coord) column $(target.x_coord)")
                    throw(error)
                end
                next!(p)
            end
        end
    else
        for i in 1:n_targets
            target = Target(Int64(targets[i, 1]), Int64(targets[i, 2]), float(targets[i, 3]))
            try
                solve_target_lock!(target,
                            int_arguments,
                            source_strength,
                            resistance,
                            os_flags,
                            cs_cfg,
                            cs_flags,
                            condition_layers,
                            conditions,
                            correction_array,
                            cum_currmap,
                            fp_cum_currmap,
                            precision)
            catch error
                println("Omniscape failed on the moving window centered on row $(target.y_coord) column $(target.x_coord)")
                throw(error)
            end
            next!(p)
        end
    end

    ## Set some objects to nothing to free up memory
    source_strength = nothing
    condition1 = nothing
    condition1_future = nothing
    condition2 = nothing
    condition2_future = nothing
    GC.gc()

    # ## Collapse 3-dim cum current arrays to 2-dim via sum
    # cum_currmap = dropdims(sum(cum_currmap, dims = 3), dims = 3)

    # if os_flags.calc_flow_potential || os_flags.calc_normalized_current
    #     fp_cum_currmap = dropdims(sum(fp_cum_currmap, dims = 3), dims = 3)
    # end

    ## Normalize by flow potential
    if os_flags.calc_normalized_current
        normalized_cum_currmap = cum_currmap ./ fp_cum_currmap
        # replace NaNs with 0's
        normalized_cum_currmap[isnan.(normalized_cum_currmap)] .= 0
    end

    if write_outputs
        ## create new directory if project_name already exists
        dir_suffix = 1
        while isdir(string(project_name, "_$(dir_suffix)"))
            dir_suffix+=1
        end
        isdir(project_name) && (project_name = string(project_name, "_$(dir_suffix)"))
        mkpath(project_name)
    end

    ## Overwrite no data
    if os_flags.mask_nodata
        if os_flags.calc_normalized_current
            normalized_cum_currmap[ismissing.(resistance)] .= -9999
        end
        if os_flags.calc_flow_potential
            fp_cum_currmap[ismissing.(resistance)] .= -9999
        end
        cum_currmap[ismissing.(resistance)] .= -9999
    end

    GC.gc()

    ## Write outputs
    if write_outputs
        write_cfg(cfg_user, project_name)

        if os_flags.reclassify && os_flags.write_reclassified_resistance
            resistance[ismissing.(resistance)] .= -9999
            write_raster("$(project_name)/classified_resistance",
                         convert(Array{precision, 2}, resistance),
                         wkt,
                         geotransform,
                         file_format)
        end

        if os_flags.write_raw_currmap
            write_raster("$(project_name)/cum_currmap",
                         cum_currmap,
                         wkt,
                         geotransform,
                         file_format)
        end

        if os_flags.calc_flow_potential
            write_raster("$(project_name)/flow_potential",
                         fp_cum_currmap,
                         wkt,
                         geotransform,
                         file_format)
        end

        if os_flags.calc_normalized_current
            write_raster("$(project_name)/normalized_cum_currmap",
                         normalized_cum_currmap,
                         wkt,
                         geotransform,
                         file_format)
        end
    end

    resistance = nothing

    @info("Time taken to complete job: $(round(time() - start_time; digits = 4)) seconds")

    if write_outputs
        @info("Outputs written to $(string(pwd(),"/",project_name))")
    end
    ## Return outputs, depending on user options
    # convert arrays, replace -9999's with missing
    cum_currmap = convert_and_fill_missing(cum_currmap, precision)

    if os_flags.calc_normalized_current && !os_flags.calc_flow_potential
        normalized_cum_currmap = convert_and_fill_missing(normalized_cum_currmap, precision)
        return cum_currmap, normalized_cum_currmap
    elseif !os_flags.calc_normalized_current && os_flags.calc_flow_potential
        fp_cum_currmap = convert_and_fill_missing(fp_cum_currmap, precision)
        return cum_currmap, fp_cum_currmap
    elseif os_flags.calc_normalized_current && os_flags.calc_flow_potential
        fp_cum_currmap = convert_and_fill_missing(fp_cum_currmap, precision)
        normalized_cum_currmap = convert_and_fill_missing(normalized_cum_currmap, precision)
        return cum_currmap, fp_cum_currmap, normalized_cum_currmap
    else
        return cum_currmap
    end
end

function run_omniscape_lock(path::String)
    cfg_user = parse_cfg(path)
    check_missing_args_ini(cfg_user) && return

    cfg = init_cfg()
    update_cfg!(cfg, cfg_user)

    ## flags and other cfg args
    os_flags = get_omniscape_flags(cfg)
    compare_to_future = lowercase(cfg["compare_to_future"])
    precision = cfg["precision"] in SINGLE ? Float32 : Float64
    n_conditions = Int64(round(parse(Float64, cfg["n_conditions"])))
    allow_different_projections = cfg["allow_different_projections"] in TRUELIST
    source_threshold = parse(precision, cfg["source_threshold"])

    ## Load resistance
    resistance_raster = read_raster("$(cfg["resistance_file"])", precision)
    resistance = resistance_raster[1]

    wkt = resistance_raster[2]
    geotransform = resistance_raster[3]

    check_resistance_values(resistance) && return

    ## Load reclass table if applicable
    if os_flags.reclassify
        reclass_table = read_reclass_table("$(cfg["reclass_table"])", precision)
    else
        reclass_table = Array{Union{precision, Missing}, 2}(undef, 1, 2)
    end

    ## Load source strengths
    if !os_flags.source_from_resistance
        sources_raster = read_raster("$(cfg["source_file"])", precision)
        source_strength = sources_raster[1]

        # Check for raster alignment
        check_raster_alignment(resistance_raster, sources_raster,
                               "resistance_file", "source_file",
                               allow_different_projections) && return

        # get rid of unneeded raster to save memory
        sources_raster = nothing

        # overwrite nodata with 0
        source_strength[ismissing.(source_strength)] .= 0.0

        # Set values < user-specified threshold to 0
        source_strength[source_strength .< source_threshold] .= 0.0
    else
        source_strength = source_from_resistance(resistance, cfg, reclass_table)
    end

    ## Load condition rasters
    if os_flags.conditional
        condition1_raster = read_raster("$(cfg["condition1_file"])", precision)
        condition1 = condition1_raster[1]

        # Check for raster alignment
        check_raster_alignment(resistance_raster, condition1_raster,
                               "resistance_file", "condition1_file",
                               allow_different_projections) && return

        # get rid of unneedecheck_rasterd raster to save memory
        condition1_raster = nothing

        if compare_to_future == "1" || compare_to_future == "both"
            condition1_future_raster = read_raster("$(cfg["condition1_future_file"])", precision)
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

        if n_conditions == 2
            condition2_raster = read_raster("$(cfg["condition2_file"])", precision)
            condition2 = condition2_raster[1]

            # Check for raster alignment
            check_raster_alignment(resistance_raster, condition2_raster,
                                   "resistance_file", "condition2_file",
                                   allow_different_projections) && return

            # get rid of unneeded raster to save memory
            condition2_raster = nothing

            if compare_to_future == "2" || compare_to_future == "both"
                condition2_future_raster = read_raster("$(cfg["condition2_future_file"])", precision)
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
            condition2 = Array{Union{Missing, precision}, 2}(undef, 1, 1)
            condition2_future = condition2
        end
    else
        condition1 = Array{Union{Missing, precision}, 2}(undef, 1, 1)
        condition2 = Array{Union{Missing, precision}, 2}(undef, 1, 1)
        condition1_future = condition1
        condition2_future = condition2
    end

    resistance_raster = nothing

    run_omniscape_lock(
        cfg,
        resistance;
        source_strength = source_strength,
        condition1 = condition1,
        condition2 = condition2,
        condition1_future = condition1_future,
        condition2_future = condition2_future,
        geotransform = geotransform,
        wkt = wkt,
        reclass_table = reclass_table,
        write_outputs = true
    )
end
