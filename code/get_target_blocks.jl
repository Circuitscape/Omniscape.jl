block_size = 10
source = reshape(randn(15000), 100, 150)
#function get_target_blocks(
#        source::Array{Real, 2},
#        block_size::Int64,
#        dims::Vector{Int64})
#
if iseven(block_size)
    @warn "block_size is even, but must be odd. Updating to block_size + 1."
    block_size = block_size + 1
end

let
    start = (block_size + 1) / 2

    xs = Int64.([start:start:size(source)[1];])
    ys = Int64.([start:start:size(source)[2];])

    ground_points = fill(0, (length(xs)*length(ys), 2))
    c = 1
    for i = 1:length(xs)
        for j = 1:length(ys)
            ground_points[c, 1] = xs[i]
            ground_points[c, 2] = ys[j]
            c += 1
        end
    end
    ground_points
end
