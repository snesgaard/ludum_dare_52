local Base = nw.system.base

local Input = Base()

Input.component = {}

function Input.component.input_buffer()
    return {}
end

function Input.input_assemble(entity, key)
    return entity
        :set(nw.component.timer, 1.0)
        :set(nw.component.die_on_timer_complete)
end

function Input:keypressed(key, ecs_world)
    local buffer = ecs_world:ensure(Input.component.input_buffer, "__global__")
    if buffer[key] then buffer[key]:destroy() end
    buffer[key] = ecs_world:entity():assemble(Input.input_assemble)
end

function Input.observables(ctx)
    return {
        keypressed = ctx:listen("keypressed"):collect()
    }
end

function Input.handle_observables(ctx, obs, ecs_world)
    local input = Input.from_ctx(ctx)

    for _, key in ipairs(obs.keypressed:pop()) do
        input:keypressed(key[1], ecs_world)
    end
end

function Input.peek(entity_or_world, key)
    local ecs_world = entity_or_world.world and entity_or_world:world() or entity_or_world
    local buffer = ecs_world:ensure(Input.component.input_buffer, "__global__")
    local k = buffer[key]
    if not k then return false end
    local t = k:get(nw.component.timer)
    if not t then return false end
    return not t:done(), buffer
end

function Input.pop(entity_or_world, key)
    local is_down, buffer =  Input.peek(entity_or_world, key)
    if is_down and buffer and buffer[key] then
        buffer[key]:destroy()
        buffer[key] = nil
    end
    return is_down
end

return Input
