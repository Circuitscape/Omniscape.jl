# Omniscape.jl

| **Documentation**  | **Build Status**| **Changelog**|
|:-----------------------------------------------------:|:------------------------------------:|:-----------:|
| [![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/stable) [![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/dev) | [![Build Status](https://travis-ci.org/Circuitscape/Omniscape.jl.svg?branch=master)](https://travis-ci.org/Circuitscape/Omniscape.jl) [![codecov](https://codecov.io/gh/Circuitscape/Omniscape.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Circuitscape/Omniscape.jl) [![Coverage Status](https://coveralls.io/repos/github/Circuitscape/Omniscape.jl/badge.svg?branch=master)](https://coveralls.io/github/Circuitscape/Omniscape.jl?branch=master) | [![news](https://img.shields.io/badge/version-v0.1.1-orange.svg)](https://github.com/Circuitscape/Omniscape.jl/blob/master/NEWS.md#news--changelog)

Omniscape.jl is a Julia package that  provides an open-source, updated version of [Omniscape](https://conservationgateway.org/ConservationByGeography/NorthAmerica/UnitedStates/oregon/science/Documents/McRae_et_al_2016_PNW_CNS_Connectivity.pdf) with improved reliability and speed. Visit https://circuitscape.github.io/Omniscape.jl/stable for documentation.
## Installation

Enter the following into a Julia terminal to install Omniscape.jl.
```julia
using Pkg; Pkg.add("Omniscape")
```
## Using via Docker

A Docker image with the latest version of Omniscape is [available on Docker Hub](https://hub.docker.com/r/vlandau/omniscape). To pull the image and start an Omniscape Docker container from your terminal, navigate to the directory containing your Omniscape input files (via `cd`) and run the following:

On Linux/Mac:
```
docker run -it --rm \
	-v $(pwd):/home/omniscape \
	vlandau/omniscape:0.1.1
```

On Windows (via Windows Command Line):
```
docker run -it --rm^
 -v %cd%:/home/omniscape^
 vlandau/omniscape:0.1.1
```

Note that the `-v` flag and subsequent code will mount the files in your current working directory and make them available to the Docker container (which is why you need to run the code above from the directory containing all needed input files). Once you're in Julia in the Docker container, run `cd("/home/omniscape")` to navigate to the location where you mounted your files, and you'll be ready to go! Make sure that the file paths in your .ini file are relative to /home/omniscape.

