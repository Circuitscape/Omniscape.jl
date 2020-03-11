# Usage

## Running Omniscape

To use Omniscape, simply run the following Julia code after Omniscape.jl has been installed.

```julia
using Omniscape
run_omniscape("path/to/config/file.ini")
```

file.ini is a file specifying input data paths and options for Omniscape. See [this link](https://github.com/Circuitscape/Omniscape.jl/blob/master/test/input/config4.ini) for an example `.ini` file. The arguments specified in the .ini file are described in detail below.

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

#### `resistance_file_is_conductance`
One of true, false. Specify whether the file specified by `resistance_file` is a conductance (rather than resistance) surface. Conductance is the inverse of resistance. Note that `r_cutoff` (an optional argument described below) must be in units of resistance even if a conductance file is supplied as input. Defaults to false.

#### `source_file`
The path to the source layer input. The source layer must also be in ASCII raster format, and all values must be ``\geq 0``. This raster must have an identical number of rows, columns, lower left corner coordinates, and cellsize as the resistance layer.

#### `radius`
A positive integer specifying the radius *in pixels* of the moving window used to identify sources to connect to each target.

#### `buffer`
A positive integer specifying an additional buffer distance beyond `radius` to clip the resistance and source layers to for each moving window iteration. If 0, resistance and source layers will be clipped to a circle of size `radius` for each moving window iteration. Defaults to 0.

#### `block_size`
An odd, positive integer specifying the side length for source layer blocking in target generation. Defaults to 1.

#### `source_threshold`
Defaults to 0. The minimum value that a pixel must be in the source layer to be included as a source.

#### `project_name`
The name of the project to use. This string will be appended as a prefix to all output files.

#### `calc_flow_potential`
One of true, false. Specify whether to calculate flow potential. Defaults to true.

### `mask_nodata`
One of true, false. Specify whether to mask current flow outputs according to NoData values in resistance surface. (i.e. pixels in current flow outputs that line up with NoData values in resistance are set to no data if `mask_nodata` = true). Defaults to true.

#### `write_raw_currmap`
One of true, false. Specify whether to save the raw current map (prior to normalization by flow potential) as output. Defaults to true.

#### `write_normalized_currmap`
One of true, false. Specify whether to save the normalized current map as output. Normalized current is calculated as raw current divided by flow potential. Defaults to true.

#### `write_flow_potential`
One of true, false. Specify whether to save the raw flow potential map as output. Defaults to true.

#### `parallelize`
One of true, false. Specify whether to use parallel processing. Defaults to true.

#### `parallel_batch_size`
The batch size (number of jobs) to send to each parallel worker. Particularly in cases where single solves are very fast, setting this to a larger number can reduce I/O overhead when scheduling/sending jobs to parallel workers. If set too high, then you will not be fully utilizing parallel workers. Defaults to 10.

#### `correct_artifacts`
One of true, false. Specify if artifacts introduced from using `block_size` greater than 1 should be corrected. Defaults to true.

#### `source_from_resistance`
One of true, false. Should a source layer be derived using the resistance layer? If true, sources are calculated as the inverse of the resistance layer, and therefore it is not recommended that your resistance layer contain values less than 1. Sources will be set to 0 for all cells with a resistance greater than `r_cutoff`. Defaults to false.

#### `r_cutoff`
The maximum resistance value a cell can have to be considered as a source. Only applies when `source_from_resistance` = true.

#### Conditional connectivity options
#### `conditional`
One of true, false. Should conditional source/target matching be uses? That is, should a given target only be connected to sources that are meet similarity conditions to the target? Defaults to false. If true, then gridded data with values for each pixel are used to compare targets and sources and determine which pairs should be connected according to user-specified criteria.
#### `n_conditions`
The number of conditions that must be met for conditional source/target matching. One of 1, 2. Only applies if `conditional` = true. Defaults to 1.
#### `comparison1`
One of within or equal. Only applies of `conditional`= true. How should conditions be compared when determining whether to connect a source/target pair. If within, then the value of condition 1 for the source must be within the following range, where target is the value at the target pixel or block: (target + `condition1_lower`, target + `condition1_upper`).  `condition1_lower` and `condition1_upper` are explained further below. If equal, then the value at the source pixel must be equal to the value at the target pixel. Defaults to within.
#### `comparison2`
One of within or equal.  Only applies of `conditional`= true and `n_conditions` = 2. How should conditions be compared when determining whether to connect a source/target pair. If within, then the value of condition 2 for the source must be within the following range, where target is the value at the target pixel or block: (target + `condition2_lower`, target + `condition2_upper`).  `condition2_lower` and `condition2_upper` are explained further below. If equal, then the value at the source pixel must be equal to the value at the target pixel. Defaults to within.
#### `condition1_lower`
Number. Only applies if `comparison1` = within. The maximum negative deviation that a potential source's condition 1 value may be from the corresponding value in the target in order to be connected. If `condition1_lower` = -1, then a source may have a condition 1 value up to 1 unit smaller than the target's value and it will still be connected.
#### `condition1_upper`
Number. Only applies if `comparison1` = within. The maximum positive deviation that a potential source's condition 1 value may be from the corresponding value in the target in order to be connected. If `condition1_lower` = 1, then a source may have a condition 1 value up to 1 unit larger than the target's value and it will still be connected.
#### `condition2_lower`
Number. Only applies if `n_conditions` = 2 and `comparison1` = within. The maximum negative deviation that a potential source's condition 2 value may be from the corresponding value in the target in order to be connected. If `condition2_lower` = -1, then a source may have a condition 2 value up to 1 unit smaller than the target's value and it will still be connected.
#### `condition2_upper`
Number. Only applies if `n_conditions` = 2 and `comparison1` = within. The maximum positive deviation that a potential source's condition 2 value may be from the corresponding value in the target in order to be connected. If `condition2_lower` = 1, then a source may have a condition 2 value up to 1 unit larger than the target's value and it will still be connected.
#### `compare_to_future`
One of none, 1, 2, or both. Which condition(s) should compare the future condition in targets with present-day conditions in sources when determining which pairs to connect? For any conditions that are included, two data layers are needed: one with future condition values for all pixels in the study area, and one for present day condition values for all pixels in the study area.
#### `condition1_present_file`
The file path to the data representing condition one in present day. Only needed if `conditional` = true. The source layer must be in ASCII raster format. This raster must have an identical number of rows and columns, lower left corner coordinates, and cellsize as the resistance layer.
#### `condition1_future_file`
The file path to the data representing condition one in the future. Only needed if `conditional` = true and `compare_to_future` = 1 or `compare_to_future` = both. The source layer must be in ASCII raster format. This raster must have an identical number of rows and columns, lower left corner coordinates, and cellsize as the resistance layer.
#### `condition2_present_file`
The file path to the data representing condition two in present day. Only needed if `conditional` = true and `n_conditions` = 2. The source layer must be in ASCII raster format. This raster must have an identical number of rows and columns, lower left corner coordinates, and cellsize as the resistance layer.
#### `condition2_future_file`
The file path to the data representing condition two in the future. Only needed if `conditional` = true and `n_conditions` = 2 *and* `compare_to_future` = 2 or `compare_to_future` = both. The source layer must be in ASCII raster format. This raster must have an identical number of rows and columns, lower left corner coordinates, and cellsize as the resistance layer.