using CounterfactualRegret
using SDA

game = SpaceGame(5,20)
sol = ESCFRSolver(game)
train!(sol, 10_000, show_progress = true)

print(sol)
data = SDA.solution_data(sol)
using Plots, PyPlot
fig = plot(data)
PyPlot.savefig("MoreSymmetric.svg")

sol.I[(2,0,5)]

print(sol)

plot(data.σ_sat, label="Satellite Strategy", legend=:bottom)
plot!(data.σ_ground, label="Ground Strategy")
savefig("")

##
using CounterfactualRegret
using SDA

game = SDA.OldSpaceGame(5,20)
sol = ESCFRSolver(game; debug=true)
train!(sol, 50_000, show_progress = true)

data = SDA.solution_data(sol)
using Plots
plot(data)
