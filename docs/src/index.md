# Omniscape.jl

!!! note
    This package is currently in the early stages of development. Please test it out and [post issues](https://github.com/Circuitscape/Omniscape.jl/issues/new) to the GitHub repo with any bugs, feature requests, or questions.

*A package to compute omnidirectional landscape connectivity*

This package implements the omnidirectional connectivity algorithm developed by [McRae et al. (2016)](https://conservationgateway.org/ConservationByGeography/NorthAmerica/UnitedStates/oregon/science/Documents/McRae_et_al_2016_PNW_CNS_Connectivity.pdf). Omniscape.jl is a moving window implementation of [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl).

## Installation
```julia
using Pkg; Pkg.add(PackageSpec(url = "https://github.com/Circuitscape/Omniscape.jl"))
```