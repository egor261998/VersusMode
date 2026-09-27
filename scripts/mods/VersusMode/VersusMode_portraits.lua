-- Original pixel portraits, drawn with native UI primitives (no texture loader).
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local mod = get_mod("VersusMode")
local portraits = {}
local imported
local function imported_portrait(breed)
    if imported == nil then
        local ok, data = pcall(mod.io_dofile, mod, "VersusMode/scripts/mods/VersusMode/VersusMode_portrait_images")
        imported = ok and type(data) == "table" and data or {}
    end
    return imported[breed]
end
local profiles = {
    renegade_plasma_gunner = { "helmet", "plasma", "steel" },
    renegade_gunner = { "helmet", "belt", "steel" },
    cultist_gunner = { "hood", "belt", "ochre" },
    chaos_ogryn_gunner = { "ogryn", "belt", "olive" },
    renegade_sniper = { "hood", "scope", "steel" },
    renegade_netgunner = { "mask", "net", "rust" },
    renegade_grenadier = { "helmet", "bomb", "rust" },
    cultist_grenadier = { "hood", "toxin", "olive" },
    chaos_hound = { "hound", "fang", "rust" },
    chaos_armored_hound = { "hound", "armor", "steel" },
    chaos_hound_mutator = { "hound", "fang", "ochre" },
    chaos_ogryn_executor = { "ogryn", "hammer", "steel" },
    chaos_ogryn_bulwark = { "ogryn", "shield", "steel" },
    chaos_poxwalker_bomber = { "mutant", "toxin", "olive" },
    renegade_executor = { "helmet", "axe", "rust" },
    cultist_mutant = { "mutant", "fist", "ochre" },
    cultist_mutant_mutator = { "mutant", "fist", "rust" },
    renegade_shocktrooper = { "helmet", "shells", "steel" },
    cultist_shocktrooper = { "hood", "shells", "ochre" },
    chaos_plague_ogryn = { "ogryn", "plague", "olive" },
    chaos_spawn = { "mutant", "claw", "rust" },
    chaos_beast_of_nurgle = { "beast", "toxin", "olive" },
    chaos_ogryn_houndmaster = { "ogryn", "fang", "ochre" },
    chaos_daemonhost = { "daemon", "rune", "violet" },
    chaos_mutator_daemonhost = { "daemon", "rune", "olive" },
    renegade_captain = { "helmet", "star", "rust" },
    cultist_captain = { "hood", "star", "ochre" },
    renegade_twin_captain = { "mask", "plasma", "steel" },
    renegade_twin_captain_two = { "mask", "sword", "violet" },
    renegade_flamer = { "mask", "flame", "rust" },
    renegade_flamer_mutator = { "mask", "flame", "violet" },
    cultist_flamer = { "hood", "flame", "olive" },
}
local colors = {
    steel = { 130, 161, 173 }, ochre = { 198, 153, 75 },
    olive = { 137, 158, 83 }, rust = { 177, 98, 74 }, violet = { 161, 120, 191 },
}
local symbols = {
    belt = { "1111111", "1010101", "1111111", "0010100", "0010100" },
    scope = { "0011100", "0001000", "1111111", "0001000", "0011100" },
    net = { "1010101", "0111110", "1010101", "0111110", "1010101" },
    bomb = { "0001100", "0010000", "0111110", "1111111", "0111110" },
    toxin = { "0100010", "1110111", "0001000", "0011100", "0001000" },
    fang = { "1000001", "1100011", "0110110", "0011100", "0001000" },
    armor = { "0111110", "1101011", "1111111", "0101010", "0011100" },
    hammer = { "1111110", "1111110", "0011000", "0011000", "0011000" },
    shield = { "1111111", "1111111", "1111111", "0111110", "0011100" },
    axe = { "0011110", "0011111", "0011110", "0010000", "0010000" },
    fist = { "0111110", "0111110", "1111110", "1111110", "0011100" },
    shells = { "0110110", "1111111", "1111111", "1111111", "0110110" },
    plague = { "0011100", "0011100", "0100010", "1110111", "0100010" },
    claw = { "1010100", "1010100", "1010101", "0111110", "0011100" },
    rune = { "1000001", "0100010", "0011100", "0101010", "1001001" },
    star = { "0001000", "1011101", "0111110", "0011100", "0100010" },
    plasma = { "0111110", "1111111", "1010101", "0111110", "0001100" },
    sword = { "0001000", "0011100", "0011100", "0111110", "0001000" },
    flame = { "0001000", "0011000", "0111010", "1111111", "0111110" },
}
local cache = {}
function portraits.build(breed)
    if cache[breed] then return cache[breed] end
    local profile = profiles[breed] or { "helmet", "star", "steel" }
    local shape, symbol, tint = profile[1], profile[2], colors[profile[3]]
    local palette = { { 18, 24, 29 }, { 42, 51, 55 }, tint, { 211, 194, 157 }, { 246, 104, 67 }, { 8, 13, 17 } }
    local grid = {}
    for y = 0, 31 do grid[y] = {}; for x = 0, 31 do grid[y][x] = 1 end end
    local function rect(x, y, w, h, color)
        for yy = y, y + h - 1 do for xx = x, x + w - 1 do
            if grid[yy] and xx >= 0 and xx < 32 then grid[yy][xx] = color end
        end end
    end
    rect(1, 1, 30, 1, 3); rect(1, 30, 30, 1, 3)
    rect(1, 1, 1, 30, 3); rect(30, 1, 1, 30, 3)
    -- Bust, collar and lit face; each family has its own silhouette.
    rect(5, 18, 22, 11, 2); rect(3, 21, 26, 7, 3)
    rect(11, 6, 10, 15, 3); rect(10, 10, 12, 7, 4)
    rect(11, 11, 10, 2, 6); rect(11, 11, 3, 1, 5); rect(18, 11, 3, 1, 5)
    rect(13, 17, 6, 2, 6)
    if shape == "helmet" then
        rect(9, 5, 14, 5, 3); rect(7, 9, 18, 2, 2); rect(15, 5, 2, 4, 4)
    elseif shape == "hood" then
        rect(9, 4, 14, 5, 3); rect(7, 7, 4, 13, 3); rect(21, 7, 4, 13, 3)
        rect(12, 14, 8, 5, 2)
    elseif shape == "mask" then
        rect(9, 5, 14, 5, 2); rect(12, 13, 8, 6, 3)
        rect(9, 15, 4, 4, 2); rect(19, 15, 4, 4, 2); rect(15, 14, 2, 4, 6)
    elseif shape == "ogryn" then
        rect(8, 5, 16, 14, 3); rect(10, 9, 12, 9, 4)
        rect(10, 10, 12, 2, 2); rect(11, 11, 3, 1, 5); rect(18, 11, 3, 1, 5)
        rect(12, 16, 8, 2, 6); rect(3, 18, 7, 7, 3); rect(22, 18, 7, 7, 3)
    elseif shape == "hound" then
        rect(5, 7, 5, 9, 3); rect(22, 7, 5, 9, 3)
        rect(7, 6, 3, 5, 4); rect(22, 6, 3, 5, 4)
        rect(8, 10, 16, 9, 3); rect(11, 16, 10, 5, 4)
        rect(13, 16, 6, 3, 6); rect(9, 12, 4, 2, 5); rect(19, 12, 4, 2, 5)
        if symbol == "armor" then rect(14, 6, 4, 9, 2); rect(15, 7, 2, 6, 4) end
    elseif shape == "mutant" then
        rect(7, 7, 18, 12, 4); rect(8, 6, 6, 5, 3); rect(21, 10, 5, 7, 3)
        rect(10, 11, 4, 2, 5); rect(17, 10, 4, 2, 6); rect(12, 16, 10, 3, 6)
    elseif shape == "daemon" then
        rect(10, 4, 12, 2, 5); rect(7, 7, 2, 9, 5); rect(23, 7, 2, 9, 5)
        rect(12, 7, 8, 13, 4); rect(12, 11, 3, 2, 5); rect(17, 11, 3, 2, 5)
        rect(14, 16, 4, 3, 6)
    elseif shape == "beast" then
        rect(5, 7, 22, 15, 3); rect(11, 5, 10, 4, 3)
        rect(14, 8, 4, 3, 5); rect(9, 14, 15, 6, 6); rect(12, 18, 9, 4, 4)
    end
    -- Weapon/role silhouette across the chest, readable even in the team HUD.
    rect(7, 22, 18, 7, 6)
    for y, row in ipairs(symbols[symbol]) do
        for x = 1, #row do if row:sub(x, x) == "1" then rect(8 + (x - 1) * 2, 22 + y, 2, 1, 4) end end
    end
    local runs, previous = {}, {}
    for y = 0, 31 do
        local current = {}
        local x = 0
        while x < 32 do
            local color, first = grid[y][x], x
            repeat x = x + 1 until x == 32 or grid[y][x] ~= color
            local key = first .. ":" .. x .. ":" .. color
            local run = previous[key]
            if run then run[4] = run[4] + 1
            else
                run = { first, y, x - first, 1, palette[color] }
                runs[#runs + 1] = run
            end
            current[key] = run
        end
        previous = current
    end
    cache[breed] = runs
    return runs
end

local unavailable = {}
local function draw_packed(renderer, photo, left, top, scale, layer)
    -- Match UIRenderer.draw_rect's immediate Gui2 path, but prepare invariant
    -- render settings once per portrait. No retained objects or cross-frame vectors.
    local settings = renderer.render_settings or {}
    local ui_scale = renderer.scale
    local position = Gui.scale_vector3(Vector3(0, 0, layer), ui_scale)
    position[3] = position[3] + (settings.start_layer or 0)
    local size = Vector3(0, 0, 0)
    local color = Color(255 * (settings.alpha_multiplier or 1), 0, 0, 0)
    local intensity = settings.color_intensity_multiplier or 1
    local options = { color = color, snap_pixel_positions = settings.snap_pixel_positions == true and ui_scale >= 1 }
    if renderer.base_render_pass then
        options.render_pass = renderer.base_render_pass .. (settings.hdr and "_hdr" or "")
    end
    local draw, byte = Gui2.rect, string.byte
    for i = 1, #photo.packed, 7 do
        local x, y, w, h, r, g, b = byte(photo.packed, i, i + 6)
        position[1], position[2] = (left + x * scale) * ui_scale, (top + y * scale) * ui_scale
        size[1], size[2] = w * scale * ui_scale, h * scale * ui_scale
        color[2], color[3], color[4] = r * intensity, g * intensity, b * intensity
        draw(renderer.gui, position, size, options)
    end
end

function portraits.draw(_, renderer, style, content, position, size)
    local breed = content.portrait_breed or "unknown"
    local photo = content.use_imported_portrait and imported_portrait(breed)
    if photo then
        local scale = math.min(size[1] / photo.width, size[2] / photo.height)
        local left = position[1] + (size[1] - photo.width * scale) / 2
        local top = position[2] + (size[2] - photo.height * scale) / 2
        if photo.packed then
            -- Gui.rect consumes its vectors immediately. Reclaim only the
            -- temporaries created below, preserving the caller's frame data.
            local vectors, quaternions, matrices
            if Script and Script.temp_count and Script.set_temp_count then
                vectors, quaternions, matrices = Script.temp_count()
            end
            if Gui2 and Gui2.rect and Gui and Gui.scale_vector3 and renderer.scale then
                draw_packed(renderer, photo, left, top, scale, position[3])
                if vectors then Script.set_temp_count(vectors, quaternions, matrices) end
            else
                for i = 1, #photo.packed, 7 do
                    local x, y, w, h, r, g, b = string.byte(photo.packed, i, i + 6)
                    UIRenderer.draw_rect(renderer,
                        Vector3(left + x * scale, top + y * scale, position[3]),
                        Vector3(w * scale, h * scale, 0), Color(255, r, g, b))
                    if vectors then Script.set_temp_count(vectors, quaternions, matrices) end
                end
            end
        else
            -- Support portrait data already loaded before a mod update.
            for _, run in ipairs(photo.runs) do
                UIRenderer.draw_rect(renderer,
                    Vector3(left + run[1] * scale, top + run[2] * scale, position[3]),
                    Vector3(run[3] * scale, run[4] * scale, 0), Color(255, run[5], run[6], run[7]))
            end
        end
        return
    end
    local material = content.portrait
    if not mod:get("use_drawn_enemy_portraits") and material
        and material ~= "content/ui/materials/dividers/skull_rendered_center_01"
        and not unavailable[material] then
        local checked, exists = pcall(Application.can_get_resource, "material", material)
        if checked and exists then
            local ok = pcall(UIRenderer.draw_texture, renderer, material, position, size, Color(255, 255, 255, 255))
            if ok then return end
        end
        unavailable[material] = true
    end
    local scale_x, scale_y = size[1] / 32, size[2] / 32
    for _, run in ipairs(portraits.build(breed)) do
        local color = run[5]
        UIRenderer.draw_rect(renderer,
            Vector3(position[1] + run[1] * scale_x, position[2] + run[2] * scale_y, position[3]),
            Vector3(run[3] * scale_x, run[4] * scale_y, 0), Color(255, color[1], color[2], color[3]))
    end
end
portraits.profiles = profiles
return portraits
