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

struct ConditionLayers{T}
    condition1_present::Union{MissingArray{T, 2}, Nothing}
    condition1_future::Union{MissingArray{T, 2}, Nothing}
    condition2_present::Union{MissingArray{T, 2}, Nothing}
    condition2_future::Union{MissingArray{T, 2}, Nothing}
end
