module TrackingGames

using CounterfactualRegret
const CFR = CounterfactualRegret
using DynamicalSystemsBase
using Plots
using StaticArrays # already exported by DynamicalSystems

include("dynamics.jl")
include("TrackingGame.jl")
include("ObsTrackingGame.jl")
include("plotting.jl")
export ObsTrackingGame, TrackingGame, plot_multi_traj!

end # module
