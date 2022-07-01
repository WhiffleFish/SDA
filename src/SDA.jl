module SDA

using CounterfactualRegret; const CFR = CounterfactualRegret
using PyPlot; const plt = PyPlot
import Plots
using StaticArrays

include("SpaceGame.jl")
export SpaceGame

include("SpaceGamePlot.jl")
export solution_data

include(joinpath("TrackingGame", "TrackingGame.jl"))

end # module
