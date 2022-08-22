@testset "tracking" begin
    game = TrackingGame(max_steps=10, tol = 0.1TrackingGames.R_EARTH)
    sol = OSCFRSolver(game)
    train!(sol, 20; show_progress = true)
    r_sums = sum.(getfield.(values(sol.I), :r))
    @test any(>(0.0), r_sums)
end
