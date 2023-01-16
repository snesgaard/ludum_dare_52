nw = require "nodeworks"
constant = require "constant"
assemble = require "assemble"
ai = require "ai"
painter = require "painter"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

local function collision_filter(ecs_world, item, other)
    local other_is_terrain = ecs_world:get(nw.component.is_terrain, other)

    if ecs_world:get(nw.component.is_ghost, item) then return "cross" end

    return other_is_terrain and "slide" or "cross"
end

nw.system.collision():class().default_filter = collision_filter

function love.load()
    world = nw.ecs.world()
    world:push(require "scene.intro")
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
    world:emit("keypressed", key, scancode, isrepeat):spin()
end

function love.keyreleased(key)
    world:emit("keyreleased", key):spin()
end

function love.update(dt)
    world:emit("update", dt):spin()
end

function love.draw()
    world:emit("draw"):spin()
end
