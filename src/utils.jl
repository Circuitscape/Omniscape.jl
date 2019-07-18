function myaddprocs(n)
    addprocs(n)
    @everywhere Core.eval(Main, :(import Omniscape))
end
