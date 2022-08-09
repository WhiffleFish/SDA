using SDA
using Plots
using CounterfactualRegret

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
