---
title: 'Omniscape.jl: Software to predict omni-directional landscape connectivity with Julia'
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
 - name: Julia Computing Inc., Cambridge, Massachussetts, United States
   index: 2
 - name: Massachusetts Institute of Technology, Cambridge, Massachussetts, United States
   index: 3
 - name: Then Nature Conservancy, Lansing, Michigan, United States
   index: 4
date: 9 October 2020
bibliography: paper.bib
---

# Summary

Modeling where and how ecological processes are connected in geographic space provides valuable information for widlife and landscape management. A common output from such efforts is a connectivity map, which provides a spatial representation of connectivity by showing likely paths of flow for ecological processes (e.g. wildlife movement or dispersal, gene flow, disease, or fire). Circuit theory offers a useful framework for modeling these processes [@mcrae2006; @mcrae2008; dickson2019]. In the circuit-theoretic approach, the landscape is abstracted as a network of current sources, grounds, and resistors. The resulting current flow through the network is then related to movement or flow intensity of the ecological process of interest. These models are implemented in the Circuitscape software [@shah2008; @anantharaman2020]. @mcrae2016 introduced the Omniscape algorithm, a moving window implementation of Circuitscape, to predict omni-directional landscape connectivity. We implemented this algorithm in the Julia programming language and provide it as an easy-to-use Julia package, Omniscape.jl.

# The Omniscape Algorithm

Omniscape works by applying Circuitscape iteratively through the landscape in a moving window with a user-specified radius. Omniscape requires two basic spatial data inputs: a resistance raster, and a source strength raster. The resistance raster defines the traversal cost for every pixel in the landscape. The source strength raster defines for every pixel the relative amount of current to be injected into that pixel. A diagram of the moving window, adapted and borrowed from @mcrae2006, is shown in \autoref{fig:window}.

![A diagram of the moving window in Omniscape.\label{fig:window}](fig1.png)



# Acknowledments

# References
