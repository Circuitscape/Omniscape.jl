abstract type Data end

function clip(
        A::Array{Union{Missing, T}, 2} where T <: Number;
        x::Int64,
        y::Int64,
        distance::Int64
    )

    sizes = size(A)

    xlower = Int64(max(x - distance, 1))
    xupper = Int64(min(x + distance, sizes[2]))
    ylower = Int64(max(y - distance, 1))
    yupper = Int64(min(y + distance, sizes[1]))


    A_sub = A[ylower:yupper, xlower:xupper]

    dim1 = size(A_sub)[1]
    dim2 = size(A_sub)[2]

    new_x = min(distance + 1, x)
    new_y = min(distance + 1, y)

    dist_array = [sqrt((j - new_x)^2 + (i - new_y)^2) for i = 1:dim1, j = 1:dim2]

    A_sub[dist_array .> distance] .= missing

    A_sub
end


function get_targets(
        source_array::Array{Union{T, Missing}, 2} where T <: Number,
        arguments::Dict{String, Int64},
        precision::DataType
    )

    block_size = arguments["block_size"]
    block_radius = arguments["block_radius"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    start = block_radius + 1

    xs = [start:block_size:(ncols - block_radius);]
    ys = [start:block_size:(nrows - block_radius);]

    ground_points = zeros(precision, (length(xs)*length(ys), 2))

    let
        c = 1
        for i = 1:length(xs)
            for j = 1:length(ys)
                ground_points[c, 1] = xs[i]
                ground_points[c, 2] = ys[j]
                c += 1
            end
        end
    end

    # create column ground_points[, 3] to hold source strengths for each target
    ground_points = cat(ground_points,
                        zeros(precision, size(ground_points)[1], 1);
                        dims = 2
                    )

    # populate ground_points[, 3] with sum of sources in block of size
    # block_size centered on each target
    for i = 1:size(ground_points)[1]
        xlower = Int64(ground_points[i, 1] - block_radius)
        xupper = min(Int64(ground_points[i, 1] + block_radius), ncols)
        ylower = Int64(ground_points[i, 2] - block_radius)
        yupper = min(Int64(ground_points[i, 2] + block_radius), nrows)

        # source_array is Array{Union{T, Missing}, 2} but should have no
        # missings, so not having skipmissings be okay
        ground_points[i, 3] = sum(source_array[ylower:yupper, xlower:xupper])
    end

    # get rid of ground_points with strength equal to 0
    targets = ground_points[ground_points[:, 3] .> 0, 1:3]
    targets
end

# x and y defined by targets object. Ultimately the for loop will be done by
# iterating through rows of targets object
function get_source(
        source_array::Array{Union{Missing, T}, 2} where T <: Number,
        arguments::Dict{String, Int64},
        os_flags::OmniscapeFlags,
        condition1_present::Array{Union{Missing, T}, 2} where T <: Number,
        condition1_future::Array{Union{Missing, T}, 2} where T <: Number,
        condition2_present::Array{Union{Missing, T}, 2} where T <: Number,
        condition2_future::Array{Union{Missing, T}, 2} where T <: Number,
        comparison1::String,
        comparison2::String,
        condition1_lower::Number,
        condition1_upper::Number,
        condition2_lower::Number,
        condition2_upper::Number,
        precision::DataType;
        x::Int64,
        y::Int64,
        strength::Number
    )

    block_radius = arguments["block_radius"]
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    source_subset = clip(source_array,
                         x = x,
                         y = y,
                         distance = radius)

    # Append missing if buffer > 0
    if buffer > 0
        ### Columns
        nrow_sub = size(source_subset)[1]
        left_col_num = max(0, min(buffer, x - radius - 1))
        right_col_num = max(0, min(buffer, ncols - (x + radius)))

        # Add left columns
        if left_col_num > 0
            source_subset = hcat(fill(missing, (nrow_sub, left_col_num)),
                                 source_subset)
        end
        # Add right columns
        if right_col_num > 0
            source_subset = hcat(source_subset,
                                 fill(missing, (nrow_sub, right_col_num)))
        end

        ### Rows
        ncol_sub = size(source_subset)[2]
        top_row_num = max(0, min(buffer, y - radius - 1))
        bottom_row_num = max(0, min(buffer, nrows - (y + radius)))

        # Add top rows
        if top_row_num > 0
            source_subset = vcat(fill(missing, (top_row_num, ncol_sub)),
                                 source_subset)
        end
        #Add bottom rows
        if bottom_row_num > 0
            source_subset = vcat(source_subset,
                                 fill(missing, (bottom_row_num, ncol_sub)))
        end
    end

    # Replace nodata vals with 0s
    source_subset[ismissing.(source_subset)] .= 0.0

    # Set any sources inside target block to 0
    xlower_sub = (radius + buffer  + 1) - block_radius
    xupper_sub = min((radius + buffer  + 1)  + block_radius, ncols)
    ylower_sub = (radius + buffer + 1)  - block_radius
    yupper_sub = min((radius + buffer  + 1)  + block_radius, nrows)

    source_subset[ylower_sub:yupper_sub, xlower_sub:xupper_sub] .= 0

    # allocate total current equal to target "strength", divide among sources
    # according to their source strengths
    source_sum = sum(source_subset[coalesce.(source_subset .> 0, false)])
    source_subset[source_subset .> 0] .=
        (source_subset[coalesce.(source_subset .> 0, false)] * strength) / source_sum

    if os_flags.conditional

        xlower_buffered = Int64(max(x - radius - buffer, 1))
        xupper_buffered = Int64(min(x + radius + buffer, ncols))
        ylower_buffered = Int64(max(y - radius - buffer, 1))
        yupper_buffered = Int64(min(y + radius + buffer, nrows))
        xlower = x - block_radius
        xupper = min(x + block_radius, ncols)
        ylower = y - block_radius
        yupper = min(y + block_radius, nrows)

        source_target_match!(source_subset,
                             arguments["n_conditions"],
                             condition1_present,
                             condition1_future,
                             condition2_present,
                             condition2_future,
                             comparison1,
                             comparison2,
                             condition1_lower,
                             condition1_upper,
                             condition2_lower,
                             condition2_upper,
                             ylower,
                             yupper,
                             xlower,
                             xupper,
                             ylower_buffered,
                             yupper_buffered,
                             xlower_buffered,
                             xupper_buffered
                             )
    end
    source_subset
end

function source_target_match!(source_subset::Array{Union{T, Missing}, 2} where T <: Number,
                              n_conditions::Int64,
                              condition1_present::Array{Union{T, Missing}, 2} where T <: Number,
                              condition1_future::Array{Union{T, Missing}, 2} where T <: Number,
                              condition2_present::Array{Union{T, Missing}, 2} where T <: Number,
                              condition2_future::Array{Union{T, Missing}, 2} where T <: Number,
                              comparison1::String,
                              comparison2::String,
                              condition1_lower::Number,
                              condition1_upper::Number,
                              condition2_lower::Number,
                              condition2_upper::Number,
                              ylower::Int64,
                              yupper::Int64,
                              xlower::Int64,
                              xupper::Int64,
                              ylower_buffered::Int64,
                              yupper_buffered::Int64,
                              xlower_buffered::Int64,
                              xupper_buffered::Int64
                              )
    con1_present_subset = condition1_present[ylower_buffered:yupper_buffered,
                                             xlower_buffered:xupper_buffered]

    if comparison1 == "within"
      value1 = median(skipmissing(condition1_future[ylower:yupper, xlower:xupper]))
      source_subset[coalesce.(((con1_present_subset .- value1) .> condition1_upper) .|
          ((con1_present_subset .- value1) .< condition1_lower), false)] .= 0
    elseif comparison1 == "equals"
      value1 = mode(skipmissing(condition1_future[ylower:yupper, xlower:xupper]))
      source_subset[coalesce.(con1_present_subset .!= value1, false)] .= 0
    end

    if n_conditions == 2
      con2_present_subset = condition2_present[ylower_buffered:yupper_buffered,
                                               xlower_buffered:xupper_buffered]
      if comparison2 == "within"
          value2 = median(skipmissing(condition2_future[ylower:yupper, xlower:xupper]))
          source_subset[coalesce.(((con2_present_subset .- value2) .> condition2_upper) .|
              ((con2_present_subset .- value2) .< condition2_lower), false)] .= 0
      elseif comparison2 == "equals"
          value2 = mode(skipmissing(condition2_future[ylower:yupper, xlower:xupper]))
          source_subset[coalesce.(con2_present_subset .!= value2, false)] .= 0
      end
    end
end

function get_ground(
        arguments::Dict{String, Int64},
        precision::DataType;
        x::Int64,
        y::Int64)
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    distance = radius + buffer

    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    xlower = Int64(max(x - radius - buffer, 1))
    xupper = Int64(min(x + radius + buffer, ncols))
    ylower = Int64(max(y - radius - buffer, 1))
    yupper = Int64(min(y + radius + buffer, nrows))

    size_x = xupper - xlower + 1
    size_y = yupper - ylower + 1

    ground = fill(convert(precision, 0.0),
                  size_y,
                  size_x)

    new_x = min(distance + 1, x)
    new_y = min(distance + 1, y)

    ground[new_y, new_x] = Inf

    ground
end

function get_conductance(
        resistance::Array{Union{T, Missing}, 2} where T <: Number,
        arguments::Dict{String, Int64},
        x::Int64,
        y::Int64,
        os_flags::OmniscapeFlags
    )

    radius = arguments["radius"]
    buffer = arguments["buffer"]

    resistance_clipped = clip(resistance,
                              x = x,
                              y = y,
                              distance = radius + buffer)

    if os_flags.resistance_is_conductance
        conductance = resistance_clipped
    else
        conductance = 1 ./ resistance_clipped
    end

    conductance
end


function calculate_current(
        conductance::Array{Union{T, Missing}, 2} where T <: Number,
        source::Array{Union{T, Missing}, 2} where T <: Number,
        ground::Array{T, 2} where T <: Number,
        cs_flags::Circuitscape.RasterFlags,
        cs_cfg::Dict{String, String},
        T::DataType
    )
    V = Int64

    # Replace missings with -9999, then convert to Array{T, 2}
    # prior to circuitscape
    conductance[ismissing.(conductance)] .= -9999
    source[ismissing.(source)] .= -9999
    conductance = convert(Array{T, 2}, conductance)
    source = convert(Array{T, 2}, source)

    # get raster data
    cellmap = conductance
    polymap = Matrix{V}(undef, 0, 0)
    source_map = source
    ground_map = ground
    points_rc = (V[], V[], V[])
    strengths = Matrix{T}(undef, 0, 0)

    included_pairs = Circuitscape.IncludeExcludePairs(:undef,
                                                      V[],
                                                      Matrix{V}(undef,0,0))

    # This is just to satisfy type requirements, most of it not used
    hbmeta = Circuitscape.RasterMeta(size(cellmap)[2],
                                     size(cellmap)[1],
                                     0.,
                                     0.,
                                     1.,
                                     -9999.,
                                     Array{Float64, 1}(undef, 1),
                                     "")

    rasterdata = Circuitscape.RasData(cellmap,
                                      polymap,
                                      source_map,
                                      ground_map,
                                      points_rc,
                                      strengths,
                                      included_pairs,
                                      hbmeta)

    # Generate advanced data
    data = Circuitscape.compute_advanced_data(rasterdata, cs_flags, cs_cfg)

    G = data.G
    nodemap = data.nodemap
    polymap = data.polymap
    hbmeta = data.hbmeta
    sources = data.sources
    grounds = data.grounds
    finitegrounds = data.finite_grounds
    cc = data.cc
    src = data.src
    check_node = data.check_node
    source_map = data.source_map # Need it for one to all mode
    cellmap = data.cellmap

    # Flags
    is_raster = cs_flags.is_raster
    is_alltoone = cs_flags.is_alltoone
    is_onetoall = cs_flags.is_onetoall
    write_v_maps = cs_flags.outputflags.write_volt_maps
    write_c_maps = cs_flags.outputflags.write_cur_maps
    write_cum_cur_map_only = cs_flags.outputflags.write_cum_cur_map_only

    volt = zeros(eltype(G), size(nodemap))
    ind = findall(x -> x != 0, nodemap)
    f_local = Vector{eltype(G)}()
    solver_called = false
    voltages = Vector{eltype(G)}()
    outvolt = Circuitscape.alloc_map(hbmeta)
    outcurr = Circuitscape.alloc_map(hbmeta)

    for c in cc
        if check_node != -1 && !(check_node in c)
            continue
        end

        # a_local = laplacian(G[c, c])
        a_local = G[c,c]
        s_local = sources[c]
        g_local = grounds[c]

        if sum(s_local) == 0 || sum(g_local) == 0
            continue
        end

        if finitegrounds != [-9999.]
            f_local = finitegrounds[c]
        else
            f_local = finitegrounds
        end

        voltages = Circuitscape.multiple_solver(cs_cfg,
                                                a_local,
                                                s_local,
                                                g_local,
                                                f_local)

        local_nodemap = Circuitscape.construct_local_node_map(nodemap,
                                                              c,
                                                              polymap)

        solver_called = true

        Circuitscape.accum_currents!(outcurr,
                                     voltages,
                                     cs_cfg,
                                     a_local,
                                     voltages,
                                     f_local,
                                     local_nodemap,
                                     hbmeta)
    end

    outcurr
end

function solve_target!(
        i::Int64,
        n_targets::Int64,
        int_arguments::Dict{String, Int64},
        targets::Array{T, 2} where T <: Number,
        source_strength::Array{Union{Missing, T}, 2} where T <: Number,
        resistance::Array{Union{Missing, T}, 2} where T <: Number,
        os_flags::OmniscapeFlags,
        cs_cfg::Dict{String, String},
        cs_flags::Circuitscape.RasterFlags,
        o::Circuitscape.OutputFlags,
        condition1_present::Array{Union{Missing, T}, 2} where T <: Number,
        condition1_future::Array{Union{Missing, T}, 2} where T <: Number,
        condition2_present::Array{Union{Missing, T}, 2} where T <: Number,
        condition2_future::Array{Union{Missing, T}, 2} where T <: Number,
        comparison1::String,
        comparison2::String,
        condition1_lower::Number,
        condition1_upper::Number,
        condition2_lower::Number,
        condition2_upper::Number,
        correction_array::Array{T, 2} where T <: Number,
        cum_currmap::Array{T, 3} where T <: Number,
        fp_cum_currmap::Array{T, 3}  where T <: Number,
        precision::DataType
    )
    ## get source
    x_coord = Int64(targets[i, 1])
    y_coord = Int64(targets[i, 2])
    source = get_source(source_strength,
                        int_arguments,
                        os_flags,
                        condition1_present,
                        condition1_future,
                        condition2_present,
                        condition2_future,
                        comparison1,
                        comparison2,
                        condition1_lower,
                        condition1_upper,
                        condition2_lower,
                        condition2_upper,
                        precision,
                        x = x_coord,
                        y = y_coord,
                        strength = float(targets[i, 3]))

    ## get ground
    ground = get_ground(int_arguments,
                        precision,
                        x = x_coord,
                        y = y_coord)

    ## get conductances for Omniscape
    conductance = get_conductance(resistance,
                                  int_arguments,
                                  x_coord,
                                  y_coord,
                                  os_flags)

    grid_size = size(source)

    ## Run circuitscape
    curr = calculate_current(conductance,
                             source,
                             ground,
                             cs_flags,
                             cs_cfg,
                             precision)

    ## If normalize = True, calculate null map and normalize
    if os_flags.compute_flow_potential
        null_conductance = convert(Array{Union{precision, Missing}, 2}, fill(1, grid_size))

        flow_potential = calculate_current(null_conductance,
                                           source,
                                           ground,
                                           cs_flags,
                                           cs_cfg,
                                           precision)
    end

    if os_flags.correct_artifacts && !(int_arguments["block_size"] == 1)
        correction_array2 = deepcopy(correction_array)
        lowerxcut = 1
        upperxcut = size(correction_array, 2)
        lowerycut = 1
        upperycut = size(correction_array, 1)

        if x_coord > int_arguments["ncols"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperxcut = upperxcut - (upperxcut - grid_size[2])
        end

        if x_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
            lowerxcut = upperxcut - grid_size[2] + 1
        end

        if y_coord > int_arguments["nrows"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperycut = upperycut - (upperycut - grid_size[1])
        end

        if y_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
            lowerycut = upperycut - grid_size[1] + 1
        end

        correction_array2 = correction_array[lowerycut:upperycut,
                                             lowerxcut:upperxcut]

        curr = curr .* correction_array2

        if os_flags.compute_flow_potential
            flow_potential = flow_potential .* correction_array2
        end
    end

    ## Accumulate values
    xlower = max(x_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    xupper = min(x_coord + int_arguments["radius"] + int_arguments["buffer"],
                 int_arguments["ncols"])
    ylower = max(y_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    yupper = min(y_coord + int_arguments["radius"] + int_arguments["buffer"],
                 int_arguments["nrows"])

    cum_currmap[ylower:yupper, xlower:xupper, threadid()] .=
        cum_currmap[ylower:yupper, xlower:xupper, threadid()] .+ curr

    if os_flags.compute_flow_potential
        fp_cum_currmap[ylower:yupper, xlower:xupper, threadid()] .=
            fp_cum_currmap[ylower:yupper, xlower:xupper, threadid()] .+ flow_potential
    end

end

function calc_correction(
        arguments::Dict{String, Int64},
        os_flags::OmniscapeFlags,
        cs_cfg::Dict{String, String},
        cs_flags::Circuitscape.RasterFlags,
        o::Circuitscape.OutputFlags,
        condition1_present::Array{Union{T, Missing}, 2} where T <: Number,
        condition1_future::Array{Union{T, Missing}, 2} where T <: Number,
        condition2_present::Array{Union{T, Missing}, 2}where T <: Number,
        condition2_future::Array{Union{T, Missing}, 2} where T <: Number,
        comparison1::String,
        comparison2::String,
        condition1_lower::Number,
        condition1_upper::Number,
        condition2_lower::Number,
        condition2_upper::Number,
        precision::DataType
    )
    buffer = arguments["buffer"]
    # This may not apply seamlessly in the case (if I add the option) that source strengths
    # are not adjusted by target weight, but stay the same according to their
    # original values. Something to keep in mind...

    temp_source = convert(Array{Union{precision, Missing}, 2},
                          fill(1.0,
                               arguments["radius"] * 2 + buffer * 2 + 1,
                               arguments["radius"] * 2 + buffer * 2 + 1))

    source_null = clip(temp_source,
                            x = arguments["radius"] + buffer + 1,
                            y = arguments["radius"] + buffer + 1,
                            distance = arguments["radius"])

    # Append NoData (-9999) if buffer > 0
    if buffer > 0
        column_dims = (size(source_null)[1], buffer)
        # Add columns
        source_null = hcat(fill(missing, column_dims),
                                source_null,
                                fill(missing, column_dims))

        row_dims = (buffer, size(source_null)[2])
        # Add rows
        source_null = vcat(fill(missing, row_dims),
                                source_null,
                                fill(missing, row_dims))
    end
    n_sources = sum(source_null[(!).(ismissing.(source_null))])

    source_null[ismissing.(source_null)] .= 0.0
    source_null[arguments["radius"] + arguments["buffer"] + 1,
                arguments["radius"] + arguments["buffer"] + 1] = 0.0
    source_null[source_null .!= 0.0] .= 1 / (n_sources - 1)

    source_blocked = get_source(temp_source,
                              arguments,
                              os_flags,
                              condition1_present,
                              condition1_future,
                              condition2_present,
                              condition2_future,
                              comparison1,
                              comparison2,
                              condition1_lower,
                              condition1_upper,
                              condition2_lower,
                              condition2_upper,
                              precision,
                              x = (arguments["radius"] + arguments["buffer"] + 1),
                              y = (arguments["radius"] + arguments["buffer"] + 1),
                              strength = float(arguments["block_size"] ^ 2))

    conductance = clip(temp_source,
                       x = arguments["radius"] + arguments["buffer"] + 1,
                       y = arguments["radius"] + arguments["buffer"] + 1,
                       distance = arguments["radius"] + arguments["buffer"])

    ground = fill(convert(precision, 0.0),
                  size(source_null))

    ground[arguments["radius"] + arguments["buffer"] + 1,
           arguments["radius"] + arguments["buffer"] + 1] = Inf


    block_null_current = calculate_current(conductance,
                                           source_blocked,
                                           ground,
                                           cs_flags,
                                           cs_cfg,
                                           precision)

    null_current =  calculate_current(conductance,
                                      source_null,
                                      ground,
                                      cs_flags,
                                      cs_cfg,
                                      precision)
    null_current_total = fill(convert(precision, 0.),
                              arguments["radius"] * 2 + arguments["buffer"] * 2 + arguments["block_size"],
                              arguments["radius"] * 2 + arguments["buffer"] * 2 + arguments["block_size"])

    for i in 1:arguments["block_size"]
        for j in 1:arguments["block_size"]
            null_current_total[i:(i + arguments["radius"] * 2 + arguments["buffer"] * 2),
                               j:(j + arguments["radius"] * 2 + arguments["buffer"] * 2)] += null_current
        end
    end

    null_current_total = null_current_total[(arguments["block_radius"] + 1):(size(null_current, 1) + arguments["block_radius"]),
                                            (arguments["block_radius"] + 1):(size(null_current, 2) + arguments["block_radius"])]

    null_current_total[block_null_current .== 0.] .= 0

    null_current_total[null_current_total .== 0.0] .= 1.0
    block_null_current[block_null_current .== 0.0] .= 1.0

    correction = null_current_total ./ block_null_current

    correction
end

function get_omniscape_flags(cfg::Dict{String, String})
    OmniscapeFlags(
        cfg["calc_flow_potential"] in TRUELIST,
        cfg["calc_normalized_current"] in TRUELIST,
        cfg["calc_flow_potential"] in TRUELIST || cfg["calc_normalized_current"] in TRUELIST,
        cfg["write_raw_currmap"] in TRUELIST,
        cfg["parallelize"] in TRUELIST,
        cfg["correct_artifacts"] in TRUELIST,
        cfg["source_from_resistance"] in TRUELIST,
        cfg["conditional"] in TRUELIST,
        cfg["mask_nodata"] in TRUELIST,
        cfg["resistance_is_conductance"] in TRUELIST,
        cfg["write_as_tif"] in TRUELIST,
        cfg["allow_different_projections"] in TRUELIST,
        cfg["reclassify_resistance"] in TRUELIST,
        cfg["write_reclassified_resistance"] in TRUELIST
    )
end

# Calculate the source layer using resistance surface and arguments from cfg
function source_from_resistance(resistance::Array{Union{T, Missing}, 2} where T <: Number,
                                cfg::Dict{String, String},
                                reclass_table::Array{T, 2} where T <: Number)
    full_cfg = init_cfg()
    update_cfg!(full_cfg, cfg)
    r_cutoff = parse(Float64, full_cfg["r_cutoff"])
    precision = full_cfg["precision"] in SINGLE ? Float32 : Float64
    reclassify = full_cfg["reclassify_resistance"] in TRUELIST

    if reclassify
        resistance_for_source = deepcopy(resistance)
        reclassify_resistance!(resistance_for_source, reclass_table)
    else
        resistance_for_source = resistance
    end

    source_strength = deepcopy(resistance_for_source)

    if full_cfg["resistance_is_conductance"] ∉ TRUELIST
        source_strength = Array{Union{precision, Missing}, 2}(1 ./ source_strength)
    end
    source_strength[coalesce.(source_strength .< 1/r_cutoff, true)] .= 0.0 # handles replacing NoData with 0 as well

    source_strength
end


function reclassify_resistance!(resistance::Array{Union{T, Missing}, 2} where T <: Number,
                                reclass_table::Array{T, 2} where T <: Number)
    resistance_old = deepcopy(resistance)
    for i in 1:(size(reclass_table)[1])
        resistance[coalesce.(resistance_old .== reclass_table[i, 1], false)] .= reclass_table[i, 2]
    end
    resistance_old = nothing # remove from memory
end
