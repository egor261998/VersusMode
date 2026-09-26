local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local MAX_CARDS = 12
local COLUMNS = 6
local scenegraph = {
    screen = { scale = "fit", size = { 1920, 1080 }, position = { 0, 0, 80 } },
    panel = { parent = "screen", horizontal_alignment = "center", vertical_alignment = "center",
        size = { 1540, 660 }, position = { 0, 0, 2 } },
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
for i = 1, MAX_CARDS do
    local name = "enemy_" .. i
    node(name, 30 + (i - 1) % COLUMNS * 250, 125 + math.floor((i - 1) / COLUMNS) * 205, 230, 185)
    local label_style = font(20)
    label_style.size = { 220, 50 }
    label_style.offset = { 5, 110, 3 }
    local cooldown_style = font(18)
    cooldown_style.size = { 220, 25 }
    cooldown_style.offset = { 5, 158, 3 }
    widgets[name] = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot", visibility_function = visible },
        { pass_type = "rect", style_id = "background", style = { color = { 230, 31, 43, 40 } }, visibility_function = visible },
        { pass_type = "texture", value = "content/ui/materials/frames/frame_tile_2px", style_id = "frame",
            style = { color = { 255, 83, 105, 87 }, scale_to_material = true, offset = { 0, 0, 1 } }, visibility_function = visible },
        { pass_type = "texture", value_id = "portrait", value = "content/ui/materials/dividers/skull_rendered_center_01",
            style = { size = { 110, 110 }, offset = { 60, 10, 2 }, color = { 255, 255, 255, 255 } }, visibility_function = visible },
        { pass_type = "text", value_id = "text", value = "", style = label_style, visibility_function = visible },
        { pass_type = "text", value_id = "cooldown", style_id = "cooldown", value = "", style = cooldown_style, visibility_function = visible },
    }, name, { visible = false })
end
for _, name in ipairs({ "cancel" }) do
    node(name, 640, 570, 260, 60)
    widgets[name] = UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
        { pass_type = "rect", style = { color = { 240, 50, 75, 50 } } },
        { pass_type = "text", value_id = "text", value = "", style = font(24) },
    }, name)
end
return { max_cards = MAX_CARDS, scenegraph_definition = scenegraph, widget_definitions = widgets }
