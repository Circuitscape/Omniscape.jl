## Inputs
block_size = 6
threshold = 0.5
sources_raw = reshape(rand(15000), 100, 150)
resistance_raw = reshape(rand(15000), 100, 150)
radius = 10
buffer = 15
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

## Calculate targets
targets = get_targets(source_array = sources_raw)

## Initialize cumulative current map
cum_currmap = fill(0., nrows, ncols)

## Initialize Circtuiscape options
#csopts = initialize_csopts()

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

    ## Call circuitscape
    # currmap = calculate_current(source, ground, resistance)

    ## If normalize = True, calculate null map and normalize
    # null_resistance = fill(1, size(resistance))
    # null_currmap = calculate_current(sources, ground, null_resistance)
    # flow_potential = currmap ./ null_currmap

    ## Add current to cumulative map if not in parallel
    # xlower = max(targets[i, 1] - radius - buffer, 1)
    # xupper = max(targets[i, 1] + radius + buffer, 1)
    # ylower = max(targets[i, 2] - radius - buffer, 1)
    # yupper = max(targets[i, 2] + radius + buffer, 1)
    # cum_currmap[xlower:xupper, ylower:yupper] .=
    #     cum_currmap[xlower:xupper, ylower:yupper] .+ currmap

end
