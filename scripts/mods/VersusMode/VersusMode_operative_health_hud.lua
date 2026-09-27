local mod = get_mod("VersusMode")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIHudSettings = require("scripts/settings/ui/ui_hud_settings")
local HudElementVersusOperativeHealth = class("HudElementVersusOperativeHealth", "HudElementBase")

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function read_vitals(unit)
    local health = ScriptUnit.has_extension(unit, "health_system")
    local toughness = ScriptUnit.has_extension(unit, "toughness_system")
    if not health or not toughness then return nil end
    local maximum, current = health:max_health(), health:current_health()
    local toughness_max = toughness:max_toughness()
    local toughness_base = toughness:max_toughness_visual()
    local toughness_current = toughness_max == 0 and 0 or toughness:current_toughness_percent() * toughness_max
    if not finite(maximum) or maximum <= 0 or not finite(current)
        or not finite(toughness_max) or toughness_max < 0
        or not finite(toughness_base) or toughness_base < 0
        or not finite(toughness_current) then return nil end
    current = math.max(0, math.min(maximum, current))
    toughness_current = math.max(0, math.min(toughness_max, toughness_current))
    local bonus = math.max(0, toughness_current - toughness_base)
    return {
        health = current, maximum = maximum,
        toughness = math.min(toughness_base, toughness_current), toughness_max = toughness_base,
        bonus = math.floor(bonus),
    }
end

local function head_position(unit)
    local node = Unit.has_node(unit, "j_head") and Unit.node(unit, "j_head")
    return node and Unit.world_position(unit, node) or Unit.world_position(unit, 1) + Vector3(0, 0, 1.6)
end

local function unobstructed(physics, origin, target, unit, state)
    local delta = target - origin
    local distance = Vector3.length(delta)
    if distance < 0.01 then return true end
    -- Same collision filter as native world markers; inspect all hits so the
    -- possessed body cannot hide a wall farther down the ray.
    local hits = PhysicsWorld.raycast(physics, origin, delta / distance, distance,
        "all", "types", "both", "collision_filter", "filter_interactable_line_of_sight_marker_check")
    for _, hit in ipairs(hits or {}) do
        local actor = hit[4]
        local hit_unit = actor and Actor.unit(actor)
        if not hit_unit or hit_unit ~= unit and hit_unit ~= state.unit and hit_unit ~= state.player_unit then
            return false
        end
    end
    return true
end

local function visible(content) return content.visible end
local function text_style(y)
    local style = table.clone(UIFontSettings.body)
    style.font_size = 16
    style.text_horizontal_alignment = "center"
    style.text_vertical_alignment = "center"
    style.text_color = { 255, 255, 255, 255 }
    style.offset = { 0, y, 3 }
    style.size = { 180, 20 }
    return style
end
local definition = UIWidget.create_definition({
    { pass_type = "rect", style = { size = { 184, 44 }, offset = { -2, -2, 0 }, color = { 210, 12, 16, 20 } }, visibility_function = visible },
    { pass_type = "rect", style_id = "health", style = { size = { 180, 20 }, offset = { 0, 0, 1 }, color = { 255, 55, 110, 65 } }, visibility_function = visible },
    { pass_type = "rect", style_id = "toughness", style = { size = { 180, 20 }, offset = { 0, 22, 1 }, color = table.clone(UIHudSettings.color_tint_6) }, visibility_function = visible },
    { pass_type = "text", value_id = "health", value = "", style = text_style(0), visibility_function = visible },
    { pass_type = "text", value_id = "toughness", value = "", style = text_style(22), visibility_function = visible },
}, "markers", { visible = false })

local damage_definition = UIWidget.create_definition({
    { pass_type = "text", style_id = "number", value_id = "number", value = "", style = text_style(0), visibility_function = visible },
}, "markers", { visible = false })

HudElementVersusOperativeHealth.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusOperativeHealth.super.init(self, parent, draw_layer, start_scale, {
        scenegraph_definition = {
            screen = { scale = "fit", size = { 1920, 1080 }, position = { 0, 0, 0 } },
            markers = { parent = "screen", horizontal_alignment = "left", vertical_alignment = "top",
                size = { 0, 0 }, position = { 0, 0, 93 } },
        }, widget_definitions = {},
    })
    self._rows = {}
    self._damage_rows = {}
    self._projections = {}
    self._projection_frame = 0
end

HudElementVersusOperativeHealth._project = function(self, unit, state, camera, origin, for_damage)
    local entry = self._projections[unit]
    if not entry then entry = {}; self._projections[unit] = entry end
    if entry.frame ~= self._projection_frame then
        entry.frame = self._projection_frame
        entry.checked, entry.visible = false, false
        entry.health_allowed, entry.damage_allowed = nil, nil
        entry.x, entry.y, entry.bar_x, entry.bar_y = nil, nil, nil, nil
    end
    local key = for_damage and "damage_allowed" or "health_allowed"
    if entry[key] == nil then
        entry[key] = (for_damage and mod.operative_damage_hud_target(unit)
            or not for_damage and mod.operative_health_hud_target(unit)) == true
    end
    if not entry[key] then return nil end
    if not entry.checked then
        entry.checked = true
        local ok, head = pcall(head_position, unit)
        if ok and Camera.inside_frustum(camera, head) > 0 then
            local los_ok, los = pcall(unobstructed, state.physics_world, origin, head, unit, state)
            entry.visible = los_ok and los
            if entry.visible then entry.wx, entry.wy, entry.wz = head.x, head.y, head.z end
        end
    end
    if not entry.visible then return nil end
    local x_key, y_key = for_damage and "x" or "bar_x", for_damage and "y" or "bar_y"
    if entry[x_key] == nil then
        local point, distance = Camera.world_to_screen(camera, Vector3(entry.wx, entry.wy, entry.wz + (for_damage and 0 or 0.35)))
        if not point or not distance or distance <= 0 then return nil end
        entry[x_key], entry[y_key] = point.x, point.y
    end
    return entry[x_key], entry[y_key]
