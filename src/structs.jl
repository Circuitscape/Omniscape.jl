struct OmniscapeFlags
    calc_flow_potential::Bool
    calc_normalized_current::Bool
    compute_flow_potential::Bool #bad name, but need a variable that stores the "or" of the previous two, internal use only
    write_raw_currmap::Bool
    parallelize::Bool
    correct_artifacts::Bool
    source_from_resistance::Bool
    conditional::Bool
    mask_nodata ::Bool
    resistance_is_conductance::Bool
    write_as_tif::Bool
    allow_different_projections::Bool
    reclassify::Bool
    write_reclassified_resistance::Bool
end