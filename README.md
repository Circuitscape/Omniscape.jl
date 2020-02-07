# Omniscape.jl

| **Documentation**  | **Build Status**| **Changelog**|
|:-----------------------------------------------------:|:------------------------------------:|:-----------:|
| [![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/stable) [![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/dev) | [![Build Status](https://travis-ci.org/Circuitscape/Omniscape.jl.svg?branch=master)](https://travis-ci.org/Circuitscape/Omniscape.jl) [![Build status](https://ci.appveyor.com/api/projects/status/5mw77lobayetc9wh?svg=true)](https://ci.appveyor.com/project/vlandau/omniscape-jl) [![codecov](https://codecov.io/gh/Circuitscape/Omniscape.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Circuitscape/Omniscape.jl) | [![news](https://img.shields.io/badge/version-v0.1.4-orange)](https://github.com/Circuitscape/Omniscape.jl/blob/master/NEWS.md#news--changelog)


Omniscape.jl is a Julia package that provides an open-source, updated version of [Omniscape](https://conservationgateway.org/ConservationByGeography/NorthAmerica/UnitedStates/oregon/science/Documents/McRae_et_al_2016_PNW_CNS_Connectivity.pdf) with improved reliability and speed. Visit https://circuitscape.github.io/Omniscape.jl/stable for documentation.
## Installation

Enter the following into a Julia terminal to install Omniscape.jl.
```julia
using Pkg; Pkg.add("Omniscape")
```
## Using with Docker

A Docker image with the latest version of Omniscape is [available on Docker Hub](https://hub.docker.com/r/vlandau/omniscape). To pull the image and start an Omniscape Docker container from your terminal, navigate to the directory containing your Omniscape input files (via `cd`) and run the following:

On Linux/Mac:
```
docker run -it --rm \
	-v $(pwd):/home/omniscape \
	vlandau/omniscape:0.1.4
```

On Windows (via Windows Command Line):
```
docker run -it --rm^
 -v %cd%:/home/omniscape^
 vlandau/omniscape:0.1.4
```
Note that the `-v` flag and subsequent code will mount the files in your current working directory and make them available to the Docker container (which is why you need to run the code above from the directory containing all needed input files). Once you're in Julia in the Docker container, run `cd("/home/omniscape")` to navigate to the location where you mounted your files, and you'll be ready to go! Make sure that the file paths in your .ini file are relative to /home/omniscape.

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
