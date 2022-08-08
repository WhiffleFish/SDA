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
        plot!(p, t[:,1], t[:,2], lw=3, c=:blue, label="", alpha=α*σ[i])
    end
end
