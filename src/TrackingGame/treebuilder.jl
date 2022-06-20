struct GameTree{G<:Game, H}
    nodes::Vector{GameTreeHist{H}}
    children::Dict{NTuple{2, UInt}, UInt}
    game::G
end

"""
- `id::UInt`                            : index of node in tree.nodes
- `h::H`                                : history returned by underlying game
- `obs_hist::NTuple{2, Vector{UInt64}}` : action-observation history of each player
- `player::Int`                         : player whose turn it is to play
- `terminal::Bool`                      : check if history is terminal
- `utility::NTuple{2,Float64}`          : utility of history if history is terminal
"""
struct GameTreeHist{H}
    id::UInt64
    h::H
    obs_hist::NTuple{2, Vector{UInt64}} # assume 2 player game
    player::Int
    terminal::Bool
    utility::NTuple{2,Float64} # assume 2 player game
end

function build_tree(game::Game)
    tree = GameTree(game)
    h = initialhist(game)
    terminal = isterminal(game, h)
    u1 = terminal ? utility(game, h, 1) : 0.0
    u2 = terminal ? utility(game, h, 2) : 0.0
    h0 = GameTreeHist(UInt(1), h, (UInt[], UInt[]), player(game, h), teriminal, (u1, u2))
    push!(tree.nodes, h0)

    _build_tree(tree, h0)
end

function _build_tree(tree, h)
    game = tree.game
    p = h.player
    obs_hist = deepcopy(h.obs_hist)
    for a in actions(game, h.h)
        id = UInt(length(tree.nodes))
        h′ = next_hist(game, h.h, a)
        o = observation(game, h.h, a, h′)
        push!(obs_hist[p], hash(a))
        for (i,o_i) in enumerate(o)
            i != p && push!(obs_hist[i], hash(o_i))
        end
        terminal = isterminal(game, h′)
        u1 = terminal ? utility(game, h′, 1) : 0.0
        u2 = terminal ? utility(game, h′, 2) : 0.0
        tree_h′ = GameTreeHist(id, h′, obs_hist, player(game, h′), terminal, (u1, u2))
        push!(tree.nodes, tree_h′)
        tree.children[(h.id, hash(a))] = id
        !term && _build_tree(tree, tree_h′)
    end
end
