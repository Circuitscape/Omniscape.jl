# Omniscape defaults
function init_csdict()
    a = Dict{String, String}()

    a["source_file"] = "scratch/temp_sources.asc"
    a["ground_file"]  = "scratch/temp_grounds.asc"
    a["ground_file_is_resistances"] = "True"
    a["use_direct_grounds"] = "False"

    a["output_file"] = "temp"
    a["write_cum_cur_map_only"] =  "False"

    a["habitat_file"] = "scratch/temp_resistance.asc"
    a["scenario"] = "Advanced"

    a
end

function init_temp_ascii_header()
    ascii_header = Dict{String, String}()
    ascii_header["ncols"] = ""
    ascii_header["nrows"] = ""
    ascii_header["xllcorner"] = "0"
    ascii_header["yllcorner"] = "0"
    ascii_header["cellsize"] = "1"
    ascii_header["nodata"] = "-9999"

    ascii_header
end

function update_ascii_header!(A, ascii_header)
    ascii_header["ncols"] = "$(size(A, 2))"
    ascii_header["nrows"] = "$(size(A, 1))"
end
