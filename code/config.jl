# Omniscape defaults
function init_csdict()
    a = Dict{String, String}()

    a["source_file"] = "scratch/sources.asc"
    a["ground_file"]  = "scratch/grounds.asc"
    a["ground_file_is_resistances"] = "True"
    a["use_direct_grounds"] = "False"

    a["use_variable_source_strengths"] = "True"
    a["variable_source_file"] =  "None"
    a["output_file"] = "$(project_name)"
    a["write_cum_cur_map_only"] =  "True"

    a["habitat_file"] = "scratch/resistance.asc"
    a["scenario"] = "Advanced"

    a
end
