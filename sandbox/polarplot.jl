using Revise
using CounterfactualRegret
using CounterfactualRegret: SpaceGame, SpaceGameHist, Kuhn
using PyPlot
const plt = PyPlot

BUDGET = 5
T = 20
game = SpaceGame(BUDGET,T)
sol = ESCFRSolver(game)
train!(sol, 100_000)

sat_strat = filter(p->first(p)[1]==1, sol.I)
L = length(sat_strat)
v = Vector{Float64}(undef, L)
for i in 0:(L-1)
    σ = copy(sat_strat[(1,i,0)].s)
    σ ./= sum(σ)
    v[i+1] = σ[2]
end

θ = LinRange(0, 2π, L)
data = v

reward_data = CounterfactualRegret.cardioid.(θ)
reward_data ./= maximum(reward_data)

fig = plt.figure()
ax = plt.axes(polar=true)
b_sat = plt.bar(θ, data, alpha=0.5, color="red", width=2π/(T-1))
b2 = plt.plot(θ, reward_data, c="yellow")
display(fig)


## Extract Ground station probabilities

k = (2,0,BUDGET)
d = Dict{Int, Float64}()

path_prob = 1.0
s = copy(sol.I[k].s)
s ./= sum(s)
t,b = k[2:3]
d[]

function recur_eval(sol, path_prob::Float64, k, d::Dict, T::Int)
    σ = copy(sol.I[k].s)
    σ ./= sum(σ)

    t,b = k[2:3]
    Pscan = get(d,t, 0.0)
    d[t] = Pscan + path_prob*σ[2]

    # for pass
    if t+1 ≥ T
        return nothing
    else
        recur_eval(sol, path_prob*σ[1], (2,t+1, b), d, T)
    end

    # for scan
    if t+1 ≥ T || b-1 ≤ 0
        return nothing
    else
        recur_eval(sol, path_prob*σ[2], (2,t+1, b-1), d, T)
    end
end

function marginal_ground_strat(sol, budget::Int, T::Int)
    base_key = (2, 0, budget)
    d = Dict{Int, Float64}()
    recur_eval(sol, 1.0, base_key, d, T)
    return d
end

d = marginal_ground_strat(sol, BUDGET, T)
ground_strat = [d[i] for i in 0:length(d)-1]

fig = plt.figure()
ax = plt.axes(polar=true)
b_sat = plt.bar(θ, data, alpha=0.5, color="red", width=2π/(T-1))
b_sat = plt.bar(θ, ground_strat, alpha=0.5, color="blue", width=2π/(T-1))
b2 = plt.plot(θ, reward_data, c="yellow")
display(fig)
plt.savefig("savepls.svg")
