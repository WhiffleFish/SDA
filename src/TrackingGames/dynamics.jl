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

struct GenCache{SYS,INT<:SciMLBase.AbstractODEIntegrator}
    sys::SYS
    integrator::INT
    dt::Float64
end

function GenCache(dt::Float64)
    sys = ContinuousDynamicalSystem(sat_dynamics, @SVector(zeros(4)), 0.0)
    return GenCache(sys,integrator(sys), dt)
end

function bump_vel(s, Δv)
    x,y,vx,vy = s
    θv = atan(vy,vx)
    Δvx = Δv*cos(θv)
    Δvy = Δv*sin(θv)
    s′ = s + SA[0., 0., Δvx, Δvy] # single impulse
    return s′
end

function Base.step(cache::GenCache, s::SVector, Δv::Float64)
    int = cache.integrator
    s′ = bump_vel(s, Δv)
    reinit!(int, s′)
    step!(int, cache.dt, true)
    return get_state(int)
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

#=
using Plots

u0 = SA[0,-1.5R_EARTH, 5000., 0.0]
sys = ContinuousDynamicalSystem(sat_dynamics, u0, -0.5)
t = trajectory(sys, 15_000.0)

x = t[:,1]
y = t[:,2]

plot(x,y,aspect_ratio=:equal, label="")

step!(sys, 1)

integ = integrator(sys)
step!(integ, 1.0)
get_state(integ)
=#
