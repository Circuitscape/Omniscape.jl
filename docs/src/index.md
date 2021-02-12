# Omniscape.jl

Package repository: [https://github.com/Circuitscape/Omniscape.jl](https://github.com/Circuitscape/Omniscape.jl)

!!! note

    Before proceeding, it is strongly recommended that you familiarize yourself with the circuit theoretic approach to modeling landscape connectivity. See [McRae 2006](https://circuitscape.org/pubs/McRae_2006_IBR_Evolution.pdf) and [McRae et al. 2008](https://circuitscape.org/pubs/McRae_et_al_2008_Ecology.pdf) to learn more. See [Anantharaman et al. 2020](https://proceedings.juliacon.org/papers/10.21105/jcon.00058) for more on [Circuitscape.jl](https://github.com/Circuitscape/Omniscape.jl).

### Table of Contents

```@contents
Pages = ["index.md", "algorithm.md","usage.md", "examples.md", "apidocs.md"]
Depth = 2
```

## About Omniscape.jl

Omniscape.jl implements the Omniscape connectivity algorithm developed by [McRae et al. (2016)](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest). This software package can be used to produce maps of omni-directional habitat connectivity useful for scientific research as well as landscape management and conservation. Omniscape.jl is built on [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl). It offers a unique approach to connectivity modeling, particularly among circuit theoretic methods, by allowing the sources, destinations, and intensity of animal movement or ecological flow (modeled as electrical current) to be informed by continuous spatial data (such as a habitat suitability map). This information is combined with other spatial information on landscape resistance to movement or flow to produce models of habitat connectivity. To learn about how the algorithm works, see [The Omniscape Algorithm](@ref). Check out the [Examples](@ref) section for a step-by-step demonstration of how to use Omniscape.jl.

### Outputs

Omniscape.jl provides three different outputs.
1. **Cumulative current flow**: the total current flowing through the landscape -- the result of the Omniscape algorithm described above.
2. **Flow potential** (optional): current flow under "null" resistance conditions. Flow potential demonstrates what movement/flow would look like when movement is unconstrained by resistance and barriers. Flow potential is calculated exactly as cumulative current flow is, but with resistance set to 1 for the entire landscape.
3. **Normalized current flow** (optional): calculated as cumulative current flow divided by flow potential. Normalized current helps identify areas where current is impeded or channelized (e.g. more or less current than expected under null resistance conditions). High values mean current flow is channelized, low values mean current is impeded.

### Climate Connectivity

Climate connectivity can be modeled using the conditional connectivity options in Omniscape. These options options allow the user to impose extra constraints on source and target identification and matching. For example the present day climate of the source pixels might be required to be similar to the projected future climate for the target pixel. Info on constraints is provided to Omniscape via raster layers. See the documentation on [Conditional Connectivity Options](@ref) for more info on how to implement this feature.

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

Be sure to also cite the [original work](https://www.researchgate.net/publication/304842896_Conserving_Nature's_Stage_Mapping_Omnidirectional_Connectivity_for_Resilient_Terrestrial_Landscapes_in_the_Pacific_Northwest) where the Omniscape algorithm was first described:
> McRae, B. H., K. Popper, A. Jones, M. Schindel, S. Buttrick, K. R. Hall, R. S. Unnasch, and J. Platt. 2016. Conserving Nature’s Stage: Mapping Omnidirectional Connectivity for Resilient Terrestrial Landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.

## Acknowledgments
Development of this software package was made possible by funding from NASA's Ecological Forecasting program and the Wilburforce Foundation through a project led by Kim Hall at The Nature Conservancy. This software package would not have been possible without Brad McRae (1966-2017), the visionary behind Circuitscape, the Omniscape algorithm, and several other software tools for assessing connectivity. Omniscape.jl is built on [Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl), which was authored by Ranjan Anantharaman and Viral Shah, both of whom have been incredibly helpful in steering and guiding the development of Omniscape.jl. Kim Hall, Aaron Jones, Carrie Schloss, Melissa Clark, Jim Platt, and early Omniscape.jl users helped steer software development by providing valuable feedback and insight.


## References

Anantharaman, R., Hall, K., Shah, V., & Edelman, A. (2020). Circuitscape in Julia: Circuitscape in Julia: High Performance Connectivity Modelling to Support Conservation Decisions. *Proceedings of the JuliaCon Conferences*. DOI: 10.21105/jcon.00058.

McRae, B. H. (2006). Isolation by resistance. *Evolution*, 60(8), 1551-1561.

McRae, B. H., Dickson, B. G., Keitt, T. H., & Shah, V. B. (2008). Using circuit theory to model connectivity in ecology, evolution, and conservation. *Ecology*, 89(10), 2712-2724.

McRae, B. H., Popper, K., Jones, A., Schindel, M., Buttrick, S., Hall, K., Unnasch, B. & Platt, J. (2016). Conserving nature’s stage: mapping omnidirectional connectivity for resilient terrestrial landscapes in the Pacific Northwest. *The Nature Conservancy*, Portland, Oregon.
