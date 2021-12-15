module SDA

using CounterfactualRegret; const CFR = CounterfactualRegret
using PyPlot; const plt = PyPlot
import Plots

include("SpaceGame.jl")
export SpaceGame

include("OldSpaceGame.jl")

include("SpaceGamePlot.jl")
export solution_data

end # module