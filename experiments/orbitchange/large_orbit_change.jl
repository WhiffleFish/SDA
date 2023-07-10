using SDA
using SDA.TrackingGames
using CounterfactualRegret
const CFR = CounterfactualRegret
using FileIO

const TRAIN_ITER = 10_000_000

save_path = joinpath(@__DIR__, "models", "model_$(train_iter).jld2")

game = TrackingGame()
sol = OSCFRSolver(game)
cb = CFR.MCTSNashConvCallback(sol, 10_000; max_iter=1_000_000)

train!(sol, TRAIN_ITER+1; cb, show_progress=true)

FileIO.save(save_path, Dict("sol" => sol, "cb"=>cb))
