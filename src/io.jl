# Inspired by GeoArrays.read()
function read_raster(path::AbstractString)
    raw = ArchGDAL.unsafe_read(path)
    transform = ArchGDAL.getgeotransform(raw)
    wkt = ArchGDAL.getproj(raw)

    # Extract 1st band (should only be one band anyway)
    # to get a 2D array instead of 3D
    band = ArchGDAL.getband(raw, 1)

    # Extract the array
    array_t = ArchGDAL.read(band)

    # Extract no data value and overwrite with Circuitscape/Omniscape default
    nodata_val = ArchGDAL.getnodatavalue(band)

    array_t[array_t .== nodata_val] .= -9999.0

    # Line to handle NaNs in datasets read from tifs
    array_t[isnan.(array_t)] .= -9999.0

    # Transpose the array -- ArchGDAL returns a x by y array, need y by x
    array = convert(Array{Float64}, permutedims(array_t, [2, 1]))

    # Close connection to dataset
    ArchGDAL.destroy(raw)
    ArchGDAL.destroy(band)

    array, wkt, transform # wkt and transform are needed later for write_raster
end

# Write a single band raster, either in .tif or .asc format,
# inspired by GeoArrays.write()
function write_raster(fn_prefix::AbstractString,
                      array,
                      wkt::AbstractString,
                      transform,
                      file_format::String)
    # transponse array back to columns by rows
    array_t = permutedims(array, [2, 1])

    width, height = size(array_t)

    # Define extension and driver based in file_format
    file_format == "tif" ? (ext = ".tif"; driver = "GTiff") :
            (ext = ".asc"; driver = "AAIGrid")

    file_format == "tif" ? (options = ["COMPRESS=DEFLATE","TILED=YES"]) :
                           (options = [])

    # Append file extention to filename
    fn = string(fn_prefix, ext)

    # Create raster in memory
    ArchGDAL.create(fn_prefix,
                    driver = ArchGDAL.getdriver("MEM"),
                    width = width,
                    height = height,
                    nbands = 1,
                    dtype = eltype(array_t),
                    options = options) do dataset
        band = ArchGDAL.getband(dataset, 1)
        # Write data to band
        ArchGDAL.write!(band, array_t)

        # Write nodata and projection info
        ArchGDAL.setnodatavalue!(band, -9999.0)
        ArchGDAL.setgeotransform!(dataset, transform)
        ArchGDAL.setproj!(dataset, wkt)

        # Copy memory object to disk (necessary because ArchGDAL.create
        # does not support creation of ASCII rasters)
        ArchGDAL.copy(dataset,
                      filename = fn,
                      driver = ArchGDAL.getdriver(driver),
                      options = options)
    end

end

function check_raster_alignment(raster1, raster2)
    sizes_equal = size(raster1[1]) == size(raster2[1])
    projections_equal = (raster1[2] == raster2[2]) && (raster1[3] == raster2[3])

    sizes_equal, projections_equal
end

function different_raster_sizes_error(name1, name2)
    @error "$(name1) and $(name2) are different sizes."
end

function different_raster_projections_warning(name1, name2)
    @warn "$(name1) and $(name2) have different projections. This could
mean they are not properly aligned. Attempting to proceed anyway. Press ctrl-c
(or command-c on Mac) to quit."
    sleep(10)
end


# # Old functions no longer needed, keep commented out for now during development
# function write_ascii(A::Array{Float64, 2}, filename::String, ascii_header::Dict)
#     f = open(filename, "w")
#
#     write(f, "ncols         $(ascii_header["ncols"])\n")
#     write(f, "nrows         $(ascii_header["nrows"])\n")
#     write(f, "xllcorner     $(ascii_header["xllcorner"])\n")
#     write(f, "yllcorner     $(ascii_header["yllcorner"])\n")
#     write(f, "cellsize      $(ascii_header["cellsize"])\n")
#     write(f, "nodata_value  $(ascii_header["nodata_value"])\n")
#
#     writedlm(f, round.(A, digits=8), ' ')
#     close(f)
# end
#
# function parse_ascii_header(path::String)
#     cf = init_ascii_header()
#     f = open(path, "r")
#     for i = 1:6
#         key_val = split(readline(f))
#         key_val[1] = lowercase(key_val[1])
#         cf["$(key_val[1])"] = key_val[2]
#     end
#
#     cf
# end
#
# function read_ascii(path::String)
#     a = readdlm(path, Float64; skipstart = 6)
#     a
# end