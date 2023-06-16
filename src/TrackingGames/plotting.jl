function plot_multi_traj!(p, game, k, σ; α::Float64=1.0)
    burns = k[7:end]
    s0 = SVector{4, Float64}(k[3:6])
    for burn in burns
        s0 = step(game, s0, burn)
    end

    for (i,a) in enumerate(game.sat_actions)
        u0 = bump_vel(s0, a)
        sys = ContinuousDynamicalSystem(sat_dynamics, u0, 0.0)
        t = trajectory(sys, game.dt, Δt = game.dt/100)
        plot!(p, t[:,1], t[:,2], lw=3, c=:red, label="", alpha=α*σ[i])
    end
end

function plot_traj!(p, game, s, Δv, α=1.0) # TODO: return final state, so we don't have to redo the step
    u0 = bump_vel(s, Δv)
    sys = ContinuousDynamicalSystem(sat_dynamics, u0, 0.0)
    X,t = trajectory(sys, game.dt, Δt = game.dt/100)
    plot!(p, X[:,1], X[:,2], lw=3, c=:red, label="", alpha=α)
end

function plot_satellite_trajectories(sol; init_state_idx::Int=1, goal_idx::Int=1, max_depth=sol.game.max_steps-1, prob_thresh=1e-2, show_earth=true, kwargs...)
    game = sol.game
    h0 = initialhist(game)
    a_chance = chance_actions(game, h0)[init_state_idx, goal_idx]
    h = next_hist(game, h0, a_chance)
    h = next_hist(game, h, first(actions(game, h)))
    I0 = infokey(game, h)
    s0 = SVector{4, Float64}(I0[3:end])
    goal_alt = I0[2]

    p = plot(;xticks=0, yticks=0, aspect_ratio=:equal, showaxis=false, kwargs...)
    if show_earth
        plot!(p, circle_shape(0,0, R_EARTH), seriestype=[:shape], lw=0.5, c=:blue, linecolor=:black, fillalpha=0.2, label="")
    end
    plot_goal_region!(p, game, goal_alt)
    plot_sat_strats!(p, sol, I0, s0; max_depth, prob_thresh)
    return p
end

function plot_sat_strats!(p, sol, I, s, η=1.0, d=0; max_depth=10, prob_thresh=1e-2)
    (d > max_depth || η < prob_thresh) && return
    σ = strategy(sol, I)
    A = sol.game.sat_actions
    for i in eachindex(σ, A)
        η′ = η*σ[i]
        η′ > prob_thresh && plot_traj!(p, sol.game, s, A[i], η′)
        s′ = step(sol.game, s, A[i])
        I′ = push!(copy(I), A[i])
        plot_sat_strats!(p, sol, I′, s′, η′, d+1; max_depth, prob_thresh)
    end
    nothing
end

function plot_goal_region!(p, game, goal::AbstractFloat; kwargs...)
    θ = 0:0.01:2π
    x1 = @. (goal - game.tol)*cos(θ)
    y1 = @. (goal - game.tol)*sin(θ)
    x2 = @. (goal + game.tol)*cos(θ)
    y2 = @. (goal + game.tol)*sin(θ)
    plot!(p, x1, y1; c=:orange, ls=:dash, label="", kwargs...)
    plot!(p, x2, y2; c=:orange, ls=:dash, label="", kwargs...)
end

# https://discourse.julialang.org/t/plot-a-circle-with-a-given-radius-with-plots-jl/23295
function circle_shape(h, k, r)
    θ = 0:0.01:2π
    h .+ r .* sin.(θ), k .+ r .* cos.(θ)
end
