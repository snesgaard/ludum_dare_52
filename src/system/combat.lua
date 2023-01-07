local Base = nw.system.base
local Combat = Base()

function Combat:deal_damage(other, damage)
    local health = other:get(nw.component.health)
    if not health then return end
    local real_damage = math.min(health, damage)
    local next_health = health - real_damage
    local info = {
        entity = other,
        damage = real_damage,
        health = next_health
    }
    other:set(nw.component.health, next_health)
    self:emit("on_damage", info)
end

function Combat:is_alive(item)
    local health = other:get(nw.component.health) or 0
    return 0 < health
end

return Combat.from_ctx
