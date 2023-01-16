local component = {}

function component.is_terrain() return true end

function component.gravity(v) return v or vec2(0, 750) end

function component.patrol(p) return p end

function component.team(t) return t or constant.team.neutral end

function component.damage(d) return d or 0 end

function component.health(hp) return hp or 0 end

function component.is_ghost() return true end

function component.hit_registry(hr) return hr or dict() end

function component.invincible(v) return true end

function component.dont_interrupt() return true end

return component
