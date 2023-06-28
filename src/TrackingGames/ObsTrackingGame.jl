# create custom iterator maybe?
const OBS_CHANCE_ACTIONS = Iterators.product(INITIAL_SAT_STATES, GOAL_ALTS) |> collect

struct ObsTrackingGameHist
    p::Int
    sat_state::SVector{4, Float64}
    goal_alt::Float64
    budget::Int
    guess::Int
    t::Int
end

Base.@kwdef struct ObsTrackingGame{N, G, IS, GS} <: Game{ObsTrackingGameHist, Nothing}
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

CFR.initialhist(g::ObsTrackingGame) = TrackingGameHist(0, @SVector(zeros(4)), -1.0, g.budget, 0, 0)

Base.step(g::ObsTrackingGame, s::SVector, Δv::Float64) = step(g.gen, s, Δv)

CFR.player(::ObsTrackingGame, h) = h.p

CFR.chance_actions(::ObsTrackingGame, h) = OBS_CHANCE_ACTIONS

# TODO: type stability
function CFR.actions(g::ObsTrackingGame, h::ObsTrackingGameHist)
    return if isone(player(g,h))
        if h.t == g.max_steps
            eachindex(g.goal_states)
        else
            0:g.n_sectors # if 0, don't scan
        end
    else
        g.sat_actions
    end
end

"""
Ground station turn
"""
function CFR.next_hist(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Int)
    @assert isone(player(g,h))
    if h.t < g.max_steps
        if a > 0
            return ObsTrackingGameHist(2, h.sat_state, h.goal_alt, h.budget-1, 0, h.t)
        else
            return ObsTrackingGameHist(2, h.sat_state, h.goal_alt, h.budget, 0, h.t)
        end
    else
        return ObsTrackingGameHist(2, h.sat_state, h.goal_alt, h.budget, a, h.t)
    end
end

"""
Satellite turn
"""
function CFR.next_hist(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Float64)
    @assert player(g,h) === 2 # TODO: account for final guessing round!
    s′ = step(g, h.sat_state, a)
    return ObsTrackingGameHist(1, s′, h.goal_alt, h.budget, h.guess, h.t+1)
end

function CFR.next_hist(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Tuple)
    @assert iszero(player(g,h))
    return ObsTrackingGameHist(
        1,
        a[1], # sat state
        a[2], # goal state
        h.budget,
        h.guess,
        h.t
    )
end

CFR.isterminal(g::ObsTrackingGame, h) = (h.t ≥ g.max_steps) && (h.p == 2)

function CFR.observation(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Int, h′::ObsTrackingGameHist)
    iszero(a) && return false
    x = h.sat_state
    θ = mod2pi(atan(x[2], x[1])) # θ ∈ [0,2π]
    sector_div = 2π / g.n_sectors
    sector = Int(θ ÷ sector_div)
    return sector == a
end

function CFR.observation(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Float64, h′::ObsTrackingGameHist)
    return zero(UInt) # sat doesn't know wtf is going on
end

function CFR.observation(g::ObsTrackingGame, h::ObsTrackingGameHist, a::Tuple, h′::ObsTrackingGameHist)
    return (zero(UInt), a)
end

function CFR.utility(g::ObsTrackingGame, p::Int, h::ObsTrackingGameHist)
    x,y = h.sat_state # this works but seems a lil dicey and unclear
    alt = sqrt(x^2 + y^2)
    guess_alt = g.goal_states[h.guess]
    if abs(alt - h.goal_alt) < g.tol
        if guess_alt == h.goal_alt
            return isone(p) ? 1.0 : -1.0
        else
            return isone(p) ? -1.0 : 1.0
        end
    else
        if h.guess == h.goal_alt
            return isone(p) ? 1.0 : -1.0
        else
            return 0.0
        end
    end
end
