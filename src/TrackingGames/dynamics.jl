const μ_EARTH = 3.986 * 10^14
const R_EARTH = 6.378 * 10^6

function sat_dynamics(u, p, t)
    x,y,vx,vy = u
    r² = x^2 + y^2
    θx = atan(y,x)
    # θv = atan(vy,vx)
    a_r = - μ_EARTH / r²
    a_y, a_x = a_r .* sincos(θx)# .+ p .* sincos(θv)
    return SA[vx, vy, a_x, a_y]
end

struct GenCache{SYS}
    sys::SYS
    dt::Float64
end

function GenCache(dt::Float64)
    sys = ContinuousDynamicalSystem(sat_dynamics, @SVector(zeros(4)), 0.0)
    return GenCache(sys, dt)
end

function bump_vel(s, Δv)
    x,y,vx,vy = s
    θv = atan(vy,vx)
    Δvx = Δv*cos(θv)
    Δvy = Δv*sin(θv)
    s′ = s + SA[0., 0., Δvx, Δvy] # single impulse
    return s′
end

function Base.step(cache::GenCache, s::SVector, Δv::AbstractFloat)
    sys = cache.sys
    s′ = bump_vel(s, Δv)
    reinit!(sys, s′)
    step!(sys, cache.dt, true)
    return get_state(sys)
end

height(s::SVector{4,Float64}) = sqrt(s[1]^2 + s[2]^2)

function circular_state_cart(x,y)
    r = sqrt(x^2 + y^2)
    θ = atan(y,x)
    return SA[x,y, circular_vel(r,θ)...]
end

function circular_state_rad(r,θ)
    y,x = r .* sincos(θ)
    return SA[x,y, circular_vel(r,θ)...]
end

function circular_vel(r,θ)
    a_g = μ_EARTH / r^2
    ω = sqrt(a_g / r)
    v_t = r*ω
    return v_t .* sincos(θ)
end
