using CounterfactualRegret
using SDA
using Plots
game = SDA.SpaceGame(7,20)
solver = ESCFRSolver(game)
train!(solver, 1_000, show_progress=true)

data = solution_data(solver)
plot(data)
