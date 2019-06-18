clip = function(A; x_coord, y_coord, distance)
    dim1 = size(A)[1]
    dim2 = size(A)[2]

    dist = [sqrt((i - x_coord)^2 + (j - y_coord)^2) for i = 1:dim1, j = 1:dim2]

    clipped = deepcopy(A)
    clipped[dist .> distance] .= -9999

    output = reshape(clipped, dim1, dim2)
    output
end
