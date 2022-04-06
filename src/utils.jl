import Circuitscape: compute_omniscape_current

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
        ground_points[i, 3] = sum(skipmissing(source_array[ylower:yupper, xlower:xupper]))
    end

    # get rid of ground_points with strength equal to 0
    targets = ground_points[ground_points[:, 3] .> 0, 1:3]
    targets
end

# x and y defined by targets object.
function get_source(
        source_array::MissingArray{T, 2} where T <: Number,
        arguments::Dict{String, Int64},
        conditional::Bool,
        condition_layers::ConditionLayers,
        conditions::Conditions,
        target::Target
    )

    block_radius = arguments["block_radius"]
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    source_subset = clip(
        source_array,
        x = target.x_coord,
        y = target.y_coord,
        distance = radius
    )

    # Append missing if buffer > 0
    if buffer > 0
        ### Columns
        nrow_sub = size(source_subset)[1]
        left_col_num = max(0, min(buffer, target.x_coord - radius - 1))
        right_col_num = max(0, min(buffer, ncols - (target.x_coord + radius)))

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
        top_row_num = max(0, min(buffer, target.y_coord - radius - 1))
        bottom_row_num = max(0, min(buffer, nrows - (target.y_coord + radius)))

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
        (source_subset[coalesce.(source_subset .> 0, false)] * target.amps) / source_sum

    if conditional

        xlower_buffered = Int64(max(target.x_coord - radius - buffer, 1))
        xupper_buffered = Int64(min(target.x_coord + radius + buffer, ncols))
        ylower_buffered = Int64(max(target.y_coord - radius - buffer, 1))
        yupper_buffered = Int64(min(target.y_coord + radius + buffer, nrows))
        xlower = target.x_coord - block_radius
        xupper = min(target.x_coord + block_radius, ncols)
        ylower = target.y_coord - block_radius
        yupper = min(target.y_coord + block_radius, nrows)

        source_target_match!(source_subset,
                             arguments["n_conditions"],
                             condition_layers,
                             conditions,
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

function source_target_match!(
        source_subset::MissingArray{T, 2} where T <: Number,
        n_conditions::Int64,
        condition_layers::ConditionLayers,
        conditions::Conditions,
        ylower::Int64,
        yupper::Int64,
        xlower::Int64,
        xupper::Int64,
        ylower_buffered::Int64,
        yupper_buffered::Int64,
        xlower_buffered::Int64,
        xupper_buffered::Int64
    )
    condition1_present = condition_layers.condition1_present
    condition1_future = condition_layers.condition1_future
    condition2_present = condition_layers.condition2_present
    condition2_future = condition_layers.condition2_future

    comparison1 = conditions.comparison1
    comparison2 = conditions.comparison2
    condition1_lower = conditions.condition1_lower
    condition1_upper = conditions.condition1_upper
    condition2_lower = conditions.condition2_lower
    condition2_upper = conditions.condition2_upper
    
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

function get_ground(arguments::Dict{String, Int64},
                    precision::DataType,
                    target::Target)
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    distance = radius + buffer

    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    xlower = Int64(max(target.x_coord - radius - buffer, 1))
    xupper = Int64(min(target.x_coord + radius + buffer, ncols))
    ylower = Int64(max(target.y_coord - radius - buffer, 1))
    yupper = Int64(min(target.y_coord + radius + buffer, nrows))

    size_x = xupper - xlower + 1
    size_y = yupper - ylower + 1

    ground = fill(convert(precision, 0.0),
                  size_y,
                  size_x)

    new_x = min(distance + 1, target.x_coord)
    new_y = min(distance + 1, target.y_coord)

    ground[new_y, new_x] = Inf

    ground
end

function get_conductance(
        resistance::MissingArray{T, 2} where T <: Number,
        arguments::Dict{String, Int64},
        target::Target,
        os_flags::OmniscapeFlags
    )

    radius = arguments["radius"]
    buffer = arguments["buffer"]

    resistance_clipped = clip(resistance, x = target.x_coord, y = target.y_coord, distance = radius + buffer)

    if os_flags.resistance_is_conductance
        conductance = resistance_clipped
    else
        conductance = 1 ./ resistance_clipped
    end

    convert(typeof(resistance_clipped), conductance)
end

function solve_target!(
        target::Target,
        int_arguments::Dict{String, Int64},
        source_strength::MissingArray{T, 2} where T <: Number,
        resistance::MissingArray{T, 2} where T <: Number,
        os_flags::OmniscapeFlags,
        cs_cfg::Dict{String, String},
        condition_layers::ConditionLayers,
        conditions::Conditions,
        correction_array::Array{T, 2} where T <: Number,
        cum_currmap::Array{T, 3} where T <: Number,
        fp_cum_currmap::Array{T, 3}  where T <: Number,
        precision::DataType
    )

    ## get source
    source = get_source(source_strength,
                        int_arguments,
                        os_flags.conditional,
                        condition_layers,
                        conditions,
                        target)

    ## get ground
    ground = get_ground(int_arguments,
                        precision,
                        target)

    ## get conductances for Omniscape
    conductance = get_conductance(resistance,
                                  int_arguments,
                                  target,
                                  os_flags)

    grid_size = size(source)

    ## Run circuitscape
    conductance = missingarray_to_array(conductance, -9999)
    source = missingarray_to_array(source, -9999)
    
    curr = compute_omniscape_current(conductance,
                                     source,
                                     ground,
                                     cs_cfg)

    ## If normalize = True, calculate null map and normalize
    if os_flags.compute_flow_potential
        null_conductance = convert(Array{precision, 2}, fill(1, grid_size))

        flow_potential = compute_omniscape_current(null_conductance,
                                                   source,
                                                   ground,
                                                   cs_cfg)
    end

    if os_flags.correct_artifacts && !(int_arguments["block_size"] == 1)
        correction_array2 = deepcopy(correction_array)
        lowerxcut = 1
        upperxcut = size(correction_array, 2)
        lowerycut = 1
        upperycut = size(correction_array, 1)

        if target.x_coord > int_arguments["ncols"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperxcut = upperxcut - (upperxcut - grid_size[2])
        end

        if target.x_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
            lowerxcut = upperxcut - grid_size[2] + 1
        end

        if target.y_coord > int_arguments["nrows"] - (int_arguments["radius"] + int_arguments["buffer"])
            upperycut = upperycut - (upperycut - grid_size[1])
        end

        if target.y_coord < int_arguments["radius"] + int_arguments["buffer"] + 1
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
    xlower = max(target.x_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    xupper = min(target.x_coord + int_arguments["radius"] + int_arguments["buffer"],
                 int_arguments["ncols"])
    ylower = max(target.y_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    yupper = min(target.y_coord + int_arguments["radius"] + int_arguments["buffer"],
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
        condition_layers::ConditionLayers,
        conditions::Conditions,
        precision::DataType
    )
    buffer = arguments["buffer"]
    # This may not apply seamlessly in the case (if I add the option) that source strengths
    # are not adjusted by target weight, but stay the same according to their
    # original values. Something to keep in mind...

    temp_source = convert(
        Array{precision, 2},
        fill(
            1.0,
            arguments["radius"] * 2 + buffer * 2 + 1,
            arguments["radius"] * 2 + buffer * 2 + 1
        )
    )
    temp_source = missingarray(temp_source, precision, -9999)

    source_null = clip(temp_source,
                       x = arguments["radius"] + buffer + 1,
                       y = arguments["radius"] + buffer + 1,
                       distance = arguments["radius"])

    # Append NoData (missing) if buffer > 0
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

    n_sources = sum(skipmissing(source_null))

    source_null[ismissing.(source_null)] .= 0.0
    source_null[arguments["radius"] + arguments["buffer"] + 1,
                arguments["radius"] + arguments["buffer"] + 1] = 0.0
    source_null[source_null .!= 0.0] .= 1 / (n_sources - 1)

    target = Target((arguments["radius"] + arguments["buffer"] + 1),
                    (arguments["radius"] + arguments["buffer"] + 1),
                    float(arguments["block_size"] ^ 2))
    
    source_blocked = get_source(temp_source,
                                arguments,
                                false,
                                condition_layers,
                                conditions,
                                target)

    conductance = clip(temp_source,
                       x = arguments["radius"] + arguments["buffer"] + 1,
                       y = arguments["radius"] + arguments["buffer"] + 1,
                       distance = arguments["radius"] + arguments["buffer"])

    ground = fill(convert(precision, 0.0),
                  size(source_null))

    ground[arguments["radius"] + arguments["buffer"] + 1,
           arguments["radius"] + arguments["buffer"] + 1] = Inf


    # Convert inputs for Circuitscape current solve
    conductance = missingarray_to_array(conductance, -9999)
    source_blocked = missingarray_to_array(source_blocked, -9999)
    source_null = missingarray_to_array(source_null, -9999)

    block_null_current = compute_omniscape_current(conductance,
                                                   source_blocked,
                                                   ground,
                                                   cs_cfg)

    null_current =  compute_omniscape_current(conductance,
                                              source_null,
                                              ground,
                                              cs_cfg)

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
function source_from_resistance(resistance::MissingArray{T, 2} where T <: Number,
                                cfg::Dict{String, String},
                                reclass_table::MissingArray{T, 2} where T <: Number)
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

function reclassify_resistance!(resistance::MissingArray{T, 2} where T <: Number,
                                reclass_table::MissingArray{T, 2} where T <: Number)
    resistance_old = deepcopy(resistance)
    for i in 1:(size(reclass_table)[1])
        resistance[coalesce.(resistance_old .== reclass_table[i, 1], false)] .= reclass_table[i, 2]
    end
    resistance_old = nothing # remove from memory
end

function arrays_equal(A::MissingArray{T, 2} where T <: Number,
                      B::MissingArray{T, 2} where T <: Number)
    # Check that non-missing entries are equal
    A[ismissing.(A)] .= -9999
    B[ismissing.(B)] .= -9999

    isapprox(Array{Float64, 2}(A), Array{Float64, 2}(B); rtol = 1e-6)
end

"""
    missingarray(A::Array{T, N}, T::DataType, nodata::Number)

This function converts an array to a `MissingArray` and replaces `nodata`
values with `missing` in the output. `MissingArray{T, N}` is an alias 
for `Array{Union{T, Missing}, N}`. This function can be used to prepare
inputs for [`run_omniscape`](@ref).

# Parameters

**`A`**: The array to convert.

**`T`**: The data type for the output (e.g. Float64 or Float32).

**`nodata`**: The numeric value to be replaced by `missing` in the result.
"""
function missingarray(
        A::Array{T, N} where T <: Union{Missing, Number} where N,
        T::DataType,
        nodata::Number
    )
    output = convert(Array{Union{T, Missing}, ndims(A)}, copy(A))
    output[output .== nodata] .= missing

    return output
end

"""
    missing_array_to_array(A::MissingArray{T, N}, nodata::Number)

This function converts an array of type `MissingArray` to a numeric array 
and replaces `missing` entries with `nodata`. `MissingArray{T, N}` is an alias 
for `Array{Union{T, Missing}, N}`.

# Parameters

**`A`**: The array to convert.

**`nodata`**: The numeric value with which `missing` values will be replaced in 
the result.
"""
function missingarray_to_array(
        A::MissingArray{T, N} where T <: Number where N,
        nodata::Number
    )
    output = copy(A)
    output[ismissing.(output)] .= nodata

    return convert(Array{typeof(output[1]), ndims(output)}, output)
end

### Utility functions for chunking (distributed computing)
"""
    get_chunk_extents(
        chunks::Tuple, 
        shape::Tuple,
        radius::Integer,
        block_size::Integer
    )

This function is used to calculate the index boundaries of each array chunk. 
Omniscape input arrays can be chunked and solved in parallel. We need to account
for the block_size argument used for Omniscape (and chunk boundaries need to 
align with block boundaries) to ensure that the chunked approach also results
in the same answer as a non-chunked approach. Returns a vector of 4-length 
vectors describing the extents of each chunk. The elements in the vector 
elements are orders as follows: top, bottom, left, right -- (extent described by
`[top:bottom, left:right]`).

# Parameters

**`chunks`**: A tuple describing how to chunk the landscape `(n_row, n_col)`. 
The landscape will be chunked into `n_row` rows and `n_col` columns.

**`shape`**: The size `(rows, columns)` of the array to be chunked.

**`radius`**: The radius used with Omniscape

**`block_size`**: The block size used with Omniscape
"""
function get_chunk_extents(
        chunks::Tuple,
        shape::Tuple,
        radius::Integer,
        block_size::Integer
    )
    block_steps = Int.(floor.((shape ./ (block_size)) ./ chunks))
    ## Add errors if chunks are too small for radius
    # row-wise
    top_row_cuts = Int[]
    bottom_row_cuts = Int[]
    for i in 0:(chunks[1] - 1)
        bottom_idx = ifelse(
            i ∈ [0, chunks[1]],
            block_steps[1] * i * block_size + 1,
            block_steps[1] * i * block_size - radius
        )
        push!(bottom_row_cuts, Int(bottom_idx))

        top_idx = ifelse(
            i == chunks[1],
            shape[1],
            min(block_steps[1] * (i + 1) * block_size + radius, shape[1])
        )
        push!(top_row_cuts, Int(top_idx))
    end

    ## Add errors if chunks are too small for radius
    # row-wise
    left_col_cuts = Int[]
    right_col_cuts = Int[]
    for i in 0:(chunks[2] - 1)
        left_idx = ifelse(
            i ∈ [0, chunks[2]],
            block_steps[2] * i * block_size + 1,
            block_steps[2] * i * block_size - radius
        )
        push!(left_col_cuts, Int(left_idx))

        right_idx = ifelse(
            i == chunks[2],
            shape[2],
            min(block_steps[2] * (i + 1) * block_size + radius, shape[2])
        )
        push!(right_col_cuts, Int(right_idx))
    end

    row_cuts = zip(bottom_row_cuts, top_row_cuts)
    col_cuts = zip(left_col_cuts, right_col_cuts)

    # extents in order top, bottom, left, right, for each chunk
    extents = vec(
        map(
            x->collect(Iterators.flatten(x)),
            Iterators.product(
                collect.(row_cuts),
                collect.(col_cuts)
                )
            )
        )

    return extents
end


"""
    get_compute_extents(chunk_extents::Vector, shape::Tuple)

To avoid doing redundant work and to make stitching outputs from different 
chunks seamless, each target must only be solved in one chunk (raw chunks -- 
the data sent to each worker -- need to overlap since Omniscape is a moving
window algorithm). As long as each target is only solved once, the outputs from
each chunk can simply be summed together (at the proper indices) to get the
correct output. Returns a vector of 4-length vectors describing the extents to
use for iterating through targets when solving each chunk. The elements in the 
vector elements are orders as follows: top, bottom, left, right -- (extent
described by `[top:bottom, left:right]`).

# Parameters

**`chunk_extents`**: A vector of 4-length vectors describing to extent of each
array chunk (returned from `Omniscape.get_chunk_extents`).

**`shape`**: The size `(rows, columns)` of the array being chunked.

"""
function get_compute_extents(chunk_extents, shape)
    compute_extents = []

    for extent in chunk_extents
        compute_extent = [
            extent[1] == 1 ? 1 : extent[1] + radius + 1,
            extent[2] == shape[1] ? extent[2] : extent[2] - radius,
            extent[3] == 1 ? 1 : extent[3] + radius + 1,
            extent[4] == shape[2] ? extent[4] : extent[4] - radius
        ] 
        push!(compute_extents, compute_extent)
    end

    return compute_extents
end

"""
    get_relative_compute_extents(chunk_extents::Vector, compute_extents::Vector)

`get_compute_extents` returns indices relative to the full input arrays. This 
function recalculates the compute extents relative to the current chunk.
Returns a vector of 4-length vectors describing the relative extents to
use for iterating through targets when solving each chunk. The elements in the 
vector elements are orders as follows: top, bottom, left, right -- (extent
described by `[top:bottom, left:right]`).

# Parameters

**`chunk_extents`**: A vector of 4-length vectors describing to extent of each
array chunk (returned from `Omniscape.get_chunk_extents`).

**`compute_extents`**: A vector of 4-length vectors describing to extent over 
which to iterate through targets when solving a chunk (returned from 
`Omniscape.get_compute_extents`).

"""
function get_relative_compute_extents(
        chunk_extents::Vector,
        compute_extents::Vector
    )
    n_chunks = length(chunk_extents)
    rel_extents = []

    # top, bottom, left, right is order of inputs in each vector
    for i in 1:n_chunks
        chunk_extents = chunk_extents[i]
        compute_extent = compute_extents[i]

        # top = extent[1] == 1 ? 1 : compute_extent[1] - extent[1] + 1
        top = compute_extent[1] - chunk_extents[1] + 1
        
        # bottom = extent[2] == shape[1] ? compute_extent[2] - compute_extent[1] + 1 : compute_extent[2] - extent[1] + 1
        bottom = compute_extent[2] - chunk_extents[1] + 1

        # left = extent[3] == 1 ? 1 : compute_extent[3] - extent[3] + 1
        left = compute_extent[3] - chunk_extents[3] + 1

        # right = extent[4] == shape[2] ? compute_extent[4] - compute_extent[3] + 1 : compute_extent[4] - extent[3] + 1
        right = compute_extent[4] - chunk_extents[3] + 1

        push!(rel_extents, [top, bottom, left, right])
    end
    
    return rel_extents
end