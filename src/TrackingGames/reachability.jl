function reachable(game; progress=true)
    T = game.max_steps - 1
    initialstates = game.init_states
    A = game.sat_actions

    # https://en.wikipedia.org/wiki/M-ary_tree
    # number of nodes in perfect m-ary tree
    total_states = floor(Int,length(initialstates) * length(A) ^ (T+1) / (length(A)-1))
    prog = Progress(total_states; enabled=progress)

    set = Dict{Int, Vector{Float64}}(0=>Float64[])
    for s0 in initialstates
        θ = mod2pi(atan(s0[2], s0[1]))
        push!(set[0], θ)
        _reachable!(set, game, s0, 0, prog)
    end
    return set
end

function _reachable!(set, game, s, d, prog)
    T = game.max_steps - 1
    d ≥ T && return

    for ΔV in game.sat_actions
        s′ = step(game, s, ΔV)
        θ = mod2pi(atan(s′[2], s′[1]))
        level = get!(set, d+1) do
            Float64[]
        end
        if height(s′) > R_EARTH
            push!(level, θ)
            next!(prog)
            _reachable!(set, game, s′, d+1, prog)
        else
            next!(prog)
        end
    end
end

function equal_areas(vals, nbins; sorted=false)
    !sorted && sort!(vals)
    N = length(vals)
    vals_per_bin = N / nbins
    v = Tuple{Float64, Float64}[]

    start = first(vals)
    finish = 0.0
    count = 0.0
    for i ∈ eachindex(vals)
        val = vals[i]
        count += 1
        if count ≥ vals_per_bin
            finish = val
            push!(v, (start, finish))
            start = finish
            count -= vals_per_bin
        end
    end
    push!(v, (last(v)[2], last(vals)))
    return v
end
