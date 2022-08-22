using SDA.TrackingGames
using CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using Plots

game = TrackingGame(
    max_steps   = 8,
    tol         = 0.1TrackingGames.R_EARTH,
    dt          = 500.,
    sat_actions = SA[-500., -100., 0., 100., 500.]
)

sol = OSCFRSolver(game)
train!(sol, 1_000_000; show_progress=true)

p = TrackingGames.plot_satellite_trajectories(sol; goal_idx=1, prob_thresh=1e-2)
savefig(p, "BetterSatTrajectories.pdf")

plot(
    (TrackingGames.plot_satellite_trajectories(sol; goal_idx=i, prob_thresh=1e-2)
    for i in 1:4)...,
    layout=4
)

Plots.savefig("MultipleTrajectories.svg")

using FileIO
FileIO.save("tracking_oscfr.jld2", sol)

#=
- Still have bug where we can't get the size of the action space via infokey
- So, a strategy call with non-tabulated infokey returns uniform actions of size whatever first(sol.I) gives
- This breaks if the size of the action space changes...

- Should be fixed in CounterfactualRegret 0.5
- Just don't wanna upgrade for now because it breaks so many things...
=#
strategy(sol, rand(Float32,10))

d = filter(sol.I) do (k,v)
    k[1] == 1
end

σs = map(values(d)) do v
    v.s ./ sum(v.s)
end

histogram(getindex.(σs, 5); normalize=true)

length.(keys(d)) |> maximum # 17
#=
1 - 1.0f0 (player num indicator)

=#
