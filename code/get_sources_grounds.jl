include("clip.jl")
using BenchmarkTools

## Inputs
block_size = 3
threshold = 0.5
sources_raw = reshape(rand(15000), 100, 150)
## end inputs

function get_targets(;source_array, threshold = 0, block_size = 1)
    source_array[source_array .< threshold] .= 0

    if iseven(block_size)
        @warn "Block_size is even, but must be odd. Using block_size + 1."
        block_size = block_size + 1
    end

    nrows = size(source_array, 1)
    ncols = size(source_array, 2)

    start = (block_size + 1) / 2
    block_radius = start - 1
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

targets = get_targets(source_array = sources_raw, threshold = 0.5, block_size = 5)
include("clip.jl")
radius = 15
buffer = 10
source_array = deepcopy(sources_raw)
block_radius = (block_size - 1) / 2
x = Int64(targets[1,1])
y = Int64(targets[1,2])

# x and y defined by targets object. Ultimately the for loop will be done by
# iterating through rows of targets object
function get_source_subset(;source_array, x, y, radius, buffer)
    source_subset = clip(source_array,
                         x_coord = x,
                         y_coord = y,
                         distance = radius)
    nrows = size(source_array, 1)
    ncols = size(source_array, 2)
    xlower = Int64(x - block_radius)
    xupper = min(Int64(x + block_radius), nrows)
    ylower = Int64(y - block_radius)
    yupper = min(Int64(y + block_radius), ncols)

    source_subset[xlower:xupper, ylower:yupper] .= 0.
    source_subset[source_subset .== 0.0] .= -9999

    xlower_buffered = max(xlower - buffer, 1)
    xupper_buffered = min(xupper + buffer, nrows)
    ylower_buffered = max(ylower - buffer, 1)
    yupper_buffered = min(yupper + buffer, nrows)

    source_subset[xlower_buffered:xupper_buffered,
                  ylower_buffered:yupper_buffered]

    # TODO: scale source subset by ground strength in targets[, 3]
end


xlower = Int64(ground_points[i, 1] - block_radius)
xupper = min(Int64(ground_points[i, 1] + block_radius), nrows)
ylower = Int64(ground_points[i, 2] - block_radius)
yupper = min(Int64(ground_points[i, 2] + block_radius), ncols)
source[xlower:xupper, ylower:yupper] .= 0.
source[source .== 0.0] .= -9999


# TODO: Get global constants working so variables like
# block_radius don't need to be redefined in each function
