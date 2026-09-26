-- Built-in overlay inspired by Wobin/Preysight. Uses only native UI drawing.
local mod = get_mod("VersusMode")
local HudElementVersusNightVision = class("HudElementVersusNightVision", "HudElementBase")
local definitions = { scenegraph_definition = {}, widget_definitions = {} }
HudElementVersusNightVision.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusNightVision.super.init(self, parent, draw_layer, start_scale, definitions)
end
HudElementVersusNightVision.draw = function(self, dt, t, ui_renderer)
    local vision = mod._night_vision
    local weight = vision and vision.optics.weight() or 0
    if weight <= 0 or (Managers.ui and Managers.ui:has_active_view()) then return end
    local width, height = Gui.resolution()
    local gui = ui_renderer.gui
    local z = self._draw_layer or 0
    Gui.rect(gui, Vector3(0, 0, z), Vector3(width, height, 0), Color(math.floor(64 * weight), 64, 255, 26))
    -- Procedural lines and sparse moving grain need no texture loader or assets.
    local spacing = math.max(6, math.floor(height / 120))
    for y = 0, height, spacing do
        Gui.rect(gui, Vector3(0, y, z + 1), Vector3(width, 1, 0), Color(math.floor(18 * weight), 0, 0, 0))
    end
    local frame = math.floor((t or 0) * 12)
    for i = 1, 64 do
        local x = (i * 173 + frame * 37) % math.max(1, width)
        local y = (i * 97 + frame * 53) % math.max(1, height)
        Gui.rect(gui, Vector3(x, y, z + 2), Vector3(2, 2, 0), Color(math.floor(20 * weight), 160, 255, 130))
    end
    Gui.bitmap(gui, "content/ui/materials/masks/gradient_vignette", Vector3(0, 0, z + 3),
        Vector3(width, height, 0), Color(math.floor(204 * weight), 0, 0, 0))
end
return HudElementVersusNightVision