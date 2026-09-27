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
    if not data or Camera.inside_frustum(camera, data.position) <= 0 then return end
    local point, distance = Camera.world_to_screen(camera, data.position)
    if not point or not distance or distance <= 0 then return end
    local gui, z = ui_renderer.gui, self._draw_layer or 0
    local color = data.kind == "contact" and Color(240, 255, 110, 80)
        or data.kind == "target" and Color(240, 100, 240, 255)
        or Color(240, 255, 210, 90)
    -- World-projected marker follows the real free-flight camera in either view.
    Gui.rect(gui, Vector3(point.x - 2, point.y - 2, z), Vector3(4, 4, 0), color)
    Gui.rect(gui, Vector3(point.x - 11, point.y - 1, z), Vector3(6, 2, 0), color)
    Gui.rect(gui, Vector3(point.x + 5, point.y - 1, z), Vector3(6, 2, 0), color)
    Gui.rect(gui, Vector3(point.x - 1, point.y - 11, z), Vector3(2, 6, 0), color)
    Gui.rect(gui, Vector3(point.x - 1, point.y + 5, z), Vector3(2, 6, 0), color)
end

return HudElementVersusMeleeMarker
