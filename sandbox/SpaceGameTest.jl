using CounterfactualRegret
using SDA
game = SDA.SpaceGame(7,20)

solver = ESCFRSolver(game)
train!(solver, 10_000, show_progress=true)

using Plots
using PyPlot
data = solution_data(solver)
Plots.plot(data)
PyPlot.savefig("PolarStrategyProfileB7T20.svg")


p = Plots.plot(rad2deg.(data.θ),data.σ_sat, label="Satellite Strategy", lw = 2, legend=:bottom)
Plots.plot!(p,rad2deg.(data.θ), data.σ_ground, label="Ground Strategy", lw = 2)
xlabel!(p, "θ (deg)")
Plots.savefig(p, "LinearStrategyProfile.svg")
