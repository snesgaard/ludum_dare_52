local system = {}

nw.system.collision_helper = require "system.collision_helper"
nw.system.combat = require "system.combat"
nw.system.damage_number = require "system.damage_number"

system.system = list(
    nw.system.damage_number,
    nw.system.timer,
    nw.system.motion,
    nw.system.camera,
    nw.system.combat,
    nw.system.collision_helper,
    nw.system.script,
    nw.system.decision
)

local function observables(sys, ctx)
    if type(sys) == "function" then
        return sys().observables(ctx)
    elseif type(sys) == "table" then
        return sys.observables(ctx)
    end
end

function system.observables_and_system(ctx)
    local obs_sys = list()

    for _, sys in ipairs(system.system) do
        local o = {
            system = sys,
            obs = observables(sys, ctx)
        }

        table.insert(obs_sys, o)
    end

    return obs_sys
end

local function handle_observables(sys, ctx, obs, ...)
    if type(sys) == "function" then
        return sys().handle_observables(ctx, obs, ...)
    elseif type(sys) == "table" and sys.handle_observables then
        return sys.handle_observables(ctx, obs, ...)
    end
end

function system.handle_observables(ctx, obs_sys, ecs_world)
    for _, o in ipairs(obs_sys) do
        handle_observables(o.system, ctx, o.obs, ecs_world)
    end
end

return system
