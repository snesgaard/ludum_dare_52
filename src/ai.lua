local ai = {}

function ai.same_team(item, other)
    return item:ensure(nw.component.team) == other:ensure(nw.component.team)
end

function ai.vector_between(from, to)
    return to:get(nw.component.position) - from:get(nw.component.position)
end

function ai.distance_between(from, to)
    return ai.vector_between(from, to):length()
end

function ai.find_nearest(item, filter)
    local others = item:world()
        :get_component_table(nw.component.position)
        :keys()
        :map(function(id) return item:world():entity(id) end)
        :filter(filter)

    local distances = others
        :map(function(other) return ai.distance_between(item, other) end)

    local closest = distances:argsort():head()
    if not closest then return nw.empty("No entity found") end
    return others[closest], distances[closest]
end

function ai.move_horizontal(ctx, entity, target_x, speed)
    local update = ctx:listen("update"):collect()

    local x_to_target = ctx:listen("moved")
        :filter(function(item) return item.id == entity.id end)
        :latest{entity}
        :map(function()
            local p = entity:get(nw.component.position)
            return target_x - p.x
        end)
        :latest()

    local abs_x_to_target = x_to_target
        :map(math.abs)
        :latest()

    local function move_on_update(dt)
        local step = speed * dt
        local is_there = abs_x_to_target:peek() <= step
        if is_there then
            local pos = entity:get(nw.component.position)
            nw.system.collision(ctx):move_to(entity, target_x, pos.y)
        else
            local s = x_to_target:peek() < 0 and -step or step
            nw.system.collision(ctx):move(entity, s, 0)
        end

        return is_there
    end

    local function move_reductor(is_done, dt)
        return is_done or move_on_update(dt)
    end

    return ctx:spin(function()
        return update:pop():reduce(move_reductor, false)
    end)
end

function ai.move_to_entity(ctx, item, other, speed, margin)
    local update = ctx:listen("update"):collect()
    local margin = margin or 0

    local function move_on_update(dt)
        local step = speed * dt
        local v = ai.vector_between(item, other)
        v.x = v.x + (v.x < 0 and margin or -margin)
        local d = v:length()
        local is_there = d <= step
        if is_there then
            nw.system.collision(ctx):move(item, v.x, 0)
        else
            local s = v.x < 0 and -step or step
            nw.system.collision(ctx):move(item, step, 0)
        end

        return is_there
    end

    local function reduce_move(is_done, dt)
        return is_done or move_on_update(dt)
    end

    return ctx:spin(function()
        return update:pop():reduce(reduce_move, false)
    end)
end

function ai.melee_hitbox(ctx, item, base_hitbox, lifetime, func, ...)
    local pos = item:get(nw.component.position)
    local hb = item:world():entity()
        :set(nw.component.mirror, item:get(nw.component.mirror))
        :set(nw.component.team, item:get(nw.component.team))
        :set(nw.component.is_ghost)
        :assemble(
            nw.system.collision().assemble.init_entity,
            pos.x, pos.y, base_hitbox
        )
        :set(nw.component.velocity, 0, 0)
        :set(nw.component.timer, lifetime)
        :set(nw.component.die_on_timer_complete)

    if func then
        hb:assemble(func, ...)
    end

    return hb
end

function ai.move(ctx, entity, target_position, speed)
    local update = ctx:listen("update"):collect()

    local vector_to_target = ctx:listen("moved")
        :filter(function(item) return item.id == entity.id end)
        :latest{entity}
        :map(function()
            return target_position - entity:get(nw.component.position)
        end)
        :latest()

    local distance_to_target = vector_to_target
        :map(vec2().length)
        :latest()

    local function move_on_update(dt)
        local step = speed * dt
        local v = vector_to_target:peek()
        local l = distance_to_target:peek()
        local is_there = l <= step
        if is_there then
            nw.system.collision(ctx):move_to(
                entity, target_position.x, target_position.y
            )
        else
            local s = v * step / l
            nw.system.collision(ctx):move(entity, s.x, s.y)
        end

        return is_there
    end

    local function move_reductor(is_done, dt)
        return is_done or move_on_update(dt)
    end

    return ctx:spin(function()
        return update:pop():reduce(move_reductor, false)
    end)
end

local function wait_reductor(time, dt) return time - dt end
local function wait_check(time) return time <= 0 end

function ai.wait(ctx, duration)

    local is_done = ctx:listen("update")
        :reduce(wait_reductor, duration)
        :map(wait_check)
        :latest()

    ctx:spin(function() return is_done:peek() end)
end

function ai.patrol(ctx, entity, speed, wait_time)
    while ctx:is_alive() do
        local patrol = entity:get(nw.component.patrol)
        if patrol then
            ai.action.move(ctx, entity, patrol:head(), speed)
            local next_patrol = patrol:body() + list(patrol:head())
            entity:set(nw.component.patrol, next_patrol)
            ai.action.wait(ctx, wait_time)
        end
    end
end

return ai
