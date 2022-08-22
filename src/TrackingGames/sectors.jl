struct ScanSector
    center::Float64
    span::Float64
end

in_sector(s::ScanSector, v::SVector{4,Float64}) = in_sector(s, v[1], v[2])

in_sector(s::ScanSector, x, y) = in_sector(s, atan(y,x))

in_sector(s::ScanSector, θ) = s.center - s.span/2 ≤ θ ≤ s.center + s.span/2
