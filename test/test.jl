using DelimitedFiles
import Circuitscape

## Include needed functions

include("../src/functions.jl")
include("../src/config.jl")
include("../src/io.jl")
include("../src/Omniscape.jl")

## Create and write sources
# sources_raw = reshape(rand(1500000), 1000, 1500)
# resistance_raw = reshape(rand(1500000), 1000, 1500)

# temp_header_1 = init_ascii_header()
# ## Update temp ascii header
# update_ascii_header!(sources_raw, temp_header_1)

# ## Write source, ground, and resistance asciis
# write_ascii(sources_raw, "test/input/source.asc", temp_header_1)
# write_ascii(resistance_raw, "test/input/resistance.asc", temp_header_1)

path = "test/input/config.ini"

Omniscape(path)
n = 6

header = open(readlines, `head -n $(n) $(file)`)
split(header[1])[1]
