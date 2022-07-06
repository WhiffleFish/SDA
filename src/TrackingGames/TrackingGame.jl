const INITIAL_SAT_STATES = (
    circular_state_rad(R_EARTH, deg2rad(000.)),
    circular_state_rad(R_EARTH, deg2rad(090.)),
    circular_state_rad(R_EARTH, deg2rad(180.)),
    circular_state_rad(R_EARTH, deg2rad(270.)),
)

const GOAL_ALTS = (
    1.0R_EARTH,
    1.1R_EARTH,
    1.3R_EARTH,
    1.5R_EARTH
)

# create custom iterator maybe?
const CHANCE_ACTIONS = Iterators.product(INITIAL_SAT_STATES, GOAL_ALTS) |> collect

struct TrackingGameHist
    p::Int
    sat_state::SVector{4, Float64}
    goal_alt::Float64
    budget::Int
    guess::Int
    t::Int
    p1_info::Vector{Float64}
    p2_info::Vector{Float64}
end

Base.@kwdef struct TrackingGame{N, G, IS, GS} <: Game{TrackingGameHist, Vector{Float64}}
    dt::Float64     = 500.
    max_steps::Int  = 5
    n_sectors::Int  = 4
    budget::Int     = 5
    gen::G          = GenCache(dt)
    tol::Float64    = 10_000.
    goal_states::GS = GOAL_ALTS
    init_states::IS = INITIAL_SAT_STATES
    sat_actions::SVector{N,Float64}  = SA[-100., 0., 100.]
end

CFR.initialhist(g::TrackingGame) = TrackingGameHist(0, @SVector(zeros(4)), -1.0, g.budget, 0, 0, Float64[1], Float64[2])

Base.step(g::TrackingGame, s::SVector, Δv::Float64) = step(g.gen, s, Δv)

CFR.player(::TrackingGame, h) = h.p

CFR.chance_actions(::TrackingGame, h) = CHANCE_ACTIONS

# TODO: type stability
function CFR.actions(g::TrackingGame, h::TrackingGameHist)
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
function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Int)
    @assert isone(player(g,h))
    if h.t < g.max_steps # searching round
        o = ground_obs(g, h, a)
        p1_info = copy(h.p1_info)
        push!(p1_info, float(a))
        push!(p1_info, o)
        if a > 0
            return TrackingGameHist(2, h.sat_state, h.goal_alt, h.budget-1, 0, h.t, p1_info, h.p2_info)
        else
            return TrackingGameHist(2, h.sat_state, h.goal_alt, h.budget, 0, h.t, p1_info, h.p2_info)
        end
    else # guessing round
        return TrackingGameHist(2, h.sat_state, h.goal_alt, h.budget, a, h.t, h.p1_info, h.p2_info)
    end
end

"""
Satellite turn
"""
function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Float64)
    @assert player(g,h) === 2
    p2_info = copy(h.p2_info)
    s′ = step(g, h.sat_state, a)
    return TrackingGameHist(1, s′, h.goal_alt, h.budget, h.guess, h.t+1, h.p1_info, push!(p2_info, a))
end

"""
Chance turn
"""
function CFR.next_hist(g::TrackingGame, h::TrackingGameHist, a::Tuple)
    @assert iszero(player(g,h))
    p2_info = copy(h.p2_info)
    initial_state, goal_alt = a
    push!(p2_info, goal_alt)
    l = length(p2_info)
    resize!(p2_info, l+4)
    p2_info[l+1:l+4] .= initial_state

    return TrackingGameHist(
        1,
        a[1], # sat state
        a[2], # goal state
        h.budget,
        h.guess,
        h.t,
        h.p1_info,
        p2_info
    )
end

CFR.isterminal(g::TrackingGame, h) = (h.t ≥ g.max_steps) && (h.p == 2)

function ground_obs(g::TrackingGame, h::TrackingGameHist, a::Int)
    iszero(a) && return false
    x = h.sat_state
    θ = mod2pi(atan(x[2], x[1])) # θ ∈ [0,2π]
    sector_div = 2π / g.n_sectors
    sector = Int(θ ÷ sector_div)
    return float(sector == a)
end


# FIXME: NOT USED - DELETE MAYBE
function CFR.observation(g::TrackingGame, h::TrackingGameHist, a::Float64)
    return (zero(Float64), zero(Float64)) # sat doesn't know wtf is going on
end

# FIXME: NOT USED - DELETE MAYBE
function CFR.observation(g::TrackingGame, h::TrackingGameHist, a::Tuple)
    initial_state, goal_alt = a
    return (zero(Float64), a)
end

function CFR.utility(g::TrackingGame, p::Int, h::TrackingGameHist)
    x,y = h.sat_state # this works but seems a lil dicey and unclear
    guess = g.goal_states[h.guess]
    alt = sqrt(x^2 + y^2)
    if abs(alt - h.goal_alt) < g.tol
        if guess == h.goal_alt
            return isone(p) ? 1.0 : -1.0
        else
            return isone(p) ? -1.0 : 1.0
        end
    else
        if guess == h.goal_alt
            return isone(p) ? 1.0 : -1.0
        else
            return 0.0
        end
    end
end

function CFR.infokey(g::TrackingGame, h)
    return isone(player(g,h)) ? h.p1_info : h.p2_info
end
