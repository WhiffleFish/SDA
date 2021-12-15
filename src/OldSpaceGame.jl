using StaticArrays

const OldSpaceGameInfoState = NTuple{3,Int} # (player, time, budget)

struct OldSpaceGameHist
    p::Int # current player
    t::Int # current time step
    score::Float64 # score dependent on terminal history is clunky here
    budget::Int # How many more times can ground station scan
    mode_change::Bool # Did sat mode change on last turn
end

# Satellite is player 1
# Gound station is player 2
struct OldSpaceGame <: Game{OldSpaceGameHist, OldSpaceGameInfoState}
    budget::Int # How often can we look
    T::Int # Max simulation time steps
end

CounterfactualRegret.player(::OldSpaceGame, h::OldSpaceGameHist) = h.p

CounterfactualRegret.actions(::OldSpaceGame, h::OldSpaceGameHist) = SA[:wait, :act]


cardioid(θ,a=1) = 2a*(1-cos(θ))

function score(g::OldSpaceGame, h::OldSpaceGameHist, a::Symbol)
    θ = 2π*(h.t/g.T)
    s = cardioid(θ)
    if h.mode_change
        return a == :act ? s : -s
    else
        return 0
    end
end


function CounterfactualRegret.next_hist(g::OldSpaceGame, h::OldSpaceGameHist , a::Symbol)
    if player(g,h) == 1
        return OldSpaceGameHist(2, h.t, h.score, h.budget, a == :act)
    else
        s = score(g,h,a)
        budget = h.budget
        a == :act && (budget -= 1)
        budget == 0 && (s -= (g.T - (h.t+1)))
        return OldSpaceGameHist(1, h.t+1, h.score + s, budget, false)
    end
end

CounterfactualRegret.isterminal(g::OldSpaceGame, h::OldSpaceGameHist) = h.t ≥ g.T || h.budget == 0

CounterfactualRegret.initialhist(g::OldSpaceGame) = OldSpaceGameHist(1, 0, 0, g.budget, false)

CounterfactualRegret.utility(::OldSpaceGame, i::Int, h::OldSpaceGameHist) = i == 2 ? h.score : -h.score

CounterfactualRegret.infokey(::OldSpaceGame, h::OldSpaceGameHist) = (h.p, h.t, h.p===2 ? h.budget : 0)
