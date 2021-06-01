<img src='docs/src/assets/logo.png' width=300/>

| **Docs** | **Chat** | **Cite** | **Build Status** |
|:-----------------------------------------------------:|:------------------------------------:|:-----------:|:-------:|
| [![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.circuitscape.org/Omniscape.jl/stable) [![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://docs.circuitscape.org/Omniscape.jl/latest) | [![gitter](https://badges.gitter.im/Circuitscape/Omniscape.jl.png)](https://gitter.im/Circuitscape/Omniscape.jl) | [![DOI](https://joss.theoj.org/papers/10.21105/joss.02829/status.svg)](https://doi.org/10.21105/joss.02829) | [![Build Status](https://github.com/Circuitscape/Omniscape.jl/workflows/CI/badge.svg)](https://github.com/Circuitscape/Omniscape.jl/actions?query=workflow%3ACI) [![codecov](https://codecov.io/gh/Circuitscape/Omniscape.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Circuitscape/Omniscape.jl) [![news](https://img.shields.io/static/v1?label=version&message=v0.5.0&color=orange)](https://github.com/Circuitscape/Omniscape.jl/releases) |

Omniscape.jl is built on [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl) and implements the Omniscape connectivity modeling algorithm to map omni-directional habitat connectivity. The Omniscape algorithm was developed by [McRae and colleagues](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) in 2016. **Check out [the docs](https://circuitscape.github.io/Omniscape.jl/stable) for additional information.**

## Installation

**The latest version of Omniscape.jl requires Julia version 1.5 or greater**. You can install Julia [here](https://julialang.org/downloads/). Once installation is complete, open a Julia terminal and run the following code to install Omniscape.jl.
```julia
using Pkg; Pkg.add("Omniscape")
```
If you want to install the latest (unreleased) development version of Omniscape, you can get it by running:
```julia
using Pkg; Pkg.add(PackageSpec(name = "Omniscape", rev = "main"))
```

## Citing Omniscape.jl 

Please cite [Landau et al. (2021)](https://doi.org/10.21105/joss.02829) when using Omniscape.jl.
> Landau, V.A., V.B. Shah, R. Anantharaman, and K.R. Hall. 2021. Omniscape.jl: Software to compute omnidirectional landscape connectivity. *Journal of Open Source Software*, *6*(57), 2829.

Here's a bibtex entry:
```
@article{Landau2021,
  doi = {10.21105/joss.02829},
  url = {https://doi.org/10.21105/joss.02829},
  year = {2021},
  publisher = {The Open Journal},
  volume = {6},
  number = {57},
  pages = {2829},
  author = {Vincent A. Landau and Viral B. Shah and Ranjan Anantharaman and Kimberly R. Hall},
  title = {Omniscape.jl: Software to compute omnidirectional landscape connectivity},
  journal = {Journal of Open Source Software}
}

```

Please be sure to also cite the [original work](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) where the Omniscape algorithm was first described:
> McRae, B. H., K. Popper, A. Jones, M. Schindel, S. Buttrick, K. R. Hall, R. S. Unnasch, and J. Platt. 2016. Conserving Nature’s Stage: Mapping Omnidirectional Connectivity for Resilient Terrestrial Landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.

## Contributing
Contributions in the form of pull requests are always welcome and appreciated. To report a bug or make a feature request, please [file an issue](https://github.com/Circuitscape/Omniscape.jl/issues/new). For general discussions and questions about usage, start a conversation on [gitter](https://gitter.im/Circuitscape/Omniscape.jl).

## Acknowledgments
Development of this software package was made possible by funding from NASA's Ecological Forecasting program and the Wilburforce Foundation through a project led by Kim Hall at The Nature Conservancy. This software package would not have been possible without Brad McRae (1966-2017), the visionary behind Circuitscape, the Omniscape algorithm, and several other software tools for assessing connectivity. Omniscape.jl is built on [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl), which was authored by Ranjan Anantharaman and Viral Shah, both of whom have been incredibly helpful in steering and guiding the development of Omniscape.jl. Kim Hall, Aaron Jones, Carrie Schloss, Melissa Clark, Jim Platt, and early Omniscape.jl users helped steer software development by providing valuable feedback and insight.
