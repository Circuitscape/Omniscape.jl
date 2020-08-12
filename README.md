# Omniscape.jl

| **Documentation**  | **Build Status**| **Changelog**|
|:-----------------------------------------------------:|:------------------------------------:|:-----------:|
| [![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/stable) [![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/dev) | [![Build Status](https://travis-ci.org/Circuitscape/Omniscape.jl.svg?branch=main)](https://travis-ci.org/Circuitscape/Omniscape.jl) [![Build status](https://ci.appveyor.com/api/projects/status/5mw77lobayetc9wh?svg=true)](https://ci.appveyor.com/project/vlandau/omniscape-jl) [![codecov](https://codecov.io/gh/Circuitscape/Omniscape.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/Circuitscape/Omniscape.jl) | [![news](https://img.shields.io/static/v1?label=version&message=v0.4.0&color=orange)](https://github.com/Circuitscape/Omniscape.jl/releases/latest)

The Omniscape algorithm was developed by [McRae and colleagues](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) in 2016 as a method to compute omnidirectional habitat connectivity. Omniscape.jl is an open-source, easy-to-use software package for Julia that offers an efficient and updated implementation of the Omniscape algorithm. **Check out [the docs](https://circuitscape.github.io/Omniscape.jl/stable) for additional information.**

## Installation

**Omniscape.jl currently requires Julia version 1.5 or greater**. You can install Julia [here](https://julialang.org/downloads/). Once installation is complete, open a Julia terminal and run the following code to install Omniscape.jl.
```julia
using Pkg; Pkg.add("Omniscape")
```
If you want to install the latest (unreleased) development version of Omniscape, you can get it by running:
```julia
using Pkg; Pkg.add(PackageSpec(name = "Omniscape", rev = "main"))
```

## Using with Docker

A Docker image with the latest version of Omniscape (precompiled so `using Omniscape` will run instantly!) is [available on Docker Hub](https://hub.docker.com/r/vlandau/omniscape). To pull the image and start an Omniscape Docker container from your terminal, navigate to the directory containing your Omniscape input files (via `cd`) and run the following (setting `JULIA_NUM_THREADS` to however many threads you want to use for parallel processing):

On Linux/Mac:
```
docker run -it --rm \
	-v $(pwd):/home/omniscape \
	-w /home/omniscape \
	-e JULIA_NUM_THREADS=2 \
	vlandau/omniscape:0.4.0
```

On Windows (via Windows Command Line):
```
docker run -it --rm^
 -v %cd%:/home/omniscape^
 -w /home/omniscape^
 -e JULIA_NUM_THREADS=2^
 vlandau/omniscape:0.4.0
```
Note that the `-v` flag and subsequent code will mount the files in your current working directory and make them available to the Docker container (which is why you need to run the code above from the directory containing all needed input files). Once you're in Julia in the Docker container, you're ready to go! Make sure that the file paths in your .ini file are relative to the working directory from which you ran Docker.

## Citing Omniscape.jl

A formal paper detailing Omniscape.jl is forthcoming, but until it is published, please use the something like the following to cite Omniscape.jl if you use it in your work:
> Landau, V. A. 2020. Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language, vX.Y.Z, URL: https://github.com/Circuitscape/Omniscape.jl, DOI: 10.5281/zenodo.3406711.

Here's a bibtex entry:
```
@misc{landau2020omniscape,
    title = {{Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language}},
    author = {Vincent A. Landau},
    year = {2020},
    version = {v0.4.0},
    url = {https://github.com/Circuitscape/Omniscape.jl},
    doi = {10.5281/zenodo.3406711}
}
```

Please also cite the [original work](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) where the Omniscape algorithm was first described:
> McRae, B. H., K. Popper, A. Jones, M. Schindel, S. Buttrick, K. R. Hall, R. S. Unnasch, and J. Platt. 2016. Conserving Nature’s Stage: Mapping Omnidirectional Connectivity for Resilient Terrestrial Landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.
