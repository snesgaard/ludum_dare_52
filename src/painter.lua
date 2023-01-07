local painter = {}

local layers = {
    background = -1,
    player = 1,
    effects = 2,
    ui = 3
}

local function sort_by_position(a, b)
    local pos_a = a:ensure(nw.component.position)
    local pos_b = b:ensure(nw.component.position)

    local dx = pos_a.x - pos_b.x

    if math.abs(dx) > 1 then return pos_a.x < pos_b.x end

    return pos_a.y < pos_b.y
end

local function sort_by_layer(a, b)
    local layer_a = a:ensure(nw.component.layer)
    local layer_b = b:ensure(nw.component.layer)

    if layer_a ~= layer_b then return layer_a < layer_b end

    return sort_by_position(a, b)
end

local function get_entity(id, ecs_world) return ecs_world:entity(id) end

function painter.draw(ecs_world)
    local drawables = ecs_world:get_component_table(nw.component.drawable)
    local entities = drawables
        :keys()
        :map(get_entity, ecs_world)
        :sort(sort_by_layer)

    for _, entity in ipairs(entities) do
        local f = entity:get(nw.component.drawable)
        gfx.push("all")
        f(entity)
        gfx.pop()
    end
end

local function compute_vertical_offset(valign, font, h)
    if valign == "top" then
                return 0
        elseif valign == "bottom" then
                return h - font:getHeight()
    else
        return (h - font:getHeight()) / 2
        end
end

function painter.text(text, x, y, w, h, opt, sx, sy)
    local opt = opt or {}
    if opt.font then gfx.setFont(opt.font) end

    local dy = compute_vertical_offset(opt.valign, gfx.getFont(), h)

    gfx.printf(text, x, y + dy, w, opt.align or "left")
end



painter.layer = layers

return painter
