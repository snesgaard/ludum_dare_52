local component = {}

function component.player(animation)
    return nw.animation.player(animation)
end

function component.hitbox_slices(slices)
    return slices or {}
end

local assemble = {}

function assemble.slice_hitbox()

end

local function update_slices(entity, frame)
    local next_slices = frame.slices
    local slices = entity:ensure(component.hitbox_slices)

    for _, s in pairs(slices) do s:destroy() end

    local next_hitbox_slices = dict()
    local pos = entity:get(nw.component.position)
    if not pos then return end

    for id, slice in pairs(next_slices) do
        local slice = frame:get_slice(id, "body")
        next_hitbox_slices[id] = entity:world():entity()
            :set(nw.component.team, entity:get(nw.component.team))
            :set(nw.component.mirror, entity:get(nw.component.mirror))
            :set(nw.component.parent, entity.id)
            :assemble(
                nw.system.collision().assemble.init_entity,
                pos.x, pos.y, slice
            )
            :set(nw.component.velocity, 0, 0)
            :set(nw.component.is_ghost)
            :assemble(nw.system.follow().follow, entity)
    end

    entity:set(component.hitbox_slices, next_hitbox_slices)
end

local function on_update(entity, value, prev_value)
    if value.frame ~= prev_value.frame then
        entity:set(nw.component.frame, value.frame)
        update_slices(entity, value.frame)
    end
end

local Animation = nw.system.base()

function Animation.on_entity_destroyed(id, values_destroyed, ecs_world)
    local hitboxes = values_destroyed[component.hitbox_slices]
    if not hitboxes then return end
    for _, hb in pairs(hitboxes) do hb:destroy() end
end

function Animation:play(entity, animation)
    local on_entity_destroyed = entity:world().on_entity_destroyed
    on_entity_destroyed.animation = on_entity_destroyed.animation or Animation.on_entity_destroyed

    local player = self:player(entity)
    if player and player.animation == animation then return player end
    entity:set(component.player, animation)
    local player = entity:get(component.player)
    local value = player:value()
    on_update(entity, value, {})
    return player
end

function Animation:stop(entity)
    entity:remove(component.player)
    return self
end

function Animation:play_once(entity, animation)
    local player = self:play(entity, animation)
    player:play_once()
    return player
end

function Animation:update(entity, player, dt)
    local prev_value = player:value()
    local is_done = player:done()
    player:update(dt)
    local next_value = player:value()
    on_update(entity, next_value, prev_value)
    if player:done() and not is_done then
        self:emit("on_animation_done", entity, player.animation)
    end
end

function Animation:player(entity)
    return entity:get(component.player)
end

function Animation.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function Animation.handle_observables(ctx, obs, ecs_world)
    local sys = Animation.from_ctx(ctx)

    for _, dt in ipairs(obs.update:pop()) do
        local animation_table = ecs_world:get_component_table(component.player)
        for id, player in pairs(animation_table) do
            sys:update(ecs_world:entity(id), player, dt)
        end
    end
end

return Animation.from_ctx
