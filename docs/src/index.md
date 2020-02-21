# Omniscape.jl

*A package to compute omnidirectional landscape connectivity*.

Package repository: [https://github.com/Circuitscape/Omniscape.jl](https://github.com/Circuitscape/Omniscape.jl)

!!! note
    This package is currently in the early stages of development. Please test it out and [post issues](https://github.com/Circuitscape/Omniscape.jl/issues/new) to the GitHub repo with any bugs, feature requests, or questions.

## Installation
```julia
using Pkg; Pkg.add("Omniscape")
```

## Overview

This package implements the omnidirectional connectivity algorithm developed by [McRae et al. (2016)](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest). Omniscape.jl is a moving window implementation of [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl) (Anantharaman et al. 2019). Circuitscape.jl applies circuit theory to make spatially-explicit predictions of connectivity using concepts developed by McRae (2006) and McRae et al. (2008).

## Citing Omniscape.jl

A formal paper detailing Omniscape.jl is forthcoming, but until it is published, please use the something like the following to cite Omniscape.jl if you use it in your work:
> Landau, VA 2020. Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language, vX.Y.Z, URL: https://github.com/Circuitscape/Omniscape.jl, DOI: 10.5281/zenodo.3406711.

Here's a bibtex entry:
```
@misc{landau2020omniscape,
    title = {{Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language}},
    author = {Vincent A. Landau},
    year = {2020},
    version = {v0.1.4},
    url = {https://github.com/Circuitscape/Omniscape.jl},
    doi = {10.5281/zenodo.3406711}
}
```
Please also cite the [original work](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) outlining the Omniscape algorithm:
> McRae, B. H., K. Popper, A. Jones, M. Schindel, S. Buttrick, K. R. Hall, R. S. Unnasch, and J. Platt. 2016. Conserving Nature’s Stage: Mapping Omnidirectional Connectivity for Resilient Terrestrial Landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon. 

## References

[[1]](https://arxiv.org/pdf/1906.03542) Anantharaman, R., Hall, K., Shah, V., & Edelman, A. (2019). Circuitscape in Julia: High Performance Connectivity Modelling to Support Conservation Decisions. *arXiv preprint arXiv:1906.03542*.

[[2]](https://circuitscape.org/pubs/McRae_2006_IBR_Evolution.pdf) McRae, B. H. (2006). Isolation by resistance. Evolution, 60(8), 1551-1561.

[[3]](https://circuitscape.org/pubs/McRae_et_al_2008_Ecology.pdf) McRae, B. H., Dickson, B. G., Keitt, T. H., & Shah, V. B. (2008). Using circuit theory to model connectivity in ecology, evolution, and conservation. Ecology, 89(10), 2712-2724.

[[4]](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) McRae, B. H., Popper, K., Jones, A., Schindel, M., Buttrick, S., Hall, K., Unnasch, B. & Platt, J. (2016). Conserving nature’s stage: mapping omnidirectional connectivity for resilient terrestrial landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.


