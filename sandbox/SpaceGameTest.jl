using Revise
using CounterfactualRegret
using SDA
game = SDA.SpaceGame(5,10)

solver = ESCFRSolver(game)
train!(solver, 1_000)
@profiler train!(solver, 10_000)


##
@profiler train!(solver, 10) recur=:flat

h = initialhist(game)
h = next_hist(game, h, :act)
h = next_hist(game, h, :act)
