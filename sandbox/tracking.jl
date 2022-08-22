using SDA.TrackingGames
using CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using Plots

game = TrackingGame(
    max_steps   = 5,
    tol         = 0.1TrackingGames.R_EARTH,
    dt          = 1000.,
    sat_actions = SA[-500., -100.,0., 100., 500.]
)
sol = OSCFRSolver(game)
train!(sol, 10_000_000; show_progress=true)

goal_alt = TrackingGames.GOAL_ALTS[2]
d2 = filter(sol.I) do (k,v)
    (first(k) == 2) && k[2] == goal_alt
end


p = plot(xticks=0, yticks=0,aspect_ratio=:equal)
Plots.vline!(p,[0], lw=5, c=:black, label="")
Plots.hline!(p,[0], lw=5, c=:black, label="")
for (k,v) in d2
    σ = v.s ./ sum(v.s)
    TrackingGames.plot_multi_traj!(p,game,k, σ)
end
TrackingGames.plot_goal_region!(p, game, goal_alt)
p

scan_prob_sums = zeros(5)
d1 = filter(sol.I) do (k,v)
    (first(k) == 1)
end
for (k,v) in d1
    if length(v.s) == 5
        scan_prob_sums .+= v.s ./ sum(v.s)
    end
end
scan_prob_sums ./= sum(scan_prob_sums)
θs = deg2rad.(45:90:360)
for i in 1:4
    y,x = 2TrackingGames.R_EARTH .* sincos(θs[i])
    σ_i = scan_prob_sums[i+1]
    σ_i_pct_str = string(round(σ_i*100, sigdigits=3))*"%"
    annotate!([(x,y, σ_i_pct_str)])
end
p

savefig(p, "TrackingGamePolicy.svg")
