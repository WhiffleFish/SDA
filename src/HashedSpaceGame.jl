const SpaceGameInfoState = Tuple{Int, Int, Int, UInt64} # (player, time, budget, hash)

struct SpaceGameHist
    p::Int # current player
    t::Int # current time step
    score::Float64 # score dependent on terminal history is clunky here
    budget::Int # How many more times can ground station scan
    mode_change::Bool # Did sat mode change on last turn
    p1hash::UInt64
    p2hash::UInt64
end

# Satellite is player 1
# Gound station is player 2
Base.@kwdef struct SpaceGame <: Game{SpaceGameHist, SpaceGameInfoState}
    budget::Int         = 5 # How often can we look
    T::Int              = 20 # Max simulation time steps
    init_hash::UInt64   = hash(Tuple{}())
end

CFR.player(::SpaceGame, h::SpaceGameHist) = h.p

CFR.actions(::SpaceGame, h::SpaceGameHist) = (:wait, :act)

cardioid(θ) = 2.0*(1.0-cos(θ))

function score(g::SpaceGame, h::SpaceGameHist, a::Symbol)
    if h.mode_change
        θ = 2π*(h.t/g.T)
        s = cardioid(θ)
        return a === :act ? s : -s
    else
        return 0.
    end
end


function CFR.next_hist(g::SpaceGame, h::SpaceGameHist , a::Symbol)
    if isone(player(g,h))
        if iszero(h.budget) # if budget is expended, loop back to satellite
            θ = 2π*(h.t/g.T)
            s = a === :act ? -cardioid(θ) : 0.0
            return SpaceGameHist(1, h.t+1, h.score + s, h.budget, a === :act, hash(a, h.p1hash), h.p2hash)
        else
            return SpaceGameHist(2, h.t, h.score, h.budget, a === :act, hash(a, h.p1hash), h.p2hash)
        end
    else
        s = score(g,h,a)
        budget = h.budget
        a === :act && (budget -= 1)
        return SpaceGameHist(1, h.t+1, h.score + s, budget, false, h.p1hash, hash(a, h.p2hash))
    end
end

CFR.isterminal(g::SpaceGame, h::SpaceGameHist) = h.t ≥ g.T

CFR.initialhist(g::SpaceGame) = SpaceGameHist(1, 0, 0, g.budget, false, g.init_hash, g.init_hash)

CFR.utility(::SpaceGame, i::Int, h::SpaceGameHist) = i === 2 ? h.score : -h.score

function CFR.infokey(::SpaceGame, h::SpaceGameHist)
    if h.p === 2
        return (h.p, h.t, h.budget, h.p2hash)::SpaceGameInfoState
    else
        return (h.p, h.t, 0, h.p1hash)::SpaceGameInfoState
    end
end
