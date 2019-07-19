function myaddprocs(n)
    addprocs(n)
    @everywhere Core.eval(Main, :(import Omniscape))
end

function copyvars(i, array)
    global nrows_remote = size(array, 1)
    global ncols_remote = size(array, 2)
end

