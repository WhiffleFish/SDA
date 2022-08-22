@testset "spacegame" begin
    game = SpaceGame(5,10)
    sol = ESCFRSolver(game)
    train!(sol, 100)
    r_sums = sum.(getfield.(values(sol.I), :r))
    @test any(>(0.0), r_sums)
end
