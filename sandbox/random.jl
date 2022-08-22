using SDA.TrackingGames
using CounterfactualRegret
const CFR = CounterfactualRegret
using StaticArrays


game = TrackingGame(
    max_steps   = 5,
    tol         = 0.1TrackingGames.R_EARTH,
    dt          = 1000.,
    sat_actions = SA[-500., -100.,0., 100., 500.]
)
sol = OSCFRSolver(game)
train!(sol, 1000; show_progress=true)


train!(sol, 100_000; show_progress=true)

sol.I



##
using Plots
sat_vec = [(k[1:end] => v.s ./ sum(v.s)) for (k,v) in sol.I if k[1] == 2.0]

s = Set(map(x->first(x)[1:6], sat_vec))

init_state = first(s)

filtered_vec = filter(x->first(x)[1:6]≈init_state, sat_vec)

key,val = first(filtered_vec)
burns = key[7:end]
start = SVector{4, Float64}(init_state[3:6])
for burn in burns
    start = step(game, start, burn)
end
s0 = start


step(game, start, -500.)

bump_vel



u0 = bump_vel(s0, 500.)
sys = ContinuousDynamicalSystem(sat_dynamics, u0, 0.0)
t = trajectory(sys, game.dt, Δt = game.dt/100)
t[:,1]


begin
    p = plot()
    for a in game.sat_actions
        u0 = bump_vel(s0, a)
        sys = ContinuousDynamicalSystem(sat_dynamics, u0, 0.0)
        t = trajectory(sys, game.dt, Δt = game.dt/100)
        plot!(p, t[:,1], t[:,2], lw=3, c=:blue, label="", alpha=0.5)
    end
    p
end

plot(x,y)

trajectory(sys)
game.gen.integrator

start



for (k,v) in filtered_vec
    [init_state]
end


sat_vec[1][1]

unique(getindex.(first.(sat_vec), 1:4))



h0 = initialhist(game)
a = rand(chance_actions(game,h0))
h1 = next_hist(game, h0,a)
s = h1.sat_state


s = TrackingGames.circular_state_rad(TrackingGames.R_EARTH, 0.0)
s = step(game, s, 500.)
s = step(game, s, 0.)





height(h1.sat_state)
TrackingGames.height(s) / TrackingGames.R_EARTH

using Plots
plot(cb, lw=2)


sum(sum.([v.r for (k,v) in sol.I if k[1] == 2.0]) .> 0.)


getfield.(values(sol.I), :r)

values(sol.I)

using SDA.Tracking
using CounterfactualRegret.Games
game = TrackingGame(max_steps=5)
tree = GameTree(game)

Base.summarysize(tree)

@timev GameTree(game)
Base.summarysize(tree) / 1e6


##


using SDA
using JET

JET.report_package(SDA)
