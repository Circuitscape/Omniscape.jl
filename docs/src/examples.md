# Examples

## Forest connectivity in central Maryland

Land cover datasets are commonly used to parameterize resistance for connectivity modeling. This example uses the [National Land Cover Dataset](https://www.usgs.gov/centers/eros/science/national-land-cover-database) for the United States to model forest connectivity in central Maryland. Each value in the categorical land cover dataset is assigned a resistance score. We can have Omniscape.jl assign these values internally by providing a reclassification table (see [Resistance Reclassification](@ref)).

First, install the necessary packages and import them:

```julia
using Pkg; Pkg.add(["Omniscape", "GeoData", "Plots"])
using Omniscape, GeoData, Plots
```
```@setup mdforest
using Pkg; Pkg.add(["Omniscape", "GeoData", "Plots"])
using Omniscape, GeoData, Plots
url_base = "https://raw.githubusercontent.com/Circuitscape/datasets/main/"
download(string(url_base, "data/nlcd_2016_frederick_md.tif"),
         "nlcd_2016_frederick_md.tif")
nothing
```

Next, download the landcover data we'll use in this example, and plot it:

```julia
url_base = "https://raw.githubusercontent.com/Circuitscape/datasets/main/"
# Download the NLCD tile used to create the resistance surface and load it
download(string(url_base, "data/nlcd_2016_frederick_md.tif"),
         "nlcd_2016_frederick_md.tif")

# Plot the landcover data
values = [11, 21, 22, 23, 24, 31, 41, 42, 43, 52, 71, 81, 82, 90, 95]
palette = ["#476BA0", "#DDC9C9", "#D89382", "#ED0000", "#AA0000",
           "#b2b2b2", "#68AA63", "#1C6330", "#B5C98E", "#CCBA7C",
           "#E2E2C1", "#DBD83D", "#AA7028", "#BAD8EA", "#70A3BA"]

plot(GeoArray(GDALarray("nlcd_2016_frederick_md.tif")),
     title = "Land Cover Type", xlabel = "Easting", ylabel = "Northing",
     seriescolor = cgrad(palette, (values .- 12) ./ 84, categorical = true),
     size = (700, 640))
```
```@raw html
<img src='../figs/mdlc.png' width=500><br>
```

Now, load the array using Omniscape's internal `read_raster()` function or a function from a GIS Julia package of your choice. `read_raster()` returns a tuple with the data array, a wkt string containing geographic projection info, and an array containing geotransform values. We'll use the wkt and geotransform later.

```@example mdforest
land_cover, wkt, transform = Omniscape.read_raster("nlcd_2016_frederick_md.tif", Float64)
```

The next step is to create a resistance reclassification table that defines a resistance value for each land cover value. Land cover values go in the left column, and resistance values go in the right column. In this case, we are modeling forest connectivity, so forest classes receive the lowest resistance score of one. Other "natural" land cover types are assigned moderate values, and human-developed land cover types are assigned higher values. Medium- to high-intensity development are given a value of `missing`, which denotes infinite resistance (absolute barriers to movement).

```@example mdforest
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

Next, we define the configuration options for this model run. See the [Arguments](@ref) section in the [User Guide](@ref) for more information about each of the configuration options.

```@example mdforest
# Specify the configuration options
config = Dict{String, String}(
    "radius" => "100",
    "block_size" => "21",
    "project_name" => "md_nlcd_omniscape_output",
    "source_from_resistance" => "true",
    "r_cutoff" => "1", # Only forest pixels should be sources
    "reclassify_resistance" => "true",
    "calc_normalized_current" => "true",
    "calc_flow_potential" => "true"
)
```

Finally, compute connectivity using `run_omniscape()`, feeding in the configuration dictionary, the resistance array, the reclass table, as well as the wkt and geotransform information loaded earlier. Passing in the wkt and geotransform, along with `true` for the `write_outputs` argument, will allow Omniscape to write the outputs as properly projected rasters. `run_omniscape` will print some information to the console and show progress, along with an ETA, in the form of a progress bar.

```@example mdforest
currmap, flow_pot, norm_current = run_omniscape(config,
                                                land_cover,
                                                reclass_table = reclass_table,
                                                wkt = wkt,
                                                geotransform = transform,
                                                write_outputs = true)
```

You'll see that outputs are written to a new folder called "md\_nlcd\_omniscape\_output". This is specified by the "project\_name" value in `config` above. The cumulative current map will always be called "cum\_currmap.tif", and it will be located in the output folder. We also specified in the run configuration that flow potential and normalized current should be computed as well. These are called "potential\_potential.tif" and "normalized\_cum\_currmap.tif", respectively. See [Outputs](@ref) for a description of each of these outputs.

Now, plot the outputs. Load the outputs into Julia as spatial data and plot them.

First, the cumulative current map:

```julia
current = GDALarray("md_nlcd_omniscape_output/cum_currmap.tif")
plot(current,
     title = "Cumulative Current Flow", xlabel = "Easting", ylabel = "Northing",
     seriescolor = cgrad(:inferno, [0, 0.005, 0.03, 0.06, 0.09, 0.14]),
     size = (600, 550))
```
```@raw html
<img src='../figs/md-curmap.png' width=500> <br><em>Cumulative current flow representing forest connectivity. Note that areas in white correspond to built up areas (NLCD values of 23 and 24) that act as absolute barriers to movement.</em><br><br>
```

Next, flow potential. This map shows what connectivity looks like under "null" conditions (resistance equals 1 for the whole landscape).

```julia
fp = GDALarray("md_nlcd_omniscape_output/flow_potential.tif")
plot(fp,
     title = "Flow Potential", xlabel = "Easting", ylabel = "Northing",
     seriescolor = cgrad(:inferno, [0, 0.005, 0.03, 0.06, 0.09, 0.14]),
     size = (700, 640))
```
```@raw html
<img src='../figs/md-fp.png' width=500> <br><em>Flow potential, which shows what connecitivty would look like in the absence of barriers to movement.</em><br><br>
```

Finally, map normalized current flow, which is calculated as flow potential divided by cumulative current.

```julia
normalized_current = GDALarray("md_nlcd_omniscape_output/normalized_cum_currmap.tif")
plot(normalized_current,
     title = "Normalized Current Flow", xlabel = "Easting", ylabel = "Northing",
     seriescolor = cgrad(:inferno, [0, 0.005, 0.03, 0.06, 0.09, 0.14]),
     size = (700, 640))
```
```@raw html
<img src='../figs/md-fp.png' width=500> <br><em>Normalized cumulative current. Values greater than one indicate areas with channelized/bottlenecked flow. Values around 1 (cumulative current ≈ flow potential) indicate diffuse current. Values less than 1 indicate impeded flow.</em><br><br>
```
