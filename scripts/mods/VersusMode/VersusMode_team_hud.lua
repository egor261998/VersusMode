local mod = get_mod("VersusMode")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local HudElementVersusTeam = class("HudElementVersusTeam", "HudElementBase")

local function text_style(size, y)
    local style = table.clone(UIFontSettings.body)
    style.font_size = size
    style.text_color = { 255, 235, 235, 225 }
    style.offset = { 68, y, 3 }
    style.size = { 246, 25 }
    return style
end

local function visible(content) return content.visible end
local row_definition = UIWidget.create_definition({
    { pass_type = "rect", style = { color = { 195, 20, 28, 31 }, size = { 324, 76 } }, visibility_function = visible },
    { pass_type = "texture", value_id = "portrait", value = "content/ui/materials/dividers/skull_rendered_center_01",
        style = { size = { 56, 56 }, offset = { 6, 8, 2 }, color = { 255, 255, 255, 255 } }, visibility_function = visible },
    { pass_type = "text", value_id = "name", value = "", style = text_style(20, 0), visibility_function = visible },
    { pass_type = "text", value_id = "label", value = "", style = text_style(16, 23), visibility_function = visible },
    { pass_type = "rect", style_id = "health_back", style = { size = { 246, 15 }, offset = { 68, 53, 1 }, color = { 255, 45, 35, 35 } }, visibility_function = visible },
    { pass_type = "rect", style_id = "health_fill", style = { size = { 246, 15 }, offset = { 68, 53, 2 }, color = { 255, 160, 60, 45 } }, visibility_function = visible },
    { pass_type = "text", value_id = "status", value = "", style = text_style(15, 48), visibility_function = visible },
}, "team", { visible = false })

HudElementVersusTeam.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusTeam.super.init(self, parent, draw_layer, start_scale, {
        scenegraph_definition = {
            screen = { scale = "fit", size = { 1920, 1080 }, position = { 0, 0, 0 } },
            team = { parent = "screen", horizontal_alignment = "right", vertical_alignment = "top",
                size = { 324, 76 }, position = { -25, 205, 80 } },
        },
        widget_definitions = {},
    })
    self._team_rows = {}
end

HudElementVersusTeam.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    HudElementVersusTeam.super.update(self, dt, t, ui_renderer, render_settings, input_service)
    local rows = mod.heretic_team_hud_data()
    local hidden = Managers.ui and Managers.ui:has_active_view()
    for i = 1, math.max(#rows, #self._team_rows) do
        local widget = self._team_rows[i]
        if not widget then
            widget = UIWidget.init("heretic_team_" .. i, row_definition)
            self._team_rows[i] = widget
            self._widgets[#self._widgets + 1] = widget
        end
        local row = rows[i]
        widget.content.visible = row ~= nil and not hidden
        if row then
            -- Additional columns keep large Realms teams on screen.
            widget.offset[1] = -math.floor((i - 1) / 9) * 334
            widget.offset[2] = (i - 1) % 9 * 82
            widget.content.name = row.name
            widget.content.label = row.label
            widget.content.portrait = row.portrait
            local has_health = row.alive and row.health and row.maximum
            widget.style.health_fill.size[1] = has_health and 246 * math.min(1, row.health / row.maximum) or 0
            widget.content.status = has_health and string.format("%d / %d", math.floor(row.health), math.floor(row.maximum))
                or row.alive and "—" or row.status
        end
    end
end

return HudElementVersusTeam
