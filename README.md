# Omniscape.jl

| **Documentation**  | **Build Status**| **Changelog**|
|:-----------------------------------------------------:|:------------------------------------:|:-----------:|
| [![docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/stable) [![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Circuitscape.github.io/Omniscape.jl/dev) | [![Build Status](https://travis-ci.org/Circuitscape/Omniscape.jl.svg?branch=master)](https://travis-ci.org/Circuitscape/Omniscape.jl) [![Build status](https://ci.appveyor.com/api/projects/status/5mw77lobayetc9wh?svg=true)](https://ci.appveyor.com/project/vlandau/omniscape-jl) [![codecov](https://codecov.io/gh/Circuitscape/Omniscape.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Circuitscape/Omniscape.jl) | [![news](https://img.shields.io/badge/version-v0.2.2-orange)](https://github.com/Circuitscape/Omniscape.jl/blob/master/NEWS.md#news--changelog)


Omniscape.jl is a Julia package that provides an open-source, updated version of [Omniscape](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) with improved reliability and speed. Visit https://circuitscape.github.io/Omniscape.jl/stable for documentation.
## Installation

Enter the following into a Julia terminal to install Omniscape.jl.
```julia
using Pkg; Pkg.add("Omniscape")
```

### Notes
On Windows systems, you may get an error related to building GDAL, e.g.:
```julia
Building GDAL → C:\Users\username\.julia\packages\GDAL\cvf6T\deps\build.log
┌ Error: Error building GDAL:
ERROR: LoadError: LoadError: Your platform ("x86_64-w64-mingw32", parsed as "x86_64-w64-mingw32-gcc8-cxx11") is not supported by this package!
```

If this happens, trying running `using Pkg; Pkg.add("GDAL")` first, and if needed, restart Julia before trying to install Omniscape again.

## Using with Docker

A Docker image with the latest version of Omniscape is [available on Docker Hub](https://hub.docker.com/r/vlandau/omniscape). To pull the image and start an Omniscape Docker container from your terminal, navigate to the directory containing your Omniscape input files (via `cd`) and run the following (set `JULIA_NUM_THREADS` to however many threads you want to use for parallel processing):

On Linux/Mac:
```
docker run -it --rm \
	-v $(pwd):/home/omniscape \
	-e JULIA_NUM_THREADS=2 \
	vlandau/omniscape:0.2.2
```

On Windows (via Windows Command Line):
```
docker run -it --rm^
 -v %cd%:/home/omniscape^
 -e JULIA_NUM_THREADS=2^
 vlandau/omniscape:0.2.2
```
Note that the `-v` flag and subsequent code will mount the files in your current working directory and make them available to the Docker container (which is why you need to run the code above from the directory containing all needed input files). Once you're in Julia in the Docker container, run `cd("/home/omniscape")` to navigate to the location where you mounted your files, and you'll be ready to go! Make sure that the file paths in your .ini file are relative to /home/omniscape.

## Citing Omniscape.jl

A formal paper detailing Omniscape.jl is forthcoming, but until it is published, please use the something like the following to cite Omniscape.jl if you use it in your work:
> Landau, V. A. 2020. Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language, vX.Y.Z, URL: https://github.com/Circuitscape/Omniscape.jl, DOI: 10.5281/zenodo.3406711.

Here's a bibtex entry:
```
@misc{landau2020omniscape,
    title = {{Omniscape.jl: An efficient and scalable implementation of the Omniscape algorithm in the Julia scientific computing language}},
    author = {Vincent A. Landau},
    year = {2020},
    version = {v0.2.2},
    url = {https://github.com/Circuitscape/Omniscape.jl},
    doi = {10.5281/zenodo.3406711}
}
```

Please also cite the [original work](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) outlining the Omniscape algorithm:
> McRae, B. H., K. Popper, A. Jones, M. Schindel, S. Buttrick, K. R. Hall, R. S. Unnasch, and J. Platt. 2016. Conserving Nature’s Stage: Mapping Omnidirectional Connectivity for Resilient Terrestrial Landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.
