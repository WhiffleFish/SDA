const SpaceGameInfoState = SVector{3,Int} # (player, time, budget)

struct SpaceGameHist
    p::Int # current player
    t::Int # current time step
    score::Float64 # score dependent on terminal history is clunky here
    budget::Int # How many more times can ground station scan
    mode_change::Bool # Did sat mode change on last turn
end

# Satellite is player 1
# Gound station is player 2
struct SpaceGame <: Game{SpaceGameHist, SpaceGameInfoState}
    budget::Int # How often can we look
    T::Int # Max simulation time steps
end

CFR.player(::SpaceGame, h::SpaceGameHist) = h.p
CFR.player(::SpaceGame, k::SpaceGameInfoState) = first(k)

CFR.actions(::SpaceGame, h::SpaceGameHist) = (:wait, :act)
CFR.actions(::SpaceGame, k::SpaceGameInfoState) = (:wait, :act)

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
            return SpaceGameHist(1, h.t+1, h.score + s, h.budget, a === :act)
        else
            return SpaceGameHist(2, h.t, h.score, h.budget, a === :act)
        end
    else
        s = score(g,h,a)
        budget = h.budget
        a === :act && (budget -= 1)
        return SpaceGameHist(1, h.t+1, h.score + s, budget, false)
    end
end

CFR.isterminal(g::SpaceGame, h::SpaceGameHist) = h.t ≥ g.T

CFR.initialhist(g::SpaceGame) = SpaceGameHist(1, 0, 0, g.budget, false)

CFR.utility(::SpaceGame, i::Int, h::SpaceGameHist) = i === 2 ? h.score : -h.score

CFR.infokey(::SpaceGame, h::SpaceGameHist) = SpaceGameInfoState(h.p, h.t, h.p===2 ? h.budget : 0)

CFR.observation(::SpaceGame, h, a, h′) = zero(UInt)
