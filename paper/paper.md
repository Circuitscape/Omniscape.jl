---
title: 'Omniscape.jl: Software to compute omnidirectional landscape connectivity'
tags:
  - julia
  - ecology
  - circuit theory
  - habitat connectivity
  - omniscape
  - circuitscape
authors:
  - name: Vincent A. Landau
    orcid: 0000-0001-9290-9438
    affiliation: 1
  - name: Viral B. Shah
    orcid: 0000-0001-9602-4012
    affiliation: 2
  - name: Ranjan Anantharaman
    ordic: 0000-0002-4409-3937
    affiliation: 3
  - name: Kimberly R. Hall
    orcid: 0000-0002-7802-3558
    affiliation: 4
affiliations:
 - name: Conservation Science Partners, Inc., Fort Collins, Colorado, United States
   index: 1
 - name: Julia Computing Inc., Cambridge, Massachusetts, United States
   index: 2
 - name: Massachusetts Institute of Technology, Cambridge, Massachusetts, United States
   index: 3
 - name: The Nature Conservancy, Lansing, Michigan, United States
   index: 4
date: 9 October 2020
bibliography: paper.bib
---

# Summary

Omniscape.jl is a software package that implements the Omniscape algorithm [@mcrae2016] to compute landscape connectivity. It is written in the Julia programming language [@bezanson2017] to be fast, scalable, and easy-to-use. Circuitscape.jl [@anantharaman2020], the package on which Omniscape.jl builds and expands, abstracts landscapes as two-dimensional electrical networks and solves for current flow. The current flow that results represents landscape connectivity. Omniscape.jl is novel in that it produces maps of "omni-directional" connectivity, which provide a spatial representation of connectivity between every possible pair of start and endpoints in the landscape. These maps can be used by researchers and landscape managers to understand and predict how ecological processes (e.g., animal movement, disease transmission, gene flow, and fire behavior) are likely to manifest in geographic space. Omniscape.jl makes use of Julia's native multi-threading, making it readily scalable and deployable to high performance compute nodes. More information on the broader Circuitscape project, which is home to Circuitscape.jl and Omniscape.jl, can be found at [circuitscape.org](https://circuitscape.org).

# Motivation

Modeling where and how ecological processes are connected provides valuable information for landscape management and researchers. A common output from connectivity modeling efforts is a map that provides a spatial representation of connectivity by showing likely paths of flow for ecological processes. A common method for identifying flow or movement corridors uses graph-theory to identify least-cost paths [@bunn2000]. The circuit-theoretic approach to connectivity modeling was a more recent innovation, and it has been gaining popularity over the past decade [@mcrae2006; @mcrae2008; @dickson2019]. In the circuit-theoretic approach, the landscape is abstracted as a network of current sources, grounds, and resistors. The resulting current flow through the electrical network is then related to the movement or flow intensity of the ecological process of interest. These models were first implemented in the Circuitscape software package [@shah2008], which was recently updated and rewritten as Circuitscape.jl [@anantharaman2020] in the Julia programming language. 

Circuitscape.jl is most often run in "pairwise" mode, where current flow is calculated between pairs of user-defined "cores," which are usually habitat patches. Results from this method can be highly sensitive to the location of cores. This can be problematic in cases where core location is arbitrary, or when there is uncertainty about where cores should be placed. The Omniscape algorithm [@mcrae2016] offers an alternative, "coreless" approach to pairwise Circuitscape.jl and computes omni-directional landscape connectivity by implementing Circuitscape.jl iteratively in a moving window. By precluding the need to identify and delineate discrete cores, the Omniscape algorithm also allows for a more detailed evaluation of connectivity within natural areas that may otherwise be defined as cores in Circuitscape. Code for Python was developed to implement the Omniscape algorithm in @mcrae2016, but a user-friendly software package was not available. To fill this need, we developed Omniscape.jl, an easy-to-use software package written in Julia. Omniscape.jl is useful for modeling connectivity in landscapes that do not have discrete cores, for example landscapes that are a combination of natural, semi-natural, and human-modified lands, or in cases where understanding connectivity within natural areas is of interest.

