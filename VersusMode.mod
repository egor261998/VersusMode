return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`Versus Mode` encountered an error loading the Darktide Mod Framework.")

        new_mod("VersusMode", {
            mod_script = "VersusMode/scripts/mods/VersusMode/VersusMode",
            mod_data = "VersusMode/scripts/mods/VersusMode/VersusMode_data",
            mod_localization = "VersusMode/scripts/mods/VersusMode/VersusMode_localization",
        })
    end,
    packages = { "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01" },
    load_after = {
        "dmf",
        "Realms",
    },
    version = "3.1.0",
    mod_id = "VersusMode",
}
