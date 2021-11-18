using Revise
using CounterfactualRegret
using CounterfactualRegret: SpaceGame, SpaceGameHist
using Plots

game = SpaceGame(5,10)
sol = ESCFRSolver(game)
train!(sol,100_000)

print(sol)
for (k,I) in sol.I
    if first(k) == 2
        println(k,"\t",I.σ)
    end
end

FullEvaluate(sol)

FullEvaluate(sol)

FullEvaluate(sol)

FullEvaluate(sol)

FullEvaluate(sol)

T = 10
scores = Vector{NTuple{2, Float64}}(undef, T)
Threads.@threads for t in 1:T
    println(t)
    game = SpaceGame(t,T)
    sol = ESCFRSolver(game)
    train!(sol,100_000)
    s = FullEvaluate(sol)
    scores[t] = s
end


p = plot(first.(scores), label="", lw=5, marker=:square, markercolor=:red)
xlabel!(p,"Ground Station Scanning Budget")
ylabel!(p,"Intruder Satellite Score")
title!("10 Step Mode Change Detection")
savefig(p,"ModeChangeDetection.svg")
