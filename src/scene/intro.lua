local system = require "system"

return function(ctx)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.system.collision().get_bump_world(ecs_world)

    local obs = system.observables_and_system(ctx)
    local draw = ctx:listen("draw"):collect()

    local skeleton = ecs_world:entity()
        :assemble(assemble.skeleton, 600, 100)
        :set(nw.component.team, constant.team.player)
        :set(nw.component.health, 30)

    local player = ecs_world:entity(constant.id.player)
        :assemble(assemble.player, 100, 100)

    local camera = ecs_world:entity()
        :set(nw.component.camera)
        :set(nw.component.target, player.id)
        :set(nw.component.scale, constant.scale, constant.scale)

    --ecs_world:entity():assemble(assemble.skeleton, 1000, 200):set(nw.component.color, 0, 1, 0)
    ecs_world:entity():assemble(assemble.tile, 0, 200, 1400, 200)
    ecs_world:entity():assemble(assemble.mine, 400, 200)

    local pause = ctx:listen("keypressed")
        :filter(function(p) return p == "p" end)
        :reduce(function(state) return not state end)
        :latest()

    local spawn = ctx:listen("keypressed")
        :filter(function(s) return s == "s" end)
        :collect()

    local draw_bump = ctx:listen("keypressed")
        :filter(function(d) return d == "d" end)
        :reduce(function(state) return not state end, true)
        :latest()

    ctx:spin(function()
        if not pause:peek() then system.handle_observables(ctx, obs, ecs_world) end
        for _, _  in ipairs(spawn:pop()) do
            local x = love.math.random(100, 1000)
            ecs_world:entity():assemble(assemble.skeleton, x, 200)
                :set(nw.component.color, 0, 1, 0)
        end
        for _, _ in ipairs(draw:pop()) do
            gfx.push()
            nw.system.camera.push_transform(camera)
            painter.draw(ecs_world)
            if draw_bump:peek() then bump_debug.draw_world(bump_world) end
            gfx.pop()
        end
    end)
end
