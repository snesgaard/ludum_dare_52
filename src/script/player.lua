local function x_dir()
    local x = 0
    if love.keyboard.isDown("left") then x = x - 1 end
    if love.keyboard.isDown("right") then x = x + 1 end

    return x
end

return function(ctx, entity)
    local update = ctx:listen("update"):collect()

    ctx:spin(function()
        update:pop():foreach(function(dt)
            local x = x_dir()
            local speed = 200
            nw.system.collision(ctx):move(entity, x * speed * dt, 0)
        end)
    end)

end
