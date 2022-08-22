using SDA.TrackingGames
using CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays
using Plots
using ProgressMeter

# sat_actions = SA[-500., -100.,0., 100., 500.]
game = TrackingGame(
    max_steps=10,
    tol = 0.1TrackingGames.R_EARTH,
    dt = 300.,
    sat_actions = SA[-100.,0., 100.]
)
sol = OSCFRSolver(game; baseline=ExpectedValueBaseline(game))
train!(sol, 10_000; show_progress=true)



sol_size = Base.summarysize(sol) # takes too long


##

sat_vec = [(k[1:end] => v.s ./ sum(v.s)) for (k,v) in sol.I if k[1] == 2.0]

s = Set(map(x->first(x)[1:6], sat_vec))

init_state = rand(s)
filtered_vec = filter(x->first(x)[1:6]≈init_state, sat_vec)
R = init_state[2]
R / TrackingGames.R_EARTH
p = plot(aspect_ratio=:equal)
@showprogress for (k,v) in filtered_vec
    plot_multi_traj!(p,game,k,v;α=0.1)
end
plot!(p, (R + game.tol) .* cos.(0:0.01:2π), (R + game.tol) .* sin.(0:0.01:2π), c=:red, ls=:dash, label="")
plot!(p, (R - game.tol) .* cos.(0:0.01:2π), (R - game.tol) .* sin.(0:0.01:2π), c=:red, ls=:dash, label="")
p

Base.summarysize(p) /1e6

savefig(p, "sat_strat_baseline_1m_iter.svg")

length(sol.I)
length(sol.I)
##

getfield.(values(sol.I), :s)


diffs = map(x -> sum(abs,x .- fill(1/3,3)),last.(filtered_vec))

sum(diffs) / length(diffs)
game.gen.integrator

##
k1, v1 = first(filtered_vec)

base = k1[1:6]
burns = k1[7:end]
init_state = SVector{4, Float64}(k1[3:6])

s1 = step(game, init_state, 500.)
u0 = TrackingGames.bump_vel(init_state, 500.)
sys = ContinuousDynamicalSystem(TrackingGames.sat_dynamics, u0, 0.0)
t = trajectory(sys, game.dt)
t

bump_vel(s1, 500.) - first(t)

first(t) - u0


p = plot()
for i in eachindex(Δv1)
    s0 = init_state
    for j in 1:i

    end
    s0 = step(game, s0, burn)

    u0 = bump_vel(s0, )
end


##

step(game,init_state, 500.)
game.gen.integrator |>propertynames
game.gen.integrator

trajectory(game.gen.integrator.f.f,100.)
