using CounterfactualRegret

game = SpaceGame(5,10)

solver = CFRSolver(game)
@time train!(solver, 1)


##
@profiler train!(solver, 10) recur=:flat
