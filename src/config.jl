function init_cfg()
    cfg = Dict{String, String}()

    cfg["resistance_file"] = "(browse to resistsance file)"
    cfg["source_file"] = "(browse to source file)"

    cfg["normalize"] = "false"
    cfg["block_size"] = "1"
    cfg["radius"] = "1"
    cfg["buffer"] = "1"
    cfg["source_threshold"] = "0"
    cfg["project_name"] = "(filename prefix for project)"

    cfg
end


function init_csdict()
    a = Dict{String, String}()

    a["source_file"] = "$(project_name)_scratch/temp_source.asc"
    a["ground_file"]  = "$(project_name)_scratch/temp_ground.asc"
    a["ground_file_is_resistances"] = "True"
    a["use_direct_grounds"] = "False"

    a["output_file"] = "temp"
    a["write_cum_cur_map_only"] =  "False"

    a["habitat_file"] = "$(project_name)_scratch/temp_resistance.asc"
    a["scenario"] = "Advanced"

    a
end

function update_ascii_header!(A, ascii_header)
    ascii_header["ncols"] = "$(size(A, 2))"
    ascii_header["nrows"] = "$(size(A, 1))"
end
