local mod = get_mod("VersusMode")
local HudElementVersusMeleeMarker = class("HudElementVersusMeleeMarker", "HudElementBase")
local definitions = { scenegraph_definition = {}, widget_definitions = {} }

HudElementVersusMeleeMarker.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusMeleeMarker.super.init(self, parent, draw_layer, start_scale, definitions)
end

HudElementVersusMeleeMarker.draw = function(self, dt, t, ui_renderer)
    if Managers.ui and Managers.ui:has_active_view() then return end
    local flight = Managers.free_flight
    if not flight or not flight:is_in_free_flight() then return end
    local ok, camera = pcall(flight.camera, flight, "global")
    if not ok or not camera then return end
    local data = mod.melee_marker_hud_data()
    if not data then return end
    local gui, z = ui_renderer.gui, self._draw_layer or 0
    local function project(position)
        if Camera.inside_frustum(camera, position) <= 0 then return nil end
        local point, distance = Camera.world_to_screen(camera, position)
        return point and distance and distance > 0 and point or nil
    end
    local center = data.area_position or data.position
    local radius = data.area_radius or 0.65
    local projected_center = project(center)
    local edge_color, fill_color = Color(240, 255, 35, 35), Color(45, 255, 25, 25)
    local segments = 48
    local first, previous
    for i = 0, segments do
        local angle = i / segments * math.pi * 2
        local current = i == segments and first
            or project(center + Vector3(math.cos(angle) * radius, math.sin(angle) * radius, 0))
        if i == 0 then first = current end
        if previous and current then
            local dx, dy = current.x - previous.x, current.y - previous.y
            local length = math.sqrt(dx * dx + dy * dy)
            if length > 0.01 then
                local offset = Vector3(-dy / length * 1.5, dx / length * 1.5, 0)
                Gui.triangle(gui, previous - offset, current - offset, current + offset, z + 1, edge_color)
                Gui.triangle(gui, previous - offset, current + offset, previous + offset, z + 1, edge_color)
                if projected_center then
                    Gui.triangle(gui, projected_center, previous, current, z, fill_color)
                end
            end
        end
        previous = current
    end
    if Camera.inside_frustum(camera, data.position) <= 0 then return end
    local point, distance = Camera.world_to_screen(camera, data.position)
    if not point or not distance or distance <= 0 then return end
    local color = edge_color
    -- World-projected marker follows the real free-flight camera in either view.
    Gui.rect(gui, Vector3(point.x - 2, point.y - 2, z), Vector3(4, 4, 0), color)
    Gui.rect(gui, Vector3(point.x - 11, point.y - 1, z), Vector3(6, 2, 0), color)
    Gui.rect(gui, Vector3(point.x + 5, point.y - 1, z), Vector3(6, 2, 0), color)
    Gui.rect(gui, Vector3(point.x - 1, point.y - 11, z), Vector3(2, 6, 0), color)
    Gui.rect(gui, Vector3(point.x - 1, point.y + 5, z), Vector3(2, 6, 0), color)
end

return HudElementVersusMeleeMarker
