block_size = 7
threshold = 0.5
source = reshape(rand(15000), 100, 150)
source[source .< threshold] .= 0
#function get_target_blocks(
#        source::Array{Real, 2},
#        block_size::Int64,
#        dims::Vector{Int64})
#
if iseven(block_size)
    @warn "Block_size is even, but must be odd. Using block_size + 1."
    block_size = block_size + 1
end

nrows = size(source, 1)
ncols = size(source, 2)

start = (block_size + 1) / 2
block_radius = start - 1
xs = [start:start:nrows;]
ys = [start:start:ncols;]

ground_points = fill(0., (length(xs)*length(ys), 2))

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

    ground_points[i, 3] = sum(source[xlower:xupper, ylower:yupper])
end
source
ground_points
targets = ground_points[ground_points[:,3] .> 0, 1:3]
