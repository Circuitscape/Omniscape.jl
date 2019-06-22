using Circuitscape
## Inputs
block_size = 6
threshold = 0.5
sources_raw = reshape(rand(15000), 100, 150)
resistance_raw = reshape(rand(15000), 100, 150)
radius = 10 # in number of pixels
buffer = 15 # in number of pixels
project_name = "test"
## end inputs

## Derived variables
if iseven(block_size)
    @warn "Block_size is even, but must be odd. Using block_size + 1."
    block_size = block_size + 1
end
nrows = size(sources_raw, 1)
ncols = size(sources_raw, 2)
block_radius = (block_size - 1) / 2
## end dervied variables

## Include needed functions
include("functions.jl")
include("config.jl")
include("io.jl")

## Setup Circuitscape configurations
cs_cfg_dict = init_csdict()
cfg = Circuitscape.init_config()
Circuitscape.update!(cfg, cs_cfg_dict)

## Calculate targets
targets = get_targets(source_array = sources_raw)

## Initialize cumulative current map
cum_currmap = fill(0., nrows, ncols)

## Initialize temporary ascii header for CS advanced mode
temp_header = init_temp_ascii_header()

## Circuitscape calls in loop over targets
for i = 1:size(targets, 1)
    ## get source
    source = get_source(source_array = sources_raw,
                        x = targets[i, 1],
                        y = targets[i, 2],
                        strength = targets[i, 3])

    ## get ground
    ground = get_ground(x = targets[i, 1],
                        y = targets[i, 2])

    ## get resistance
    resistance = clip(resistance_raw,
                 x_coord = targets[i, 1],
                 y_coord = targets[i, 2],
                 distance = radius + buffer)
    grid_size = size(source)
    n_cells = prod(grid_size)

    if n_cells <= 2000000
        cfg["solver"] = "cholmod"
    end

    ## Update temp ascii header
    update_ascii_header!(source, temp_header)

    ## Write source, ground, and resistance asciis
    write_ascii(source, temp_header; type = "source")
    write_ascii(ground, temp_header; type = "ground")
    write_ascii(resistance, temp_header; type = "resistance")

    ## Run circuitscape
    curr = calculate_current(cfg)

    rm("scratch/temp_resistance.asc")
    ## If normalize = True, calculate null map and normalize
    if normalize == true
        null_resistance = fill(1, grid_size)
        write_ascii(null_resistance, temp_header; type = "resistance")

        flow_potential = calculate_current(cfg)
        curr .= curr ./ flow_potential # TODO: is each window normalized or is normalization done in one step at the end
    end

    # flow_potential = currmap ./ null_currmap
    rm("scratch/temp_source.asc")
    rm("scratch/temp_ground.asc")
    ## Add current to cumulative map if not in parallel
    xlower = max(targets[i, 1] - radius - buffer, 1)
    xupper = max(targets[i, 1] + radius + buffer, 1)
    ylower = max(targets[i, 2] - radius - buffer, 1)
    yupper = max(targets[i, 2] + radius + buffer, 1)
    cum_currmap[xlower:xupper, ylower:yupper] .=
        cum_currmap[xlower:xupper, ylower:yupper] .+ curr

end
