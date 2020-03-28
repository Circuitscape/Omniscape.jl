function different_raster_sizes_error(name1, name2)
    @error "$(name1) and $(name2) are different sizes."
end

function different_raster_projections_warning(name1, name2)
    @warn "$(name1) and $(name2) have different projections. This could
mean they are not properly aligned. Attempting to proceed anyway. Press ctrl-c
(or command-c on Mac) to quit."
    sleep(10) # to give the user a chance to read the message and quit before
              # a bunch more terminal outputs starts
end

function bad_resistance_values_error()
    @error "Resistance (or conductance) surface contains 0 or negative values"
end

function even_block_size_warning()
    @warn "block_size is even, but must be odd. Using block_size + 1."
end

function check_raster_alignment(raster1, raster2, name1, name2, allow_different_projections)
    sizes_not_equal = size(raster1[1]) != size(raster2[1])
    projections_not_equal = (raster1[2] != raster2[2]) || (raster1[3] != raster2[3])

    if projections_not_equal && !allow_different_projections
        different_raster_projections_warning(name1, name2)
    end

    if sizes_not_equal
        different_raster_sizes_error(name1, name2)
    end

    sizes_not_equal
end

function check_resistance_values(resistance)
    bad_values = minimum(resistance[resistance .!= -9999]) <= 0

    if bad_values
        bad_resistance_values_error()
    end

    bad_values
end

function check_block_size(block_size)
    even_block_size = iseven(block_size)

    if even_block_size
        even_block_size_warning()
    end

    even_block_size
end