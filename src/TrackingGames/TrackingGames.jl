module TrackingGames

using CounterfactualRegret
const CFR = CounterfactualRegret
using DynamicalSystems
using StaticArrays # already exported by DynamicalSystems

include("dynamics.jl")
include("ObsTrackingGame.jl")
include("TrackingGame.jl")
export ObsTrackingGame, TrackingGame

end # module
