const REQUIRED_ARGS_INI = ["resistance_file",
                           "radius",
                           "project_name"]

const REQUIRED_ARGS_DICT = ["radius",
                            "project_name"]

const TRUELIST = ["true", "True", "TRUE"]

const SINGLE = ["single", "Single", "SINGLE"]

const SOLVERS = ["cg+amg", "cholmod"]

const N_CONDITIONS_VALUES = ["1", "2"]

const COMPARE_TO_FUTURE_VALUES = ["none", "1", "2", "both"]

const COMPARISONS = ["equal", "within"]

const SUPPORTED_ARGS = ["resistance_file", "resistance_is_conductance",
    "source_file", "project_name", "parallelize", "parallel_batch_size",
    "block_size", "radius", "buffer", "source_threshold",
    "source_from_resistance", "r_cutoff", "precision",
    "connect_four_neighbors_only", "solver", "calc_flow_potential",
    "calc_normalized_current", "correct_artifacts", "write_raw_currmap",
    "write_as_tif", "mask_nodata", "suppress_cs_messages", "conditional",
    "n_conditions", "compare_to_future", "condition1_file", "condition2_file",
    "condition1_future_file", "condition2_future_file", "comparison1",
    "comparison2", "condition1_lower", "condition2_lower", "condition1_upper",
    "condition2_upper", "reclassify_resistance", "reclass_table",
    "write_reclassified_resistance", "allow_different_projections"]
