clip = function(A::Array{Real,2}, x::Real, y::Real, distance::Real)
    dim1 = size(A)[1]
    dim2 = size(A)[2]

    dist = zeros(dim1, dim2)
    for i=1:dim1,j=1:dim2
        dist[i, j] = sqrt((i - x)^2 + (j - y)^2)
    end
    clipped = A
    clipped[dist.>distance] .= -9
    reshape(clipped, dim1, dim2)
end
