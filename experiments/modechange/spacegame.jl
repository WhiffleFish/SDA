using CounterfactualRegret
using SDA
using Plots
game = SDA.SpaceGame(7,20)
solver = ESCFRSolver(game)
train!(solver, 10_000, show_progress=true)

data = solution_data(solver)
p = Plots.plot(data)

using PyPlot
PyPlot.savefig(joinpath(@__DIR__, "img", "polar_strategy.svg"))
PyPlot.savefig(joinpath(@__DIR__, "img", "polar_strategy.pdf"))
