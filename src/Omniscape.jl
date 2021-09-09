module Omniscape
using ArchGDAL
using Base.Threads
using Circuitscape
using DelimitedFiles
using LinearAlgebra.BLAS
using ProgressMeter
using Random
using StatsBase
using Statistics

include("structs.jl")
include("config.jl")
include("io.jl")
include("consts.jl")
include("utils.jl")
include("main.jl")
include("errors_warnings.jl")
include("main_lock.jl")
export run_omniscape, run_omniscape_lock

end