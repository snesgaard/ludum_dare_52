local Base = nw.system.base

local CollisionHelper = Base()

function CollisionHelper:handle_damage(item, other)
    local damage = item:get(nw.component.damage)
    if not damage or ai.same_team(item, other) then return end
    nw.system.combat(self.world):deal_damage(other, damage)
end

function CollisionHelper:handle_collision(item, other)
    local hr = item:ensure(nw.component.hit_registry)
    if hr[other] then return end

    self:handle_damage(item, other)

    hr[other] = true
end

function CollisionHelper.observables(ctx)
    return {
        collision = ctx:listen("collision"):collect()
    }
end

function CollisionHelper.handle_observables(ctx, obs)
    local ch = CollisionHelper.from_ctx(ctx)

    for _, colinfo in ipairs(obs.collision:pop()) do
        local item = colinfo.ecs_world:entity(colinfo.item)
        local other = colinfo.ecs_world:entity(colinfo.other)
        ch:handle_collision(item, other)
        ch:handle_collision(other, item)
    end
end

return CollisionHelper
