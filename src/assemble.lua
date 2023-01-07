local decision = {}

decision.skeleton = {}

local pos = vec2(300, 0)

function decision.skeleton.patrol(entity)
    return {
        score = 0.1,
        func = ai.move_horizontal,
        args = {entity, 1000, 100}
    }
end

local function is_neutral_filter(item)
    return item:ensure(nw.component.team) == constant.team.foe
end

local function damage_assemble(entity)
    return entity:set(nw.component.damage, 2)
end

local function attack_task(ctx, entity, other)
    ai.move_to_entity(ctx, entity, other, 200, 50)
    ai.melee_hitbox(ctx, entity, spatial(50, -20, 10, 10), 0.2, damage_assemble)
    ai.wait(ctx, 0.5)
end

function decision.skeleton.go_to_mine(entity)
    local nearest_mine, nearest_dist = ai.find_nearest(entity, is_neutral_filter)
    local score = math.max(0, 1.0 - nearest_dist / 100)
    return {
        score = score,
        func =  attack_task,
        args =  {entity, nearest_mine}
    }
end

local assemble = {}

local skeleton = {}

function assemble.skeleton(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(50, 100)
        )
        :set(nw.component.gravity)
        :set(nw.component.decision, decision.skeleton)
        :set(nw.component.team, constant.team.player)
end

function assemble.tile(entity, x, y, w, h)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, spatial(0, 0, w, h)
        )
        :set(nw.component.is_terrain)
end

function assemble.mine(entity, x, y)
    entity
        :assemble(
            nw.system.collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 20)
        )
        :set(nw.component.health, 20)
        :set(nw.component.team, constant.team.foe)
end

return assemble
