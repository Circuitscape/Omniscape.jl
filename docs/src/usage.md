# Usage

## Running Omniscape

To use Omniscape, simply run the following Julia code after Omniscape.jl has been installed.

```julia
using Omniscape
run_omniscape("path/to/config/file.ini")
```

file.ini is a file specifying input data paths and options for Omniscape. See [this link](https://github.com/Circuitscape/Omniscape.jl/blob/master/test/input/config.ini) for an example `.ini` file. The arguments specified in the .ini file are described in detail below.

#### Parallel Processing

Omniscape uses parallel processing by default, but currently, Julia requires that the number of parallel threads to use be specified outside of via an environment variable called `JULIA_NUM_THREADS`. This environment variable needs to be defined prior to launching Julia from the terminal.

**Example to set up Julia with 4 threads**:
On Linux/Mac:
```bash
export JULIA_NUM_THREADS=4
julia
```
On Windows:
```bash
set JULIA_NUM_THREADS=4
julia
```

## Arguments

#### `resistance_file`
The path to the resistance layer input. Currently, the resistance surface must be in ASCII raster format with the following header format:
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
The path to the source layer input. The source layer must also be in ASCII raster format, and all values must be ``\geq 0``. This raster must have an identical number of rows, columns, lower left corner coordinates, and cellsize as the resistance layer.

#### `radius`
A positive integer specifying the radius *in pixels* of the moving window used to identify sources to connect to each target.

#### `buffer`
Defaults to 0. A positive integer specifying an additional buffer distance beyond `radius` to clip the resistance and source layers to for each moving window iteration. If 0, resistance and source layers will be clipped the a circle of size `radius` for each moving window iteration.

#### `block_size`
An odd, positive integer specifying the side length for source layer blocking in target generation. Defaults to 1.

#### `source_threshold`
Defaults to 0. The minimum value that a pixel must be in the source layer to be included as a source.

#### `project_name`
The name of the project to use. This string will be appended as a prefix to all output files.

#### `calc_flow_potential`
One of true, false. Specify whether to calculate flow potential. Defaults to true.

#### `write_raw_currmap`
One of true, false. Specify whether to save the raw current map (prior to normailization by flow potential) as output. Defaults to true.

#### `write_normalized_currmap`
One of true, false. Specify whether to save the normalized current map as output. Normalized current is calculated as raw current divided by flow potential. Defaults to true.

#### `write_flow_potential`
One of true, false. Specify whether to save the raw flow potential map as output. Defaults to true.

#### `parallelize`
One of true, false. Specify whether to use parallel processing. Defaults to true.

#### `correct_artifacts`
One of true, false. Specify if artifacts introduced from using `block_size` greater than 1 should be corrected. Defaults to true.

#### `source_from_resistance`
One of true, false. Should a source layer be derived using the resistance layer? If true, sources are calculated as the inverse of the resistance layer, and therefore it is not recommended that your resistance layer contain values less than 1. Sources will be set to 0 for all cells with a resistance greater than `r_cutoff`. Defaults to false.

#### `r_cutoff`
The maximum resistance value a cell can have to be considered as a source. Only applies when `source_from_resistance` = true.