end

HudElementVersusOperativeHealth._update_damage = function(self, state, camera, origin, ui_renderer, t)
    local events = mod._damage_feedback and mod._damage_feedback.events or {}
    t = mod._damage_feedback and mod._damage_feedback:time() or t
    for i, event in ipairs(events) do
        local age = t - event.started
        if age >= 0 and age < 1.2 then
            local x, y = self:_project(event.unit, state, camera, origin, true)
            if x then
                local widget = self._damage_rows[i]
                if not widget then
                    widget = UIWidget.init("operative_damage_" .. i, damage_definition)
                    self._damage_rows[i] = widget
                    self._widgets[#self._widgets + 1] = widget
                end
                local is_health = event.kind == "health"
                local color = widget.style.number.text_color
                color[1] = math.floor(255 * math.min(1, (1.2 - age) / 0.4))
                color[2], color[3], color[4] = is_health and 255 or 80, is_health and 70 or 175, is_health and 70 or 255
                widget.style.number.font_size = 22 + 5 * math.max(0, 1 - age / 0.2)
                if widget._value ~= event.value then
                    widget.content.number = tostring(math.max(1, math.floor(event.value + 0.5)))
                    widget._value = event.value
                end
                local scale = ui_renderer.inverse_scale or 1
                widget.offset[1] = x * scale - 90 + (is_health and 45 or -45)
                widget.offset[2] = y * scale - 65 - 45 * age
                widget.content.visible = true
            end
        end
    end
end

HudElementVersusOperativeHealth.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    HudElementVersusOperativeHealth.super.update(self, dt, t, ui_renderer, render_settings, input_service)
    for _, widget in ipairs(self._rows) do widget.content.visible = false end
    for _, widget in pairs(self._damage_rows) do widget.content.visible = false end
    self._projection_frame = self._projection_frame + 1
    local state = mod.operative_health_hud_context()
    if not state or not state.physics_world or not ui_renderer
        or Managers.ui and Managers.ui:has_active_view() then
        for _, widget in ipairs(self._rows) do widget._unit = nil; widget._vitals = nil end
        for unit in pairs(self._projections) do self._projections[unit] = nil end
        return
    end
    local flight = Managers.free_flight
    if not flight or not flight:is_in_free_flight() then return end
    local camera_ok, camera = pcall(flight.camera, flight, "global")
    if not camera_ok or not camera then return end
    local origin = Camera.world_position(camera)
    self:_update_damage(state, camera, origin, ui_renderer, t)
    local players = Managers.player and Managers.player:players()
    self._refresh_in = (self._refresh_in or 0) - dt
    local refresh = self._refresh_in <= 0
    if refresh then self._refresh_in = 0.1 end
    local index = 0
    for _, player in pairs(players or {}) do
        local unit = player.player_unit
        if unit and ALIVE[unit] then
            local x, y = self:_project(unit, state, camera, origin, false)
            if x then
                index = index + 1
                local widget = self._rows[index]
                if not widget then
                    widget = UIWidget.init("operative_health_" .. index, definition)
                    self._rows[index] = widget
                    self._widgets[#self._widgets + 1] = widget
                end
                if refresh or widget._unit ~= unit then
                    local ok, vitals = pcall(read_vitals, unit)
                    widget._unit, widget._vitals = unit, ok and vitals or nil
                    if widget._vitals then
                        widget.content.health = mod:localize("operative_health_value", math.floor(vitals.health), math.floor(vitals.maximum))
                        widget.content.toughness = mod:localize("operative_toughness_value", math.floor(vitals.toughness), math.floor(vitals.toughness_max))
                            .. (vitals.bonus > 0 and " +" .. vitals.bonus or "")
                        widget.style.health.size[1] = 180 * vitals.health / vitals.maximum
                        widget.style.toughness.size[1] = vitals.toughness_max > 0 and 180 * vitals.toughness / vitals.toughness_max or 0
                        local color = vitals.bonus > 0 and UIHudSettings.color_tint_10 or UIHudSettings.color_tint_6
                        for i = 1, 4 do widget.style.toughness.color[i] = color[i] end
                    end
                end
                -- Projected coordinates are numbers; never retain temporary Vector3 userdata.
                local scale = ui_renderer.inverse_scale or 1
                widget.offset[1], widget.offset[2] = x * scale - 90, y * scale - 44
                widget.content.visible = widget._vitals ~= nil
            end
        end
    end
    for i = index + 1, #self._rows do
        self._rows[i]._unit = nil
        self._rows[i]._vitals = nil
    end
    for unit, entry in pairs(self._projections) do
        if entry.frame ~= self._projection_frame then self._projections[unit] = nil end
    end
end

-- Pools retain their peak size after a busy fight. Skip hidden widgets before
-- UIWidget.draw, not only inside each pass's visibility function.
HudElementVersusOperativeHealth._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
    for i = 1, #self._widgets do
        local widget = self._widgets[i]
        if widget.content.visible then
            UIWidget.draw(widget, ui_renderer)
        end
    end
end
return HudElementVersusOperativeHealth
