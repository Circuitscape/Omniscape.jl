abstract type Data end

function clip(
        A::Array{Float64, 2};
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

    dist = [sqrt((j - new_x)^2 + (i - new_y)^2) for i = 1:dim1, j = 1:dim2]

    A_sub[dist .> distance] .= -9999

    A_sub
end


function get_targets(
        source_array::Array{Float64, 2},
        arguments::Dict{String, Int64}
    )

    block_size = arguments["block_size"]
    block_radius = arguments["block_radius"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    start = (block_size + 1) / 2

    xs = [start:block_size:ncols;]
    ys = [start:block_size:nrows;]

    ground_points = zeros(Float64,(length(xs)*length(ys), 2))

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
                        zeros(size(ground_points)[1], 1);
                        dims = 2
                    )

    # populate ground_points[, 3] with sum of sources in block of size
    # block_size centered on each target
    for i = 1:size(ground_points)[1]
        xlower = Int64(ground_points[i, 1] - block_radius)
        xupper = min(Int64(ground_points[i, 1] + block_radius), ncols)
        ylower = Int64(ground_points[i, 2] - block_radius)
        yupper = min(Int64(ground_points[i, 2] + block_radius), nrows)

        ground_points[i, 3] = sum(source_array[ylower:yupper, xlower:xupper])
    end

    # get rid of ground_points with strength below 0
    targets = ground_points[ground_points[:, 3] .> 0, 1:3]
    targets
end

# x and y defined by targets object. Ultimately the for loop will be done by
# iterating through rows of targets object
function get_source(
        source_array::Array{Float64, 2},
        arguments::Dict{String, Int64},
        conditional::Bool,
        condition1_present::Array{Float64, 2},
        condition1_future::Array{Float64, 2},
        condition2_present::Array{Float64, 2},
        condition2_future::Array{Float64, 2},
        comparison1::String,
        comparison2::String,
        condition1_lower::Float64,
        condition1_upper::Float64,
        condition2_lower::Float64,
        condition2_upper::Float64;
        x::Int64,
        y::Int64,
        strength::Float64
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

    # Append NoData (-9999) if buffer > 0
    if buffer > 0
        ### Columns
        nrow_sub = size(source_subset)[1]
        left_col_num = max(0, min(buffer, buffer + x - radius - buffer))
        right_col_num = max(0, min(buffer, buffer + ncols - (x + radius + buffer)))

        # Add left columns
        if left_col_num > 0
            source_subset = hcat(fill(-9999., (nrow_sub, left_col_num)),
                                 source_subset)
        end
        # Add right columns
        if right_col_num > 0
            source_subset = hcat(source_subset,
                                 fill(-9999., (nrow_sub, right_col_num)))
        end

        ### Rows
        ncol_sub = size(source_subset)[2]
        top_row_num = max(0, min(buffer, buffer + y - radius - buffer))
        bottom_row_num = max(0, min(buffer, buffer + nrows - (y + radius + buffer)))

        # Add top rows
        if top_row_num > 0
            source_subset = vcat(fill(-9999., (top_row_num, ncol_sub)),
                                    source_subset)
        end
        #Add bottom rows
        if bottom_row_num > 0
            source_subset = vcat(source_subset,
                                 fill(-9999., (bottom_row_num, ncol_sub)))
        end
    end
    
    # Replace nodata vals with 0s
    source_subset[source_subset .== -9999] .= 0.0

    # Set any sources inside target to NoData
    xlower_sub = (radius + buffer  + 1) - block_radius
    xupper_sub = min((radius + buffer  + 1)  + block_radius, ncols)
    ylower_sub = (radius + buffer + 1)  - block_radius
    yupper_sub = min((radius + buffer  + 1)  + block_radius, nrows)

    source_subset[ylower_sub:yupper_sub, xlower_sub:xupper_sub] .= 0

    # allocate total current equal to target "strength", divide among sources
    # according to their source strengths
    source_sum = sum(source_subset[source_subset .> 0])
    source_subset[source_subset .> 0] .=
        (source_subset[source_subset .> 0] * strength) / source_sum

    if conditional

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

function source_target_match!(source_subset::Array{Float64,2},
                              n_conditions::Int64,
                              condition1_present::Array{Float64,2},
                              condition1_future::Array{Float64,2},
                              condition2_present::Array{Float64,2},
                              condition2_future::Array{Float64,2},
                              comparison1::String,
                              comparison2::String,
                              condition1_lower::Float64,
                              condition1_upper::Float64,
                              condition2_lower::Float64,
                              condition2_upper::Float64,
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
      value1 = median(condition1_future[ylower:yupper, xlower:xupper])
      source_subset[((con1_present_subset .- value1) .> condition1_upper) .|
          ((con1_present_subset .- value1) .< condition1_lower)] .= 0
    elseif comparison1 == "equals"
      value1 = mode(condition1_future[ylower:yupper, xlower:xupper])
      source_subset[con1_present_subset .!= value1] .= 0
    end

    if n_conditions == 2
      con2_present_subset = condition2_present[ylower_buffered:yupper_buffered,
                               xlower_buffered:xupper_buffered]
      if comparison2 == "within"
          value2 = median(condition2_future[ylower:yupper, xlower:xupper])
          source_subset[((con2_present_subset .- value2) .> condition2_upper) .|
              ((con2_present_subset .- value2) .< condition2_lower)] .= 0
      elseif comparison2 == "equals"
          value2 = mode(condition2_future[ylower:yupper, xlower:xupper])
          source_subset[con2_present_subset .!= value2] .= 0
      end
    end
end

function get_ground(
        arguments::Dict{String, Int64};
        x::Int64,
        y::Int64
    )

    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    xlower_buffered = Int64(max(x - radius - buffer, 1))
    xupper_buffered = Int64(min(x + radius + buffer, ncols))
    ylower_buffered = Int64(max(y - radius - buffer, 1))
    yupper_buffered = Int64(min(y + radius + buffer, nrows))

    ground = fill(0.0,
                  nrows,
                  ncols)
    ground[y, x] = Inf

    output = ground[ylower_buffered:yupper_buffered,
                    xlower_buffered:xupper_buffered]
    output
end

function get_resistance(
        raw_resistance::Array{Float64, 2},
        arguments::Dict{String, Int64};
        x::Int64,
        y::Int64
    )

    radius = arguments["radius"]
    buffer = arguments["buffer"]

    resistance_clipped = clip(raw_resistance,
                              x = x,
                              y = y,
                              distance = radius + buffer)

    resistance = 1 ./ resistance_clipped
end


function calculate_current(
        resistance::Array{Float64, 2},
        source::Array{Float64, 2},
        ground::Array{Float64, 2},
        flags::Circuitscape.RasterFlags,
        cs_cfg::Dict{String, String}
    )

    T = Float64
    V = Int64

    # get raster data
    cellmap = resistance
    polymap = Matrix{V}(undef, 0, 0)
    source_map = source
    ground_map = ground
    points_rc = (V[], V[], V[])
    strengths = Matrix{T}(undef, 0, 0)

    included_pairs = Circuitscape.IncludeExcludePairs(:undef,
                                                      V[],
                                                      Matrix{V}(undef,0,0))

    hbmeta = Circuitscape.RasterMeta(size(cellmap)[2],
                                     size(cellmap)[1],
                                     0.,
                                     0.,
                                     1.,
                                     -9999.,
                                     0)

    rasterdata = Circuitscape.RasData(cellmap,
                                      polymap,
                                      source_map,
                                      ground_map,
                                      points_rc,
                                      strengths,
                                      included_pairs,
                                      hbmeta)

    # Generate advanced data
    data = Circuitscape.compute_advanced_data(rasterdata, flags)

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
    is_raster = flags.is_raster
    is_alltoone = flags.is_alltoone
    is_onetoall = flags.is_onetoall
    write_v_maps = flags.outputflags.write_volt_maps
    write_c_maps = flags.outputflags.write_cur_maps
    write_cum_cur_map_only = flags.outputflags.write_cum_cur_map_only

    volt = zeros(eltype(G), size(nodemap))
    ind = findall(x -> x != 0,nodemap)
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
        targets::Array{Float64, 2},
        sources_raw::Array{Float64, 2},
        resistance_raw::Array{Float64, 2},
        cs_cfg::Dict{String, String},
        o::Circuitscape.OutputFlags,
        calc_flow_potential::Bool,
        correct_artifacts::Bool,
        conditional::Bool,
        condition1_present::Array{Float64, 2},
        condition1_future::Array{Float64, 2},
        condition2_present::Array{Float64, 2},
        condition2_future::Array{Float64, 2},
        comparison1::String,
        comparison2::String,
        condition1_lower::Float64,
        condition1_upper::Float64,
        condition2_lower::Float64,
        condition2_upper::Float64,
        correction_array::Array{Float64, 2},
        cum_currmap::Array{Float64, 3},
        fp_cum_currmap::Array{Float64, 3}
    )

    ## get source
    @info "Solving target $(i) of $(n_targets)"
    x_coord = Int64(targets[i, 1])
    y_coord = Int64(targets[i, 2])
    source = get_source(sources_raw,
                        int_arguments,
                        conditional,
                        condition1_present,
                        condition1_future,
                        condition2_present,
                        condition2_future,
                        comparison1,
                        comparison2,
                        condition1_lower,
                        condition1_upper,
                        condition2_lower,
                        condition2_upper;
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
    #     solver = "cholmod" # FIXME: "cholmod" not available in advanced mode
    # end

    flags = Circuitscape.RasterFlags(true, false, true,
                                     false, false,
                                     false, Symbol("rmvsrc"),
                                     false, false, solver, o)

    ## Run circuitscape
    curr = calculate_current(resistance, source, ground, flags, cs_cfg)

    ## If normalize = True, calculate null map and normalize
    if calc_flow_potential == true
        @info "Calculating flow potential for target $(i) of $(n_targets)"
        null_resistance = fill(1., grid_size)

        flow_potential = calculate_current(null_resistance,
                                           source,
                                           ground,
                                           flags,
                                           cs_cfg)
    end

    if correct_artifacts
        correction_array2 = deepcopy(correction_array)
        lowerxcut = 1
        upperxcut = size(correction_array, 2)
        lowerycut = 1
        upperycut = size(correction_array, 1)

        if x_coord > int_arguments["ncols"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperxcut = upperxcut -
                            (upperxcut - grid_size[2])
        end

        if x_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
            lowerxcut = upperxcut - grid_size[2] + 1
        end

        if y_coord > int_arguments["nrows"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperycut = upperycut -
                            (upperycut - grid_size[1])
        end

        if y_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
            lowerycut = upperycut - grid_size[1] + 1
        end

        correction_array2 = correction_array[lowerycut:upperycut,
                                             lowerxcut:upperxcut]

        curr = curr .* correction_array2

        if calc_flow_potential
            flow_potential = flow_potential .* correction_array2
        end
    end

    ## Accumulate values
    xlower = max(x_coord - int_arguments["radius"] - int_arguments["buffer"],
                 1)
    xupper = min(x_coord + int_arguments["radius"] + int_arguments["buffer"],
                 int_arguments["ncols"])
    ylower = max(y_coord - int_arguments["radius"] - int_arguments["buffer"],
                 1)
    yupper = min(y_coord + int_arguments["radius"] + int_arguments["buffer"],
                 int_arguments["nrows"])

    cum_currmap[ylower:yupper, xlower:xupper, threadid()] .=
        cum_currmap[ylower:yupper, xlower:xupper, threadid()] .+ curr

    if calc_flow_potential == true
        fp_cum_currmap[ylower:yupper, xlower:xupper, threadid()] .=
            fp_cum_currmap[ylower:yupper, xlower:xupper, threadid()] .+ flow_potential
    end
end

function calc_correction(
        arguments::Dict{String, Int64},
        cs_cfg::Dict{String, String},
        o,
        conditional::Bool,
        condition1_present::Array{Float64, 2},
        condition1_future::Array{Float64, 2},
        condition2_present::Array{Float64, 2},
        condition2_future::Array{Float64, 2},
        comparison1::String,
        comparison2::String,
        condition1_lower::Float64,
        condition1_upper::Float64,
        condition2_lower::Float64,
        condition2_upper::Float64
    )
    buffer = arguments["buffer"]
    # This may not apply seamlessly in the case (if I add the option) that source strengths
    # are not adjusted by target weight, but stay the same according to their
    # original values. Something to keep in mind...

    solver = "cg+amg"

    # if (arguments["radius"]+1)^2 <= 2000000
    #     solver = "cholmod" # FIXME: "cholmod" not available in advanced mode
    # end

    flags = Circuitscape.RasterFlags(true, false, true,
                                     false, false,
                                     false, Symbol("keepall"),
                                     false, false, solver, o)

    temp_source = fill(1.,
                       arguments["radius"] * 2 + buffer * 2 + 1,
                       arguments["radius"] * 2 + buffer * 2 + 1)

    temp_source_clip = clip(temp_source,
                            x = arguments["radius"] + buffer + 1,
                            y = arguments["radius"] + buffer + 1,
                            distance = arguments["radius"])

    # Append NoData (-9999) if buffer > 0
    if buffer > 0
        column_dims = (size(temp_source_clip)[1], buffer)
        # Add columns
        temp_source_clip = hcat(fill(-9999., column_dims),
                                temp_source_clip,
                                fill(-9999., column_dims))

        row_dims = (buffer, size(temp_source_clip)[2])
        # Add rows
        temp_source_clip = vcat(fill(-9999., row_dims),
                                temp_source_clip,
                                fill(-9999., row_dims))
    end
    source_null = deepcopy(temp_source_clip)
    n_sources = sum(source_null[source_null .!= -9999])

    source_null[source_null .== -9999] .= 0.0
    source_null[arguments["radius"] + arguments["buffer"] + 1,
                arguments["radius"] + arguments["buffer"] + 1] = 0.0
    source_null[source_null .!= 0.0] .= 1 / (n_sources - 1)

    source_block = get_source(temp_source,
                              arguments,
                              conditional,
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
                              x = (arguments["radius"] + arguments["buffer"] + 1),
                              y = (arguments["radius"] + arguments["buffer"] + 1),
                              strength = float(arguments["block_size"] ^ 2))

    resistance = clip(temp_source,
                      x = arguments["radius"] + arguments["buffer"] + 1,
                      y = arguments["radius"] + arguments["buffer"] + 1,
                      distance = arguments["radius"] + arguments["buffer"])

    ground = fill(0.0,
                  size(source_null))

    ground[arguments["radius"] + arguments["buffer"] + 1,
           arguments["radius"] + arguments["buffer"] + 1] = Inf

    block_null_current = calculate_current(resistance,
                                           source_block,
                                           ground,
                                           flags,
                                           cs_cfg)

    null_current =  calculate_current(resistance,
                                      source_null,
                                      ground,
                                      flags,
                                      cs_cfg)
    null_current_total = fill(0.,
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
