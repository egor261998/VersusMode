local mod = get_mod("VersusMode")
local lighting = {}
local resource = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01"
local rig
local failed = false
local directions = {
    { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 },
    { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 },
}

lighting.clear = function()
    local old = rig
    rig = nil
    if not old then return end
    local worlds = Managers.world
    if not worlds or not worlds:has_world("level_world")
        or worlds:world("level_world") ~= old.world then return end
    for _, light in ipairs(old.lights) do
        if Unit.alive(light.unit) then World.destroy_unit(old.world, light.unit) end
    end
end

local function create(world, position)
    rig = { world = world, lights = {} }
    for _, direction in ipairs(directions) do
        local unit = World.spawn_unit_ex(world, resource, nil, position)
        -- Retain immediately so partial setup failures can destroy every unit.
        local light = { unit = unit }
        rig.lights[#rig.lights + 1] = light
        assert(Unit.num_lights(unit) > 0, "Night vision resource has no lights")
        for i = 1, Unit.num_lights(unit) do
            Light.set_enabled(Unit.light(unit, i), false)
        end
        for i = 1, Unit.num_meshes(unit) do Unit.set_mesh_visibility(unit, i, false) end
        light.source = Unit.light(unit, 1)
        local source = light.source
        Light.set_type(source, "directional")
        Light.set_spot_reflector(source, false)
        Light.set_casts_shadows(source, false)
        Light.set_volumetric_intensity(source, 0)
        Light.set_intensity(source, 0)
        Light.set_color_filter(source, Vector3(1, 1, 1))
        Light.set_correlated_color_temperature(source, 6500)
        local up = direction[3] ~= 0 and Vector3(0, 1, 0) or Vector3(0, 0, 1)
        Unit.set_local_rotation(unit, 1, Quaternion.look(Vector3(direction[1], direction[2], direction[3]), up))
        Light.set_enabled(source, true)
        World.update_unit(world, unit)
    end
end

lighting.update = function(world, position, strength)
    if strength <= 0 then lighting.clear(); return end
    if failed then return end
    if rig then
        local valid = rig.world == world
        if valid then
            for _, light in ipairs(rig.lights) do
                if not Unit.alive(light.unit) then valid = false; break end
            end
        end
        if not valid then lighting.clear() end
    end
    if not rig then
        if mod:package_status(resource) ~= "loaded" then return end
        local ok, err = pcall(create, world, position)
        if not ok then
            lighting.clear()
            failed = true
            mod:warning("Night vision lighting unavailable: %s", tostring(err))
            return
        end
    end
    -- Opposite directions cover every normal. Bound the combined diffuse
    -- contribution: |nx| + |ny| + |nz| <= sqrt(3) for a unit normal.
    local intensity = strength / math.sqrt(3)
    local x, y, z = position[1], position[2], position[3]
    local moved = rig.x ~= x or rig.y ~= y or rig.z ~= z
    local changed = rig.intensity ~= intensity
    if not moved and not changed then return end
    for _, light in ipairs(rig.lights) do
        if moved then Unit.set_local_position(light.unit, 1, position) end
        if changed then Light.set_intensity(light.source, intensity) end
        World.update_unit(world, light.unit)
    end
    -- Own only scalar coordinates, never retain an engine-temporary vector.
    rig.x, rig.y, rig.z, rig.intensity = x, y, z, intensity
end

return lighting
