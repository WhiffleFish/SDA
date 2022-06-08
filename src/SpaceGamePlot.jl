struct SpaceSolData
    θ::Vector{Float64}
    σ_sat::Vector{Float64}
    σ_ground::Vector{Float64}
    r::Vector{Float64}
end

function recur_eval(sol, path_prob::Float64, k, d::Dict, T::Int)
    σ = CFR.strategy(sol, k)

    t,b = k[2:3]
    Pscan = get(d,t, 0.0)
    d[t] = Pscan + path_prob*σ[2]

    # for pass
    if t+1 ≥ T
        return nothing
    else
        recur_eval(sol, path_prob*σ[1], SA[2,t+1, b], d, T)
    end

    # for scan
    if t+1 ≥ T || b-1 ≤ 0
        return nothing
    else
        recur_eval(sol, path_prob*σ[2], SA[2,t+1, b-1], d, T)
    end
end

function marginal_ground_strat(sol)
    T = sol.game.T
    budget = sol.game.budget

    base_key = SA[2, 0, budget]
    d = Dict{Int, Float64}()
    recur_eval(sol, 1.0, base_key, d, T)
    return [d[i] for i in 0:length(d)-1]
end

function sat_strat(sol)
    # sat_strat = filter(p->first(p)[1]==1, sol.I)
    # L = length(sat_strat)
    L = sol.game.T
    v = Vector{Float64}(undef, L)
    for i in 0:(L-1)
        σ = CFR.strategy(sol, SA[1,i,0])
        v[i+1] = σ[2]
    end
    return v
end

function solution_data(sol)
    σ_sat = sat_strat(sol)
    # L = length(σ_sat)
    L = sol.game.T
    Δθ = 2π/(L+1)
    θ = LinRange(0, 2π, L+1)[1:end-1]
    σ_ground = marginal_ground_strat(sol)
    reward_data = cardioid.(θ)

    return SpaceSolData(θ, σ_sat, σ_ground, reward_data)
end

function Plots.plot(data::SpaceSolData)
    θ, σ_sat, σ_ground, reward_data = data.θ, data.σ_sat, data.σ_ground, data.r
    T = length(θ)
    reward_data = [data.r; first(data.r)]
    reward_data ./= maximum(reward_data)

    fig = plt.figure()
    ax = plt.axes(polar=true)
    b_sat = plt.bar(
        θ, σ_sat,
        alpha = 0.50,
        color = "red",
        width = 2π/(T),
        label = "Satellite Strategy",
        # edgecolor = "black"
    )
    b_sat = plt.bar(
        θ, σ_ground,
        alpha = 0.50,
        color = "blue",
        width = 2π/(T),
        label = "Ground Strategy",
        # edgecolor = "black"
    )
    b2 = plt.plot([θ; first(θ)], reward_data, c="green", label="Reward")
    legend(loc="best", bbox_to_anchor=(0.75, 0.0, 0.30, 0.0))
    display(fig)

    return fig
end
