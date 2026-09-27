-- Built-in overlay inspired by Wobin/Preysight. Uses only native UI drawing.
local mod = get_mod("VersusMode")
local HudElementVersusNightVision = class("HudElementVersusNightVision", "HudElementBase")
local definitions = { scenegraph_definition = {}, widget_definitions = {} }
HudElementVersusNightVision.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusNightVision.super.init(self, parent, draw_layer, start_scale, definitions)
end
HudElementVersusNightVision.draw = function(self, dt, t, ui_renderer)
    local vision = mod._night_vision
    local weight = vision and vision.optics.weight() * (vision.tint or 0) or 0
    if weight <= 0 or (Managers.ui and Managers.ui:has_active_view()) then return end
    local width, height = Gui.resolution()
    local gui = ui_renderer.gui
    local z = self._draw_layer or 0
    Gui.rect(gui, Vector3(0, 0, z), Vector3(width, height, 0), Color(math.floor(48 * weight), 64, 255, 26))
end
return HudElementVersusNightVision