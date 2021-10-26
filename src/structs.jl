import Base: size, getindex, setindex!, length, sum, eltype, view
import Base.Broadcast: broadcasted, broadcast
import StatsBase: mode
import Statistics: median

struct OmniscapeFlags
    calc_flow_potential::Bool
    calc_normalized_current::Bool
    compute_flow_potential::Bool #bad name, but need a variable that stores the "or" of the previous two, internal use only
    write_raw_currmap::Bool
    parallelize::Bool
    correct_artifacts::Bool
    source_from_resistance::Bool
    conditional::Bool
    mask_nodata ::Bool
    resistance_is_conductance::Bool
    write_as_tif::Bool
    allow_different_projections::Bool
    reclassify::Bool
    write_reclassified_resistance::Bool
end

struct Target
    x_coord::Int64
    y_coord::Int64
    amps::Float64
end

struct Conditions
    comparison1::String
    comparison2::String
    condition1_lower::Number
    condition1_upper::Number
    condition2_lower::Number
    condition2_upper::Number
end


const MissingArray{T, N} = Array{Union{Missing, T}, N}

struct ConditionLayers{T, N}
    condition1_present::MissingArray{T, N}
    condition1_future::MissingArray{T, N}
    condition2_present::MissingArray{T, N}
    condition2_future::MissingArray{T, N}
end

function missingarray(
        A::Array{T, N} where T <: Union{Missing, Number} where N,
        precision::DataType,
        nodata::Number
    )
    output = convert(Array{Union{precision, Missing}, ndims(A)}, copy(A))
    output[output .== nodata] .= missing
    
    return output
end

function missingarray_to_array(
        A::MissingArray{T, N} where T <: Number where N,
        nodata::Number
    )
    output = copy(A)
    output[ismissing.(output)] .= nodata

    return convert(Array{typeof(output[1]), ndims(output)}, output)
end
