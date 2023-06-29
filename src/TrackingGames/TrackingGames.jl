module TrackingGames

using CounterfactualRegret
const CFR = CounterfactualRegret
using DynamicalSystemsBase
using ProgressMeter
using Plots
using StaticArrays # already exported by DynamicalSystems
import POMDPs
import POMDPTools

include("dynamics.jl")
include("TrackingGame.jl")
include("ObsTrackingGame.jl")
include("plotting.jl")
include("reachability.jl")
include("heuristic.jl")
include("pomdp.jl")
export ObsTrackingGame, TrackingGame, plot_multi_traj!

end # module
