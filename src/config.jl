function init_cfg()
    cfg = Dict{String, String}()

    cfg["resistance_file"] = "(browse to resistance file)"
    cfg["resistance_file_is_conductance"] = "false"
    cfg["source_file"] = "(browse to source file)"
    cfg["project_name"] = "(filename prefix for project)"

    cfg["parallelize"] = "true"
    cfg["parallel_batch_size"] = "10"

    cfg["block_size"] = "1"
    cfg["radius"] = "(choose source radius)"
    cfg["buffer"] = "0"
    cfg["source_threshold"] = "0"
    cfg["source_from_resistance"] = "false"
    cfg["r_cutoff"] = "Inf"
    cfg["precision"] = "double"

    cfg["calc_flow_potential"] = "false"
    cfg["calc_normalized_current"] = "false"

    cfg["correct_artifacts"] = "true"

    cfg["write_raw_currmap"] = "true"
    cfg["write_as_tif"] = "true"
    cfg["mask_nodata"] = "true"

    cfg["conditional"] = "false"
    cfg["n_conditions"] = "1"
    cfg["compare_to_future"] = "none"
    cfg["condition1_file"] = "(browse to condition 1 file)"
    cfg["condition2_file"] = "(browse to condition 2 file)"
    cfg["condition1_future_file"] = "(browse to future condition 1 file)"
    cfg["condition2_future_file"] = "(browse to future condition 2 file)"
    cfg["comparison1"] = "within"
    cfg["comparison2"] = "within"
    cfg["condition1_lower"] = "0"
    cfg["condition2_lower"] = "0"
    cfg["condition1_upper"] = "0"
    cfg["condition2_upper"] = "0"

    cfg["reclassify_resistance"] = "false"
    cfg["reclass_table"] = "(browse to resistance reclass table file)"
    cfg["write_reclassified_resistance"] = "false"

    cfg["allow_different_projections"] = "false"

    cfg
end

function update_cfg!(cfg, cfg_new)
    for (key,val) in cfg_new
        cfg[key] = val
    end
end

function parse_cfg(path::String)
    cf = Dict{String, String}()
    f = open(path, "r")
    for i in eachline(f, keep = true)
        if first(i) == '['
            continue
        end
        idx = something(findfirst(isequal('='), i), 0)
        var = rstrip(i[1:idx - 1])
        val = strip(i[idx + 1:end])
        cf[var] = val
    end
    close(f)
    cf
end

function init_csdict(cfg)
    a = Dict{String, String}()

    a["ground_file_is_resistances"] = "True"
    a["use_direct_grounds"] = "False"

    a["output_file"] = "temp"
    a["write_cum_cur_map_only"] =  "False"

    a["scenario"] = "Advanced"

    a
end

