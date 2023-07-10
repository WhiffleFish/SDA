const TSState = Tuple{Int, Int} # (goal_idx, burn_idx)

struct TrackingStationPOMDP{G} <: POMDPs.POMDP{TSState, Int, Bool}
    trajs::Vector{Vector{SVector{4,Float64}}}
    game::G
end

function TrackingStationPOMDP(game::Game)
    @assert game.n_sectors+1 == length(game.sat_actions)
    trajs = TrackingGames.traverse(game)
    state_trajs = collect_traj_states(game, trajs)
    return TrackingStationPOMDP(state_trajs, game)
end

function collect_traj_states(game, trajs)
    state_trajs = Vector{SVector{4,Float64}}[]
    for traj ∈ trajs
        s = only(game.init_states)
        state_traj = [s]
        for Δv ∈ traj
            u0 = TrackingGames.bump_vel(s, Δv)
            sys = ContinuousDynamicalSystem(TrackingGames.sat_dynamics, u0, 0.0)
            X,t = trajectory(sys, game.dt, Δt = game.dt/100)
            s = last(X)
            push!(state_traj, s)
        end
        push!(state_trajs, state_traj)
    end
    return state_trajs
end

function flatten_trajs(state_trajs)
    d1 = length(state_trajs)
    d2 = length(first(state_trajs))
    function inner_func(i)
        outer, inner = divrem(i, d1)
        return (outer, state_trajs[outer+1][inner])
    end
    return (inner_func(i) for i ∈ 1:(d1*d2))
end

function POMDPs.states(p::TrackingStationPOMDP)
    ss = vec([(i,j) for j ∈ eachindex(first(p.trajs)), i ∈ eachindex(p.trajs)])
    push!(ss, (-1,-1)) # terminal
    return ss
end

POMDPs.actions(p::TrackingStationPOMDP) = 0:p.game.n_sectors
POMDPs.observations(::TrackingStationPOMDP) = (true, false)

function POMDPs.stateindex(p::TrackingStationPOMDP, s::TSState)
    if s === (-1,-1)
        return length(p.trajs)*length(first(p.trajs)) + 1
    else
        k = length(first(p.trajs))
        return k*(first(s)-1) + last(s)
    end
end
POMDPs.actionindex(::TrackingStationPOMDP, a) = a+1
POMDPs.obsindex(::TrackingStationPOMDP, o::Bool) = o ? 1 : 2

function POMDPs.observation(p::TrackingStationPOMDP, a, sp)
    (iszero(a) || POMDPs.isterminal(p, sp)) && return POMDPTools.Deterministic(false)
    x = p.trajs[first(sp)][last(sp)]
    θ = mod2pi(atan(x[2], x[1]))
    sector_div = 2π / p.game.n_sectors
    sector = Int(θ ÷ sector_div)
    return POMDPTools.Deterministic(sector == a)
end

function POMDPs.transition(p::TrackingStationPOMDP, s, a)
    POMDPs.isterminal(p, s) && return Deterministic(s)
    goal_idx, state_idx = s 
    return if state_idx < length(first(p.trajs))
        POMDPTools.Deterministic((goal_idx, state_idx+1))
    else
        POMDPTools.Deterministic((-1,-1))
    end
end

POMDPs.discount(::TrackingStationPOMDP) = 1. - eps()

POMDPs.initialstate(p::TrackingStationPOMDP) = POMDPTools.Uniform([
    (i,1) for i ∈ eachindex(p.trajs)
])

function POMDPs.reward(p::TrackingStationPOMDP, s, a)
    goal_idx, state_idx = s
    return if state_idx < length(first(p.trajs))
        0.0
    else
        a === goal_idx ? 1.0 : 0.0
    end
end

POMDPs.isterminal(::TrackingStationPOMDP, s) = s === (-1,-1)