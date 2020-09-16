module Omniscape
    using Circuitscape
    using LinearAlgebra.BLAS
    using Base.Threads
    using StatsBase
    using Statistics
    using DelimitedFiles

    include("config.jl")
    include("consts.jl")
    include("utils.jl")
    include("main.jl")
    include("errors_warnings.jl")
    export run_omniscape
end