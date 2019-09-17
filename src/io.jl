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

function parse_ascii_header(path::String)
    cf = init_ascii_header()
    f = open(path, "r")
    for i = 1:6
        key_val = split(readline(f))
        cf["$(key_val[1])"] = key_val[2]
    end
    cf
end

function read_ascii(path::String)
    a = readdlm(path, Float64; skipstart = 6)
    a
end