# Examples

## Forest connectivity in central Maryland

Land cover datasets are commonly used to parameterize resistance for connectivity modeling. This example uses the [National Land Cover Dataset](https://www.usgs.gov/centers/eros/science/national-land-cover-database) for the United States to model forest connectivity in central Maryland. Each value in the categorical land cover dataset is assigned a resistance score. We can have Omniscape.jl can assign these values internally by providing a reclassification table (see [Resistance Reclassification](@ref)).

First, install the necessary packages and import them:

```julia
using Pkg; Pkg.add(["Omniscape", "GeoData", "Plots"])
using Omniscape, GeoData, Plots
```

Next, download the landcover data we'll use in this example:

```julia
url_base = "https://raw.githubusercontent.com/Circuitscape/datasets/main/"
# Download the NLCD tile used to create the resistance surface and load it
download(string(url_base, "data/nlcd_2016_frederick_md.tif"),
         "nlcd_2016_frederick_md.tif")

# Load the array using one of Omniscape's internal functions, or a function
# from a GIS Julia package of your choice. Omniscape's `read_raster()` returns a
# tuple with the data array, a wkt string containing geographic projection info,
# and an array containing geotransform values.
land_cover, wkt, transform = Omniscape.read_raster("nlcd_2016_frederick_md.tif", Float64)
```

The next step is to create a resistance reclassification table that defines a resistance value for each land cover value. Land cover values go in the left column, and resistance values go in the right column. In this case, we are modeling forest connectivity, so forest classes receive the lowest-possible resistance score of one. Other "natural" land cover types are assigned moderate values, and human-developed land cover types are assigned higher values. Medium- to high-intensity development, are given a value of `missing`, which denotes infinite resistance (absolute barriers to movement).

```julia
# Create the reclassification table used to translate land cover into resistance
reclass_table = [
    11.	100; # Water
    21	500; # Developed, open space
    22	1000; # Developed, low intensity
    23	missing; # Developed, medium intensity
    24	missing; # Developed, high intensity
    31	100; # Barren land
    41	1; # Deciduous forest
    42	1; # Evergreen forest
    43	1; # Mixed forest
    52	20; # Shrub/scrub
    71	30; # Grassland/herbaceous
    81	200; # Pasture/hay
    82	300; # Cultivated crops
    90	20; # Woody wetlands
    95	30; # Emergent herbaceous wetlands
]
```

Next, we define the configuration options for this model run. See the [Arguments](@ref) section in the [User Guide](@ref) for more information each of the configuration options.

```julia
# Specify the configuration options
config = Dict{String, String}(
    "radius" => "100",
    "block_size" => "21",
    "project_name" => "md_nlcd_omniscape_output",
    "source_from_resistance" => "true",
    "r_cutoff" => "1", # Only forest pixels should be sources
    "reclassify_resistance" => "true"
)
```

Finally, run Omniscape, feeding in the configuration dictionary, the resistance array, the reclass table, as well as the wkt and geotransform information loaded above with `Omniscape.read_raster()`. Passing in the wkt and geotransform, along with `true` as the `write_outputs` argument, will allow Omniscape to write the outputs as properly projected rasters.

```julia
output = run_omniscape(config,
                       land_cover_array,
                       reclass_table = reclass_table,
                       wkt = wkt,
                       geotransform = transform,
                       write_outputs = true)
```

You'll see that outputs are written to a new folder called "md_nlcd_omniscape_output". This is specified by the "project_name" value in `config` above. The cumulative current map will always be called "cum_currmap.tif", and it will be located in the output folder.

Now, load the current map back into Julia using [GeoData.jl](https://github.com/rafaqz/GeoData.jl) and plot it:

```julia
current = GDALarray("md_nlcd_omniscape_output")
plot(current,
     title = "Cumulative Current Flow", xlabel = "Easting", ylabel = "Northing",
     seriescolor = cgrad(:inferno, [0, 0.005, 0.03, 0.06, 0.1, 0.15]),
     size = (620, 600))
```

```@raw html
<img src='../figs/nlcd_currmap.png' width=450> <br><em>Cumulative current flow output representing forest connectivity in central Maryland.</em><br><br>
```
