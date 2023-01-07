local component = {}

function component.damage_number(num)
    return num
end

local function drawable(entity)
    nw.drawable.push_transform(entity)
    nw.drawable.push_state(entity)
    local num = entity:get(component.damage_number)
    local hb = entity:get(nw.component.hitbox) or spatial()
    if not num then return end
    painter.text(num, hb.x, hb.y, hb.w, hb.h, {align="center"})
end

local assemble = {}

function assemble.damage_number(entity, x, y, num)
    entity
        :set(nw.component.position, x, y)
        :set(nw.component.color, 0.9, 0.3, 0.2)
        :set(component.damage_number, num)
        :set(nw.component.drawable, drawable)
        :set(nw.component.timer, 0.4)
        :set(nw.component.die_on_timer_complete)
        :set(nw.component.layer, painter.layer.ui)
        :set(nw.component.hitbox, spatial():expand(150, 50):unpack())
end

local DamageNumber = nw.system.base()

function DamageNumber.damage_number_from_info(info)
    local hb = nw.system.collision().read_bump_hitbox(info.entity)
    local area = hb:up(0, 0, 150, 50, "center"):center()
    info.entity:world():entity()
        :assemble(assemble.damage_number, area.x, area.y, info.damage)
end

function DamageNumber.observables(ctx)
    return {
        update = ctx:listen("update"):collect(),
        damage = ctx:listen("on_damage"):collect()
    }
end

function DamageNumber.handle_observables(ctx, obs, ecs_world)
    for _, info in ipairs(obs.damage:pop()) do
        DamageNumber.damage_number_from_info(info)
    end
end

return DamageNumber.from_ctx
