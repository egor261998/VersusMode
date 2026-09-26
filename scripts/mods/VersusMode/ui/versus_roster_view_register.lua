local mod = get_mod("VersusMode")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local WwiseGameSyncSettings = require("scripts/settings/wwise_game_sync/wwise_game_sync_settings")

local VIEW_NAME = "versus_mode_roster_view"
local VIEW_PATH = "VersusMode/scripts/mods/VersusMode/ui/versus_roster_view"

mod:add_require_path(VIEW_PATH)
mod:register_view({
    view_name = VIEW_NAME,
    view_settings = {
        class = "VersusModeRosterView",
        disable_game_world = false,
        game_world_blur = 0.8,
        init_view_function = function()
            return true
        end,
        load_always = true,
        load_in_hub = true,
        path = VIEW_PATH,
        throttle_frame_rate = false,
        use_transition_ui = true,
        enter_sound_events = {
            UISoundEvents.system_menu_enter,
        },
        exit_sound_events = {
            UISoundEvents.system_menu_exit,
        },
        wwise_states = {
            options = WwiseGameSyncSettings.state_groups.options.ingame_menu,
        },
    },
    view_transitions = {},
    view_options = {
        close_all = false,
        close_previous = false,
        close_transition_time = nil,
        transition_time = nil,
    },
})

local VIEW_NAME = "versus_mode_spawn_view"
local VIEW_PATH = "VersusMode/scripts/mods/VersusMode/ui/versus_spawn_view"

mod:add_require_path(VIEW_PATH)
mod:register_view({
    view_name = VIEW_NAME,
    view_settings = {
        class = "VersusModeSpawnView",
        disable_game_world = false,
        game_world_blur = 0.8,
        init_view_function = function()
            return true
        end,
        load_always = true,
        load_in_hub = true,
        path = VIEW_PATH,
        throttle_frame_rate = false,
        use_transition_ui = true,
        enter_sound_events = {
            UISoundEvents.system_menu_enter,
        },
        exit_sound_events = {
            UISoundEvents.system_menu_exit,
        },
        wwise_states = {
            options = WwiseGameSyncSettings.state_groups.options.ingame_menu,
        },
    },
    view_transitions = {},
    view_options = {
        close_all = false,
        close_previous = false,
        close_transition_time = nil,
        transition_time = nil,
    },
})
