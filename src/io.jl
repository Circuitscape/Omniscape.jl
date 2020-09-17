function read_raster(path::String, T)
    # Check if file exists (ArchGDAL error is cryptic)
    check_path = endswith(path, ".gz") ? path[10:lastindex(path)] : path
    !isfile(check_path) && error("the file \"$(check_path)\" does not exist")

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
    # the raster). Then, need to convert to T. Weird, yes,
    # but it's the only way I could get it to work for all raster types... -VL
    nodata_val = convert(T, convert(ras_type, ArchGDAL.getnodatavalue(band)))

    # Transpose the array -- ArchGDAL returns a x by y array, need y by x
    # Line to handle NaNs in datasets read from tifs
    array_t[isnan.(array_t)] .= nodata_val

    array = convert(Array{Union{Missing, T}}, permutedims(array_t, [2, 1]))

    array[array .== nodata_val] .= missing

    # Close connection to dataset
    ArchGDAL.destroy(raw)

    array, wkt, transform # wkt and transform are needed later for write_raster
end

# Write a single band raster, either in .tif or .asc format,
# inspired by GeoArrays.write()
# Intended to only write rasters with no values < 0
function write_raster(fn_prefix::String,
                      array::Array{Union{Missing, T}, 2} where T <: Number,
                      wkt::String,
                      transform,
                      file_format::String)
    # Handle missing values, replace with typemin for nodata setting
    # and to Array{T, 2}
    no_data_val = -9999
    data_eltype = eltype(array)
    dtype = data_eltype.a == Missing ? data_eltype.b : data_eltype.a
    array[ismissing.(array)] .= nodata_val

    array = convert(Array{dtype, 2}, array)

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

    # Create raster in memory *NEEDED* because no create driver for .asc
    ArchGDAL.create(fn_prefix,
                    driver = ArchGDAL.getdriver("MEM"),
                    width = width,
                    height = height,
                    nbands = 1,
                    dtype = dtype,
                    options = options) do dataset
        band = ArchGDAL.getband(dataset, 1)
        # Write data to band
        ArchGDAL.write!(band, array_t)

        # Write nodata and projection info
        ArchGDAL.setnodatavalue!(band, nodata_val)
        ArchGDAL.setgeotransform!(dataset, transform)
        ArchGDAL.setproj!(dataset, wkt)

        # Copy memory object to disk (necessary because ArchGDAL.create
        # does not support creation of ASCII rasters)
        ArchGDAL.destroy(ArchGDAL.copy(dataset,
                                       filename = fn,
                                       driver = ArchGDAL.getdriver(driver),
                                       options = options))
    end

end

