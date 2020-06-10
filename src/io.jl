# Inspired by GeoArrays.read()
function read_raster(path::String)
    raw = ArchGDAL.unsafe_read(path)
    transform = ArchGDAL.getgeotransform(raw)
    wkt = ArchGDAL.getproj(raw)

    # Extract 1st band (should only be one band anyway)
    # to get a 2D array instead of 3D
    band = ArchGDAL.getband(raw, 1)

    # Extract the array
    array_t = ArchGDAL.read(band)

    # This handles UInt tiff rasters that can still have negative NoData values
    # Need to convert the NoData value to Int64 in these cases
    if eltype(array_t) <: Integer
        ras_type = Int64
    else
        ras_type = eltype(array_t)
    end

    # Extract no data value, first converting it to the proper type (based on
    # the raster). Then, need to convert to Float64. Weird, yes,
    # but it's the only way I could get it to work for all raster types...
    nodata_val = convert(Float64, convert(ras_type, ArchGDAL.getnodatavalue(band)))

    # Transpose the array -- ArchGDAL returns a x by y array, need y by x
    array = convert(Array{Float64}, permutedims(array_t, [2, 1]))

    array[array .== nodata_val] .= -9999.0

    # Line to handle NaNs in datasets read from tifs
    array[isnan.(array)] .= -9999.0

    # Close connection to dataset
    ArchGDAL.destroy(raw)

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

    file_format == "tif" ? (options = ["COMPRESS=LZW"]) :
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
        ArchGDAL.setnodatavalue!(band, -9999.0)
        # Write projection info
        ArchGDAL.setgeotransform!(dataset, transform)
        ArchGDAL.setproj!(dataset, wkt)

        # Copy memory object to disk (necessary because ArchGDAL.create
        # does not support creation of ASCII rasters)
        ArchGDAL.destroy(ArchGDAL.copy(dataset,
                                       filename = fn,
                                       driver = ArchGDAL.getdriver(driver),
                                       options = options))
    end
    nothing
end
