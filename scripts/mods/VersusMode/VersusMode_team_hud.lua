local mod = get_mod("VersusMode")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local HudElementVersusTeam = class("HudElementVersusTeam", "HudElementBase")

local function text_style(size, y)
    local style = table.clone(UIFontSettings.body)
    style.font_size = size
    style.text_color = { 255, 235, 235, 225 }
    style.offset = { 116, y, 3 }
    style.size = { 274, 25 }
    return style
end

local function visible(content) return content.visible end
local function detailed(content) return content.visible and not content.compact end
local row_definition = UIWidget.create_definition({
    { pass_type = "rect", style_id = "background", style = { color = { 195, 20, 28, 31 }, size = { 400, 116 } }, visibility_function = visible },
    { pass_type = "logic", value_id = "draw_portrait", value = mod._portraits.draw,
        style = { size = { 100, 100 }, offset = { 8, 8, 2 }, color = { 255, 255, 255, 255 } }, visibility_function = detailed },
    { pass_type = "text", style_id = "name", value_id = "name", value = "", style = text_style(20, 12), visibility_function = visible },
    { pass_type = "text", value_id = "label", value = "", style = text_style(16, 39), visibility_function = detailed },
    { pass_type = "rect", style_id = "health_back", style = { size = { 274, 18 }, offset = { 116, 82, 1 }, color = { 255, 45, 35, 35 } }, visibility_function = detailed },
    { pass_type = "rect", style_id = "health_fill", style = { size = { 274, 18 }, offset = { 116, 82, 2 }, color = { 255, 160, 60, 45 } }, visibility_function = detailed },
    { pass_type = "text", style_id = "status", value_id = "status", value = "", style = text_style(15, 78), visibility_function = visible },
}, "team", { visible = false, use_imported_portrait = true })

HudElementVersusTeam.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusTeam.super.init(self, parent, draw_layer, start_scale, {
        scenegraph_definition = {
            screen = { scale = "fit", size = { 1920, 1080 }, position = { 0, 0, 0 } },
            team = { parent = "screen", horizontal_alignment = "right", vertical_alignment = "bottom",
                size = { 400, 116 }, position = { -25, -60, 80 } },
        },
        widget_definitions = {},
    })
    self._team_rows = {}
end

HudElementVersusTeam.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    HudElementVersusTeam.super.update(self, dt, t, ui_renderer, render_settings, input_service)
    self._refresh_in = (self._refresh_in or 0) - dt
    if self._refresh_in > 0 then return end
    self._refresh_in = 0.1
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
            local compact = row.compact == true
            widget.content.compact = compact
            -- Stack upward from the bottom-right; overflow continues to the left.
            local per_column = compact and 12 or 7
            widget.offset[1] = (compact and 100 or 0) - math.floor((i - 1) / per_column) * (compact and 310 or 410)
            widget.offset[2] = (compact and 60 or 0) - ((i - 1) % per_column) * (compact and 64 or 124)
            widget.style.background.size[1], widget.style.background.size[2] = compact and 300 or 400, compact and 56 or 116
            widget.style.name.offset[1], widget.style.name.offset[2] = compact and 10 or 116, compact and 4 or 12
            widget.style.status.offset[1], widget.style.status.offset[2] = compact and 10 or 116, compact and 29 or 78
            widget.style.name.size[1], widget.style.status.size[1] = compact and 280 or 274, compact and 280 or 274
            widget.content.name = row.name
            widget.content.label = row.label or ""
            widget.content.portrait = row.portrait
            widget.content.portrait_breed = row.portrait_breed
            local has_health = not compact and row.alive and row.health and row.maximum
            widget.style.health_fill.size[1] = has_health and 274 * math.min(1, row.health / row.maximum) or 0
            widget.content.status = compact and row.status or has_health and string.format("%d / %d", math.floor(row.health), math.floor(row.maximum))
                or row.alive and "—" or row.status
        end
    end
end

return HudElementVersusTeam
