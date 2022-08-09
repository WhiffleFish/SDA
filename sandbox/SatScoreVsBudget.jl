using CounterfactualRegret
# using CounterfactualRegret: SpaceGame, SpaceGameHist, Kuhn
using SDA
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
using BestResponsePOMDP
B = 3
game = SpaceGame(3,10)
sol = CFRSolver(game)
train!(sol, 10_000; show_progress=true)

approx_exploitability(sol, 100_000)

T = 10
t = 4
B = 3
start = div(T,2) - div(B,2)
finish = start + B-1
new_sol = deepcopy(sol)
for (k,v) in new_sol.I
    if k[1] == 2
        t = k[2]
        if start ≤ t ≤ finish
            v.s .= (0.0, 1.0)
        else
            v.s .= (1.0, 0.0)
        end
    else
        v.s .= (1.0, 0.0)
    end
end

data = solution_data(new_sol)
p = plot(data)
using PyPlot
PyPlot.savefig("naive_strategy.svg")

approx_exploitability(new_sol, 100_000, new_sol.game, 1)

data
SDA.cardioid.(data.θ)


new_sol2 = deepcopy(sol)
for (k,v) in new_sol2.I
    t = k[2]
    if k[1] == 2
        if start ≤ t ≤ finish
            v.s .= (0.0, 1.0)
        else
            v.s .= (1.0, 0.0)
        end
    else
        if start ≤ t ≤ finish
            v.s .= (1.0, 0.0)
        else
            v.s .= (0.0, 1.0)
        end
    end
end

data = solution_data(new_sol2)
plot(data)
PyPlot.savefig("exploitative_sat.svg")

plot(solution_data(sol))
PyPlot.savefig("NE_strat.svg")

using Base.Threads
nthreads()
N = 100
vals = zeros(N)
@threads for i ∈ 1:N
    vals[i] = approx_exploitability(sol, 100_000)
end
histogram(vals)



## new budget study

function fill_heuristic!(sol, b, T)
    T = 10
    start = div(T,2) - div(b,2)
    finish = start + b-1
    for (k,v) in sol.I
        t = k[2]
        if k[1] == 2
            if start ≤ t ≤ finish
                v.s .= (0.0, 1.0)
            else
                v.s .= (1.0, 0.0)
            end
        else
            if start ≤ t ≤ finish
                v.s .= (1.0, 0.0)
            else
                v.s .= (0.0, 1.0)
            end
        end
    end
end

using ProgressMeter

exp_hist = zeros(10)
@showprogress for b ∈ 1:10
    game = SpaceGame(b,10)
    _sol = CFRSolver(game)
    train!(_sol, 1)
    _new_sol = deepcopy(sol)
    fill_heuristic!(_new_sol, b, 10)
    evaluate(_new_sol)
    exp_hist[b] = approx_exploitability(_new_sol, 1_000_000, game, 2; use_tree_value=false)/4
end

plot(
    exp_hist.*2;
    xlabel="budget",
    ylabel="Satellite Score",
    title="Pure Strategy Performance",
    labels="",
    lw = 2)

exp_hist2 = zeros(10)
exp_hist2_ne = zeros(10)
for b ∈ 1:10
    @show b
    game = SpaceGame(b,10)
    _sol = CFRSolver(game)
    train!(_sol, 1_000; show_progress=true)
    _new_sol = deepcopy(_sol)
    fill_heuristic!(_new_sol, b, 10)
    exp_hist2[b] = first(evaluate(_new_sol))/2
    exp_hist2_ne[b] = first(evaluate(_sol))/2
end


sol = CFRSolver(SpaceGame(5,10))
train!(sol, 1)
max_score = sum(SDA.cardioid(θ) for θ in solution_data(sol).θ) / 2


y1 = [max_score;copy(exp_hist2_ne)]
y2 = [max_score;copy(exp_hist2)]
x = 0:length(y1)-1 |> collect


plot(
    hcat(x,x),
    hcat(y1, y2);
    xlabel="Budgeted Sensor Observations",
    ylabel="Satellite Score \n(Higher for more undetected mode changes)",
    title="Strategy Performance Comparison",
    lw=5,
    xticks = 0:10,
    yticks = 0:10,
    marker=:square,
    # markercolor=:red,
    label = ["NE Strategy" "Best Pure Strategy"])



savefig("StrategyPerforamanceComparison.svg")
