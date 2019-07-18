abstract type Data end

clip = function(A::Array{Float64, 2}; x::Int64, y::Int64, distance::Int64)
    dim1 = size(A)[1]
    dim2 = size(A)[2]

    dist = [sqrt((i - x)^2 + (j - y)^2) for i = 1:dim1, j = 1:dim2]

    clipped = deepcopy(A)
    clipped[dist .> distance] .= -9999

    clipped
end


function get_targets(source_array::Array{Float64, 2}, arguments::Dict{String, Int64}; threshold::Float64)
    block_size = arguments["block_size"]
    block_radius = arguments["block_radius"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    source_array[source_array .< threshold] .= 0

    start = (block_size + 1) / 2

    xs = [start:block_radius:nrows;]
    ys = [start:block_radius:ncols;]

    ground_points = zeros(Float64,(length(xs)*length(ys), 2))

    let
        c = 1
        for i = 1:length(xs)
            for j = 1:length(ys)
                ground_points[c, 1] = xs[i]
                ground_points[c, 2] = ys[j]
                c += 1
            end
        end
    end

    ground_points = cat(ground_points,
                        zeros(size(ground_points)[1], 1);
                        dims = 2
                    )

    for i = 1:size(ground_points)[1]
        xlower = Int64(ground_points[i, 1] - block_radius)
        xupper = min(Int64(ground_points[i, 1] + block_radius), nrows)
        ylower = Int64(ground_points[i, 2] - block_radius)
        yupper = min(Int64(ground_points[i, 2] + block_radius), ncols)

        ground_points[i, 3] = sum(source_array[xlower:xupper, ylower:yupper])
    end

    targets = ground_points[ground_points[:,3] .> 0, 1:3]
    targets
end

# x and y defined by targets object. Ultimately the for loop will be done by
# iterating through rows of targets object
function get_source(source_array::Array{Float64, 2}, arguments::Dict{String, Int64}; x::Int64, y::Int64, strength::Float64)
    block_radius = arguments["block_radius"]
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    source_subset = clip(source_array,
                         x = x,
                         y = y,
                         distance = radius)

    # Set any sources inside target to NoData
    xlower = x - block_radius
    xupper = min(x + block_radius, nrows)
    ylower = y - block_radius
    yupper = min(y + block_radius, ncols)

    source_subset[xlower:xupper, ylower:yupper] .= -9999.
    source_subset[source_subset .== 0.0] .= -9999.

    # Extract subset for faster solve times
    xlower_buffered = max(x - radius - buffer, 1)
    xupper_buffered = min(x + radius + buffer, ncols)
    ylower_buffered = max(y - radius - buffer, 1)
    yupper_buffered = min(y + radius + buffer, nrows)

    source_subset = source_subset[xlower_buffered:xupper_buffered,
                                  ylower_buffered:yupper_buffered]

    # allocate total current equal to target "strength", divide among sources
    # according to their source strengths
    source_sum = sum(source_subset[source_subset .> 0])
    source_subset[source_subset .> 0] .=
        (source_subset[source_subset .> 0] * strength) / source_sum

    source_subset
end

function get_ground(arguments::Dict{String, Int64},; x::Int64, y::Int64)
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    xlower_buffered = Int64(max(x - radius - buffer, 1))
    xupper_buffered = Int64(min(x + radius + buffer, ncols))
    ylower_buffered = Int64(max(y - radius - buffer, 1))
    yupper_buffered = Int64(min(y + radius + buffer, nrows))

    ground = fill(0.0,
                  nrows,
                  ncols)
    ground[x, y] = Inf

    output = ground[xlower_buffered:xupper_buffered,
                    ylower_buffered:yupper_buffered]
    output
end

function get_resistance(raw_resistance::Array{Float64, 2}, arguments::Dict{String, Int64},; x::Int64, y::Int64)
    radius = arguments["radius"]
    buffer = arguments["buffer"]
    nrows = arguments["nrows"]
    ncols = arguments["ncols"]

    xlower_buffered = Int64(max(x - radius - buffer, 1))
    xupper_buffered = Int64(min(x + radius + buffer, ncols))
    ylower_buffered = Int64(max(y - radius - buffer, 1))
    yupper_buffered = Int64(min(y + radius + buffer, nrows))
    resistance_clipped = clip(raw_resistance,
                              x = x,
                              y = y,
                              distance = radius + buffer)

    resistance = resistance_clipped[xlower_buffered:xupper_buffered,
                                ylower_buffered:yupper_buffered]
end


function calculate_current(resistance, source, ground, solver, flags, cs_cfg)
    T = Float64
    V = Int64

    # get raster data
    cellmap = resistance
    polymap = Matrix{V}(undef,0,0)
    source_map = source
    ground_map = ground
    points_rc = (V[], V[], V[])
    strengths = Matrix{T}(undef, 0,0)
    included_pairs = Circuitscape.IncludeExcludePairs(:undef, V[], Matrix{V}(undef,0,0))
    hbmeta = Circuitscape.RasterMeta(size(cellmap)[2], size(cellmap)[1], 0., 0., 1., -9999., 0)

    rasterdata = Circuitscape.RasData(cellmap, polymap, source_map, ground_map, points_rc,
                    strengths, included_pairs, hbmeta)

    # Generate advanced
    data = Circuitscape.compute_advanced_data(rasterdata, flags)

    G = data.G
    nodemap = data.nodemap
    polymap = data.polymap
    hbmeta = data.hbmeta
    sources = data.sources
    grounds = data.grounds
    finitegrounds = data.finite_grounds
    cc = data.cc
    src = data.src
    check_node = data.check_node
    source_map = data.source_map # Need it for one to all mode
    cellmap = data.cellmap

    # Flags
    is_raster = flags.is_raster
    is_alltoone = flags.is_alltoone
    is_onetoall = flags.is_onetoall
    write_v_maps = flags.outputflags.write_volt_maps
    write_c_maps = flags.outputflags.write_cur_maps
    write_cum_cur_map_only = flags.outputflags.write_cum_cur_map_only

    volt = zeros(eltype(G), size(nodemap))
    ind = findall(x->x!=0,nodemap)
    f_local = Vector{eltype(G)}()
    solver_called = false
    voltages = Vector{eltype(G)}()
    outvolt = Circuitscape.alloc_map(hbmeta)
    outcurr = Circuitscape.alloc_map(hbmeta)

    for c in cc
        if check_node != -1 && !(check_node in c)
            continue
        end

        # a_local = laplacian(G[c, c])
        a_local = G[c,c]
        s_local = sources[c]
        g_local = grounds[c]

        if sum(s_local) == 0 || sum(g_local) == 0
            continue
        end

        if finitegrounds != [-9999.]
            f_local = finitegrounds[c]
        else
            f_local = finitegrounds
        end

        voltages = Circuitscape.multiple_solver(cs_cfg, a_local, s_local, g_local, f_local)
        local_nodemap = Circuitscape.construct_local_node_map(nodemap, c, polymap)
        solver_called = true

        Circuitscape.accum_currents!(outcurr, voltages, cs_cfg, a_local, voltages,
                        f_local, local_nodemap, hbmeta)
    end

    outcurr
end

function myaddprocs(n)
    addprocs(n)
    @everywhere Core.eval(Main, :(using Omniscape))
end

function solve_target!(i)
    ## get source
    println("Solving target $(i) of $(n_targets)")
    x_coord = Int64(targets[i, 1])
    y_coord = Int64(targets[i, 2])
    source = get_source(sources_raw,
                        int_arguments,
                        x = x_coord,
                        y = y_coord,
                        strength = float(targets[i, 3]))

    ## get ground
    ground = get_ground(int_arguments,
                        x = x_coord,
                        y = y_coord)

    ## get resistance
    resistance = get_resistance(resistance_raw,
                                int_arguments,
                                x = x_coord,
                                y = y_coord)

    grid_size = size(source)
    n_cells = prod(grid_size)

    solver = "cg+amg"

    # if n_cells <= 2000000
    #     solver = "cholmod" # FIXME: "cholmod" not available in advanced mode
    # end

    flags = Circuitscape.RasterFlags(true, false, true,
                                     false, false,
                                     false, Symbol("keepall"),
                                     false, false, solver, o)

    ## Run circuitscape
    curr = calculate_current(resistance, source, ground, solver, flags, cs_cfg)

    ## If normalize = True, calculate null map and normalize
    if calc_flow_potential == true
        null_resistance = fill(1., grid_size)
        flow_potential = calculate_current(null_resistance, source, ground, solver, flags, cs_cfg)
    end

    ## Accumulate values
    xlower = max(x_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    xupper = min(x_coord + int_arguments["radius"] + int_arguments["buffer"],  int_arguments["ncols"])
    ylower = max(y_coord - int_arguments["radius"] - int_arguments["buffer"], 1)
    yupper = min(y_coord + int_arguments["radius"] + int_arguments["buffer"],  int_arguments["nrows"])

    cum_currmap[xlower:xupper, ylower:yupper] .=
        cum_currmap[xlower:xupper, ylower:yupper] .+ curr

    if calc_flow_potential == true
        fp_cum_currmap[xlower:xupper, ylower:yupper] .=
            fp_cum_currmap[xlower:xupper, ylower:yupper] .+ flow_potential
    end
end