using Test, Omniscape, Circuitscape

# read in the raster
url_base = "https://raw.githubusercontent.com/Circuitscape/datasets/main/"
# Download the NLCD tile used to create the resistance surface and load it
download(string(url_base, "data/nlcd_2016_frederick_md.tif"),
         "nlcd_2016_frederick_md.tif")

land_cover, wkt, transform = Omniscape.read_raster(
    "nlcd_2016_frederick_md.tif",
    Float64
)

shape = size(land_cover)

chunks = (2, 2)

radius = 50 
block_size = 7

extents = Omniscape.get_chunk_extents(chunks, shape, radius, block_size)
compute_extents = Omniscape.get_compute_extents(extents, shape, radius)
rel_compute_extents = Omniscape.get_relative_compute_extents(
    extents,
    compute_extents
)

## Check that the relative extents are correct and stitch back together properly

output = fill(-9., size(land_cover))

for chunk_id in 1:length(extents)
    rel_range = (
        rel_compute_extents[chunk_id][1]:rel_compute_extents[chunk_id][2],
        rel_compute_extents[chunk_id][3]:rel_compute_extents[chunk_id][4]
    )
    extent_range = (
        extents[chunk_id][1]:extents[chunk_id][2],
        extents[chunk_id][3]:extents[chunk_id][4]
    )
    comp_range = (
        compute_extents[chunk_id][1]:compute_extents[chunk_id][2],
        compute_extents[chunk_id][3]:compute_extents[chunk_id][4]
    )
    
    ## Check if above calculation of relative extents is correct
    lc_chunk_ext = land_cover[extent_range...]
    lc_chunk_al = land_cover[comp_range...] 
    lc_chunk_rel = lc_chunk_ext[rel_range...]

    @test lc_chunk_rel == lc_chunk_al

    output[comp_range...] = lc_chunk_rel
end

@test output == land_cover

# for chunk_id in 1:length(extents)
#     rel_range = (rel_compute_bounds[chunk_id][1]:rel_compute_bounds[chunk_id][2], rel_compute_bounds[chunk_id][3]:rel_compute_bounds[chunk_id][4])
#     extent_range = (extents[chunk_id][1]:extents[chunk_id][2], extents[chunk_id][3]:extents[chunk_id][4])
#     comp_range = (compute_bounds[chunk_id][1]:compute_bounds[chunk_id][2], compute_bounds[chunk_id][3]:compute_bounds[chunk_id][4])
    
#     println(extent_range, " ", comp_range, " ", rel_range)
#     the_chunk = land_cover[extent_range...]
#     the_sub_chunk = the_chunk[rel_range...]

    
# end



rm("nlcd_2016_frederick_md.tif")