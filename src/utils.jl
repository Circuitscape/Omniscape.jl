function myaddprocs(n)
    addprocs(n)
    @everywhere Core.eval(Main, :(import Omniscape))
end

function copyvars(i, array)
    global nrows_remote = size(array, 1)
    global ncols_remote = size(array, 2)
end

function sum_currmaps(args::Dict{String, Int64})
    cum_currmap_local = fill(0., args["nrows"], args["ncols"])
    for i in workers()
        cum_currmap_local = cum_currmap_local .+ @fetchfrom i cum_currmap
    end
    cum_currmap_local
end

function sum_fpmaps(args::Dict{String, Int64})
    fp_cum_currmap_local = fill(0., args["nrows"], args["ncols"])
    for i in workers()
        fp_cum_currmap_local = fp_cum_currmap_local .+ @fetchfrom i fp_cum_currmap
    end
    fp_cum_currmap_local
end


