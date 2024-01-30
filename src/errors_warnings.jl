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

function missing_args_error(missing_args)
    @error "The following arguments are missing from your .ini (or config Dictionary) with no defaults:
       $(join(map(string, missing_args), " "))"
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
    bad_values = minimum(resistance[(!).(ismissing.(resistance))]) <= 0

    if bad_values
        bad_resistance_values_error()
    end

    bad_values
end

function check_block_size!(int_arguments)
    if iseven(int_arguments["block_size"])
        even_block_size_warning()
        int_arguments["block_size"] = int_arguments["block_size"] + 1
    end
    int_arguments["block_size"]
end

function check_missing_args_ini(cfg)
    indices = indexin(REQUIRED_ARGS_INI, convert.(String, keys(cfg)))
    indices[indices .== nothing] .= 0

    is_missing = indices .== 0
    missing_args = REQUIRED_ARGS_INI[is_missing]

    if !isempty(missing_args)
        missing_args_error(missing_args)
    end

    !isempty(missing_args)
end

function check_missing_args_dict(cfg)
    indices = indexin(REQUIRED_ARGS_DICT, convert.(String, keys(cfg)))
    indices[indices .== nothing] .= 0

    is_missing = indices .== 0
    missing_args = REQUIRED_ARGS_DICT[is_missing]

    if !isempty(missing_args)
        missing_args_error(missing_args)
    end

    !isempty(missing_args)
end

function check_solver!(cfg)
    if (cfg["solver"] in SOLVERS) == false
        @warn "Got unsupported value for solver: $(cfg["solver"]). Using the default, cg+amg"
        cfg["solver"] = "cg+amg"
    end
end

function check_unsupported_args(cfg)
    arg_names = String.(keys(cfg))

    bad_args = arg_names[map(x->(x ∉ SUPPORTED_ARGS), arg_names)]
    
    if bad_args != String[] && bad_args != [""]
        
        @warn "The following unsupported arguments were provided and will be ignored:
         $(join(map(string, bad_args), " "))"
    end
end

function check_arg_values(
        cfg::Dict{String, String},
        reclass_table::Union{Nothing, MissingArray{T, 2} where T <: Number},
        condition1::Union{Nothing, MissingArray{T, 2} where T <: Number},
        condition2::Union{Nothing, MissingArray{T, 2} where T <: Number},
        write_outputs::Bool
    )
    # Case when reclass_table is specified but reclass is false
    if (cfg["reclassify_resistance"] ∉ TRUELIST) && (reclass_table !== nothing)
        @error("You provided a reclass_table, but did not specify reclassify_resistance to true.")
    end

    if (condition1 !== nothing || condition2 !== nothing) && (cfg["conditional"] ∉ TRUELIST)
        @error("You provided condition rasters but conditional was not set to true in your config.")
    end
end

