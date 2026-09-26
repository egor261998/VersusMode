local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local MAX_ROWS = 8
local PANEL_WIDTH = 900
local PANEL_HEIGHT = 720
local CONTENT_WIDTH = PANEL_WIDTH - 64
local ROW_HEIGHT = 48
local ROW_STEP = 54

local scenegraph_definition = {
    screen = {
        scale = "fit",
        size = { 1920, 1080 },
        position = { 0, 0, 80 },
    },
    panel = {
        parent = "screen",
        horizontal_alignment = "center",
        vertical_alignment = "center",
        size = { PANEL_WIDTH, PANEL_HEIGHT },
        position = { 0, 0, 2 },
    },
    title = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = { CONTENT_WIDTH, 46 },
        position = { 32, 24, 3 },
    },
    subtitle = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = { CONTENT_WIDTH, 34 },
        position = { 32, 70, 3 },
    },
    selection_count = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = { CONTENT_WIDTH, 30 },
        position = { 32, 106, 3 },
    },
    status = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        size = { CONTENT_WIDTH, 34 },
        position = { 32, -100, 3 },
    },
    apply_button = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "bottom",
        size = { 260, 58 },
        position = { 32, -30, 3 },
    },
    clear_button = {
        parent = "panel",
        horizontal_alignment = "center",
        vertical_alignment = "bottom",
        size = { 260, 58 },
        position = { 0, -30, 3 },
    },
    close_button = {
        parent = "panel",
        horizontal_alignment = "right",
        vertical_alignment = "bottom",
        size = { 260, 58 },
        position = { -32, -30, 3 },
    },
}

for i = 1, MAX_ROWS do
    scenegraph_definition["row_" .. i] = {
        parent = "panel",
        horizontal_alignment = "left",
        vertical_alignment = "top",
        size = { CONTENT_WIDTH, ROW_HEIGHT },
        position = { 32, 146 + (i - 1) * ROW_STEP, 3 },
    }
end

local function clone_font(source, size, color, horizontal)
    local style = table.clone(source)

    style.font_size = size
    style.text_color = color
    style.text_horizontal_alignment = horizontal or "left"
    style.text_vertical_alignment = "center"
    style.horizontal_alignment = "center"
    style.vertical_alignment = "center"
    style.offset = { 0, 0, 2 }

    return style
end

local function visible(content)
    return content.visible ~= false
end

local function panel_definition()
    return UIWidget.create_definition({
        {
            pass_type = "rect",
            style = { color = { 238, 10, 16, 18 } },
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/frames/frame_tile_2px",
            style = {
                scale_to_material = true,
                color = { 235, 112, 137, 115 },
                offset = { 0, 0, 1 },
            },
        },
    }, "panel")
end

local function row_definition(scenegraph_id)
    return UIWidget.create_definition({
        {
            pass_type = "hotspot",
            content_id = "hotspot",
            visibility_function = visible,
        },
        {
            pass_type = "rect",
            style_id = "background",
            visibility_function = visible,
            style = { color = { 220, 31, 43, 40 } },
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/frames/frame_tile_2px",
            visibility_function = visible,
            style_id = "frame",
            style = {
                scale_to_material = true,
                color = { 210, 83, 105, 87 },
                offset = { 0, 0, 1 },
            },
        },
        {
            pass_type = "text",
            value = "",
            value_id = "text",
            visibility_function = visible,
            style_id = "text",
            style = clone_font(UIFontSettings.body, 22, { 255, 222, 226, 219 }, "left"),
        },
    }, scenegraph_id, {
        visible = false,
        text = "",
        token = nil,
    })
end

local function button_definition(scenegraph_id, text)
    return UIWidget.create_definition({
        { pass_type = "hotspot", content_id = "hotspot" },
        {
            pass_type = "rect",
            style_id = "background",
            style = { color = { 235, 39, 57, 48 } },
        },
        {
            pass_type = "texture",
            value = "content/ui/materials/frames/frame_tile_2px",
            style_id = "frame",
            style = {
                scale_to_material = true,
                color = { 235, 112, 137, 115 },
                offset = { 0, 0, 1 },
            },
        },
        {
            pass_type = "text",
            value = text,
            value_id = "text",
            style_id = "text",
            style = clone_font(UIFontSettings.body, 22, { 255, 225, 230, 221 }, "center"),
        },
    }, scenegraph_id)
end

local widget_definitions = {
    background = UIWidget.create_definition({
        { pass_type = "rect", style = { color = { 165, 0, 0, 0 } } },
    }, "screen"),
    panel = panel_definition(),
    title = UIWidget.create_definition({
        {
            pass_type = "text",
            value = "",
            value_id = "text",
            style = clone_font(UIFontSettings.header_2, 34, { 255, 237, 185, 92 }, "left"),
        },
    }, "title"),
    subtitle = UIWidget.create_definition({
        {
            pass_type = "text",
            value = "",
            value_id = "text",
            style = clone_font(UIFontSettings.body, 20, { 255, 200, 207, 195 }, "left"),
        },
    }, "subtitle"),
    selection_count = UIWidget.create_definition({
        {
            pass_type = "text",
            value = "",
            value_id = "text",
            style_id = "text",
            style = clone_font(UIFontSettings.body, 20, { 255, 120, 235, 145 }, "left"),
        },
    }, "selection_count"),
    status = UIWidget.create_definition({
        {
            pass_type = "text",
            value = "",
            value_id = "text",
            style_id = "text",
            style = clone_font(UIFontSettings.body, 19, { 255, 200, 207, 195 }, "left"),
        },
    }, "status"),
    apply_button = button_definition("apply_button", ""),
    clear_button = button_definition("clear_button", ""),
    close_button = button_definition("close_button", ""),
}

for i = 1, MAX_ROWS do
    widget_definitions["row_" .. i] = row_definition("row_" .. i)
end

return {
    max_rows = MAX_ROWS,
    scenegraph_definition = scenegraph_definition,
    widget_definitions = widget_definitions,
}