# The Omniscape Algorithm

Omniscape.jl works by applying Circuitscape.jl iteratively through the landscape in a circular moving window with a user-specified radius (\autoref{fig:window}). Omniscape.jl requires two basic spatial data inputs: a resistance raster, and a source strength raster. The resistance raster defines the traversal cost (measured in ohms) for every pixel in the landscape, that is, the relative cost for the ecological process of interest to move through each pixel. The source strength raster defines for every pixel the relative amount of current (measured in amperes) to be injected into that pixel. In the case of modeling animal movement, a pixel with a high source strength corresponds to relatively more individuals originating from that pixel.

![A diagram of the moving window used in Omniscape.jl, adapted with permission from @mcrae2016.\label{fig:window}](fig1.png)

The algorithm works as follows:

1. The circular window centers on a pixel in the source strength surface that has a source strength greater than 0 (or a user-specified threshold). This is referred to as the target pixel.
2. The source strength and resistance rasters are clipped to the circular window centered on the target pixel.
3. Every source strength pixel within the search radius that also has a source strength greater than 0 is identified. These are referred to as the source pixels.
4. Circuitscape.jl is run using the clipped resistance raster in “advanced" mode, where the target pixel is set to ground, and the source pixels are set as current sources. The total amount of current injected is equal to the source strength of the target pixel, and is divvied up among the source pixels in proportion to their source strengths.

Steps 1-4 are repeated for every potential target pixel. The resulting current maps from each moving window iteration are summed to get a final map of cumulative current flow. Individual moving window iterations can be run independently. Omniscape.jl makes use of Julia's multi-threaded parallel processing to solve individual moving windows in parallel.

In addition to cumulative current, Omniscape.jl also optionally provides two additional outputs: flow potential, and normalized cumulative current (\autoref{fig:outputs}). Flow potential represents current flow under "null" resistance conditions and demonstrates what current flow would look like when unconstrained by resistance and barriers. Flow potential is calculated exactly as cumulative current flow, but with resistance set to one for the entire landscape. Normalized cumulative current flow is calculated by dividing cumulative current flow by flow potential. Normalized current helps identify areas where current is impeded or channelized (e.g., more or less current than expected under null resistance conditions). High values mean current flow is channelized, and low values mean current is impeded.

![An example of the three different Omniscape.jl outputs. Outputs are from the "Maryland Forest Connectivity" example in the software documentation. Cumulative current flow shows the total current for each landscape pixel. Flow potential shows predicted current under resistance-free conditions. Normalized current shows the degree to which a pixel has more or less current than expected under resistance-free conditions (cumulative current flow divided by flow potential). Each layer is visualized using a quantile stretch with 30 breaks. Axes show easting and northing coordinates for reference.\label{outputs}](fig2.png)

# Usage

Omniscape.jl is run from the Julia REPL. It offers a single user-facing function, `run_omniscape`, which has two methods. The first method accepts a single argument specifying the path to an [INI file](https://en.wikipedia.org/wiki/INI_file) that contains input data file paths and run options. Spatial data inputs can be in either ASCII or GeoTIFF raster formats, and outputs can also be written in either format. The second method of `run_omniscape` accepts arrays representing resistance and other spatial data inputs, and a dictionary of arguments specifying algorithm options. A complete user guide for Omniscape.jl, including installation instructions, function documentation, examples, and a complete list of options and their defaults, can be found in the [Omniscape.jl documentation](https://docs.circuitscape.org/Omniscape.jl/latest/).


# Acknowledgments
Development of this software package was made possible by funding from NASA's Ecological Forecasting program (grant NNX17AF58G) and the Wilburforce Foundation. This software package would not have been possible without Brad McRae (1966-2017), the visionary behind Circuitscape, the Omniscape algorithm, and several other software tools for assessing connectivity. Aaron Jones developed the diagram in \autoref{fig:window}. Aaron Jones, Carrie Schloss, Melissa Clark, Jim Platt, and early Omniscape.jl users helped steer software development by providing valuable feedback and insight.

# References
