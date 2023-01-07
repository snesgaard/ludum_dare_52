local system = require "system"

return function(ctx)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.system.collision().get_bump_world(ecs_world)

    local obs = system.observables_and_system(ctx)
    local draw = ctx:listen("draw"):collect()

    ecs_world:entity():assemble(assemble.skeleton, 100, 100)
    ecs_world:entity():assemble(assemble.tile, 0, 200, 1400, 200)
    ecs_world:entity():assemble(assemble.mine, 400, 200)

    ctx:spin(function()
        system.handle_observables(ctx, obs, ecs_world)
        for _, _ in ipairs(draw:pop()) do
            painter.draw(ecs_world)
            bump_debug.draw_world(bump_world)
        end
    end)
end
