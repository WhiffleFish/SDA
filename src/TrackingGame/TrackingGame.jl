module TrackingGame

using CounterfactualRegret
using DifferentialEquations
using DynamicalSystems
using StaticArrays # already exported by DynamicalSystems

const INITIAL_SAT_STATES = (
    SA[0,-1.5R_EARTH, 5000., 0.0],
    SA[1.0R_EARTH,-1.0R_EARTH, 5000., 0.0],
    SA[1.0R_EARTH,-1.0R_EARTH, 2500., 2500.],
    SA[1.0R_EARTH,1.0R_EARTH, , -2500., 2500.],
)

const GOAL_ALTS = (
    1.5R_EARTH,
    2.0R_EARTH,
    2.5R_EARTH
)

# create custom iterator maybe?
const CHANCE_ACTIONS = Iterators.product(INITIAL_SAT_STATES, GOAL_ALTS) |> collect

struct TrackingGameHist
    p::Int
    sat_state::SVector{4, Float64}
    goal_alt::Float64
    budget::Int
    guess::Float64
    t::Int
end

CFR.initialhist(g::TrackingGame) = TrackingGameHist(0, @SVector(zeros(4)), -1.0, g.budget, 0.0, 0)

Base.@kwdef struct TrackingGame{N, G, IS, GS} <: Game{TrackingGameHist, K??}
    dt::Float64     = 100.
    max_steps::Int  = 10
    n_sectors::Int  = 4
    budget::Int     = 5
    gen::G          = GenCache(dt)
    tol::Float64    = 10_000.
    goal_states::GS = GOAL_ALTS
    init_states::IS = INITIAL_SAT_STATES
    sat_actions::SVector{N,Float64}  = SA[-10., 0., 10.]
end

CFR.player(::TrackingGame, h) = h.p

CFR.chance_actions(::TrackingGame, h) = CHANCE_ACTIONS

# TODO: type stability
function CFR.actions(g::TrackingGame, h::TrackingGameHist)
    return if isone(player(g,h))
        0:n_sectors # if 0, don't scan
    else
        g.sat_actions
    end
end

"""
Ground station turn
"""
function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Int)
    @assert player(g,h) === 1
    if a > 0
        TrackingGameHist(2, h.sat_state, h.goal_alt, h.budget-1, h.t)
    else
        TrackingGameHist(2, h.sat_state, h.goal_alt, h.budget, h.t)
    end
end

"""
Satellite turn
"""
function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Float64)
    @assert player(g,h) === 2 # TODO: account for final guessing round!
    s′ = step(g, h.sat_state, a)
    return TrackingGameHist(1, s′, h.goal_alt, h.budget, h.t-1)
end

function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Tuple)
    return TrackingGameHist(
        1,
        a[1], # sat state
        a[2], # goal state
        h.budget,
        h.guess,
        h.t
    )
end

CFR.isterminal(g::TrackingGame, h) = h.t ≥ g.max_steps

function CFR.utility(g::TrackingGame, p::Int, h::TrackingGameHist)
    x,y = h.sat_state
    alt = sqrt(x^2 + y^2)
    if abs(alt - h.goal_alt) < g.tol
        if h.guess == g.goal_state
            return isone(p) ? 1.0 : -1.0
        else
            return isone(p) ? -1.0 : 1.0
        end
    else
        if h.guess == g.goal_state
            return isone(p) ? 1.0 : -1.0
        else
            return 0.0
        end
    end
end

end # module
