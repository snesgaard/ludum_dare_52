local function rng(min, max)
    local min = min or 0
    local max = max or 1
    local r = love.math.random()
    return max * r + min * (1 - r)
end

local decision = {}

decision.skeleton = {}

local pos = vec2(300, 0)

local function dead_task(ctx, entity)
    entity:set(nw.component.frame, get_atlas("art/characters"):get_frame("skeleton/dead"))
    ctx:spin()
end

function decision.skeleton.dead(entity)
    return {
        score = nw.system.combat().is_alive(entity) and 0 or math.huge,
        func = dead_task,
        args = {entity}
    }
end

function decision.skeleton.patrol(entity)
    local pos = entity:get(nw.component.position)
    local dst = pos.x <= 950 and 1000 or 100
    return {
        score = nw.system.decision().is_busy(entity) and 0 or 0.01,
        func = ai.move_horizontal,
        args = {entity, dst, 100}
    }
end

local function is_neutral_filter(item)
    return ai.opposing_team()
end

local function damage_assemble(entity)
    return entity:set(nw.component.damage, 2)
end

local function attack_task(ctx, entity, other)
    ai.move_to_entity(ctx, entity, other, 200, 50)
    entity:set(
        nw.component.frame,
        get_atlas("art/characters"):get_frame("skeleton/claw_anticipation")
    )
    ai.wait(ctx, 0.2)
    local anime = nw.animation.from_aseprite(
        "art/characters", "skeleton/claw_action"
    )
    local player = nw.animation.player(anime)
        :play_once()
        :on_update(function(value, prev_values)
            entity:set(nw.component.frame, value.frame)
        end)
    player:spin(ctx)
    ai.melee_hitbox(ctx, entity, spatial(50, -20, 10, 10), 0.2, damage_assemble)
    ai.wait(ctx, love.math.random(3, 5) / 10.0)
    entity:set(
        nw.component.frame,
        get_atlas("art/characters"):get_frame("skeleton/idle")
    )
end

local function proj_assemble(entity)
    entity
        :set(nw.component.damage, 1)
        :set(nw.component.drawable, nw.drawable.body)
        :set(nw.component.color, 1, 1, 1)
end

local function shoot_task(ctx, entity, target)
    local v = ai.vector_between(entity, target)
    ai.turn_towards(ctx, entity, target)
    local mag = math.max(0, 100 - math.abs(v.x))
    ai.move_to(ctx, entity, v.x < 0 and mag or -mag, 50)
    ai.turn_towards(ctx, entity, target)
    ai.projectile(
        ctx, entity, spatial(50, -20, 10, 10), 5, vec2(1000, 0), proj_assemble
    )
    ai.wait(ctx, rng(0.3, 0.5))
end

function decision.skeleton.shoot(entity)
    local nearest_mine, nearest_dist = ai.find_nearest(
        entity,
        function(other)
            local is_alive = nw.system.combat().is_alive(other)
            return ai.opposing_team(entity, other) and is_alive
        end
    )
    local score = nearest_dist and  math.max(0, 1.0 - nearest_dist / 150) or 0
    return {
        score = score,
        func = shoot_task,
        args = {entity, nearest_mine}
    }
end

function decision.skeleton.go_to_mine(entity)
    local nearest_mine, nearest_dist = ai.find_nearest(
        entity,
        function(other)
            local is_alive = nw.system.combat().is_alive(other)
            return ai.opposing_team(entity, other) and is_alive
        end
    )
    local score = nearest_dist and math.max(0, 1.0 - nearest_dist / 200) or 0
    return {
        score = score,
        func =  attack_task,
        args =  {entity, nearest_mine}
    }
end

local assemble = {}

local skeleton = {}

function skeleton.should_decide(entity)
    local task = entity:get(nw.component.task)
    if not task or not task:is_alive() then return true end
    local should_die = not nw.system.combat().is_alive(entity) and task.system ~= dead_task
    return task.system == ai.move_horizontal or should_die
end

function assemble.skeleton(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(32, 32)
        )
        :set(nw.component.gravity)
        :set(nw.component.decision, decision.skeleton)
        :set(nw.component.team, constant.team.foe)
        :set(nw.component.drawable, nw.drawable.frame)
        :set(nw.component.frame, get_atlas("art/characters"):get_frame("skeleton/idle"))
        :set(nw.component.health, 10)
        :set(nw.component.should_decide, skeleton.should_decide)
end

function assemble.tile(entity, x, y, w, h)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, spatial(0, 0, w, h)
        )
        :set(nw.component.is_terrain)
        :set(nw.component.drawable, nw.drawable.body)
end

function assemble.mine(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 20)
        )
        :set(nw.component.health, 20)
        :set(nw.component.team, constant.team.foe)
        :set(nw.component.drawable, nw.drawable.body)
end

function assemble.player(entity, x, y)
    local decision = require "script.player"
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(32, 32)
        )
        :set(nw.component.health, 20)
        :set(nw.component.decision, decision.decision)
        :set(nw.component.should_decide, decision.should_decide)
        :set(nw.component.gravity)
        :set(nw.component.team, constant.team.player)
        :set(nw.component.drawable, nw.drawable.frame)
end

return assemble
