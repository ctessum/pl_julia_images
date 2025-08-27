using Pkg
Pkg.instantiate()
Pkg.precompile()

using Pluto
using Pluto.PlutoRunner
using PlutoUI

t = @async include(joinpath(ENV["PROJECT_DIR"], "startup.jl"))

sleep(60)
@info "throwing interrupt"
@async Base.throwto(t, InterruptException())
sleep(2)
@info "done with Pluto"

using Plots
