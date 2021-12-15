using Revise
using CounterfactualRegret
using SDA
game = SDA.SpaceGame(5,20)

solver = ESCFRSolver(game)
train!(solver, 10_000, show_progress=true)

using Plots
using PyPlot
data = solution_data(solver)
Plots.plot(data)
PyPlot.savefig("PolarStrategyProfile.svg")


p = Plots.plot(data.σ_sat, label="Satellite Strategy", lw = 2, legend=:right)
Plots.plot!(p, data.σ_ground, label="Ground Strategy", lw = 2)
xlabel!(p, "Time Step")
Plots.savefig(p, "LinearStrategyProfile.svg")
