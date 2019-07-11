function init_cfg()
    cfg = Dict{String, String}()

    cfg["resistance_file"] = "(browse to resistance file)"
    cfg["source_file"] = "(browse to source file)"

    cfg["calc_flow_potential"] = "false"
    cfg["block_size"] = "1"
    cfg["radius"] = "1"
    cfg["buffer"] = "0"
    cfg["source_threshold"] = "0"
    cfg["project_name"] = "(filename prefix for project)"

    cfg
end

function parse_cfg(path::String)
    cf = init_cfg()
    f = open(path, "r")
    for i in eachline(f, keep = true)
        if first(i) == '['
            continue
        end
        idx = something(findfirst(isequal('='), i), 0)
        var = rstrip(i[1:idx-1])
        val = strip(i[idx+1:end])
        cf[var] = val
    end
    close(f)
    cf
end

function init_csdict(cfg)
    a = Dict{String, String}()

    a["source_file"] = "$(cfg["project_name"])_scratch/temp_source.asc"
    a["ground_file"]  = "$(cfg["project_name"])_scratch/temp_ground.asc"
    a["ground_file_is_resistances"] = "True"
    a["use_direct_grounds"] = "False"

    a["output_file"] = "temp"
    a["write_cum_cur_map_only"] =  "False"

    a["habitat_file"] = "$(cfg["project_name"])_scratch/temp_resistance.asc"
    a["scenario"] = "Advanced"

    a
end

function init_ascii_header()
    ascii_header = Dict{String, String}()
    ascii_header["ncols"] = ""
    ascii_header["nrows"] = ""
    ascii_header["xllcorner"] = "0"
    ascii_header["yllcorner"] = "0"
    ascii_header["cellsize"] = "1"
    ascii_header["nodata_value"] = "-9999"

    ascii_header
end


function update_ascii_header!(A, ascii_header)
    ascii_header["ncols"] = "$(size(A, 2))"
    ascii_header["nrows"] = "$(size(A, 1))"
end
