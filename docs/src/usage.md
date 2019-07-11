# Usage

To use Omniscape, simply run the following code after Omniscape.jl has be installed.

```julia
julia> using Omniscape
julia> run_omniscape("path/to/config/file.ini")
```

file.ini is a file specifying input file paths and options for Omniscape. See [this link](https://github.com/Circuitscape/Omniscape.jl/blob/master/test/input/config.ini) for an example `.ini` file. The arguments specified in the .ini file are described in detail below.

## Arguments

#### `resistance_file`
The path to the resistance layer input. Currently, the resistance surface must be in ASCII raster format with a NoData value of -9999 the following headier format:
```
ncols         30
nrows         30
xllcorner     0
yllcorner     0
cellsize      1
nodata_value  -9999
``` 
This is the format used by both QGIS and ArcMap GIS software.

#### `source_file`
The path to the source layer input. The source layer must also be in ASCII raster format, and all values must be ``\geq 1``. This raster must have an identical number of rows, columns, lower left corner coordinates, and cellsize as the resistance layer.

#### `radius`
A positive integer specifying the radius *in pixels* of the moving window used to identify sources to connect to each target.

#### `buffer`
Optional (default = 0). A positive integer specifying an additional buffer distance beyond `radius`to clip the resistance and source layers to for each moving window iteration. If 0, resistance and source layers will be clipped the a circle of size `radius` for each moving window iteration.

#### `block_size`
An odd, positive integer specifying the side length for source layer blocking in target generation.

#### `source_threshold`
Optional (default = 0), the minimum value that a pixel must be in the source layer to be included as a source.

#### `project_name`
The name of the project to use. This string will be appended as a prefix to all output files.

#### `calc_flow_potential`
One of `true, false`. Specify whether to calculate flow potential.

#### `write_raw_currmap`
One of `true, false`. Specify whether to save the raw current map (prior to normailization by flow potential) as output.

#### `write_normalized_currmap`
One of `true, false`. Specify whether to save the normalized current map as output. Normalized current is calculated as raw current divided by flow potential.

#### `write_flow_potential`
One of `true, false`. Specify whether to save the raw flow potential map as output.