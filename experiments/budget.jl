using CounterfactualRegret
using SDA
using Plots

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

exp_hist = zeros(10)
exp_hist_ne = zeros(10)
for b ∈ 1:10
    @show b
    game = SpaceGame(b,10)
    _sol = CFRSolver(game)
    train!(_sol, 1_000; show_progress=true)
    _new_sol = deepcopy(_sol)
    fill_heuristic!(_new_sol, b, 10)
    exp_hist[b] = first(evaluate(_new_sol))/2
    exp_hist_ne[b] = first(evaluate(_sol))/2
end

sol = CFRSolver(SpaceGame(5,10))
train!(sol, 1)
max_score = sum(SDA.cardioid(θ) for θ in solution_data(sol).θ) / 2

y1 = [max_score;copy(exp_hist)]
y2 = [max_score;copy(exp_hist_ne)]
x = 0:length(y1)-1 |> collect


plot(
    x,
    y1;
    xlabel="Budgeted Sensor Observations",
    ylabel="Satellite Score \n(Higher for more undetected mode changes)",
    title="Strategy Performance Comparison",
    lw=5,
    xticks = 0:10,
    yticks = 0:10,
    marker=:square,
    # markercolor=:red,
    label = "Best Pure Strategy")

savefig("BestPureStrategy.svg")

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
    label = ["Best Pure Strategy" "NE Strategy"])

savefig("StrategyPerformanceComparison.svg")
