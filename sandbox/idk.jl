using Revise
using CounterfactualRegret
using CounterfactualRegret: SpaceGame, SpaceGameHist, Kuhn
using Plots

game = SpaceGame(5,10)
sol = ESCFRSolver(game)
@profiler train!(sol,10_000)

print(sol)
for (k,I) in sol.I
    if first(k) == 2
        println(k,"\t",I.σ)
    end
end

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

pv = Vector{Plots.Plot}(undef,2)
p = plot(first.(scores), label="", lw=5, marker=:square, markercolor=:red)
xlabel!(p,"Ground Station Scanning Budget")
ylabel!(p,"Intruder Satellite Score")
title!(p, "")
pv[2] = p

cardioid(θ,a=1) = 2a*(1-cos(θ))
p1 = plot(2π .* (0:(T)) ./ T, cardioid, proj=:polar, label="", lw=3)
title!(p1, "Polar Reward Profile")
savefig(p1, "PolarRewardProfile.svg")

title!("10 Step Mode Change Detection")
savefig(p,"ModeChangeDetection.svg")

## Scores???

T = 20
dist_from_origin(t,T) = min(t, T+1-t)
score(t,T) = (T+1)÷2 - dist_from_origin(t,T)

θ =
scores = score.(0:(T),T)

plot(θ, scores, proj=:polar)

cardioid(θ,a=1) = 2a*(1-cos(θ))

plot(θ, cardioid, proj=:polar)

##

@recipe function f(sol::CounterfactualRegret.AbstractCFRSolver{H,K,G}) where {H,K,G <: CounterfactualRegret.IIEMatrixGame}
    layout --> 2
    link := :both
    framestyle := [:axes :axes]

    xlabel := "Training Steps"

    L1 = length(sol.I[0].σ)
    # labels1 = Matrix{String}(undef, 1, L1)
    # for i in eachindex(labels1); labels1[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 1
        ylabel := "Strategy"
        title := "Player 1"
        # labels := labels1
        reduce(hcat,I[0].hist)'
    end

    L2 = length(sol.I[1].σ)
    labels2 = Matrix{String}(undef, 1, L2)
    # for i in eachindex(labels2); labels2[i] = L"a_{%$(i)}"; end

    @series begin
        subplot := 2
        title := "Player 2"
        # labels := labels2
        reduce(hcat,I[1].hist)'
    end
end

game = CounterfactualRegret.IIEMatrixGame([
    (1,1) (0,0) (0,0);
    (0,0) (0,2) (3,0);
    (0,0) (2,0) (0,3);
])
sol1 = ESCFRSolver(game;debug=true)
train!(sol1, 10_000)

plot(reduce(hcat, sol1.I[0].hist)')

sol1 isa CounterfactualRegret.AbstractCFRSolver{H,K,G} where {H,K,G <: CounterfactualRegret.IIEMatrixGame}

typeof(game) <: CounterfactualRegret.IIEMatrixGame
