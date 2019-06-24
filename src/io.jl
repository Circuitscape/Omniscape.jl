function write_ascii(A::Array{Float64, 2}, filename::String, ascii_header::Dict)
    f = open(filename, "w")

    write(f, "ncols         $(ascii_header["ncols"])\n")
    write(f, "nrows         $(ascii_header["nrows"])\n")
    write(f, "xllcorner     $(ascii_header["xllcorner"])\n")
    write(f, "yllcorner     $(ascii_header["yllcorner"])\n")
    write(f, "cellsize      $(ascii_header["cellsize"])\n")
    write(f, "nodata_value  $(ascii_header["nodata_value"])\n")

    writedlm(f, round.(A, digits=8), ' ')
    close(f)
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

function parse_ascii_header(path::String)
    cf = init_ascii_header()
    header = open(readlines, `head -n $(6) $(path)`)
    for i = 1:6
        key_val = split(header[i])
        cf["$(key_val[1])"] = key_val[2]
    end
    cf
end

function read_ascii(path::String)
    a = readdlm(path, Float64; skipstart = 6)
    a
end
