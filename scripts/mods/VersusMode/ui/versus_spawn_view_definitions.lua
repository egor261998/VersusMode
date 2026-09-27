local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local portraits = get_mod("VersusMode")._portraits
local draw_portrait = type(portraits) == "table" and type(portraits.draw) == "function" and portraits.draw

local MAX_CARDS = 28
local COLUMNS = 7
local scenegraph = {
    screen = { scale = "fit", size = { 1920, 1080 }, position = { 0, 0, 80 } },
    panel = { parent = "screen", horizontal_alignment = "center", vertical_alignment = "center",
        size = { 1800, 1020 }, position = { 0, 0, 2 } },
}
local function node(name, x, y, width, height)
    scenegraph[name] = { parent = "panel", horizontal_alignment = "left", vertical_alignment = "top",
        size = { width, height }, position = { x, y, 3 } }
end
local function font(size)
    local style = table.clone(UIFontSettings.body)
    style.font_size = size
    style.text_color = { 255, 235, 235, 225 }
    style.text_horizontal_alignment = "center"
    style.text_vertical_alignment = "center"
    style.offset = { 0, 0, 3 }
    return style
end
local widgets = {
    panel = UIWidget.create_definition({ { pass_type = "rect", style = { color = { 245, 10, 16, 18 } } } }, "panel"),
}
node("title", 20, 15, 1500, 45)
node("hint", 20, 60, 1500, 55)
for _, name in ipairs({ "title", "hint" }) do
    widgets[name] = UIWidget.create_definition({
        { pass_type = "text", value_id = "text", value = "", style = font(name == "title" and 30 or 20) },
    }, name)
end
local function visible(content) return content.visible ~= false end
local function card_background(content, style)
    local color = style.color
    local blocked = content.hotspot.disabled
    local selected = content.hotspot.is_hover or content.selected
    color[1] = not blocked and selected and 245 or 230
    color[2] = blocked and 55 or selected and 63 or 31
    color[3] = blocked and 30 or selected and 93 or 43
    color[4] = blocked and 30 or selected and 53 or 40
end
local function card_frame(content, style)
    local selected = not content.hotspot.disabled and (content.hotspot.is_hover or content.selected)
    local color = style.color
    color[1] = 255
    color[2] = selected and 155 or 83
    color[3] = selected and 235 or 105
    color[4] = selected and 115 or 87
end
for i, group in ipairs({ "melee", "ranged", "bosses" }) do
    local name = "group_" .. group
    node(name, 180 + (i - 1) * 480, 120, 440, 50)
    widgets[name] = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
        { pass_type = "rect", style_id = "background", style = { color = { 230, 31, 43, 40 } } },
        { pass_type = "text", value_id = "text", value = "", style = font(24) },
    }, name)
end
for i = 1, MAX_CARDS do
    local name = "enemy_" .. i
    node(name, 30 + (i - 1) % COLUMNS * 250, 180 + math.floor((i - 1) / COLUMNS) * 190, 230, 185)
    local label_style = font(20)
    label_style.size = { 220, 50 }
    label_style.offset = { 5, 110, 3 }
    local cooldown_style = font(18)
    cooldown_style.size = { 220, 25 }
    cooldown_style.offset = { 5, 158, 3 }
    widgets[name] = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot", visibility_function = visible },
        { pass_type = "rect", style_id = "background", style = { color = { 230, 31, 43, 40 } }, visibility_function = visible, change_function = card_background },
        { pass_type = "texture", value = "content/ui/materials/frames/frame_tile_2px", style_id = "frame",
            style = { color = { 255, 83, 105, 87 }, scale_to_material = true, offset = { 0, 0, 1 } }, visibility_function = visible, change_function = card_frame },
        { pass_type = draw_portrait and "logic" or "texture", value_id = draw_portrait and "draw_portrait" or "portrait",
            value = draw_portrait or "content/ui/materials/dividers/skull_rendered_center_01",
            style = { size = { 110, 110 }, offset = { 60, 10, 2 }, color = { 255, 255, 255, 255 } }, visibility_function = visible },
        { pass_type = "text", value_id = "text", value = "", style = label_style, visibility_function = visible },
        { pass_type = "text", value_id = "cooldown", style_id = "cooldown", value = "", style = cooldown_style, visibility_function = visible },
    }, name, { visible = false, use_imported_portrait = true })
end
for _, name in ipairs({ "cancel" }) do
    node(name, 700, 950, 400, 60)
    widgets[name] = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
        { pass_type = "rect", style = { color = { 240, 50, 75, 50 } } },
        { pass_type = "text", value_id = "text", value = "", style = font(24) },
    }, name)
end
return { max_cards = MAX_CARDS, scenegraph_definition = scenegraph, widget_definitions = widgets }
