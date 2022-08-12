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

function plot_goal_region!(p, game, goal::AbstractFloat; kwargs...)
    θ = 0:0.01:2π
    x1 = @. (goal - game.tol)*cos(θ)
    y1 = @. (goal - game.tol)*sin(θ)
    x2 = @. (goal + game.tol)*cos(θ)
    y2 = @. (goal + game.tol)*sin(θ)
    plot!(p, x1, y1; c=:orange, ls=:dash, label="", kwargs...)
    plot!(p, x2, y2; c=:orange, ls=:dash, label="", kwargs...)
end
