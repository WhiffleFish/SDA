struct SatTrackingHeuristicPolicy{S}
    d::Dict{S, Float64}
end

struct SatHeuristicTraverser{G}
    game::G
    goal_alt::Float64
    A::Vector{Float64}
    T::Int
end

function traverse(game::TrackingGame)
    s = only(game.init_states)
    A = game.sat_actions
    GA = game.goal_states
    opt_traj = Vector{Float64}[]
    for goal_alt in GA
        trav = SatHeuristicTraverser(game, goal_alt, A, game.max_steps)
        traj = search(trav, s, 0)
        push!(opt_traj, traj)
    end
    return opt_traj
end


function search(trav::SateHeuristicTraverser, state, t)
    (;game, goal_alt, A, T) = trav
    x,y = state
    alt = sqrt(square(x) + square(y))
    if t == T
        cost = 0.0
        traj = Float64[]
        cost = abs(alt - goal_alt) < game.tol ? 0.0 : Inf
        return traj, cost
    end
    local best_traj::Vector{Float64}
    best_a = A
    best_cost = Inf
    for a ∈ A
        sp = step(game, state, a)
        sub_traj, cost = search(sp, goal, t+1)
        if cost < best_cost
            best_cost = cost
            best_a = ax
            best_traj = sub_traj
        end
    end
    return [a; best_traj], abs(best_a) + best_cost
end
