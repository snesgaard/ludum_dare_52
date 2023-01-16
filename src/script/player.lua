local atlas = "art/characters"

local animations = {
    run = nw.animation.from_aseprite(atlas, "reaper/run"),
    idle = nw.animation.from_aseprite(atlas, "reaper/idle"),
    strike_aniticipation = nw.animation.from_aseprite(atlas, "reaper/strike_anticipation"),
    strike_action = nw.animation.from_aseprite(atlas, "reaper/strike_action"),
    strike = nw.animation.from_aseprite(atlas, "reaper/strike")
}

local function x_dir()
    local x = 0
    if love.keyboard.isDown("left") then x = x - 1 end
    if love.keyboard.isDown("right") then x = x + 1 end

    return x
end

local function change_dir_based_on_input(entity)
    local x = x_dir()
    if x ~= 0 then
        nw.system.collision(ctx):mirror_to(entity, x < 0)
    end
    return entity:get(nw.component.mirror)
end

local task = {}

function task.idle(ctx, entity)
    local update = ctx:listen("update"):collect()

    ctx:spin(function()
        update:pop():foreach(function(dt)
            change_dir_based_on_input(entity)
            local x = x_dir()
            if x == 0 then
                nw.system.animation(ctx):play(entity, animations.idle)
            else
                nw.system.animation(ctx):play(entity, animations.run)
            end
            local speed = 200
            nw.system.collision(ctx):move(entity, x * speed * dt, 0)
        end)
    end)
end

function task.strike(ctx, entity)
    local update = ctx:listen("update"):collect()
    local player = nw.system.animation(ctx):play_once(entity, animations.strike)
    entity:set(nw.component.dont_interrupt)
    ctx:spin(function()
        return player:done()
    end)
    entity:remove(nw.component.dont_interrupt)
end

function task.dash(ctx, entity)
    local update = ctx:listen("update"):collect()
    local timer = nw.component.timer(0.4)
    local speed = 300
    local x = x_dir()
    if x ~= 0 then
        nw.system.collision(ctx):mirror_to(entity, x < 0)
    end
    local sx = entity:get(nw.component.mirror) and -1 or 1

    entity
        :remove(nw.component.gravity)
        :remove(nw.component.velocity)
        :set(nw.component.invincible)
        :set(nw.component.dont_interrupt)

    ctx:spin(function()
        for _, dt in ipairs(update:pop()) do
            timer:update(dt)
            nw.system.collision(ctx):move(entity, sx * speed * dt, 0)
        end
        return timer:done()
    end)

    entity
        :set(nw.component.gravity)
        :remove(nw.component.dont_interrupt)
        :remove(nw.component.invincible)
end

function task.attack(ctx, entity)
    local x = x_dir()
    if x ~= 0 then
        nw.system.collision(ctx):mirror_to(entity, x < 0)
    end

    entity:set(nw.component.dont_interrupt)
    ai.melee_hitbox(ctx, entity, spatial(50, -20, 10, 10), 0.2)
    ai.wait(ctx, 0.4)
    entity:remove(nw.component.dont_interrupt)
end

local function decision(entity)
    if nw.system.input.pop(entity, "t") then
        return {
            func = task.dash,
            args = {entity}
        }
    elseif nw.system.input.pop(entity, "a") then
        return {
            func = task.strike,
            args = {entity}
        }
    else
        return {
            func = task.idle,
            args = {entity}
        }
    end
end

local function should_decide(entity)
    return not entity:get(nw.component.dont_interrupt)
end

return {
    should_decide = should_decide,
    decision = decision
}
