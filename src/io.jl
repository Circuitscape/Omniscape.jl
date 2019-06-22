function write_ascii(A, ascii_header; type)
    filename = "scratch/temp_$(type).asc"
    f = open(filename, "w")

    write(f, "ncols         $(ascii_header["ncols"])\n")
    write(f, "nrows         $(ascii_header["nrows"])\n")
    write(f, "xllcorner     $(ascii_header["xllcorner"])\n")
    write(f, "yllcorner     $(ascii_header["yllcorner"])\n")
    write(f, "cellsize      $(ascii_header["cellsize"])\n")
    write(f, "NODATA_value  $(ascii_header["nodata"])\n")

    writedlm(f, round.(A, digits=8), ' ')
    close(f)
enda
