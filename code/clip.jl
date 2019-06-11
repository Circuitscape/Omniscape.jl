clip = function(A::Array{Real,2}, x::Real, y::Real, distance::Real)
    dim1 = size(A)[1]
    dim2 = size(A)[2]

    dist = [sqrt((i - x)^2 + (j - y)^2) for i = 1:dim1, j = 1:dim2]

    clipped = A
    clipped[dist .> distance] .= -9999

    output = reshape(clipped, dim1, dim2)
    output
end
