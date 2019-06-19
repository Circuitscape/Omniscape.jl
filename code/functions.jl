clip = function(A; x_coord, y_coord, distance)
    dim1 = size(A)[1]
    dim2 = size(A)[2]

    dist = [sqrt((i - x_coord)^2 + (j - y_coord)^2) for i = 1:dim1, j = 1:dim2]

    clipped = deepcopy(A)
    clipped[dist .> distance] .= -9999

    output = reshape(clipped, dim1, dim2)
    output
end


function get_targets(;source_array)
    source_array[source_array .< threshold] .= 0

    nrows = size(source_array, 1)
    ncols = size(source_array, 2)

    start = (block_size + 1) / 2

    xs = [start:block_size:nrows;]
    ys = [start:block_size:ncols;]

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

    ground_points = cat(ground_points,
                        zeros(size(ground_points)[1], 1);
                        dims = 2
                    )

    for i = 1:size(ground_points)[1]
        xlower = Int64(ground_points[i, 1] - block_radius)
        xupper = min(Int64(ground_points[i, 1] + block_radius), nrows)
        ylower = Int64(ground_points[i, 2] - block_radius)
        yupper = min(Int64(ground_points[i, 2] + block_radius), ncols)

        ground_points[i, 3] = sum(source_array[xlower:xupper, ylower:yupper]) # FIXME: Floating point rounding errors
    end

    targets = ground_points[ground_points[:,3] .> 0, 1:3]
    targets
end

# x and y defined by targets object. Ultimately the for loop will be done by
# iterating through rows of targets object
function get_source(;source_array, x, y, strength)
    source_subset = clip(source_array,
                         x_coord = x,
                         y_coord = y,
                         distance = radius)

    # Set any sources inside target to NoData
    xlower = Int64(x - block_radius)
    xupper = min(Int64(x + block_radius), nrows)
    ylower = Int64(y - block_radius)
    yupper = min(Int64(y + block_radius), ncols)

    source_subset[xlower:xupper, ylower:yupper] .= -9999
    source_subset[source_subset .== 0.0] .= -9999

    # Extract subset for faster solve times
    xlower_buffered = max(x - radius - buffer, 1)
    xupper_buffered = min(x + radius + buffer, nrows)
    ylower_buffered = max(y - radius - buffer, 1)
    yupper_buffered = min(y + radius + buffer, nrows)

    source_subset = source_subset[xlower_buffered:xupper_buffered,
                                  ylower_buffered:yupper_buffered]

    # allocate total current equal to target "strength", divide among sources
    # according to their source strengths
    source_sum = sum(source_subset[source_subset .> 0])
    source_subset[source_subset .> 0] .=
        (source_subset[source_subset .> 0] * strength) / source_sum

    source_subset
end

function get_ground(;x, y)
    xlower_buffered = max(x - radius - buffer, 1)
    xupper_buffered = min(x + radius + buffer, nrows)
    ylower_buffered = max(y - radius - buffer, 1)
    yupper_buffered = min(y + radius + buffer, nrows)

    ground = fill(-9999,
                  xupper_buffered - xlower_buffered,
                  yupper_buffered - ylower_buffered)
    ground[x, y] = 0

    ground
end
