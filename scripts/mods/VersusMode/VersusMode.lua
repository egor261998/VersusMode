local mod = get_mod("VersusMode")

-- DMF's custom HUD loader executes a physical Lua file instead of consulting
-- package.loaded. Pointing it back to this guaranteed-existing main file lets
-- the second execution return the class immediately without duplicating hooks.
if mod._embedded_hud_class then
    mod:info("Supplying embedded VersusMode HUD class.")

    return mod._embedded_hud_class
end

local HumanGameplay = require("scripts/managers/player/player_game_states/human_gameplay")
local FreeFlightManager = require("scripts/foundation/managers/free_flight/free_flight_manager")
require("scripts/ui/hud/elements/hud_element_base")
local VersusModeState = {
    player_compositions = require("scripts/utilities/players/player_compositions"),
    player_unit_status = require("scripts/utilities/attack/player_unit_status"),
    nav_queries = require("scripts/utilities/nav_queries"),
    navigation_cost_settings = require("scripts/settings/navigation/navigation_cost_settings"),
    breeds = require("scripts/settings/breed/breeds"),
    outline_system = require("scripts/extension_systems/outline/outline_system"),
    fade_system = require("scripts/extension_systems/fade/fade_system"),
    spectator_text = require("scripts/ui/hud/elements/spectator/hud_element_spectator_text"),
    camera_manager = require("scripts/managers/camera/camera_manager"),
    text = require("scripts/utilities/ui/text"),
    free_flight_default_input = require("scripts/foundation/managers/free_flight/free_flight_default_input"),
    fov = require("scripts/utilities/camera/fov"),
    player_orientation_settings = require("scripts/settings/player_character/player_orientation_settings"),
    camera_handler = require("scripts/managers/player/player_game_states/camera_handler"),
    camera_modes = require("scripts/managers/player/player_game_states/utilities/camera_modes"),
    player_unit_camera = CLASS.PlayerUnitCameraExtension,
    player_husk_camera = CLASS.PlayerHuskCameraExtension,
    player_unit_first_person = require("scripts/extension_systems/first_person/player_unit_first_person_extension"),
    player_husk_first_person = require("scripts/extension_systems/first_person/player_husk_first_person_extension"),
    flamer_approach_action = require("scripts/extension_systems/behavior/nodes/actions/bt_flamer_approach_action"),
    melee_attack_action = require("scripts/extension_systems/behavior/nodes/actions/bt_melee_attack_action"),
    shoot_liquid_beam_action = require("scripts/extension_systems/behavior/nodes/actions/bt_shoot_liquid_beam_action"),
    daemonhost_settings = require("scripts/settings/monster/chaos_daemonhost_settings"),
    daemonhost_selector = require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_daemonhost_selector_node"),
    mutator_daemonhost_selector = require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_mutator_daemonhost_selector_node"),
    buff_settings = require("scripts/settings/buff/buff_settings"),
    direct_specialist_selectors = {
        require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_flamer_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_flamer_mutator_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_cultist_flamer_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_hound_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_armored_hound_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_hound_mutator_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_cultist_mutant_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_poxwalker_bomber_selector_node"),
    },
    rescue_interaction = require("scripts/extension_systems/interaction/interactions/rescue_interaction"),
    respawn_beacon_system = require("scripts/extension_systems/respawn_beacon/respawn_beacon_system"),
    game_mode_coop = require("scripts/managers/game_mode/game_modes/game_mode_coop_complete_objective"),
    game_mode_survival = require("scripts/managers/game_mode/game_modes/game_mode_survival"),
    game_mode_expedition = require("scripts/managers/game_mode/game_modes/game_mode_expedition"),
    expedition_logic = require("scripts/managers/game_mode/game_modes/expedition/expedition_logic_base"),
    trigger_all_players = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_all_players_inside"),
    trigger_all_alive_players = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_all_alive_players_inside"),
    trigger_all_players_no_enemies = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_all_players_inside_no_enemies"),
    trigger_half_players = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_at_least_half_players_inside"),
    trigger_one_player = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_at_least_one_player_inside"),
    trigger_only_enter = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_only_enter"),
    trigger_end_zone = require("scripts/extension_systems/trigger/trigger_conditions/trigger_condition_all_required_players_in_end_zone"),
    door_extension = require("scripts/extension_systems/door/door_extension"),
    moveable_platform_extension = require("scripts/extension_systems/moveable_platform/moveable_platform_extension"),
    flow_callbacks = require("scripts/script_flow_nodes/flow_callbacks"),
    player_movement = require("scripts/utilities/player_movement"),
    player_death = require("scripts/utilities/player_death"),
    minion_movement = require("scripts/utilities/minion_movement"),
    bot_teleport_action = require("scripts/extension_systems/behavior/nodes/actions/bot/bt_bot_teleport_to_ally_action"),
    bot_unit_input = require("scripts/extension_systems/input/bot_unit_input"),
    nameplates = require("scripts/ui/hud/elements/nameplates/hud_element_nameplates"),
    boss_extension = require("scripts/extension_systems/boss/boss_extension"),
    spawn_point_queries = require("scripts/managers/main_path/utilities/spawn_point_queries"),
    main_path_queries = require("scripts/utilities/main_path_queries"),
    climb_action = require("scripts/extension_systems/behavior/nodes/actions/bt_climb_action"),
    open_door_action = require("scripts/extension_systems/behavior/nodes/actions/bt_open_door_action"),
    chaos_spawn_leap_action = require("scripts/extension_systems/behavior/nodes/actions/bt_leap_action"),
    charge_action = require("scripts/extension_systems/behavior/nodes/actions/bt_charge_action"),
    captain_root_selectors = {
        require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_captain_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_cultist_captain_selector_node"),
    },
    gunner_root_selectors = {
        require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_gunner_selector_node"),
        require("scripts/extension_systems/behavior/nodes/generated/bt_cultist_gunner_selector_node"),
    },
    -- Captain switch actions are not guaranteed to exist at title-screen mod
    -- load. Let DMF install the responsiveness hook after the engine registers
    -- the class, just like the shared phase extension below.
    switch_weapon_action = CLASS.BtSwitchWeaponAction,
    -- Requiring this extension while mods load constructs its class before the
    -- engine has registered its superclass. Use DMF's delayed class proxy so
    -- spawning a minion cannot encounter CombatRangeUserBehaviorExtension.super
    -- as nil during extension initialization.
    combat_range_user_behavior = CLASS.CombatRangeUserBehaviorExtension,
    -- Buff templates do not exist yet when DMF loads mods on the title screen.
    -- CLASS lets DMF defer these hooks until MinionBuffExtension is registered.
    minion_buff_extension = CLASS.MinionBuffExtension,
    -- Animation repair observes the native minion RPC rather than replacing
    -- it. Delayed proxies keep these gameplay classes safe at title-screen
    -- load and let the client distinguish a received native event from a
    -- genuinely missed one before applying the Realms fallback.
    minion_animation = CLASS.MinionAnimationExtension,
    animation_system = CLASS.AnimationSystem,
    game_session_manager = CLASS.GameSessionManager,
    stagger = require("scripts/utilities/attack/stagger"),
    network_constants = nil,
    respawn_breeds = {
        { name = "renegade_gunner", label = "Scab Gunner" },
        { name = "cultist_gunner", label = "Dreg Gunner" },
        { name = "chaos_ogryn_gunner", label = "Reaper" },
        { name = "renegade_sniper", label = "Scab Sniper" },
        { name = "renegade_netgunner", label = "Scab Trapper" },
        { name = "renegade_grenadier", label = "Scab Bomber" },
        { name = "cultist_grenadier", label = "Dreg Tox Bomber" },
        { name = "chaos_hound", label = "Pox Hound" },
        { name = "chaos_ogryn_executor", label = "Crusher" },
        { name = "chaos_poxwalker_bomber", label = "Poxburster" },
    },
    -- Keep automatic boss assignments outside this restricted reinforcement roster.
    allow_boss_reinforcements = false,
    controlled_elite_breeds = {
        renegade_gunner = true,
        cultist_gunner = true,
        chaos_ogryn_gunner = true,
        chaos_ogryn_executor = true,
        chaos_ogryn_bulwark = true,
    },
    gunner_smoke_melee_range = 4,
    gunner_breeds = {
        renegade_gunner = true,
        cultist_gunner = true,
        chaos_ogryn_gunner = true,
    },
    daemonhost_breeds = {
        chaos_daemonhost = true,
        chaos_mutator_daemonhost = true,
    },
    variant_spawn_choices = {
        { name = "renegade_netgunner", variant_id = "sniper_netter", label_key = "variant_sniper_netter" },
    },
    variant_breeds = {
        sniper_netter = "renegade_netgunner",
    },
    survivor_view_dot = 0.15,
    suppressed_outline_marker = {},
    streaming_anchor_refresh_interval = 0.35,
    streaming_anchor_switch_advantage = 6,
    streaming_transition_distance = 12,
    camera_diagnostic_interval = 10,
    controlled_animation_lod_radius = 1000,
    remote_animation_fallback_delay = 0.2,
    remote_animation_credit_lifetime = 0.75,
    remote_animation_queue_limit = 32,
    auto_boss_release_guard_duration = 0.5,
    random_spawn_max_distance = 35,
    random_spawn_fallback_max_distance = 50,
    random_spawn_group_range = 12,
    random_spawn_spacing = 10,
    random_spawn_reservation_duration = 3,
    random_spawn_duplicate_distance = 1.5,
    random_spawn_history_distance = 12,
    random_spawn_history_size = 6,
    random_spawn_fallback_candidate_limit = 96,
    traversal_max_distance = 25,
    traversal_timeout = 14,
    contextual_traversal_distance = 3.25,
    contextual_traversal_min_forward_dot = 0.1,
    traversal_highlight_refresh_interval = 0.12,
    traversal_entrance_commit_distance = 0.35,
    traversal_entrance_commit_max_distance = 1.25,
    traversal_entrance_commit_radius_scale = 1,
    traversal_entrance_commit_radius_padding = 0.2,
    traversal_stale_entrance_timeout = 1.25,
    traversal_entrance_progress_timeout = 3,
    traversal_rejected_link_duration = 10,
    traversal_entrance_nav_projection = 1.5,
    traversal_link_acquire_timeout = 2,
    traversal_link_retry_limit = 2,
    traversal_parallel_direction_dot = 0.5,
    traversal_parallel_height_tolerance = 0.5,
    traversal_parallel_link_tolerance = 2,
    traversal_selected_endpoint_tolerance = 1.5,
    traversal_selected_layer_cost = 0.05,
    traversal_minimum_height_delta = 0.5,
    traversal_flat_fence_score_penalty = 0.75,
    automatic_respawn_retry_interval = 2,
    automatic_respawn_notice_interval = 6,
    redeployment_geography_refresh_interval = 0.5,
    redeployment_transition_distance = 60,
    redeployment_transition_cooldown = 10,
    redeployment_streaming_settle_time = 1,
    spectator_camera_distance = 2.75,
    spectator_camera_height = 0.4,
    spectator_camera_focus_distance = 4,
    spectator_retarget_interval = 0.25,
    first_person_camera_min_forward_offset = 0.16,
    door_exit_offsets = { 2.5, 4, 6 },
    mutant_door_retry_interval = 0.75,
    mutant_door_retry_limit = 3,
    mutant_door_progress_epsilon = 0.15,
    specialist_camera_height_scale = 1.1,
    specialist_camera_fallback_height = 1.8,
    specialist_camera_pitch = -math.pi / 12,
    death_camera_drop_duration = 0.85,
    death_camera_hold_duration = 0.65,
    death_camera_greyscale_fade = 0.35,
    death_camera_ground_height = 0.22,
    death_camera_max_drop = 6,
    vanilla_input_aliases = {
        attack_keybind = "action_one",
        heavy_attack_keybind = "action_two",
        alternate_attack_keybind = "weapon_extra",
        special_attack_keybind = "combat_ability",
        cancel_action_keybind = "sprint",
        controlled_traverse_keybind = "jump",
        cycle_target_keybind = "quick_wield",
        target_lock_keybind = "quick_wield",
    },
}

-- Release builds register Darktide's FreeFlight input service and load the
-- manager class, but they do not construct Managers.free_flight themselves.
-- Camera Freeflight happened to do that as a side effect. Versus Mode owns
-- the native manager initialization it needs so possession and infected
-- waiting cameras do not depend on that separate developer-camera mod.
function VersusModeState.free_flight_false_input()
    return false
end

function VersusModeState.free_flight_zero_input()
    return 0
end

function VersusModeState.free_flight_zero_vector_input()
    return Vector3.zero()
end

for _, action_name in ipairs({
    "camera_speed_down",
    "camera_speed_up",
    "decrease_fov_hold",
    "increase_fov_hold",
    "teleport_player_to_camera",
    "toggle_input_in_free_flight",
    "toggle_look_input",
}) do
    VersusModeState.free_flight_default_input[action_name] =
        VersusModeState.free_flight_default_input[action_name] or VersusModeState.free_flight_false_input
end

for _, action_name in ipairs({ "roll_left", "roll_right" }) do
    VersusModeState.free_flight_default_input[action_name] =
        VersusModeState.free_flight_default_input[action_name] or VersusModeState.free_flight_zero_input
end

VersusModeState.free_flight_default_input["move_controller"] =
    VersusModeState.free_flight_default_input["move_controller"] or VersusModeState.free_flight_zero_vector_input

function VersusModeState.free_flight_manager_usable(free_flight)
    local camera_data = free_flight
        and free_flight._free_flight_cameras
        and free_flight._free_flight_cameras.global

    if not camera_data or type(free_flight.is_in_free_flight) ~= "function" then
        return false
    end

    local active_ok, active = pcall(free_flight.is_in_free_flight, free_flight)

    if not active_ok then
        return false
    end

    if not active then
        return true
    end

    if type(free_flight.camera_position_rotation) ~= "function" then
        return false
    end

    -- A manager can remain active across a mission transition while its
    -- level_world viewport has already been destroyed. Merely checking the
    -- active flag would then preserve an object that crashes on possession.
    local camera_ok, position, rotation = pcall(
        free_flight.camera_position_rotation,
        free_flight,
        "global"
    )

    return camera_ok and position ~= nil and rotation ~= nil
end

function VersusModeState.reset_owned_free_flight_manager(reason)
    local free_flight = Managers.free_flight
    local owned_manager = mod._owned_free_flight_manager

    if not free_flight
        or mod._free_flight_manager_created ~= true
        or owned_manager and owned_manager ~= free_flight then
        return false
    end

    -- Clear ownership before invoking engine cleanup so a partial failure can
    -- never cause this destroyed manager to be reused on the next mission.
    mod._free_flight_manager_created = nil
    mod._owned_free_flight_manager = nil

    local camera_data = free_flight._free_flight_cameras
        and free_flight._free_flight_cameras.global

    if camera_data and camera_data.active then
        local exited = type(free_flight._exit_global_free_flight) == "function"
            and pcall(free_flight._exit_global_free_flight, free_flight, camera_data)

        if not exited then
            if type(free_flight._clear_free_flight_camera) == "function" then
                pcall(free_flight._clear_free_flight_camera, free_flight, camera_data)
            else
                camera_data.active = false
                camera_data.viewport_world_name = nil
            end
        end
    end

    if type(free_flight.destroy) == "function" then
        pcall(free_flight.destroy, free_flight)
    end

    if Managers.free_flight == free_flight then
        Managers.free_flight = nil
    end

    mod._free_flight_creation_warning = nil
    mod._free_flight_update_warning = nil

    if reason then
        mod:info("Versus Mode: reset its native free-flight manager (%s).", tostring(reason))
    end

    return true
end

function VersusModeState.ensure_free_flight_manager()
    local free_flight = Managers.free_flight

    if free_flight and VersusModeState.free_flight_manager_usable(free_flight) then
        return free_flight
    end

    if free_flight then
        if mod._free_flight_manager_created == true
            and (not mod._owned_free_flight_manager or mod._owned_free_flight_manager == free_flight) then
            VersusModeState.reset_owned_free_flight_manager("stale gameplay viewport")
        else
            if not mod._free_flight_creation_warning then
                mod._free_flight_creation_warning = true
                mod:warning("Versus Mode: the existing free-flight manager has no usable gameplay viewport.")
            end

            return nil
        end
    end

    local created, new_free_flight = pcall(FreeFlightManager.new, FreeFlightManager)

    if not created or not new_free_flight then
        if not mod._free_flight_creation_warning then
            mod._free_flight_creation_warning = true
            mod:warning("Versus Mode: could not initialize Darktide's free-flight manager: %s", tostring(new_free_flight))
        end

        return nil
    end

    Managers.free_flight = new_free_flight
    mod._free_flight_manager_created = true
    mod._owned_free_flight_manager = new_free_flight
    mod._free_flight_creation_warning = nil
    mod:info("Versus Mode: initialized Darktide's native free-flight manager.")

    return new_free_flight
end

local MinionPerceptionExtension = require("scripts/extension_systems/perception/minion_perception_extension")
local BtChaosBeastOfNurgleSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_beast_of_nurgle_selector_node")
local BtChaosSpawnSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_spawn_selector_node")
local BtChaosOgrynHoundmasterSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_chaos_ogryn_houndmaster_selector_node")
local BtRenegadeSniperSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_sniper_selector_node")
local BtRenegadeNetgunnerSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_netgunner_selector_node")
local BtRenegadeGrenadierSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_renegade_grenadier_selector_node")
local BtCultistGrenadierSelectorNode = require("scripts/extension_systems/behavior/nodes/generated/bt_cultist_grenadier_selector_node")
local BtChaosSpawnGrabAction = require("scripts/extension_systems/behavior/nodes/actions/bt_chaos_spawn_grab_action")
local BtChaosHoundLeapAction = require("scripts/extension_systems/behavior/nodes/actions/bt_chaos_hound_leap_action")
local BtBeastOfNurgleConsumeAction = require("scripts/extension_systems/behavior/nodes/actions/bt_beast_of_nurgle_consume_action")
local BtBeastOfNurgleSpitOutAction = require("scripts/extension_systems/behavior/nodes/actions/bt_beast_of_nurgle_spit_out_action")
local BtSniperShootAction = require("scripts/extension_systems/behavior/nodes/actions/bt_sniper_shoot_action")
local BtShootAction = require("scripts/extension_systems/behavior/nodes/actions/bt_shoot_action")
local BtShootNetAction = require("scripts/extension_systems/behavior/nodes/actions/bt_shoot_net_action")
local BtRenegadeNetgunnerApproachAction = require("scripts/extension_systems/behavior/nodes/actions/bt_renegade_netgunner_approach_action")
local BtGrenadierFollowAction = require("scripts/extension_systems/behavior/nodes/actions/bt_grenadier_follow_action")
local BtGrenadierThrowAction = require("scripts/extension_systems/behavior/nodes/actions/bt_grenadier_throw_action")
local BtMutantChargerChargeAction = require("scripts/extension_systems/behavior/nodes/actions/bt_mutant_charger_charge_action")
local BtPoxwalkerBomberApproachAction = require("scripts/extension_systems/behavior/nodes/actions/bt_poxwalker_bomber_approach_action")
local BtSummonMinionsAction = require("scripts/extension_systems/behavior/nodes/actions/bt_summon_minions_action")
local BtRandomUtilityNode = require("scripts/extension_systems/behavior/nodes/bt_random_utility_node")
local BtConditions = require("scripts/extension_systems/behavior/utilities/bt_conditions")
local Blackboard = require("scripts/extension_systems/blackboard/utilities/blackboard")
local Breed = require("scripts/utilities/breed")
local ChaosSpawnSettings = require("scripts/settings/monster/chaos_spawn_settings")
local Utility = require("scripts/extension_systems/behavior/utilities/utility")
local OutlineSettings = require("scripts/settings/outline/outline_settings")
local MinionAttack = require("scripts/utilities/minion_attack")
local MinionVisualLoadout = require("scripts/utilities/minion_visual_loadout")
local SmartTagSystem = require("scripts/extension_systems/smart_tag/smart_tag_system")
local InputUtils = require("scripts/managers/input/input_utils")
local HudElementWorldMarkers = require("scripts/ui/hud/elements/world_markers/hud_element_world_markers")
local UIHud = require("scripts/managers/ui/ui_hud")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local BreedActions = require("scripts/settings/breed/breed_actions")
local ProjectileIntegration = require("scripts/extension_systems/locomotion/utilities/projectile_integration")
local MinionMovement = require("scripts/utilities/minion_movement")
local Trajectory = require("scripts/utilities/trajectory")

mod.version = "0.1.2"
mod:info("Versus Mode %s loaded.", mod.version)
mod._suppress_freeflight_toggle_frames = 0
mod._suppress_smart_tag_until = -math.huge
mod._realms_compat = mod:io_dofile("VersusMode/scripts/mods/VersusMode/VersusMode_realms")

VersusModeState.ensure_free_flight_manager()

VersusModeState.roster_view_name = "versus_mode_roster_view"

mod:io_dofile("VersusMode/scripts/mods/VersusMode/ui/versus_roster_view_register")

local math_atan2 = math.atan2
local math_cos = math.cos
local math_max = math.max
local math_min = math.min
local math_sin = math.sin
local table_unpack = table.unpack or unpack
local vector3_distance = Vector3.distance
local vector3_dot = Vector3.dot
local vector3_length = Vector3.length
local vector3_normalize = Vector3.normalize
local vector3_up = Vector3.up

local DEFAULTS = {
    selection_range = 50,
    move_speed_percent = 90,
    attack_burst_duration = 2,
    attack_acquire_timeout = 8,
    protect_player = true,
    camera_distance = 7,
    camera_height = 2.5,
    specialist_camera_distance = 2,
    specialist_camera_horizontal_offset = 0.4,
    specialist_camera_height_adjustment = 0,
    default_first_person_view = false,
    mouse_sensitivity = 100,
    sniper_mouse_sensitivity_multiplier = 100,
    enable_sniper_scope_zoom = true,
    sniper_scope_vertical_fov = 35,
    hound_heavy_trajectory_mode = "hold_charge",
    long_hold_threshold = 0.45,
    use_custom_enemy_keybinds = false,
    possess_keybind_hold = false,
    attack_keybind_hold = false,
    heavy_attack_keybind_hold = false,
    alternate_attack_keybind_hold = false,
    special_attack_keybind_hold = false,
    cancel_action_keybind_hold = false,
    cycle_target_keybind_hold = false,
    target_lock_keybind_hold = false,
    cycle_infected_spawn_keybind_hold = false,
    enable_mutant_throw_direction_adjustment = true,
    enable_last_survivor_buff = false,
    enable_specialist_variants = false,
    enable_infected_spawn_selection = false,
    enable_random_safe_spawn = true,
    enable_automatic_respawn = true,
    enable_controlled_traversal = true,
    enable_versus_mode = true,
    enable_versus_roster_menu = true,
    infected_menu_keybind_hold = false,
    infected_respawn_delay = 10,
    infected_min_spawn_distance = 5,
    auto_takeover_normal_bosses = true,
    max_infected_controlled_bosses = 1,
    controlled_boss_health_multiplier = 2,
    controlled_specialist_health_multiplier = 1.5,
    controlled_elite_health_multiplier = 1.5,
    controlled_boss_cc_effect_percent = 50,
    hide_infected_team_panel = true,
    show_control_hud = true,
    show_attack_log = false,
    show_sniper_crosshair = false,
    show_target_outline = true,
    show_allied_heretic_outlines = true,
    replace_player_panel = true,
    enemy_panel_x = 17,
    enemy_panel_y = -50,
    hud_x = 40,
    hud_y = 210,
    hud_font_size = 18,
    hud_text_opacity = 90,
}

local ENEMY_PORTRAIT_FALLBACK = "content/ui/materials/dividers/skull_rendered_center_01"
local ENEMY_PORTRAITS = {
    chaos_spawn = "content/ui/materials/icons/portraits/minion_portraits/chaos_spawn_portrait",
    chaos_beast_of_nurgle = "content/ui/materials/icons/portraits/minion_portraits/beast_of_nurgle_portrait",
    renegade_netgunner = "content/ui/materials/icons/portraits/minion_portraits/scab_trapper_portrait",
    chaos_hound = "content/ui/materials/icons/portraits/minion_portraits/chaos_hound_portrait",
    chaos_armored_hound = "content/ui/materials/icons/portraits/minion_portraits/chaos_hound_portrait",
    chaos_hound_mutator = "content/ui/materials/icons/portraits/minion_portraits/chaos_hound_portrait",
    chaos_poxwalker_bomber = "content/ui/materials/icons/portraits/minion_portraits/bomber_portrait",
    cultist_mutant = "content/ui/materials/icons/portraits/minion_portraits/mutant_portrait",
    cultist_mutant_mutator = "content/ui/materials/icons/portraits/minion_portraits/mutant_portrait",
    -- Darktide exposes the Havoc Flamer achievement as a raw texture rather
    -- than a GUI material. Passing it to a texture widget renders a white
    -- square on clients, so Flamers deliberately use the valid neutral emblem
    -- until a packaged minion portrait exists.
    renegade_flamer = ENEMY_PORTRAIT_FALLBACK,
    renegade_flamer_mutator = ENEMY_PORTRAIT_FALLBACK,
    cultist_flamer = ENEMY_PORTRAIT_FALLBACK,
}

local SNIPER_BREED_NAME = "renegade_sniper"
local NETTER_BREED_NAME = "renegade_netgunner"
local GRENADIER_BREEDS = {
    renegade_grenadier = true,
    cultist_grenadier = true,
}
local CAPTAIN_BREEDS = {
    renegade_captain = true,
    cultist_captain = true,
}
local HOUND_BREEDS = {
    chaos_hound = true,
    chaos_armored_hound = true,
    chaos_hound_mutator = true,
}
local MUTANT_BREEDS = {
    cultist_mutant = true,
    cultist_mutant_mutator = true,
}
local POXBURSTER_BREED_NAME = "chaos_poxwalker_bomber"
-- Gunners share the always-on crosshair mode with the Trapper. Their native
-- camera-directed volleys use MinionAttack.get_aim_position below.
local MANUAL_AIM_BREEDS = {
    renegade_gunner = true,
    cultist_gunner = true,
    chaos_ogryn_gunner = true,
    renegade_sniper = true,
    renegade_netgunner = true,
}
local SNIPER_AIM_DISTANCE = 150
local SNIPER_CAMERA_FORWARD_OFFSET = 0.18
local SNIPER_CAMERA_UP_OFFSET = 0.04
local SNIPER_FIRE_COOLDOWN = 1.5
local UI_INPUT_RELEASE_GRACE = 0.2
local GRENADE_PREVIEW_STEP = 0.06
local GRENADE_PREVIEW_MAX_TIME = 12
local GRENADE_PREVIEW_REFRESH_INTERVAL = 0.05
local GRENADE_PREVIEW_MAX_POINTS = 129
local GRENADE_CLOSE_AIM_DISTANCE = 4
local GRENADE_MIN_AIM_DISTANCE = 0.75
local GRENADE_CAMERA_RAY_DISTANCE = 150
local GRENADE_AREA_RADIUS = {
    renegade_grenadier = 4.6,
    cultist_grenadier = 7.6,
}

-- Keep the 0.11 specialist additions behind one top-level local. Darktide's
-- Lua 5.1-compatible compiler limits each chunk to 200 active locals, and the
-- original 0.11.0 layout exceeded that ceiling before the mod could start.
local Specialist = {
    captain_post_switch_acquire_grace = 3,
    free_aim_min_dot = 0.94,
    hound_preview_refresh_interval = 0,
    hound_preview_sample_interval = 0.05,
    hound_preview_max_time = 3,
    hound_preview_max_points = 65,
    hound_charge_duration = 1.5,
    hound_charge_min_pitch = math.pi / 30,
    hound_charge_max_pitch = math.pi * 2 / 9,
    sniper_scope_transition_duration = 0.2,
    sniper_scope_min_fov = math.pi / 12,
    hound_settings = require("scripts/settings/specials/chaos_hound_settings"),
    hound_approach_action = require("scripts/extension_systems/behavior/nodes/actions/bt_chaos_hound_approach_action"),
    -- Native Spawn Leap uses a low ballistic solution. On stepped arena
    -- geometry its coarse precheck can miss a floor contact near the apex,
    -- after which the per-frame sphere sweep lands several metres short. Only
    -- that confirmed early-impact case is replaced by the lowest clear arc
    -- that still lands inside the authored impact radius.
    spawn_leap_clearance_heights = { 2.5, 3.25, 4, 4.75, 5.5, 6.25 },
    spawn_leap_target_offset = 0.75,
    spawn_leap_target_tolerance = 1.5,
    spawn_leap_sweep_interval = 0.05,
    spawn_leap_landing_probe_time = 0.35,
    spawn_leap_max_clearance_speed = 24,
    -- Player-issued Leap is dependable only through Darktide's authored short
    -- branch. Keep the game's global 11–25 m AI allowance untouched, but expose
    -- the proven 11–16 m window in both Adaptive and Advanced control.
    spawn_leap_command_max_distance = ChaosSpawnSettings.short_leap_distance,
    -- The authored 15 m/s solve reaches only about 11.25 m on level ground.
    -- After the 2 m takeoff and 3 m target stand-off, that makes requests just
    -- beyond the 16 m short-leap split mathematically impossible. Retain the
    -- bounded extended solve only so an already committed in-range request can
    -- survive modest target movement during native wind-up.
    spawn_leap_solver_speed_margin = 1.1,
    -- Controlled Leap temporarily removes the ordinary 6 m/s navigation
    -- ceiling. Leave headroom above every bounded replacement arc so a
    -- script-driven frame can also correct a small positional lag.
    spawn_leap_motion_speed_ceiling = 30,
}

-- Enemy units do not have player-style first-person arms. Hide modular head
-- pieces and locally collapse the same base-skeleton head node Darktide uses
-- for native gibbing, preserving the animated body, arms and weapons. Breeds
-- without a known safe head node retain the whole-model fallback. None of
-- these presentation changes use the minion visual-loadout RPC, so survivors
-- and other Realms peers retain the complete controlled unit.
VersusModeState.first_person_visibility_refresh_interval = 0.5
VersusModeState.first_person_head_slots = {
    slot_face = true,
    slot_head = true,
    slot_head_attachment = true,
    slot_headgear = true,
}
VersusModeState.first_person_head_scale_nodes = {
    chaos_armored_hound = "j_head",
    chaos_hound = "j_head",
    chaos_hound_mutator = "j_head",
    chaos_ogryn_bulwark = "j_head",
    chaos_ogryn_executor = "j_head",
    chaos_ogryn_gunner = "j_head",
    chaos_poxwalker_bomber = "j_head",
    cultist_flamer = "j_neck",
    cultist_grenadier = "j_neck",
    cultist_gunner = "j_neck",
    cultist_mutant = "j_head",
    cultist_mutant_mutator = "j_head",
    renegade_flamer = "j_neck",
    renegade_flamer_mutator = "j_neck",
    renegade_grenadier = "j_neck",
    renegade_gunner = "j_neck",
    renegade_netgunner = "j_neck",
    renegade_sniper = "j_neck",
}

local TARGET_OUTLINE = "versus_mode_target"
VersusModeState.allied_heretic_outline_name = "versus_mode_allied_heretic"
VersusModeState.allied_heretic_outline_color = { 0.05, 1, 0.08 }
VersusModeState.operative_outline_color = { 1, 1, 1 }
VersusModeState.locked_operative_outline_color = { 1, 0.025, 0.025 }
VersusModeState.target_outline_material_layers = {
    "player_outline_general",
    "player_outline_general_depth",
}
VersusModeState.allied_heretic_outline_material_layers = {
    "minion_outline",
    "minion_outline_reversed_depth",
}
local target_outline_setting = {
    -- OutlineSystem sorts lower priorities first. This Versus Mode-owned layer
    -- stays above ordinary ally, coherency and PlayerOutlines entries. Its
    -- color is re-applied per Operative after the native update: white while
    -- unlocked, red for the confirmed lock.
    priority = -100,
    material_layers = VersusModeState.target_outline_material_layers,
    color = VersusModeState.operative_outline_color,
    visibility_check = function(unit)
        return HEALTH_ALIVE[unit]
            and not (VersusModeState.local_infected_view
                and VersusModeState.local_infected_view()
                and VersusModeState.player_is_hidden_from_infected
                and VersusModeState.player_is_hidden_from_infected(unit))
    end,
}

local allied_heretic_outline_setting = {
    priority = 0,
    material_layers = VersusModeState.allied_heretic_outline_material_layers,
    color = VersusModeState.allied_heretic_outline_color,
    visibility_check = function(unit)
        return HEALTH_ALIVE[unit] == true
    end,
}

function VersusModeState.ensure_outline_settings(extension)
    local player_settings = OutlineSettings.PlayerUnitOutlineExtension
    local minion_settings = OutlineSettings.MinionOutlineExtension

    if player_settings then
        player_settings[TARGET_OUTLINE] = target_outline_setting
    end

    if minion_settings then
        minion_settings[VersusModeState.allied_heretic_outline_name] = allied_heretic_outline_setting
    end

    -- PlayerOutlines and similar HUD mods can replace an extension's settings
    -- table after VersusMode first loads. Repair the live instance as well as
    -- the global registry immediately before adding one of our owned outlines.
    if extension and type(extension.settings) == "table" then
        if extension.name == "PlayerUnitOutlineExtension" then
            extension.settings[TARGET_OUTLINE] = target_outline_setting
        elseif extension.name == "MinionOutlineExtension" then
            extension.settings[VersusModeState.allied_heretic_outline_name] = allied_heretic_outline_setting
        end
    end
end

VersusModeState.ensure_outline_settings()

local ATTACKS = {
    renegade_sniper = {
        primary = { label = "Fire Longlas", action_name = "shoot", manual_aim = true },
        heavy = { label = "Aim Laser", action_name = "shoot", manual_aim = true, laser_only = true },
    },
    renegade_netgunner = {
        primary = { label = "Fire Net", action_name = "shoot_net", manual_aim = true },
    },
    renegade_flamer = {
        primary = { label = "Flame Stream", action_name = "shoot", native_ai = true, cancellable = true, camera_directed = true, direct_native = "flamer", stationary = true },
        heavy = { label = "Kick", action_name = "melee_attack", native_ai = true, range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true, camera_directed = true, direct_native = "specialist_melee", stationary = true },
    },
    renegade_flamer_mutator = {
        primary = { label = "Flame Stream", action_name = "shoot", native_ai = true, cancellable = true, camera_directed = true, direct_native = "flamer", stationary = true },
        heavy = { label = "Kick", action_name = "melee_attack", native_ai = true, range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true, camera_directed = true, direct_native = "specialist_melee", stationary = true },
    },
    cultist_flamer = {
        primary = { label = "Flame Stream", action_name = "shoot", native_ai = true, cancellable = true, camera_directed = true, direct_native = "flamer", stationary = true },
        heavy = { label = "Kick", action_name = "melee_attack", native_ai = true, range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true, camera_directed = true, direct_native = "specialist_melee", stationary = true },
    },
    chaos_hound = {
        primary = { label = "Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_instant_pounce = true },
        heavy = { label = "Aimed Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_trajectory = true },
    },
    chaos_armored_hound = {
        primary = { label = "Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_instant_pounce = true },
        heavy = { label = "Aimed Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_trajectory = true },
    },
    chaos_hound_mutator = {
        primary = { label = "Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_instant_pounce = true },
        heavy = { label = "Aimed Pounce", action_name = "leap", native_ai = true, force_utility = true, cancellable = true, camera_directed = true, direct_native = "hound", hound_trajectory = true },
    },
    cultist_mutant = {
        primary = { label = "Charge / Grab", action_name = "charge", native_ai = true, cancellable = true, camera_directed = true, direct_native = "mutant" },
        special = { label = "Throw Carried Target", mutant_throw = true },
    },
    cultist_mutant_mutator = {
        primary = { label = "Charge / Grab", action_name = "charge", native_ai = true, cancellable = true, camera_directed = true, direct_native = "mutant" },
        special = { label = "Throw Carried Target", mutant_throw = true },
    },
    chaos_poxwalker_bomber = {
        primary = {
            label = "Lunge",
            action_name = "approach",
            native_ai = true,
            cancellable = true,
            camera_directed = true,
            direct_native = "poxburster",
            range_max = 6,
            range_text = "0–6 m",
            acquire_timeout = 12,
        },
    },
    renegade_grenadier = {
        primary = { label = "Throw Fire Grenade", action_name = "throw_grenade", grenadier_path = "far" },
        heavy = { label = "Kick", action_name = "melee_attack", selector_name = "close_combat", force_utility = true, native_ai = true, grenadier_path = "close", range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true, camera_directed = true, direct_native = "specialist_melee", stationary = true },
    },
    cultist_grenadier = {
        primary = { label = "Throw Tox Grenade", action_name = "throw_grenade", grenadier_path = "far" },
        heavy = { label = "Kick", action_name = "melee_attack", selector_name = "close_combat", force_utility = true, native_ai = true, grenadier_path = "close", range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true, camera_directed = true, direct_native = "specialist_melee", stationary = true },
    },
    renegade_gunner = {
        primary = { label = "Suppressive Fire", action_name = "shoot_spray_n_pray", selector_name = "combat", gunner_combat_range = "far", force_utility = true, cancellable = true, camera_directed = true, single_shoot_cycle = true },
        heavy = { label = "Gun Butt Strike", action_name = "melee_attack", selector_name = "combat", gunner_combat_range = "melee", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
    },
    cultist_gunner = {
        primary = { label = "Suppressive Fire", action_name = "shoot_spray_n_pray", selector_name = "combat", gunner_combat_range = "far", force_utility = true, cancellable = true, camera_directed = true, single_shoot_cycle = true },
        heavy = { label = "Bayonet Stab", action_name = "bayonet_melee_attack", selector_name = "combat", gunner_combat_range = "melee", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
    },
    chaos_ogryn_gunner = {
        primary = { label = "Reaper Volley", action_name = "shoot", selector_name = "combat", gunner_combat_range = "far", force_utility = true, cancellable = true, camera_directed = true, single_shoot_cycle = true },
        heavy = { label = "Reaper Strike", action_name = "melee_attack", selector_name = "combat", gunner_combat_range = "melee", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        alternate = { label = "Reaper Push", action_name = "melee_attack_push", selector_name = "combat", gunner_combat_range = "melee", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
    },
    chaos_ogryn_executor = {
        primary = { label = "Crusher Strike", action_name = "melee_attack", range_max = 3.75, range_text = "0–3.75 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        heavy = { label = "Crusher Cleave", action_name = "melee_attack_cleave", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        alternate = { label = "Pommel Strike", action_name = "melee_attack_pommel", range_max = 3.5, range_text = "0–3.5 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        special = { label = "Kick", action_name = "melee_attack_kick", range_max = 3.5, range_text = "0–3.5 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
    },
    chaos_ogryn_bulwark = {
        primary = { label = "Maul Swing", action_name = "melee_attack", selector_name = "combat", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        heavy = { label = "Shield Push", action_name = "shield_push", selector_name = "combat", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true, stationary = true },
        alternate = { label = "Advancing Strike", action_name = "moving_melee_attack", selector_name = "combat", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true, camera_directed = true, free_aim_melee = true },
    },
    chaos_plague_ogryn = {
        primary = {
            label = "Slam",
            action_name = "melee_slam",
            range_max = 3.5,
            range_text = "0–3.5 m",
            cancellable = true,
        },
        special = {
                label = "Charge Attack",
                action_name = "charge",
                range_min = 6,
                range_min_exclusive = true,
                range_max = 15,
                range_text = "6–15 m",
                requires_line_of_sight = true,
                strict_range = true,
                force_utility = true,
                acquire_timeout = 12,
                cancellable = true,
        },
        heavy = { label = "Plague Stomp", action_name = "plague_stomp", cancellable = true },
        alternate = { label = "Combo Attack", action_name = "combo_attack", range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true },
    },
    chaos_spawn = {
        primary = {
            label = "Claw Attack",
            action_name = "claw_attack",
            range_max = 3.5,
            range_text = "0–3.5 m",
            cancellable = true,
        },
        special = {
                label = "Leap Attack",
                action_name = "leap",
                range_min = ChaosSpawnSettings.min_leap_distance,
                range_max = Specialist.spawn_leap_command_max_distance,
                range_text = string.format(
                    "%g–%g m",
                    ChaosSpawnSettings.min_leap_distance,
                    Specialist.spawn_leap_command_max_distance
                ),
                spawn_leap = true,
                requires_line_of_sight = true,
                strict_range = true,
                acquire_timeout = 12,
                cancellable = true,
        },
        heavy = { label = "Combo Attack", action_name = "combo_attack", range_max = 4, range_text = "0–4 m", strict_range = true, cancellable = true },
        alternate = { label = "Grab", action_name = "grab", cancellable = true },
    },
    chaos_beast_of_nurgle = {
        primary = { label = "Vomit", action_name = "vomit", beast_path = "vomit" },
        heavy = { label = "Body Slam", action_name = "melee_attack_body_slam_aoe", beast_path = "body_slam", cancellable = true },
        special = { label = "Consume", action_name = "consume", beast_path = "consume", requires_vomit = true, cancellable = true },
    },
    renegade_captain = {
        primary = {
            label = "Power Sword Attack",
            action_name = "power_sword_melee_attack",
            captain_weapon_slot = "slot_power_sword",
            range_max = 3.5,
            range_text = "0–3.5 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
            contextual_attack = {
                label = "Charge Attack",
                action_name = "charge",
                selector_name = "renegade_captain_specials",
                captain_charge = true,
                captain_weapon_slot = "slot_power_sword",
                captain_combat_range = "melee",
                range_min = 6,
                range_max = 15,
                range_text = "6–15 m",
                requires_line_of_sight = true,
                strict_range = true,
                force_utility = true,
                acquire_timeout = 12,
                cancellable = true,
            },
        },
        heavy = {
            label = "Power Sword Combo",
            action_name = "power_sword_melee_combo_attack",
            captain_weapon_slot = "slot_power_sword",
            range_max = 3.25,
            range_text = "0–3.25 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
        },
        alternate = {
            label = "Power Sword Sweep",
            action_name = "power_sword_melee_sweep",
            captain_weapon_slot = "slot_power_sword",
            range_max = 4,
            range_text = "0–4 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
        },
    },
    cultist_captain = {
        primary = {
            label = "Power Maul Attack",
            action_name = "powermaul_melee_attack",
            captain_weapon_slot = "slot_powermaul",
            range_max = 3.5,
            range_text = "0–3.5 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
            contextual_attack = {
                label = "Charge Attack",
                action_name = "charge",
                selector_name = "renegade_captain_specials",
                captain_charge = true,
                captain_weapon_slot = "slot_powermaul",
                captain_combat_range = "melee",
                range_min = 6,
                range_max = 15,
                range_text = "6–15 m",
                requires_line_of_sight = true,
                strict_range = true,
                force_utility = true,
                acquire_timeout = 12,
                cancellable = true,
            },
        },
        heavy = {
            label = "Power Maul Cleave",
            action_name = "powermaul_melee_cleave",
            captain_weapon_slot = "slot_powermaul",
            range_max = 4,
            range_text = "0–4 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
        },
        alternate = {
            label = "Power Maul Ground Slam",
            action_name = "powermaul_ground_slam",
            captain_weapon_slot = "slot_powermaul",
            range_max = 5,
            range_text = "0–5 m",
            acquire_timeout = 12,
            cancellable = true,
            stationary = true,
        },
    },
    chaos_daemonhost = {
        primary = { label = "Warp Claw", action_name = "melee_attack", range_max = 4.5, range_text = "0–4.5 m", strict_range = true, force_utility = true, cancellable = true },
        heavy = { label = "Warp Combo", action_name = "combo_attack", range_max = 4.5, range_text = "0–4.5 m", strict_range = true, force_utility = true, cancellable = true },
        alternate = { label = "Warp Sweep", action_name = "warp_sweep", range_min = 4, range_max = 8, range_text = "4–8 m", strict_range = true, force_utility = true, cancellable = true },
        special = { label = "Warp Teleport", action_name = "warp_teleport", selector_name = "melee_combat", range_min = 4.75, range_text = "4.75+ m", force_utility = true, acquire_timeout = 4, cancellable = true },
    },
    chaos_mutator_daemonhost = {
        primary = { label = "Warp Claw", action_name = "melee_attack", range_max = 4.5, range_text = "0–4.5 m", strict_range = true, force_utility = true, cancellable = true },
        heavy = { label = "Warp Combo", action_name = "combo_attack", range_max = 4.5, range_text = "0–4.5 m", strict_range = true, force_utility = true, cancellable = true },
        alternate = { label = "Warp Sweep", action_name = "warp_sweep", range_min = 4, range_max = 8, range_text = "4–8 m", strict_range = true, force_utility = true, cancellable = true },
        special = { label = "Warp Teleport", action_name = "warp_teleport", selector_name = "melee_combat", range_min = 4.75, range_text = "4.75+ m", force_utility = true, acquire_timeout = 4, cancellable = true },
    },
    chaos_ogryn_houndmaster = {
        primary = {
            label = "Melee Attack",
            action_name = "melee_attack",
            range_max = 4,
            range_text = "0–4 m",
            strict_range = true,
            force_utility = true,
            cancellable = true,
            contextual_attack = {
                label = "Charge Attack",
                action_name = "charge",
                range_min = 9,
                range_max = 15,
                range_text = "9–15 m",
                requires_line_of_sight = true,
                strict_range = true,
                force_utility = true,
                acquire_timeout = 12,
                cancellable = true,
            },
        },
        heavy = { label = "Electric Cleave", action_name = "moving_melee_attack_cleave", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true },
        alternate = { label = "Moving Electric Attack", action_name = "far_moving_attack", range_max = 4, range_text = "0–4 m", strict_range = true, force_utility = true, cancellable = true },
        special = { label = "Summon Hounds", action_name = "summon", summon_hounds = true, acquire_timeout = 7 },
    },
    renegade_twin_captain = {
        primary = { label = "Plasma Pistol Shot", action_name = "plasma_pistol_shoot", selector_name = "plasma_pistol_combat", range_min = 6, range_max = 12, range_text = "6–12 m", requires_line_of_sight = true, strict_range = true, force_utility = true, single_shoot_cycle = true, cancellable = true },
        heavy = { label = "Kick", action_name = "kick", selector_name = "plasma_pistol_combat", range_max = 3, range_text = "0–3 m", strict_range = true, force_utility = true, cancellable = true },
        special = { label = "Grenade Throw", action_name = "quick_throw_grenade", selector_name = "throw_grenade", twin_grenade = true, range_min = 4, range_max = 20, range_text = "4–20 m", requires_line_of_sight = true, strict_range = true, force_utility = true, acquire_timeout = 6, cancellable = true },
    },
    renegade_twin_captain_two = {
        primary = {
            label = "Power Sword Sweep",
            action_name = "power_sword_melee_sweep",
            selector_name = "combat",
            range_max = 3.5,
            range_text = "0–3.5 m",
            strict_range = true,
            force_utility = true,
            cancellable = true,
            contextual_attack = {
                label = "Dash and Sweep",
                action_name = "dash_and_sweep",
                selector_name = "combat",
                range_min = 8,
                range_max = 20,
                range_text = "8–20 m",
                requires_line_of_sight = true,
                strict_range = true,
                force_utility = true,
                acquire_timeout = 12,
                cancellable = true,
            },
        },
        heavy = { label = "Power Sword Combo", action_name = "power_sword_melee_combo_attack", selector_name = "combat", range_max = 3.25, range_text = "0–3.25 m", strict_range = true, force_utility = true, cancellable = true },
        alternate = { label = "Moving Sword Sweep", action_name = "power_sword_moving_melee_sweep", selector_name = "combat", range_max = 5, range_text = "0–5 m", strict_range = true, force_utility = true, cancellable = true },
        special = { label = "Kick", action_name = "kick", selector_name = "combat", range_max = 3, range_text = "0–3 m", strict_range = true, force_utility = true, cancellable = true },
    },
}

-- Captain attack selection removes every unused weapon slot from the spawned
-- unit. Breed name therefore cannot tell us whether this particular Captain
-- owns a sword, maul, shotgun or plasma pistol. The melee tables above remain
-- the canonical command definitions; this table supplies the fourth, ranged
-- command after the unit's real visual-loadout slots have been inspected.
local CAPTAIN_RANGED_ATTACKS = {
    slot_shotgun = {
        label = "Shotgun Blast",
        action_name = "shotgun_shoot",
        captain_weapon_slot = "slot_shotgun",
        captain_selector = "shotgun_combat",
        captain_combat_range = "far",
        range_max = 12,
        range_text = "0–12 m",
        single_shoot_cycle = true,
        acquire_timeout = 8,
        cancellable = true,
    },
    slot_plasma_pistol = {
        label = "Plasma Pistol Shot",
        action_name = "plasma_pistol_shoot",
        captain_weapon_slot = "slot_plasma_pistol",
        captain_selector = "plasma_pistol_combat",
        captain_combat_range = "far",
        range_max = 12,
        range_text = "0–12 m",
        single_shoot_cycle = true,
        acquire_timeout = 8,
        cancellable = true,
    },
    slot_bolt_pistol = {
        label = "Bolt Pistol Shot",
        action_name = "bolt_pistol_shoot",
        captain_weapon_slot = "slot_bolt_pistol",
        captain_selector = "bolt_pistol_combat",
        captain_combat_range = "far",
        range_max = 12,
        range_text = "0–12 m",
        acquire_timeout = 8,
        cancellable = true,
    },
    slot_hellgun = {
        label = "Hellgun Burst",
        action_name = "hellgun_shoot",
        captain_weapon_slot = "slot_hellgun",
        captain_selector = "hellgun_combat",
        captain_combat_range = "far",
        range_max = 12,
        range_text = "0–12 m",
        acquire_timeout = 8,
        cancellable = true,
    },
}

local GENERIC_SPECIALIST_ATTACKS = {
    primary = { label = "Native Attack", native_ai = true },
}

local GENERIC_BOSS_ATTACKS = {
    primary = {
        label = "Native Combat",
        native_ai = true,
        native_boss = true,
        cancellable = true,
        acquire_timeout = 12,
    },
}

-- Casual Combat never opens the whole behavior tree. Primary gives the
-- breed's native utility selector a whitelist of ordinary attacks, while
-- Heavy is one explicit signature command. The selector still evaluates its
-- original conditions, utility curves and cooldown timestamps, but follow,
-- phase-transition and signature nodes are absent from the eligible set.
Specialist.casual_primary_attack = {
    label = "Adaptive Attack",
    casual_primary = true,
    casual_command = true,
    native_ai = true,
    cancellable = true,
    acquire_timeout = 3,
}
Specialist.casual_configs = {
    chaos_ogryn_executor = {
        selector_name = "melee_combat",
        primary_actions = {
            melee_attack_cleave = ATTACKS.chaos_ogryn_executor.heavy,
            melee_attack_pommel = ATTACKS.chaos_ogryn_executor.alternate,
            melee_attack_kick = ATTACKS.chaos_ogryn_executor.special,
        },
        signature = ATTACKS.chaos_ogryn_executor.primary,
    },
    chaos_ogryn_bulwark = {
        selector_name = "combat",
        primary_actions = {
            melee_attack = ATTACKS.chaos_ogryn_bulwark.primary,
            moving_melee_attack = ATTACKS.chaos_ogryn_bulwark.alternate,
        },
        signature = ATTACKS.chaos_ogryn_bulwark.heavy,
    },
    chaos_plague_ogryn = {
        selector_name = "melee_combat",
        primary_actions = {
            melee_slam = ATTACKS.chaos_plague_ogryn.primary,
            combo_attack = ATTACKS.chaos_plague_ogryn.alternate,
            charge = ATTACKS.chaos_plague_ogryn.special,
        },
        signature = ATTACKS.chaos_plague_ogryn.heavy,
        signature_range_max = 4,
        approach_range_max = 6,
        approach_timeout = 6,
    },
    chaos_spawn = {
        selector_name = "melee_combat",
        primary_actions = {
            claw_attack = ATTACKS.chaos_spawn.primary,
            combo_attack = ATTACKS.chaos_spawn.heavy,
        },
        signature = ATTACKS.chaos_spawn.alternate,
        signature_range_max = 4,
        approach_range_max = ChaosSpawnSettings.min_leap_distance,
        approach_range_max_exclusive = true,
        approach_timeout = 6,
    },
    chaos_beast_of_nurgle = {
        immediate_primary = true,
        signature = ATTACKS.chaos_beast_of_nurgle.special,
        signature_range_max = 5,
    },
    chaos_ogryn_houndmaster = {
        selector_name = "melee_combat",
        primary_actions = {
            melee_attack = ATTACKS.chaos_ogryn_houndmaster.primary,
            charge = ATTACKS.chaos_ogryn_houndmaster.primary.contextual_attack,
            far_moving_attack = ATTACKS.chaos_ogryn_houndmaster.alternate,
            moving_melee_attack_cleave = ATTACKS.chaos_ogryn_houndmaster.heavy,
        },
        signature = ATTACKS.chaos_ogryn_houndmaster.special,
    },
    chaos_daemonhost = {
        selector_name = "melee_combat",
        primary_actions = {
            melee_attack = ATTACKS.chaos_daemonhost.primary,
            combo_attack = ATTACKS.chaos_daemonhost.heavy,
            warp_teleport = ATTACKS.chaos_daemonhost.special,
        },
        signature = ATTACKS.chaos_daemonhost.alternate,
    },
    chaos_mutator_daemonhost = {
        selector_name = "melee_combat",
        primary_actions = {
            melee_attack = ATTACKS.chaos_mutator_daemonhost.primary,
            combo_attack = ATTACKS.chaos_mutator_daemonhost.heavy,
            warp_teleport = ATTACKS.chaos_mutator_daemonhost.special,
        },
        signature = ATTACKS.chaos_mutator_daemonhost.alternate,
    },
    renegade_captain = {
        captain = true,
        signature_slot = "alternate",
        approach_range_max = 6,
        approach_timeout = 6,
        approach_actions = {
            power_sword_melee_attack = true,
        },
    },
    cultist_captain = {
        captain = true,
        signature_slot = "alternate",
        approach_range_max = 6,
        approach_timeout = 6,
        approach_actions = {
            powermaul_melee_cleave = true,
        },
    },
    renegade_twin_captain = {
        selector_name = "plasma_pistol_combat",
        primary_actions = {
            kick = ATTACKS.renegade_twin_captain.heavy,
            plasma_pistol_shoot = ATTACKS.renegade_twin_captain.primary,
        },
        signature = ATTACKS.renegade_twin_captain.special,
        approach_range_max = 20,
        approach_timeout = 12,
        approach_actions = {
            kick = true,
            plasma_pistol_shoot = true,
        },
    },
    renegade_twin_captain_two = {
        selector_name = "combat",
        primary_actions = {
            kick = ATTACKS.renegade_twin_captain_two.special,
            power_sword_melee_sweep = ATTACKS.renegade_twin_captain_two.primary,
            power_sword_melee_combo_attack = ATTACKS.renegade_twin_captain_two.heavy,
            power_sword_moving_melee_sweep = ATTACKS.renegade_twin_captain_two.alternate,
        },
        signature = ATTACKS.renegade_twin_captain_two.primary.contextual_attack,
        approach_range_max = 20,
        approach_timeout = 12,
        approach_actions = {
            power_sword_moving_melee_sweep = true,
        },
    },
}

function Specialist.casual_breed_supported(breed_or_name)
    local breed_name = type(breed_or_name) == "table" and breed_or_name.name or breed_or_name

    return Specialist.casual_configs[breed_name] ~= nil
end

function Specialist.casual_supported(state)
    return state and state.breed and Specialist.casual_breed_supported(state.breed) or false
end

function VersusModeState.daemonhost_adaptive_execution_action(state, action_name)
    local requested = state and state.requested_attack

    return requested
        and requested.casual_primary == true
        and state.breed
        and VersusModeState.daemonhost_breeds[state.breed.name] == true
        and (action_name == "warp_grab_teleport"
            or action_name == "warp_teleport"
            or action_name == "warp_grab")
        or false
end

function Specialist.copy_attack(attack, overrides)
    if not attack then
        return nil
    end

    local copy = {}

    for key, value in pairs(attack) do
        copy[key] = value
    end

    for key, value in pairs(overrides or {}) do
        copy[key] = value
    end

    return copy
end

-- Variant definitions are command-scoped. They never mutate the shared breed
-- or action tables used by ordinary AI specialists.
VersusModeState.variant_attacks = {
    sniper_netter = {
        primary = {
            label = "Fire Long-range Net",
            action_name = "shoot_net",
            manual_aim = true,
            manual_range_max = 28,
            cooldown_duration = 5,
        },
    },
}

-- Combat labels remain stable English identifiers for host/client messages.
-- The HUD resolves them in the viewing client's language at presentation time.
VersusModeState.hud_attack_label_keys = {
    ["Adaptive Attack"] = "hud_attack_adaptive",
    ["Aimed Pounce"] = "attack_hound_aimed_pounce",
    ["Aim Laser"] = "hud_attack_aim_laser",
    ["Bayonet Stab"] = "hud_attack_bayonet_stab",
    ["Body Slam"] = "hud_attack_body_slam",
    ["Bolt Pistol Shot"] = "hud_attack_bolt_pistol_shot",
    ["Charge / Grab"] = "hud_attack_charge_grab",
    ["Charge Attack"] = "attack_boss_charge",
    ["Claw Attack"] = "hud_attack_claw",
    ["Combo Attack"] = "hud_attack_combo",
    ["Consume"] = "hud_attack_consume",
    ["Crusher Cleave"] = "hud_attack_crusher_cleave",
    ["Crusher Strike"] = "hud_attack_crusher_strike",
    ["Dash and Sweep"] = "hud_attack_dash_sweep",
    ["Electric Cleave"] = "hud_attack_electric_cleave",
    ["Fire Long-range Net"] = "attack_sniper_netter_primary",
    ["Fire Longlas"] = "hud_attack_fire_longlas",
    ["Fire Net"] = "hud_attack_fire_net",
    ["Flame Stream"] = "hud_attack_flame_stream",
    ["Grenade Throw"] = "hud_attack_grenade_throw",
    ["Gun Butt Strike"] = "hud_attack_gun_butt_strike",
    ["Grab"] = "hud_attack_grab",
    ["Hellgun Burst"] = "hud_attack_hellgun_burst",
    ["Kick"] = "hud_attack_kick",
    ["Leap Attack"] = "attack_boss_leap",
    ["Lunge"] = "hud_attack_lunge",
    ["Maul Swing"] = "hud_attack_maul_swing",
    ["Melee Attack"] = "hud_attack_melee",
    ["Moving Electric Attack"] = "hud_attack_moving_electric",
    ["Moving Sword Sweep"] = "hud_attack_moving_sword_sweep",
    ["Native Attack"] = "hud_attack_native",
    ["Native Combat"] = "hud_attack_native_combat",
    ["no ranged weapon"] = "hud_no_ranged_weapon",
    ["Plague Stomp"] = "hud_attack_plague_stomp",
    ["Plasma Pistol Shot"] = "hud_attack_plasma_pistol_shot",
    ["Pounce"] = "hud_attack_pounce",
    ["Power Maul Attack"] = "hud_attack_power_maul",
    ["Power Maul Cleave"] = "hud_attack_power_maul_cleave",
    ["Power Maul Ground Slam"] = "hud_attack_power_maul_slam",
    ["Power Sword Attack"] = "hud_attack_power_sword",
    ["Power Sword Combo"] = "hud_attack_power_sword_combo",
    ["Power Sword Sweep"] = "hud_attack_power_sword_sweep",
    ["Reaper Push"] = "hud_attack_reaper_push",
    ["Reaper Strike"] = "hud_attack_reaper_strike",
    ["Reaper Volley"] = "hud_attack_reaper_volley",
    ["Pommel Strike"] = "hud_attack_pommel_strike",
    ["Advancing Strike"] = "hud_attack_advancing_strike",
    ["Shield Push"] = "hud_attack_shield_push",
    ["Shotgun Blast"] = "hud_attack_shotgun_blast",
    ["Slam"] = "hud_attack_slam",
    ["Summon Hounds"] = "hud_attack_summon_hounds",
    ["Suppressive Fire"] = "hud_attack_suppressive_fire",
    ["Throw Carried Target"] = "hud_attack_throw_carried",
    ["Throw Fire Grenade"] = "hud_attack_throw_fire_grenade",
    ["Throw Tox Grenade"] = "hud_attack_throw_tox_grenade",
    ["Vomit"] = "hud_attack_vomit",
    ["Warp Claw"] = "hud_attack_warp_claw",
    ["Warp Combo"] = "hud_attack_warp_combo",
    ["Warp Sweep"] = "hud_attack_warp_sweep",
    ["Warp Teleport"] = "hud_attack_warp_teleport",
}

VersusModeState.hud_text_keys = {
    ["ACQUIRING"] = "hud_state_acquiring",
    ["ACTIVE"] = "hud_state_active",
    ["AIMING"] = "hud_state_aiming",
    ["AIMING NET"] = "hud_state_aiming_net",
    ["AIMING THROW"] = "hud_state_aiming_throw",
    ["ALIGNING"] = "hud_state_aligning",
    ["APPROACHING"] = "hud_state_approaching",
    ["Attack already in progress"] = "hud_attack_already_active",
    ["Attack cancelled: target lost"] = "hud_attack_target_lost",
    ["Attack unavailable for this Captain loadout"] = "hud_attack_captain_loadout",
    ["Attack unavailable from this position"] = "hud_attack_position_unavailable",
    ["AUTO targeting"] = "hud_auto_targeting",
    ["CASUAL COMBAT"] = "hud_casual_combat",
    ["BLOCKED — NO TRAJECTORY"] = "hud_blocked_no_trajectory",
    ["BUSY"] = "hud_state_busy",
    ["CALLING HOUNDS"] = "hud_state_calling_hounds",
    ["CANCEL SENT"] = "hud_cancel_sent",
    ["CARRYING"] = "hud_state_carrying",
    ["CHARGE WIND-UP"] = "hud_state_charge_windup",
    ["CHARGING / AIMING"] = "hud_state_charging_aiming",
    ["COOLDOWN"] = "hud_state_cooldown",
    ["COMPLETE"] = "hud_state_complete",
    ["Consume requires a vomited target"] = "hud_consume_requires_vomit",
    ["Control ready."] = "hud_control_ready",
    ["Cannot change target during an attack"] = "hud_target_change_attack_busy",
    ["Cannot change targeting during an attack"] = "hud_target_mode_attack_busy",
    ["DETONATING"] = "hud_state_detonating",
    ["Detonation state unavailable"] = "hud_detonation_unavailable",
    ["Enable target lock before cycling targets"] = "hud_enable_lock_before_cycle",
    ["EXECUTING"] = "hud_state_executing",
    ["FIRED"] = "hud_state_fired",
    ["FIRING"] = "hud_state_firing",
    ["FUSE ARMED"] = "hud_state_fuse_armed",
    ["Fuse armed — detonation cannot be cancelled"] = "hud_fuse_not_cancellable",
    ["Hound summon state unavailable"] = "hud_hound_summon_unavailable",
    ["IGNITING"] = "hud_state_igniting",
    ["INTERRUPTED"] = "hud_state_interrupted",
    ["INVALID THROW ANIMATION"] = "hud_state_invalid_throw_animation",
    ["LASER AIMING"] = "hud_state_laser_aiming",
    ["Laser aim released"] = "hud_laser_released",
    ["LOCK MODE ONLY"] = "hud_lock_mode_only",
    ["Locked target lost; AUTO targeting"] = "hud_locked_target_lost",
    ["Longlas recharging"] = "hud_longlas_recharging",
    ["LUNGE WIND-UP"] = "hud_state_lunge_windup",
    ["Manual-aim enemies use the crosshair"] = "hud_manual_aim_crosshair",
    ["MISSED"] = "hud_state_missed",
    ["NEEDS DISTANCE"] = "hud_state_needs_distance",
    ["NO AIM"] = "hud_state_no_aim",
    ["NO CARRIED TARGET"] = "hud_state_no_carried_target",
    ["NO LOS"] = "hud_state_no_los",
    ["NO TARGET"] = "hud_state_no_target",
    ["NO TRAJECTORY"] = "hud_state_no_trajectory",
    ["NO VALID TRAJECTORY"] = "hud_no_valid_trajectory",
    ["No cancellable action in progress"] = "hud_no_cancellable_action",
    ["No carried target to throw"] = "hud_no_carried_target",
    ["No living survivor anchor"] = "hud_no_survivor_anchor",
    ["No usable floor below camera"] = "hud_no_floor",
    ["No valid grenade trajectory"] = "hud_no_grenade_trajectory",
    ["No valid target"] = "hud_no_valid_target",
    ["No valid targets"] = "hud_no_valid_targets",
    ["Not enough room at camera location"] = "hud_not_enough_room",
    ["Open space"] = "hud_open_space",
    ["Open space (not locked)"] = "hud_open_space_unlocked",
    ["OUT OF RANGE"] = "hud_state_out_of_range",
    ["NO ATTACK READY"] = "hud_state_no_attack_ready",
    ["PRIMARY"] = "attack_keybind",
    ["HEAVY"] = "heavy_attack_keybind",
    ["ALTERNATE"] = "alternate_attack_keybind",
    ["SPECIAL"] = "special_attack_keybind",
    ["Player"] = "hud_player",
    ["None"] = "hud_none",
    ["POUNCE WIND-UP"] = "hud_state_pounce_windup",
    ["READY"] = "hud_state_ready",
    ["READY (OPEN ARC)"] = "hud_ready_open_arc",
    ["READY — LANDING UNCONFIRMED"] = "hud_ready_landing_unconfirmed",
    ["READY — NET EXPIRES EARLY"] = "hud_ready_net_expires",
    ["RECOVERING"] = "hud_state_recovering",
    ["SELECTING"] = "hud_state_selecting",
    ["SELECTING GRENADE"] = "hud_state_selecting_grenade",
    ["SHOT ALLOWED — NET EXPIRES EARLY"] = "hud_shot_net_expires",
    ["STAGGERED"] = "hud_state_staggered",
    ["STRIKING"] = "hud_state_striking",
    ["SWITCHING WEAPON"] = "hud_state_switching_weapon",
    ["SUMMONING"] = "hud_state_summoning",
    ["TARGET CYCLE SENT"] = "hud_target_cycle_sent",
    ["TARGET LOCK OFF: free aim"] = "hud_target_lock_off_status",
    ["TARGET MODE SENT"] = "hud_target_mode_sent",
    ["Casual Combat enabled"] = "hud_casual_enabled_status",
    ["Advanced Combat enabled"] = "hud_advanced_enabled_status",
    ["Target distance unavailable"] = "hud_target_distance_unavailable",
    ["Target mode unavailable for this enemy"] = "hud_target_mode_unavailable",
    ["This specialist already uses manual crosshair aim"] = "hud_already_manual_aim",
    ["THROWING"] = "hud_state_throwing",
    ["THROWN"] = "hud_state_thrown",
    ["TOO CLOSE"] = "hud_state_too_close",
    ["TOO FAR"] = "hud_state_too_far",
    ["Unavailable"] = "hud_unavailable",
    ["UNAVAILABLE"] = "hud_unavailable",
    ["Visible to survivor"] = "hud_visible_to_survivor",
    ["WAITING"] = "hud_state_waiting",
    ["WINDING UP"] = "hud_state_winding_up",
    ["World"] = "hud_world",
    ["World point (not locked)"] = "hud_world_point_unlocked",
    ["Respawn unavailable"] = "hud_respawn_unavailable",
    ["Free-flight camera unavailable"] = "hud_camera_unavailable",
    ["Level collision unavailable"] = "hud_collision_unavailable",
    ["Not enough headroom"] = "hud_not_enough_headroom",
    ["not enough headroom"] = "hud_not_enough_headroom",
    ["too close to another controlled infected"] = "hud_too_close_controlled_infected",
    ["missing position or collision world"] = "hud_spawn_world_unavailable",
    ["no living survivor anchor"] = "hud_no_survivor_anchor",
    ["Random Safe selection requires the host"] = "hud_random_safe_host_only",
    ["native occluded spawn data is unavailable"] = "hud_native_spawn_data_unavailable",
    ["native spawn groups are unavailable"] = "hud_native_spawn_groups_unavailable",
    ["native occluded spawn query returned an inconsistent candidate list"] = "hud_native_spawn_inconsistent",
    ["all candidates failed final safety validation"] = "hud_all_spawn_candidates_failed",
    ["Invalid client camera position"] = "hud_invalid_client_camera",
    ["Navigation mesh unavailable"] = "hud_navmesh_unavailable",
    ["The minion spawn manager is unavailable."] = "hud_spawn_manager_unavailable",
    ["The selected infected could not be spawned at this location."] = "hud_specialist_spawn_failed",
    ["You already control an enemy."] = "hud_already_controlling_enemy",
}

function VersusModeState.localize_attack_label(attack_or_label)
    local label = type(attack_or_label) == "table" and attack_or_label.label or attack_or_label
    local key = label and VersusModeState.hud_attack_label_keys[label]

    if not key and type(label) == "string" then
        local normalized = string.lower(label)

        for stable_label, stable_key in pairs(VersusModeState.hud_attack_label_keys) do
            if string.lower(stable_label) == normalized then
                key = stable_key

                break
            end
        end
    end

    return key and mod:localize(key) or label or mod:localize("hud_attack_native")
end

function VersusModeState.localize_range_text(range_text)
    if type(range_text) ~= "string" then
        return range_text
    end

    local minimum, maximum = string.match(range_text, "^([%d%.]+)–([%d%.]+) m$")

    if minimum then
        return mod:localize("hud_range_metres", minimum, maximum)
    end

    return range_text
end

function VersusModeState.localize_hud_text(text)
    if type(text) ~= "string" then
        return text
    end

    local key = VersusModeState.hud_text_keys[text]

    if key then
        return mod:localize(key)
    end

    local value = string.match(text, "^Longlas cooldown: ([%d%.]+) s$")

    if value then
        return mod:localize("hud_longlas_cooldown", tonumber(value) or 0)
    end

    value = string.match(text, "^NETWORK INPUT WAITING: (.+)$")

    if value then
        return mod:localize("hud_network_waiting", value)
    end

    value = string.match(text, "^COMMAND SENT: (.+)$")

    if value then
        return mod:localize("hud_command_sent", VersusModeState.localize_hud_text(value))
    end

    value = string.match(text, "^LOCKED: (.+)$")

    if value then
        return mod:localize("hud_locked_target", value)
    end

    value = string.match(text, "^TARGET LOCK ON: (.+)$")

    if value then
        return mod:localize("hud_target_lock_on_status", value == "no target" and mod:localize("hud_no_target_lower") or value)
    end

    local count = string.match(text, "^(%d+) summoned hounds? still active$")

    if count then
        return mod:localize("hud_summoned_hounds_active", tonumber(count) or 0)
    end

    local attack_label, distance, maximum = string.match(text, "^(.-) is too far %(([%d%.]+) m; max ([%d%.]+) m%)$")

    if attack_label then
        return mod:localize(
            "hud_attack_too_far_max",
            VersusModeState.localize_attack_label(attack_label),
            tonumber(distance) or 0,
            tonumber(maximum) or 0
        )
    end

    attack_label, distance = string.match(text, "^(.-) is too close %(([%d%.]+) m%)$")

    if attack_label then
        return mod:localize("hud_attack_too_close", VersusModeState.localize_attack_label(attack_label), tonumber(distance) or 0)
    end

    attack_label, distance = string.match(text, "^(.-) is too far %(([%d%.]+) m%)$")

    if attack_label then
        return mod:localize("hud_attack_too_far", VersusModeState.localize_attack_label(attack_label), tonumber(distance) or 0)
    end

    attack_label = string.match(text, "^(.-) requires line of sight$")

    if attack_label then
        return mod:localize("hud_attack_requires_los", VersusModeState.localize_attack_label(attack_label))
    end

    attack_label = string.match(text, "^(.-) cannot be cancelled$")

    if attack_label then
        return mod:localize("hud_attack_not_cancellable", VersusModeState.localize_attack_label(attack_label))
    end

    attack_label = string.match(text, "^CANCELLED: (.+)$")

    if attack_label then
        return mod:localize("hud_attack_cancelled", VersusModeState.localize_attack_label(attack_label))
    end

    local slot = string.match(text, "^([A-Z]+) unavailable for this enemy$")

    if slot then
        return mod:localize("hud_slot_unavailable", VersusModeState.localize_hud_text(slot))
    end

    local breed, seconds = string.match(text, "^(.+) will be available in ([%d%.]+) seconds%.$")

    if breed then
        return mod:localize("hud_spawn_available_seconds", breed, tonumber(seconds) or 0)
    end

    local reason = string.match(text, "^Cannot respawn — (.-)%.$")

    if reason then
        return mod:localize("hud_cannot_respawn", VersusModeState.localize_hud_text(reason))
    end

    local visible_name = string.match(text, "^[Vv]isible to (.+)$")

    if visible_name then
        return mod:localize("hud_visible_to", visible_name)
    end

    local current_distance, survivor_name, minimum_distance = string.match(
        text,
        "^([%d%.]+) m from (.+) is below the ([%d%.]+) m minimum$"
    )

    if current_distance then
        return mod:localize(
            "hud_below_spawn_minimum",
            tonumber(current_distance) or 0,
            survivor_name,
            tonumber(minimum_distance) or 0
        )
    end

    current_distance, maximum = string.match(
        text,
        "^([%d%.]+) m from survivors exceeds the ([%d%.]+) m maximum$"
    )

    if current_distance then
        return mod:localize(
            "hud_above_spawn_maximum",
            tonumber(current_distance) or 0,
            tonumber(maximum) or 0
        )
    end

    minimum_distance = string.match(
        text,
        "^no occluded native spawn point was found at least ([%d%.]+) metres from every survivor$"
    )

    if minimum_distance then
        return mod:localize("hud_no_occluded_spawn", tonumber(minimum_distance) or 0)
    end

    reason = string.match(text, "^no candidate passed final safety checks %((.+)%)$")

    if reason then
        return mod:localize("hud_no_safe_candidate", VersusModeState.localize_hud_text(reason))
    end

    return text
end

VersusModeState.notice_text_keys = {
    ["released."] = "notice_control_released",
    ["camera became unavailable; control released."] = "notice_camera_lost",
    ["server authority was lost; control released."] = "notice_server_authority_lost",
    ["controlled enemy died; control released."] = "notice_controlled_enemy_died",
    ["controlled enemy died; native death resumed."] = "notice_controlled_enemy_died",
    ["controlled enemy was removed; control released."] = "notice_controlled_enemy_removed",
    ["controlled enemy disappeared; waiting for the host."] = "notice_controlled_enemy_removed",
    ["initialization did not complete; control released."] = "notice_control_initialization_failed",
    ["host restored your survivor role; control released."] = "notice_survivor_role_restored",
    ["Realms host disconnected; control released."] = "notice_realms_host_disconnected",
    ["client compatibility was lost; control released."] = "notice_client_compatibility_lost",
    ["infected-role test disabled; control released."] = "notice_infected_mode_disabled",
    ["mod disabled; control released."] = "notice_mod_disabled",
    ["the Realms client could not receive its enemy assignment."] = "notice_assignment_delivery_failed",
}

function VersusModeState.localize_notice(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    local key = VersusModeState.notice_text_keys[text]

    if key then
        return mod:localize(key)
    end

    local attack_label = string.match(text, "^started (.-)%.$")

    if attack_label then
        return mod:localize("notice_attack_started", VersusModeState.localize_attack_label(attack_label))
    end

    attack_label = string.match(text, "^cancelled (.-)%.$")

    if attack_label then
        return mod:localize("notice_attack_cancelled", VersusModeState.localize_attack_label(attack_label))
    end

    return VersusModeState.localize_hud_text(text)
end

function VersusModeState.echo_localized(key, ...)
    mod:echo("Versus Mode: " .. mod:localize(key, ...))
end

function VersusModeState.echo_notice(text)
    mod:echo("Versus Mode: " .. VersusModeState.localize_notice(text))
end

local function is_specialist_breed(breed)
    return breed and breed.tags and breed.tags.special == true
end

-- Keep the original network/status field name for compatibility with the
-- established Realms bridge. Crusher and Bulwark share the same toggle so an
-- older bridge payload remains sufficient for the expanded free-aim set.
function Specialist.target_mode_supported(state)
    local breed = state and state.breed
    local breed_name = breed and breed.name

    return breed
        and not breed.is_boss
        and not MANUAL_AIM_BREEDS[breed_name]
        and not HOUND_BREEDS[breed_name]
        and (is_specialist_breed(breed) or VersusModeState.controlled_elite_breeds[breed_name])
        or false
end

function Specialist.free_aim(state)
    local breed = state and state.breed
    local breed_name = breed and breed.name

    return breed
        and (MANUAL_AIM_BREEDS[breed_name]
            or HOUND_BREEDS[breed_name]
            or Specialist.target_mode_supported(state) and state.grenadier_target_lock == false)
        or false
end

local function attacks_for_breed(breed)
    if not breed then
        return nil
    end

    return ATTACKS[breed.name]
        or is_specialist_breed(breed) and GENERIC_SPECIALIST_ATTACKS
        or breed.is_boss and GENERIC_BOSS_ATTACKS
        or nil
end

local ATTACK_KEYBIND_SETTINGS = {
    primary = "attack_keybind",
    heavy = "heavy_attack_keybind",
    alternate = "alternate_attack_keybind",
    special = "special_attack_keybind",
    cancel = "cancel_action_keybind",
}
local KEYBIND_ACTIVATION_SETTINGS = {
    possess_keybind = "possess_keybind_hold",
    attack_keybind = "attack_keybind_hold",
    heavy_attack_keybind = "heavy_attack_keybind_hold",
    alternate_attack_keybind = "alternate_attack_keybind_hold",
    special_attack_keybind = "special_attack_keybind_hold",
    cancel_action_keybind = "cancel_action_keybind_hold",
    cycle_target_keybind = "cycle_target_keybind_hold",
    target_lock_keybind = "target_lock_keybind_hold",
    infected_menu_keybind = "infected_menu_keybind_hold",
    cycle_infected_spawn_keybind = "cycle_infected_spawn_keybind_hold",
}
local KEYBIND_FUNCTION_NAMES = {
    possess_keybind = "toggle_possession",
    attack_keybind = "primary_attack",
    heavy_attack_keybind = "heavy_attack",
    alternate_attack_keybind = "alternate_attack",
    special_attack_keybind = "special_attack",
    cancel_action_keybind = "cancel_action",
    cycle_target_keybind = "cycle_target",
    target_lock_keybind = "toggle_target_lock",
    infected_menu_keybind = "toggle_versus_roster_menu",
    cycle_infected_spawn_keybind = "cycle_infected_spawn",
}

local function setting(id)
    local value = mod:get(id)

    if value == nil then
        return DEFAULTS[id]
    end

    return value
end

function VersusModeState.echo_attack_log_localized(key, ...)
    if setting("show_attack_log") then
        VersusModeState.echo_localized(key, ...)
    end
end

function VersusModeState.echo_attack_log_notice(text)
    if setting("show_attack_log") then
        VersusModeState.echo_notice(text)
    end
end

mod.reset_camera_defaults = function()
    for _, id in ipairs({
        "mouse_sensitivity",
        "camera_distance",
        "camera_height",
        "specialist_camera_distance",
        "specialist_camera_horizontal_offset",
        "specialist_camera_height_adjustment",
        "default_first_person_view",
        "sniper_mouse_sensitivity_multiplier",
        "enable_sniper_scope_zoom",
        "sniper_scope_vertical_fov",
    }) do
        mod:set(id, DEFAULTS[id])
    end

    VersusModeState.echo_localized("notice_camera_settings_reset")
end

mod.reset_hud_layout = function()
    for _, id in ipairs({
        "enemy_panel_x",
        "enemy_panel_y",
        "hud_x",
        "hud_y",
        "hud_font_size",
        "hud_text_opacity",
    }) do
        mod:set(id, DEFAULTS[id])
    end

    VersusModeState.echo_localized("notice_hud_layout_reset")
end

local function fallback_key_name(key)
    local name = string.upper(string.gsub(tostring(key), "_", " "))

    return "[" .. name .. "]"
end

function VersusModeState.uses_custom_enemy_keybinds()
    return setting("use_custom_enemy_keybinds") == true
end

function VersusModeState.ingame_input_service()
    local input_manager = Managers.input

    if not input_manager or not input_manager.get_input_service then
        return nil
    end

    local ok, service = pcall(input_manager.get_input_service, input_manager, "Ingame")

    return ok and service or nil
end

function VersusModeState.native_input_action(input_service, action_name)
    if not input_service or not input_service.has or not input_service.get then
        return false
    end

    local has_ok, has_action = pcall(input_service.has, input_service, action_name)

    if not has_ok or not has_action then
        return false
    end

    local value_ok, value = pcall(input_service.get, input_service, action_name)

    return value_ok and value == true
end

function VersusModeState.native_input_device_types()
    local input_manager = Managers.input

    if input_manager and input_manager.device_in_use then
        local gamepad_ok, gamepad_in_use = pcall(input_manager.device_in_use, input_manager, "gamepad")

        if gamepad_ok and gamepad_in_use then
            local types_ok, device_types = pcall(InputUtils.get_gamepad_device_type)

            if types_ok and type(device_types) == "table" then
                return device_types
            end
        end
    end

    return { "keyboard", "mouse" }
end

function VersusModeState.native_binding_key_info(alias_name)
    local input_manager = Managers.input

    if not input_manager or not input_manager.alias_object then
        return nil
    end

    local alias_ok, aliases = pcall(input_manager.alias_object, input_manager, "Ingame")

    if not alias_ok or not aliases or not aliases.get_keys_for_alias then
        return nil
    end

    local key_ok, key_info = pcall(
        aliases.get_keys_for_alias,
        aliases,
        alias_name,
        VersusModeState.native_input_device_types()
    )

    return key_ok and key_info or nil
end

function VersusModeState.native_binding_label(alias_name)
    local label_ok, label = pcall(InputUtils.input_text_for_current_input_device, "Ingame", alias_name, false)

    if label_ok and label and label ~= "" and label ~= "[]" then
        return label
    end

    return "[UNBOUND]"
end

function VersusModeState.native_quick_wield_holdable(key_info)
    key_info = key_info or VersusModeState.native_binding_key_info("quick_wield")
    local main = key_info and key_info.main and string.lower(tostring(key_info.main)) or ""

    return main ~= ""
        and not string.find(main, "wheel", 1, true)
        and not string.find(main, "axis", 1, true)
end

function VersusModeState.native_key_held(input_service, key_name)
    if not input_service or not input_service.device or not key_name then
        return false, false
    end

    local type_ok, device_type = pcall(InputUtils.key_device_type, key_name)

    if not type_ok or not device_type then
        return false, false
    end

    local device_ok, device = pcall(input_service.device, input_service, device_type)

    if not device_ok or not device or not device.button_index or not device.held then
        return false, false
    end

    local index_ok, index = pcall(device.button_index, device, key_name)

    if not index_ok or index == nil then
        return false, false
    end

    local held_ok, held = pcall(device.held, device, index)

    return held_ok and held == true, held_ok
end

function VersusModeState.native_quick_wield_held(input_service, key_info)
    key_info = key_info or VersusModeState.native_binding_key_info("quick_wield")

    if not key_info or not VersusModeState.native_quick_wield_holdable(key_info) then
        return false, false
    end

    local main_held, main_available = VersusModeState.native_key_held(input_service, key_info.main)

    if not main_available or not main_held then
        return false, main_available
    end

    for i = 1, #(key_info.enablers or {}) do
        local enabled = VersusModeState.native_key_held(input_service, key_info.enablers[i])

        if not enabled then
            return false, true
        end
    end

    for i = 1, #(key_info.disablers or {}) do
        local disabled = VersusModeState.native_key_held(input_service, key_info.disablers[i])

        if disabled then
            return false, true
        end
    end

    return true, true
end

local function keybind_label(setting_id)
    local keys = setting_id and mod:get(setting_id)

    if type(keys) ~= "table" or #keys == 0 then
        return "[UNBOUND]"
    end

    local dmf = get_mod("DMF")

    if dmf and dmf.local_keys_to_keywatch_result then
        local key_info_ok, key_info = pcall(dmf.local_keys_to_keywatch_result, keys)

        if key_info_ok and key_info and key_info.main then
            local label_ok, label = pcall(InputUtils.localized_string_from_key_info, key_info)

            if label_ok and label and label ~= "" and label ~= "[]" then
                return label
            end
        end
    end

    local labels = {}

    for i = 2, #keys do
        labels[#labels + 1] = fallback_key_name(keys[i])
    end

    labels[#labels + 1] = fallback_key_name(keys[1])

    return table.concat(labels, "+")
end

local function hold_keybind_label(setting_id)
    return mod:localize("hud_hold_keybind", keybind_label(setting_id))
end

local function keybind_activation(binding_id)
    local activation_setting = KEYBIND_ACTIVATION_SETTINGS[binding_id]

    return activation_setting and setting(activation_setting) == true and "hold" or "press"
end

local function configured_keybind_label(binding_id)
    if keybind_activation(binding_id) == "hold" then
        return hold_keybind_label(binding_id)
    end

    return keybind_label(binding_id)
end

function VersusModeState.enemy_control_keybind_label(binding_id)
    if VersusModeState.uses_custom_enemy_keybinds() then
        return configured_keybind_label(binding_id), true
    end

    local alias_name = VersusModeState.vanilla_input_aliases[binding_id]
    local label = VersusModeState.native_binding_label(alias_name)

    if binding_id == "target_lock_keybind" then
        local holdable = VersusModeState.native_quick_wield_holdable()

        return holdable and mod:localize("hud_hold_keybind", label)
            or mod:localize("hud_hold_unavailable", label), holdable
    elseif binding_id == "cycle_target_keybind" then
        return VersusModeState.native_quick_wield_holdable()
            and mod:localize("hud_tap_keybind", label) or label, true
    end

    return label, true
end

function VersusModeState.target_hud_capabilities(state)
    local breed = state and state.breed
    local breed_name = breed and breed.name

    if not breed
        or MANUAL_AIM_BREEDS[breed_name]
        or HOUND_BREEDS[breed_name] then
        return false, false
    end

    return true, Specialist.target_mode_supported(state) or Specialist.casual_supported(state)
end

local function attack_keybind_label(slot)
    return VersusModeState.enemy_control_keybind_label(ATTACK_KEYBIND_SETTINGS[slot])
end

function VersusModeState.cancel_action_hud_line(state, attacks)
    local attack = state and state.requested_attack
    local cancellable = attack and attack.cancellable == true
        or state and state.remote_client and state.remote_attack_cancellable == true

    if not state or state.poxburster_armed then
        return nil
    end

    if state.attack_deadline then
        if not cancellable then
            return nil
        end
    else
        cancellable = false

        for _, configured_attack in pairs(attacks or {}) do
            if configured_attack and configured_attack.cancellable == true then
                cancellable = true

                break
            end
        end
    end

    if not cancellable then
        return nil
    end

    return {
        label = attack_keybind_label("cancel"),
        text = mod:localize("hud_cancel_attack"),
        kind = state.attack_deadline and "busy" or "normal",
    }
end

local function gameplay_time()
    local time_manager = Managers.time

    if not time_manager or not time_manager._timers then
        return 0
    end

    if time_manager:has_timer("gameplay") then
        return time_manager:time("gameplay")
    end

    return time_manager:has_timer("main") and time_manager:time("main") or 0
end

-- Lobby selection crosses the hub/preparation -> mission state boundary. The
-- gameplay timer is recreated during GameplayInitStepTimer, so a retry/deadline
-- captured just before that step can be stranded far in the future after the
-- clock resets to zero. The main timer is process-monotonic across that handoff.
local function main_time()
    local time_manager = Managers.time

    if time_manager and time_manager._timers and time_manager:has_timer("main") then
        return time_manager:time("main")
    end

    return gameplay_time()
end

local function update_keybind_hold(binding_id, is_pressed)
    local holds = mod._keybind_holds

    if not holds then
        holds = {}
        mod._keybind_holds = holds
    end

    local hold = holds[binding_id]

    if not hold then
        hold = {}
        holds[binding_id] = hold
    end

    local t = gameplay_time()

    if is_pressed == false then
        if hold.is_down then
            hold.last_duration = math_max(0, t - (hold.started_at or t))
            hold.was_long_hold = hold.long_hold == true or hold.last_duration >= setting("long_hold_threshold")
            hold.was_long_action_fired = hold.long_action_fired == true
        else
            hold.was_long_hold = false
            hold.was_long_action_fired = false
        end

        hold.is_down = false
        hold.started_at = nil
        hold.long_hold = false
        hold.long_action_fired = false

        return false
    end

    if hold.is_down then
        return false
    end

    hold.is_down = true
    hold.started_at = t
    hold.last_duration = 0
    hold.was_long_hold = false
    hold.was_long_action_fired = false
    hold.long_hold = false
    hold.long_action_fired = false

    return true
end

local function configured_keybind_should_fire(binding_id, is_pressed)
    local pressed_edge = update_keybind_hold(binding_id, is_pressed)
    local activation = keybind_activation(binding_id)

    if is_pressed == false then
        local hold = mod._keybind_holds and mod._keybind_holds[binding_id]

        if activation == "press" then
            return hold and not hold.was_long_hold
        end

        return hold and hold.was_long_hold and not hold.was_long_action_fired
    end

    -- One-shot Press actions wait for release so another action using the same
    -- physical key can claim Long hold without also firing the Press action.
    return false, pressed_edge
end

mod.keybind_hold_state = function(binding_id)
    local hold = mod._keybind_holds and mod._keybind_holds[binding_id]

    if not hold then
        return false, 0, false
    end

    local duration = hold.is_down and math_max(0, gameplay_time() - (hold.started_at or gameplay_time()))
        or hold.last_duration or 0

    return hold.is_down == true, duration, hold.long_hold == true or hold.was_long_hold == true
end

local function local_player()
    local player_manager = Managers.player

    return player_manager and player_manager.local_player_safe and player_manager:local_player_safe(1)
end

local function suppress_possession_smart_tag(tagger_unit)
    if not tagger_unit then
        return false
    end

    local state = mod._control

    if state and state.possessed and tagger_unit == state.player_unit then
        return true
    end

    if setting("enable_versus_mode")
        and VersusModeState.is_unit
        and VersusModeState.is_unit(tagger_unit) then
        return true
    end

    -- Smart tags are committed when their input is released. Keep a short
    -- guard after leaving possession so the release of a shared key cannot
    -- create a location/unit marker on the first normal-player frame.
    if gameplay_time() <= (mod._suppress_smart_tag_until or 0) then
        local player = local_player()

        return player and player.player_unit == tagger_unit
    end

    return false
end

local function is_server()
    local state = Managers.state
    local game_session = state and state.game_session

    return game_session and game_session:is_server()
end

local function safe_extension(unit, system_name)
    if not unit then
        return nil
    end

    local alive_ok, alive = pcall(function()
        return ALIVE[unit]
    end)

    if not alive_ok or not alive then
        return nil
    end

    local extension_ok, extension = pcall(function()
        return ScriptUnit.has_extension(unit, system_name)
    end)

    return extension_ok and extension or nil
end

-- Accessing a method on an extension that was destroyed earlier in the same
-- frame raises before a normal pcall(extension.method, ...) can begin. Keep
-- both the property lookup and invocation inside the protected closure.
local function safe_extension_call(extension, method_name, ...)
    if not extension then
        return false, nil
    end

    local args = { ... }

    return pcall(function()
        return extension[method_name](extension, table_unpack(args))
    end)
end

-- Darktide normally renders the local player's world body only while its
-- first-person extension is forced into third-person mode. Camera Freeflight
-- used to apply this flag every frame as an undocumented side effect. The
-- possession viewport otherwise sees only the player's first-person arms.
-- Snapshot the exact pre-camera value so manual possession, infected waiting
-- and death-camera hand-offs never leave the survivor presentation changed.
function VersusModeState.force_possession_camera_player_body()
    local player = local_player()
    local player_unit = player and player.player_unit
    local extension = safe_extension(player_unit, "first_person_system")
    local snapshot = mod._possession_camera_player_presentation

    if not extension then
        return false
    end

    if snapshot and snapshot.extension ~= extension then
        VersusModeState.restore_possession_camera_player_body()
        snapshot = nil
    end

    if not snapshot then
        snapshot = {
            extension = extension,
            old_force_third_person_mode = extension._force_third_person_mode,
            player_unit = player_unit,
        }
        mod._possession_camera_player_presentation = snapshot
        mod:info("Versus Mode: original player body forced to third-person rendering for the possession camera.")
    end

    extension._force_third_person_mode = true

    return true
end

function VersusModeState.restore_possession_camera_player_body()
    local snapshot = mod._possession_camera_player_presentation

    if not snapshot then
        return false
    end

    mod._possession_camera_player_presentation = nil

    local restored, failure = pcall(function()
        snapshot.extension._force_third_person_mode = snapshot.old_force_third_person_mode
    end)

    if not restored then
        mod:warning("Versus Mode: could not restore the original player camera presentation: %s", tostring(failure))
    end

    return restored
end

function VersusModeState.possession_camera_player_body_required()
    local free_flight = Managers.free_flight

    if not free_flight or type(free_flight.is_in_free_flight) ~= "function" then
        return false
    end

    local active_ok, free_flight_active = pcall(
        free_flight.is_in_free_flight,
        free_flight
    )

    if not active_ok or not free_flight_active then
        return false
    end

    local state = mod._control

    if state and state.possessed then
        return true
    end

    if mod._death_camera then
        return true
    end

    local role = mod._versus_role_test

    return role ~= nil
        and role.wait_camera_active == true
        and VersusModeState.local_active()
        or false
end

function VersusModeState.refresh_possession_camera_player_body()
    if VersusModeState.possession_camera_player_body_required() then
        local forced = VersusModeState.force_possession_camera_player_body()

        if not forced and not mod._possession_camera_player_presentation_warning then
            mod._possession_camera_player_presentation_warning = true
            mod:warning("Versus Mode: possession camera could not enable the original player's world body.")
        elseif forced then
            mod._possession_camera_player_presentation_warning = nil
        end

        return forced
    end

    mod._possession_camera_player_presentation_warning = nil

    return VersusModeState.restore_possession_camera_player_body()
end

function VersusModeState.normalize_peer_id(peer_id)
    return peer_id and string.lower(tostring(peer_id)) or nil
end

function VersusModeState.player_method_value(player, method_name)
    if not player then
        return nil
    end

    -- RemotePlayer userdata can remain in HUD arrays for one render after the
    -- connection destroys it. Even reading a method through __index then
    -- raises, so both lookup and invocation must live inside pcall.
    local method_ok, method = pcall(function()
        return player[method_name]
    end)

    if not method_ok or type(method) ~= "function" then
        return nil
    end

    local value_ok, value = pcall(method, player)

    return value_ok and value or nil
end

function VersusModeState.player_peer_id(player)
    local peer_id = VersusModeState.player_method_value(player, "peer_id")

    return VersusModeState.normalize_peer_id(peer_id)
end


function VersusModeState.player_local_id(player)
    return VersusModeState.player_method_value(player, "local_player_id")
end


function VersusModeState.player_account_id(player)
    local account_id = VersusModeState.player_method_value(player, "account_id")

    return account_id and string.lower(tostring(account_id)) or nil
end


function VersusModeState.player_character_id(player)
    local character_id = VersusModeState.player_method_value(player, "character_id")

    return character_id and string.lower(tostring(character_id)) or nil
end


function VersusModeState.control_for_unit(unit)
    local state = mod._control

    if state and state.unit == unit then
        return state
    end

    for _, remote_state in pairs(mod._remote_controls or {}) do
        if remote_state.unit == unit then
            return remote_state
        end
    end

    return nil
end

function VersusModeState.control_for_role(role)
    if not role then
        return nil
    end

    local state = mod._control

    if state and state.versus_role == role then
        return state
    end

    for _, remote_state in pairs(mod._remote_controls or {}) do
        if remote_state.versus_role == role then
            return remote_state
        end
    end

    return nil
end


function VersusModeState.control_for_blackboard(blackboard)
    local state = mod._control

    if state and state.blackboard == blackboard then
        return state
    end

    for _, remote_state in pairs(mod._remote_controls or {}) do
        if remote_state.blackboard == blackboard then
            return remote_state
        end
    end

    return nil
end


function VersusModeState.control_for_peer(peer_id)
    return peer_id and (mod._remote_controls or {})[VersusModeState.normalize_peer_id(peer_id)] or nil
end


function VersusModeState.any_authoritative_control()
    return mod._control ~= nil or next(mod._remote_controls or {}) ~= nil
end


function VersusModeState.role_for_peer(peer_id)
    peer_id = VersusModeState.normalize_peer_id(peer_id)

    for _, role in pairs(VersusModeState.roles()) do
        if role.infected_human and role.infected_peer_id == peer_id then
            return role
        end
    end

    return nil
end

function VersusModeState.state()
    local state = mod._infected_selector_state

    if not state then
        state = {
            selected_unique_id = nil,
            selector_until = 0,
        }
        mod._infected_selector_state = state
    end

    return state
end

function VersusModeState.roles()
    local roles = mod._versus_roles

    if not roles then
        roles = {}
        mod._versus_roles = roles
    end

    return roles
end

function VersusModeState.role_for_unique_id(unique_id)
    return unique_id ~= nil and VersusModeState.roles()[unique_id] or nil
end

function VersusModeState.role_for_replicated_token(token)
    if token == nil then
        return nil
    end

    token = tostring(token)

    for _, role in pairs(VersusModeState.roles()) do
        if role.replicated_client and tostring(role.replicated_token or role.infected_unique_id) == token then
            return role
        end
    end

    return nil
end

function VersusModeState.local_role()
    local player = local_player()

    if not player then
        mod._versus_role_test = nil

        return nil
    end

    local peer_id = VersusModeState.player_peer_id(player)
    local local_player_id = VersusModeState.player_local_id(player)

    for _, role in pairs(VersusModeState.roles()) do
        local same_player = role.infected_player == player
        local same_network_player = role.infected_human
            and peer_id ~= nil
            and role.infected_peer_id == peer_id
            and (role.infected_local_player_id == nil
                or tostring(role.infected_local_player_id) == tostring(local_player_id))

        if same_player or same_network_player then
            if role.replicated_client
                and (role.infected_player ~= player or role.infected_unit ~= player.player_unit) then
                VersusModeState.bind_replicated_player(role, player)
            end

            mod._versus_role_test = role

            return role
        end
    end

    mod._versus_role_test = nil

    return nil
end

function VersusModeState.count()
    local count = 0

    for _ in pairs(VersusModeState.roles()) do
        count = count + 1
    end

    return count
end

function VersusModeState.local_active()
    local role = VersusModeState.local_role()

    return setting("enable_versus_mode")
        and role
        and role.infected_unique_id
        and role.infected_human
        or false
end

function VersusModeState.local_infected_view()
    local state = mod._control

    if state and state.possessed then
        return state.versus_role ~= nil
    end

    return VersusModeState.local_active()
end

function VersusModeState.clear_owned_smart_tags(player_unit)
    if not player_unit then
        return
    end

    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, system = pcall(function()
        return extension_manager and extension_manager:system("smart_tag_system")
    end)

    if not system_ok or not system or not system._all_tags then
        return
    end

    local owned_tag_ids = {}

    for tag_id, tag in pairs(system._all_tags) do
        local tagger_ok, tagger_unit = pcall(function()
            return tag:tagger_unit()
        end)

        if tagger_ok and tagger_unit == player_unit then
            owned_tag_ids[#owned_tag_ids + 1] = tag_id
        end
    end

    for i = 1, #owned_tag_ids do
        pcall(system.cancel_tag, system, owned_tag_ids[i], player_unit, true)
    end
end

function VersusModeState.survivor_bot_is_frozen(player)
    return VersusModeState.test_active()
        and setting("freeze_survivor_bots")
        and player
        and not VersusModeState.player_is_human(player)
        and player.player_unit
        and not VersusModeState.is_unit(player.player_unit)
        or false
end

function VersusModeState.survivor_bot_unit_is_frozen(unit)
    local spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local player = spawn_manager and unit and spawn_manager:owner(unit)

    return VersusModeState.survivor_bot_is_frozen(player)
end

function VersusModeState.remove_shell_nameplate(element)
    local nameplate_units = element and element._nameplate_units

    if not nameplate_units then
        return
    end

    for _, role in pairs(VersusModeState.roles()) do
        local unit = role.infected_unit
        local data = unit and nameplate_units[unit]

        if data then
            if data.marker_id and Managers.event then
                Managers.event:trigger("remove_world_marker", data.marker_id)
            end

            nameplate_units[unit] = nil
        end
    end
end

function VersusModeState.run_without_bot_event_teleports(func, params)
    if not VersusModeState.test_active() then
        return func(params)
    end

    mod._versus_role_event_teleport_guard = true

    local ok, result = pcall(func, params)

    mod._versus_role_event_teleport_guard = nil

    if not ok then
        error(result)
    end

    return result
end

function VersusModeState.test_active()
    return setting("enable_versus_mode")
        and is_server()
        and next(VersusModeState.roles()) ~= nil
        or false
end

function VersusModeState.specialist_variants_enabled()
    if is_server() then
        return setting("enable_specialist_variants") == true
    end

    return mod._host_specialist_variants_enabled == true
end

function VersusModeState.spawn_selection_enabled()
    if is_server() then
        return setting("enable_infected_spawn_selection") == true
    end

    return mod._host_infected_spawn_selection_enabled == true
end

function VersusModeState.random_safe_spawn_enabled()
    if is_server() then
        return setting("enable_random_safe_spawn") == true
    end

    return mod._host_random_safe_spawn_enabled == true
end

function VersusModeState.automatic_respawn_enabled()
    if is_server() then
        return setting("enable_automatic_respawn") == true
    end

    return mod._host_automatic_respawn_enabled == true
end

function VersusModeState.bot_reinforcement_enabled(role)
    return role
        and not role.infected_human
        and is_server()
        and VersusModeState.automatic_respawn_enabled()
        and VersusModeState.random_safe_spawn_enabled()
        or false
end

function VersusModeState.controlled_traversal_enabled()
    if is_server() then
        return setting("enable_controlled_traversal") == true
    end

    return mod._host_controlled_traversal_enabled == true
end

function VersusModeState.controlled_traversal_breed_supported(breed, traversal_kind)
    if not breed or not breed.name then
        return false
    end

    local breed_name = breed.name
    local controllable_family = is_specialist_breed(breed)
        or VersusModeState.controlled_elite_breeds[breed_name]
        or breed.is_boss == true

    if not controllable_family then
        return false
    end

    local breed_actions = BreedActions[breed_name]

    if not breed_actions then
        return false
    elseif traversal_kind == "climb" then
        return breed_actions.climb ~= nil
    elseif traversal_kind == "door" then
        return breed_actions.open_door ~= nil
    end

    return breed_actions.climb ~= nil or breed_actions.open_door ~= nil
end

function VersusModeState.controlled_traversal_layer_supported(breed, layer_type)
    if not breed or type(layer_type) ~= "string" then
        return false
    end

    local breed_costs = breed.nav_tag_allowed_layers
    local default_costs = VersusModeState.navigation_cost_settings
        and VersusModeState.navigation_cost_settings.default_nav_tag_layers_minions
    local cost = breed_costs and breed_costs[layer_type]

    if cost == nil then
        cost = default_costs and default_costs[layer_type]
    end

    -- A zero cost disables a nav-tag layer in Darktide's traverse logic. The
    -- controlled route may temporarily make an already allowed selected link
    -- cheaper, but it must never turn a breed-forbidden link back on.
    return type(cost) == "number" and cost > 0
end

function VersusModeState.controlled_traversal_animation_events(anim_events)
    if type(anim_events) == "string" and anim_events ~= "" then
        return { anim_events }
    elseif type(anim_events) == "table" and #anim_events > 0 then
        local events = {}

        for i = 1, #anim_events do
            if type(anim_events[i]) ~= "string" or anim_events[i] == "" then
                return nil
            end

            events[#events + 1] = anim_events[i]
        end

        return events
    end

    return nil
end


function VersusModeState.controlled_traversal_threshold_data(breed, direction, jump_type, height)
    local template = breed and breed.smart_object_template
    local thresholds = template and (direction == "up"
        and template.jump_up_anim_thresholds
        or template.jump_down_anim_thresholds)

    if type(thresholds) ~= "table" or type(height) ~= "number" or height < 0 then
        return nil
    end

    -- This deliberately mirrors BtClimbAction:_jump_anim_event's strict '<'
    -- threshold selection so the preflight validates the exact event pool the
    -- native action will randomly choose from.
    for i = 1, #thresholds do
        local threshold = thresholds[i]

        if type(threshold) == "table"
            and type(threshold.height_threshold) == "number"
            and height < threshold.height_threshold then
            local jump_data = threshold[jump_type]

            return type(jump_data) == "table" and jump_data or nil
        end
    end

    return nil
end

function VersusModeState.controlled_traversal_timed_events_supported(anim_events, timings)
    local events = VersusModeState.controlled_traversal_animation_events(anim_events)

    if not events or type(timings) ~= "table" then
        return false
    end

    for i = 1, #events do
        if type(timings[events[i]]) ~= "number" then
            return false
        end
    end

    return true
end

function VersusModeState.controlled_traversal_ending_events_supported(anim_events, ending_move_states)
    local events = VersusModeState.controlled_traversal_animation_events(anim_events)

    if not events or type(ending_move_states) ~= "table" then
        return false
    end

    for i = 1, #events do
        if ending_move_states[events[i]] == nil then
            return false
        end
    end

    return true
end


function VersusModeState.controlled_traversal_landing_supported(action_data, jump_data)
    local jump = type(jump_data) == "table" and jump_data.jump
    local land = type(jump_data) == "table" and jump_data.land
    local jump_events = jump and VersusModeState.controlled_traversal_animation_events(jump.anim_events)
    local land_events = land and VersusModeState.controlled_traversal_animation_events(land.anim_events)
    local anim_timings = action_data and action_data.anim_timings
    local land_timings = action_data and action_data.land_timings
    local ending_move_states = action_data and action_data.ending_move_states

    if not jump_events or not land_events or type(anim_timings) ~= "table"
        or type(ending_move_states) ~= "table" then
        return false
    end

    for i = 1, #land_events do
        local land_event = land_events[i]

        if ending_move_states[land_event] == nil then
            return false
        end

        for j = 1, #jump_events do
            local jump_event = jump_events[j]
            local landing_duration = type(land_timings) == "table" and land_timings[jump_event]
                or anim_timings[land_event]

            if type(landing_duration) ~= "number" then
                return false
            end
        end
    end

    return true
end

function VersusModeState.controlled_traversal_data_position(value)
    if value == nil then
        return nil
    end

    local unbox_ok, position = pcall(function()
        return value:unbox()
    end)

    return unbox_ok and position or value
end

function VersusModeState.controlled_traversal_position_box(value)
    local position = VersusModeState.controlled_traversal_data_position(value)

    if not position then
        return nil
    end

    local box_ok, position_box = pcall(Vector3Box, position)

    return box_ok and position_box or nil
end

function VersusModeState.controlled_traversal_animation_supported(breed, action_data, near_position, far_position, smart_object_data)
    if not breed
        or type(action_data) ~= "table"
        or type(action_data.rotation_duration) ~= "number"
        or action_data.rotation_duration <= 0
        or not near_position
        or not far_position
        or type(smart_object_data) ~= "table" then
        return false
    end

    local ledge_type = smart_object_data.ledge_type
    local jump_type = ledge_type == "edge" and "edge"
        or (ledge_type == "narrow_fence" or ledge_type == "thick_fence") and "fence"

    if not jump_type then
        return false
    end

    local ledge_position

    if ledge_type == "thick_fence" then
        local first = VersusModeState.controlled_traversal_data_position(smart_object_data.ledge_position1)
        local second = VersusModeState.controlled_traversal_data_position(smart_object_data.ledge_position2)

        if not first or not second then
            return false
        end

        ledge_position = vector3_distance(first, near_position) < vector3_distance(second, near_position)
            and first or second
    else
        ledge_position = VersusModeState.controlled_traversal_data_position(smart_object_data.ledge_position)
    end

    -- BtClimbAction always boxes this authored point, including for an edge.
    if not ledge_position then
        return false
    end

    local near_height = Vector3.z(near_position)
    local far_height = Vector3.z(far_position)

    if ledge_type == "edge" then
        if near_height <= far_height then
            local height = far_height - near_height
            local jump_data = VersusModeState.controlled_traversal_threshold_data(
                breed,
                "up",
                "edge",
                height
            )
            local jump = jump_data and jump_data.jump

            return jump
                and VersusModeState.controlled_traversal_timed_events_supported(
                    jump.anim_events,
                    action_data.anim_timings
                )
                and VersusModeState.controlled_traversal_ending_events_supported(
                    jump.anim_events,
                    action_data.ending_move_states
                )
                or false
        end

        local jump_data = VersusModeState.controlled_traversal_threshold_data(
            breed,
            "down",
            "edge",
            near_height - far_height
        )

        return VersusModeState.controlled_traversal_landing_supported(action_data, jump_data)
    end

    local ledge_height = Vector3.z(ledge_position)
    local climb_height = ledge_height - near_height
    local fall_height = ledge_height - far_height

    if climb_height < 0 or fall_height < 0 then
        return false
    end

    local climb_data = VersusModeState.controlled_traversal_threshold_data(
        breed,
        "up",
        "fence",
        climb_height
    )
    local climb_jump = climb_data and climb_data.jump
    local fall_data = VersusModeState.controlled_traversal_threshold_data(
        breed,
        "down",
        "fence",
        fall_height
    )

    return climb_jump
        and VersusModeState.controlled_traversal_timed_events_supported(
            climb_jump.anim_events,
            action_data.anim_timings
        )
        and VersusModeState.controlled_traversal_landing_supported(action_data, fall_data)
        or false
end

function VersusModeState.controlled_climb_candidate_supported(state, layer_type, near_position, far_position, smart_object_data, origin)
    local breed = state and state.breed
    local breed_actions = breed and BreedActions[breed.name]
    local action_data = breed_actions and breed_actions.climb

    if not VersusModeState.controlled_traversal_breed_supported(breed, "climb")
        or not VersusModeState.controlled_traversal_layer_supported(breed, layer_type)
        or not VersusModeState.controlled_traversal_animation_supported(
            breed,
            action_data,
            near_position,
            far_position,
            smart_object_data
        ) then
        return false
    end

    -- A Realms client does not own the minion navigation extension. The host
    -- separately replicates its authoritative candidate; only run this final
    -- per-breed reachability preflight where that traverse logic exists.
    if state.remote_client then
        return true
    end

    local nav_ok, nav_world = safe_extension_call(state.navigation, "nav_world")
    local traverse_ok, traverse_logic = safe_extension_call(state.navigation, "traverse_logic")

    if not origin or not nav_ok or not nav_world or not traverse_ok or not traverse_logic then
        return false
    end

    local query_ok, can_reach_entrance = pcall(
        VersusModeState.nav_queries.ray_can_go,
        nav_world,
        origin,
        near_position,
        traverse_logic,
        VersusModeState.traversal_entrance_nav_projection,
        VersusModeState.traversal_entrance_nav_projection
    )

    return query_ok and can_reach_entrance == true
end

function VersusModeState.controlled_traversal_entrance_distance(state)
    local radius = state and state.breed and state.breed.player_locomotion_constrain_radius

    if type(radius) ~= "number"
        or radius < VersusModeState.traversal_entrance_commit_distance + 0.15 then
        return VersusModeState.traversal_entrance_commit_distance
    end

    return math_max(
        VersusModeState.traversal_entrance_commit_distance,
        math_min(
            VersusModeState.traversal_entrance_commit_max_distance,
            radius * VersusModeState.traversal_entrance_commit_radius_scale
                + VersusModeState.traversal_entrance_commit_radius_padding
        )
    )
end

function VersusModeState.controlled_traversal_link_rejected(state, smart_object_id, t)
    local rejected = state and state.controlled_traversal_rejected_links
    local rejected_until = rejected and rejected[smart_object_id]

    if type(rejected_until) ~= "number" then
        return false
    end

    if (t or gameplay_time()) < rejected_until then
        return true
    end

    rejected[smart_object_id] = nil

    return false
end

function VersusModeState.reject_controlled_traversal_link(state, smart_object_id, reason)
    if not state or smart_object_id == nil then
        return false
    end

    state.controlled_traversal_rejected_links = state.controlled_traversal_rejected_links or {}
    state.controlled_traversal_rejected_links[smart_object_id] = gameplay_time()
        + VersusModeState.traversal_rejected_link_duration
    state.contextual_traversal_candidate = nil
    state.contextual_traversal_refresh_at = 0
    state.traversal_highlight_cache = nil

    mod:info(
        "Versus Mode: temporarily hid smart object %s from controlled %s after %s.",
        tostring(smart_object_id),
        tostring(state.breed and state.breed.name or "enemy"),
        tostring(reason or "an unusable approach")
    )

    return true
end

function VersusModeState.controlled_traversal_carrying_player(state)
    if not state
        or not state.breed
        or state.breed.name ~= "chaos_beast_of_nurgle" then
        return false
    end

    local behavior_component = state.blackboard and state.blackboard.behavior

    return behavior_component and HEALTH_ALIVE[behavior_component.consumed_unit] == true or false
end

function VersusModeState.valid_variant(breed_name, variant_id)
    return variant_id == nil
        or type(variant_id) == "string"
        and VersusModeState.variant_breeds[variant_id] == breed_name
        and VersusModeState.specialist_variants_enabled()
end

function VersusModeState.respawn_label(breed_name, variant_id)
    if variant_id and VersusModeState.valid_variant(breed_name, variant_id) then
        for i = 1, #VersusModeState.variant_spawn_choices do
            local variant = VersusModeState.variant_spawn_choices[i]

            if variant.name == breed_name and variant.variant_id == variant_id then
                return mod:localize(variant.label_key)
            end
        end
    end

    for i = 1, #VersusModeState.respawn_breeds do
        local entry = VersusModeState.respawn_breeds[i]

        if entry.name == breed_name then
            local breed = VersusModeState.breeds[breed_name]
            local display_name = breed and breed.display_name

            if display_name then
                local localized_ok, localized_name = pcall(Localize, display_name)

                if localized_ok and localized_name and localized_name ~= display_name then
                    return localized_name
                end
            end

            return entry.label
        end
    end

    return breed_name and string.gsub(breed_name, "_", " ") or "specialist"
end

function VersusModeState.remote_respawn_notice_message(payload)
    if type(payload) ~= "table" or type(payload.notice_key) ~= "string" then
        return nil
    end

    local key = payload.notice_key

    if key == "notice_automatic_respawn_retry" then
        local reason = type(payload.notice_reason) == "string"
            and string.sub(payload.notice_reason, 1, 256)
            or mod:localize("hud_invalid_location")

        return mod:localize(key, VersusModeState.localize_hud_text(reason))
    elseif key == "notice_strike_team_advanced_redeploy" then
        return mod:localize(key)
    end

    local breed_name = type(payload.notice_breed) == "string" and payload.notice_breed or nil

    if not breed_name or not VersusModeState.breeds[breed_name] then
        return nil
    end

    local variant_id = type(payload.notice_variant) == "string"
        and VersusModeState.valid_variant(breed_name, payload.notice_variant)
        and payload.notice_variant
        or nil
    local label = VersusModeState.respawn_label(breed_name, variant_id)

    if key == "infected_spawn_selected" then
        return mod:localize(key, label)
    elseif key == "notice_next_infected_spawn" then
        local seconds = type(payload.notice_seconds) == "number" and payload.notice_seconds or 0

        seconds = math_max(0, math_min(3600, seconds))

        return mod:localize(key, label, seconds)
    elseif key == "notice_spawn_ready_automatic" then
        return mod:localize(key, label)
    elseif key == "notice_spawn_ready_random_safe" or key == "notice_spawn_ready_manual" then
        return mod:localize(key, label, configured_keybind_label("possess_keybind"))
    end

    return nil
end

function VersusModeState.available_spawn_choices()
    local choices = {}

    for i = 1, #VersusModeState.respawn_breeds do
        local entry = VersusModeState.respawn_breeds[i]

        if VersusModeState.breeds[entry.name] then
            choices[#choices + 1] = entry
        end
    end

    if VersusModeState.specialist_variants_enabled() then
        for i = 1, #VersusModeState.variant_spawn_choices do
            local entry = VersusModeState.variant_spawn_choices[i]

            if VersusModeState.breeds[entry.name] then
                choices[#choices + 1] = entry
            end
        end
    end

    return choices
end

function VersusModeState.cycle_respawn(role, requesting_peer_id, breed_name, variant_id)
    if not is_server()
        or not VersusModeState.spawn_selection_enabled()
        or not role
        or not role.infected_human
        or role.assigned_boss_unit
        or VersusModeState.control_for_peer(role.infected_peer_id) then
        return false
    end

    local choices = VersusModeState.available_spawn_choices()

    if #choices == 0 then
        return false
    end

    local current_index = 0

    for i = 1, #choices do
        local entry = choices[i]

        if entry.name == role.respawn_breed and entry.variant_id == role.respawn_variant then
            current_index = i

            break
        end
    end

    local selected = choices[current_index % #choices + 1]

    if breed_name ~= nil then
        selected = nil
        for i = 1, #choices do
            if choices[i].name == breed_name and choices[i].variant_id == variant_id then
                selected = choices[i]
                break
            end
        end
        if not selected then
            return false
        end
    end

    role.respawn_breed = selected.name
    role.respawn_variant = selected.variant_id
    role.last_respawn_breed = selected.name
    role.respawn_ready_notified = false
    role.spawn_check = nil
    role.spawn_check_at = nil

    if not role.respawn_ready_at then
        role.respawn_ready_at = gameplay_time() + math_max(0, setting("infected_respawn_delay"))
    end

    -- Deliberately keep respawn_ready_at: cycling is a choice, not a way to
    -- shorten or restart the current respawn timer.
    local label = VersusModeState.respawn_label(selected.name, selected.variant_id)

    if requesting_peer_id then
        VersusModeState.send_remote_respawn_notice(requesting_peer_id, "infected_spawn_selected", role)
    elseif VersusModeState.local_role() == role then
        mod:echo(mod:localize("infected_spawn_selected", label))
    end

    mod:info(
        "Versus Mode: %s selected next infected spawn %s (variant %s); timer preserved.",
        tostring(role.infected_name or requesting_peer_id or "local infected"),
        tostring(selected.name),
        tostring(selected.variant_id or "normal")
    )
    VersusModeState.publish_roster()

    return true
end

function VersusModeState.is_unit(unit)
    if not unit then
        return false
    end

    for _, role in pairs(VersusModeState.roles()) do
        if role.infected_unit == unit then
            return true
        end
    end

    return false
end

function VersusModeState.player_name(player)
    if player and player.name then
        local ok, name = pcall(player.name, player)

        if ok and name and name ~= "" then
            return tostring(name)
        end
    end

    return "Unknown player"
end

function VersusModeState.player_is_human(player)
    if player and player.is_human_controlled then
        local ok, human = pcall(player.is_human_controlled, player)

        return ok and human == true
    end

    return false
end

function VersusModeState.player_is_hogtied(unit)
    local unit_data_extension = safe_extension(unit, "unit_data_system")

    if not unit_data_extension then
        return false
    end

    local ok, is_hogtied = pcall(function()
        local character_state_component = unit_data_extension:read_component("character_state")

        return character_state_component and VersusModeState.player_unit_status.is_hogtied(character_state_component)
    end)

    return ok and is_hogtied == true
end

function VersusModeState.candidates()
    local candidates = {}
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local local_human = local_player()

    if not players then
        return candidates
    end

    for unique_id, player in pairs(players) do
        local unit = player and player.player_unit
        local is_current_infected = VersusModeState.role_for_unique_id(unique_id) ~= nil

        -- Do not appropriate an ordinary captured/dead player as the test
        -- shell. The role's own hogtied unit remains selectable so the same
        -- Apply binding can restore it.
        if unit and ALIVE[unit] and (is_current_infected or not VersusModeState.player_is_hogtied(unit)) then
            candidates[#candidates + 1] = {
                unique_id = unique_id,
                player = player,
                unit = unit,
                name = VersusModeState.player_name(player),
                human = VersusModeState.player_is_human(player),
                local_human = player == local_human,
                peer_id = VersusModeState.player_peer_id(player),
                local_player_id = VersusModeState.player_local_id(player),
                account_id = VersusModeState.player_account_id(player),
                character_id = VersusModeState.player_character_id(player),
            }
        end
    end

    table.sort(candidates, function(a, b)
        if a.local_human ~= b.local_human then
            return a.local_human
        end

        if a.human ~= b.human then
            return a.human
        end

        if a.name == b.name then
            return tostring(a.unique_id) < tostring(b.unique_id)
        end

        return a.name < b.name
    end)

    return candidates
end

function VersusModeState.find_player_by_token(token)
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()

    if not players then
        return nil, nil
    end

    for unique_id, player in pairs(players) do
        if tostring(unique_id) == tostring(token) then
            return unique_id, player
        end
    end

    return nil, nil
end

function VersusModeState.find_player_by_identity(token, peer_id, local_player_id)
    local unique_id, player = VersusModeState.find_player_by_token(token)

    if player then
        return unique_id, player
    end

    peer_id = VersusModeState.normalize_peer_id(peer_id)

    if not peer_id then
        return nil, nil
    end

    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()

    if not players then
        return nil, nil
    end

    for candidate_unique_id, candidate in pairs(players) do
        local candidate_local_id = VersusModeState.player_local_id(candidate)
        local local_id_matches = local_player_id == nil
            or tostring(candidate_local_id) == tostring(local_player_id)

        if local_id_matches and VersusModeState.player_peer_id(candidate) == peer_id then
            return candidate_unique_id, candidate
        end
    end

    return nil, nil
end

function VersusModeState.bind_replicated_player(role, player)
    role.infected_player = player

    local replicated_unit = player and player.player_unit

    if replicated_unit == role.infected_unit then
        return
    end

    VersusModeState.restore_unit(role)
    role.infected_unit = replicated_unit
    role.infected_visibility = safe_extension(replicated_unit, "player_visibility_system")

    local visible_ok, visible = safe_extension_call(role.infected_visibility, "visible")

    role.old_visibility = not visible_ok or visible ~= false
end

function VersusModeState.network_unit_id(unit)
    local unit_spawner = Managers.state and Managers.state.unit_spawner

    if not unit_spawner or not unit then
        return nil
    end

    local ok, unit_id = pcall(unit_spawner.game_object_id, unit_spawner, unit)

    return ok and unit_id or nil
end

function VersusModeState.unit_from_network_id(unit_id)
    local unit_spawner = Managers.state and Managers.state.unit_spawner

    unit_id = tonumber(unit_id)

    if not unit_spawner or not unit_id or unit_id ~= unit_id or unit_id % 1 ~= 0 then
        return nil
    end

    local ok, unit = pcall(unit_spawner.unit, unit_spawner, unit_id)

    return ok and unit or nil
end

-- The normal minion bone-LOD registration is evaluated from Darktide's
-- player viewport. A Realms Heretic watches through a separate free-flight
-- possession camera while their Operative body can be tens of metres away;
-- the native LOD can therefore stop evaluating the controlled model even
-- though it fills the possession view. Re-register only that local controlled
-- unit with a large bounds radius, then restore the breed radius on release.
function VersusModeState.ensure_controlled_animation_lod(state)
    if not state
        or not state.possessed
        or not ALIVE[state.unit]
        or state.controller_peer_id and not state.remote_client
        or not state.breed
        or state.breed.use_bone_lod ~= true then
        return false
    end

    local manager = Managers.state and Managers.state.bone_lod
    local animation = safe_extension(state.unit, "animation_system")

    if not manager or not animation then
        return false
    end

    local registration = state.controlled_animation_lod_registration

    if registration
        and registration.animation == animation
        and animation.bone_lod_extension_id == registration.registration_id then
        return true
    end

    -- A rebuilt animation extension has already disposed its old registration.
    -- Forget our stale bookkeeping and promote the replacement below.
    state.controlled_animation_lod_registration = nil

    local original_id = animation.bone_lod_extension_id

    if original_id == nil then
        return false
    end

    local removed = pcall(manager.unregister_unit, manager, original_id)

    if not removed then
        return false
    end

    local registered, replacement_id = pcall(
        manager.register_unit,
        manager,
        state.unit,
        VersusModeState.controlled_animation_lod_radius,
        true
    )

    if not registered or replacement_id == nil then
        local restored, restored_id = pcall(
            manager.register_unit,
            manager,
            state.unit,
            state.breed.bone_lod_radius or 1,
            true
        )

        animation.bone_lod_extension_id = restored and restored_id or nil

        if gameplay_time() >= (state.animation_lod_warning_at or 0) then
            state.animation_lod_warning_at = gameplay_time() + 3
            mod:warning(
                "Versus Mode: could not promote the controlled %s animation LOD.",
                tostring(state.breed.name)
            )
        end

        return false
    end

    animation.bone_lod_extension_id = replacement_id
    state.controlled_animation_lod_registration = {
        animation = animation,
        original_radius = state.breed.bone_lod_radius or 1,
        registration_id = replacement_id,
    }

    if not state.animation_lod_promotion_logged then
        state.animation_lod_promotion_logged = true
        mod:info(
            "Versus Mode: kept the locally viewed %s at active animation LOD.",
            tostring(state.breed.name)
        )
    end

    return true
end

function VersusModeState.restore_controlled_animation_lod(state)
    local registration = state and state.controlled_animation_lod_registration

    if not registration then
        return false
    end

    state.controlled_animation_lod_registration = nil

    local manager = Managers.state and Managers.state.bone_lod
    local animation = ALIVE[state.unit] and safe_extension(state.unit, "animation_system") or nil

    if not manager
        or not animation
        or animation ~= registration.animation
        or animation.bone_lod_extension_id ~= registration.registration_id then
        return false
    end

    pcall(manager.unregister_unit, manager, registration.registration_id)

    local restored, restored_id = pcall(
        manager.register_unit,
        manager,
        state.unit,
        registration.original_radius,
        true
    )

    animation.bone_lod_extension_id = restored and restored_id or nil

    return restored and restored_id ~= nil
end

-- The native animation extension sends an event index that is private to the
-- unit's state machine. Capture that exact index while the ordinary Darktide
-- RPC is being emitted so the Realms fallback can mirror it without guessing
-- an event-name lookup or restarting animations that arrived normally.
function VersusModeState.capture_remote_animation_rpc(
    rpc_name,
    unit_id,
    event_index,
    variable_index,
    variable_value,
    variable_name
)
    local capture = mod._remote_animation_capture

    if not capture
        or capture.rpc_name ~= rpc_name
        or capture.unit_id ~= unit_id
        or type(event_index) ~= "number"
        or event_index ~= event_index
        or event_index % 1 ~= 0 then
        return false
    end

    capture.event_index = event_index

    if rpc_name == "rpc_minion_anim_event_variable_float" then
        capture.variable_index = variable_index
        capture.variable_value = variable_value
        capture.variable_name = variable_name
    end

    return true
end

function VersusModeState.send_remote_animation_capture(state, capture)
    local bridge = mod._realms_compat

    if not state
        or not state.possessed
        or not state.controller_peer_id
        or not bridge
        or type(bridge.send_animation) ~= "function"
        or not capture
        or type(capture.event_index) ~= "number" then
        return false
    end

    state.remote_animation_sequence = (state.remote_animation_sequence or 0) + 1

    local payload = {
        event_index = capture.event_index,
        event_name = type(capture.event_name) == "string"
            and string.sub(capture.event_name, 1, 128) or nil,
        sequence = state.remote_animation_sequence,
        unit_id = capture.unit_id,
    }

    if type(capture.variable_index) == "number"
        and type(capture.variable_value) == "number" then
        payload.variable_index = capture.variable_index
        payload.variable_value = capture.variable_value
        payload.variable_name = type(capture.variable_name) == "string"
            and string.sub(capture.variable_name, 1, 128) or nil
    end

    local sent, send_error = bridge.send_animation(state.controller_peer_id, payload)
    local t = gameplay_time()

    if not sent and t >= (state.remote_animation_warning_at or 0) then
        state.remote_animation_warning_at = t + 3
        mod:warning(
            "Versus Mode: controlled animation fallback could not be sent to %s: %s.",
            tostring(state.controller_peer_id),
            tostring(send_error or "unknown transport failure")
        )
    end

    return sent == true
end

function VersusModeState.remote_animation_entry_matches(entry, event_index, variable_index)
    return entry
        and entry.event_index == event_index
        and (entry.variable_index == nil) == (variable_index == nil)
        and (entry.variable_index == nil or entry.variable_index == variable_index)
end

function VersusModeState.prune_remote_animation_credits(state, t)
    local credits = state and state.remote_animation_native_credits

    if not credits then
        return
    end

    for i = #credits, 1, -1 do
        if t - (credits[i].received_at or 0) > VersusModeState.remote_animation_credit_lifetime then
            table.remove(credits, i)
        end
    end
end

function VersusModeState.note_remote_animation_rpc(unit_id, event_index, variable_index)
    local state = mod._control

    if not state
        or not state.remote_client
        or state.network_unit_id ~= unit_id
        or type(event_index) ~= "number" then
        return false
    end

    local pending = state.remote_animation_pending or {}

    state.remote_animation_pending = pending

    for i = 1, #pending do
        if VersusModeState.remote_animation_entry_matches(pending[i], event_index, variable_index) then
            table.remove(pending, i)

            return true
        end
    end

    local t = gameplay_time()
    local credits = state.remote_animation_native_credits or {}

    state.remote_animation_native_credits = credits
    VersusModeState.prune_remote_animation_credits(state, t)
    credits[#credits + 1] = {
        event_index = event_index,
        received_at = t,
        variable_index = variable_index,
    }

    if #credits > VersusModeState.remote_animation_queue_limit then
        table.remove(credits, 1)
    end

    return true
end

function VersusModeState.apply_remote_animation(payload)
    local state = mod._control

    if not state or not state.remote_client or type(payload) ~= "table" then
        return false
    end

    local unit_id = payload.unit_id
    local sequence = payload.sequence
    local event_index = payload.event_index
    local variable_index = payload.variable_index
    local variable_value = payload.variable_value

    if type(unit_id) ~= "number"
        or unit_id ~= state.network_unit_id
        or unit_id ~= unit_id
        or unit_id % 1 ~= 0
        or type(sequence) ~= "number"
        or sequence ~= sequence
        or sequence % 1 ~= 0
        or sequence < 1
        or type(event_index) ~= "number"
        or event_index ~= event_index
        or event_index % 1 ~= 0
        or event_index < 0 then
        return false
    end

    if variable_index ~= nil
        and (type(variable_index) ~= "number"
            or variable_index ~= variable_index
            or variable_index % 1 ~= 0
            or variable_index < 0
            or type(variable_value) ~= "number"
            or variable_value ~= variable_value
            or math.abs(variable_value) > 1000000) then
        return false
    end

    if payload.variable_name ~= nil
        and (type(payload.variable_name) ~= "string" or #payload.variable_name > 128) then
        return false
    end

    if payload.event_name ~= nil
        and (type(payload.event_name) ~= "string" or #payload.event_name > 128) then
        return false
    end

    if sequence <= (state.remote_animation_last_sequence or 0) then
        return false
    end

    state.remote_animation_last_sequence = sequence

    local t = gameplay_time()
    local credits = state.remote_animation_native_credits or {}

    state.remote_animation_native_credits = credits
    VersusModeState.prune_remote_animation_credits(state, t)

    for i = 1, #credits do
        if VersusModeState.remote_animation_entry_matches(credits[i], event_index, variable_index) then
            table.remove(credits, i)

            return true
        end
    end

    local pending = state.remote_animation_pending or {}

    state.remote_animation_pending = pending
    pending[#pending + 1] = {
        apply_at = t + VersusModeState.remote_animation_fallback_delay,
        event_index = event_index,
        event_name = payload.event_name,
        sequence = sequence,
        variable_index = variable_index,
        variable_name = payload.variable_name,
        variable_value = variable_value,
    }

    if #pending > VersusModeState.remote_animation_queue_limit then
        table.remove(pending, 1)
    end

    return true
end

function VersusModeState.update_remote_animation_fallback(state)
    if not state or not state.remote_client or not ALIVE[state.unit] then
        return false
    end

    local t = gameplay_time()
    local pending = state.remote_animation_pending
    local repaired = 0

    VersusModeState.prune_remote_animation_credits(state, t)

    while pending and pending[1] and t >= (pending[1].apply_at or math.huge) do
        local entry = table.remove(pending, 1)
        local applied, failure = pcall(function()
            if entry.variable_index ~= nil then
                Unit.animation_set_variable(state.unit, entry.variable_index, entry.variable_value)
            end

            Unit.animation_event_by_index(state.unit, entry.event_index)
        end)

        if applied then
            repaired = repaired + 1

            if t >= (state.remote_animation_repair_log_at or 0) then
                state.remote_animation_repair_log_at = t + 1
                mod:info(
                    "Versus Mode: repaired missed client animation event %s (%d).",
                    tostring(entry.event_name or "index"),
                    entry.event_index
                )
            end
        elseif t >= (state.remote_animation_warning_at or 0) then
            state.remote_animation_warning_at = t + 3
            mod:warning(
                "Versus Mode: client animation fallback failed for event %s (%d): %s.",
                tostring(entry.event_name or "index"),
                entry.event_index,
                tostring(failure)
            )
        end
    end

    return repaired > 0
end

function VersusModeState.remote_target_reference(unit)
    if not unit then
        return nil
    end

    local reference = {
        unit_id = VersusModeState.network_unit_id(unit),
    }
    local player_manager = Managers.player
    local player = player_manager and player_manager.player_by_unit
        and player_manager:player_by_unit(unit)
        or nil

    if not player then
        return reference.unit_id and reference or nil
    end

    reference.peer_id = VersusModeState.player_peer_id(player)
    reference.local_player_id = VersusModeState.player_local_id(player)
    reference.account_id = VersusModeState.player_account_id(player)
    reference.character_id = VersusModeState.player_character_id(player)
    reference.name = VersusModeState.player_name(player)

    if reference.account_id == "no_account_id" then
        reference.account_id = nil
    end

    if type(player.unique_id) == "function" then
        local unique_ok, unique_id = pcall(player.unique_id, player)

        reference.unique_id = unique_ok and unique_id and tostring(unique_id) or nil
    end

    return reference
end

function VersusModeState.unit_from_player_identity(reference)
    if type(reference) ~= "table" then
        return nil, nil
    end

    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()

    if not players then
        return nil, nil
    end

    local wanted_character = reference.character_id
        and string.lower(tostring(reference.character_id)) or nil
    local wanted_account = reference.account_id
        and string.lower(tostring(reference.account_id)) or nil

    if wanted_account == "no_account_id" then
        wanted_account = nil
    end
    local wanted_peer = VersusModeState.normalize_peer_id(reference.peer_id)
    local wanted_local_id = reference.local_player_id
    local wanted_unique = reference.unique_id and tostring(reference.unique_id) or nil
    local wanted_name = type(reference.name) == "string" and reference.name ~= ""
        and reference.name or nil
    local character_unit
    local account_unit
    local peer_unit
    local peer_matches = 0
    local unique_unit
    local named_unit
    local name_matches = 0

    for unique_id, player in pairs(players) do
        local unit = player and player.player_unit

        if unit then
            local character_id = VersusModeState.player_character_id(player)
            local account_id = VersusModeState.player_account_id(player)
            local peer_id = VersusModeState.player_peer_id(player)
            local local_player_id = VersusModeState.player_local_id(player)

            if wanted_character and character_id == wanted_character then
                character_unit = unit
            end

            if wanted_account and account_id == wanted_account then
                account_unit = unit
            end

            if wanted_peer and peer_id == wanted_peer
                and (wanted_local_id == nil
                    or tostring(local_player_id) == tostring(wanted_local_id)) then
                peer_unit = unit
                peer_matches = peer_matches + 1
            end

            if wanted_unique and tostring(unique_id) == wanted_unique then
                unique_unit = unit
            end

            if wanted_name and VersusModeState.player_name(player) == wanted_name then
                named_unit = unit
                name_matches = name_matches + 1
            end
        end
    end

    if character_unit then
        return character_unit, "character"
    elseif account_unit then
        return account_unit, "account"
    elseif peer_unit and peer_matches == 1 then
        return peer_unit, "peer"
    elseif unique_unit then
        return unique_unit, "unique"
    elseif named_unit and name_matches == 1 then
        return named_unit, "name"
    end

    return nil, nil
end

function VersusModeState.resolve_remote_target_reference(reference, state)
    if type(reference) ~= "table" then
        return nil, "none"
    end

    local unit = VersusModeState.unit_from_network_id(reference.unit_id)

    if VersusModeState.valid_attack_target(unit, state) then
        return unit, "network"
    end

    local identity_source

    unit, identity_source = VersusModeState.unit_from_player_identity(reference)

    if VersusModeState.valid_attack_target(unit, state) then
        return unit, identity_source or "identity"
    end

    return nil, reference.unit_id ~= nil and "network pending" or "identity pending"
end

function VersusModeState.roster_payload()
    local payload = {
        revision = mod._versus_roster_revision or 0,
        automatic_respawn_enabled = VersusModeState.automatic_respawn_enabled(),
        controlled_traversal_enabled = VersusModeState.controlled_traversal_enabled(),
        random_safe_spawn_enabled = VersusModeState.random_safe_spawn_enabled(),
        spawn_selection_enabled = VersusModeState.spawn_selection_enabled(),
        specialist_variants_enabled = VersusModeState.specialist_variants_enabled(),
        roles = {},
        last_survivor = VersusModeState.last_survivor_payload(),
    }

    for _, role in pairs(VersusModeState.roles()) do
        local control = VersusModeState.control_for_role(role)
        local allied_unit = control and control.possessed and control.unit or nil

        if not allied_unit and not role.infected_human then
            allied_unit = role.autonomous_bot_unit
        end

        if allied_unit and (not ALIVE[allied_unit] or not HEALTH_ALIVE[allied_unit]) then
            allied_unit = nil
        end

        payload.roles[#payload.roles + 1] = {
            controlled_unit_id = VersusModeState.network_unit_id(allied_unit),
            human = role.infected_human == true,
            local_player_id = role.infected_local_player_id,
            name = role.infected_name,
            peer_id = role.infected_peer_id,
            respawn_breed = role.respawn_breed,
            respawn_variant = role.respawn_variant,
            respawn_remaining = role.respawn_ready_at and math_max(0, role.respawn_ready_at - gameplay_time()) or nil,
            unique_id = tostring(role.infected_unique_id),
        }
    end

    table.sort(payload.roles, function(a, b)
        return a.unique_id < b.unique_id
    end)

    return payload
end

function VersusModeState.publish_roster(recipient)
    local bridge = mod._realms_compat

    if not is_server() or not bridge or not bridge.is_host() or not bridge.available() then
        return false
    end

    local sent, send_error = bridge.send_roster(VersusModeState.roster_payload(), recipient)

    if not sent then
        mod:info("Versus Mode: Heretic roster synchronization deferred: %s", tostring(send_error))
    end

    return sent
end

function VersusModeState.roster_changed()
    mod._versus_roster_revision = (mod._versus_roster_revision or 0) + 1
    VersusModeState.publish_roster()
end

function VersusModeState.clear_replicated_host_state()
    mod._host_automatic_respawn_enabled = nil
    mod._host_controlled_traversal_enabled = nil
    mod._host_infected_spawn_selection_enabled = nil
    mod._host_random_safe_spawn_enabled = nil
    mod._host_specialist_variants_enabled = nil
    mod._last_survivor_notice = nil
end

function VersusModeState.apply_replicated_roster(payload)
    if is_server() or type(payload) ~= "table" or type(payload.roles) ~= "table" then
        return false
    end

    if not setting("enable_versus_mode") then
        VersusModeState.clear()
        VersusModeState.clear_replicated_host_state()

        return false
    end

    local desired = {}

    mod._host_automatic_respawn_enabled = payload.automatic_respawn_enabled == true
    mod._host_controlled_traversal_enabled = payload.controlled_traversal_enabled == true
    mod._host_random_safe_spawn_enabled = payload.random_safe_spawn_enabled == true
    mod._host_infected_spawn_selection_enabled = payload.spawn_selection_enabled == true
    mod._host_specialist_variants_enabled = payload.specialist_variants_enabled == true

    VersusModeState.receive_last_survivor(payload.last_survivor)

    for i = 1, #payload.roles do
        local entry = payload.roles[i]

        if type(entry) == "table" and type(entry.unique_id) == "string" and entry.unique_id ~= "" then
            desired[entry.unique_id] = entry
        end
    end

    local pending_clear = {}

    for _, role in pairs(VersusModeState.roles()) do
        local replicated_token = tostring(role.replicated_token or role.infected_unique_id)

        if role.replicated_client and not desired[replicated_token] then
            pending_clear[#pending_clear + 1] = role
        end
    end

    for i = 1, #pending_clear do
        VersusModeState.clear_role(pending_clear[i])
    end

    for token, entry in pairs(desired) do
        -- PlayerManager's unique-id counter is generated independently on
        -- every peer. Match the host token when possible, then fall back to
        -- the stable network identity shared by host and client.
        local unique_id, player = VersusModeState.find_player_by_identity(
            token,
            entry.peer_id,
            entry.local_player_id
        )
        local role = VersusModeState.role_for_replicated_token(token)
            or VersusModeState.role_for_unique_id(unique_id)
            or VersusModeState.role_for_unique_id(token)

        if role and unique_id ~= nil and role.infected_unique_id ~= unique_id then
            VersusModeState.roles()[role.infected_unique_id] = nil
            role.infected_unique_id = unique_id
            VersusModeState.roles()[unique_id] = role
        end

        if not role then
            role = {
                infected_unique_id = unique_id or token,
                replicated_client = true,
                replicated_token = token,
            }
            VersusModeState.roles()[role.infected_unique_id] = role
        end

        role.replicated_token = token

        role.controlled_unit_id = type(entry.controlled_unit_id) == "number"
            and entry.controlled_unit_id
            or nil
        role.infected_name = tostring(entry.name or VersusModeState.player_name(player))
        role.infected_human = entry.human == true
        role.infected_peer_id = VersusModeState.normalize_peer_id(entry.peer_id)
        role.infected_local_player_id = entry.local_player_id
        role.respawn_breed = type(entry.respawn_breed) == "string" and entry.respawn_breed or nil
        role.respawn_variant = type(entry.respawn_variant) == "string"
            and VersusModeState.valid_variant(role.respawn_breed, entry.respawn_variant)
            and entry.respawn_variant
            or nil
        role.respawn_ready_at = type(entry.respawn_remaining) == "number"
            and gameplay_time() + math_max(0, entry.respawn_remaining)
            or nil

        VersusModeState.bind_replicated_player(role, player)
    end

    mod._versus_roster_revision = type(payload.revision) == "number" and payload.revision or 0
    local replicated_local_role = VersusModeState.local_role()

    mod:info(
        "Versus Mode: applied Heretic roster revision %s (%d roles; local Heretic: %s).",
        tostring(mod._versus_roster_revision),
        #payload.roles,
        replicated_local_role and tostring(replicated_local_role.infected_name) or "no"
    )

    VersusModeState.notify_composition_changed()

    if mod._control and mod._control.remote_client and not VersusModeState.local_active() then
        VersusModeState.release_client_control("host restored your survivor role; control released.", true)
    end

    if VersusModeState.local_active() and not mod._control then
        VersusModeState.enter_wait_camera(mod._versus_role_test)
    end

    return true
end

function VersusModeState.selected_candidate()
    local role = VersusModeState.state()
    local candidates = VersusModeState.candidates()

    for i = 1, #candidates do
        if candidates[i].unique_id == role.selected_unique_id then
            return candidates[i], candidates, i
        end
    end

    local candidate = candidates[1]

    if candidate then
        role.selected_unique_id = candidate.unique_id
    else
        role.selected_unique_id = nil
    end

    return candidate, candidates, candidate and 1 or nil
end

function VersusModeState.notify_composition_changed()
    VersusModeState.suspend_last_survivor_trigger()

    if Managers.event then
        pcall(VersusModeState.player_compositions.trigger_change_event, "game_session_players")
    end
end

function VersusModeState.restore_unit(role)
    local unit = role and role.infected_unit

    if unit and ALIVE[unit] then
        if role.replicated_client then
            if role.infected_visibility and role.old_visibility ~= false then
                safe_extension_call(role.infected_visibility, "show")
            end

            return
        end

        local unit_data_extension = safe_extension(unit, "unit_data_system")

        if unit_data_extension then
            pcall(function()
                local hogtied_state_input = unit_data_extension:write_component("hogtied_state_input")

                hogtied_state_input.hogtie = false

                if VersusModeState.player_is_hogtied(unit) then
                    local assisted_state_input = unit_data_extension:write_component("assisted_state_input")

                    -- Mirror the successful half of vanilla RescueInteraction
                    -- so the temporary shell returns to walking without a
                    -- survivor having to interact with it.
                    assisted_state_input.force_assist = false
                    assisted_state_input.in_progress = true
                    assisted_state_input.success = true
                end
            end)
        end

        if role.infected_health then
            safe_extension_call(role.infected_health, "set_invulnerable", role.old_raw_invulnerable == true)
            safe_extension_call(role.infected_health, "set_unkillable", role.old_raw_unkillable == true)
        end

        if role.infected_visibility and role.old_visibility ~= false then
            safe_extension_call(role.infected_visibility, "show")
        end
    end
end

function VersusModeState.clear_autonomous_bot(role, despawn)
    local unit = role and role.autonomous_bot_unit

    if not unit then
        return false
    end

    if role.autonomous_health_state and ALIVE[unit] and HEALTH_ALIVE[unit] then
        VersusModeState.restore_controlled_health(role.autonomous_health_state)
    end

    if despawn and ALIVE[unit] then
        local minion_spawn_manager = Managers.state and Managers.state.minion_spawn

        if minion_spawn_manager then
            local despawn_ok, despawn_error = pcall(
                minion_spawn_manager.despawn_minion,
                minion_spawn_manager,
                unit
            )

            if not despawn_ok then
                mod:warning(
                    "Versus Mode: could not despawn the temporary AI Heretic for %s: %s",
                    tostring(role.infected_name or "bot"),
                    tostring(despawn_error)
                )
            end
        end
    end

    if role.assigned_boss_unit == unit then
        role.assigned_boss_unit = nil
    end

    role.autonomous_bot_unit = nil
    role.autonomous_health_state = nil
    role.autonomous_bot_roster_pending = nil

    return true
end

function VersusModeState.clear_role(role, reason)
    if not role or not role.infected_unique_id then
        return false
    end

    local old_name = role.infected_name or "player"
    local unique_id = role.infected_unique_id

    if mod._death_camera and mod._death_camera.role == role then
        VersusModeState.finish_death_camera(false)
    end

    VersusModeState.finish_survivor_spectating(role)
    VersusModeState.leave_wait_camera(role)
    VersusModeState.clear_autonomous_bot(role, true)
    VersusModeState.clear_owned_smart_tags(role.infected_unit)
    VersusModeState.restore_unit(role)
    VersusModeState.restore_observer_camera(role)
    VersusModeState.roles()[unique_id] = nil

    if mod._versus_role_test == role then
        mod._versus_role_test = nil
    end

    VersusModeState.notify_composition_changed()

    if not role.replicated_client then
        VersusModeState.roster_changed()
    end

    if reason then
        VersusModeState.echo_localized("notice_player_restored_to_survivors", old_name)
    end

    return true
end

function VersusModeState.clear(reason)
    local roles = VersusModeState.roles()
    local pending = {}

    for _, role in pairs(roles) do
        pending[#pending + 1] = role
    end

    local cleared = false

    for i = 1, #pending do
        cleared = VersusModeState.clear_role(pending[i], reason) or cleared
    end

    mod._versus_role_test = nil

    return cleared
end

function VersusModeState.assign_candidate(candidate)
    if not candidate or not candidate.unit or not ALIVE[candidate.unit] then
        return false, "Selected player is no longer available"
    end

    local existing = VersusModeState.role_for_unique_id(candidate.unique_id)

    if existing then
        return true, nil, existing
    end

    if VersusModeState.player_is_hogtied(candidate.unit) then
        return false, "Selected player is already hogtied"
    end

    local unit_data_extension = safe_extension(candidate.unit, "unit_data_system")
    local health_extension = safe_extension(candidate.unit, "health_system")
    local visibility_extension = safe_extension(candidate.unit, "player_visibility_system")

    if not unit_data_extension or not health_extension or not visibility_extension then
        return false, "Selected player does not expose the required host extensions"
    end

    local role = {}
    local old_raw_invulnerable = health_extension._is_invulnerable == true
    local old_raw_unkillable = health_extension._is_unkillable == true
    local visibility_state_ok, old_visibility = safe_extension_call(visibility_extension, "visible")
    local hogtie_ok = pcall(function()
        local hogtied_state_input = unit_data_extension:write_component("hogtied_state_input")

        hogtied_state_input.hogtie = true
    end)
    local invulnerable_ok = safe_extension_call(health_extension, "set_invulnerable", true)
    local unkillable_ok = safe_extension_call(health_extension, "set_unkillable", true)

    if not hogtie_ok or not invulnerable_ok or not unkillable_ok then
        if hogtie_ok then
            pcall(function()
                unit_data_extension:write_component("hogtied_state_input").hogtie = false
            end)
        end

        if invulnerable_ok then
            safe_extension_call(health_extension, "set_invulnerable", old_raw_invulnerable)
        end

        if unkillable_ok then
            safe_extension_call(health_extension, "set_unkillable", old_raw_unkillable)
        end

        return false, "Could not create the temporary Heretic shell"
    end

    role.infected_unique_id = candidate.unique_id
    role.infected_player = candidate.player
    role.infected_unit = candidate.unit
    role.infected_name = candidate.name
    role.infected_human = candidate.human
    role.infected_peer_id = candidate.peer_id
    role.infected_local_player_id = candidate.local_player_id
    role.infected_health = health_extension
    role.infected_visibility = visibility_extension
    role.old_raw_invulnerable = old_raw_invulnerable
    role.old_raw_unkillable = old_raw_unkillable
    role.old_visibility = not visibility_state_ok or old_visibility ~= false

    VersusModeState.clear_owned_smart_tags(candidate.unit)

    local hidden_ok = safe_extension_call(visibility_extension, "hide")

    if not hidden_ok then
        VersusModeState.restore_unit(role)

        return false, "Could not hide the temporary Heretic shell"
    end

    VersusModeState.roles()[candidate.unique_id] = role

    VersusModeState.notify_composition_changed()
    VersusModeState.roster_changed()

    if candidate.local_human then
        mod._versus_role_test = role
        VersusModeState.enter_wait_camera(role)
    end

    return true, nil, role
end

function VersusModeState.attach_replacement_shell(role, player, unit)
    if not role or not player or not unit or not ALIVE[unit] then
        return false, "replacement unit is not alive"
    end

    local unit_data_extension = safe_extension(unit, "unit_data_system")
    local health_extension = safe_extension(unit, "health_system")
    local visibility_extension = safe_extension(unit, "player_visibility_system")

    if not unit_data_extension or not health_extension or not visibility_extension then
        return false, "replacement extensions are not ready"
    end

    if role.infected_unit and role.infected_unit ~= unit and ALIVE[role.infected_unit] then
        VersusModeState.restore_unit(role)
    end

    local old_raw_invulnerable = health_extension._is_invulnerable == true
    local old_raw_unkillable = health_extension._is_unkillable == true
    local visibility_state_ok, old_visibility = safe_extension_call(visibility_extension, "visible")
    local hogtie_ok = pcall(function()
        unit_data_extension:write_component("hogtied_state_input").hogtie = true
    end)
    local invulnerable_ok = safe_extension_call(health_extension, "set_invulnerable", true)
    local unkillable_ok = safe_extension_call(health_extension, "set_unkillable", true)
    local hidden_ok = safe_extension_call(visibility_extension, "hide")

    if not hogtie_ok or not invulnerable_ok or not unkillable_ok or not hidden_ok then
        if hogtie_ok then
            pcall(function()
                unit_data_extension:write_component("hogtied_state_input").hogtie = false
            end)
        end

        if invulnerable_ok then
            safe_extension_call(health_extension, "set_invulnerable", old_raw_invulnerable)
        end

        if unkillable_ok then
            safe_extension_call(health_extension, "set_unkillable", old_raw_unkillable)
        end

        if hidden_ok and (not visibility_state_ok or old_visibility ~= false) then
            safe_extension_call(visibility_extension, "show")
        end

        return false, "replacement shell could not be protected"
    end

    role.infected_player = player
    role.infected_unit = unit
    role.infected_health = health_extension
    role.infected_visibility = visibility_extension
    role.old_raw_invulnerable = old_raw_invulnerable
    role.old_raw_unkillable = old_raw_unkillable
    role.old_visibility = not visibility_state_ok or old_visibility ~= false
    role.player_missing_since = nil
    role.shell_missing_notified = nil
    role.shell_attach_warning_at = nil

    VersusModeState.clear_owned_smart_tags(unit)
    VersusModeState.notify_composition_changed()
    mod:info("Versus Mode: reattached Heretic role to replacement shell for %s.", role.infected_name or "player")

    return true
end

function VersusModeState.maintain_role(role)
    if not role or not role.infected_unique_id then
        return
    end

    if role.replicated_client then
        local old_unique_id = role.infected_unique_id
        local unique_id, player = VersusModeState.find_player_by_identity(
            role.replicated_token or old_unique_id,
            role.infected_peer_id,
            role.infected_local_player_id
        )

        if unique_id ~= nil and unique_id ~= old_unique_id then
            VersusModeState.roles()[old_unique_id] = nil
            role.infected_unique_id = unique_id
            VersusModeState.roles()[unique_id] = role
        end

        local unit = player and player.player_unit

        role.infected_player = player

        if unit and ALIVE[unit] then
            if unit ~= role.infected_unit then
                VersusModeState.restore_unit(role)
                role.infected_unit = unit
                role.infected_visibility = safe_extension(unit, "player_visibility_system")

                local visible_ok, visible = safe_extension_call(role.infected_visibility, "visible")

                role.old_visibility = not visible_ok or visible ~= false
            end

            if role.infected_visibility then
                safe_extension_call(role.infected_visibility, "hide")
            end
        end

        if VersusModeState.local_role() == role and not mod._control then
            VersusModeState.maintain_wait_camera(role)
        end

        return
    end

    if not setting("enable_versus_mode") or not is_server() then
        VersusModeState.clear_role(role, "test disabled")

        return
    end

    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local player = players and players[role.infected_unique_id]
    local unit = player and player.player_unit
    local t = gameplay_time()

    if not player then
        role.player_missing_since = role.player_missing_since or t

        if t - role.player_missing_since >= 5 then
            VersusModeState.clear_role(role, "player left the session")
        end

        return
    end

    role.player_missing_since = nil

    if not role.infected_human and role.autonomous_bot_unit then
        local autonomous_unit = role.autonomous_bot_unit

        if not ALIVE[autonomous_unit] or not HEALTH_ALIVE[autonomous_unit] then
            VersusModeState.clear_autonomous_bot(role, false)
            VersusModeState.schedule_respawn(role)
            mod:info(
                "Versus Mode: temporary AI Heretic for %s was defeated; replacement queued.",
                tostring(role.infected_name or "bot")
            )
        elseif role.autonomous_bot_roster_pending
            and VersusModeState.network_unit_id(autonomous_unit) then
            role.autonomous_bot_roster_pending = nil
            VersusModeState.publish_roster()
        end
    end

    if not unit or not ALIVE[unit] then
        role.infected_player = player
        role.infected_unit = nil
        role.infected_health = nil
        role.infected_visibility = nil
        role.old_raw_invulnerable = nil
        role.old_raw_unkillable = nil
        role.old_visibility = nil

        if not role.shell_missing_notified then
            role.shell_missing_notified = true
            mod:info("Versus Mode: Heretic role retained while %s awaits a replacement shell.", role.infected_name or "player")
        end

        return
    end

    if player ~= role.infected_player or unit ~= role.infected_unit then
        local attached, attach_error = VersusModeState.attach_replacement_shell(role, player, unit)

        if not attached and t >= (role.shell_attach_warning_at or 0) then
            role.shell_attach_warning_at = t + 5
            mod:warning("Versus Mode: waiting to attach replacement infected shell (%s).", tostring(attach_error))
        end

        return
    end

    local unit_data_extension = safe_extension(unit, "unit_data_system")

    if unit_data_extension and not VersusModeState.player_is_hogtied(unit) then
        pcall(function()
            unit_data_extension:write_component("hogtied_state_input").hogtie = true
        end)
    end

    if role.infected_health then
        safe_extension_call(role.infected_health, "set_invulnerable", true)
        safe_extension_call(role.infected_health, "set_unkillable", true)
    end

    -- Other systems may refresh player visibility when equipment or character
    -- state changes. The extension makes repeated hide calls idempotent and
    -- preserves its original snapshot for restoration.
    if role.infected_visibility then
        safe_extension_call(role.infected_visibility, "hide")
    end

    local can_reinforce = role.infected_human or VersusModeState.bot_reinforcement_enabled(role)

    if can_reinforce and not role.assigned_boss_unit then
        if VersusModeState.local_role() == role and not mod._control then
            VersusModeState.maintain_wait_camera(role)
        end

        if not role.respawn_breed then
            VersusModeState.schedule_respawn(role)
        elseif not role.respawn_ready_notified
            and gameplay_time() >= (role.respawn_ready_at or math.huge) then
            role.respawn_ready_notified = true
            local random_safe = VersusModeState.random_safe_spawn_enabled()
            local automatic = random_safe and VersusModeState.automatic_respawn_enabled()
            local notice_key

            if automatic then
                notice_key = "notice_spawn_ready_automatic"
            elseif random_safe then
                notice_key = "notice_spawn_ready_random_safe"
            else
                notice_key = "notice_spawn_ready_manual"
            end

            if role.infected_human then
                if VersusModeState.local_role() == role then
                    local label = VersusModeState.respawn_label(role.respawn_breed, role.respawn_variant)

                    if notice_key == "notice_spawn_ready_automatic" then
                        VersusModeState.echo_localized(notice_key, label)
                    else
                        VersusModeState.echo_localized(notice_key, label, configured_keybind_label("possess_keybind"))
                    end
                elseif role.infected_peer_id then
                    VersusModeState.send_remote_respawn_notice(role.infected_peer_id, notice_key, role)
                end
            else
                mod:info(
                    "Versus Mode: %s's temporary AI Heretic %s is ready for Random Safe deployment.",
                    tostring(role.infected_name or "Bot"),
                    VersusModeState.respawn_label(role.respawn_breed, role.respawn_variant)
                )
            end
        end
    end
end

function VersusModeState.maintain()
    local pending = {}

    for _, role in pairs(VersusModeState.roles()) do
        pending[#pending + 1] = role
    end

    for i = 1, #pending do
        VersusModeState.maintain_role(pending[i])
    end
end

function VersusModeState.all_players_dead(func, self, num_alive_players, alive_players, include_bots, ...)
    local human_infected = false

    for _, role in pairs(VersusModeState.roles()) do
        if role.infected_human then
            human_infected = true

            break
        end
    end

    -- Vanilla co-op deliberately ignores bots for the all-dead check. While a
    -- human is assigned to the infected role, survivor bots become the active
    -- strike team and must be allowed to keep the SoloPlay mission running.
    if setting("enable_versus_mode")
        and is_server()
        and human_infected then
        include_bots = true
    end

    return func(self, num_alive_players, alive_players, include_bots, ...)
end

function VersusModeState.progression_units(mode)
    local result = {}
    local player_unit_spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local alive_players = player_unit_spawn_manager and player_unit_spawn_manager:alive_players() or {}

    for i = 1, #alive_players do
        local player_unit = alive_players[i].player_unit

        if player_unit and ALIVE[player_unit] and not VersusModeState.is_unit(player_unit) then
            local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
            local character_state_component = unit_data_extension and unit_data_extension:read_component("character_state")
            local valid = false

            if character_state_component then
                if mode == "alive" then
                    valid = not VersusModeState.player_unit_status.requires_allied_interaction_help(character_state_component)
                elseif mode == "end_zone" then
                    valid = VersusModeState.player_unit_status.end_zone_conditions_fulfilled(character_state_component)
                else
                    valid = not VersusModeState.player_unit_status.is_hogtied(character_state_component)
                end
            end

            if valid then
                result[#result + 1] = player_unit
            end
        end
    end

    return result
end

VersusModeState.last_survivor_duration = 20
VersusModeState.last_survivor_buff_templates = {
    -- This existing template applies one exact 0.5 multiplier to both melee
    -- and ranged attacks. Using the knockdown linger template here would also
    -- multiply toughness damage a second time, producing 75% toughness DR.
    "havoc_rotten_armor_dr_02",
    "player_movement_speed_node_buff_low_1",
    "player_movement_speed_node_buff_low_2",
    "player_movement_speed_node_buff_low_3",
    "player_movement_speed_node_buff_low_4",
    "havoc_positive_attack_speed_5",
}

function VersusModeState.last_survivor_state()
    if not mod._last_survivor_state then
        mod._last_survivor_state = {
            armed = false,
            triggered = false,
        }
    end

    return mod._last_survivor_state
end

function VersusModeState.remove_last_survivor_buffs(active)
    if not active then
        return
    end

    local buff_extension = active.buff_extension

    for i = 1, #(active.buffs or {}) do
        local buff = active.buffs[i]

        safe_extension_call(buff_extension, "remove_externally_controlled_buff", buff.index, buff.component_index)
    end

    active.buffs = {}
end


function VersusModeState.reset_last_survivor(preserve_trigger)
    local previous = mod._last_survivor_state

    if previous and previous.active then
        VersusModeState.remove_last_survivor_buffs(previous.active)
    end

    mod._last_survivor_state = {
        armed = false,
        triggered = preserve_trigger and previous and previous.triggered or false,
        rearm_at = gameplay_time() + 1,
    }
    mod._last_survivor_notice = nil
end

-- Unlike progression checks, a net or knockdown is not a death. Counting it
-- here could spend the mission's only activation before anybody had died.
function VersusModeState.last_survivor_units()
    local result = {}
    local spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local players = spawn_manager and spawn_manager:alive_players() or {}

    for i = 1, #players do
        local unit = players[i].player_unit
        local extension = unit and safe_extension(unit, "unit_data_system")
        local ok, component = safe_extension_call(extension, "read_component", "character_state")

        if unit and HEALTH_ALIVE[unit] and not VersusModeState.is_unit(unit)
            and ok and component
            and not VersusModeState.player_unit_status.is_dead_for_mission_failure(component) then
            result[#result + 1] = unit
        end
    end

    return result
end

function VersusModeState.last_survivor_payload()
    local active = mod._last_survivor_state and mod._last_survivor_state.active

    if active then
        return {
            unit_id = VersusModeState.network_unit_id(active.unit),
            name = active.name,
            remaining = math_max(0, active.expires_at - gameplay_time()),
        }
    end
end

function VersusModeState.receive_last_survivor(payload)
    if type(payload) ~= "table" or type(payload.unit_id) ~= "number"
        or type(payload.remaining) ~= "number" or payload.remaining ~= payload.remaining
        or payload.remaining <= 0 or payload.remaining > VersusModeState.last_survivor_duration then
        mod._last_survivor_notice = nil

        return
    end

    local previous = mod._last_survivor_notice
    local notice = {
        unit_id = payload.unit_id,
        name = tostring(payload.name or "?"),
        expires_at = gameplay_time() + payload.remaining,
    }
    mod._last_survivor_notice = notice

    if not previous or previous.unit_id ~= notice.unit_id or previous.expires_at <= gameplay_time() then
        mod:echo("Versus Mode: " .. mod:localize("last_survivor_recipient", notice.name))
    end
end

function VersusModeState.last_survivor_stat_summary(extension)
    local ok, stats = safe_extension_call(extension, "stat_buffs")

    if not ok or not stats then
        return "stats unavailable"
    end

    return string.format("move=%s melee_speed=%s ranged_speed=%s melee_taken=%s ranged_taken=%s",
        tostring(stats.movement_speed), tostring(stats.melee_attack_speed), tostring(stats.ranged_attack_speed),
        tostring(stats.melee_damage_taken_multiplier), tostring(stats.ranged_damage_taken_multiplier))
end

function VersusModeState.update_last_survivor_notice()
    local notice = mod._last_survivor_notice

    if not notice then
        return
    end

    local unit = VersusModeState.unit_from_network_id(notice.unit_id)

    if gameplay_time() >= notice.expires_at or unit and not HEALTH_ALIVE[unit] then
        mod._last_survivor_notice = nil

        return
    end

    -- The owning client also predicts ability charges. Refill only its own
    -- character after the authenticated host announced this timed activation.
    local player = Managers.player and Managers.player:local_player(1)

    if not is_server() and unit and player and player.player_unit == unit then
        VersusModeState.refill_combat_ability(safe_extension(unit, "ability_system"))
    end
end

function VersusModeState.suspend_last_survivor_trigger()
    local state = VersusModeState.last_survivor_state()

    if not state.triggered then
        state.armed = false
        state.previous_count = nil
        state.rearm_at = gameplay_time() + 1
    end
end

function VersusModeState.refill_combat_ability(ability_extension)
    local maximum_ok, maximum_charges = safe_extension_call(
        ability_extension,
        "max_ability_charges",
        "combat_ability"
    )
    local remaining_ok, remaining_charges = safe_extension_call(
        ability_extension,
        "remaining_ability_charges",
        "combat_ability"
    )

    if maximum_ok
        and remaining_ok
        and type(maximum_charges) == "number"
        and type(remaining_charges) == "number"
        and maximum_charges > 0
        and remaining_charges < maximum_charges then
        safe_extension_call(ability_extension, "set_ability_charges", "combat_ability", maximum_charges)
    end
end

function VersusModeState.apply_last_survivor_buff(unit)
    local buff_extension = safe_extension(unit, "buff_system")
    local ability_extension = safe_extension(unit, "ability_system")

    if not buff_extension or not ability_extension then
        return false, "player buff or ability extension unavailable"
    end

    local t = gameplay_time()
    local spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local owner = spawn_manager and spawn_manager:owner(unit)
    local active = {
        ability_extension = ability_extension,
        buff_extension = buff_extension,
        buffs = {},
        expires_at = t + VersusModeState.last_survivor_duration,
        unit = unit,
        name = VersusModeState.player_name(owner),
        before_stats = VersusModeState.last_survivor_stat_summary(buff_extension),
        audit_at = t + 0.25,
    }

    for i = 1, #VersusModeState.last_survivor_buff_templates do
        local template_name = VersusModeState.last_survivor_buff_templates[i]
        local call_ok, client_tried, index, component_index = safe_extension_call(
            buff_extension,
            "add_externally_controlled_buff",
            template_name,
            t
        )

        if not call_ok or client_tried or not index then
            VersusModeState.remove_last_survivor_buffs(active)

            return false, "failed adding " .. tostring(template_name)
        end

        active.buffs[#active.buffs + 1] = {
            component_index = component_index,
            index = index,
        }

    end

    VersusModeState.refill_combat_ability(ability_extension)

    return true, active
end

function VersusModeState.update_last_survivor()
    if not is_server() then
        return
    end

    local state = VersusModeState.last_survivor_state()
    local t = gameplay_time()

    if state.active then
        local active = state.active

        if t >= active.expires_at or not HEALTH_ALIVE[active.unit] or not setting("enable_last_survivor_buff") then
            VersusModeState.remove_last_survivor_buffs(active)
            state.active = nil
            mod._last_survivor_notice = nil
            VersusModeState.publish_roster()
            mod:info("Versus Mode: Last Survivor buff ended.")
        else
            VersusModeState.refill_combat_ability(active.ability_extension)

            if active.audit_at and t >= active.audit_at then
                active.audit_at = nil
                mod:info("Versus Mode: Last Survivor recipient=%s; before [%s]; active [%s].",
                    active.name, active.before_stats, VersusModeState.last_survivor_stat_summary(active.buff_extension))
            end
        end

        return
    end

    if state.triggered then
        return
    end

    if not setting("enable_last_survivor_buff") or not VersusModeState.test_active() then
        state.armed = false
        state.previous_count = nil

        return
    end

    if t < (state.rearm_at or 0) then
        return
    end

    local survivors = VersusModeState.last_survivor_units()
    local survivor_count = #survivors

    if state.previous_count ~= survivor_count then
        mod:info("Versus Mode: Last Survivor living count %s -> %d; armed=%s; trigger consumed=%s.",
            tostring(state.previous_count), survivor_count, tostring(state.armed), tostring(state.triggered))
    end

    if survivor_count >= 2 then
        state.armed = true
    elseif survivor_count == 1 and state.armed and state.previous_count and state.previous_count >= 2 then
        local applied, active_or_error = VersusModeState.apply_last_survivor_buff(survivors[1])

        if applied then
            state.active = active_or_error
            state.triggered = true
            VersusModeState.receive_last_survivor(VersusModeState.last_survivor_payload())
            VersusModeState.publish_roster()
            mod:info(
                "Versus Mode: Last Survivor activated for %s for %.1f seconds.",
                active_or_error.name,
                VersusModeState.last_survivor_duration
            )
        elseif t >= (state.warning_at or 0) then
            state.warning_at = t + 5
            mod:warning("Versus Mode: Last Survivor activation deferred: %s.", tostring(active_or_error))
        end

        if not applied then
            -- Keep the 2 -> 1 edge pending while the player extensions finish
            -- spawning instead of consuming the once-per-mission trigger.
            state.previous_count = 2

            return
        end
    end

    state.previous_count = survivor_count
end

function VersusModeState.all_progression_units_inside(condition, volume_id, mode)
    local units = VersusModeState.progression_units(mode)

    return #units > 0
        and VolumeEvent.has_all_units_inside(condition._engine_volume_event_system, volume_id, table_unpack(units))
        or false
end

function VersusModeState.progression_units_inside_count(condition, volume_id, mode)
    local units = VersusModeState.progression_units(mode)
    local inside = 0

    for i = 1, #units do
        if VolumeEvent.has_all_units_inside(condition._engine_volume_event_system, volume_id, units[i]) then
            inside = inside + 1
        end
    end

    return inside, #units
end

function VersusModeState.any_progression_unit_inside(condition, volume_id)
    local inside = VersusModeState.progression_units_inside_count(condition, volume_id)

    return inside > 0
end

function VersusModeState.progression_entering_unit(unit)
    local player_unit_spawn_manager = Managers.state and Managers.state.player_unit_spawn
    local player = player_unit_spawn_manager and player_unit_spawn_manager:owner(unit)

    return player ~= nil and not VersusModeState.is_unit(unit)
end

function VersusModeState.all_progression_units_inside_no_enemies(condition, volume_id)
    local broadphase_results = {}
    local broadphase_center = condition._broadphase_center:unbox()
    local position_offset = Vector3.up() * 0.25
    local num_results = Broadphase.query(
        condition._broadphase,
        broadphase_center,
        condition._broadphase_radius,
        broadphase_results,
        condition._enemy_side_names
    )

    for i = 1, num_results do
        local enemy_unit = broadphase_results[i]
        local enemy_position = POSITION_LOOKUP[enemy_unit]

        if enemy_position
            and Unit.is_point_inside_volume(condition._volume_unit, "enemy_check_volume", enemy_position + position_offset) then
            return false
        end
    end

    return VersusModeState.all_progression_units_inside(condition, volume_id)
end

function VersusModeState.platform_all_players_inside(platform)
    local side = platform._side_system:get_side_from_name(platform._player_side)
    local passenger_units = platform._overlap_result and platform._overlap_result[platform._box]
    local at_least_one = false

    if not side or not passenger_units then
        return false
    end

    for i = 1, #side.player_units do
        local player_unit = side.player_units[i]

        if not VersusModeState.is_unit(player_unit) and platform:_valid_passenger_player_unit(player_unit) then
            local unit_data_extension = ScriptUnit.extension(player_unit, "unit_data_system")
            local character_state_component = unit_data_extension:read_component("character_state")

            if not passenger_units[player_unit]
                or VersusModeState.player_unit_status.is_disabled(character_state_component) then
                return false
            end

            at_least_one = true
        end
    end

    return at_least_one
end

local function captain_has_weapon_slot(state, slot_name)
    local visual_loadout = state and (state.visual_loadout or safe_extension(state.unit, "visual_loadout_system"))

    if not visual_loadout or not slot_name then
        return false
    end

    local ok, has_slot = safe_extension_call(visual_loadout, "has_slot", slot_name)

    return ok and has_slot == true
end

-- Captain phase names are loadout-specific. Resolve the phase from the live
-- behavior extension instead of assuming that every spawned Captain has the
-- same sword/maul and shotgun/plasma combination.
function Specialist.captain_phase_for_slot(state, combat_range, slot_name)
    local phase_template = state and state.behavior and state.behavior._phase_template
    local range_template = type(phase_template) == "table" and phase_template[combat_range]
    local phases = type(range_template) == "table" and range_template.phases

    if type(phases) ~= "table" then
        return nil
    end

    local phase_component = state.blackboard and state.blackboard.phase
    local current_phase = phase_component and phase_component.current_phase
    local current_data = current_phase and phases[current_phase]

    if type(current_data) == "table" and current_data.wanted_weapon_slot == slot_name then
        return current_phase
    end

    for phase_name, phase_data in pairs(phases) do
        if type(phase_data) == "table" and phase_data.wanted_weapon_slot == slot_name then
            return phase_name
        end
    end

    local entry_phase = range_template.entry_phase

    if type(entry_phase) == "string" then
        local entry_data = phases[entry_phase]

        if type(entry_data) == "table"
            and (entry_data.wanted_weapon_slot == nil or entry_data.wanted_weapon_slot == slot_name) then
            return entry_phase
        end
    elseif type(entry_phase) == "table" then
        for i = 1, #entry_phase do
            local phase_name = entry_phase[i]
            local phase_data = phases[phase_name]

            if type(phase_data) == "table"
                and (phase_data.wanted_weapon_slot == nil or phase_data.wanted_weapon_slot == slot_name) then
                return phase_name
            end
        end
    end

    return nil
end

local function captain_attacks_for_state(state)
    local melee_attacks

    if captain_has_weapon_slot(state, "slot_power_sword") then
        melee_attacks = ATTACKS.renegade_captain
    elseif captain_has_weapon_slot(state, "slot_powermaul") then
        melee_attacks = ATTACKS.cultist_captain
    end

    local ranged_attack
    local ranged_slot_order = {
        "slot_shotgun",
        "slot_plasma_pistol",
        "slot_bolt_pistol",
        "slot_hellgun",
    }

    for i = 1, #ranged_slot_order do
        local slot_name = ranged_slot_order[i]

        if captain_has_weapon_slot(state, slot_name) then
            ranged_attack = CAPTAIN_RANGED_ATTACKS[slot_name]

            break
        end
    end

    if not melee_attacks then
        return ranged_attack and { primary = ranged_attack } or GENERIC_BOSS_ATTACKS
    end

    return {
        primary = melee_attacks.primary,
        heavy = melee_attacks.heavy,
        alternate = melee_attacks.alternate,
        special = ranged_attack,
    }
end

-- BtSwitchWeaponAction assumes both the requested weapon slot and its switch
-- metadata exist, then dereferences that metadata without a nil guard. A
-- custom/spawner Captain can expose a visual slot whose breed action table is
-- incomplete, so validate all three native pieces before waking the brain.
function Specialist.captain_weapon_request_supported(state, attack)
    if not state
        or not state.breed
        or not CAPTAIN_BREEDS[state.breed.name]
        or not attack
        or not attack.captain_weapon_slot then
        return true
    end

    local slot_name = attack.captain_weapon_slot

    if not captain_has_weapon_slot(state, slot_name) then
        return false, "spawned visual loadout has no " .. tostring(slot_name)
    end

    local visual_loadout = state.visual_loadout or safe_extension(state.unit, "visual_loadout_system")
    local wielded_ok, wielded_slot = safe_extension_call(visual_loadout, "wielded_slot_name")

    if not (wielded_ok and wielded_slot == slot_name) then
        local can_wield_ok, can_wield = safe_extension_call(visual_loadout, "can_wield_slot", slot_name)

        if not can_wield_ok or can_wield ~= true then
            return false, "spawned visual loadout cannot wield " .. tostring(slot_name)
        end
    end

    local breed_actions = BreedActions and BreedActions[state.breed.name]
    local switch_action_data = type(breed_actions) == "table" and breed_actions.switch_weapon
    local switch_data = type(switch_action_data) == "table" and switch_action_data[slot_name]

    if attack.casual_primary and type(attack.casual_actions) == "table" then
        for action_name in pairs(attack.casual_actions) do
            if type(breed_actions) ~= "table" or type(breed_actions[action_name]) ~= "table" then
                return false, "breed action missing " .. tostring(action_name)
            end
        end
    elseif type(breed_actions) ~= "table" or type(breed_actions[attack.action_name]) ~= "table" then
        return false, "breed action missing " .. tostring(attack.action_name)
    end

    if type(switch_data) ~= "table" then
        return false, "weapon-switch metadata missing " .. tostring(slot_name)
    end

    local combat_range = attack.captain_combat_range or "melee"
    local phase_name = Specialist.captain_phase_for_slot(state, combat_range, slot_name)

    if not phase_name then
        return false, string.format("phase metadata missing %s in %s", tostring(slot_name), tostring(combat_range))
    end

    return true
end

local function attacks_for_state(state)
    if not state then
        return nil
    end

    if CAPTAIN_BREEDS[state.breed.name] then
        return captain_attacks_for_state(state)
    end

    if state.variant_id and VersusModeState.variant_attacks[state.variant_id] then
        return VersusModeState.variant_attacks[state.variant_id]
    end

    return attacks_for_breed(state.breed)
end

local function hide_original_first_person_equipment(state)
    if not state.first_person or not ALIVE[state.player_unit] then
        return
    end

    local unit_data_extension = safe_extension(state.player_unit, "unit_data_system")
    local first_person_extension = safe_extension(state.player_unit, "first_person_system")
    local visual_loadout_extension = safe_extension(state.player_unit, "visual_loadout_system")
    local first_person_mode_component = unit_data_extension and unit_data_extension:write_component("first_person_mode")

    if first_person_mode_component then
        state.player_first_person_mode_component = first_person_mode_component
        state.old_wants_1p_camera = first_person_mode_component.wants_1p_camera
        state.old_show_1p_equipment_at_t = first_person_mode_component.show_1p_equipment_at_t
        first_person_mode_component.wants_1p_camera = false
    end

    if first_person_extension then
        state.player_first_person_extension = first_person_extension
        state.old_show_1p_equipment = first_person_extension._show_1p_equipment
        state.old_wants_1p_camera_internal = first_person_extension._wants_1p_camera
        first_person_extension._show_1p_equipment = false
        first_person_extension._wants_1p_camera = false
    end

    if visual_loadout_extension and visual_loadout_extension._update_item_visibility then
        state.player_visual_loadout_extension = visual_loadout_extension
        state.old_visual_first_person_mode = visual_loadout_extension._is_in_first_person_mode
        visual_loadout_extension._is_in_first_person_mode = false
        pcall(visual_loadout_extension._update_item_visibility, visual_loadout_extension, false)
    end
end

local function restore_original_first_person_equipment(state)
    if not state or not ALIVE[state.player_unit] then
        return
    end

    local first_person_mode_component = state.player_first_person_mode_component

    if first_person_mode_component then
        first_person_mode_component.wants_1p_camera = state.old_wants_1p_camera
        first_person_mode_component.show_1p_equipment_at_t = state.old_show_1p_equipment_at_t
    end

    local first_person_extension = state.player_first_person_extension

    if first_person_extension then
        first_person_extension._show_1p_equipment = state.old_show_1p_equipment
        first_person_extension._wants_1p_camera = state.old_wants_1p_camera_internal
    end

    local visual_loadout_extension = state.player_visual_loadout_extension

    if visual_loadout_extension and visual_loadout_extension._update_item_visibility then
        local old_mode = state.old_visual_first_person_mode or false

        visual_loadout_extension._is_in_first_person_mode = old_mode
        pcall(visual_loadout_extension._update_item_visibility, visual_loadout_extension, old_mode)
    end
end

function VersusModeState.first_person_supported(state)
    return state
        and state.breed
        and state.breed.is_boss ~= true
        or false
end

function VersusModeState.set_local_render_visibility(unit, visible)
    if not unit then
        return false
    end

    local visibility_context = VisibilityContexts and VisibilityContexts.DEFAULT_CONTEXT

    if visibility_context and Unit.set_unit_objects_visibility then
        local context_ok = pcall(
            Unit.set_unit_objects_visibility,
            unit,
            visible == true,
            true,
            visibility_context
        )

        if context_ok then
            return true
        end
    end

    -- Older runtime builds do not expose visibility contexts to Lua. This
    -- fallback is still client-local because it never uses the visual-loadout
    -- extension's networked set_slot_visibility method.
    return pcall(Unit.set_unit_visibility, unit, visible == true, true)
end

function VersusModeState.remember_and_hide_first_person_unit(state, unit, restore_visible)
    if not state or not unit then
        return false
    end

    local snapshot = state.first_person_visibility_snapshot

    if not snapshot then
        snapshot = {
            by_unit = {},
            units = {},
        }
        state.first_person_visibility_snapshot = snapshot
    end

    local hidden = VersusModeState.set_local_render_visibility(unit, false)

    if not hidden then
        return false
    end

    if not snapshot.by_unit[unit] then
        local record = {
            restore_visible = restore_visible ~= false,
            unit = unit,
        }

        snapshot.by_unit[unit] = record
        snapshot.units[#snapshot.units + 1] = record
    end

    return true
end

function VersusModeState.suppress_controlled_first_person_head(state)
    local unit = state and state.unit
    local breed_name = state and state.breed and state.breed.name
    local node_name = breed_name and VersusModeState.first_person_head_scale_nodes[breed_name]

    if not unit or not node_name then
        return false
    end

    local snapshot = state.first_person_head_scale_snapshot

    if not snapshot then
        local has_node_ok, has_node = pcall(Unit.has_node, unit, node_name)

        if not has_node_ok or not has_node then
            return false
        end

        local node_ok, node = pcall(Unit.node, unit, node_name)
        local scale_ok
        local original_scale

        if node_ok then
            scale_ok, original_scale = pcall(Unit.local_scale, unit, node)
        end

        if not node_ok or not scale_ok or not original_scale then
            return false
        end

        local camera_height_offset

        if node_name ~= "j_head" then
            local head_ok, has_head = pcall(Unit.has_node, unit, "j_head")

            if head_ok and has_head then
                local head_node_ok, head_node = pcall(Unit.node, unit, "j_head")
                local anchor_position_ok, anchor_position = pcall(Unit.world_position, unit, node)
                local head_position_ok
                local head_position

                if head_node_ok then
                    head_position_ok, head_position = pcall(Unit.world_position, unit, head_node)
                end

                if anchor_position_ok and head_position_ok and anchor_position and head_position then
                    camera_height_offset = Vector3.z(head_position) - Vector3.z(anchor_position)
                end
            end
        end

        snapshot = {
            camera_height_offset = camera_height_offset,
            node = node,
            node_name = node_name,
            original_scale = Vector3Box(original_scale),
            unit = unit,
        }
        state.first_person_head_scale_snapshot = snapshot
    end

    return pcall(Unit.set_local_scale, snapshot.unit, snapshot.node, Vector3(0.01, 0.01, 0.01))
end

function VersusModeState.restore_controlled_first_person_head(state)
    local snapshot = state and state.first_person_head_scale_snapshot

    if not snapshot then
        return false
    end

    local scale_ok, original_scale = pcall(snapshot.original_scale.unbox, snapshot.original_scale)
    local restored = scale_ok
        and original_scale
        and pcall(Unit.set_local_scale, snapshot.unit, snapshot.node, original_scale)
        or false

    state.first_person_head_scale_snapshot = nil

    return restored
end

function VersusModeState.restore_controlled_first_person_visibility(state)
    if not state then
        return false
    end

    local snapshot = state.first_person_visibility_snapshot
    local restored = VersusModeState.restore_controlled_first_person_head(state)

    -- Whole-body fallback records the root first and its loadout afterward.
    -- Restoring in that order lets originally hidden loadout slots be hidden
    -- again after the root's recursive visibility restoration.
    for i = 1, #(snapshot and snapshot.units or {}) do
        local record = snapshot.units[i]

        VersusModeState.set_local_render_visibility(record.unit, record.restore_visible)
        restored = true
    end

    state.first_person_visibility_snapshot = nil
    state.first_person_visibility_mode = nil
    state.next_first_person_visibility_refresh_at = nil

    return restored
end

function VersusModeState.refresh_controlled_first_person_visibility(state, force)
    if not state or not state.first_person or not VersusModeState.first_person_supported(state) then
        return VersusModeState.restore_controlled_first_person_visibility(state)
    end

    local t = gameplay_time()

    if not force and t < (state.next_first_person_visibility_refresh_at or 0) then
        return true
    end

    state.next_first_person_visibility_refresh_at = t + VersusModeState.first_person_visibility_refresh_interval

    local visual_loadout = state.visual_loadout or safe_extension(state.unit, "visual_loadout_system")
    local slots = visual_loadout and visual_loadout._slots

    if visual_loadout and visual_loadout.slot_items then
        local slots_ok, current_slots = pcall(visual_loadout.slot_items, visual_loadout)

        if slots_ok and type(current_slots) == "table" then
            slots = current_slots
        end
    end

    slots = type(slots) == "table" and slots or {}

    if not state.first_person_visibility_mode then
        local breed_name = state.breed and state.breed.name
        local use_head_only = VersusModeState.first_person_head_scale_nodes[breed_name] ~= nil

        -- Known skeletons must never fall back to hiding the entire hierarchy
        -- just because an asynchronously spawned head attachment is absent on
        -- the first frame. The base head is collapsed independently below.
        state.first_person_visibility_mode = use_head_only and "head_only" or "whole_body"
        mod:info(
            "Versus Mode: experimental first-person visibility for %s uses %s.",
            tostring(breed_name or "enemy"),
            state.first_person_visibility_mode == "head_only"
                and "controller-local head-only suppression"
                or "controller-local whole-body fallback"
        )
    end

    local hide_whole_body = state.first_person_visibility_mode == "whole_body"

    if hide_whole_body then
        VersusModeState.remember_and_hide_first_person_unit(state, state.unit, true)
    else
        VersusModeState.suppress_controlled_first_person_head(state)
    end

    for slot_name, slot in pairs(slots) do
        local hide_slot = hide_whole_body or VersusModeState.first_person_head_slots[slot_name] == true

        if hide_slot and slot then
            local restore_visible = slot.visible ~= false

            if slot.unit then
                VersusModeState.remember_and_hide_first_person_unit(state, slot.unit, restore_visible)
            end

            for i = 1, #(slot.attachments or {}) do
                VersusModeState.remember_and_hide_first_person_unit(
                    state,
                    slot.attachments[i],
                    restore_visible
                )
            end
        end
    end

    return true
end

function VersusModeState.set_controlled_first_person(state, enabled)
    if not state or not state.possessed then
        return false
    end

    enabled = enabled == true

    if enabled and not VersusModeState.first_person_supported(state) then
        return false
    end

    state.first_person = enabled
    state.camera_collision_distance = nil
    state.camera_collision_at = nil

    if enabled then
        hide_original_first_person_equipment(state)
        VersusModeState.refresh_controlled_first_person_visibility(state, true)
    else
        VersusModeState.restore_controlled_first_person_visibility(state)
        restore_original_first_person_equipment(state)
    end

    return true
end

local function live_world_position(unit)
    if not unit or not ALIVE[unit] then
        return nil
    end

    local ok, position = pcall(Unit.world_position, unit, 1)

    if ok then
        return position
    end

    return nil
end

local function node_world_position(unit, node_name)
    if not unit or not ALIVE[unit] or not node_name then
        return nil
    end

    local has_node_ok, has_node = pcall(Unit.has_node, unit, node_name)

    if not has_node_ok or not has_node then
        return nil
    end

    local node_ok, node = pcall(Unit.node, unit, node_name)

    if not node_ok then
        return nil
    end

    local position_ok, position = pcall(Unit.world_position, unit, node)

    return position_ok and position or nil
end

local function state_look_direction(state)
    local flat_forward = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)
    local pitch_cos = math_cos(state.pitch)

    return Vector3(
        Vector3.x(flat_forward) * pitch_cos,
        Vector3.y(flat_forward) * pitch_cos,
        math_sin(state.pitch)
    ), flat_forward
end

function VersusModeState.first_person_camera_collision_guard(safe_position, wanted_position, flat_forward, collision_position)
    if not safe_position or not wanted_position or not flat_forward then
        return collision_position or wanted_position
    end

    if not collision_position then
        return wanted_position
    end

    local forward_distance = vector3_dot(collision_position - safe_position, flat_forward)

    -- CameraManager returns the safe point itself when the animated head is
    -- already overlapping a wall. That point lies inside the base face mesh.
    -- Keep a small render-only forward clearance even if it clips into the
    -- wall, so the wall can occlude the view but the face can never fill it.
    if forward_distance < VersusModeState.first_person_camera_min_forward_offset then
        return safe_position + flat_forward * VersusModeState.first_person_camera_min_forward_offset
    end

    return collision_position
end

local function sniper_camera_position(state, look_direction, flat_forward)
    local fallback_height = type(state.breed.base_height) == "number"
        and state.breed.base_height * 0.85 or 1.65
    local head_scale_snapshot = state.first_person_head_scale_snapshot
    local head_position

    if head_scale_snapshot
        and head_scale_snapshot.node_name ~= "j_head"
        and type(head_scale_snapshot.camera_height_offset) == "number" then
        local anchor_position = node_world_position(state.unit, head_scale_snapshot.node_name)

        if anchor_position then
            head_position = anchor_position
                + vector3_up() * head_scale_snapshot.camera_height_offset
        end
    end

    head_position = head_position or node_world_position(state.unit, "j_head")
        or node_world_position(state.unit, state.breed.aim_config and state.breed.aim_config.node)
        or (live_world_position(state.unit) + vector3_up() * fallback_height)
    local safe_position = head_position + vector3_up() * SNIPER_CAMERA_UP_OFFSET
    local wanted_position = safe_position + flat_forward * SNIPER_CAMERA_FORWARD_OFFSET
    local camera_manager = Managers.state and Managers.state.camera

    if camera_manager and camera_manager._smooth_camera_collision then
        local ok, collision_position = pcall(camera_manager._smooth_camera_collision, camera_manager, wanted_position, safe_position, 0.04, 0.015)

        if ok and collision_position then
            return VersusModeState.first_person_camera_collision_guard(
                safe_position,
                wanted_position,
                flat_forward,
                collision_position
            )
        end
    end

    return wanted_position
end

local function camera_aim_ray(state)
    local physics_world = state.physics_world

    if not physics_world then
        return nil, nil, nil
    end

    local look_direction, flat_forward = state_look_direction(state)
    local stored_camera_position = state.camera_position
    local origin = state.first_person and sniper_camera_position(state, look_direction, flat_forward)
        or stored_camera_position and stored_camera_position:unbox()
        or (live_world_position(state.unit) + vector3_up() * setting("camera_height"))
    local hit, hit_position, _, _, hit_actor = PhysicsWorld.raycast(
        physics_world,
        origin,
        look_direction,
        SNIPER_AIM_DISTANCE,
        "closest",
        "collision_filter",
        "filter_minion_shooting_no_friendly_fire"
    )
    local aim_position = hit_position or origin + look_direction * SNIPER_AIM_DISTANCE
    local hit_unit

    if hit and hit_actor then
        local actor_ok, actor_unit = pcall(Actor.unit, hit_actor)

        if actor_ok then
            hit_unit = actor_unit
        end
    end

    return aim_position, hit_unit, vector3_distance(origin, aim_position)
end

local function grenade_preview_collision(state, from_position, to_position, radius, collision_types, collision_filter)
    local sweep_ok, hits = pcall(
        PhysicsWorld.linear_sphere_sweep,
        state.physics_world,
        from_position,
        to_position,
        radius,
        32,
        "types",
        collision_types,
        "collision_filter",
        collision_filter
    )

    if not sweep_ok or not hits then
        return nil
    end

    for i = 1, #hits do
        local hit = hits[i]
        local hit_position = hit.position or hit[1]
        local hit_actor = hit.actor or hit[4]
        local hit_unit

        if hit_actor then
            local actor_ok, actor_unit = pcall(Actor.unit, hit_actor)

            if actor_ok then
                hit_unit = actor_unit
            end
        end

        -- The native projectile cast ignores its owner. The preview has no
        -- projectile unit yet, so explicitly skip the possessed Grenadier.
        if hit_position and hit_unit ~= state.unit then
            local hit_normal = hit.normal or hit[3]

            return hit_position, hit_normal, hit_unit
        end
    end

    return nil
end

local function grenade_launch_direction(state, throw_position, look_direction, collision_types, collision_filter)
    local free_flight = Managers.free_flight
    local camera
    local camera_position

    if free_flight and free_flight:is_in_free_flight() then
        local camera_ok, active_camera = pcall(free_flight.camera, free_flight, "global")

        camera = camera_ok and active_camera or nil
    end

    if camera then
        local position_ok, active_position = pcall(Camera.local_position, camera)

        if position_ok then
            camera_position = active_position
        end
    end

    if not camera_position then
        return look_direction
    end

    -- A direction copied directly from a third-person camera is parallel to
    -- the crosshair ray rather than converging on it. That parallax is mostly
    -- invisible at normal ranges, but becomes severe when aiming at the floor
    -- beside the Grenadier. Only correct the short-range case so long throws
    -- retain the player's explicitly chosen ballistic pitch.
    local ray_end_ok, ray_end = pcall(function()
        return camera_position + look_direction * GRENADE_CAMERA_RAY_DISTANCE
    end)

    -- Camera APIs can briefly expose a boxed/native userdata while the
    -- free-flight viewport is entering or recovering. The parallax correction
    -- is optional, so preserve the raw throw direction instead of allowing
    -- that transient value to abort all grenade preview updates.
    if not ray_end_ok or not ray_end then
        return look_direction
    end

    local aim_position = grenade_preview_collision(
        state,
        camera_position,
        ray_end,
        0.01,
        collision_types,
        collision_filter
    )

    if not aim_position then
        return look_direction
    end

    local to_aim = aim_position - throw_position
    local aim_distance = vector3_length(to_aim)

    if aim_distance < GRENADE_MIN_AIM_DISTANCE or aim_distance > GRENADE_CLOSE_AIM_DISTANCE then
        return look_direction
    end

    local corrected_direction = vector3_normalize(to_aim)

    -- Do not let a crosshair point behind the hand reverse the throw when the
    -- camera is pressed against geometry or looking almost straight down.
    if vector3_dot(corrected_direction, look_direction) <= 0.1 then
        return look_direction
    end

    return corrected_direction
end

local function grenade_free_aim_solution(state)
    local breed_actions = BreedActions[state.breed.name]
    local follow_data = breed_actions and breed_actions.follow
    local throw_data = breed_actions and breed_actions.throw_grenade
    local throw_anim_events = follow_data and follow_data.throw_anim_events
    local long_events = throw_anim_events and throw_anim_events.long
    local anim_event = long_events and long_events[1]
    local local_offset_box = anim_event and follow_data.throw_node_local_offset and follow_data.throw_node_local_offset[anim_event]
    local projectile_template = throw_data and throw_data.throw_config and throw_data.throw_config.projectile_template
    local locomotion_template = projectile_template and projectile_template.locomotion_template
    local trajectory_parameters = locomotion_template and locomotion_template.trajectory_parameters and locomotion_template.trajectory_parameters.throw
    local integrator_parameters = locomotion_template and locomotion_template.integrator_parameters
    local unit_position = live_world_position(state.unit)

    if not state.physics_world or not anim_event or not local_offset_box or not trajectory_parameters or not integrator_parameters or not unit_position then
        return nil
    end

    local look_direction, flat_forward = state_look_direction(state)

    if vector3_length(flat_forward) < 0.001 or vector3_length(look_direction) < 0.001 then
        return nil
    end

    look_direction = vector3_normalize(look_direction)
    flat_forward = vector3_normalize(flat_forward)

    local wanted_rotation = Quaternion.look(flat_forward, vector3_up())
    local scale = Unit.world_scale(state.unit, 1)
    local root_pose = Matrix4x4.from_quaternion_position_scale(wanted_rotation, unit_position, scale)
    local throw_position = Matrix4x4.transform(root_pose, local_offset_box:unbox())
    local speed = trajectory_parameters.speed_initial or trajectory_parameters.speed
    local gravity = integrator_parameters.gravity

    if not speed or not gravity then
        return nil
    end

    local collision_filter = integrator_parameters.collision_filter or "filter_minion_throwing"
    local collision_types = integrator_parameters.collision_types or "both"
    local radius = integrator_parameters.radius or 0.025
    local launch_direction = grenade_launch_direction(
        state,
        throw_position,
        look_direction,
        collision_types,
        collision_filter
    )
    local mass = integrator_parameters.mass or 1
    local air_density = integrator_parameters.air_density or 0
    local drag_coefficient = integrator_parameters.drag_coefficient or 0
    local air_drag = 0.5 * drag_coefficient * (math.pi * radius * radius) * air_density / mass
    local integration_data = {
        position = throw_position,
        previous_position = throw_position,
        velocity = launch_direction * speed,
        acceleration = Vector3(0, 0, 0),
        gravity = gravity,
        air_drag = air_drag,
        collision_filter = collision_filter,
        collision_types = collision_types,
        radius = radius,
        integrator_parameters = integrator_parameters,
        owner_unit = state.unit,
        projectile_unit = nil,
        target_unit = nil,
        true_flight_template = integrator_parameters.true_flight_template,
        damage_extension = nil,
        fx_extension = nil,
        use_generous_bouncing = integrator_parameters.use_generous_bouncing,
        coefficient_of_restitution = integrator_parameters.coefficient_of_restitution or 0,
        have_bounced = nil,
        bounced_this_frame = false,
        number_of_bounces = 0,
        integrate = true,
        last_hit_detection_position = throw_position,
        last_hit_position = nil,
        last_hit_unit = nil,
        has_hit = false,
        time_since_start = 0,
    }
    local fuse_data = projectile_template.damage and projectile_template.damage.fuse
    local fuse_time = fuse_data and fuse_data.fuse_time or 0
    local impact_triggered_fuse = fuse_data and fuse_data.impact_triggered
    local detonation_at

    if not impact_triggered_fuse then
        detonation_at = fuse_time
    end
    -- Continue long enough for very high but eventually valid throws to come
    -- back into the map. The cap applies to the complete flight, including an
    -- impact-triggered fuse, so pathological open trajectories stay bounded.
    local preview_max_time = GRENADE_PREVIEW_MAX_TIME
    local points = { throw_position }
    local bounce_segments = {}
    local impact_position
    local first_impact_position
    local elapsed = 0

    local function append_point(position)
        local previous = points[#points]

        if not previous or vector3_distance(previous, position) > 0.01 then
            points[#points + 1] = position
        end
    end

    while elapsed < preview_max_time do
        local step = math_min(GRENADE_PREVIEW_STEP, preview_max_time - elapsed)

        if detonation_at then
            step = math_min(step, math_max(detonation_at - elapsed, 0))
        end

        if step <= 0.0001 then
            impact_position = integration_data.position

            break
        end

        ProjectileIntegration.integrate_position(state.physics_world, integration_data, step, elapsed, 1, true)
        elapsed = elapsed + step

        if integration_data.has_hit and integration_data.last_hit_position then
            local hit_position = integration_data.last_hit_position

            append_point(hit_position)

            if integration_data.integrate then
                bounce_segments[#points] = true
            end

            first_impact_position = first_impact_position or hit_position

            if impact_triggered_fuse and not detonation_at then
                detonation_at = elapsed + fuse_time
            end
        end

        append_point(integration_data.position)

        if not integration_data.integrate then
            impact_position = integration_data.position

            break
        elseif detonation_at and elapsed >= detonation_at - 0.0001 then
            impact_position = integration_data.position

            break
        end
    end

    -- An impact-triggered enemy grenade is not armed until it touches
    -- something. Keep the airborne path visible, but do not advertise a false
    -- impact area if the simulation times out without a collision.
    if impact_triggered_fuse and not first_impact_position then
        impact_position = nil
    end

    local area_radius = GRENADE_AREA_RADIUS[state.breed.name] or 5
    local sampled_points = points
    local sampled_bounce_segments = bounce_segments

    -- The physics pass keeps every integration step for collision accuracy,
    -- but the HUD only needs a bounded number of vertices. Preserve endpoints
    -- and every bounce boundary, then distribute the remaining samples across
    -- the complete flight so long high arcs do not increase UI draw cost.
    if #points > GRENADE_PREVIEW_MAX_POINTS then
        local selected = {
            [1] = true,
            [#points] = true,
        }
        local selected_count = 2

        for i = 1, #points - 1 do
            if bounce_segments[i] then
                if not selected[i] then
                    selected[i] = true
                    selected_count = selected_count + 1
                end

                if not selected[i + 1] then
                    selected[i + 1] = true
                    selected_count = selected_count + 1
                end
            end
        end

        local remaining = math_max(GRENADE_PREVIEW_MAX_POINTS - selected_count, 0)

        for i = 1, remaining do
            local index = math.floor(1 + i * (#points - 1) / (remaining + 1) + 0.5)

            selected[index] = true
        end

        local selected_indices = {}

        for i = 1, #points do
            if selected[i] then
                selected_indices[#selected_indices + 1] = i
            end
        end

        sampled_points = {}
        sampled_bounce_segments = {}

        for i = 1, #selected_indices do
            sampled_points[i] = points[selected_indices[i]]

            if i < #selected_indices then
                for original_index = selected_indices[i], selected_indices[i + 1] - 1 do
                    if bounce_segments[original_index] then
                        sampled_bounce_segments[i] = true

                        break
                    end
                end
            end
        end
    end

    local boxed_points = {}

    for i = 1, #sampled_points do
        boxed_points[i] = Vector3Box(sampled_points[i])
    end

    return {
        -- A missing impact means the path left the currently collidable map
        -- volume; the launch data itself is still valid and the real
        -- projectile should be allowed to follow that open trajectory.
        valid = true,
        has_impact = impact_position ~= nil,
        points = boxed_points,
        bounce_segments = sampled_bounce_segments,
        impact_position = impact_position and Vector3Box(impact_position) or nil,
        throw_position = Vector3Box(throw_position),
        throw_direction = Vector3Box(launch_direction),
        wanted_rotation = QuaternionBox(wanted_rotation),
        anim_event = anim_event,
        area_radius = area_radius,
        distance = impact_position and vector3_distance(unit_position, impact_position) or nil,
    }
end

local function grenade_locked_target_solution(state, target_unit)
    local breed_actions = BreedActions[state.breed.name]
    local follow_data = breed_actions and breed_actions.follow
    local throw_data = breed_actions and breed_actions.throw_grenade
    local throw_config = throw_data and throw_data.throw_config
    local projectile_template = throw_config and throw_config.projectile_template
    local locomotion_template = projectile_template and projectile_template.locomotion_template
    local trajectory_parameters = locomotion_template and locomotion_template.trajectory_parameters and locomotion_template.trajectory_parameters.throw
    local integrator_parameters = locomotion_template and locomotion_template.integrator_parameters
    local unit_position = live_world_position(state.unit)
    local target_position = live_world_position(target_unit)

    if not state.physics_world or not follow_data or not throw_config or not trajectory_parameters or not integrator_parameters or not unit_position or not target_position then
        return nil
    end

    -- Match the native Grenadier solver's small lift above the navigation
    -- surface so the final trajectory segment does not treat the floor under
    -- the target as an obstruction before reaching the intended landing.
    target_position = target_position + Vector3(0, 0, 0.1)

    local flat_to_target = Vector3.flat(target_position - unit_position)
    local target_distance = vector3_length(flat_to_target)

    if target_distance < 0.05 then
        return nil
    end

    local thresholds = follow_data.throw_distance_thresholds or {}
    local event_group = target_distance < (thresholds.close or 4) and "close"
        or target_distance < (thresholds.medium or 10) and "medium"
        or "long"
    local events = follow_data.throw_anim_events and follow_data.throw_anim_events[event_group]
    local anim_event = events and events[1]
    local local_offset_box = anim_event and follow_data.throw_node_local_offset and follow_data.throw_node_local_offset[anim_event]
    local speed = trajectory_parameters.speed_initial or trajectory_parameters.speed
    local gravity = integrator_parameters.gravity

    if not anim_event or not local_offset_box or not speed or not gravity then
        return nil
    end

    local wanted_rotation = Quaternion.look(vector3_normalize(flat_to_target), vector3_up())
    local scale = Unit.world_scale(state.unit, 1)
    local root_pose = Matrix4x4.from_quaternion_position_scale(wanted_rotation, unit_position, scale)
    local throw_position = Matrix4x4.transform(root_pose, local_offset_box:unbox())
    local target_velocity = Vector3.zero()
    local velocity_ok, moving_velocity = pcall(MinionMovement.target_velocity, target_unit)

    if velocity_ok and moving_velocity then
        target_velocity = moving_velocity
    end

    local collision_filter = integrator_parameters.collision_filter or "filter_minion_throwing"
    local radius = integrator_parameters.radius or 0.025
    local acceptable_accuracy = throw_config.acceptable_accuracy or 1

    local function try_angle(use_high_arc)
        local angle, estimated_position = Trajectory.angle_to_hit_moving_target(
            throw_position,
            target_position,
            speed,
            target_velocity,
            gravity,
            acceptable_accuracy,
            use_high_arc
        )

        if not angle or not estimated_position then
            return nil
        end

        local velocity, time_in_flight = Trajectory.get_trajectory_velocity(
            throw_position,
            estimated_position,
            gravity,
            speed,
            angle
        )

        if not velocity or not time_in_flight or time_in_flight <= 0 then
            return nil
        end

        local trajectory_ok = Trajectory.check_trajectory_collisions(
            state.physics_world,
            throw_position,
            estimated_position,
            gravity,
            speed,
            angle,
            40,
            collision_filter,
            time_in_flight,
            false,
            radius,
            acceptable_accuracy + radius
        )

        if not trajectory_ok then
            return nil
        end

        return vector3_normalize(velocity), estimated_position
    end

    local launch_direction, estimated_position = try_angle(false)
    local trajectory_kind = "LOW ARC"

    if not launch_direction then
        launch_direction, estimated_position = try_angle(true)
        trajectory_kind = "HIGH ARC"
    end

    if not launch_direction then
        return nil
    end

    return {
        valid = true,
        has_impact = true,
        throw_position = Vector3Box(throw_position),
        throw_direction = Vector3Box(launch_direction),
        wanted_rotation = QuaternionBox(wanted_rotation),
        anim_event = anim_event,
        target_position = Vector3Box(estimated_position),
        trajectory_kind = trajectory_kind,
        area_radius = GRENADE_AREA_RADIUS[state.breed.name] or 5,
        distance = target_distance,
    }
end

local function destroy_grenade_preview(state)
    if state then
        state.grenade_preview_solution = nil
        state.grenade_preview_next_update = nil
    end
end

function Specialist.destroy_hound_preview(state)
    if state then
        state.hound_pounce_preview_active = nil
        state.hound_pounce_preview_solution = nil
        state.hound_pounce_preview_next_update = nil
        state.hound_pounce_charge_started_at = nil
        state.hound_pounce_charge_fraction = nil
    end
end

function Specialist.hound_uses_charge_mode()
    return setting("hound_heavy_trajectory_mode") ~= "camera_pitch"
end

function Specialist.hound_charge_fraction(state, t)
    local started_at = state and state.hound_pounce_charge_started_at or t
    local duration = Specialist.hound_charge_duration

    if type(started_at) ~= "number" or type(t) ~= "number" or duration <= 0 then
        return 0
    end

    return math_max(0, math_min(1, (t - started_at) / duration))
end

function Specialist.hound_charge_pitch(charge_fraction)
    local fraction = math_max(0, math_min(1, tonumber(charge_fraction) or 0))

    return Specialist.hound_charge_min_pitch
        + (Specialist.hound_charge_max_pitch - Specialist.hound_charge_min_pitch) * fraction
end

local function commit_grenade_solution(state, blackboard)
    local solution = state.grenade_committed_solution
    local throw_grenade_component = blackboard and blackboard.throw_grenade

    if not solution or not solution.valid or not throw_grenade_component then
        return false
    end

    throw_grenade_component.throw_direction:store(solution.throw_direction:unbox())
    throw_grenade_component.throw_position:store(solution.throw_position:unbox())
    throw_grenade_component.wanted_rotation:store(solution.wanted_rotation:unbox())
    throw_grenade_component.anim_event = solution.anim_event

    return true
end

local function update_manual_aim_preview(state)
    if HOUND_BREEDS[state.breed.name] and state.hound_pounce_preview_active then
        local t = gameplay_time()

        if t < (state.hound_pounce_preview_next_update or 0) then
            return
        end

        state.hound_pounce_preview_next_update = t + Specialist.hound_preview_refresh_interval
        local charge_fraction
        local preferred_pitch

        if Specialist.hound_uses_charge_mode() then
            charge_fraction = Specialist.hound_charge_fraction(state, t)
            preferred_pitch = Specialist.hound_charge_pitch(charge_fraction)
        end

        state.hound_pounce_charge_fraction = charge_fraction
        state.hound_pounce_preview_solution = Specialist.hound_pounce_solution
            and Specialist.hound_pounce_solution(state, state.yaw, preferred_pitch, charge_fraction)
            or nil

        local solution = state.hound_pounce_preview_solution

        state.manual_aim_hit_unit = solution and solution.target_unit or nil
        state.manual_aim_distance = solution and solution.distance or nil
        state.manual_aim_position = solution and solution.impact_position and solution.impact_position:unbox() or nil

        return
    end

    if GRENADIER_BREEDS[state.breed.name] and state.grenadier_target_lock == false then
        local t = gameplay_time()

        if t < (state.grenade_preview_next_update or 0) then
            return
        end

        state.grenade_preview_next_update = t + GRENADE_PREVIEW_REFRESH_INTERVAL
        local solution = grenade_free_aim_solution(state)

        state.grenade_preview_solution = solution
        state.manual_aim_position = nil
        state.manual_aim_hit_unit = nil
        state.manual_aim_distance = solution and solution.distance or nil
        return
    end

    if not state.first_person and not Specialist.free_aim(state) then
        return
    end

    local aim_position, hit_unit, distance = camera_aim_ray(state)

    if aim_position then
        state.manual_aim_position = aim_position
        state.manual_aim_hit_unit = Specialist.free_aim(state)
            and Specialist.free_aim_attack_target
            and Specialist.free_aim_attack_target(state)
            or hit_unit
        state.manual_aim_distance = distance
    end
end

local function refresh_engine_position(unit)
    local position = live_world_position(unit)

    if position and POSITION_LOOKUP then
        POSITION_LOOKUP[unit] = position
    end

    return position
end

function VersusModeState.normal_boss_status(unit, breed, boss_extension)
    if not unit or not breed or not breed.is_boss then
        return false, "not a boss"
    end

    boss_extension = boss_extension or safe_extension(unit, "boss_system")

    if not boss_extension then
        return false, "boss metadata unavailable"
    end

    if boss_extension._versus_mode_classification_ready ~= true then
        return false, "boss classification pending"
    end

    local status_ok, weakened = safe_extension_call(boss_extension, "is_weakened")

    if not status_ok then
        return false, "boss metadata unreadable"
    end

    -- Retain the historical function name for save/Realms compatibility, but
    -- both full-strength and weakened BossExtension classifications are now
    -- controllable. The fourth result lets allocation/UI code describe the
    -- classified strength without ever mutating it.
    return true, nil, boss_extension, weakened == true
end

function VersusModeState.daemonhost_stage(unit)
    local boss_extension = safe_extension(unit, "boss_system")
    local template_data = boss_extension and boss_extension._template_data
    local game_session = template_data and template_data.game_session
    local game_object_id = template_data and template_data.game_object_id

    if not game_session then
        local manager = Managers.state and Managers.state.game_session
        local session_ok, session = pcall(function()
            return manager and manager:game_session()
        end)

        game_session = session_ok and session or nil
    end

    if game_object_id == nil then
        local spawner = Managers.state and Managers.state.unit_spawner
        local id_ok, object_id = pcall(function()
            return spawner and spawner:game_object_id(unit)
        end)

        game_object_id = id_ok and object_id or nil
    end

    if not game_session or game_object_id == nil then
        return nil
    end

    local get_field = GameSession and GameSession.game_object_field

    if type(get_field) ~= "function" then
        return nil
    end

    local stage_ok, stage = pcall(get_field, game_session, game_object_id, "stage")

    return stage_ok and stage or nil
end

function VersusModeState.daemonhost_control_status(unit, breed)
    if not breed or not VersusModeState.daemonhost_breeds[breed.name] then
        return "ready"
    end

    local stage = VersusModeState.daemonhost_stage(unit)
    local stages = VersusModeState.daemonhost_settings.stages

    if stage == stages.aggroed then
        return "ready", stage
    elseif stage == stages.death_normal or stage == stages.death_leave then
        return "ended", stage
    end

    -- Missing replication data is treated conservatively. Possession pauses
    -- the behavior tree, and doing that before the passive leaf has left is
    -- exactly what causes Darktide to wake a Daemonhost instantly.
    return "waking", stage
end

function VersusModeState.daemonhost_victim_limit_reached(state)
    local statistics = state and state.blackboard and state.blackboard.statistics

    return state
        and state.breed
        and state.breed.name == "chaos_daemonhost"
        and statistics
        and type(statistics.player_deaths) == "number"
        and statistics.player_deaths >= 1
        or false
end

function VersusModeState.begin_normal_daemonhost_leave(state)
    if not VersusModeState.daemonhost_victim_limit_reached(state) then
        return false
    end

    mod._daemonhost_forced_leave = mod._daemonhost_forced_leave
        or setmetatable({}, { __mode = "k" })
    mod._daemonhost_forced_leave[state.unit] = true

    if state.perception_component then
        state.perception_component.lock_target = false
    end

    VersusModeState.release_control(
        state,
        mod:localize("notice_daemonhost_victim_limit"),
        false,
        false
    )

    return true
end

local function controllable_breed(unit)
    local unit_data_extension = safe_extension(unit, "unit_data_system")
    local breed = unit_data_extension and unit_data_extension:breed()

    if breed and is_specialist_breed(breed) then
        return breed
    end

    if breed and VersusModeState.controlled_elite_breeds[breed.name] then
        return breed
    end

    if breed and breed.is_boss then
        local normal_boss = VersusModeState.normal_boss_status(unit, breed)

        if normal_boss and VersusModeState.daemonhost_breeds[breed.name] then
            local status = VersusModeState.daemonhost_control_status(unit, breed)

            if status ~= "ready" then
                return nil, status == "ended" and "daemonhost ended" or "daemonhost not awake", breed
            end
        end

        return normal_boss and breed or nil
    end

    return nil
end

local function valid_player_target(unit)
    if not unit or VersusModeState.is_unit(unit) or not HEALTH_ALIVE[unit] or not live_world_position(unit) then
        return false
    end

    local unit_data_extension = safe_extension(unit, "unit_data_system")
    local breed = unit_data_extension and unit_data_extension:breed()

    if not Breed.is_player(breed) then
        return false
    end

    local player_manager = Managers.player
    local player = player_manager and player_manager.player_by_unit and player_manager:player_by_unit(unit)

    return player ~= nil
end

function VersusModeState.player_is_hidden_from_infected(unit)
    if not valid_player_target(unit) then
        return false
    end

    local buff_extension = safe_extension(unit, "buff_system")
    local keywords = VersusModeState.buff_settings.keywords

    if not buff_extension or not keywords then
        return false
    end

    local invisible_ok, invisible = pcall(
        buff_extension.has_keyword,
        buff_extension,
        keywords.invisible
    )
    local unperceivable_ok, unperceivable = pcall(
        buff_extension.has_keyword,
        buff_extension,
        keywords.unperceivable
    )

    return invisible_ok and invisible == true or unperceivable_ok and unperceivable == true
end

function VersusModeState.infected_stealth_targeting_active(state)
    if state then
        return state.versus_role ~= nil
    end

    local local_state = mod._control

    if local_state and local_state.possessed then
        return local_state.versus_role ~= nil
    end

    return VersusModeState.local_active()
end

function VersusModeState.gunner_auto_lock_can_target(unit, state)
    if not state or not state.possessed or not state.breed
        or not VersusModeState.gunner_breeds[state.breed.name]
        or state.grenadier_target_lock == false then
        return true
    end

    local gunner_position = live_world_position(state.unit)
    local target_position = live_world_position(unit)

    if not gunner_position or not target_position
        or vector3_distance(gunner_position, target_position) <= VersusModeState.gunner_smoke_melee_range then
        return true
    end

    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, smoke_system = pcall(function()
        return extension_manager and extension_manager:system("smoke_fog_system")
    end)
    local fog_extensions = system_ok and smoke_system and smoke_system._unit_to_extension_map

    if not fog_extensions then
        return true
    end

    local target_in_smoke = false

    for _, fog in pairs(fog_extensions) do
        if fog.block_line_of_sight and not fog.is_expired
            and type(fog.is_unit_inside) == "function" then
            local target_ok, target_inside = pcall(fog.is_unit_inside, fog, target_position)

            if target_ok and target_inside then
                target_in_smoke = true

                local gunner_ok, gunner_inside = pcall(fog.is_unit_inside, fog, gunner_position)

                if gunner_ok and gunner_inside then
                    return true
                end
            end
        end
    end

    return not target_in_smoke
end

function VersusModeState.valid_attack_target(unit, state)
    return valid_player_target(unit)
        and (not VersusModeState.infected_stealth_targeting_active(state)
            or not VersusModeState.player_is_hidden_from_infected(unit))
        and VersusModeState.gunner_auto_lock_can_target(unit, state)
end

function VersusModeState.refresh_infected_stealth_visibility()
    local previous = mod._infected_hidden_survivors or {}
    local current = setmetatable({}, { __mode = "k" })
    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, fade_system = pcall(function()
        return extension_manager and extension_manager:system("fade_system")
    end)

    fade_system = system_ok and fade_system or nil

    if VersusModeState.local_infected_view() and fade_system then
        local player_manager = Managers.player
        local players_ok, players = pcall(function()
            return player_manager and player_manager:players()
        end)

        for _, player in pairs(players_ok and players or {}) do
            local unit = player and player.player_unit

            if VersusModeState.player_is_hidden_from_infected(unit) then
                pcall(fade_system.set_min_fade, fade_system, unit, 1)
                current[unit] = true
            end
        end
    end

    if fade_system then
        for unit in pairs(previous) do
            if not current[unit] then
                -- Native stealth renders allies at 50% fade. Restore that
                -- value if the ability is still active when the infected view
                -- ends; otherwise return the unit to the ordinary zero floor.
                local restore_fade = VersusModeState.player_is_hidden_from_infected(unit) and 0.5 or 0

                pcall(fade_system.set_min_fade, fade_system, unit, restore_fade)
            end
        end
    end

    mod._infected_hidden_survivors = next(current) and current or nil
end

function VersusModeState.clear_infected_stealth_visibility()
    local hidden = mod._infected_hidden_survivors

    if not hidden then
        return
    end

    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, fade_system = pcall(function()
        return extension_manager and extension_manager:system("fade_system")
    end)

    if system_ok and fade_system then
        mod._restoring_infected_stealth_visibility = true

        for unit in pairs(hidden) do
            local restore_fade = VersusModeState.player_is_hidden_from_infected(unit) and 0.5 or 0

            pcall(fade_system.set_min_fade, fade_system, unit, restore_fade)
        end

        mod._restoring_infected_stealth_visibility = nil
    end

    mod._infected_hidden_survivors = nil
end

function VersusModeState.remove_hidden_survivor_nameplates(element)
    if not VersusModeState.local_infected_view() then
        return
    end

    local nameplate_units = element and element._nameplate_units

    if not nameplate_units then
        return
    end

    for unit, data in pairs(nameplate_units) do
        if VersusModeState.player_is_hidden_from_infected(unit) then
            if data.marker_id and Managers.event then
                Managers.event:trigger("remove_world_marker", data.marker_id)
            end

            nameplate_units[unit] = nil
        end
    end
end

local function pretty_name(breed)
    local display_name = breed and breed.display_name

    if display_name then
        local ok, localized = pcall(Localize, display_name)

        if ok and localized and localized ~= display_name then
            return localized
        end
    end

    local name = breed and breed.name or "boss"

    name = string.gsub(name, "^chaos_", "")
    name = string.gsub(name, "^cultist_", "")
    name = string.gsub(name, "^renegade_", "")
    name = string.gsub(name, "_", " ")

    return string.gsub(" " .. name, "%W%l", string.upper):sub(2)
end

function VersusModeState.controlled_label(state)
    if state and state.variant_id then
        return VersusModeState.respawn_label(state.breed.name, state.variant_id)
    end

    return pretty_name(state and state.breed)
end

local function camera_origin_rotation(player)
    local camera_manager = Managers.state and Managers.state.camera

    if not camera_manager or not player or not player.viewport_name then
        return nil, nil
    end

    return camera_manager:camera_position(player.viewport_name), camera_manager:camera_rotation(player.viewport_name)
end

function VersusModeState.camera_handler_role(handler)
    local role = VersusModeState.local_active() and mod._versus_role_test or nil

    if not role or not handler then
        return nil
    end

    local handler_player = handler._player
    local expected_player = local_player() or role.infected_player

    if handler_player and expected_player and handler_player ~= expected_player then
        return nil
    end

    return role
end

function VersusModeState.cinematic_camera_active()
    local cinematic = Managers.state and Managers.state.cinematic

    if not cinematic or not cinematic.cinematic_active then
        return false
    end

    local ok, active = pcall(cinematic.cinematic_active, cinematic)

    return ok and active == true
end

-- CameraHandler's follow-unit field and each player first-person extension can
-- become desynchronized during a networked hogtied/spectator transition. In
-- that state CameraHandler already reports the infected shell, but the old
-- survivor still has is_camera_follow_target=true. Exclusive survivor sounds
-- and screen particles (including Zealot Until Death) use that extension flag
-- directly, so they continue to play through the infected free-flight view.
-- Clear the flag on every client-side player unit instead of trusting the
-- handler's single cached unit.
function VersusModeState.detach_observer_player_units(role)
    if not role or role.camera_restoring then
        return 0
    end

    local player_manager = Managers.player
    local players = player_manager and player_manager:players()
    local detached = 0

    for _, player in pairs(players or {}) do
        local unit = player and player.player_unit
        local first_person_extension = unit and ALIVE[unit]
            and ScriptUnit.has_extension(unit, "first_person_system")

        if first_person_extension then
            local was_followed = first_person_extension._is_camera_follow_target == true

            if first_person_extension.is_camera_follow_target then
                local ok, followed = pcall(
                    first_person_extension.is_camera_follow_target,
                    first_person_extension
                )

                was_followed = ok and followed == true or was_followed
            end

            pcall(
                first_person_extension.set_camera_follow_target,
                first_person_extension,
                false,
                false
            )

            if was_followed then
                detached = detached + 1
            end
        end
    end

    return detached
end

-- Survivor damage moods are a separate camera path from exclusive player FX.
-- Transition the native MoodHandler through removing -> inactive once, then
-- keep its camera blend empty for as long as the infected role owns the view.
function VersusModeState.clear_observer_moods(role, handler)
    local mood_handler = handler and handler._mood_handler
    local camera_manager = Managers.state and Managers.state.camera

    if not role or not mood_handler then
        return false
    end

    role.camera_empty_mood_blend = role.camera_empty_mood_blend or {}
    table.clear(role.camera_empty_mood_blend)

    if not role.camera_moods_cleared and mood_handler._current_moods_status then
        local removing_data = {}
        local inactive_data = {}

        for mood_type, current_status in pairs(mood_handler._current_moods_status) do
            removing_data[mood_type] = {
                entered_t = 0,
                removed_t = 0,
                status = current_status == "active" and "removing" or current_status,
            }
            inactive_data[mood_type] = {
                entered_t = math.huge,
                removed_t = math.huge,
                status = "inactive",
            }
        end

        local removing_ok = pcall(
            mood_handler.update_moods,
            mood_handler,
            role.camera_empty_mood_blend,
            removing_data
        )

        table.clear(role.camera_empty_mood_blend)

        local inactive_ok = pcall(
            mood_handler.update_moods,
            mood_handler,
            role.camera_empty_mood_blend,
            inactive_data
        )

        role.camera_moods_cleared = removing_ok and inactive_ok
    end

    if camera_manager and camera_manager.set_mood_blend_list then
        pcall(camera_manager.set_mood_blend_list, camera_manager, role.camera_empty_mood_blend)
    end

    return role.camera_moods_cleared == true
end

function VersusModeState.position_diagnostic(position)
    if not position then
        return "none"
    end

    local ok, result = pcall(function()
        return string.format(
            "%.1f,%.1f,%.1f",
            Vector3.x(position),
            Vector3.y(position),
            Vector3.z(position)
        )
    end)

    return ok and result or "unreadable"
end

function VersusModeState.free_flight_position()
    local free_flight = Managers.free_flight

    if not free_flight or not free_flight.is_in_free_flight or not free_flight:is_in_free_flight() then
        return nil
    end

    local ok, position = pcall(free_flight.camera_position_rotation, free_flight, "global")

    return ok and position or nil
end

function VersusModeState.streaming_focus(role)
    local state = mod._control

    if state and state.possessed and state.versus_role == role then
        if state.camera_position then
            local ok, position = pcall(state.camera_position.unbox, state.camera_position)

            if ok and position then
                return position
            end
        end

        local controlled_position = live_world_position(state.unit)

        if controlled_position then
            return controlled_position
        end
    end

    return VersusModeState.free_flight_position() or live_world_position(role and role.infected_unit)
end

function VersusModeState.select_streaming_anchor(role, focus_position)
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local best_unit
    local best_player
    local best_distance = math.huge

    for _, player in pairs(players or {}) do
        local unit = player and player.player_unit

        if valid_player_target(unit) then
            local position = live_world_position(unit)
            local distance = focus_position and position and vector3_distance(focus_position, position) or 0

            if distance < best_distance then
                best_unit = unit
                best_player = player
                best_distance = distance
            end
        end
    end

    local current_unit = role and role.streaming_anchor_unit
    local current_position = valid_player_target(current_unit) and live_world_position(current_unit) or nil
    local current_distance = focus_position and current_position and vector3_distance(focus_position, current_position)

    -- Keep a healthy current reference unless another survivor is materially
    -- closer. This avoids camera-root churn when two players run side by side.
    if current_position
        and best_unit ~= current_unit
        and (not focus_position or current_distance <= best_distance + VersusModeState.streaming_anchor_switch_advantage) then
        best_unit = current_unit
        best_distance = current_distance or 0
        best_player = player_manager and player_manager.player_by_unit
            and player_manager:player_by_unit(current_unit)
    end

    return best_unit, best_player, best_distance
end

function VersusModeState.refresh_streaming_anchor(role, focus_position, force)
    if not role then
        return nil, false, false
    end

    local t = gameplay_time()
    local refresh_forced = force or role.streaming_refresh_forced
    local current_unit = role.streaming_anchor_unit

    if not refresh_forced
        and valid_player_target(current_unit)
        and t < (role.streaming_anchor_refresh_at or 0) then
        return current_unit, false, false
    end

    role.streaming_refresh_forced = nil
    role.streaming_anchor_refresh_at = t + VersusModeState.streaming_anchor_refresh_interval
    focus_position = focus_position or VersusModeState.streaming_focus(role)

    local selected_unit, selected_player, selected_distance = VersusModeState.select_streaming_anchor(role, focus_position)
    local old_unit = role.streaming_anchor_unit
    local anchor_changed = selected_unit ~= old_unit
    local selected_position = live_world_position(selected_unit)
    local previous_position = not anchor_changed
        and role.streaming_anchor_last_position
        and role.streaming_anchor_last_position:unbox()
    local moved_distance = previous_position and selected_position
        and vector3_distance(previous_position, selected_position)
        or 0
    local transition_detected = role.streaming_transition_pending == true
        or moved_distance >= VersusModeState.streaming_transition_distance

    if moved_distance >= VersusModeState.streaming_transition_distance then
        role.streaming_transition_reason = string.format("anchor moved %.1fm", moved_distance)
    end

    role.streaming_transition_pending = nil
    role.streaming_anchor_unit = selected_unit
    role.streaming_anchor_name = selected_player and VersusModeState.player_name(selected_player) or "none"
    role.streaming_anchor_distance = selected_distance
    role.streaming_anchor_last_position = selected_position and Vector3Box(selected_position) or nil

    return selected_unit, anchor_changed, transition_detected
end

function VersusModeState.note_camera_transition(reason)
    VersusModeState.note_redeployment_transition(reason)

    local role = VersusModeState.local_active() and mod._versus_role_test or nil

    if not role then
        return
    end

    role.streaming_refresh_forced = true
    role.streaming_transition_pending = true
    role.streaming_transition_reason = tostring(reason or "mission transition")
    role.camera_diagnostic_force = true

    local state = mod._control

    if state and state.possessed and state.versus_role == role and not state.remote_client then
        state.animation_heartbeat_reason = role.streaming_transition_reason
    end
end

function VersusModeState.log_camera_diagnostic(role, handler, reason, force)
    if not role then
        return
    end

    local t = gameplay_time()

    if not force and t < (role.camera_diagnostic_at or 0) then
        return
    end

    role.camera_diagnostic_at = t + VersusModeState.camera_diagnostic_interval

    local state = mod._control
    local controlled_position = state and state.possessed and state.versus_role == role
        and live_world_position(state.unit)
        or nil
    local native_unit = handler and handler._camera_follow_unit
    local native_kind = native_unit == role.streaming_anchor_unit and "stream anchor"
        or native_unit == role.infected_unit and "infected shell"
        or native_unit and "other unit"
        or "none"

    mod:info(
        "Versus Mode camera diagnostic [%s]: free=%s; shell=%s; controlled=%s; native=%s@%s; anchor=%s@%s.",
        tostring(reason or "periodic"),
        VersusModeState.position_diagnostic(VersusModeState.free_flight_position()),
        VersusModeState.position_diagnostic(live_world_position(role.infected_unit)),
        VersusModeState.position_diagnostic(controlled_position),
        native_kind,
        VersusModeState.position_diagnostic(live_world_position(native_unit)),
        tostring(role.streaming_anchor_name or "none"),
        VersusModeState.position_diagnostic(live_world_position(role.streaming_anchor_unit))
    )
end

-- The infected shell uses vanilla's hogtied state, whose CameraHandler also
-- enables first-person survivor spectating. Global free flight changes only
-- the rendered viewport; without detaching this underlying follow target the
-- followed survivor is hidden, Wwise follows their ears, and their damage
-- moods/post-processing are applied to the infected client. Keep the native
-- handler on a living survivor solely as a world-streaming reference, while
-- blocking first-person follow, moods and audio. Versus Mode's independent
-- free-flight camera remains the only view shown to the infected player.
function VersusModeState.isolate_observer_camera(role, handler, reason)
    role = role or mod._versus_role_test
    handler = handler or role and role.camera_handler

    if not role
        or not handler
        or VersusModeState.camera_handler_role(handler) ~= role
        or VersusModeState.cinematic_camera_active() then
        return false
    end

    local shell = role.infected_unit
    local focus_position = VersusModeState.streaming_focus(role)
    local anchor, anchor_changed, transition_detected = VersusModeState.refresh_streaming_anchor(
        role,
        focus_position,
        role.camera_diagnostic_force
    )
    local follow_unit = anchor or shell and ALIVE[shell] and shell

    if not follow_unit then
        return false
    end

    if role.camera_handler ~= handler then
        role.camera_handler = handler
        role.camera_previous_follow_unit = handler._camera_follow_unit
        role.camera_previous_mode = handler._mode
        role.camera_previous_first_person_spectating_mode = handler._first_person_spectating_mode
        role.camera_isolation_logged = nil
    end

    local old_follow = handler._camera_follow_unit
    local foreign_follow = old_follow and old_follow ~= follow_unit
    local was_observing = handler._mode == VersusModeState.camera_modes.observer
        and handler._first_person_spectating_mode == true
    local old_follow_kind = not old_follow and "none"
        or old_follow == shell and "infected shell"
        or old_follow == role.streaming_anchor_unit and "stream anchor"
        or "other unit"

    handler._first_person_spectating_mode = false
    handler._mode = VersusModeState.camera_modes.observer

    if old_follow ~= follow_unit then
        role.camera_streaming_switch = true

        local switched = pcall(handler._switch_follow_target, handler, follow_unit)

        role.camera_streaming_switch = nil

        if not switched then
            return false
        end
    end

    -- Force the native tree root even when CameraHandler's cached follow unit
    -- is unchanged. Safe-room teleports can move that unit into a newly loaded
    -- sublevel without causing CameraHandler's normal switched-target refresh.
    pcall(handler._update_follow, handler, true)

    if anchor_changed or transition_detected then
        local chunk_lod = Managers.state and Managers.state.chunk_lod

        if chunk_lod and chunk_lod.reset_timer then
            pcall(chunk_lod.reset_timer, chunk_lod)
        end
    end

    local detached = VersusModeState.detach_observer_player_units(role)

    VersusModeState.clear_observer_moods(role, handler)

    local wwise_sync = Managers.wwise_game_sync

    if wwise_sync and wwise_sync.set_followed_player_unit then
        pcall(wwise_sync.set_followed_player_unit, wwise_sync, nil)
    end

    if foreign_follow or anchor_changed or transition_detected or detached > 0 or not role.camera_isolation_logged then
        role.camera_isolation_logged = true
        mod:info(
            "Versus Mode: isolated infected observer camera (%s; native stream anchor: %s; was observing: %s; previous follow: %s; detached player views: %d).",
            tostring(reason or "role active"),
            tostring(role.streaming_anchor_name or "infected shell fallback"),
            was_observing and "yes" or "no",
            old_follow_kind,
            detached
        )
    end

    local diagnostic_reason = role.streaming_transition_reason
        or anchor_changed and "stream anchor changed"
        or role.camera_diagnostic_force and "forced refresh"
        or reason

    VersusModeState.log_camera_diagnostic(
        role,
        handler,
        diagnostic_reason,
        anchor_changed or transition_detected or role.camera_diagnostic_force
    )

    role.streaming_transition_reason = nil
    role.camera_diagnostic_force = nil

    return true
end

function VersusModeState.restore_observer_camera(role)
    local handler = role and role.camera_handler

    if not handler then
        return
    end

    local shell = role.infected_unit

    role.camera_restoring = true

    if shell and ALIVE[shell] then
        handler._first_person_spectating_mode = false
        pcall(handler._switch_follow_target, handler, shell)
        handler._mode = VersusModeState.camera_modes.first_person
        pcall(handler._update_follow, handler, true)
        pcall(handler._update_player_mood, handler, true, shell)

        local wwise_sync = Managers.wwise_game_sync

        if wwise_sync and wwise_sync.set_followed_player_unit then
            pcall(wwise_sync.set_followed_player_unit, wwise_sync, shell)
        end
    end

    handler._first_person_spectating_mode = role.camera_previous_first_person_spectating_mode ~= false
    role.camera_restoring = nil
    role.camera_handler = nil
    role.camera_previous_follow_unit = nil
    role.camera_previous_mode = nil
    role.camera_previous_first_person_spectating_mode = nil
    role.camera_isolation_logged = nil
    role.camera_moods_cleared = nil
    role.camera_empty_mood_blend = nil
    role.streaming_anchor_unit = nil
    role.streaming_anchor_name = nil
    role.streaming_anchor_distance = nil
    role.streaming_anchor_last_position = nil
    role.streaming_anchor_refresh_at = nil
    role.streaming_refresh_forced = nil
    role.streaming_transition_pending = nil
    role.streaming_transition_reason = nil
    role.camera_diagnostic_at = nil
    role.camera_diagnostic_force = nil
end

function VersusModeState.camera_freeflight_updates_manager()
    local camera_mod = get_mod("camera_freeflight")

    if not camera_mod then
        return false
    end

    if type(camera_mod.is_enabled) ~= "function" then
        return true
    end

    local checked, enabled = pcall(camera_mod.is_enabled, camera_mod)

    return not checked or enabled ~= false
end

function VersusModeState.update_wait_camera_input(dt)
    if mod._control or not VersusModeState.local_active() or VersusModeState.camera_freeflight_updates_manager() then
        return false
    end

    local free_flight = VersusModeState.ensure_free_flight_manager()

    if not free_flight or not free_flight:is_in_free_flight() then
        return false
    end

    local t = gameplay_time()
    local time_manager = Managers.time

    if time_manager and type(time_manager.time) == "function" then
        local read, main_t = pcall(time_manager.time, time_manager, "main")

        if read and type(main_t) == "number" then
            t = main_t
        end
    end

    local updated, failure = pcall(free_flight.update, free_flight, dt, t)

    if not updated then
        if not mod._free_flight_update_warning then
            mod._free_flight_update_warning = true
            mod:warning("Versus Mode: native waiting-camera update failed: %s", tostring(failure))
        end

        return false
    end

    mod._free_flight_update_warning = nil

    return true
end

function VersusModeState.enter_wait_camera(role)
    local free_flight = VersusModeState.ensure_free_flight_manager()

    if mod._death_camera or not role or not VersusModeState.local_active() or not free_flight then
        return false
    end

    VersusModeState.isolate_observer_camera(role, nil, "waiting")

    mod._suppress_freeflight_toggle_frames = 3

    if free_flight:is_in_free_flight() then
        if role.wait_camera_owned == nil then
            role.wait_camera_owned = false
        end

        role.wait_camera_active = true
        VersusModeState.seed_wait_camera(role, free_flight)
        VersusModeState.force_possession_camera_player_body()

        return true
    end

    local camera_data = free_flight._free_flight_cameras and free_flight._free_flight_cameras.global

    if not camera_data then
        return false
    end

    local entered = pcall(free_flight._enter_global_free_flight, free_flight, camera_data)

    if entered and free_flight:is_in_free_flight() then
        role.wait_camera_owned = true
        role.wait_camera_active = true
        VersusModeState.seed_wait_camera(role, free_flight)
        VersusModeState.force_possession_camera_player_body()

        return true
    end

    role.wait_camera_active = nil
    VersusModeState.refresh_possession_camera_player_body()

    return false
end

function VersusModeState.maintain_wait_camera(role)
    if mod._control or mod._death_camera or not VersusModeState.local_active() then
        return false
    end

    role = role or mod._versus_role_test
    VersusModeState.isolate_observer_camera(role, nil, "waiting update")

    return VersusModeState.enter_wait_camera(role)
end

function VersusModeState.leave_wait_camera(role)
    local free_flight = Managers.free_flight

    if not role then
        return
    end

    local owned = role.wait_camera_owned == true

    role.wait_camera_active = nil
    role.wait_camera_owned = nil
    role.wait_camera_seeded = nil

    if owned and free_flight and free_flight:is_in_free_flight() then
        local camera_data = free_flight._free_flight_cameras and free_flight._free_flight_cameras.global

        if camera_data then
            mod._suppress_freeflight_toggle_frames = 3
            pcall(free_flight._exit_global_free_flight, free_flight, camera_data)
        end
    end

    VersusModeState.refresh_possession_camera_player_body()
end

-- A lobby roster can assign the local Heretic while StateGameplay is still
-- completing its camera hand-off. The native free-flight manager may then
-- report an active global camera even though the gameplay viewport remains
-- attached to the Operative shell. A manual restore/reassign fixed that by
-- destroying and recreating the waiting viewport. Do the same automatically
-- before possession so enter_camera never inherits that stale early viewport.
function VersusModeState.recycle_wait_camera_for_possession(role)
    if not role or role.wait_camera_active ~= true or role.wait_camera_owned ~= true then
        return false
    end

    VersusModeState.leave_wait_camera(role)
    mod:info("Versus Mode: refreshed the lobby-created Deployment View before possession.")

    return true
end

function VersusModeState.schedule_respawn(role)
    role = role or mod._versus_role_test

    if not role
        or not is_server()
        or not role.infected_human and not VersusModeState.bot_reinforcement_enabled(role) then
        return false
    end

    local choices = {}

    for i = 1, #VersusModeState.respawn_breeds do
        local entry = VersusModeState.respawn_breeds[i]

        if VersusModeState.breeds[entry.name] and entry.name ~= role.last_respawn_breed then
            choices[#choices + 1] = entry
        end
    end

    if #choices == 0 then
        for i = 1, #VersusModeState.respawn_breeds do
            local entry = VersusModeState.respawn_breeds[i]

            if VersusModeState.breeds[entry.name] then
                choices[#choices + 1] = entry
            end
        end
    end

    if #choices == 0 then
        return false
    end

    local selected = choices[math.random(1, #choices)]
    local delay = math_max(0, setting("infected_respawn_delay"))

    role.respawn_breed = selected.name
    role.respawn_variant = nil
    role.last_respawn_breed = selected.name
    role.respawn_ready_at = gameplay_time() + delay
    role.respawn_ready_notified = false
    role.spawn_check_at = nil
    role.spawn_check = nil
    role.automatic_respawn_retry_at = nil
    role.automatic_respawn_notice_at = nil
    role.automatic_respawn_reason = nil
    role.automatic_respawn_not_before = nil

    if VersusModeState.local_role() == role then
        VersusModeState.echo_localized(
            "notice_next_infected_spawn",
            VersusModeState.respawn_label(selected.name, selected.variant_id),
            delay
        )
    elseif role.infected_human and role.infected_peer_id then
        VersusModeState.send_remote_respawn_notice(
            role.infected_peer_id,
            "notice_next_infected_spawn",
            role,
            delay
        )
    end

    VersusModeState.publish_roster()

    return true
end

function VersusModeState.physics_world()
    local world_manager = Managers.world

    if not world_manager or not world_manager:has_world("level_world") then
        return nil
    end

    local world = world_manager:world("level_world")
    local ok, physics_world = pcall(World.physics_world, world)

    return ok and physics_world or nil
end

function VersusModeState.death_camera_ground_position(state, camera_position)
    local physics_world = state and state.physics_world or VersusModeState.physics_world()
    local up = vector3_up()

    if physics_world and camera_position then
        local ray_ok, hit, hit_position = pcall(
            PhysicsWorld.raycast,
            physics_world,
            camera_position + up * 0.1,
            up * -1,
            VersusModeState.death_camera_max_drop + 0.1,
            "closest",
            "types",
            "statics",
            "collision_filter",
            "filter_camera_sweep"
        )

        if ray_ok and hit and hit_position then
            return Vector3(
                Vector3.x(hit_position),
                Vector3.y(hit_position),
                math_min(
                    Vector3.z(camera_position),
                    Vector3.z(hit_position) + VersusModeState.death_camera_ground_height
                )
            ), true
        end
    end

    local unit_position = state and live_world_position(state.unit)
    local fallback_z = unit_position
        and math_min(
            Vector3.z(camera_position),
            Vector3.z(unit_position) + VersusModeState.death_camera_ground_height
        )
        or Vector3.z(camera_position) - math_min(VersusModeState.death_camera_max_drop, 1)
    local fallback_position = Vector3(
        Vector3.x(camera_position),
        Vector3.y(camera_position),
        fallback_z
    )
    local manager = Managers.state and Managers.state.camera
    local collision_ok, collision_position = safe_extension_call(
        manager,
        "_smooth_camera_collision",
        fallback_position,
        camera_position,
        0.2,
        0.1
    )

    return collision_ok and collision_position or fallback_position, false
end

function VersusModeState.finish_death_camera(enter_wait_camera)
    local death_camera = mod._death_camera

    if not death_camera then
        return false
    end

    mod._death_camera = nil
    mod._suppress_freeflight_toggle_frames = 3

    if death_camera.role then
        death_camera.role.death_camera_active = nil
    end

    if enter_wait_camera
        and death_camera.role
        and VersusModeState.local_active()
        and not mod._control then
        VersusModeState.begin_survivor_spectating(death_camera.role)
    end

    VersusModeState.refresh_possession_camera_player_body()

    return true
end

function VersusModeState.start_death_camera(state, role)
    local free_flight = Managers.free_flight

    if not state
        or not role
        or not VersusModeState.local_active()
        or not free_flight
        or not free_flight:is_in_free_flight() then
        return false
    end

    if mod._death_camera then
        VersusModeState.finish_death_camera(false)
    end

    VersusModeState.finish_survivor_spectating(role)

    local pose_ok, camera_position, camera_rotation = pcall(
        free_flight.camera_position_rotation,
        free_flight,
        "global"
    )

    if not pose_ok or not camera_position or not camera_rotation then
        return false
    end

    local ground_position, floor_found = VersusModeState.death_camera_ground_position(state, camera_position)
    local boxed_ok, start_box, ground_box, rotation_box = pcall(function()
        return Vector3Box(camera_position), Vector3Box(ground_position), QuaternionBox(camera_rotation)
    end)

    if not boxed_ok then
        return false
    end

    local t = gameplay_time()

    mod._death_camera = {
        role = role,
        start_position = start_box,
        ground_position = ground_box,
        rotation = rotation_box,
        started_at = t,
        drop_ends_at = t + VersusModeState.death_camera_drop_duration,
        ends_at = t + VersusModeState.death_camera_drop_duration + VersusModeState.death_camera_hold_duration,
        greyscale_amount = 0,
    }
    role.death_camera_active = true
    mod._suppress_freeflight_toggle_frames = 3
    local teleported = pcall(
        free_flight.teleport_camera,
        free_flight,
        "global",
        camera_position,
        camera_rotation
    )

    if not teleported then
        VersusModeState.finish_death_camera(false)

        return false
    end

    mod:info(
        "Versus Mode: infected death camera started (%s floor; %.2f s drop, %.2f s hold).",
        floor_found and "collision" or "fallback",
        VersusModeState.death_camera_drop_duration,
        VersusModeState.death_camera_hold_duration
    )

    return true
end

function VersusModeState.update_death_camera(dt)
    local death_camera = mod._death_camera

    if not death_camera then
        return false
    end

    if mod._control
        or not VersusModeState.local_active()
        or mod._versus_role_test ~= death_camera.role then
        VersusModeState.finish_death_camera(false)

        return false
    end

    local t = gameplay_time()

    if t >= death_camera.ends_at then
        VersusModeState.finish_death_camera(true)

        return false
    end

    local free_flight = Managers.free_flight

    if not free_flight or not free_flight:is_in_free_flight() then
        VersusModeState.finish_death_camera(true)

        return false
    end

    local unboxed, start_position, ground_position, camera_rotation = pcall(function()
        return death_camera.start_position:unbox(),
            death_camera.ground_position:unbox(),
            death_camera.rotation:unbox()
    end)

    if not unboxed then
        VersusModeState.finish_death_camera(true)

        return false
    end

    local drop_progress = math_min(
        1,
        math_max(0, (t - death_camera.started_at) / VersusModeState.death_camera_drop_duration)
    )
    local eased_progress = drop_progress * drop_progress * (3 - 2 * drop_progress)
    local camera_position = start_position + (ground_position - start_position) * eased_progress

    death_camera.greyscale_amount = math_min(
        1,
        math_max(0, (t - death_camera.started_at) / VersusModeState.death_camera_greyscale_fade)
    )

    local teleported = pcall(
        free_flight.teleport_camera,
        free_flight,
        "global",
        camera_position,
        camera_rotation
    )

    if not teleported then
        VersusModeState.finish_death_camera(true)

        return false
    end

    return true
end

function VersusModeState.survivor_view(player, unit)
    local position
    local rotation
    local unit_data_extension = safe_extension(unit, "unit_data_system")

    if unit_data_extension then
        pcall(function()
            local first_person_component = unit_data_extension:read_component("first_person")

            position = first_person_component.position
            rotation = first_person_component.rotation
        end)
    end

    if not position then
        position = node_world_position(unit, "j_head")
        local unit_position = not position and live_world_position(unit)

        position = position or unit_position and (unit_position + vector3_up() * 1.5) or Vector3.zero()
    end

    if not rotation then
        local rotation_ok, unit_rotation = pcall(Unit.world_rotation, unit, 1)

        rotation = rotation_ok and unit_rotation or Quaternion.identity()
    end

    return position, rotation
end

-- A lobby-assigned Heretic can enter Deployment View before the stricter
-- survivor-spectator filter exposes an Operative. Seed the newly created
-- free-flight viewport from the native streaming anchor so it never renders
-- the manager's default origin while normal spectating finishes initializing.
function VersusModeState.seed_wait_camera(role, free_flight)
    if not role or role.wait_camera_seeded then
        return role and role.wait_camera_seeded == true or false
    end

    free_flight = free_flight or Managers.free_flight

    if not free_flight or not free_flight:is_in_free_flight() then
        return false
    end

    local target = role.streaming_anchor_unit

    if not valid_player_target(target) then
        target = VersusModeState.refresh_streaming_anchor(
            role,
            live_world_position(role.infected_unit),
            true
        )
    end

    if not target or not ALIVE[target] then
        target = role.infected_unit
    end

    if not target or not ALIVE[target] then
        return false
    end

    local player_manager = Managers.player
    local player = player_manager and player_manager.player_by_unit
        and player_manager:player_by_unit(target)
        or nil
    local focus, view_rotation = VersusModeState.survivor_view(player, target)
    local view_forward = Quaternion.forward(view_rotation)
    local flat_forward = Vector3.flat(view_forward)

    if vector3_length(flat_forward) <= 0.01 then
        local rotation_ok, target_rotation = pcall(Unit.world_rotation, target, 1)

        flat_forward = rotation_ok and Vector3.flat(Quaternion.forward(target_rotation)) or Vector3(0, 1, 0)
    end

    flat_forward = vector3_normalize(flat_forward)

    local wanted = focus - flat_forward * VersusModeState.spectator_camera_distance
        + vector3_up() * VersusModeState.spectator_camera_height
    local camera_manager = Managers.state and Managers.state.camera
    local collision_ok, collision_position = safe_extension_call(
        camera_manager,
        "_smooth_camera_collision",
        wanted,
        focus,
        0.2,
        0.1
    )
    local camera_position = collision_ok and collision_position or wanted
    local look_target = focus + view_forward * VersusModeState.spectator_camera_focus_distance
    local look_offset = look_target - camera_position

    if vector3_length(look_offset) <= 0.01 then
        look_offset = view_forward
    end

    local camera_rotation = Quaternion.look(vector3_normalize(look_offset), vector3_up())
    local teleported = pcall(
        free_flight.teleport_camera,
        free_flight,
        "global",
        camera_position,
        camera_rotation
    )

    if teleported then
        role.wait_camera_seeded = true
        mod:info(
            "Versus Mode: initialized Heretic Deployment View from the %s camera anchor.",
            target == role.infected_unit and "shell" or "Operative"
        )
    end

    return teleported
end

local mouse_look_ui_gate

function VersusModeState.spectator_target_valid(unit)
    return valid_player_target(unit)
        and not VersusModeState.player_is_hidden_from_infected(unit)
        or false
end

function VersusModeState.survivor_spectator_candidates()
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local candidates = {}

    for unique_id, player in pairs(players or {}) do
        local unit = player and player.player_unit

        if VersusModeState.spectator_target_valid(unit) then
            candidates[#candidates + 1] = {
                name = VersusModeState.player_name(player),
                player = player,
                token = tostring(unique_id),
                unit = unit,
            }
        end
    end

    table.sort(candidates, function(a, b)
        if a.name == b.name then
            return a.token < b.token
        end

        return a.name < b.name
    end)

    return candidates
end

function VersusModeState.select_survivor_spectator(role, cycle)
    if not role then
        return nil
    end

    local candidates = VersusModeState.survivor_spectator_candidates()
    local selected

    if #candidates > 0 then
        local current_index

        for i = 1, #candidates do
            if candidates[i].unit == role.spectator_target_unit
                or role.spectator_target_token and candidates[i].token == role.spectator_target_token then
                current_index = i

                break
            end
        end

        if cycle and current_index then
            selected = candidates[current_index % #candidates + 1]
        else
            selected = current_index and candidates[current_index] or candidates[1]
        end
    end

    local old_unit = role.spectator_target_unit

    role.spectator_target_unit = selected and selected.unit or nil
    role.spectator_target_player = selected and selected.player or nil
    role.spectator_target_token = selected and selected.token or nil
    role.spectator_target_name = selected and selected.name or nil

    if role.spectator_target_unit ~= old_unit then
        mod:info(
            "Versus Mode: infected spectator target changed to %s.",
            tostring(role.spectator_target_name or "free-flight fallback")
        )
    end

    return role.spectator_target_unit
end

function VersusModeState.finish_survivor_spectating(role)
    role = role or mod._versus_role_test

    if not role then
        return false
    end

    local was_active = role.spectator_active == true

    role.spectator_active = nil
    role.spectator_target_unit = nil
    role.spectator_target_player = nil
    role.spectator_target_token = nil
    role.spectator_target_name = nil
    role.spectator_retarget_at = nil
    role.spectator_cycle_at = nil
    role.spectator_input_block_until = nil

    return was_active
end

function VersusModeState.begin_survivor_spectating(role)
    role = role or mod._versus_role_test
    local manual_placement_ready = role
        and role.respawn_breed
        and not VersusModeState.random_safe_spawn_enabled()
        and gameplay_time() >= (role.respawn_ready_at or math.huge)

    if not role
        or mod._control
        or mod._death_camera
        or manual_placement_ready
        or VersusModeState.local_role() ~= role
        or not VersusModeState.local_active()
        or not VersusModeState.maintain_wait_camera(role) then
        return false
    end

    role.spectator_active = true
    role.spectator_retarget_at = 0
    VersusModeState.select_survivor_spectator(role, false)

    return true
end

function VersusModeState.update_survivor_spectating(dt)
    local role = VersusModeState.local_role()
    local manual_placement_ready = role
        and role.respawn_breed
        and not VersusModeState.random_safe_spawn_enabled()
        and gameplay_time() >= (role.respawn_ready_at or math.huge)

    if not role
        or not VersusModeState.local_active()
        or mod._control
        or mod._death_camera
        or manual_placement_ready then
        VersusModeState.finish_survivor_spectating(role)

        return false
    end

    if not role.spectator_active and not VersusModeState.begin_survivor_spectating(role) then
        return false
    end

    if not VersusModeState.maintain_wait_camera(role) then
        return false
    end

    local free_flight = Managers.free_flight

    if not free_flight or not free_flight:is_in_free_flight() then
        return false
    end

    local t = gameplay_time()
    local target = role.spectator_target_unit

    if not VersusModeState.spectator_target_valid(target)
        and t >= (role.spectator_retarget_at or 0) then
        role.spectator_retarget_at = t + VersusModeState.spectator_retarget_interval
        target = VersusModeState.select_survivor_spectator(role, false)
    end

    local input_gated = mouse_look_ui_gate()

    if input_gated then
        role.spectator_input_block_until = t + UI_INPUT_RELEASE_GRACE
    elseif t >= (role.spectator_input_block_until or 0)
        and t >= (role.spectator_cycle_at or 0) then
        local input_service = VersusModeState.ingame_input_service()

        if VersusModeState.native_input_action(input_service, "spectate_next") then
            role.spectator_cycle_at = t + 0.15
            target = VersusModeState.select_survivor_spectator(role, true)
        end
    end

    if not VersusModeState.spectator_target_valid(target) then
        return false
    end

    local view_position, view_rotation = VersusModeState.survivor_view(role.spectator_target_player, target)
    local view_forward = Quaternion.forward(view_rotation)
    local flat_forward = Vector3.flat(view_forward)

    if vector3_length(flat_forward) <= 0.01 then
        local rotation_ok, target_rotation = pcall(Unit.world_rotation, target, 1)

        flat_forward = rotation_ok and Vector3.flat(Quaternion.forward(target_rotation)) or Vector3(0, 1, 0)
    end

    flat_forward = vector3_normalize(flat_forward)

    local focus = view_position
    local wanted = focus - flat_forward * VersusModeState.spectator_camera_distance
        + vector3_up() * VersusModeState.spectator_camera_height
    local camera_manager = Managers.state and Managers.state.camera
    local collision_ok, collision_position = safe_extension_call(
        camera_manager,
        "_smooth_camera_collision",
        wanted,
        focus,
        0.2,
        0.1
    )
    local camera_position = collision_ok and collision_position or wanted
    local look_target = focus + view_forward * VersusModeState.spectator_camera_focus_distance
    local look_offset = look_target - camera_position

    if vector3_length(look_offset) <= 0.01 then
        look_offset = view_forward
    end

    local camera_rotation = Quaternion.look(vector3_normalize(look_offset), vector3_up())
    local teleported = pcall(
        free_flight.teleport_camera,
        free_flight,
        "global",
        camera_position,
        camera_rotation
    )

    if not teleported then
        VersusModeState.finish_survivor_spectating(role)

        return false
    end

    return true
end

function VersusModeState.spawn_headroom(breed_name)
    local breed = breed_name and VersusModeState.breeds[breed_name]
    local base_height = breed and type(breed.base_height) == "number" and breed.base_height or 0

    -- The legacy 2.6 m ray remains the floor for specialists. Taller infected
    -- use their actual breed height plus a small animation/mover margin.
    return math_max(2.6, base_height + 0.25)
end

function VersusModeState.spawn_visibility_heights(breed_name)
    local heights = { 1.25 }

    if VersusModeState.controlled_elite_breeds[breed_name] then
        local breed = VersusModeState.breeds[breed_name]
        local base_height = breed and type(breed.base_height) == "number" and breed.base_height or 2.5

        -- Body visibility alone is insufficient for Ogryn-sized infected: a
        -- low wall can hide the torso while leaving the head plainly exposed.
        heights[2] = math_min(2.65, math_max(1.5, base_height - 0.25))
    end

    return heights
end

function VersusModeState.visible_to_survivor(spawn_position, physics_world, breed_name)
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local target_heights = VersusModeState.spawn_visibility_heights(breed_name)

    if not players then
        return nil
    end

    for unique_id, player in pairs(players) do
        local unit = player and player.player_unit

        if unit and ALIVE[unit] and HEALTH_ALIVE[unit] and not VersusModeState.is_unit(unit)
            and not VersusModeState.player_is_hogtied(unit) then
            local eye_position, eye_rotation = VersusModeState.survivor_view(player, unit)
            local forward = Quaternion.forward(eye_rotation)

            for i = 1, #target_heights do
                local target_position = spawn_position + vector3_up() * target_heights[i]
                local offset = target_position - eye_position
                local distance = vector3_length(offset)

                if distance < 0.1 then
                    return VersusModeState.player_name(player)
                end

                local direction = offset / distance

                if vector3_dot(forward, direction) >= VersusModeState.survivor_view_dot then
                    local ray_ok, hit = pcall(
                        PhysicsWorld.raycast,
                        physics_world,
                        eye_position,
                        direction,
                        distance,
                        "any",
                        "types",
                        "both",
                        "collision_filter",
                        "filter_minion_line_of_sight_check"
                    )

                    if not ray_ok or not hit then
                        return VersusModeState.player_name(player)
                    end
                end
            end
        end
    end

    return nil
end

function VersusModeState.nearest_survivor(spawn_position)
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local nearest_name
    local nearest_distance = math.huge

    if not players then
        return nil, nearest_distance
    end

    for unique_id, player in pairs(players) do
        local unit = player and player.player_unit

        if unit
            and ALIVE[unit]
            and HEALTH_ALIVE[unit]
            and not VersusModeState.is_unit(unit)
            and not VersusModeState.player_is_hogtied(unit) then
            local position = live_world_position(unit)

            if position then
                local distance = vector3_distance(spawn_position, position)

                if distance < nearest_distance then
                    nearest_distance = distance
                    nearest_name = VersusModeState.player_name(player)
                end
            end
        end
    end

    return nearest_name, nearest_distance
end

function VersusModeState.random_spawn_survivors()
    local positions = {}
    local anchor_position
    local anchor_unit
    local best_travel_distance = -math.huge
    local player_manager = Managers.player
    local players = player_manager and player_manager.players and player_manager:players()
    local main_path = Managers.state and Managers.state.main_path

    if not players then
        return positions, nil
    end

    for _, player in pairs(players) do
        local unit = player and player.player_unit

        if unit
            and ALIVE[unit]
            and HEALTH_ALIVE[unit]
            and not VersusModeState.is_unit(unit)
            and not VersusModeState.player_is_hogtied(unit) then
            local position = live_world_position(unit)

            if position then
                positions[#positions + 1] = position
                anchor_position = anchor_position or position
                anchor_unit = anchor_unit or unit

                if main_path and type(main_path.travel_distance_from_position) == "function" then
                    local ok, travel_distance = pcall(main_path.travel_distance_from_position, main_path, position, true)

                    if ok and type(travel_distance) == "number" and travel_distance > best_travel_distance then
                        best_travel_distance = travel_distance
                        anchor_position = position
                        anchor_unit = unit
                    end
                end
            end
        end
    end

    return positions, anchor_position, anchor_unit
end

function VersusModeState.random_spawn_disallowed(role)
    local positions = {}
    local reservations = mod._random_spawn_reservations or {}
    local t = gameplay_time()

    mod._random_spawn_reservations = reservations
    reservations[role] = nil

    for reservation_role, reservation in pairs(reservations) do
        if reservation and reservation.position and t < (reservation.expires_at or 0) then
            positions[#positions + 1] = reservation.position
        else
            reservations[reservation_role] = nil
        end
    end

    local local_state = mod._control

    if local_state and local_state.possessed and ALIVE[local_state.unit] then
        local position = live_world_position(local_state.unit)

        if position then
            positions[#positions + 1] = Vector3Box(position)
        end
    end

    for _, state in pairs(mod._remote_controls or {}) do
        if state and state ~= local_state and state.possessed and ALIVE[state.unit] then
            local position = live_world_position(state.unit)

            if position then
                positions[#positions + 1] = Vector3Box(position)
            end
        end
    end

    return positions
end

function VersusModeState.random_spawn_spacing_ok(spawn_position, disallowed_positions)
    for i = 1, #(disallowed_positions or {}) do
        local boxed = disallowed_positions[i]
        local position = boxed and boxed:unbox()

        if position and vector3_distance(spawn_position, position) < VersusModeState.random_spawn_spacing then
            return false
        end
    end

    return true
end

function VersusModeState.random_spawn_history_rank(spawn_position)
    local history = mod._random_spawn_history or {}
    local recent_rank
    local nearest_history_distance = math.huge

    for i = 1, #history do
        local entry = history[i]
        local position = entry and entry.position and entry.position:unbox()

        if position then
            local distance = vector3_distance(spawn_position, position)

            nearest_history_distance = math_min(nearest_history_distance, distance)

            if distance < VersusModeState.random_spawn_history_distance then
                recent_rank = i
            end
        end
    end

    return recent_rank, nearest_history_distance
end

function VersusModeState.remember_random_spawn(spawn_position)
    local history = mod._random_spawn_history or {}

    mod._random_spawn_history = history
    history[#history + 1] = {
        position = Vector3Box(spawn_position),
        used_at = gameplay_time(),
    }

    while #history > VersusModeState.random_spawn_history_size do
        table.remove(history, 1)
    end
end

function VersusModeState.random_spawn_duplicate(spawn_position, seen_positions)
    for i = 1, #seen_positions do
        local position = seen_positions[i]:unbox()

        if vector3_distance(spawn_position, position) < VersusModeState.random_spawn_duplicate_distance then
            return true
        end
    end

    seen_positions[#seen_positions + 1] = Vector3Box(spawn_position)

    return false
end

-- Some missions (notably Mercantile HL-70-04) expose a valid main path and
-- navmesh but return no authored occluded spawn-point candidates. Build a
-- bounded host-side fallback from projected main-path and survivor-ring
-- samples; the normal headroom, survivor distance, visibility, separation and
-- history validation below still decides whether any sample is actually safe.
function VersusModeState.random_spawn_navmesh_candidates(nav_world, main_path, anchor_position, minimum_distance, maximum_distance)
    local positions = {}

    if not nav_world or not anchor_position then
        return positions, 0
    end

    local candidate_limit = VersusModeState.random_spawn_fallback_candidate_limit or 96
    local function add_projected(sample_position)
        if not sample_position or #positions >= candidate_limit then
            return
        end

        local position_ok, nav_position = pcall(
            VersusModeState.nav_queries.position_on_mesh_guaranteed,
            nav_world,
            sample_position,
            5,
            10
        )

        if position_ok and nav_position then
            positions[#positions + 1] = nav_position
        end
    end

    local base_positions = {}
    local travel_distance

    if main_path and type(main_path.ahead_unit) == "function" then
        local ahead_ok, _, ahead_travel_distance, path_position = pcall(
            main_path.ahead_unit,
            main_path,
            1
        )

        if ahead_ok then
            travel_distance = type(ahead_travel_distance) == "number" and ahead_travel_distance or nil

            if path_position then
                base_positions[#base_positions + 1] = path_position
            end
        end
    end

    if travel_distance
        and VersusModeState.main_path_queries
        and type(VersusModeState.main_path_queries.position_from_distance) == "function" then
        local path_offset = math_max(minimum_distance + 5, 10)

        while path_offset <= maximum_distance and #base_positions < 10 do
            for direction_index = 1, 2 do
                local direction = direction_index == 1 and -1 or 1
                local query_distance = math_max(0, travel_distance + path_offset * direction)
                local query_ok, path_position = pcall(
                    VersusModeState.main_path_queries.position_from_distance,
                    query_distance
                )

                if query_ok and path_position then
                    base_positions[#base_positions + 1] = path_position
                end
            end

            path_offset = path_offset + 12
        end
    end

    -- Main-path samples favor connected playable space; small cardinal offsets
    -- can reach an adjacent room or piece of cover without guessing a remote
    -- floor on top of or below the squad.
    for i = 1, #base_positions do
        local base_position = base_positions[i]

        add_projected(base_position)

        for angle_index = 0, 3 do
            local angle = angle_index * math.pi * 0.5
            local offset = Vector3(math_cos(angle) * 6, math_sin(angle) * 6, 0)

            add_projected(base_position + offset)
        end
    end

    -- If the authored main path is absent, truncated or currently between
    -- segments, concentric samples around the foremost survivor still give the
    -- map's navmesh a chance to provide a hidden legal position.
    local radius = math_max(minimum_distance + 4, 8)

    while radius < maximum_distance and #positions < candidate_limit do
        for angle_index = 0, 7 do
            local angle = angle_index * math.pi * 0.25
            local offset = Vector3(math_cos(angle) * radius, math_sin(angle) * radius, 0)

            add_projected(anchor_position + offset)
        end

        radius = radius + 10
    end

    return positions, #positions
end

function VersusModeState.validate_random_spawn_candidate(spawn_position, physics_world, minimum_distance, maximum_distance, disallowed_positions, breed_name)
    if not spawn_position or not physics_world then
        return false, "missing position or collision world"
    end

    if not VersusModeState.random_spawn_spacing_ok(spawn_position, disallowed_positions) then
        return false, "too close to another controlled infected"
    end

    local headroom_ok, blocked_overhead = pcall(
        PhysicsWorld.raycast,
        physics_world,
        spawn_position + vector3_up() * 0.15,
        vector3_up(),
        VersusModeState.spawn_headroom(breed_name),
        "any",
        "types",
        "both",
        "collision_filter",
        "filter_minion_mover"
    )

    if not headroom_ok or blocked_overhead then
        return false, "not enough headroom"
    end

    local nearest_name, nearest_distance = VersusModeState.nearest_survivor(spawn_position)

    if not nearest_name then
        return false, "no living survivor anchor"
    end

    if nearest_distance < minimum_distance then
        return false, string.format("%.1f m from %s is below the %.1f m minimum", nearest_distance, nearest_name, minimum_distance)
    end

    if nearest_distance > maximum_distance then
        return false, string.format("%.1f m from survivors exceeds the %.1f m maximum", nearest_distance, maximum_distance)
    end

    local visible_name = VersusModeState.visible_to_survivor(spawn_position, physics_world, breed_name)

    if visible_name then
        return false, "visible to " .. visible_name
    end

    return true
end

function VersusModeState.random_safe_spawn(role)
    if not is_server() or not role then
        return false, "Random Safe selection requires the host"
    end

    local nav_manager = Managers.state and Managers.state.nav_mesh
    local nav_world = nav_manager and nav_manager:nav_world()
    local main_path = Managers.state and Managers.state.main_path
    local nav_spawn_points = main_path and main_path.nav_spawn_points and main_path:nav_spawn_points()
    local physics_world = VersusModeState.physics_world()
    local survivor_positions, anchor_position = VersusModeState.random_spawn_survivors()

    if not nav_world or not physics_world or not anchor_position or #survivor_positions == 0 then
        return false, "navmesh, collision or survivor spawn data is unavailable"
    end

    local minimum_distance = math_max(0, setting("infected_min_spawn_distance"))
    local maximum_distance = math_max(VersusModeState.random_spawn_max_distance, minimum_distance + 5)
    local fallback_maximum_distance = math_max(VersusModeState.random_spawn_fallback_max_distance, minimum_distance + 5)
    local disallowed_positions = VersusModeState.random_spawn_disallowed(role)
    local positions = {}
    local num_positions = 0
    local candidate_source = "native"
    local query_diagnostic = "spawn groups unavailable"
    local count_ok, num_groups

    if nav_spawn_points then
        count_ok, num_groups = pcall(GwNavSpawnPoints.get_count, nav_spawn_points)
    end

    if count_ok and type(num_groups) == "number" and num_groups > 0 then
        local query_ok, query_positions, query_count = pcall(
            VersusModeState.spawn_point_queries.get_occluded_positions,
            nav_world,
            nav_spawn_points,
            anchor_position,
            survivor_positions,
            fallback_maximum_distance,
            num_groups,
            minimum_distance,
            nil,
            VersusModeState.random_spawn_group_range,
            false,
            disallowed_positions
        )

        query_diagnostic = query_ok and "empty" or tostring(query_positions)

        if query_ok and type(query_positions) == "table" and type(query_count) == "number" then
            positions = query_positions
            num_positions = math_min(query_count, #query_positions)
        end
    end

    if num_positions < 1 then
        candidate_source = "navmesh fallback"
        positions, num_positions = VersusModeState.random_spawn_navmesh_candidates(
            nav_world,
            main_path,
            anchor_position,
            minimum_distance,
            fallback_maximum_distance
        )
        mod:info(
            "Versus Mode: Random Safe native query returned no candidates (%s); navmesh fallback generated %d.",
            tostring(query_diagnostic),
            num_positions
        )

        if num_positions < 1 then
            return false, "no native or fallback navmesh spawn candidate was found at least "
                .. string.format("%.0f metres from every survivor", minimum_distance)
        end
    end

    for i = num_positions, 2, -1 do
        local swap_index = math.random(1, i)

        positions[i], positions[swap_index] = positions[swap_index], positions[i]
    end

    local last_reason = "all candidates failed final safety validation"
    local seen_positions = {}
    local checked_count = 0
    local duplicate_count = 0
    local valid_count = 0
    local fresh_count = 0
    local recent_count = 0
    local selected
    local fallback_fresh
    local standard_reused
    local fallback_reused

    for index = 1, num_positions do
        local position = positions[index]

        if VersusModeState.random_spawn_duplicate(position, seen_positions) then
            duplicate_count = duplicate_count + 1
        else
            checked_count = checked_count + 1
            local valid, reason = VersusModeState.validate_random_spawn_candidate(
                position,
                physics_world,
                minimum_distance,
                fallback_maximum_distance,
                disallowed_positions,
                role.respawn_breed
            )

            if valid then
                local _, nearest_distance = VersusModeState.nearest_survivor(position)
                local history_rank, history_distance = VersusModeState.random_spawn_history_rank(position)
                local candidate = {
                    history_distance = history_distance,
                    history_rank = history_rank,
                    index = index,
                    nearest_distance = nearest_distance,
                    position = position,
                }
                local standard_range = nearest_distance <= maximum_distance

                valid_count = valid_count + 1

                if not history_rank then
                    fresh_count = fresh_count + 1

                    if standard_range then
                        selected = candidate

                        break
                    end

                    fallback_fresh = fallback_fresh or candidate
                else
                    recent_count = recent_count + 1
                    local reused = standard_range and standard_reused or fallback_reused

                    if not reused
                        or history_rank < reused.history_rank
                        or history_rank == reused.history_rank and history_distance > reused.history_distance then
                        if standard_range then
                            standard_reused = candidate
                        else
                            fallback_reused = candidate
                        end
                    end
                end
            else
                last_reason = reason or last_reason
            end
        end
    end

    selected = selected or fallback_fresh or standard_reused or fallback_reused

    if selected then
        local position = selected.position
        local flat_forward = Vector3.flat(anchor_position - position)

        if vector3_length(flat_forward) < 0.01 then
            flat_forward = Vector3(0, 1, 0)
        else
            flat_forward = vector3_normalize(flat_forward)
        end

        local spawn_position = position + vector3_up() * 0.05
        local spawn_rotation = Quaternion.look(flat_forward, vector3_up())
        local reused = selected.history_rank ~= nil
        local expanded = selected.nearest_distance > maximum_distance
        local selection_tier = reused and (expanded and "expanded-reused" or "standard-reused")
            or expanded and "expanded-fresh"
            or "standard-fresh"
        local selected_maximum = expanded and fallback_maximum_distance or maximum_distance

        mod._random_spawn_reservations[role] = {
            expires_at = gameplay_time() + VersusModeState.random_spawn_reservation_duration,
            position = Vector3Box(spawn_position),
        }
        VersusModeState.remember_random_spawn(spawn_position)
        mod:info(
            "Versus Mode: Random Safe %s scan raw=%d checked=%d valid=%d fresh=%d recent=%d duplicates=%d; selected %s candidate %d at %.1f m.",
            candidate_source,
            num_positions,
            checked_count,
            valid_count,
            fresh_count,
            recent_count,
            duplicate_count,
            selection_tier,
            selected.index,
            selected.nearest_distance
        )

        return true,
            string.format("Random Safe: hidden, %.0f–%.0f m from nearest survivor", minimum_distance, selected_maximum),
            spawn_position,
            spawn_rotation
    end

    mod:info(
        "Versus Mode: Random Safe %s scan raw=%d checked=%d valid=%d fresh=%d recent=%d duplicates=%d; no selection (%s).",
        candidate_source,
        num_positions,
        checked_count,
        valid_count,
        fresh_count,
        recent_count,
        duplicate_count,
        tostring(last_reason)
    )

    return false, "no candidate passed final safety checks (" .. tostring(last_reason) .. ")"
end

function VersusModeState.spawn_position_for_role(role, remote_payload)
    if VersusModeState.random_safe_spawn_enabled() then
        return VersusModeState.random_safe_spawn(role)
    end

    if remote_payload then
        return VersusModeState.validate_remote_spawn(remote_payload, role)
    end

    return VersusModeState.spawn_validation(true, role)
end

function VersusModeState.spawn_validation(force_refresh, role)
    role = role or mod._versus_role_test
    local t = gameplay_time()

    if not role or not VersusModeState.local_active() or mod._control then
        return false, "Respawn unavailable"
    end

    if not force_refresh and role.spawn_check and t < (role.spawn_check_at or 0) then
        local check = role.spawn_check

        return check.ok, check.reason, check.position and check.position:unbox(), check.rotation and check.rotation:unbox()
    end

    local check = { ok = false, reason = "Free-flight camera unavailable" }
    local free_flight = Managers.free_flight

    if not free_flight or not free_flight:is_in_free_flight() then
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local camera_position, camera_rotation = free_flight:camera_position_rotation("global")
    local nav_manager = Managers.state and Managers.state.nav_mesh
    local nav_world = nav_manager and nav_manager:nav_world()

    if not camera_position or not camera_rotation or not nav_world then
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local nav_ok, spawn_position = pcall(
        VersusModeState.nav_queries.position_on_mesh_guaranteed,
        nav_world,
        camera_position,
        4,
        30,
        nil,
        2.5,
        0.35
    )

    if not nav_ok or not spawn_position then
        check.reason = "No usable floor below camera"
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local physics_world = VersusModeState.physics_world()

    if not physics_world then
        check.reason = "Level collision unavailable"
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local headroom_ok, blocked_overhead = pcall(
        PhysicsWorld.raycast,
        physics_world,
        spawn_position + vector3_up() * 0.15,
        vector3_up(),
        VersusModeState.spawn_headroom(role.respawn_breed),
        "any",
        "types",
        "both",
        "collision_filter",
        "filter_minion_mover"
    )

    if not headroom_ok or blocked_overhead then
        check.reason = "Not enough room at camera location"
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local nearest_name, nearest_distance = VersusModeState.nearest_survivor(spawn_position)
    local minimum_distance = math_max(0, setting("infected_min_spawn_distance"))

    if nearest_name and nearest_distance < minimum_distance then
        check.reason = string.format(
            "Too close to %s (%.1f m; minimum %.1f m)",
            nearest_name,
            nearest_distance,
            minimum_distance
        )
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local visible_name = VersusModeState.visible_to_survivor(spawn_position, physics_world, role.respawn_breed)

    if visible_name then
        check.reason = "Visible to " .. visible_name
        role.spawn_check = check
        role.spawn_check_at = t + 0.1

        return false, check.reason
    end

    local camera_forward = Quaternion.forward(camera_rotation)
    local flat_forward = Vector3(Vector3.x(camera_forward), Vector3.y(camera_forward), 0)

    if vector3_length(flat_forward) < 0.01 then
        flat_forward = Vector3(0, 1, 0)
    else
        flat_forward = vector3_normalize(flat_forward)
    end

    local spawn_rotation = Quaternion.look(flat_forward, vector3_up())

    check.ok = true
    check.reason = string.format("Hidden and at least %.0f m from survivors", minimum_distance)
    check.position = Vector3Box(spawn_position + vector3_up() * 0.05)
    check.rotation = QuaternionBox(spawn_rotation)
    role.spawn_check = check
    role.spawn_check_at = t + 0.1

    return true, check.reason, check.position:unbox(), check.rotation:unbox()
end

function VersusModeState.validate_remote_spawn(payload, role)
    if type(payload) ~= "table"
        or type(payload.x) ~= "number"
        or type(payload.y) ~= "number"
        or type(payload.z) ~= "number"
        or type(payload.yaw) ~= "number"
        or payload.x ~= payload.x
        or payload.y ~= payload.y
        or payload.z ~= payload.z
        or payload.yaw ~= payload.yaw
        or math.abs(payload.x) > 100000
        or math.abs(payload.y) > 100000
        or math.abs(payload.z) > 100000 then
        return false, "Invalid client camera position"
    end

    local camera_position = Vector3(payload.x, payload.y, payload.z)
    local nav_manager = Managers.state and Managers.state.nav_mesh
    local nav_world = nav_manager and nav_manager:nav_world()

    if not nav_world then
        return false, "Navigation mesh unavailable"
    end

    local nav_ok, spawn_position = pcall(
        VersusModeState.nav_queries.position_on_mesh_guaranteed,
        nav_world,
        camera_position,
        4,
        30,
        nil,
        2.5,
        0.35
    )

    if not nav_ok or not spawn_position then
        return false, "No usable floor below camera"
    end

    local physics_world = VersusModeState.physics_world()

    if not physics_world then
        return false, "Level collision unavailable"
    end

    local headroom_ok, blocked_overhead = pcall(
        PhysicsWorld.raycast,
        physics_world,
        spawn_position + vector3_up() * 0.15,
        vector3_up(),
        VersusModeState.spawn_headroom(role and role.respawn_breed),
        "any",
        "types",
        "both",
        "collision_filter",
        "filter_minion_mover"
    )

    if not headroom_ok or blocked_overhead then
        return false, "Not enough room at camera location"
    end

    local nearest_name, nearest_distance = VersusModeState.nearest_survivor(spawn_position)
    local minimum_distance = math_max(0, setting("infected_min_spawn_distance"))

    if nearest_name and nearest_distance < minimum_distance then
        return false, string.format(
            "Too close to %s (%.1f m; minimum %.1f m)",
            nearest_name,
            nearest_distance,
            minimum_distance
        )
    end

    local visible_name = VersusModeState.visible_to_survivor(
        spawn_position,
        physics_world,
        role and role.respawn_breed
    )

    if visible_name then
        return false, "Visible to " .. visible_name
    end

    local flat_forward = Vector3(math_sin(payload.yaw), math_cos(payload.yaw), 0)
    local spawn_rotation = Quaternion.look(flat_forward, vector3_up())

    return true,
        string.format("Hidden and at least %.0f m from survivors", minimum_distance),
        spawn_position + vector3_up() * 0.05,
        spawn_rotation
end

local function find_controllable_enemy(player, player_unit)
    local extension_manager = Managers.state and Managers.state.extension
    local side_system = extension_manager and extension_manager:system("side_system")
    local side = side_system and side_system.side_by_unit[player_unit]

    if not side then
        return nil
    end

    local units = side:alive_units_by_tag("enemy", "minion")
    local origin, rotation = camera_origin_rotation(player)
    local forward = rotation and Quaternion.forward(rotation)
    local maximum_range = setting("selection_range")
    local aimed_unit
    local aimed_score = -math.huge
    local nearest_unit
    local nearest_distance = math.huge
    local unavailable_daemonhost
    local unavailable_daemonhost_score = -math.huge

    for i = 1, units.size do
        local unit = units[i]
        local breed, unavailable_reason, unavailable_breed

        if ALIVE[unit] then
            breed, unavailable_reason, unavailable_breed = controllable_breed(unit)
        end

        if breed then
            local position = live_world_position(unit)

            if position and origin then
                local offset = position - origin
                local distance = vector3_length(offset)

                if distance <= maximum_range then
                    if distance < nearest_distance then
                        nearest_unit = unit
                        nearest_distance = distance
                    end

                    if forward and distance > 0.01 then
                        local aim_dot = vector3_dot(forward, offset / distance)

                        if aim_dot >= 0.94 then
                            local score = aim_dot - distance * 0.0005

                            if score > aimed_score then
                                aimed_unit = unit
                                aimed_score = score
                            end
                        end
                    end
                end
            end
        elseif unavailable_reason == "daemonhost not awake" and unavailable_breed then
            local position = live_world_position(unit)

            if position and origin then
                local offset = position - origin
                local distance = vector3_length(offset)

                if distance <= maximum_range then
                    local score = -distance * 0.0005

                    if forward and distance > 0.01 then
                        local aim_dot = vector3_dot(forward, offset / distance)

                        if aim_dot >= 0.94 then
                            score = aim_dot - distance * 0.0005
                        end
                    end

                    if score > unavailable_daemonhost_score then
                        unavailable_daemonhost = unit
                        unavailable_daemonhost_score = score
                    end
                end
            end
        end
    end

    if aimed_unit or nearest_unit then
        return aimed_unit or nearest_unit
    end

    return nil, unavailable_daemonhost and "daemonhost not awake" or nil
end

local function safe_anim_event(extension, event_name)
    safe_extension_call(extension, "anim_event", event_name)
end

local function stop_manual_motion(state, skip_idle)
    if state and state.locomotion and ALIVE[state.unit] then
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())

        if state.moving and not skip_idle then
            safe_anim_event(state.animation, "idle")
            state.animation_heartbeat_last_event = "idle"
        end

        state.moving = false
    end
end

local function restore_captain_combat_state(state)
    local restore = state and state.captain_combat_restore

    if not restore then
        return
    end

    if not state.unit or not ALIVE[state.unit] then
        state.captain_combat_restore = nil

        return
    end

    local still_controlled = state.possessed == true

    -- Creature Spawner can rebuild a unit's blackboard before ALIVE flips.
    -- Resolve it again and keep the complete proxy access protected so cleanup
    -- cannot turn a despawn/replacement race into a Lua error. While possessed,
    -- keep the phase frozen on the same slot/range pair as the last command.
    -- On release, unlock only after current_phase, wanted_phase and combat_range
    -- have been made coherent; Darktide assumes that combination always exists.
    pcall(function()
        local blackboard = BLACKBOARDS[state.unit] or state.blackboard
        local phase_component = blackboard and Blackboard.write_component(blackboard, "phase")
        local weapon_switch_component = blackboard and Blackboard.write_component(blackboard, "weapon_switch")
        local behavior_component = blackboard and Blackboard.write_component(blackboard, "behavior")

        if phase_component then
            phase_component.current_phase = restore.safe_phase_name
            phase_component.wanted_phase = restore.safe_phase_name
            phase_component.exit_phase_t = still_controlled and math.huge or gameplay_time()
            phase_component.force_next_phase = false
            phase_component.lock = still_controlled or restore.phase_lock
        end

        if weapon_switch_component then
            weapon_switch_component.wanted_weapon_slot = restore.safe_weapon_slot
            weapon_switch_component.wanted_combat_range = restore.safe_combat_range
            weapon_switch_component.is_switching_weapons = false
        end

        if behavior_component then
            behavior_component.combat_range = restore.safe_combat_range
            behavior_component.lock_combat_range_switch = still_controlled or restore.combat_range_lock
        end
    end)

    if not still_controlled then
        state.captain_combat_restore = nil
    end
end

-- A successful Hound collision ends the leap leaf one frame before the native
-- target-pounced leaf starts. If control is paused in that hand-off (or a
-- cancel/timeout aborts it), BtChaosHoundLeapAction deliberately leaves the
-- locomotion in script-driven mode because it expects the next leaf to restore
-- it. Always return a paused controlled Hound to steerable navmesh movement.
function VersusModeState.reset_hound_pounce_motion(state)
    if not state
        or not state.breed
        or not HOUND_BREEDS[state.breed.name]
        or not ALIVE[state.unit] then
        return false
    end

    local pounce_component = state.blackboard and state.blackboard.pounce
    local was_active = state.hound_manual_pounce_active == true
        or state.hound_manual_pounce_started == true
        or pounce_component and (
            pounce_component.started_leap == true
            or pounce_component.pounce_target ~= nil
        )

    if pounce_component then
        pounce_component.started_leap = false
        pounce_component.pounce_target = nil
    end

    local behavior_component = state.blackboard and state.blackboard.behavior

    if behavior_component and behavior_component.move_state == "attacking" then
        behavior_component.move_state = "moving"
    end

    if state.locomotion then
        safe_extension_call(state.locomotion, "set_wanted_velocity", Vector3.zero())
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
        safe_extension_call(state.locomotion, "set_affected_by_gravity", false)
        safe_extension_call(state.locomotion, "set_anim_driven", false, false, false)
        safe_extension_call(state.locomotion, "use_lerp_rotation", true)
        safe_extension_call(state.locomotion, "set_movement_type", "snap_to_navmesh")

        if type(state.old_rotation_speed) == "number" then
            safe_extension_call(state.locomotion, "set_rotation_speed", state.old_rotation_speed)
        end
    end

    state.hound_committed_solution = nil
    state.hound_manual_pounce_active = nil
    state.hound_manual_pounce_started = nil
    state.hound_manual_pounce_started_at = nil

    if was_active then
        safe_anim_event(state.animation, "idle")
        state.animation_heartbeat_last_event = "idle"
    end

    return was_active == true
end

local function pause_brain(state)
    if not state or not ALIVE[state.unit] then
        return
    end

    local t = gameplay_time()

    if state.behavior then
        pcall(function()
            local brain = state.behavior._brain

            if brain then
                brain:shutdown_behavior_tree(t, false)
            end

            state.behavior:set_brain_enabled(false)
        end)
    end

    VersusModeState.reset_hound_pounce_motion(state)

    if state.breed.name == "chaos_spawn" and state.blackboard and state.blackboard.behavior then
        state.blackboard.behavior.should_leap = false
    end

    if state.spawn_leap_motion_scratchpad then
        Specialist.restore_controlled_spawn_leap_navigation(state.spawn_leap_motion_scratchpad)
    end

    if state.navigation then
        safe_extension_call(state.navigation, "set_enabled", false)
    end

    if state.locomotion then
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())

        if state.camera_melee_translation_suppressed then
            safe_extension_call(state.locomotion, "set_anim_translation_scale", Vector3(1, 1, 1))
        end
    end

    if (state.first_person or MANUAL_AIM_BREEDS[state.breed.name]) and state.blackboard and state.blackboard.aim then
        state.blackboard.aim.controlled_aiming = false
    end

    restore_captain_combat_state(state)

    state.attack_min_until = nil
    state.attack_deadline = nil
    state.attack_hard_deadline = nil
    state.attack_started = nil
    state.gunner_shoot_move_event = nil
    state.gunner_shoot_rotation_released = nil
    state.command_action_complete = nil
    state.attack_target = nil
    state.requested_attack = nil
    state.attack_phase = nil
    state.consume_attempt_complete = nil
    state.sniper_shot_fired = nil
    state.sniper_shot_stop_t = nil
    state.sniper_laser_active = nil
    state.grenade_committed_solution = nil
    state.grenade_throw_complete = nil
    state.grenade_projectile_spawned = nil
    state.net_shot_complete = nil
    state.mutant_carrying = nil
    state.mutant_force_throw = nil
    state.poxburster_armed = nil
    state.spawn_leap_failure = nil
    state.spawn_leap_native_state = nil
    state.spawn_leap_launched = nil
    state.spawn_leap_request_distance = nil
    state.spawn_leap_calculation_distance = nil
    state.spawn_leap_landing_offset = nil
    state.spawn_leap_contact_tolerance = nil
    state.spawn_leap_start_position = nil
    state.spawn_leap_target_position = nil
    state.spawn_leap_landing_logged = nil
    state.spawn_leap_native_predicted_error = nil
    state.spawn_leap_clearance_height = nil
    state.spawn_leap_predicted_error = nil
    state.spawn_leap_handoff_logged = nil
    state.spawn_leap_solver_speed = nil
    state.spawn_leap_motion_scratchpad = nil
    state.hound_committed_solution = nil
    state.hound_manual_pounce_active = nil
    state.hound_manual_pounce_started = nil
    state.hound_manual_pounce_started_at = nil
    state.flamer_shot_from = nil
    state.flamer_shot_to = nil
    state.flamer_last_aim_position = nil
    state.flamer_stream_started_at = nil
    state.flamer_retry_logged = nil
    state.flamer_early_done_logged = nil
    state.command_aim_yaw = nil
    state.command_aim_pitch = nil
    state.camera_melee_move_destination = nil
    state.camera_melee_translation_suppressed = nil
    state.direct_attack_complete = nil
    -- The native action may have replaced the last manual move/idle state.
    -- Mark locomotion dirty so the first post-action frame emits exactly one
    -- recovery event instead of a perpetual timer-based heartbeat.
    state.animation_heartbeat_last_event = nil
    Specialist.destroy_hound_preview(state)
end

local function outline_system()
    local extension_manager = Managers.state and Managers.state.extension

    return extension_manager and extension_manager:system("outline_system")
end

function VersusModeState.set_outline_material_color(unit, material_layers, color_values)
    if not unit or not ALIVE[unit] or type(material_layers) ~= "table" or type(color_values) ~= "table" then
        return 0
    end

    local color = Vector3(color_values[1], color_values[2], color_values[3])
    local colored_units = {}
    local colored_count = 0

    local function color_unit(candidate)
        if not candidate or colored_units[candidate] or not ALIVE[candidate] then
            return
        end

        colored_units[candidate] = true

        local colored = false

        for i = 1, #material_layers do
            local material_layer = material_layers[i]

            if material_layer ~= "" then
                local ok = pcall(
                    Unit.set_vector3_for_material,
                    candidate,
                    material_layer,
                    "outline_color",
                    color
                )

                colored = ok or colored
            end
        end

        if colored then
            colored_count = colored_count + 1
        end
    end

    local function color_attachment_groups(attachments)
        if type(attachments) ~= "table" then
            return
        end

        for parent_unit, attachment_group in pairs(attachments) do
            if type(parent_unit) == "number" then
                -- Older loadout surfaces can expose one flat attachment list.
                color_unit(attachment_group)
            else
                color_unit(parent_unit)

                if type(attachment_group) == "table" then
                    for _, attachment_unit in pairs(attachment_group) do
                        color_unit(attachment_unit)
                    end
                else
                    color_unit(attachment_group)
                end
            end
        end
    end

    color_unit(unit)

    local visual_loadout = ScriptUnit.has_extension(unit, "visual_loadout_system")

    if not visual_loadout then
        return colored_count
    end

    -- Darktide 1.12 player and player-husk loadouts no longer expose the
    -- inventory_slots()/slot_unit() pair still called by OutlineSystem's
    -- breed-only color helper. Enumerate the current equipment surface and
    -- color its third-person units and attachment groups directly.
    local equipment = visual_loadout._equipment

    if type(equipment) == "table" then
        for slot_name, slot in pairs(equipment) do
            local slot_unit = type(slot) == "table" and slot.unit_3p or nil
            local attachments = type(slot) == "table" and slot.attachments_by_unit_3p or nil

            if type(visual_loadout.unit_and_attachments_from_slot) == "function" then
                local ok, _, current_slot_unit, _, current_attachments = pcall(
                    visual_loadout.unit_and_attachments_from_slot,
                    visual_loadout,
                    slot_name
                )

                if ok then
                    slot_unit = current_slot_unit or slot_unit
                    attachments = current_attachments or attachments
                end
            end

            color_unit(slot_unit)
            color_attachment_groups(attachments)
        end

        return colored_count
    end

    -- Retain compatibility with older visual-loadout extensions.
    if type(visual_loadout.inventory_slots) ~= "function" then
        return colored_count
    end

    local slots_ok, slots = pcall(visual_loadout.inventory_slots, visual_loadout)

    if not slots_ok or not slots then
        return colored_count
    end

    for slot_name, slot in pairs(slots) do
        if slot.use_outline then
            local slot_ok, slot_unit, attachments = false, nil, nil

            if type(visual_loadout.slot_unit) == "function" then
                slot_ok, slot_unit, attachments = pcall(
                    visual_loadout.slot_unit,
                    visual_loadout,
                    slot_name
                )
            end

            if slot_ok then
                local outlined_unit = slot_unit or slot.unit

                color_unit(outlined_unit)
                color_attachment_groups(attachments)
            end
        end
    end

    return colored_count
end

local function find_target_outline(extension)
    local outlines = extension and extension.outlines

    if outlines then
        for i = 1, #outlines do
            if outlines[i].name == TARGET_OUTLINE then
                return outlines[i]
            end
        end
    end

    return nil
end

function VersusModeState.find_owned_outline(extension, outline_name)
    local outlines = extension and extension.outlines

    if outlines then
        for i = 1, #outlines do
            if outlines[i].name == outline_name then
                return outlines[i]
            end
        end
    end

    return nil
end

function VersusModeState.allied_heretic_units()
    local units = {}
    local own_unit = mod._control and mod._control.possessed and mod._control.unit or nil

    for _, state in pairs(mod._remote_controls or {}) do
        if state.possessed and state.versus_role and state.unit ~= own_unit
            and ALIVE[state.unit] and HEALTH_ALIVE[state.unit] then
            units[state.unit] = true
        end
    end

    if is_server() then
        for _, role in pairs(VersusModeState.roles()) do
            local unit = not role.infected_human and role.autonomous_bot_unit or nil

            if unit and unit ~= own_unit and ALIVE[unit] and HEALTH_ALIVE[unit] then
                units[unit] = true
            end
        end
    end

    if not is_server() then
        for _, role in pairs(VersusModeState.roles()) do
            local unit = type(role.controlled_unit_id) == "number"
                and VersusModeState.unit_from_network_id(role.controlled_unit_id)
                or nil

            if unit and unit ~= own_unit and ALIVE[unit] and HEALTH_ALIVE[unit] then
                units[unit] = true
            end
        end
    end

    return units
end

function VersusModeState.refresh_allied_heretic_outlines(system, desired_units)
    desired_units = desired_units or {}
    mod._allied_heretic_outlined_units = mod._allied_heretic_outlined_units
        or setmetatable({}, { __mode = "k" })

    local tracked_units = mod._allied_heretic_outlined_units
    local extension_data = system and system._unit_extension_data or {}

    for unit in pairs(tracked_units) do
        local extension = extension_data[unit]

        if not desired_units[unit] or not ALIVE[unit] or not HEALTH_ALIVE[unit]
            or not extension or extension.name ~= "MinionOutlineExtension" then
            local outline = VersusModeState.find_owned_outline(
                extension,
                VersusModeState.allied_heretic_outline_name
            )

            if outline then
                outline.stack_count = 1
                pcall(
                    system.remove_outline,
                    system,
                    unit,
                    VersusModeState.allied_heretic_outline_name
                )
            end

            tracked_units[unit] = nil
        end
    end

    for unit in pairs(desired_units) do
        local extension = extension_data[unit]

        if extension and extension.name == "MinionOutlineExtension"
            and ALIVE[unit] and HEALTH_ALIVE[unit] then
            VersusModeState.ensure_outline_settings(extension)

            local outline = VersusModeState.find_owned_outline(
                extension,
                VersusModeState.allied_heretic_outline_name
            )

            if not outline then
                pcall(
                    system.add_outline,
                    system,
                    unit,
                    VersusModeState.allied_heretic_outline_name
                )
                outline = VersusModeState.find_owned_outline(
                    extension,
                    VersusModeState.allied_heretic_outline_name
                )
            end

            if outline then
                outline.stack_count = 1
                tracked_units[unit] = true
            end
        end
    end

    return desired_units
end

function VersusModeState.clear_allied_heretic_outlines()
    local system = outline_system()

    if system then
        VersusModeState.refresh_allied_heretic_outlines(system, {})
    end

    mod._allied_heretic_outlined_units = nil
end

function VersusModeState.presentation_target_outline(state)
    if not state then
        return nil
    end

    local unit = VersusModeState.valid_attack_target(state.locked_target, state)
        and state.locked_target
        or state.remote_client
            and VersusModeState.valid_attack_target(state.remote_locked_target, state)
            and state.remote_locked_target
        or nil

    if unit then
        return unit
    end

    unit = state.remote_client
        and VersusModeState.valid_attack_target(state.remote_outline_target, state)
        and state.remote_outline_target
        or nil

    if unit then
        return unit
    end

    return Specialist.free_aim(state)
        and VersusModeState.valid_attack_target(state.manual_aim_hit_unit, state)
        and state.manual_aim_hit_unit
        or nil
end

function VersusModeState.locked_target_for_state(state)
    if not state then
        return nil
    end

    return VersusModeState.valid_attack_target(state.locked_target, state)
        and state.locked_target
        or state.remote_client
            and VersusModeState.valid_attack_target(state.remote_locked_target, state)
            and state.remote_locked_target
        or nil
end

local function clear_target_outline(state)
    if state then
        state.outlined_target = nil
    end
end

local function refresh_target_outline(state)
    local unit = VersusModeState.presentation_target_outline(state)

    state.outlined_target = setting("show_target_outline")
        and VersusModeState.valid_attack_target(unit, state)
        and unit
        or nil
end

function VersusModeState.operative_outline_units(state)
    local units = {}

    if not setting("show_target_outline") or not VersusModeState.local_infected_view() then
        return units
    end

    local locked_target = VersusModeState.locked_target_for_state(state)
    local player_manager = Managers.player
    local players_ok, players = pcall(function()
        return player_manager and player_manager:players()
    end)

    for _, player in pairs(players_ok and players or {}) do
        local unit_ok, unit = pcall(function()
            return player and player.player_unit
        end)

        if unit_ok and VersusModeState.valid_attack_target(unit, state) then
            units[unit] = unit == locked_target
                and VersusModeState.locked_operative_outline_color
                or VersusModeState.operative_outline_color
        end
    end

    return units
end

function VersusModeState.force_outline_material_layers(unit, material_layers)
    if not unit or not ALIVE[unit] or type(material_layers) ~= "table" then
        return false
    end

    local enabled = false

    for i = 1, #material_layers do
        local material_layer = material_layers[i]

        if material_layer ~= "" then
            enabled = pcall(Unit.set_material_layer, unit, material_layer, true) or enabled
        end
    end

    if enabled then
        pcall(Unit.set_unit_culling, unit, false, true)
    end

    return enabled
end


-- Every visible Operative owns one VersusMode outline while viewed by a
-- Heretic. White identifies an unlocked enemy; the confirmed locked target is
-- red. Reassert only the enabled layers and color after native OutlineSystem
-- processing, avoiding the old every-frame hide/show cycle that could flicker
-- or leave the player-blue material disabled behind stale bookkeeping.
function VersusModeState.refresh_operative_outlines(system, state, force_clear)
    if not system then
        return 0
    end

    local desired_units = not force_clear and VersusModeState.operative_outline_units(state) or {}

    mod._operative_outlined_units = mod._operative_outlined_units
        or setmetatable({}, { __mode = "k" })

    local tracked_units = mod._operative_outlined_units
    local extension_data = system._unit_extension_data or {}

    for unit in pairs(tracked_units) do
        local extension = extension_data[unit]

        if not desired_units[unit]
            or not ALIVE[unit]
            or not extension
            or extension.name ~= "PlayerUnitOutlineExtension" then
            local outline = find_target_outline(extension)

            if outline then
                outline.stack_count = 1
                pcall(system.remove_outline, system, unit, TARGET_OUTLINE)
            end

            tracked_units[unit] = nil
        end
    end

    local applied = 0

    for unit, color in pairs(desired_units) do
        local extension = extension_data[unit]

        if extension and extension.name == "PlayerUnitOutlineExtension" then
            VersusModeState.ensure_outline_settings(extension)

            local outline = find_target_outline(extension)

            if not outline then
                pcall(system.add_outline, system, unit, TARGET_OUTLINE)
                outline = find_target_outline(extension)
            end

            if outline then
                outline.stack_count = 1
                outline.priority = target_outline_setting.priority
                outline.color = color
                outline.material_layers = VersusModeState.target_outline_material_layers
                outline.visibility_check = target_outline_setting.visibility_check

                local outlines = extension.outlines

                if outlines and outlines[1] ~= outline then
                    for i = 2, #outlines do
                        if outlines[i] == outline then
                            table.remove(outlines, i)
                            table.insert(outlines, 1, outline)

                            break
                        end
                    end
                end

                if extension.visible_material_layers ~= VersusModeState.suppressed_outline_marker then
                    if extension.visible_material_layers ~= VersusModeState.target_outline_material_layers then
                        pcall(system._hide_outline, system, unit, extension)
                        pcall(system._show_outline, system, unit, extension)
                    end

                    VersusModeState.force_outline_material_layers(
                        unit,
                        VersusModeState.target_outline_material_layers
                    )
                    VersusModeState.set_outline_material_color(
                        unit,
                        VersusModeState.target_outline_material_layers,
                        color
                    )
                    tracked_units[unit] = true
                    applied = applied + 1
                end
            end
        end
    end

    return applied
end

function VersusModeState.clear_operative_outlines()
    local system = outline_system()

    if system then
        VersusModeState.refresh_operative_outlines(system, nil, true)
    end

    mod._operative_outlined_units = nil
end

local function remote_target_reference_key(reference)
    if type(reference) ~= "table" then
        return "none"
    end

    return table.concat({
        tostring(reference.unit_id or ""),
        tostring(reference.peer_id or ""),
        tostring(reference.local_player_id or ""),
        tostring(reference.account_id or ""),
        tostring(reference.character_id or ""),
        tostring(reference.unique_id or ""),
        tostring(reference.name or ""),
    }, ":")
end

function VersusModeState.refresh_remote_target_resolution(state)
    if not state or not state.remote_client then
        return false
    end

    local old_presentation = VersusModeState.presentation_target_outline(state)
    local locked_target, locked_source = VersusModeState.resolve_remote_target_reference(
        state.remote_locked_target_reference,
        state
    )
    local outline_target, outline_source = VersusModeState.resolve_remote_target_reference(
        state.remote_outline_target_reference,
        state
    )

    state.remote_locked_target = locked_target
    state.remote_outline_target = outline_target

    local presentation = VersusModeState.presentation_target_outline(state)

    if state.outlined_target ~= presentation or old_presentation ~= presentation then
        refresh_target_outline(state)
    end

    local primary_reference = state.remote_locked_target_reference
        or state.remote_outline_target_reference
    local resolution_source = locked_target and locked_source
        or outline_target and outline_source
        or primary_reference and (locked_source ~= "none" and locked_source or outline_source)
        or "cleared"
    local diagnostic_key = remote_target_reference_key(primary_reference)
        .. ":" .. tostring(presentation) .. ":" .. tostring(resolution_source)

    if state.remote_target_resolution_diagnostic ~= diagnostic_key then
        state.remote_target_resolution_diagnostic = diagnostic_key

        if primary_reference then
            mod:info(
                "Versus Mode: client Operative target %s via %s (name=%s, network id=%s, unit=%s).",
                presentation and "resolved" or "pending",
                tostring(resolution_source),
                tostring(primary_reference.name or state.remote_target_name or "unknown"),
                tostring(primary_reference.unit_id or "none"),
                tostring(presentation or "none")
            )
        else
            mod:info("Versus Mode: client Operative target outline cleared.")
        end
    end

    return presentation ~= nil
end

local function set_locked_target(state, unit)
    state.locked_target = unit
    refresh_target_outline(state)
end

local function set_status(state, text, duration)
    if not state then
        return
    end

    state.status_message = text
    state.status_until = gameplay_time() + (duration or 2.5)
end

function VersusModeState.finish_failed_spawn_leap(state)
    local failure = state and state.spawn_leap_failure

    if not failure then
        return false
    end

    local remote_controller = state.controller_peer_id ~= nil

    pause_brain(state)
    set_status(state, failure, 3)

    if remote_controller then
        mod:info("Versus Mode: remote Chaos Spawn Leap stopped: %s", failure)
    else
        VersusModeState.echo_notice(failure)
    end

    return true
end

local function restore_camera(state, keep_current_free_flight)
    local free_flight = Managers.free_flight

    if not free_flight or not state then
        VersusModeState.restore_possession_camera_player_body()

        return
    end

    mod._suppress_freeflight_toggle_frames = 3

    -- A killed infected should continue from the point where its possessed
    -- body died. Restoring the pre-possession pose here would send the waiting
    -- camera back to the location where that enemy originally spawned.
    if keep_current_free_flight then
        -- If possession created the viewport, ownership must move to the
        -- Heretic role while that same viewport becomes Deployment View.
        -- Otherwise clear_role() will regard it as foreign and leave it alive
        -- after the player dies or the mission changes.
        if state.versus_role and state.camera_was_active ~= true then
            state.versus_role.wait_camera_owned = true
        end

        VersusModeState.force_possession_camera_player_body()

        return
    end

    if state.camera_was_active then
        if free_flight:is_in_free_flight() and state.saved_camera_position and state.saved_camera_rotation then
            -- ScriptCamera returns frame-local Vector3/Quaternion userdata.
            -- Possession can last for minutes, so restore only durable boxed
            -- copies instead of retaining those stale engine values.
            local restored, position, rotation = pcall(function()
                return state.saved_camera_position:unbox(), state.saved_camera_rotation:unbox()
            end)

            if restored then
                local teleported = pcall(free_flight.teleport_camera, free_flight, "global", position, rotation)

                if not teleported then
                    mod:warning("Could not restore the pre-possession free-flight camera pose.")
                end
            else
                mod:warning("Could not unbox the pre-possession free-flight camera pose.")
            end
        end
    elseif free_flight:is_in_free_flight() then
        local camera_data = free_flight._free_flight_cameras and free_flight._free_flight_cameras.global

        if camera_data then
            free_flight:_exit_global_free_flight(camera_data)
        end
    end

    VersusModeState.refresh_possession_camera_player_body()
end

function VersusModeState.write_boss_health(health_extension, max_health, damage)
    if not health_extension or type(max_health) ~= "number" or max_health <= 0 then
        return false
    end

    damage = math_min(math_max(0, damage or 0), max_health)
    health_extension._health = max_health
    health_extension._damage = damage

    local game_session = health_extension._game_session
    local game_object_id = health_extension._game_object_id

    if game_session and game_object_id then
        local health_ok = pcall(GameSession.set_game_object_field, game_session, game_object_id, "health", max_health)
        local damage_ok = pcall(GameSession.set_game_object_field, game_session, game_object_id, "damage", damage)

        return health_ok and damage_ok
    end

    return true
end

function VersusModeState.health_network_max()
    local network_constants = VersusModeState.network_constants

    if not network_constants then
        local loaded, result = pcall(require, "scripts/network_lookup/network_constants")

        if not loaded or type(result) ~= "table" then
            return nil
        end

        network_constants = result
        VersusModeState.network_constants = result
    end

    local health_large = network_constants.health_large
    local maximum = health_large and health_large.max

    return type(maximum) == "number" and maximum or nil
end

function VersusModeState.controlled_health_setting_id(state)
    local breed = state and state.breed

    if not breed then
        return nil
    end

    if state.controlled_normal_boss then
        return "controlled_boss_health_multiplier"
    elseif VersusModeState.controlled_elite_breeds[breed.name] then
        return "controlled_elite_health_multiplier"
    elseif breed.tags and breed.tags.special == true then
        return "controlled_specialist_health_multiplier"
    end

    return nil
end

function VersusModeState.rescale_controlled_health(state, multiplier)
    if not state or not VersusModeState.controlled_health_setting_id(state) then
        return false
    end

    local health_extension = safe_extension(state.unit, "health_system")

    if not health_extension then
        return false
    end

    local current_ok, current_health = safe_extension_call(health_extension, "current_health")
    local max_ok, current_max = safe_extension_call(health_extension, "max_health")

    if not current_ok or not max_ok or type(current_health) ~= "number" or type(current_max) ~= "number" or current_max <= 0 then
        return false
    end

    state.controlled_health_original_max = state.controlled_health_original_max or current_max
    local health_ratio = math_min(1, math_max(0, current_health / current_max))
    local requested_max = state.controlled_health_original_max * math_max(1, multiplier or 1)
    local network_max = VersusModeState.health_network_max()

    if not network_max then
        return false
    end

    local new_max = math_min(requested_max, network_max)
    local new_damage = new_max * (1 - health_ratio)
    local written = VersusModeState.write_boss_health(health_extension, new_max, new_damage)

    if written then
        state.controlled_health_applied_multiplier = new_max / state.controlled_health_original_max
        state.controlled_health_extension = health_extension
    end

    return written
end

function VersusModeState.restore_controlled_health(state)
    if not state or not state.controlled_health_original_max then
        return
    end

    local health_extension = safe_extension(state.unit, "health_system")

    if not health_extension then
        return
    end

    local current_ok, current_health = safe_extension_call(health_extension, "current_health")
    local max_ok, current_max = safe_extension_call(health_extension, "max_health")

    if not current_ok or not max_ok or type(current_health) ~= "number" or type(current_max) ~= "number" or current_max <= 0 then
        return
    end

    local health_ratio = math_min(1, math_max(0, current_health / current_max))
    local restored_max = state.controlled_health_original_max

    VersusModeState.write_boss_health(health_extension, restored_max, restored_max * (1 - health_ratio))
end

function VersusModeState.rescale_controlled_boss_health(state, multiplier)
    return state and state.controlled_normal_boss
        and VersusModeState.rescale_controlled_health(state, multiplier)
        or false
end

function VersusModeState.restore_controlled_boss_health(state)
    if state and state.controlled_normal_boss then
        VersusModeState.restore_controlled_health(state)
    end
end

function VersusModeState.controlled_boss_cc_scale(unit)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.possessed and state.controlled_normal_boss and state.unit == unit then
        return math_min(1, math_max(0, setting("controlled_boss_cc_effect_percent") * 0.01))
    end

    return nil
end

function VersusModeState.scale_taunt_buffs(buff_extension, scale)
    if not buff_extension or scale == nil or scale >= 1 then
        return
    end

    for _, buff_instance in pairs(buff_extension._buffs_by_index or {}) do
        local template_ok, template = pcall(buff_instance.template, buff_instance)
        local is_taunt = template_ok and template and (template.buff_id == "taunted" or template.name == "taunted" or template.name == "taunted_short")

        if is_taunt and not buff_instance._versus_mode_cc_scaled then
            buff_instance._versus_mode_cc_scaled = true

            if scale <= 0 then
                buff_instance._finished = true
            else
                local duration_ok, duration = pcall(buff_instance.duration, buff_instance)

                if duration_ok and type(duration) == "number" and duration > 0 then
                    pcall(buff_instance.set_extra_duration, buff_instance, duration * scale - duration)
                end
            end
        end
    end
end

function VersusModeState.release_control(state, reason, suppress_respawn, controlled_unit_dead)
    if not state then
        return
    end

    local is_local_control = mod._control == state
    local controller_peer_id = state.controller_peer_id
    local versus_role = state.versus_role or is_local_control and mod._versus_role_test

    if is_local_control then
        VersusModeState.restore_sniper_scope(state)
        VersusModeState.restore_controlled_first_person_visibility(state)
    end

    VersusModeState.restore_controlled_animation_lod(state)

    if controlled_unit_dead and is_local_control and versus_role then
        VersusModeState.start_death_camera(state, versus_role)
    end

    if state.controlled_traversal then
        VersusModeState.finish_controlled_traversal(state, "released", controlled_unit_dead, true)
    end

    state.possessed = false

    if is_local_control then
        mod._suppress_smart_tag_until = gameplay_time() + 0.75
    end

    if not controlled_unit_dead
        and state.attack_deadline
        and (state.first_person or MANUAL_AIM_BREEDS[state.breed.name] or state.captain_combat_restore) then
        pause_brain(state)
    end

    restore_captain_combat_state(state)

    stop_manual_motion(state, controlled_unit_dead)
    clear_target_outline(state)
    destroy_grenade_preview(state)
    Specialist.destroy_hound_preview(state)

    if not controlled_unit_dead then
        VersusModeState.restore_controlled_health(state)
    end

    if versus_role and versus_role.assigned_boss_unit == state.unit then
        versus_role.assigned_boss_unit = nil
    end

    if is_local_control then
        mod._control = nil
    elseif controller_peer_id and mod._remote_controls then
        mod._remote_controls[controller_peer_id] = nil
    end

    if ALIVE[state.unit] then
        if state.blackboard and state.blackboard.aim then
            state.blackboard.aim.controlled_aiming = state.old_controlled_aiming or false
        end

        if state.perception_component then
            state.perception_component.lock_target = state.old_lock_target
        end

        if not controlled_unit_dead then
            safe_extension_call(state.perception, "force_new_target_attempt")
        end

        -- VersusMode pauses the behavior brain while directly driving a
        -- minion. Health depletion still raises the native "dead" behavior
        -- event, but that event cannot enter the breed's death action until
        -- the brain resumes. A death release must therefore enable it even
        -- when the freshly spawned unit happened to be inactive at possession.
        safe_extension_call(state.behavior, "set_brain_enabled", controlled_unit_dead and true or state.brain_was_active)

        if state.navigation then
            refresh_engine_position(state.unit)
            safe_extension_call(
                state.navigation,
                "set_enabled",
                controlled_unit_dead and true or state.navigation_was_enabled,
                state.old_max_speed
            )
        end

        if not controlled_unit_dead then
            safe_anim_event(state.animation, "idle")
        end
    end

    if state.player_health and ALIVE[state.player_unit] and state.player_invulnerability_changed then
        safe_extension_call(state.player_health, "set_invulnerable", state.old_raw_invulnerable)
    end

    if is_local_control then
        restore_original_first_person_equipment(state)
        restore_camera(state, controlled_unit_dead and VersusModeState.local_active())
    elseif controller_peer_id and mod._realms_compat then
        mod._realms_compat.release_control(controller_peer_id, reason, controlled_unit_dead)
    end

    if not suppress_respawn and versus_role and versus_role.infected_human and is_server() then
        VersusModeState.schedule_respawn(versus_role)

        if controlled_unit_dead then
            versus_role.automatic_respawn_not_before = gameplay_time()
                + VersusModeState.death_camera_drop_duration
                + VersusModeState.death_camera_hold_duration
        end

        if VersusModeState.local_role() == versus_role then
            VersusModeState.maintain_wait_camera(versus_role)
        end
    end

    VersusModeState.publish_roster()

    if reason and is_local_control then
        VersusModeState.echo_notice(reason)
    elseif reason and controller_peer_id then
        mod:info("Versus Mode: remote control %s released: %s", controller_peer_id, reason)
    end
end

local function release_possession(reason, suppress_respawn, controlled_unit_dead)
    if mod._control and mod._control.remote_client and VersusModeState.release_client_control then
        if not suppress_respawn and mod._realms_compat then
            VersusModeState.send_client_action("release")
        end

        return VersusModeState.release_client_control(reason, controlled_unit_dead)
    end

    return VersusModeState.release_control(mod._control, reason, suppress_respawn, controlled_unit_dead)
end

local function enter_camera(state)
    state.camera_failure_reason = nil

    local free_flight = VersusModeState.ensure_free_flight_manager()

    if not free_flight then
        state.camera_failure_reason = "native free-flight manager unavailable"

        return false
    end

    mod._suppress_freeflight_toggle_frames = 3

    state.camera_was_active = free_flight:is_in_free_flight()

    if state.camera_was_active then
        local position, rotation = free_flight:camera_position_rotation("global")

        if position and rotation then
            state.saved_camera_position = Vector3Box(position)
            state.saved_camera_rotation = QuaternionBox(rotation)
        end
    else
        local camera_data = free_flight._free_flight_cameras and free_flight._free_flight_cameras.global

        if not camera_data then
            state.camera_failure_reason = "native global camera data unavailable"

            return false
        end

        local entered, failure = pcall(free_flight._enter_global_free_flight, free_flight, camera_data)

        if not entered then
            state.camera_failure_reason = "native viewport entry failed: " .. tostring(failure)

            return false
        end
    end

    local active = free_flight:is_in_free_flight()

    if not active then
        state.camera_failure_reason = "native global viewport was not created"
    else
        VersusModeState.force_possession_camera_player_body()
    end

    return active
end

local function begin_possession(unit, player, player_unit, controller_peer_id, versus_role, variant_id)
    local breed, unavailable_reason = controllable_breed(unit)
    local controlled_normal_boss = false
    local controlled_weakened_boss = false

    if not breed then
        if unavailable_reason == "daemonhost not awake" then
            VersusModeState.echo_localized("notice_daemonhost_not_awake")
        else
            VersusModeState.echo_localized("notice_enemy_extensions_unavailable")
        end

        return false
    end

    -- Re-read the replicated stage immediately before pausing the brain. This
    -- closes the race between crosshair/allocation selection and possession;
    -- a passive Daemonhost must never be woken by shutdown_behavior_tree().
    if VersusModeState.daemonhost_breeds[breed.name]
        and VersusModeState.daemonhost_control_status(unit, breed) ~= "ready" then
        VersusModeState.echo_localized("notice_daemonhost_not_awake")

        return false
    end

    if breed and breed.is_boss then
        local eligible, _, _, weakened = VersusModeState.normal_boss_status(unit, breed)

        controlled_normal_boss = eligible == true
        controlled_weakened_boss = eligible == true and weakened == true
    end

    local behavior = safe_extension(unit, "behavior_system")
    local navigation = safe_extension(unit, "navigation_system")
    local locomotion = safe_extension(unit, "locomotion_system")
    local perception = safe_extension(unit, "perception_system")
    local animation = safe_extension(unit, "animation_system")
    local visual_loadout = safe_extension(unit, "visual_loadout_system")

    if not behavior or not navigation or not locomotion or not perception then
        VersusModeState.echo_localized("notice_enemy_extensions_unavailable")

        return false
    end

    local blackboard = BLACKBOARDS[unit]
    local perception_component = blackboard and blackboard.perception
    local aim_component = blackboard and blackboard.aim
    local spawn_component = blackboard and blackboard.spawn
    local old_max_speed = navigation:max_speed()
    local rotation_ok, old_rotation_speed = safe_extension_call(locomotion, "rotation_speed")
    local brain_was_active = true

    if behavior._brain then
        brain_was_active = behavior._brain:active()
    end

    local state = {
        unit = unit,
        breed = breed,
        blackboard = blackboard,
        behavior = behavior,
        navigation = navigation,
        locomotion = locomotion,
        perception = perception,
        perception_component = perception_component,
        animation = animation,
        visual_loadout = visual_loadout,
        physics_world = spawn_component and spawn_component.physics_world,
        player = player,
        player_unit = player_unit,
        brain_was_active = brain_was_active,
        navigation_was_enabled = navigation._enabled ~= false,
        old_max_speed = old_max_speed or breed.run_speed or 4,
        old_rotation_speed = rotation_ok and old_rotation_speed or nil,
        old_lock_target = perception_component and perception_component.lock_target or false,
        yaw = 0,
        pitch = not breed.is_boss and (is_specialist_breed(breed) or VersusModeState.controlled_elite_breeds[breed.name])
            and VersusModeState.specialist_camera_pitch or -0.18,
        moving = false,
        -- First person is opt-in and never applies to bosses. The live toggle
        -- can change this local presentation without changing target mode.
        first_person = breed.is_boss ~= true and setting("default_first_person_view") == true,
        casual_combat = Specialist.casual_breed_supported(breed),
        grenadier_target_lock = (is_specialist_breed(breed) or VersusModeState.controlled_elite_breeds[breed.name])
            and not (HOUND_BREEDS[breed.name] or MANUAL_AIM_BREEDS[breed.name]),
        old_controlled_aiming = aim_component and aim_component.controlled_aiming or false,
        controlled_normal_boss = controlled_normal_boss == true,
        controlled_weakened_boss = controlled_weakened_boss == true,
        controller_peer_id = VersusModeState.normalize_peer_id(controller_peer_id),
        versus_role = versus_role,
        variant_id = VersusModeState.valid_variant(breed.name, variant_id) and variant_id or nil,
    }

    local unit_rotation = Unit.world_rotation(unit, 1)
    local unit_forward = Quaternion.forward(unit_rotation)

    state.yaw = math_atan2(Vector3.x(unit_forward), Vector3.y(unit_forward))

    if not state.controller_peer_id then
        VersusModeState.finish_survivor_spectating(versus_role)
        VersusModeState.finish_death_camera(false)
        VersusModeState.recycle_wait_camera_for_possession(versus_role)
    end

    if not state.controller_peer_id and not enter_camera(state) then
        mod:warning(
            "Versus Mode: possession camera startup failed: %s.",
            tostring(state.camera_failure_reason or "unknown camera failure")
        )
        VersusModeState.echo_localized("notice_possession_camera_failed")

        return false
    end

    local player_health = safe_extension(player_unit, "health_system")

    if not state.controller_peer_id and setting("protect_player") and player_health then
        state.player_health = player_health
        state.old_raw_invulnerable = player_health._is_invulnerable or false
        state.player_invulnerability_changed = not state.old_raw_invulnerable
        player_health:set_invulnerable(true)
    end

    if state.controller_peer_id then
        mod._remote_controls = mod._remote_controls or {}
        mod._remote_controls[state.controller_peer_id] = state
    else
        hide_original_first_person_equipment(state)
        VersusModeState.refresh_controlled_first_person_visibility(state, true)
        mod._control = state
        mod._personal_panel_widget_suppression_logged = nil
        mod._personal_panel_suppression_failure_logged = nil
        mod._suppress_smart_tag_until = gameplay_time() + 0.75
    end

    local health_setting_id = VersusModeState.controlled_health_setting_id(state)

    if health_setting_id then
        local health_scaled = VersusModeState.rescale_controlled_health(state, setting(health_setting_id))

        if not health_scaled then
            mod:warning(
                "Versus Mode: could not apply the controlled-enemy health multiplier to %s.",
                tostring(breed.name)
            )
        end
    end

    if state.controlled_normal_boss then
        VersusModeState.scale_taunt_buffs(
            safe_extension(unit, "buff_system"),
            math_min(1, math_max(0, setting("controlled_boss_cc_effect_percent") * 0.01))
        )
    end

    if CAPTAIN_BREEDS[breed.name] then
        local captain_attacks = attacks_for_state(state) or {}
        local primary = captain_attacks.primary
        local primary_is_ranged = primary and primary.captain_combat_range == "far"
        local ranged = captain_attacks.special or primary_is_ranged and primary
        local melee_slot = not primary_is_ranged and primary and primary.captain_weapon_slot or "none"
        local ranged_slot = ranged and ranged.captain_weapon_slot or "none"
        local wielded_ok, wielded_slot = safe_extension_call(visual_loadout, "wielded_slot_name")

        mod:info(
            "Versus Mode: Captain possession preflight breed=%s melee=%s ranged=%s wielded=%s Casual=%s.",
            tostring(breed.name),
            tostring(melee_slot),
            tostring(ranged_slot),
            tostring(wielded_ok and wielded_slot or "unavailable"),
            tostring(state.casual_combat == true)
        )
    end

    pause_brain(state)
    locomotion:set_movement_type("snap_to_navmesh")
    state.possessed = true

    if not state.controller_peer_id then
        VersusModeState.ensure_controlled_animation_lod(state)
    end

    VersusModeState.publish_roster()

    set_status(state, "READY", 2)

    if state.controller_peer_id then
        local unit_id = VersusModeState.network_unit_id(unit)
        local sent = unit_id and mod._realms_compat and mod._realms_compat.assign_control(state.controller_peer_id, {
            breed_name = breed.name,
            casual_combat = state.casual_combat,
            pitch = state.pitch,
            unit_id = unit_id,
            variant_id = state.variant_id,
            yaw = state.yaw,
        })

        if not sent then
            VersusModeState.release_control(state, "the Realms client could not receive its enemy assignment.", true)

            return false
        end

        state.network_unit_id = unit_id
        state.next_status_sync_at = 0
    end

    -- The remote player receives its private assignment after the control RPC.
    -- Do not reveal that breed through the Operative host's local chat feed.
    if not state.controller_peer_id then
        if MANUAL_AIM_BREEDS[breed.name] then
            VersusModeState.echo_localized("notice_controlling_manual_aim", VersusModeState.controlled_label(state))
        elseif HOUND_BREEDS[breed.name] then
            VersusModeState.echo_localized("notice_controlling_hound", VersusModeState.controlled_label(state))
        elseif GRENADIER_BREEDS[breed.name] then
            VersusModeState.echo_localized("notice_controlling_grenadier", VersusModeState.controlled_label(state))
        elseif VersusModeState.controlled_elite_breeds[breed.name] then
            VersusModeState.echo_localized("notice_controlling_elite", VersusModeState.controlled_label(state))
        elseif is_specialist_breed(breed) then
            VersusModeState.echo_localized("notice_controlling_specialist", VersusModeState.controlled_label(state))
        elseif CAPTAIN_BREEDS[breed.name] then
            local captain_attacks = attacks_for_state(state) or {}
            local primary_is_ranged = captain_attacks.primary and captain_attacks.primary.captain_combat_range == "far"
            local ranged_label = captain_attacks.special and captain_attacks.special.label
                or primary_is_ranged and captain_attacks.primary.label
                or "no ranged weapon"

            VersusModeState.echo_localized(
                "notice_controlling_captain",
                pretty_name(breed),
                VersusModeState.localize_attack_label(ranged_label)
            )
        elseif not ATTACKS[breed.name] and breed.is_boss then
            VersusModeState.echo_localized("notice_controlling_native_boss", pretty_name(breed))
        else
            VersusModeState.echo_localized("notice_controlling_boss", pretty_name(breed))
        end
    end

    return true
end

function VersusModeState.queue_normal_boss(unit, boss_extension)
    if not VersusModeState.allow_boss_reinforcements
        or not setting("enable_versus_mode")
        or not setting("auto_takeover_normal_bosses")
        or not is_server()
        or not unit
        or not ALIVE[unit] then
        return
    end

    mod._versus_mode_checked_bosses = mod._versus_mode_checked_bosses or setmetatable({}, { __mode = "k" })

    if mod._versus_mode_checked_bosses[unit] then
        return
    end

    mod._versus_mode_checked_bosses[unit] = true

    local unit_data_extension = safe_extension(unit, "unit_data_system")
    local breed = unit_data_extension and unit_data_extension:breed()
    local eligible, _, classified_extension, weakened = VersusModeState.normal_boss_status(unit, breed, boss_extension)

    if not eligible then
        return
    end

    mod._pending_normal_bosses = mod._pending_normal_bosses or setmetatable({}, { __mode = "k" })
    mod._pending_normal_bosses[unit] = {
        unit = unit,
        breed = breed,
        boss_extension = classified_extension,
        weakened = weakened == true,
        queued_at = gameplay_time(),
        retry_at = 0,
        attempts = 0,
    }

    mod:info(
        "Versus Mode: queued %s boss %s for infected allocation.",
        weakened and "weakened" or "full-strength",
        breed.name
    )
end

function VersusModeState.controlled_boss_count()
    local count = 0
    local state = mod._control

    if state and state.possessed and state.controlled_normal_boss then
        count = count + 1
    end

    for _, remote_state in pairs(mod._remote_controls or {}) do
        if remote_state.possessed and remote_state.controlled_normal_boss then
            count = count + 1
        end
    end

    return count
end

function VersusModeState.auto_boss_release_blocked(state)
    if not state
        or state.auto_boss_takeover ~= true
        or gameplay_time() >= (state.auto_boss_release_block_until or 0) then
        return false
    end

    if not state.auto_boss_release_block_logged then
        state.auto_boss_release_block_logged = true
        mod:info("Versus Mode: ignored carry-over Possess input after automatic boss takeover.")
    end

    return true
end

function VersusModeState.try_assign_pending_boss()
    if not VersusModeState.allow_boss_reinforcements
        or not setting("enable_versus_mode")
        or not setting("auto_takeover_normal_bosses")
        or not is_server()
        or VersusModeState.count() == 0 then
        return false
    end

    local maximum = math_max(1, math.floor(setting("max_infected_controlled_bosses") or 1))

    if VersusModeState.controlled_boss_count() >= maximum then
        return false
    end

    local pending = mod._pending_normal_bosses

    if not pending then
        return false
    end

    local t = gameplay_time()
    local selected

    for unit, entry in pairs(pending) do
        if not unit or not ALIVE[unit] or not HEALTH_ALIVE[unit] then
            pending[unit] = nil
        else
            local eligible, _, _, weakened = VersusModeState.normal_boss_status(unit, entry.breed, entry.boss_extension)

            if not eligible then
                pending[unit] = nil
            else
                entry.weakened = weakened == true
                local control_status = VersusModeState.daemonhost_control_status(unit, entry.breed)

                if control_status == "ended" then
                    pending[unit] = nil
                elseif control_status ~= "ready" then
                    entry.retry_at = t + 0.25

                    if not entry.awaiting_wake_logged then
                        entry.awaiting_wake_logged = true
                        mod:info(
                            "Versus Mode: holding %s allocation until its native wake-up completes.",
                            tostring(entry.breed.name)
                        )
                    end
                elseif t >= (entry.retry_at or 0) and (not selected or entry.queued_at < selected.queued_at) then
                    if entry.awaiting_wake_logged and not entry.wake_ready_logged then
                        entry.wake_ready_logged = true
                        mod:info("Versus Mode: %s is fully awake and ready for allocation.", tostring(entry.breed.name))
                    end

                    selected = entry
                end
            end
        end
    end

    if not selected then
        return false
    end

    local selected_role
    local current_state

    -- Give an unoccupied infected player the boss before replacing another
    -- player's live specialist. This matters once several Realm clients can
    -- own independent control states.
    for _, role in pairs(VersusModeState.roles()) do
        local local_role = VersusModeState.local_role() == role
        local compatible_remote = role.infected_peer_id
            and mod._realms_compat
            and mod._realms_compat.peer_compatible(role.infected_peer_id)

        if role.infected_human and not role.assigned_boss_unit and (local_role or compatible_remote) then
            selected_role = role

            break
        end
    end

    if not selected_role and mod._control and mod._control.infected_spawn and not mod._control.controlled_normal_boss then
        current_state = mod._control
        selected_role = mod._control.versus_role or mod._versus_role_test
    end

    if not selected_role then
        for _, remote_state in pairs(mod._remote_controls or {}) do
            if remote_state.infected_spawn and not remote_state.controlled_normal_boss then
                current_state = remote_state
                selected_role = remote_state.versus_role

                break
            end
        end
    end

    if not selected_role then
        return false
    end

    if current_state then
        VersusModeState.release_control(
            current_state,
            selected.weakened
                and "a weakened boss spawned; previous enemy returned to AI."
                or "a full-strength boss spawned; previous enemy returned to AI.",
            true
        )
    end

    local player = selected_role.infected_player
    local local_role = VersusModeState.local_role() == selected_role
    local controller_peer_id

    -- Lua's common `condition and value or fallback` idiom cannot represent a
    -- deliberately nil value: `local_role and nil or peer_id` always chooses
    -- peer_id. That made a host-local allocation create a remote control state
    -- and left the host in free camera. Keep the two authority routes explicit.
    if not local_role then
        controller_peer_id = VersusModeState.normalize_peer_id(selected_role.infected_peer_id)
    end

    if not local_role and not controller_peer_id then
        selected.retry_at = t + 1
        mod:warning(
            "Versus Mode: deferred boss allocation for %s because the remote controller has no peer ID.",
            tostring(selected_role.infected_name or "player")
        )

        return false
    end

    mod:info(
        "Versus Mode: boss allocation route for %s is %s (selected peer: %s).",
        tostring(selected_role.infected_name or VersusModeState.player_name(player)),
        local_role and "local host control" or "remote client control",
        tostring(controller_peer_id or "none")
    )

    local possessed = player and begin_possession(
        selected.unit,
        player,
        player.player_unit,
        controller_peer_id,
        selected_role
    )
    local control_state = controller_peer_id and VersusModeState.control_for_peer(controller_peer_id) or mod._control

    if possessed and control_state then
        control_state.infected_spawn = true
        control_state.auto_boss_takeover = true
        -- The same update can finish a held Possess key after replacing the
        -- previous Specialist. Without a short guard, that release edge is
        -- applied to the brand-new boss and immediately relinquishes it.
        control_state.auto_boss_release_block_until = gameplay_time()
            + VersusModeState.auto_boss_release_guard_duration
        selected_role.assigned_boss_unit = selected.unit
        pending[selected.unit] = nil
        VersusModeState.publish_roster()

        VersusModeState.echo_localized(
            selected.weakened and "notice_weakened_boss_allocated" or "notice_full_strength_boss_allocated",
            pretty_name(selected.breed),
            selected_role.infected_name or VersusModeState.player_name(player)
        )

        return true
    end

    selected.attempts = (selected.attempts or 0) + 1
    selected.retry_at = t + 1

    if selected.attempts >= 3 then
        pending[selected.unit] = nil
        mod:warning("Versus Mode: abandoned automatic takeover of %s after three failed attempts.", selected.breed.name)
    end

    return false
end

local function prepare_native_attack(state, attack)
    local behavior_component = state.blackboard and state.blackboard.behavior

    if not behavior_component then
        return false, "behavior blackboard component unavailable"
    end

    if VersusModeState.gunner_breeds[state.breed.name] then
        behavior_component.combat_range = attack.gunner_combat_range or "far"
    elseif VersusModeState.controlled_elite_breeds[state.breed.name] then
        -- Bulwark's inner utility selector needs the native melee branch.
        behavior_component.combat_range = "melee"
    end

    if CAPTAIN_BREEDS[state.breed.name] and attack.captain_weapon_slot then
        local components_ok, phase_component, weapon_switch_component = pcall(function()
            return Blackboard.write_component(state.blackboard, "phase"),
                Blackboard.write_component(state.blackboard, "weapon_switch")
        end)

        if not components_ok or not phase_component or not weapon_switch_component then
            return false, components_ok and "Captain phase/weapon-switch component unavailable"
                or "Captain blackboard access failed: " .. tostring(phase_component)
        end

        local combat_range = attack.captain_combat_range or "melee"
        local phase_name = Specialist.captain_phase_for_slot(state, combat_range, attack.captain_weapon_slot)

        if not phase_name then
            return false, string.format(
                "Captain phase metadata missing %s in %s",
                tostring(attack.captain_weapon_slot),
                tostring(combat_range)
            )
        end

        state.captain_combat_restore = state.captain_combat_restore or {
            phase_lock = phase_component.lock,
            combat_range_lock = behavior_component.lock_combat_range_switch,
        }

        local restore = state.captain_combat_restore

        restore.safe_phase_name = phase_name
        restore.safe_weapon_slot = attack.captain_weapon_slot
        restore.safe_combat_range = combat_range

        -- Captain phases otherwise keep their currently selected ranged
        -- weapon (usually the shotgun) for 10–25 seconds. Freeze the complete
        -- phase/range pair for the possession and let the native switch action
        -- equip the breed's actual weapon before selecting its attack.
        phase_component.lock = true
        phase_component.current_phase = phase_name
        phase_component.wanted_phase = phase_name
        phase_component.exit_phase_t = math.huge
        phase_component.force_next_phase = false
        weapon_switch_component.wanted_weapon_slot = attack.captain_weapon_slot
        weapon_switch_component.wanted_combat_range = combat_range
        behavior_component.combat_range = combat_range
        behavior_component.lock_combat_range_switch = true
    elseif state.breed.name == "chaos_beast_of_nurgle" then
        behavior_component.vomit_cooldown = 0
        behavior_component.melee_cooldown = 0
        behavior_component.melee_aoe_cooldown = 0
        behavior_component.wants_to_play_alerted = false
    elseif state.breed.name == "chaos_spawn" then
        if attack.action_name == "grab" then
            behavior_component.grab_cooldown = 0
        end
    elseif (state.breed.name == "chaos_daemonhost" or state.breed.name == "chaos_mutator_daemonhost") and attack.action_name == "warp_sweep" then
        behavior_component.warp_sweep_cooldown = 0
    elseif attack.twin_grenade then
        local throw_grenade_component = state.blackboard and Blackboard.write_component(state.blackboard, "throw_grenade")

        if throw_grenade_component then
            throw_grenade_component.next_throw_at_t = 0
        end
    elseif state.breed.name == NETTER_BREED_NAME then
        behavior_component.shoot_net_cooldown = 0
        behavior_component.net_is_ready = true
        behavior_component.hit_target = false
    elseif GRENADIER_BREEDS[state.breed.name] then
        local throw_grenade_component = state.blackboard and state.blackboard.throw_grenade

        if throw_grenade_component then
            throw_grenade_component.next_throw_at_t = 0
        end

        behavior_component.combat_range = attack.grenadier_path == "close" and "close" or "far"
    elseif HOUND_BREEDS[state.breed.name] then
        local pounce_component = state.blackboard and state.blackboard.pounce

        if pounce_component then
            pounce_component.pounce_cooldown = 0
        end
    end

    local brain = state.behavior and state.behavior._brain
    local node_data = brain and brain._node_data

    if node_data then
        for _, data in pairs(node_data) do
            local utility_data = type(data) == "table" and data.utility_node_data
            local selected_data = utility_data and utility_data[attack.action_name]

            if selected_data then
                selected_data.last_time = -math.huge
                selected_data.last_done_time = -math.huge
            end

            if attack.twin_grenade and utility_data then
                local quick_throw = utility_data.quick_throw_grenade
                local multiple_throw = utility_data.multiple_quick_throw_grenade

                if quick_throw then
                    quick_throw.last_time = -math.huge
                    quick_throw.last_done_time = -math.huge
                end

                if multiple_throw then
                    multiple_throw.last_time = -math.huge
                    multiple_throw.last_done_time = -math.huge
                end
            end
        end
    end

    return true
end

local function target_name(unit)
    local player_manager = Managers.player
    local player = player_manager and player_manager.player_by_unit and player_manager:player_by_unit(unit)

    if player and player.name then
        local ok, name = pcall(player.name, player)

        if ok and name and name ~= "" then
            return name
        end
    end

    return unit and "Player" or "None"
end

local function player_side_targets(state, include_hidden_proxies)
    local extension_manager = Managers.state and Managers.state.extension
    local side_system = extension_manager and extension_manager:system("side_system")
    local boss_side = side_system and side_system.side_by_unit[state.unit]
    local candidates = boss_side and boss_side.ai_target_units
    local player_side = side_system and side_system.side_by_unit[state.player_unit]
    local player_units = player_side and player_side.player_units
    local considered = {}
    local targets = {}

    local function consider(unit)
        local eligible = include_hidden_proxies and valid_player_target(unit)
            or VersusModeState.valid_attack_target(unit, state)

        if considered[unit] or not eligible then
            return
        end

        considered[unit] = true
        targets[#targets + 1] = unit
    end

    if candidates then
        for i = 1, #candidates do
            consider(candidates[i])
        end
    end

    if player_units then
        for i = 1, #player_units do
            consider(player_units[i])
        end
    end

    consider(state.player_unit)

    local boss_position = live_world_position(state.unit)

    table.sort(targets, function(a, b)
        local a_position = live_world_position(a)
        local b_position = live_world_position(b)
        local a_distance = a_position and boss_position and vector3_distance(boss_position, a_position) or math.huge
        local b_distance = b_position and boss_position and vector3_distance(boss_position, b_position) or math.huge

        if a_distance == b_distance then
            return target_name(a) < target_name(b)
        end

        return a_distance < b_distance
    end)

    return targets
end

function VersusModeState.nearest_native_proxy(state)
    local targets = player_side_targets(state, true)

    -- Never feed the assigned infected player's isolated survivor shell back
    -- into combat. Ordinary manual testing deliberately retains that player as
    -- the final fallback because the Psykhanium often has no other player unit.
    for i = 1, #targets do
        if targets[i] ~= state.player_unit then
            return targets[i]
        end
    end

    return not state.versus_role and targets[1] or nil
end


local function nearest_attack_target(state)
    if state.locked_target and VersusModeState.valid_attack_target(state.locked_target, state) then
        return state.locked_target
    end

    local targets = player_side_targets(state)

    for i = 1, #targets do
        if targets[i] ~= state.player_unit then
            return targets[i]
        end
    end

    return targets[1]
end

-- Native specialist actions still require a real player unit as their
-- perception target. In free-aim mode choose the survivor nearest the centre
-- of the camera ray instead of silently snapping back to the nearest player.
Specialist.free_aim_attack_target = function(state)
    local aim_position, hit_unit, ray_distance = camera_aim_ray(state)

    if VersusModeState.valid_attack_target(hit_unit, state) and not VersusModeState.is_unit(hit_unit) then
        return hit_unit
    end

    local origin = state.camera_position and state.camera_position:unbox() or live_world_position(state.unit)
    local look_direction = state_look_direction(state)

    if not origin or not aim_position or not look_direction then
        return nil
    end

    look_direction = vector3_normalize(look_direction)

    local targets = player_side_targets(state)
    local best_target
    local best_dot = Specialist.free_aim_min_dot
    local best_distance = math.huge

    for i = 1, #targets do
        local target = targets[i]

        if not VersusModeState.is_unit(target) then
            local target_position = node_world_position(target, Specialist.hound_settings.leap_target_node_name)
                or live_world_position(target)

            if target_position then
                local offset = target_position - origin
                local distance = vector3_length(offset)

                -- When the camera ray stopped on level geometry, do not select
                -- a similarly aligned survivor hidden behind that obstruction.
                if distance > 0.01 and (not ray_distance or distance <= ray_distance + 1) then
                    local dot = vector3_dot(vector3_normalize(offset), look_direction)

                    if dot > best_dot or dot == best_dot and distance < best_distance then
                        best_target = target
                        best_dot = dot
                        best_distance = distance
                    end
                end
            end
        end
    end

    return best_target
end

function Specialist.direct_attack_active(state, unit, kind)
    local attack = state and state.requested_attack

    return state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == kind
        or false
end

function Specialist.camera_melee_active(state, unit)
    local attack = state and state.requested_attack

    return Specialist.direct_attack_active(state, unit, "specialist_melee")
        or state
            and state.unit == unit
            and state.attack_deadline
            and Specialist.free_aim(state)
            and attack
            and attack.free_aim_melee == true
        or false
end

function Specialist.stationary_melee_active(state, unit)
    local attack = state and state.requested_attack

    return state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and attack.stationary == true
        or false
end

function Specialist.flamer_aim_position(state)
    if state and state.manual_aim_position then
        return state.manual_aim_position
    end

    local cached = state and state.flamer_last_aim_position

    if cached then
        local ok, aim_position = pcall(cached.unbox, cached)

        return ok and aim_position or nil
    end

    return nil
end

function Specialist.flamer_shot_positions(state, unit, action_data)
    local live_aim_position, hit_unit, camera_distance = camera_aim_ray(state)
    local aim_position = live_aim_position or Specialist.flamer_aim_position(state)
    local unit_position = live_world_position(unit)

    if not aim_position or not unit_position then
        return nil
    end

    local look_direction, flat_forward = state_look_direction(state)
    local offset = aim_position - unit_position
    local distance = vector3_length(offset)
    local max_range = action_data.range or distance
    local min_range = action_data.min_range or 0
    local range_margin = math_min(0.1, math_max(0, max_range - min_range) * 0.25)
    local safe_max_range = max_range - range_margin
    local safe_min_range = min_range + range_margin

    -- Native liquid-beam run() rejects strict >max and <min distances. Using
    -- the exact boundary lets camera/unit movement and float quantization push
    -- the proxy outside on the next line, ending an otherwise healthy stream.
    if distance > safe_max_range and distance > 0.01 then
        aim_position = unit_position + vector3_normalize(offset) * safe_max_range
        distance = safe_max_range
    elseif distance < safe_min_range then
        aim_position = unit_position + vector3_normalize(look_direction) * safe_min_range
        distance = safe_min_range
    end

    local flat_offset = Vector3.flat(aim_position - unit_position)
    local flat_direction = vector3_length(flat_offset) > 0.01 and vector3_normalize(flat_offset)
        or vector3_normalize(flat_forward)
    local range_percentage_front = action_data.range_percentage_front or 0
    local shot_from = aim_position - flat_direction * (distance * range_percentage_front)
    local shot_to = aim_position + flat_direction * (action_data.range_back or 0)

    state.manual_aim_position = aim_position
    state.flamer_last_aim_position = state.flamer_last_aim_position or Vector3Box(aim_position)
    state.flamer_last_aim_position:store(aim_position)

    if live_aim_position then
        state.manual_aim_hit_unit = hit_unit
        state.manual_aim_distance = camera_distance
    end

    return shot_from, shot_to, look_direction
end

function Specialist.camera_proxy_target_position(state, unit, target)
    local unit_position = live_world_position(unit)
    local target_position = live_world_position(target)

    if not unit_position or not target_position then
        return nil
    end

    local attack = state.requested_attack
    local free_aim_melee = attack and attack.free_aim_melee == true
    local yaw = state.command_aim_yaw or state.yaw
    local pitch = free_aim_melee and 0 or state.command_aim_pitch or state.pitch
    local pitch_cos = math_cos(pitch)
    local direction = Vector3(math_sin(yaw) * pitch_cos, math_cos(yaw) * pitch_cos, math_sin(pitch))
    local distance = free_aim_melee and (attack.range_max or 3)
        or math_max(0.1, vector3_distance(unit_position, target_position))

    return unit_position + vector3_normalize(direction) * distance
end

function Specialist.spawn_leap_flight_time(start_position, landing_position, velocity)
    local gravity = ChaosSpawnSettings.leap_gravity

    if not start_position or not landing_position or not velocity or not gravity or gravity <= 0 then
        return nil
    end

    local vertical_speed = Vector3.z(velocity)
    local height_delta = Vector3.z(landing_position) - Vector3.z(start_position)
    local discriminant = vertical_speed * vertical_speed - 2 * gravity * height_delta

    if discriminant < 0 then
        return nil
    end

    local flight_time = (vertical_speed + math.sqrt(discriminant)) / gravity

    return flight_time > 0 and flight_time or nil
end

function Specialist.controlled_spawn_leap_solver_speed(self_position, target_position, action_data)
    local native_speed = ChaosSpawnSettings.leap_speed
    local gravity = ChaosSpawnSettings.leap_gravity

    if type(native_speed) ~= "number"
        or native_speed <= 0
        or not self_position
        or not target_position
        or type(gravity) ~= "number"
        or gravity <= 0 then
        return native_speed
    end

    local request_offset = target_position - self_position
    local request_distance = vector3_length(request_offset)
    local short_distance = ChaosSpawnSettings.short_leap_distance or 16

    -- Preserve the exact native solve for the short range already proven in
    -- 0.11.46. Only the authored long-range branch needs more launch speed.
    if request_distance <= short_distance then
        return native_speed
    end

    local start_offset = action_data and action_data.start_offset_distance or 0
    local target_offset = ChaosSpawnSettings.offset_in_front_of_target or 0
    local solve_offset = request_offset
        - vector3_normalize(request_offset) * (start_offset + target_offset)
    local horizontal_distance = math_max(0.01, vector3_length(Vector3.flat(solve_offset)))
    local height_delta = Vector3.z(solve_offset)
    -- Minimum launch speed for a ballistic arc connecting points separated by
    -- horizontal distance x and height y:
    -- v^2 = g * (y + sqrt(x^2 + y^2)).
    local minimum_speed_squared = gravity * (
        height_delta
        + math.sqrt(horizontal_distance * horizontal_distance + height_delta * height_delta)
    )

    if minimum_speed_squared <= 0 then
        return native_speed
    end

    local margin = Specialist.spawn_leap_solver_speed_margin or 1
    local requested_speed = math_max(native_speed, math.sqrt(minimum_speed_squared) * margin)
    local maximum_speed = math_max(
        native_speed,
        Specialist.spawn_leap_max_clearance_speed or native_speed
    )

    return math_min(requested_speed, maximum_speed)
end

function Specialist.spawn_leap_swept_impact(scratchpad, velocity, flight_time, landing_position)
    local start_box = scratchpad and scratchpad.leap_start_position
    local start_position = start_box and start_box:unbox()
    local flat_velocity = velocity and Vector3.flat(velocity)
    local flat_speed = flat_velocity and vector3_length(flat_velocity) or 0

    if not start_position
        or not scratchpad.physics_world
        or not landing_position
        or not flight_time
        or flight_time <= 0
        or flat_speed <= 0.01 then
        return nil, nil, nil
    end

    local sweep_t = 0
    local sweep_end_t = flight_time + Specialist.spawn_leap_landing_probe_time
    local sweep_interval = math_max(0.01, Specialist.spawn_leap_sweep_interval or 0.05)
    local direction = vector3_normalize(flat_velocity)
    local last_position

    -- Mirror BtLeapAction's airborne loop with short consecutive samples so
    -- prediction and execution stop at the same first collision and expose
    -- comparable diagnostics for every part of the arc.
    while sweep_t < sweep_end_t do
        local next_t = math_min(sweep_t + sweep_interval, sweep_end_t)
        local hit_position, hit_normal, new_position = Trajectory.sphere_sweep_collision_check(
            scratchpad.physics_world,
            start_position,
            direction,
            flat_speed,
            Vector3.z(velocity),
            ChaosSpawnSettings.leap_gravity,
            ChaosSpawnSettings.trajectory_radius,
            ChaosSpawnSettings.trajectory_collision_filter,
            sweep_t,
            next_t,
            false
        )

        last_position = hit_position or new_position or last_position

        if hit_position then
            local impact_error = vector3_length(Vector3.flat(landing_position - hit_position))

            return hit_position, impact_error, hit_normal
        end

        sweep_t = next_t
    end

    local impact_error = last_position
        and vector3_length(Vector3.flat(landing_position - last_position))

    return nil, impact_error, nil
end

function Specialist.spawn_leap_native_path_is_effective(scratchpad, target_position, action_data)
    local velocity_box = scratchpad and scratchpad.leap_velocity
    local start_box = scratchpad and scratchpad.leap_start_position
    local velocity = velocity_box and velocity_box:unbox()
    local start_position = start_box and start_box:unbox()

    if not velocity or not start_position or not target_position then
        return true, nil
    end

    local flat_offset = Vector3.flat(target_position - start_position)
    local flat_distance = vector3_length(flat_offset)

    if flat_distance <= 0.01 then
        return true, nil
    end

    local direction = vector3_normalize(flat_offset)
    local landing_position = target_position
        - direction * ChaosSpawnSettings.offset_in_front_of_target
    local flight_time = Specialist.spawn_leap_flight_time(start_position, landing_position, velocity)

    if not flight_time then
        return true, nil
    end

    local hit_position, impact_error = Specialist.spawn_leap_swept_impact(
        scratchpad,
        velocity,
        flight_time,
        target_position
    )
    local impact_data = action_data and action_data.catapult_or_push_players
    local impact_radius = impact_data and impact_data.radius or 4

    -- Preserve 0.11.25/Darktide's known-good unobstructed three-metre stand-off.
    -- Only an actual first collision outside the authored damage radius needs
    -- replacement; repaired arcs below use the tighter target tolerance.
    return hit_position and impact_error and impact_error <= impact_radius,
        impact_error,
        impact_radius
end

function Specialist.controlled_spawn_leap_clearance_solution(scratchpad, target_position, action_data)
    local start_box = scratchpad and scratchpad.leap_start_position
    local start_position = start_box and start_box:unbox()
    local gravity = ChaosSpawnSettings.leap_gravity

    if not start_position or not target_position or not gravity or gravity <= 0 then
        return nil
    end

    local flat_offset = Vector3.flat(target_position - start_position)
    local target_distance = vector3_length(flat_offset)

    if target_distance <= 0.01 then
        return nil
    end

    local direction = vector3_normalize(flat_offset)
    local landing_position = target_position
        - direction * Specialist.spawn_leap_target_offset
    local landing_distance = vector3_length(Vector3.flat(landing_position - start_position))
    local start_height = Vector3.z(start_position)
    local landing_height = Vector3.z(landing_position)
    local impact_data = action_data and action_data.catapult_or_push_players
    local impact_radius = impact_data and impact_data.radius or 4
    local target_tolerance = math_min(impact_radius, Specialist.spawn_leap_target_tolerance)
    local maximum_time = ChaosSpawnSettings.leap_max_time_in_flight or 3
    local best_solution

    for i = 1, #Specialist.spawn_leap_clearance_heights do
        local clearance_height = Specialist.spawn_leap_clearance_heights[i]
        local apex_height = math_max(start_height, landing_height) + clearance_height
        local ascent = math.sqrt(2 * (apex_height - start_height) / gravity)
        local descent = math.sqrt(2 * (apex_height - landing_height) / gravity)
        local flight_time = ascent + descent
        local flat_speed = landing_distance / flight_time
        local vertical_speed = gravity * ascent
        local velocity = direction * flat_speed + Vector3(0, 0, vertical_speed)
        local total_speed = vector3_length(velocity)

        if flight_time <= maximum_time and total_speed <= Specialist.spawn_leap_max_clearance_speed then
            local hit_position, impact_error = Specialist.spawn_leap_swept_impact(
                scratchpad,
                velocity,
                flight_time,
                target_position
            )

            if hit_position
                and impact_error
                and impact_error <= target_tolerance
                and (not best_solution or impact_error < best_solution.impact_error) then
                best_solution = {
                    clearance_height = clearance_height,
                    flight_time = flight_time,
                    impact_error = impact_error,
                    impact_radius = target_tolerance,
                    landing_offset = Specialist.spawn_leap_target_offset,
                    speed = total_speed,
                    velocity = velocity,
                }
            end
        end
    end

    return best_solution
end

-- Navigation normally publishes the Chaos Spawn's 6 m/s run-speed ceiling.
-- BtLeapAction is script-driven at 15 m/s, but a possessed unit retains that
-- navigation extension and the locomotion layer clamps the requested ballistic
-- correction to the published ceiling. Isolate the native action from the nav
-- writer and raise only this command's ceiling; leave() restores both values.
function Specialist.suspend_controlled_spawn_leap_navigation(state, scratchpad)
    if not state or not scratchpad or scratchpad.versus_mode_spawn_leap_motion then
        return false
    end

    local navigation = state.navigation

    if not navigation then
        return false
    end

    local enabled_ok, was_enabled = safe_extension_call(navigation, "enabled")
    local speed_ok, previous_max_speed = safe_extension_call(navigation, "max_speed")

    if not enabled_ok then
        was_enabled = navigation._enabled ~= false
    end

    if not speed_ok or type(previous_max_speed) ~= "number" then
        previous_max_speed = state.old_max_speed
            or state.breed and state.breed.run_speed
            or ChaosSpawnSettings.leap_speed
    end

    local speed_ceiling = math_max(
        previous_max_speed or 0,
        ChaosSpawnSettings.leap_speed or 0,
        Specialist.spawn_leap_max_clearance_speed or 0,
        Specialist.spawn_leap_motion_speed_ceiling or 0
    )
    local motion = {
        navigation = navigation,
        previous_max_speed = previous_max_speed,
        speed_ceiling = speed_ceiling,
        state = state,
        was_enabled = was_enabled == true,
    }

    scratchpad.versus_mode_spawn_leap_motion = motion
    state.spawn_leap_motion_scratchpad = scratchpad

    local ceiling_applied = safe_extension_call(navigation, "set_max_speed", speed_ceiling)
    local navigation_suspended = safe_extension_call(navigation, "set_enabled", false)

    mod:info(
        "Versus Mode: Chaos Spawn Leap isolated native locomotion (navigation ceiling %.2f -> %.2f m/s, suspended=%s).",
        previous_max_speed or -1,
        speed_ceiling,
        tostring(navigation_suspended == true)
    )

    return ceiling_applied == true and navigation_suspended == true
end

function Specialist.restore_controlled_spawn_leap_navigation(scratchpad)
    local motion = scratchpad and scratchpad.versus_mode_spawn_leap_motion

    if not motion or motion.restored then
        return false
    end

    motion.restored = true

    local navigation = motion.navigation

    if navigation then
        safe_extension_call(navigation, "set_max_speed", motion.previous_max_speed)
        safe_extension_call(
            navigation,
            "set_enabled",
            motion.was_enabled,
            motion.previous_max_speed
        )
    end

    local state = motion.state

    if state and state.spawn_leap_motion_scratchpad == scratchpad then
        state.spawn_leap_motion_scratchpad = nil
    end

    scratchpad.versus_mode_spawn_leap_motion = nil

    return true
end

-- Preview a camera-directed ballistic arc at the Hound's native leap speed and
-- gravity. Hold Charge maps an authoritative normalized charge to a bounded
-- launch pitch below 45 degrees, so height and flat-ground distance rise
-- together while camera pitch remains free. The legacy mode still accepts the
-- camera pitch directly. Neither path selects or tracks a survivor.
Specialist.hound_pounce_solution = function(state, preferred_yaw, preferred_pitch, charge_fraction)
    local start_position = live_world_position(state.unit)

    if not state.physics_world or not start_position then
        return nil
    end

    start_position = start_position + Vector3(0, 0, 0.1)
    local yaw = type(preferred_yaw) == "number" and preferred_yaw or state.yaw
    local pitch = type(preferred_pitch) == "number" and preferred_pitch or state.pitch

    if type(charge_fraction) == "number" then
        charge_fraction = math_max(0, math_min(1, charge_fraction))
        pitch = Specialist.hound_charge_pitch(charge_fraction)
    else
        charge_fraction = nil
    end

    if yaw ~= yaw or pitch ~= pitch or math.abs(yaw) > 1000000 or math.abs(pitch) > 1000000 then
        return nil
    end

    yaw = (yaw + math.pi) % (math.pi * 2) - math.pi
    pitch = math_max(-0.9, math_min(1.05, pitch))

    local flat_direction = Vector3(math_sin(yaw), math_cos(yaw), 0)
    local pitch_cos = math_cos(pitch)
    local launch_direction = Vector3(
        Vector3.x(flat_direction) * pitch_cos,
        Vector3.y(flat_direction) * pitch_cos,
        math_sin(pitch)
    )
    local velocity = vector3_normalize(launch_direction) * Specialist.hound_settings.leap_speed
    local flat_speed = vector3_length(Vector3.flat(velocity))
    local vertical_speed = Vector3.z(velocity)

    if flat_speed <= 0.01 then
        return nil
    end

    local max_time = math_min(Specialist.hound_preview_max_time, Specialist.hound_settings.leap_max_time_in_flight)
    local sample_interval = Specialist.hound_preview_sample_interval
    local points = { Vector3Box(start_position) }
    local impact_position
    local flight_time = 0

    for i = 1, Specialist.hound_preview_max_points - 1 do
        local next_time = math_min(i * sample_interval, max_time)
        local hit_position, _, new_position = Trajectory.sphere_sweep_collision_check(
            state.physics_world,
            start_position,
            flat_direction,
            flat_speed,
            vertical_speed,
            Specialist.hound_settings.leap_gravity,
            Specialist.hound_settings.leap_radius,
            Specialist.hound_settings.leap_collision_filter,
            flight_time,
            next_time,
            false
        )
        local point = new_position or hit_position

        if not point then
            break
        end

        points[#points + 1] = Vector3Box(point)
        flight_time = next_time

        if hit_position then
            impact_position = point
            break
        elseif next_time >= max_time then
            break
        end
    end

    impact_position = impact_position or points[#points]:unbox()

    return {
        valid = #points >= 2,
        has_impact = impact_position ~= nil,
        points = points,
        impact_position = Vector3Box(impact_position),
        launch_velocity = Vector3Box(velocity),
        yaw = yaw,
        pitch = pitch,
        charge_fraction = charge_fraction,
        flight_time = flight_time,
        trajectory_kind = "POUNCE",
        show_area = false,
        distance = vector3_distance(start_position, impact_position),
    }
end

-- A contextual primary never chains two independently selected actions. It
-- swaps the command before the behavior tree is evaluated, so a native
-- charge/leap sequence remains one atomic action with its own hit follow-up.
function Specialist.casual_attacks_for_state(state, advanced_attacks)
    local config = state and state.breed and Specialist.casual_configs[state.breed.name]

    if not config then
        return nil
    end

    local signature = config.signature
        or config.signature_slot and advanced_attacks and advanced_attacks[config.signature_slot]
    local signature_overrides = {
        casual_command = true,
        casual_signature = true,
        force_utility = true,
    }

    if config.signature_range_max then
        signature_overrides.range_max = config.signature_range_max
        signature_overrides.range_text = string.format("0–%g m", config.signature_range_max)
        signature_overrides.strict_range = true
    end

    return {
        primary = Specialist.copy_attack(Specialist.casual_primary_attack, {
            selector_name = config.selector_name,
        }),
        heavy = Specialist.copy_attack(signature, signature_overrides),
    }
end

function Specialist.casual_command_target(state, preferred_target)
    if VersusModeState.valid_attack_target(preferred_target, state)
        and not VersusModeState.is_unit(preferred_target) then
        return preferred_target
    end

    if VersusModeState.valid_attack_target(state.locked_target, state) then
        return state.locked_target
    end

    return nearest_attack_target(state)
end

function Specialist.casual_nearby_target_count(state, radius)
    local origin = state and live_world_position(state.unit)
    local count = 0

    if not origin then
        return count
    end

    local targets = player_side_targets(state)

    for i = 1, #targets do
        local position = live_world_position(targets[i])

        if position and vector3_distance(origin, position) <= radius then
            count = count + 1
        end
    end

    return count
end


-- Spawn Leap, Beast branches and Captain weapon switching sit outside a single
-- utility selector, so resolve only those first branch choices at button press.
-- A Captain uses its verified shotgun/plasma slot at mid range, melee at close
-- range and Charge beyond the firearm's useful range. Other Captain firearms
-- remain Advanced-only. Beast chooses its close AOE for a group and otherwise
-- uses Vomit when the target is visible.
function Specialist.resolve_immediate_casual_primary(state, attack, preferred_target)
    if not attack or not attack.casual_primary or not Specialist.casual_supported(state) then
        return attack
    end

    local config = Specialist.casual_configs[state.breed.name]
    local target = Specialist.casual_command_target(state, preferred_target)
    local origin = live_world_position(state.unit)
    local target_position = live_world_position(target)
    local distance = origin and target_position and vector3_distance(origin, target_position)

    if config.captain then
        local advanced = attacks_for_state(state) or {}
        local primary = advanced.primary
        local ordinary = advanced.heavy
        local ranged = advanced.special
        local charge = primary and primary.contextual_attack
        local melee_range = primary and math_max(primary.range_max or 0, ordinary and ordinary.range_max or 0)
        local ranged_slot = ranged and ranged.captain_weapon_slot
        local casual_ranged = (ranged_slot == "slot_shotgun" or ranged_slot == "slot_plasma_pistol")
            and ranged

        if casual_ranged
            and distance
            and melee_range
            and distance > melee_range
            and distance <= (casual_ranged.range_max or math.huge) then
            return Specialist.copy_attack(casual_ranged, {
                casual_command = true,
                casual_selected = true,
                force_utility = true,
                native_ai = true,
                range_min = melee_range,
                range_min_exclusive = true,
                requires_line_of_sight = true,
                single_shoot_cycle = true,
                strict_range = true,
            })
        end

        if charge and distance and distance >= (charge.range_min or melee_range or 0) then
            return Specialist.copy_attack(charge, {
                casual_command = true,
                casual_selected = true,
            })
        end

        if not primary or not ordinary or not primary.captain_weapon_slot then
            return nil
        end

        local selector_name = primary.captain_weapon_slot == "slot_power_sword"
            and "power_sword_melee_combat" or "powermaul_melee_combat"
        local range_max = math_max(primary.range_max or 0, ordinary.range_max or 0)

        return Specialist.copy_attack(attack, {
            captain_weapon_slot = primary.captain_weapon_slot,
            -- The native Captain root must finish its authored weapon switch
            -- before the melee utility selector exists. Give that selector
            -- the same full acquisition allowance as the individual attack
            -- instead of expiring the Casual envelope after three seconds.
            acquire_timeout = primary.acquire_timeout or 12,
            casual_actions = {
                [primary.action_name] = primary,
                [ordinary.action_name] = ordinary,
            },
            range_max = range_max,
            range_text = string.format("0–%g m", range_max),
            selector_name = selector_name,
            strict_range = true,
        })
    elseif state.breed.name == "chaos_spawn"
        and distance
        and distance >= ChaosSpawnSettings.min_leap_distance
        and distance <= Specialist.spawn_leap_command_max_distance then
        return Specialist.copy_attack(ATTACKS.chaos_spawn.special, {
            casual_command = true,
            casual_selected = true,
            native_ai = true,
        })
    elseif config.immediate_primary then
        local attacks = ATTACKS.chaos_beast_of_nurgle
        local line_of_sight_ok, has_line_of_sight = safe_extension_call(
            state.perception,
            "immediate_line_of_sight_check",
            target
        )
        local grouped = Specialist.casual_nearby_target_count(state, 4.75) >= 2
        local body_slam = distance and distance <= 4.75
            and (grouped or VersusModeState.target_has_beast_vomit(target, state) or not (line_of_sight_ok and has_line_of_sight))

        if body_slam then
            return Specialist.copy_attack(attacks.heavy, {
                casual_command = true,
                casual_selected = true,
                range_max = 4.75,
                range_text = "0–4.75 m",
                strict_range = true,
            })
        end

        return Specialist.copy_attack(attacks.primary, {
            casual_command = true,
            casual_selected = true,
            range_max = 10,
            range_text = "0–10 m",
            requires_line_of_sight = true,
            strict_range = true,
        })
    end

    return attack
end

local function resolved_attacks_for_state(state)
    local attacks = attacks_for_state(state)

    if state and state.casual_combat == true and Specialist.casual_supported(state) then
        return Specialist.casual_attacks_for_state(state, attacks)
    end

    local primary = attacks and attacks.primary
    local contextual_attack = primary and primary.contextual_attack

    if not contextual_attack then
        return attacks
    end

    local target = nearest_attack_target(state)
    local unit_position = live_world_position(state.unit)
    local target_position = live_world_position(target)
    local distance = unit_position and target_position and vector3_distance(unit_position, target_position)
    local switch_distance = primary.context_switch_distance or primary.range_max or contextual_attack.range_min

    if not distance or not switch_distance or distance <= switch_distance then
        return attacks
    end

    return {
        primary = contextual_attack,
        heavy = attacks.heavy,
        alternate = attacks.alternate,
        special = attacks.special,
    }
end

local OFFENSIVE_ACTION_PATTERNS = {
    "attack",
    "shoot",
    "slam",
    "stomp",
    "charge",
    "grab",
    "pounce",
    "kick",
    "leap",
    "sweep",
    "cleave",
    "pommel",
    "punch",
    "throw_",
    "vomit",
    "consume",
    "spit_out",
    "shoot_net",
    "void_shield_explosion",
    "explode",
    "summon",
    "dash",
    "warp_",
    "spray",
    "grenade",
}

local function running_offensive_action(state)
    local ok, action_name, action_data = pcall(function()
        local brain = state.behavior and state.behavior._brain

        if brain then
            return brain:running_action()
        end
    end)

    if not ok or not action_name then
        return false
    end

    -- Adaptive is only a request envelope, not an action. A generated parent
    -- selector can have "attack" in its running name before the whitelisted
    -- child has been chosen; counting that as execution produces the misleading
    -- "Started Adaptive Attack" notice and disables the short acquire timeout.
    -- Daemonhost is the deliberate exception: its generated root preempts the
    -- melee utility selector with warp_grab_teleport when the target is downed.
    -- That native finisher must keep the brain awake through teleport, channel
    -- and execution instead of expiring with the three-second envelope.
    if state.requested_attack and state.requested_attack.casual_primary then
        return VersusModeState.daemonhost_adaptive_execution_action(state, action_name)
    end

    if state.requested_attack
        and state.requested_attack.casual_selected
        and state.requested_attack.action_name
        and action_name ~= state.requested_attack.action_name then
        return false
    end

    -- A target-locked Pox Burster's native Primary starts in `approach` and
    -- later transitions to its lunge/fuse. Treat that complete native leaf as
    -- the commanded attack; otherwise the generic acquisition timeout stops
    -- it after four seconds before it can reach lunge range.
    if action_name == "approach"
        and state.requested_attack
        and state.requested_attack.direct_native == "poxburster" then
        return true
    end

    if action_data and (action_data.damage_profile or action_data.attack_anim or action_data.attack_anim_events or action_data.attack_type) then
        return true
    end

    for i = 1, #OFFENSIVE_ACTION_PATTERNS do
        if string.find(action_name, OFFENSIVE_ACTION_PATTERNS[i], 1, true) then
            return true
        end
    end

    return false
end

function VersusModeState.spawn_leap_interrupted(state)
    local attack = state and state.requested_attack
    local stagger = state and state.blackboard and state.blackboard.stagger

    return state ~= nil
        and state.attack_started == true
        and state.breed
        and state.breed.name == "chaos_spawn"
        and attack
        and attack.action_name == "leap"
        and stagger
        and stagger.num_triggered_staggers > 0
end

function VersusModeState.hound_pounce_in_progress(state)
    if not state
        or not state.attack_deadline
        or not state.breed
        or not HOUND_BREEDS[state.breed.name]
        or not state.hound_manual_pounce_active then
        return false
    end

    local pounce_component = state.blackboard and state.blackboard.pounce

    return pounce_component ~= nil
        and (pounce_component.started_leap == true
            or pounce_component.pounce_target ~= nil)
end

function VersusModeState.attack_command_should_stop(state, t, attacking)
    if not state or not state.attack_deadline then
        return false
    end

    local hard_timeout = state.attack_hard_deadline
        and t >= state.attack_hard_deadline
        and not state.poxburster_armed
    local action_finished = state.attack_started
        and t >= (state.attack_min_until or 0)
        and not attacking

    return hard_timeout or action_finished
end

function VersusModeState.refresh_control_animation(state)
    if not state
        or not state.possessed
        or not ALIVE[state.unit]
        or state.remote_client
        or state.attack_deadline
        or state.controlled_traversal
        or state.poxburster_armed
        or running_offensive_action(state) then
        return false
    end

    local event_name = state.moving and "move_fwd" or "idle"
    local reason = state.animation_heartbeat_reason

    -- Replaying the same locomotion event every 0.75 seconds restarts some
    -- minion state machines at the same frame, which looks exactly like a
    -- frozen pose on a Realms client. Edge-trigger normal locomotion below;
    -- only a diagnosed camera/stream transition may request one explicit
    -- same-state resync.
    if not reason and state.animation_heartbeat_last_event == event_name then
        return false
    end

    state.animation = safe_extension(state.unit, "animation_system") or state.animation
    local sent = safe_extension_call(state.animation, "anim_event", event_name)

    if sent then
        mod:info(
            "Versus Mode: locomotion animation synchronized to %s for %s%s.",
            event_name,
            tostring(state.breed and state.breed.name or "controlled enemy"),
            reason and " after " .. tostring(reason) or ""
        )
    end

    state.animation_heartbeat_last_event = event_name
    state.animation_heartbeat_reason = nil

    return sent
end

function VersusModeState.target_has_beast_vomit(unit, state)
    if not VersusModeState.valid_attack_target(unit, state) then
        return false
    end

    local buff_extension = safe_extension(unit, "buff_system")

    if not buff_extension then
        return false
    end

    local ok, stacks = pcall(buff_extension.current_stacks, buff_extension, "chaos_beast_of_nurgle_hit_by_vomit")

    -- The forced Consume branch uses beast_of_nurgle_should_eat, whose native
    -- requirement is any non-zero vomit stack. Three stacks belong to the
    -- separate autonomous dash-and-consume selector.
    return ok and stacks and stacks > 0
end

local function active_summoned_hound_count(state)
    local summoned_minions_extension = safe_extension(state.unit, "summon_minions_system")

    if not summoned_minions_extension then
        return nil
    end

    local ok, summoned_minions = safe_extension_call(summoned_minions_extension, "summoned_minions")

    if not ok or type(summoned_minions) ~= "table" then
        return nil
    end

    local alive = 0

    for i = 1, #summoned_minions do
        if HEALTH_ALIVE[summoned_minions[i]] then
            alive = alive + 1
        end
    end

    return alive
end

local function start_attack_burst(state, attack, preferred_target, hound_aim_yaw, hound_aim_pitch, hound_charge_fraction)
    if state.attack_deadline then
        set_status(state, "Attack already in progress", 1.5)

        return
    end

    local t = gameplay_time()
    local hound_solution
    local command_free_aim = Specialist.free_aim(state) and attack.camera_directed

    if attack.cooldown_duration and t < (state.netter_fire_cooldown_until or 0) then
        local remaining = state.netter_fire_cooldown_until - t

        set_status(state, mod:localize("variant_attack_cooldown", remaining), remaining)

        return
    end

    if attack.manual_range_max then
        local aim_distance = state.manual_aim_distance

        if not aim_distance then
            set_status(state, mod:localize("variant_attack_no_aim"), 2.5)

            return
        elseif aim_distance > attack.manual_range_max then
            set_status(state, mod:localize("variant_attack_out_of_range", aim_distance, attack.manual_range_max), 2.5)

            return
        end
    end

    if Specialist.free_aim(state)
        and attack.native_ai
        and not attack.direct_native
        and not attack.manual_aim then
        local message = mod:localize("free_aim_attack_unsupported")

        set_status(state, message, 2.5)
        VersusModeState.echo_notice(message)

        return
    end

    if attack.hound_trajectory or attack.hound_instant_pounce then
        hound_solution = Specialist.hound_pounce_solution(
            state,
            hound_aim_yaw,
            hound_aim_pitch,
            attack.hound_trajectory and hound_charge_fraction or nil
        )

        if not hound_solution or not hound_solution.valid or not hound_solution.launch_velocity then
            set_status(state, mod:localize("hound_no_valid_trajectory"), 2.5)
            VersusModeState.echo_localized("hound_no_valid_trajectory")

            return
        end
    end

    if attack.summon_hounds then
        local active_hounds = active_summoned_hound_count(state)

        if active_hounds == nil then
            set_status(state, "Hound summon state unavailable", 2.5)

            return
        elseif active_hounds > 0 then
            set_status(state, string.format("%d summoned hound%s still active", active_hounds, active_hounds == 1 and "" or "s"), 2.5)

            return
        end

    end

    if attack.summon_hounds
        or state.breed.name == "chaos_spawn" and attack.action_name == "leap"
        or HOUND_BREEDS[state.breed.name]
            and (attack.hound_trajectory or attack.hound_instant_pounce) then
        -- A completed or interrupted summon, Spawn Leap, or Hound pounce can
        -- leave its root child link and scratchpad behind while the possessed
        -- brain is disabled. Every button press is a fresh one-action command,
        -- so clear only that inactive tree state before enabling it.
        if HOUND_BREEDS[state.breed.name] then
            VersusModeState.reset_hound_pounce_motion(state)
        end

        if state.spawn_leap_motion_scratchpad then
            Specialist.restore_controlled_spawn_leap_navigation(state.spawn_leap_motion_scratchpad)
        end

        local brain = state.behavior and state.behavior._brain

        if brain then
            if brain.leave_state then
                local left_state = pcall(brain.leave_state, brain)

                if not left_state then
                    brain._running_state_node = nil
                end
            else
                brain._running_state_node = nil
            end

            if brain._scratchpad then
                table.clear(brain._scratchpad)
            end

            if brain._running_child_nodes then
                table.clear(brain._running_child_nodes)
            end

            if brain._old_running_child_nodes then
                table.clear(brain._old_running_child_nodes)
            end

            brain._running_leaf_node = nil
            brain._running_leaf_node_result = "running"
            brain._evaluate_utility = true
        end
    end

    if state.breed.name == SNIPER_BREED_NAME and not attack.laser_only and t < (state.sniper_fire_cooldown_until or 0) then
        local remaining = state.sniper_fire_cooldown_until - t

        set_status(state, string.format("Longlas cooldown: %.1f s", remaining), remaining)

        return
    end

    -- Sniper and Netter manual aim are intentionally not target locks. Their
    -- native shoot actions still need a valid perception target internally,
    -- but the projectile direction comes exclusively from the camera ray.
    local manual_aim_proxy = MANUAL_AIM_BREEDS[state.breed.name] and attack.manual_aim
    local free_aim_grenade_proxy = GRENADIER_BREEDS[state.breed.name]
        and attack.grenadier_path == "far"
        and state.grenadier_target_lock == false
    local target

    if attack.hound_trajectory or attack.hound_instant_pounce then
        -- The native leap action still needs a living player as an internal
        -- behavior-tree proxy, but this target never determines the manual
        -- launch direction or who can be hit along the arc.
        target = VersusModeState.nearest_native_proxy(state)
    elseif VersusModeState.valid_attack_target(preferred_target, state) and not VersusModeState.is_unit(preferred_target) then
        target = preferred_target
    elseif manual_aim_proxy or free_aim_grenade_proxy or command_free_aim then
        target = VersusModeState.nearest_native_proxy(state)
    elseif attack.manual_aim and VersusModeState.valid_attack_target(state.manual_aim_hit_unit, state) then
        target = state.manual_aim_hit_unit
    elseif Specialist.free_aim(state) then
        target = Specialist.free_aim_attack_target(state)
    elseif VersusModeState.valid_attack_target(state.locked_target, state) then
        target = state.locked_target
    else
        target = nearest_attack_target(state)
    end

    if not target then
        VersusModeState.echo_localized("hud_no_valid_target")
        set_status(state, "No valid target", 2.5)

        return
    end

    if attack.strict_range and not (command_free_aim and attack.free_aim_melee) then
        local unit_position = live_world_position(state.unit)
        local target_position = live_world_position(target)
        local target_distance = unit_position and target_position and vector3_distance(unit_position, target_position)
        local too_close = attack.range_min and target_distance and (
            attack.range_min_exclusive and target_distance <= attack.range_min
            or not attack.range_min_exclusive and target_distance < attack.range_min
        )
        local too_far = attack.range_max and target_distance and target_distance > attack.range_max

        if not target_distance then
            set_status(state, "Target distance unavailable", 2.5)

            return
        elseif too_close then
            set_status(state, string.format("%s is too close (%.1f m)", attack.label, target_distance), 2.5)

            return
        elseif too_far then
            set_status(state, string.format("%s is too far (%.1f m)", attack.label, target_distance), 2.5)

            return
        elseif attack.requires_line_of_sight then
            local ok, has_line_of_sight = safe_extension_call(state.perception, "immediate_line_of_sight_check", target)

            if not ok or not has_line_of_sight then
                set_status(state, attack.label .. " requires line of sight", 2.5)

                return
            end
        end
    end

    if CAPTAIN_BREEDS[state.breed.name] and attack.captain_weapon_slot then
        if not captain_has_weapon_slot(state, attack.captain_weapon_slot) then
            local message = "Attack unavailable for this Captain loadout"

            set_status(state, message, 3)
            VersusModeState.echo_notice(message)

            return
        end

        local request_supported, request_failure = Specialist.captain_weapon_request_supported(state, attack)

        if not request_supported then
            local message = "Attack unavailable for this Captain loadout"

            mod:warning(
                "Versus Mode: rejected Captain command %s (%s): %s.",
                tostring(attack.action_name),
                tostring(attack.captain_weapon_slot),
                tostring(request_failure)
            )
            set_status(state, message, 3)
            VersusModeState.echo_notice(message)

            return
        end

        local unit_position = live_world_position(state.unit)
        local target_position = live_world_position(target)
        local target_distance = unit_position and target_position and vector3_distance(unit_position, target_position)

        if attack.range_max and target_distance and target_distance > attack.range_max then
            local message = string.format("%s is too far (%.1f m; max %.1f m)", attack.label, target_distance, attack.range_max)

            set_status(state, message, 3)
            VersusModeState.echo_notice(message)

            return
        end

        local flat_to_target = unit_position and target_position and Vector3.flat(target_position - unit_position)

        if flat_to_target and vector3_length(flat_to_target) > 0.01 then
            local direction = vector3_normalize(flat_to_target)

            state.yaw = math_atan2(Vector3.x(direction), Vector3.y(direction))
            safe_extension_call(state.locomotion, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))
        end
    end

    local stationary_grenade = GRENADIER_BREEDS[state.breed.name] and attack.grenadier_path == "far"
    local free_aim_grenade = stationary_grenade and state.grenadier_target_lock == false

    if stationary_grenade then
        local solution = free_aim_grenade and state.grenade_preview_solution
            or grenade_locked_target_solution(state, target)

        state.grenade_committed_solution = nil

        if not solution or not solution.valid then
            local message = free_aim_grenade and "No valid grenade trajectory" or "BLOCKED — NO TRAJECTORY"

            set_status(state, message, 2.5)
            VersusModeState.echo_notice(message)

            return
        end

        -- Freeze the exact solved launch for this throw. Live camera and target
        -- updates cannot redirect a grenade already in its wind-up animation.
        state.grenade_committed_solution = {
            valid = true,
            throw_position = Vector3Box(solution.throw_position:unbox()),
            throw_direction = Vector3Box(solution.throw_direction:unbox()),
            wanted_rotation = QuaternionBox(solution.wanted_rotation:unbox()),
            anim_event = solution.anim_event,
            trajectory_kind = solution.trajectory_kind,
        }
    end

    if attack.requires_vomit and not VersusModeState.target_has_beast_vomit(target, state) then
        local message = "Consume requires a vomited target"

        VersusModeState.echo_notice(message)
        set_status(state, message, 3)

        return
    end

    stop_manual_motion(state)

    if (attack.casual_command
        or state.breed.name == "chaos_spawn" and attack.action_name == "leap")
        and state.navigation then
        -- A paused controlled enemy must not resume a destination retained
        -- from traversal or autonomous AI. Casual Combat and direct Spawn Leap
        -- permit only the selected native action's own movement/root motion.
        safe_extension_call(state.navigation, "stop")
    end

    -- Generic/native commands are one button press = one native action. The old
    -- minimum two-second AI window could finish a short strike and begin a
    -- second one before control was paused again.
    local minimum_duration = attack.native_ai and 0 or setting("attack_burst_duration")
    local acquire_timeout = math_max(minimum_duration, attack.acquire_timeout or setting("attack_acquire_timeout"))

    state.attack_target = target
    state.attack_min_until = t + minimum_duration
    state.attack_deadline = t + acquire_timeout
    -- A Pox Burster's `approach` leaf is the commanded action itself, so do not
    -- give it the generic ten-second post-acquisition tail. Its advertised
    -- twelve-second window is also its total approach cap.
    local hard_deadline_extension = attack.direct_native == "poxburster" and 0 or 10

    state.attack_hard_deadline = attack.laser_only and math.huge or t + acquire_timeout + hard_deadline_extension
    state.attack_started = false
    state.command_action_complete = nil
    state.requested_attack = attack
    state.attack_phase = "ACQUIRING"
    state.consume_attempt_complete = nil
    state.sniper_laser_active = attack.laser_only or nil
    state.grenade_throw_complete = nil
    state.grenade_projectile_spawned = nil
    state.net_shot_complete = nil
    state.mutant_carrying = nil
    state.mutant_force_throw = nil
    state.poxburster_armed = nil
    state.spawn_leap_failure = nil
    state.spawn_leap_native_state = nil
    state.spawn_leap_launched = nil
    state.spawn_leap_request_distance = nil
    state.spawn_leap_calculation_distance = nil
    state.spawn_leap_landing_offset = nil
    state.spawn_leap_contact_tolerance = nil
    state.spawn_leap_start_position = nil
    state.spawn_leap_target_position = nil
    state.spawn_leap_landing_logged = nil
    state.spawn_leap_native_predicted_error = nil
    state.spawn_leap_clearance_height = nil
    state.spawn_leap_predicted_error = nil
    state.spawn_leap_handoff_logged = nil
    state.spawn_leap_solver_speed = nil
    state.captain_charge_native_state = nil
    state.netter_approach_bypass_logged = nil
    state.grenadier_follow_bypass_logged = nil
    state.command_aim_yaw = command_free_aim and state.yaw or nil
    state.command_aim_pitch = command_free_aim and state.pitch or nil
    state.camera_melee_move_destination = nil

    if state.breed.name == "chaos_spawn" and attack.action_name == "leap" then
        local leap_origin = live_world_position(state.unit)
        local leap_target_position = live_world_position(target)

        if leap_origin and leap_target_position then
            state.spawn_leap_request_distance = vector3_distance(leap_origin, leap_target_position)
            state.spawn_leap_target_position = Vector3Box(leap_target_position)
        end
    end

    if command_free_aim and attack.free_aim_melee and not attack.stationary then
        local move_destination = Specialist.camera_proxy_target_position(state, state.unit, target)
        local unit_position = live_world_position(state.unit)

        if not move_destination and unit_position then
            local direction = Vector3(
                math_sin(state.command_aim_yaw or state.yaw),
                math_cos(state.command_aim_yaw or state.yaw),
                0
            )

            move_destination = unit_position + vector3_normalize(direction) * (attack.range_max or 3)
        end

        if move_destination then
            state.camera_melee_move_destination = Vector3Box(move_destination)
        end
    end

    if hound_solution then
        state.yaw = hound_solution.yaw
        state.pitch = hound_solution.pitch
        state.hound_committed_solution = {
            launch_velocity = Vector3Box(hound_solution.launch_velocity:unbox()),
            yaw = hound_solution.yaw,
            pitch = hound_solution.pitch,
        }
        state.hound_manual_pounce_active = true
    end

    local prepared, preparation_failure = prepare_native_attack(state, attack)

    if prepared == false then
        local message = CAPTAIN_BREEDS[state.breed.name]
            and "Attack unavailable for this Captain loadout"
            or "Attack unavailable from this position"

        mod:warning(
            "Versus Mode: rejected %s preparation for %s: %s.",
            tostring(attack.action_name),
            tostring(state.breed.name),
            tostring(preparation_failure)
        )
        pause_brain(state)
        set_status(state, message, 3)
        VersusModeState.echo_notice(message)

        return
    end

    if state.perception_component then
        -- Darktide's behavior conditions treat this internal flag as a reason
        -- not to begin a fresh action. Target stability is provided by our
        -- perception hook instead.
        state.perception_component.lock_target = false
    end

    if state.perception then
        safe_extension_call(state.perception, "_set_target_unit", target)
        safe_extension_call(state.perception, "aggro")

        if state.perception_component then
            -- Generated Captain/Twin roots require the replicated blackboard
            -- value on the same evaluation that enters combat. Keep the local
            -- command coherent even if a disabled perception update has not
            -- yet published aggro()'s state transition.
            state.perception_component.aggro_state = "aggroed"
            state.perception_component.target_changed = false
        end
    end

    if state.breed.name == "chaos_spawn" and attack.action_name == "leap" then
        -- Refresh the selected target before enabling the brain and clear any
        -- stale autonomous approval. The forced root selector below hands an
        -- explicit in-range request directly to BtLeapAction; that native leaf
        -- still owns its stricter navmesh, raycast and trajectory validation.
        -- Do not call BossExtension.update out of band or mutate its boxed
        -- per-frame template context.
        VersusModeState.update_controlled_perception(state, state.perception)

        local behavior_component = state.blackboard and state.blackboard.behavior

        if behavior_component then
            behavior_component.should_leap = false

            if behavior_component.move_state == "attacking" then
                behavior_component.move_state = "moving"
            end
        end

    end

    local stationary_netter = state.breed.name == NETTER_BREED_NAME and attack.action_name == "shoot_net"

    if state.navigation and (stationary_grenade or stationary_netter or attack.gunner_combat_range == "far" or command_free_aim and attack.stationary) then
        safe_extension_call(state.navigation, "set_enabled", false)
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
    elseif state.navigation then
        refresh_engine_position(state.unit)

        if state.camera_melee_move_destination then
            safe_extension_call(state.navigation, "stop")
        end

        safe_extension_call(state.navigation, "set_enabled", true, state.breed.run_speed or state.old_max_speed)

        if state.camera_melee_move_destination then
            local destination = state.camera_melee_move_destination:unbox()
            local move_ok = safe_extension_call(state.navigation, "move_to", destination)

            mod:info(
                "Versus Mode: controlled %s committed camera-forward melee motion %.1f m ahead (route=%s).",
                tostring(state.breed.name),
                vector3_distance(live_world_position(state.unit), destination),
                tostring(move_ok == true)
            )
        end
    end

    if state.behavior then
        safe_extension_call(state.behavior, "set_brain_enabled", true)
    end

    if hound_solution then
        VersusModeState.echo_attack_log_localized("notice_requested_hound_pounce")
    elseif state.breed.name == "chaos_spawn" and attack.action_name == "leap" then
        local leap_range_min = attack.range_min or ChaosSpawnSettings.min_leap_distance
        local leap_range_max = attack.range_max or Specialist.spawn_leap_command_max_distance

        VersusModeState.echo_attack_log_localized("notice_spawn_leap_requested",
            target_name(target),
            string.format("%.1f", state.spawn_leap_request_distance or -1),
            string.format("%g", leap_range_min),
            string.format("%g", leap_range_max)
        )
    elseif manual_aim_proxy then
        VersusModeState.echo_attack_log_localized("notice_requested_crosshair_attack", VersusModeState.localize_attack_label(attack))
    elseif free_aim_grenade then
        VersusModeState.echo_attack_log_localized("notice_requested_free_trajectory", VersusModeState.localize_attack_label(attack))
    elseif command_free_aim then
        VersusModeState.echo_attack_log_localized("free_aim_attack_requested", VersusModeState.localize_attack_label(attack))
    elseif stationary_grenade then
        VersusModeState.echo_attack_log_localized(
            "notice_requested_stationary_attack",
            VersusModeState.localize_attack_label(attack),
            target_name(target)
        )
    else
        VersusModeState.echo_attack_log_localized(
            "notice_requested_target_attack",
            VersusModeState.localize_attack_label(attack),
            target_name(target)
        )
    end
end

function VersusModeState.update_controlled_perception(state, perception_extension)
    local target = state.attack_target
    local perception_component = state.perception_component
    local boss_position = live_world_position(state.unit)
    local target_position = live_world_position(target)
    local camera_directed = Specialist.free_aim(state)
        and state.requested_attack
        and state.requested_attack.camera_directed

    if camera_directed then
        local aim_position = state.requested_attack.free_aim_melee
            and Specialist.camera_proxy_target_position(state, state.unit, target)
            or camera_aim_ray(state)

        target_position = aim_position or target_position
    end

    if not perception_component or not boss_position or not target_position then
        return false
    end

    if perception_component.target_unit ~= target then
        local target_ok = safe_extension_call(perception_extension, "_set_target_unit", target)

        if not target_ok then
            return false
        end
    end

    perception_component.target_changed = false

    local offset = target_position - boss_position
    local has_line_of_sight = camera_directed == true
    local ok, result

    if not camera_directed then
        ok, result = safe_extension_call(perception_extension, "immediate_line_of_sight_check", target)

        if ok then
            has_line_of_sight = result
        end
    end

    perception_component.lock_target = false
    perception_component.target_distance = vector3_length(offset)
    perception_component.target_distance_z = math.abs(Vector3.z(offset))
    perception_component.target_speed_away = 0
    perception_component.has_line_of_sight = has_line_of_sight

    if has_line_of_sight then
        safe_extension_call(perception_extension, "set_last_los_position", target, target_position)
        perception_component.has_last_los_position = true
        perception_component.has_good_last_los_position = true

        if perception_component.last_los_position then
            perception_component.last_los_position:store(target_position)
        end
    end

    if perception_component.target_position then
        perception_component.target_position:store(target_position)
    end

    if perception_extension._line_of_sight_lookup then
        perception_extension._line_of_sight_lookup[target] = has_line_of_sight
    end

    if perception_extension._line_of_sight_lookup_by_id then
        for _, lookup in pairs(perception_extension._line_of_sight_lookup_by_id) do
            lookup[target] = has_line_of_sight
        end
    end

    local priority_ok = safe_extension_call(perception_extension, "_update_priority_blackboard_status", state.unit)

    -- Perception is deliberately short-circuited while a player command owns
    -- the target. Preserve the combat-root state that the skipped native
    -- update would otherwise maintain.
    perception_component.aggro_state = "aggroed"

    return priority_ok
end

local function evaluate_forced_child(parent, child, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local leaf_node

    if child.evaluate then
        leaf_node = child:evaluate(unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    else
        leaf_node = child
    end

    if leaf_node then
        new_running_child_nodes[parent.identifier] = child
    end

    return leaf_node
end

local function utility_action_by_name(selector, action_name)
    local actions = selector._action_list

    if actions then
        for i = 1, #actions do
            if actions[i].name == action_name then
                return actions[i]
            end
        end
    end

    return nil
end

-- Mirror BtRandomUtilityNode's weighted choice, but only across the ordinary
-- actions explicitly approved for Casual Primary. The chosen child is frozen
-- into requested_attack before it runs, so later utility evaluations cannot
-- change target/action or fall through to a follow node.
function Specialist.evaluate_casual_utility_attack(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state and state.requested_attack

    if not attack
        or not attack.casual_primary
        or unit ~= state.unit
        or blackboard ~= state.blackboard then
        return false, nil
    end

    local config = Specialist.casual_configs[state.breed.name]
    local expected_selector = attack.selector_name or config and config.selector_name

    if not expected_selector or selector.identifier ~= expected_selector then
        return false, nil
    end

    local allowed = attack.casual_actions or config and config.primary_actions
    local children = selector._random_utility_children
    local selector_data = node_data and node_data[selector.identifier]
    local utility_node_data = selector_data and selector_data.utility_node_data

    if not allowed or not children or not utility_node_data then
        state.attack_phase = "UNAVAILABLE"

        return true, nil
    end

    local choices = {}
    local fallback_choices = {}
    local approach_choices = {}
    local native_scores = {}
    local total_score = 0
    local running_node = old_running_child_nodes[selector.identifier]
    local actions = selector._action_list or {}
    local target_distance = blackboard.perception and blackboard.perception.target_distance

    for i = 1, #actions do
        local action_data = actions[i]
        local action_name = action_data.name
        local descriptor = action_name and allowed[action_name]
        local child = descriptor and children[action_name]
        local utility_data = child and utility_node_data[action_name]

        if child and utility_data and type(target_distance) == "number" then
            local too_close = descriptor.range_min and (
                descriptor.range_min_exclusive and target_distance <= descriptor.range_min
                or not descriptor.range_min_exclusive and target_distance < descriptor.range_min
            )
            local too_far = descriptor.range_max and target_distance > descriptor.range_max
            local line_of_sight_ok = true

            if descriptor.requires_line_of_sight then
                local los_ok, has_line_of_sight = safe_extension_call(
                    state.perception,
                    "immediate_line_of_sight_check",
                    state.attack_target
                )

                line_of_sight_ok = los_ok and has_line_of_sight == true
            end

            if not too_close and not too_far and line_of_sight_ok then
                fallback_choices[#fallback_choices + 1] = {
                    child = child,
                    descriptor = descriptor,
                    fallback = true,
                    score = 1,
                    utility_data = utility_data,
                }
            elseif too_far
                and config
                and config.approach_range_max
                and (config.approach_actions
                    and config.approach_actions[action_name] == true
                    or not config.approach_actions and not descriptor.range_min)
                and (config.approach_range_max_exclusive
                    and target_distance < config.approach_range_max
                    or not config.approach_range_max_exclusive
                    and target_distance <= config.approach_range_max) then
                -- Some breeds have authored gaps between useful attack ranges.
                -- Casual Primary may use only a bounded, command-scoped native
                -- follow with the explicitly approved action; the target and
                -- strike stay frozen and no other attack can run.
                approach_choices[#approach_choices + 1] = {
                    approach = true,
                    child = child,
                    descriptor = descriptor,
                    fallback = true,
                    score = 1,
                    utility_data = utility_data,
                }
            end

            local tree_node = child.tree_node
            local condition = BtConditions[child.condition_name]
            local is_running = last_leaf_node_running and running_node == child
            local condition_ok = not too_close
                and not too_far
                and line_of_sight_ok
                and (not condition
                or condition(
                    unit,
                    blackboard,
                    scratchpad,
                    tree_node.condition_args,
                    tree_node.action_data,
                    is_running
                ))
            local score = condition_ok and Utility.get_action_utility(action_data, blackboard, t, utility_data) or 0

            if type(score) == "number" and score > 0 and score == score then
                native_scores[action_name] = score
                choices[#choices + 1] = {
                    child = child,
                    descriptor = descriptor,
                    score = score,
                    utility_data = utility_data,
                }
                total_score = total_score + score
            end
        end
    end

    if total_score <= 0 then
        if #fallback_choices > 0 then
            choices = fallback_choices
            total_score = #fallback_choices
        else
            choices = approach_choices
            total_score = #approach_choices
        end
    end

    -- Native utility can heavily favor one move forever. Preserve its weights,
    -- but anti-repeat must consider every range-valid whitelisted alternative,
    -- including one whose current native utility is zero. Otherwise a sole
    -- positive Slam/Claw permanently hides its valid Combo alternative.
    local context_choices = #fallback_choices > 0 and fallback_choices or approach_choices

    if state.casual_last_action_name and #context_choices > 1 then
        local previous_available = false

        for i = 1, #context_choices do
            if context_choices[i].descriptor.action_name == state.casual_last_action_name then
                previous_available = true

                break
            end
        end

        if previous_available then
            choices = {}
            total_score = 0

            for i = 1, #context_choices do
                local candidate = context_choices[i]
                local action_name = candidate.descriptor.action_name

                if action_name ~= state.casual_last_action_name then
                    local native_score = native_scores[action_name]

                    candidate.score = native_score or 1
                    candidate.fallback = native_score == nil
                    choices[#choices + 1] = candidate
                    total_score = total_score + candidate.score
                end
            end
        end
    end

    if total_score <= 0 or #choices < 1 then
        state.attack_phase = "NO ATTACK READY"

        return true, nil
    end

    local roll = math.random() * total_score
    local selected = choices[#choices]

    for i = 1, #choices do
        selected = choices[i]
        roll = roll - selected.score

        if roll < 0 then
            break
        end
    end

    local selected_attack = Specialist.copy_attack(selected.descriptor, {
        casual_command = true,
        casual_selected = true,
        -- Utility and range selected this exact child above. Keep it forced for
        -- the rest of this one command so setting last_time cannot put the
        -- chosen move back on cooldown before its leaf enters next frame.
        force_utility = true,
        native_ai = true,
        selector_name = expected_selector,
        casual_approach = selected.approach == true,
    })

    -- A dynamic Captain request carries the verified melee slot on the
    -- synthetic command; preserve it when replacing that command with the
    -- chosen native strike descriptor.
    selected_attack.captain_weapon_slot = selected_attack.captain_weapon_slot
        or attack.captain_weapon_slot
    state.requested_attack = selected_attack
    state.casual_last_action_name = selected_attack.action_name
    state.attack_phase = selected.approach and "APPROACHING" or "SELECTING"
    selected.utility_data.last_time = t

    if selected.approach then
        state.attack_deadline = math_max(
            state.attack_deadline or 0,
            t + (config.approach_timeout or 6)
        )
    end

    mod:info(
        "Versus Mode: Adaptive selected %s for %s using %s weighting at %.2f m%s.",
        tostring(selected_attack.label or selected_attack.action_name),
        tostring(state.breed.name),
        selected.fallback and "range fallback" or "native utility",
        target_distance or -1,
        selected.approach and " (bounded approach)" or ""
    )

    if selected.approach then
        local follow_node = children.follow or children.erratic_follow or children.move_to_combat_vector

        if follow_node then
            return true, evaluate_forced_child(
                selector,
                follow_node,
                unit,
                blackboard,
                scratchpad,
                dt,
                t,
                evaluate_utility,
                node_data,
                old_running_child_nodes,
                new_running_child_nodes,
                last_leaf_node_running
            )
        end

        state.attack_phase = "NO ATTACK READY"

        return true, nil
    end

    return true, evaluate_forced_child(
        selector,
        selected.child,
        unit,
        blackboard,
        scratchpad,
        dt,
        t,
        evaluate_utility,
        node_data,
        old_running_child_nodes,
        new_running_child_nodes,
        last_leaf_node_running
    )
end

local child_by_identifier

local function evaluate_forced_utility_attack(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack
    local action_name = attack and attack.action_name
    local expected_selector = attack and attack.selector_name
        or attack and attack.captain_selector
        or attack and attack.captain_weapon_slot == "slot_power_sword" and "power_sword_melee_combat"
        or attack and attack.captain_weapon_slot == "slot_powermaul" and "powermaul_melee_combat"
        or state.breed.name == SNIPER_BREED_NAME and "COMBAT"
        or GRENADIER_BREEDS[state.breed.name] and "close_combat"
        or "melee_combat"

    if not action_name or unit ~= state.unit or blackboard ~= state.blackboard or selector.identifier ~= expected_selector then
        return false, nil
    end

    local children = selector._random_utility_children

    if attack.captain_weapon_slot and not attack.casual_selected then
        local requested_node = children and children[action_name]

        if not requested_node then
            return false, nil
        end

        local running_node = old_running_child_nodes[selector.identifier]
        local is_running = last_leaf_node_running and running_node == requested_node
        local action_data = requested_node.tree_node and requested_node.tree_node.action_data
        local attack_range = attack.range_max
            or action_data and (action_data.range or action_data.weapon_reach)
            or 4
        local target_distance = blackboard.perception.target_distance or math.huge

        if state.attack_started and not is_running then
            state.command_action_complete = true
            state.attack_min_until = 0
            state.attack_phase = "COMPLETE"

            return true, nil
        end

        if is_running or target_distance <= attack_range then
            state.attack_phase = state.attack_started and "EXECUTING" or "SELECTING"

            return true, evaluate_forced_child(selector, requested_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end

        -- Direct Captain commands never hand locomotion to a follow action.
        -- If the target moves out of range while the weapon is being equipped,
        -- keep the Captain stationary and let the command time out cleanly.
        state.attack_phase = "OUT OF RANGE"

        return true, nil
    end

    if state.breed.name == "chaos_spawn" and action_name == "leap" then
        -- Leap belongs to the root selector. Never let a retained lower
        -- melee-combat evaluation turn a Leap command into silent following.
        local target_distance = blackboard.perception.target_distance or math.huge
        local leap_range_min = attack.range_min or ChaosSpawnSettings.min_leap_distance
        local leap_range_max = attack.range_max or Specialist.spawn_leap_command_max_distance

        state.attack_phase = target_distance < leap_range_min
            and mod:localize("spawn_leap_too_close")
            or target_distance > leap_range_max
            and mod:localize("hud_state_too_far")
            or mod:localize("spawn_leap_checking_arc")

        return true, nil
    end

    local requested_node = children and children[action_name]
    local requested_action = requested_node and utility_action_by_name(selector, action_name)
    local selector_data = node_data and node_data[selector.identifier]
    local utility_data = selector_data and selector_data.utility_node_data and selector_data.utility_node_data[action_name]

    if not requested_node or not requested_action or not utility_data then
        return false, nil
    end

    local running_node = old_running_child_nodes[selector.identifier]
    local is_running = last_leaf_node_running and running_node == requested_node
    local tree_node = requested_node.tree_node
    local condition = BtConditions[requested_node.condition_name]
    local forced_specialist_action = attack.force_utility
        or state.breed.name == SNIPER_BREED_NAME and action_name == "shoot"
        or GRENADIER_BREEDS[state.breed.name] and action_name == "melee_attack" and (blackboard.perception.target_distance or math.huge) <= 4
    local condition_ok = forced_specialist_action or not condition or condition(unit, blackboard, scratchpad, tree_node.condition_args, tree_node.action_data, is_running)
    local score = forced_specialist_action and 1 or condition_ok and Utility.get_action_utility(requested_action, blackboard, t, utility_data) or 0

    if state.attack_started and not is_running then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    if attack.casual_approach
        and not is_running
        and attack.range_max
        and (blackboard.perception.target_distance or math.huge) > attack.range_max then
        local follow_node = children.follow or children.erratic_follow or children.move_to_combat_vector

        if follow_node then
            state.attack_phase = "APPROACHING"

            return true, evaluate_forced_child(selector, follow_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end

        state.attack_phase = "NO ATTACK READY"

        return true, nil
    end

    if is_running or score > 0 then
        state.attack_phase = state.attack_started and "EXECUTING" or "SELECTING"

        return true, evaluate_forced_child(selector, requested_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if attack.casual_selected then
        state.attack_phase = "NO ATTACK READY"

        return true, nil
    end

    local follow_node = children.follow or children.erratic_follow or children.move_to_combat_vector

    if follow_node then
        state.attack_phase = "APPROACHING"

        return true, evaluate_forced_child(selector, follow_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    return true, nil
end

local function evaluate_forced_spawn_leap(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack
    local selector_identifier = selector and selector.identifier
    local is_spawn_root = selector_identifier == "chaos_spawn_GENERATED"
        or selector_identifier == "chaos_spawn"

    if state.breed.name ~= "chaos_spawn" or not attack or attack.action_name ~= "leap" or unit ~= state.unit or blackboard ~= state.blackboard or not is_spawn_root then
        return false, nil
    end

    local children = selector._selector_children
    local leap_node = child_by_identifier(children, "leap")
    local running_node = old_running_child_nodes[selector.identifier]
    local brain = state.behavior and state.behavior._brain
    local running_action_ok, running_action

    if brain then
        running_action_ok, running_action = pcall(brain.running_action, brain)
    end

    local is_running = last_leaf_node_running
        and running_node == leap_node
        and running_action_ok
        and running_action == "leap"
    local target_distance = blackboard.perception.target_distance or math.huge
    local leap_range_min = attack.range_min or ChaosSpawnSettings.min_leap_distance
    local leap_range_max = attack.range_max or Specialist.spawn_leap_command_max_distance
    local in_leap_range = target_distance >= leap_range_min and target_distance <= leap_range_max
    local behavior_component = blackboard.behavior
    local trajectory_ready = behavior_component and behavior_component.should_leap == true
    local stagger_component = blackboard.stagger
    local staggered = stagger_component and stagger_component.num_triggered_staggers > 0
    local smart_object_ok, at_smart_object = safe_extension_call(state.navigation, "is_using_smart_object")

    -- Smart-object traversal and stagger sit above Leap in Darktide's generated
    -- selector. Preserve those safety/interrupt branches; once clear, enter the
    -- requested leaf and let that leaf validate its real trajectory.
    if staggered or smart_object_ok and at_smart_object == true then
        state.attack_phase = mod:localize(staggered and "spawn_leap_interrupted_stagger" or "spawn_leap_traversing")

        return false, nil
    end

    if state.attack_started and not is_running then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    if leap_node and (is_running or in_leap_range) then
        if not is_running and not state.spawn_leap_handoff_logged then
            state.spawn_leap_handoff_logged = true
            mod:info(
                "Versus Mode: Chaos Spawn Leap handed directly to its authoritative native leaf at %.2f m (coarse_ready=%s).",
                target_distance,
                tostring(trajectory_ready)
            )
        end

        state.attack_phase = state.spawn_leap_launched and mod:localize("spawn_leap_launched")
            or state.attack_started and mod:localize("spawn_leap_windup")
            or mod:localize("spawn_leap_windup")

        local leaf_node = evaluate_forced_child(selector, leap_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)

        if not leaf_node and not is_running then
            state.spawn_leap_failure = mod:localize("spawn_leap_no_trajectory")
            state.attack_phase = state.spawn_leap_failure
            mod:warning("Versus Mode: Chaos Spawn Leap native leaf rejected the selector handoff.")
        end

        return true, leaf_node
    end

    if target_distance < leap_range_min then
        local idle_node = child_by_identifier(children, "idle")

        state.attack_phase = mod:localize("spawn_leap_too_close")

        if idle_node then
            return true, evaluate_forced_child(selector, idle_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end

        return true, nil
    end

    if in_leap_range then
        state.spawn_leap_failure = mod:localize("spawn_leap_no_trajectory")
        state.attack_phase = state.spawn_leap_failure
        mod:warning("Versus Mode: Chaos Spawn Leap leaf is unavailable in the generated selector.")

        return true, nil
    end

    local idle_node = child_by_identifier(children, "idle")

    state.attack_phase = mod:localize("hud_state_too_far")

    if idle_node then
        return true, evaluate_forced_child(selector, idle_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    return true, nil
end

child_by_identifier = function(children, identifier)
    if not children then
        return nil
    end

    for i = 1, #children do
        if children[i].identifier == identifier then
            return children[i]
        end
    end

    return nil
end

-- Free aim supplies a real survivor only as a replication/perception proxy.
-- These generated-root overrides narrow the enabled behavior tree to the one
-- requested native attack, preventing follow, patrol, melee, smart-object and
-- other autonomous branches from taking control when the attack key is used.
-- Flamer Kick also needs this direct root selection in Target Lock: the kick
-- can move its target beyond the native root's transient melee combat-range
-- gate before the next request. Keep ranged Target Lock on the normal tree.
-- Darktide's leaf actions still own animation, hit detection and networking.
function Specialist.evaluate_forced_direct_attack(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state and state.requested_attack
    local direct_selector_command = attack
        and (Specialist.free_aim(state) or attack.direct_native == "specialist_melee")

    if not attack
        or not attack.direct_native
        or not direct_selector_command
        or unit ~= state.unit
        or blackboard ~= state.blackboard then
        return false, nil
    end

    local stagger_component = blackboard.stagger

    if stagger_component and stagger_component.num_triggered_staggers > 0 then
        state.attack_phase = "STAGGERED"

        return false, nil
    end

    if state.direct_attack_complete then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    local children = selector._selector_children

    if attack.direct_native == "hound" then
        local combat_node = child_by_identifier(children, "combat")

        if combat_node then
            state.attack_phase = state.hound_manual_pounce_started and "EXECUTING" or "POUNCE WIND-UP"

            return true, evaluate_forced_child(selector, combat_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end
    elseif attack.direct_native == "mutant" then
        local charge_node = child_by_identifier(children, "charge")

        if charge_node then
            new_running_child_nodes[selector.identifier] = charge_node
            state.attack_phase = state.attack_started and "EXECUTING" or "CHARGE WIND-UP"

            return true, charge_node
        end
    elseif attack.direct_native == "poxburster" then
        local approach_node = child_by_identifier(children, "approach")

        if approach_node then
            new_running_child_nodes[selector.identifier] = approach_node
            state.attack_phase = state.poxburster_armed and "FUSE ARMED" or "LUNGE WIND-UP"

            return true, approach_node
        end
    elseif attack.direct_native == "flamer" then
        local combat_node = child_by_identifier(children, "combat")
        local shoot_node = combat_node and child_by_identifier(combat_node._sequence_children, "shoot")

        if combat_node and shoot_node then
            node_data[combat_node.identifier] = 2
            new_running_child_nodes[selector.identifier] = combat_node
            new_running_child_nodes[combat_node.identifier] = shoot_node
            state.attack_phase = state.attack_started and "FIRING" or "IGNITING"

            return true, shoot_node
        end
    elseif attack.direct_native == "specialist_melee" then
        local melee_node = child_by_identifier(children, "melee_attack")

        if melee_node then
            new_running_child_nodes[selector.identifier] = melee_node
            state.attack_phase = state.attack_started and "EXECUTING" or "STRIKING"

            return true, melee_node
        end
    end

    state.command_action_complete = true
    state.attack_min_until = 0
    state.attack_phase = "UNAVAILABLE"

    return true, nil
end

-- The ranged Karnak Twin's single grenade is nested two utility selectors
-- deep: plasma_pistol_combat -> throw_grenade -> quick_throw_grenade. Forcing
-- only the outer node leaves the inner utility roll at zero in several valid
-- combat states, which is why the HUD accepted the request but no action ever
-- began. Preserve both running-node links and select the single-throw leaf
-- directly so its native enter/leave hooks and projectile code still run.
local function evaluate_forced_twin_grenade(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack

    if state.breed.name ~= "renegade_twin_captain"
        or not attack
        or not attack.twin_grenade
        or unit ~= state.unit
        or blackboard ~= state.blackboard then
        return false, nil
    end

    local children = selector._random_utility_children

    if selector.identifier == "plasma_pistol_combat" then
        local grenade_selector = children and children.throw_grenade

        if not grenade_selector then
            return false, nil
        end

        state.attack_phase = state.attack_started and "THROWING" or "SELECTING GRENADE"

        return true, evaluate_forced_child(selector, grenade_selector, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if selector.identifier ~= "throw_grenade" then
        return false, nil
    end

    local grenade_node = children and children.quick_throw_grenade

    if not grenade_node then
        return false, nil
    end

    local running_node = old_running_child_nodes[selector.identifier]
    local is_running = last_leaf_node_running and running_node == grenade_node

    if state.attack_started and not is_running then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    state.attack_phase = state.attack_started and "THROWING" or "WINDING UP"

    return true, evaluate_forced_child(selector, grenade_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end

-- Summoning is a root-level Pack Master action rather than a member of its
-- melee utility selector. The request layer rejects a new summon while any of
-- this Pack Master's hounds are alive; once the pack is gone, this root hook
-- deliberately bypasses only the native respawn timer and runs the complete
-- vanilla summon animation/spawn action once.
local function evaluate_forced_houndmaster_command(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack

    if state.breed.name ~= "chaos_ogryn_houndmaster"
        or not attack
        or unit ~= state.unit
        or blackboard ~= state.blackboard
        or selector.identifier ~= "chaos_ogryn_houndmaster" then
        return false, nil
    end

    local stagger_component = blackboard.stagger

    if stagger_component and stagger_component.num_triggered_staggers > 0 then
        state.attack_phase = "STAGGERED"

        return false, nil
    end

    local children = selector._selector_children

    -- Summon is above melee_combat in the native root selector. During every
    -- deliberate non-summon command, route the root straight into melee combat
    -- so an expired autonomous summon timer cannot replace the requested hit.
    if not attack.summon_hounds then
        local combat_node = child_by_identifier(children, "melee_combat")

        if not combat_node then
            return false, nil
        end

        return true, evaluate_forced_child(selector, combat_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    local summon_node = child_by_identifier(children, "summon")

    if not summon_node then
        return false, nil
    end

    local running_node = old_running_child_nodes[selector.identifier]
    local is_running = last_leaf_node_running and running_node == summon_node

    if state.attack_started and not is_running then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    state.attack_phase = state.attack_started and "SUMMONING" or "CALLING HOUNDS"

    return true, evaluate_forced_child(selector, summon_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end

local function evaluate_forced_sniper_shot(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack

    if state.breed.name ~= SNIPER_BREED_NAME or not attack or attack.action_name ~= "shoot" or unit ~= state.unit or blackboard ~= state.blackboard or selector.identifier ~= SNIPER_BREED_NAME then
        return false, nil
    end

    local stagger_component = blackboard.stagger

    if stagger_component and stagger_component.num_triggered_staggers > 0 then
        state.attack_phase = "STAGGERED"

        return false, nil
    end

    local combat_node = child_by_identifier(selector._selector_children, "COMBAT")

    if combat_node then
        state.attack_phase = state.attack_started and "AIMING" or "SELECTING"

        return true, evaluate_forced_child(selector, combat_node, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    return true, nil
end

local function evaluate_forced_netter_shot(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack

    if state.breed.name ~= NETTER_BREED_NAME or not attack or attack.action_name ~= "shoot_net" or unit ~= state.unit or blackboard ~= state.blackboard or selector.identifier ~= NETTER_BREED_NAME then
        return false, nil
    end

    local stagger_component = blackboard.stagger

    if stagger_component and stagger_component.num_triggered_staggers > 0 then
        state.attack_phase = "STAGGERED"

        return false, nil
    end

    if state.net_shot_complete then
        state.attack_min_until = 0
        state.attack_phase = "FIRED"

        return true, nil
    end

    local attack_target = child_by_identifier(selector._selector_children, "attack_target")

    if attack_target then
        local net_sequence = child_by_identifier(attack_target._selector_children, "net_sequence")
        local shoot_net = net_sequence and child_by_identifier(net_sequence._sequence_children, "shoot_net")

        if shoot_net then
            -- Skip BtRenegadeNetgunnerApproachAction. The commanded net is
            -- fired immediately from the possessed unit's current position;
            -- the native projectile still expires at its normal range. Build
            -- the complete running-node chain explicitly so the parent
            -- selector cannot restore the approach child during evaluation.
            node_data[net_sequence.identifier] = 2
            new_running_child_nodes[selector.identifier] = attack_target
            new_running_child_nodes[attack_target.identifier] = net_sequence
            new_running_child_nodes[net_sequence.identifier] = shoot_net
            state.attack_phase = state.attack_started and "FIRING" or "AIMING"

            return true, shoot_net
        end
    end

    return true, nil
end

local function evaluate_forced_grenadier_attack(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local attack = state.requested_attack
    local breed_name = state.breed.name

    if not GRENADIER_BREEDS[breed_name] or not attack or unit ~= state.unit or blackboard ~= state.blackboard or selector.identifier ~= breed_name then
        return false, nil
    end

    local stagger_component = blackboard.stagger

    if stagger_component and stagger_component.num_triggered_staggers > 0 then
        state.attack_phase = "STAGGERED"

        return false, nil
    end

    local branch_name = attack.grenadier_path == "close" and "close_combat" or "far_combat"
    local branch = child_by_identifier(selector._selector_children, branch_name)

    if branch and attack.grenadier_path == "far" then
        if state.grenade_throw_complete then
            state.attack_min_until = 0
            state.attack_phase = "THROWN"

            return true, nil
        end

        local throw_node = child_by_identifier(branch._sequence_children, "throw_grenade")

        if throw_node and commit_grenade_solution(state, blackboard) then
            -- Native far combat normally starts with BtGrenadierFollowAction,
            -- which searches for and walks to an AI-selected throwing spot.
            -- Direct control already owns a valid launch vector in both lock
            -- and free-aim modes, so construct the complete running-node chain
            -- at the native throw child instead.
            node_data[branch.identifier] = 2
            new_running_child_nodes[selector.identifier] = branch
            new_running_child_nodes[branch.identifier] = throw_node
            state.attack_phase = state.attack_started and "THROWING" or "WINDING UP"

            return true, throw_node
        end

        state.attack_min_until = 0
        state.attack_phase = "NO TRAJECTORY"

        return true, nil
    end

    if branch then
        state.attack_phase = state.attack_started and "EXECUTING" or attack.grenadier_path == "close" and "APPROACHING" or "AIMING THROW"

        return true, evaluate_forced_child(selector, branch, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    return true, nil
end

local function sanitize_beast_consumed_state(blackboard, scratchpad)
    local behavior_component = blackboard and blackboard.behavior

    if not behavior_component then
        return
    end

    local consumed_unit = behavior_component.consumed_unit

    if consumed_unit and not valid_player_target(consumed_unit) then
        behavior_component.consumed_unit = nil
        behavior_component.force_spit_out = false
        behavior_component.wants_to_catapult_consumed_unit = false

        if scratchpad and scratchpad.consumed_unit == consumed_unit then
            scratchpad.consumed_unit = nil
        end
    end

    local scratchpad_consumed_unit = scratchpad and scratchpad.consumed_unit

    if scratchpad_consumed_unit and not valid_player_target(scratchpad_consumed_unit) then
        scratchpad.consumed_unit = nil
    end
end

local function evaluate_forced_beast_attack(selector, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    if state.breed.name ~= "chaos_beast_of_nurgle" or blackboard ~= state.blackboard or unit ~= state.unit then
        return false, nil
    end

    sanitize_beast_consumed_state(blackboard, scratchpad)

    local attack = state.requested_attack

    if not attack then
        return false, nil
    end

    if state.attack_started and not last_leaf_node_running then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "COMPLETE"

        return true, nil
    end

    local death_component = blackboard.death
    local stagger_component = blackboard.stagger
    local behavior_component = blackboard.behavior

    if not behavior_component or death_component and death_component.is_dead or stagger_component and stagger_component.num_triggered_staggers > 0 or HEALTH_ALIVE[behavior_component.consumed_unit] then
        return false, nil
    end

    local children = selector._selector_children
    local perception_component = blackboard.perception
    local target_distance = perception_component.target_distance or math.huge
    local ready = state.attack_started
    local branch

    if attack.beast_path == "vomit" then
        ready = ready or perception_component.has_line_of_sight and perception_component.target_distance_z < 3 and target_distance <= 10
        branch = child_by_identifier(children, "vomiting")
    elseif attack.beast_path == "body_slam" then
        ready = ready or target_distance <= 4.75

        if ready then
            local melee_selector = child_by_identifier(children, "melee_push_back_attacks")
            local body_slam = melee_selector and child_by_identifier(melee_selector._selector_children, "melee_attack_body_slam_aoe")

            if body_slam then
                new_running_child_nodes[selector.identifier] = melee_selector
                new_running_child_nodes[melee_selector.identifier] = body_slam
                state.attack_phase = "EXECUTING"

                return true, body_slam
            end
        end
    elseif attack.beast_path == "consume" then
        if state.consume_attempt_complete then
            state.attack_min_until = 0
            state.attack_phase = "MISSED"

            return true, nil
        end

        ready = ready or target_distance < 5 and VersusModeState.target_has_beast_vomit(state.attack_target, state)
        branch = child_by_identifier(children, "consuming")
    end

    if ready and branch then
        state.attack_phase = state.attack_started and "EXECUTING" or "ALIGNING"

        return true, evaluate_forced_child(selector, branch, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if attack.casual_command then
        -- Casual attacks are chosen only for their current position. If the
        -- target steps out during wind-up, wait for the short command timeout
        -- instead of handing movement to the Beast's autonomous chase branch.
        state.attack_phase = "OUT OF RANGE"

        return true, nil
    end

    local movement = child_by_identifier(children, "movement")

    if movement then
        state.attack_phase = "APPROACHING"

        return true, evaluate_forced_child(selector, movement, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    return true, nil
end

mouse_look_ui_gate = function()
    local ui_manager = Managers.ui
    local imgui_manager = Managers.imgui
    local input_manager = Managers.input

    if imgui_manager and imgui_manager:using_input() then
        return true, "ImGui"
    end

    if ui_manager then
        if ui_manager:handling_popups() then
            return true, "popup"
        end

        local active_view = ui_manager:active_top_view()

        if active_view then
            return true, "menu/view " .. tostring(active_view)
        end

        if ui_manager:chat_using_input() then
            return true, "chat input"
        end

        if ui_manager:using_input() then
            return true, "HUD input"
        end
    end

    if input_manager and input_manager:cursor_active() then
        return true, "mouse cursor"
    end

    return false
end

local function control_input_ui_gated(state)
    if mod._death_camera then
        return true
    end

    local gated, reason = mouse_look_ui_gate()
    local t = gameplay_time()

    if gated and state then
        state.ui_input_block_until = t + UI_INPUT_RELEASE_GRACE
        state.ui_input_block_reason = reason
    elseif state and t < (state.ui_input_block_until or 0) then
        gated = true
        reason = state.ui_input_block_reason or "recent UI input"
    end

    if state then
        if gated then
            if not state.control_input_gated or state.control_input_gate_reason ~= reason then
                mod:info("Possession controls gated by " .. reason .. ".")
            end

            state.control_input_gated = true
            state.control_input_gate_reason = reason
        elseif state.control_input_gated then
            mod:info("Possession controls resumed.")
            state.control_input_gated = nil
            state.control_input_gate_reason = nil
            state.ui_input_block_reason = nil
        end
    end

    return gated
end

function VersusModeState.active_free_flight_camera()
    local free_flight = Managers.free_flight

    if not free_flight or not free_flight:is_in_free_flight() then
        return nil
    end

    local camera_ok, camera = pcall(free_flight.camera, free_flight, "global")

    return camera_ok and camera or nil
end

function VersusModeState.sniper_scope_sensitivity_modifier(state)
    local vertical_fov = state and state.sniper_scope_current_fov

    if type(vertical_fov) ~= "number" then
        local camera = VersusModeState.active_free_flight_camera()
        local fov_ok, camera_fov = false, nil

        if camera and Camera and Camera.vertical_fov then
            fov_ok, camera_fov = pcall(Camera.vertical_fov, camera)
        end

        vertical_fov = fov_ok and camera_fov or nil
    end

    if type(vertical_fov) ~= "number" or vertical_fov <= 0 then
        return nil
    end

    -- Match Darktide's Fov.sensitivity_modifier against the camera that is
    -- actually rendered. The normal player viewport is hidden during
    -- possession and therefore cannot describe this temporary scope zoom.
    return math.tan(vertical_fov * 0.5) / math.tan(math.pi / 6)
end

function VersusModeState.update_sniper_scope(state)
    if not state or not state.breed or state.breed.name ~= SNIPER_BREED_NAME then
        return false
    end

    local camera = VersusModeState.active_free_flight_camera()

    if not camera or not Camera or not Camera.vertical_fov or not Camera.set_vertical_fov then
        return false
    end

    local t = gameplay_time()
    local fov_ok, camera_fov = pcall(Camera.vertical_fov, camera)

    if not fov_ok or type(camera_fov) ~= "number" or camera_fov <= 0 then
        return false
    end

    if not state.sniper_scope_base_fov then
        state.sniper_scope_base_fov = camera_fov
        state.sniper_scope_current_fov = camera_fov
        state.sniper_scope_progress = 0
        state.sniper_scope_updated_at = t
    end

    local enabled = setting("enable_sniper_scope_zoom") == true
    local target_progress = enabled and state.sniper_scope_held and 1 or 0
    local progress = state.sniper_scope_progress or 0
    local dt = math_max(0, math_min(0.1, t - (state.sniper_scope_updated_at or t)))
    local step = dt / Specialist.sniper_scope_transition_duration

    if target_progress > progress then
        progress = math_min(target_progress, progress + step)
    elseif target_progress < progress then
        progress = math_max(target_progress, progress - step)
    end

    local base_fov = state.sniper_scope_base_fov
    local configured_fov = math_max(
        Specialist.sniper_scope_min_fov,
        setting("sniper_scope_vertical_fov") * math.pi / 180
    )
    local scope_fov = math_min(base_fov, configured_fov)
    local eased_progress = progress * progress * (3 - 2 * progress)
    local applied_fov = base_fov + (scope_fov - base_fov) * eased_progress
    local applied_ok = pcall(Camera.set_vertical_fov, camera, applied_fov)

    if not applied_ok then
        return false
    end

    state.sniper_scope_progress = progress
    state.sniper_scope_current_fov = applied_fov
    state.sniper_scope_updated_at = t

    return true
end

function VersusModeState.restore_sniper_scope(state)
    if not state then
        return false
    end

    local camera = VersusModeState.active_free_flight_camera()
    local restored = false

    if camera
        and Camera
        and Camera.set_vertical_fov
        and type(state.sniper_scope_base_fov) == "number" then
        restored = pcall(Camera.set_vertical_fov, camera, state.sniper_scope_base_fov)
    end

    state.sniper_scope_held = nil
    state.sniper_scope_base_fov = nil
    state.sniper_scope_current_fov = nil
    state.sniper_scope_progress = nil
    state.sniper_scope_updated_at = nil

    return restored
end

function VersusModeState.sniper_scope_hud_progress()
    local state = mod._control

    return state
        and state.possessed
        and state.breed
        and state.breed.name == SNIPER_BREED_NAME
        and state.sniper_scope_progress
        or 0
end

local function update_manual_look(state)
    -- Raw Mouse.axis input bypasses the player's normal input service. Stop
    -- consuming it whenever a menu, popup, chat box or ImGui window owns the
    -- mouse so navigating UI cannot rotate the possessed enemy underneath it.
    if state and not state.controller_peer_id and control_input_ui_gated(state) then
        return false
    end

    local mouse
    local sensitivity
    local native_orientation = false

    if state and state.breed and state.breed.name == SNIPER_BREED_NAME then
        local input_service = VersusModeState.ingame_input_service()
        local has_ok
        local has_action

        if input_service and input_service.has then
            has_ok, has_action = pcall(input_service.has, input_service, "look_ranged_alternate_fire")
        end

        if has_ok and has_action and input_service.get then
            local input_ok, filtered_mouse = pcall(input_service.get, input_service, "look_ranged_alternate_fire")

            if input_ok and filtered_mouse then
                mouse = filtered_mouse
                native_orientation = true

                local orientation_defaults = VersusModeState.player_orientation_settings.default or {}
                local player = local_player()
                local player_sensitivity = player and tonumber(player.sensitivity) or 1
                local scope_fov_modifier = VersusModeState.sniper_scope_sensitivity_modifier(state)
                local fov_modifier = scope_fov_modifier or 1

                if not scope_fov_modifier and player and player.viewport_name then
                    local fov_ok, value = pcall(VersusModeState.fov.sensitivity_modifier, player.viewport_name)

                    if fov_ok and type(value) == "number" then
                        fov_modifier = value
                    end
                end

                sensitivity = (orientation_defaults.mouse_scale or 0.001)
                    * player_sensitivity
                    * fov_modifier
                    * setting("sniper_mouse_sensitivity_multiplier")
                    * 0.01
            end
        end
    end

    if not mouse then
        mouse = Mouse.axis(0)
        sensitivity = setting("mouse_sensitivity") * 0.00003
    end

    if native_orientation then
        -- Darktide's ranged alternate-fire filter already applies the user's
        -- ADS sensitivity and vertical-inversion setting. Match the native
        -- FOV scaling and vertical sign, then apply only our local Sniper
        -- multiplier. VersusMode's yaw convention is positive mouse X; using
        -- the camera's opposite transform here was what inverted horizontal
        -- Sniper movement. Other possessed enemies retain their existing path.
        state.yaw = state.yaw + Vector3.x(mouse) * sensitivity
    else
        state.yaw = state.yaw + Vector3.x(mouse) * sensitivity
    end

    if state.first_person then
        local pitch_delta = Vector3.y(mouse) * sensitivity

        state.pitch = math_max(-1.25, math_min(1.25, state.pitch + (native_orientation and pitch_delta or -pitch_delta)))
    elseif Specialist.free_aim(state) then
        local pitch_delta = Vector3.y(mouse) * sensitivity

        state.pitch = math_max(-0.9, math_min(1.05, state.pitch + (native_orientation and pitch_delta or -pitch_delta)))
    else
        local pitch_delta = Vector3.y(mouse) * sensitivity

        state.pitch = math_max(-0.7, math_min(0.35, state.pitch + (native_orientation and pitch_delta or -pitch_delta)))
    end

    return true
end

function VersusModeState.update_gunner_shoot_movement(state, forward_amount, right_amount)
    local forward = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)
    local right = Vector3(math_cos(state.yaw), -math_sin(state.yaw), 0)
    local direction = forward * forward_amount + right * right_amount
    local amount = vector3_length(direction)

    if amount <= 0.01 then
        state.locomotion:set_wanted_velocity_flat(Vector3.zero())

        if state.gunner_shoot_move_event then
            local end_event = state.breed.name == "chaos_ogryn_gunner" and "hip_fire" or "aim_standing"

            safe_anim_event(state.animation, end_event)
            state.animation_heartbeat_last_event = end_event
            state.gunner_shoot_move_event = nil
        end

        state.moving = false

        return
    end

    direction = vector3_normalize(direction)

    local rotation = Unit.local_rotation(state.unit, 1)
    local facing = Vector3.flat(Quaternion.forward(rotation))
    local side = Vector3.flat(Quaternion.right(rotation))
    local forward_dot = Vector3.dot(direction, facing)
    local right_dot = Vector3.dot(direction, side)
    local move_direction = math.abs(forward_dot) >= math.abs(right_dot)
        and (forward_dot >= 0 and "fwd" or "bwd")
        or (right_dot >= 0 and "right" or "left")
    local move_event = "move_" .. move_direction .. "_walk_aim"
    local speed = 1.6

    if state.breed.name == "chaos_ogryn_gunner" then
        speed = ({ fwd = 2.4, bwd = 1.32, left = 1.68, right = 1.92 })[move_direction]
    end

    state.locomotion:set_wanted_velocity_flat(direction * speed * setting("move_speed_percent") * 0.01)

    -- Native strafe shooting keeps facing the aim point while moving sideways.
    local aim_forward = forward

    if state.attack_target and not Specialist.free_aim(state) then
        local target_position = live_world_position(state.attack_target)
        local unit_position = live_world_position(state.unit)
        local to_target = target_position and unit_position and Vector3.flat(target_position - unit_position)

        if to_target and vector3_length(to_target) > 0.01 then
            aim_forward = vector3_normalize(to_target)
        end
    end

    state.locomotion:set_wanted_rotation(Quaternion.look(aim_forward, vector3_up()))

    if state.gunner_shoot_move_event ~= move_event then
        safe_anim_event(state.animation, move_event)
        state.animation_heartbeat_last_event = move_event
        state.gunner_shoot_move_event = move_event
    end

    state.moving = false
end

local function update_manual_movement(state, gunner_shooting)
    if not update_manual_look(state) then
        if gunner_shooting then
            VersusModeState.update_gunner_shoot_movement(state, 0, 0)

            return
        end

        state.locomotion:set_wanted_velocity_flat(Vector3.zero())

        if state.moving then
            safe_anim_event(state.animation, "idle")
            state.animation_heartbeat_last_event = "idle"
            state.moving = false
        end

        return
    end

    local forward_amount = Keyboard.button(Keyboard.button_index("w")) - Keyboard.button(Keyboard.button_index("s"))
    local right_amount = Keyboard.button(Keyboard.button_index("d")) - Keyboard.button(Keyboard.button_index("a"))

    if gunner_shooting then
        VersusModeState.update_gunner_shoot_movement(state, forward_amount, right_amount)

        return
    end

    local forward = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)
    local right = Vector3(math_cos(state.yaw), -math_sin(state.yaw), 0)
    local direction = forward * forward_amount + right * right_amount
    local amount = vector3_length(direction)

    if amount > 0.01 then
        direction = vector3_normalize(direction)

        local speed = (state.breed.run_speed or state.old_max_speed or 4) * setting("move_speed_percent") * 0.01

        state.locomotion:set_wanted_velocity_flat(direction * speed)
        state.locomotion:set_wanted_rotation(Quaternion.look(state.first_person and forward or direction, vector3_up()))

        if not state.moving then
            safe_anim_event(state.animation, "move_fwd")
            state.animation_heartbeat_last_event = "move_fwd"
            state.moving = true
        end
    else
        state.locomotion:set_wanted_velocity_flat(Vector3.zero())

        if state.first_person or Specialist.free_aim(state) then
            state.locomotion:set_wanted_rotation(Quaternion.look(forward, vector3_up()))
        end

        if state.moving then
            safe_anim_event(state.animation, "idle")
            state.animation_heartbeat_last_event = "idle"
            state.moving = false
        end
    end
end

function VersusModeState.restore_controlled_traversal_layer_cost(state, traversal)
    if not state or not traversal or not traversal.layer_cost_overridden then
        return false
    end

    local restored = safe_extension_call(
        state.navigation,
        "set_nav_tag_layer_cost",
        traversal.expected_layer_type,
        traversal.original_layer_cost or 1
    )

    traversal.layer_cost_overridden = nil

    return restored == true
end

function VersusModeState.controlled_traversal_interval_matches(traversal, smart_object)
    if not traversal or traversal.expected_smart_object_id == nil then
        return true
    end

    if not smart_object then
        return false, string.format(
            "expected smart object %s, navigation selected none",
            tostring(traversal.expected_smart_object_id)
        )
    end

    if traversal.expected_layer_type
        and smart_object.type ~= traversal.expected_layer_type then
        return false, string.format(
            "expected smart object %s (%s), navigation selected %s (%s)",
            tostring(traversal.expected_smart_object_id),
            tostring(traversal.expected_layer_type),
            tostring(smart_object.id),
            tostring(smart_object.type)
        )
    end

    local expected_entrance = traversal.selected_near_position
        and traversal.selected_near_position:unbox()
    local expected_exit = traversal.selected_far_position
        and traversal.selected_far_position:unbox()
    local actual_entrance = smart_object.entrance_position
        and smart_object.entrance_position:unbox()
    local actual_exit = smart_object.exit_position
        and smart_object.exit_position:unbox()
    local ids_match = smart_object.id == traversal.expected_smart_object_id

    if not expected_entrance or not expected_exit or not actual_entrance or not actual_exit then
        if ids_match then
            return true
        end

        return false, string.format(
            "expected smart object %s, navigation selected %s without comparable endpoints",
            tostring(traversal.expected_smart_object_id),
            tostring(smart_object.id)
        )
    end

    local entrance_error = vector3_distance(expected_entrance, actual_entrance)
    local exit_error = vector3_distance(expected_exit, actual_exit)

    if ids_match then
        local tolerance = VersusModeState.traversal_selected_endpoint_tolerance

        if entrance_error > tolerance or exit_error > tolerance then
            return false, string.format(
                "selected smart object %s was routed in the wrong direction (entrance %.2f m, exit %.2f m)",
                tostring(smart_object.id),
                entrance_error,
                exit_error
            )
        end

        return true
    end

    -- Wide ledges and fence tops are frequently authored as several parallel
    -- nav graphs. The contextual selector can choose the closest sample while
    -- the per-breed pathfinder chooses its adjacent sample from the same edge.
    -- Accept that handoff only when both oriented endpoints, vertical travel,
    -- layer and travel direction prove that it crosses the same obstacle.
    local expected_delta = expected_exit - expected_entrance
    local actual_delta = actual_exit - actual_entrance
    local expected_flat = Vector3.flat(expected_delta)
    local actual_flat = Vector3.flat(actual_delta)
    local expected_flat_length = vector3_length(expected_flat)
    local actual_flat_length = vector3_length(actual_flat)
    local direction_dot = 1

    if expected_flat_length > 0.05 and actual_flat_length > 0.05 then
        direction_dot = vector3_dot(
            vector3_normalize(expected_flat),
            vector3_normalize(actual_flat)
        )
    end

    local expected_height = Vector3.z(expected_delta)
    local actual_height = Vector3.z(actual_delta)
    local height_error = math.abs(expected_height - actual_height)
    local parallel_match = entrance_error <= VersusModeState.traversal_parallel_link_tolerance
        and exit_error <= VersusModeState.traversal_parallel_link_tolerance
        and height_error <= VersusModeState.traversal_parallel_height_tolerance
        and direction_dot >= VersusModeState.traversal_parallel_direction_dot

    if parallel_match then
        return true, string.format(
            "parallel smart object %s substituted for %s (entrance %.2f m, exit %.2f m, height error %.2f m, dot %.2f)",
            tostring(smart_object.id),
            tostring(traversal.expected_smart_object_id),
            entrance_error,
            exit_error,
            height_error,
            direction_dot
        ), true
    end

    return false, string.format(
        "expected smart object %s, navigation selected non-equivalent %s "
            .. "(entrance %.2f m, exit %.2f m, heights %+.2f/%+.2f m, dot %.2f)",
        tostring(traversal.expected_smart_object_id),
        tostring(smart_object.id),
        entrance_error,
        exit_error,
        expected_height,
        actual_height,
        direction_dot
    )
end

function VersusModeState.commit_controlled_traversal_link(state, traversal, t)
    if not state or not traversal or not traversal.destination then
        return false
    end

    local route_time = t or gameplay_time()
    local destination = traversal.destination:unbox()
    local layer_type = traversal.expected_layer_type

    if layer_type and not traversal.layer_cost_overridden then
        local layer_costs = state.breed and state.breed.nav_tag_allowed_layers
        local default_layer_costs = VersusModeState.navigation_cost_settings
            and VersusModeState.navigation_cost_settings.default_nav_tag_layers_minions
        local original_cost = layer_costs and layer_costs[layer_type]
            or default_layer_costs and default_layer_costs[layer_type]

        traversal.original_layer_cost = type(original_cost) == "number" and original_cost or 1
        traversal.layer_cost_overridden = safe_extension_call(
            state.navigation,
            "set_nav_tag_layer_cost",
            layer_type,
            VersusModeState.traversal_selected_layer_cost
        ) == true
    end

    safe_extension_call(state.navigation, "stop")

    local enabled_ok = safe_extension_call(state.navigation, "set_enabled", true, traversal.speed)
    local entrance = traversal.selected_near_position
        and traversal.selected_near_position:unbox()
    local nav_start_aligned = enabled_ok
        and entrance
        and safe_extension_call(state.navigation, "set_nav_bot_position", entrance)
    local move_ok = enabled_ok and safe_extension_call(state.navigation, "move_to", destination)

    if not move_ok then
        VersusModeState.finish_controlled_traversal(state, "selected ledge route was unavailable")

        return false
    end

    traversal.phase = "link_pathing"
    traversal.completion_armed = false
    traversal.stale_reached_logged = nil
    traversal.expected_link_seen = nil
    traversal.unexpected_smart_object_id = nil
    traversal.link_route_started_at = route_time
    traversal.nav_start_aligned = nav_start_aligned == true

    local behavior_component = state.blackboard and state.blackboard.behavior

    if behavior_component then
        behavior_component.move_state = "moving"
    end

    if not state.moving then
        safe_anim_event(state.animation, "move_fwd")
    end

    state.moving = true
    set_status(
        state,
        mod:localize("controlled_traversal_pathing"),
        math_max(0, (traversal.deadline or route_time) - route_time)
    )

    mod:info(
        "Versus Mode: controlled %s committed smart object %s (%s) from its authored entrance; "
            .. "nav start aligned=%s, temporary layer cost %.2f (restore %.2f).",
        tostring(state.breed and state.breed.name or "enemy"),
        tostring(traversal.expected_smart_object_id or "route-selected"),
        tostring(layer_type or "native"),
        tostring(traversal.nav_start_aligned),
        traversal.layer_cost_overridden and VersusModeState.traversal_selected_layer_cost or -1,
        traversal.original_layer_cost or -1
    )

    return true
end

function VersusModeState.retry_controlled_traversal_link(state, traversal, reason, t)
    if not state or not traversal then
        return false
    end

    local retries = (traversal.link_route_retries or 0) + 1

    if retries > VersusModeState.traversal_link_retry_limit then
        VersusModeState.reject_controlled_traversal_link(
            state,
            traversal.expected_smart_object_id,
            reason or "the selected native route was unavailable"
        )
        VersusModeState.finish_controlled_traversal(state, reason or "selected ledge route was unavailable")

        return false
    end

    traversal.link_route_retries = retries

    local position = live_world_position(state.unit)
    local entrance = traversal.selected_near_position and traversal.selected_near_position:unbox()
    local entrance_distance = position and entrance and vector3_distance(position, entrance) or math.huge

    mod:warning(
        "Versus Mode: controlled %s retrying committed smart object %s (%d/%d; %s).",
        tostring(state.breed and state.breed.name or "enemy"),
        tostring(traversal.expected_smart_object_id or "unknown"),
        retries,
        VersusModeState.traversal_link_retry_limit,
        tostring(reason or "route mismatch")
    )

    local entrance_commit_distance = traversal.entrance_completion_armed
        and VersusModeState.controlled_traversal_entrance_distance(state)
        or VersusModeState.traversal_entrance_commit_distance

    if entrance and entrance_distance > entrance_commit_distance then
        VersusModeState.restore_controlled_traversal_layer_cost(state, traversal)
        safe_extension_call(state.navigation, "stop")

        local enabled_ok = safe_extension_call(state.navigation, "set_enabled", true, traversal.speed)
        local move_ok = enabled_ok and safe_extension_call(state.navigation, "move_to", entrance)

        if not move_ok then
            VersusModeState.reject_controlled_traversal_link(
                state,
                traversal.expected_smart_object_id,
                "the authored entrance route could not be resumed"
            )
            VersusModeState.finish_controlled_traversal(state, "selected ledge entrance was unavailable")

            return false
        end

        traversal.phase = "entrance_pathing"
        traversal.entrance_completion_armed = false
        traversal.expected_link_seen = nil
        traversal.stale_entrance_reached_logged = nil
        traversal.stale_entrance_reached_at = nil
        traversal.unexpected_smart_object_id = nil
        traversal.link_route_started_at = nil
        traversal.entrance_best_remaining = entrance_distance
        traversal.entrance_progress_at = t or gameplay_time()
        traversal.entrance_started_at = t or gameplay_time()

        return true
    end

    return VersusModeState.commit_controlled_traversal_link(state, traversal, t or gameplay_time())
end

function VersusModeState.finish_controlled_traversal(state, reason, destroy, quiet)
    local traversal = state and state.controlled_traversal

    if not traversal then
        return false
    end

    if traversal.native_started and traversal.native_action and state.unit and ALIVE[state.unit] then
        pcall(
            traversal.native_action.leave,
            traversal.native_action,
            state.unit,
            state.breed,
            state.blackboard,
            traversal.scratchpad,
            traversal.native_action_data,
            gameplay_time(),
            reason == "done" and "done" or "failed",
            destroy == true
        )
    end

    VersusModeState.restore_controlled_traversal_layer_cost(state, traversal)

    state.controlled_traversal = nil

    if state.unit and ALIVE[state.unit] then
        local behavior_component = state.blackboard and state.blackboard.behavior

        if behavior_component then
            behavior_component.move_state = "idle"
        end

        safe_extension_call(state.navigation, "stop")
        safe_extension_call(state.navigation, "set_enabled", false)
        safe_extension_call(state.locomotion, "set_movement_type", "snap_to_navmesh")
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
        state.moving = false

        if not destroy then
            safe_anim_event(state.animation, "idle")
        end
    end

    mod:info(
        "Versus Mode: controlled %s traversal ended (%s).",
        tostring(state.breed and state.breed.name or "specialist"),
        tostring(reason or "unknown")
    )

    if not quiet then
        if reason == "done" then
            set_status(state, mod:localize("controlled_traversal_complete"), 2)
        elseif reason == "cancelled" then
            set_status(state, mod:localize("controlled_traversal_cancelled"), 2)
        else
            set_status(state, mod:localize("controlled_traversal_failed", tostring(reason or "unknown")), 3)
        end
    end

    return true
end

function VersusModeState.controlled_open_door_action_data(state, action_data)
    if not action_data
        or not state
        or not state.breed
        or state.breed.name ~= "cultist_mutant"
        or action_data.open_door_time_offset == nil then
        return action_data
    end

    -- Darktide gives only the Mutant a two-second door self-close override.
    -- That is sufficient while its complete AI tree owns the route, but the
    -- command-scoped controller can still be resuming navigation when a spawn
    -- hatch begins closing. Copy the action data so ordinary AI and every
    -- other breed retain their native values, then let this door use its own
    -- configured self-close timing for the controlled Mutant passage.
    local controlled_data = {}

    for key, value in pairs(action_data) do
        controlled_data[key] = value
    end

    controlled_data.open_door_time_offset = nil

    return controlled_data
end

function VersusModeState.update_mutant_door_clearance(state, traversal, t, position, destination)
    if not state
        or not traversal
        or not traversal.door_native_completed_at
        or not state.breed
        or state.breed.name ~= "cultist_mutant"
        or not position
        or not destination then
        return false
    end

    local door_extension = safe_extension(traversal.door_target_unit, "door_system")
    local blocked_ok, nav_blocked = safe_extension_call(door_extension, "nav_blocked")

    -- Never push through a closed or still-blocking door. The native door
    -- action remains the only code allowed to open it.
    if not blocked_ok or nav_blocked then
        return false
    end

    local offset = Vector3.flat(destination - position)
    local remaining = vector3_length(offset)

    if remaining <= 0.01 then
        return false
    end

    local best_remaining = traversal.mutant_door_best_remaining or remaining

    if remaining + VersusModeState.mutant_door_progress_epsilon < best_remaining then
        traversal.mutant_door_best_remaining = remaining
        traversal.mutant_door_progress_at = t
        traversal.mutant_door_retry_at = t + VersusModeState.mutant_door_retry_interval
        traversal.mutant_door_retry_count = 0
    elseif t >= (traversal.mutant_door_retry_at or 0)
        and (traversal.mutant_door_retry_count or 0) < VersusModeState.mutant_door_retry_limit then
        traversal.mutant_door_retry_count = (traversal.mutant_door_retry_count or 0) + 1
        traversal.mutant_door_retry_at = t + VersusModeState.mutant_door_retry_interval

        safe_extension_call(state.navigation, "set_enabled", true, traversal.speed)
        safe_extension_call(state.navigation, "move_to", destination)
        mod:info(
            "Versus Mode: controlled Mutant door-clearance route retry %d/%d (%.1f m remaining).",
            traversal.mutant_door_retry_count,
            VersusModeState.mutant_door_retry_limit,
            remaining
        )
    end

    -- The Mutant uses navigation path splines and a substantially larger
    -- collision body than humanoid specialists. Do not add a straight-line
    -- velocity on top of the native path: that can steer the body into the
    -- hatch frame. The already validated move_to route remains authoritative;
    -- this helper only asks that same route to retry when progress stalls.
    return true
end

function VersusModeState.start_controlled_traversal(state, requested_destination, door_target_unit, traversal_metadata)
    if not state or not state.possessed or state.remote_client then
        return false
    end

    if not VersusModeState.controlled_traversal_enabled() then
        set_status(state, mod:localize("controlled_traversal_disabled"), 2.5)

        return false
    end

    local traversal_kind = door_target_unit and "door" or "climb"

    if not VersusModeState.controlled_traversal_breed_supported(state.breed, traversal_kind) then
        set_status(state, mod:localize("controlled_traversal_specialist_only"), 2.5)

        return false
    end

    if state.attack_deadline or VersusModeState.controlled_traversal_carrying_player(state) then
        set_status(state, mod:localize("controlled_traversal_attack_busy"), 2.5)
        mod:info(
            "Versus Mode: controlled %s rejected contextual traversal while attack/carry state was active.",
            tostring(state.breed and state.breed.name or "enemy")
        )

        return false
    end

    if state.controlled_traversal then
        if state.controlled_traversal.native_started then
            set_status(state, mod:localize("controlled_traversal_native_busy"), 2.5)

            return false
        end

        VersusModeState.finish_controlled_traversal(state, "cancelled", false, true)
    end

    local origin = live_world_position(state.unit)
    local aim_position = requested_destination or camera_aim_ray(state)
    local nav_ok, nav_world = safe_extension_call(state.navigation, "nav_world")
    local traverse_ok, traverse_logic = safe_extension_call(state.navigation, "traverse_logic")
    local breed_actions = BreedActions[state.breed.name]
    local climb_action_data = breed_actions and breed_actions.climb
    local native_open_door_action_data = breed_actions and breed_actions.open_door
    local open_door_action_data = VersusModeState.controlled_open_door_action_data(state, native_open_door_action_data)

    if not origin
        or not aim_position
        or not nav_ok
        or not nav_world
        or door_target_unit and not open_door_action_data
        or not door_target_unit and not climb_action_data then
        set_status(state, mod:localize("controlled_traversal_unavailable"), 3)
        mod:warning(
            "Versus Mode: controlled %s traversal prerequisites unavailable "
                .. "(origin=%s, aim=%s, nav_call=%s, nav_world=%s, action=%s).",
            tostring(state.breed and state.breed.name or "enemy"),
            tostring(origin ~= nil),
            tostring(aim_position ~= nil),
            tostring(nav_ok == true),
            tostring(nav_world ~= nil),
            tostring(door_target_unit ~= nil and open_door_action_data ~= nil
                or door_target_unit == nil and climb_action_data ~= nil)
        )

        return false
    end

    local offset = aim_position - origin
    local distance = vector3_length(offset)
    local minimum_distance = requested_destination and 0.5 or 1.5

    if distance < minimum_distance then
        set_status(state, mod:localize("controlled_traversal_aim_farther"), 2.5)
        mod:info(
            "Versus Mode: controlled %s traversal destination was only %.2f m away (minimum %.2f m).",
            tostring(state.breed and state.breed.name or "enemy"),
            distance,
            minimum_distance
        )

        return false
    end

    if distance > VersusModeState.traversal_max_distance then
        aim_position = origin + vector3_normalize(offset) * VersusModeState.traversal_max_distance
    end

    local position_ok, destination

    if requested_destination then
        position_ok, destination = true, requested_destination
    else
        position_ok, destination = pcall(
            VersusModeState.nav_queries.position_on_mesh_guaranteed,
            nav_world,
            aim_position,
            6,
            12,
            traverse_ok and traverse_logic or nil,
            4,
            0.35
        )
    end

    if not position_ok or not destination or vector3_distance(origin, destination) < minimum_distance then
        set_status(state, mod:localize("controlled_traversal_no_destination"), 3)
        mod:warning(
            "Versus Mode: controlled %s could not validate its traversal destination "
                .. "(query=%s, destination=%s).",
            tostring(state.breed and state.breed.name or "enemy"),
            tostring(position_ok == true),
            tostring(destination ~= nil)
        )

        return false
    end

    local selected_link = not door_target_unit
        and type(traversal_metadata) == "table"
        and traversal_metadata.smart_object_id ~= nil
        and traversal_metadata.near_position
        and traversal_metadata.layer_type
    local route_destination = selected_link and traversal_metadata.near_position or destination

    pause_brain(state)

    local behavior_component = state.blackboard and state.blackboard.behavior
    local speed = (state.breed.run_speed or state.old_max_speed or 4) * setting("move_speed_percent") * 0.01

    refresh_engine_position(state.unit)
    safe_extension_call(state.navigation, "stop")

    local enabled_ok = safe_extension_call(state.navigation, "set_enabled", true, speed)
    local move_ok = enabled_ok and safe_extension_call(state.navigation, "move_to", route_destination)

    if not behavior_component or not move_ok then
        safe_extension_call(state.navigation, "set_enabled", false)

        if selected_link then
            VersusModeState.reject_controlled_traversal_link(
                state,
                traversal_metadata.smart_object_id,
                "the authored entrance route could not start"
            )
        end

        set_status(state, mod:localize("controlled_traversal_unavailable"), 3)
        mod:warning(
            "Versus Mode: controlled %s could not start its traversal route "
                .. "(behavior=%s, navigation_enabled=%s, move_to=%s).",
            tostring(state.breed and state.breed.name or "enemy"),
            tostring(behavior_component ~= nil),
            tostring(enabled_ok == true),
            tostring(move_ok == true)
        )

        return false
    end

    local start_time = gameplay_time()

    behavior_component.move_state = "moving"
    state.controlled_traversal = {
        climb_action_data = climb_action_data,
        completion_armed = false,
        door_target_unit = door_target_unit,
        open_door_action_data = open_door_action_data,
        mutant_door_timing_adjusted = native_open_door_action_data ~= open_door_action_data,
        deadline = start_time + VersusModeState.traversal_timeout,
        destination = Vector3Box(destination),
        entrance_completion_armed = false,
        entrance_best_remaining = selected_link and vector3_distance(origin, route_destination) or nil,
        entrance_progress_at = selected_link and start_time or nil,
        entrance_started_at = selected_link and start_time or nil,
        expected_layer_type = selected_link and traversal_metadata.layer_type or nil,
        expected_smart_object_id = selected_link and traversal_metadata.smart_object_id or nil,
        last_update = start_time,
        link_route_retries = 0,
        phase = door_target_unit and "door_pathing" or selected_link and "entrance_pathing" or "pathing",
        selected_far_position = selected_link and Vector3Box(traversal_metadata.far_position or destination) or nil,
        selected_near_position = selected_link and Vector3Box(traversal_metadata.near_position) or nil,
        speed = speed,
    }
    state.moving = true
    safe_anim_event(state.animation, "move_fwd")
    set_status(
        state,
        mod:localize(door_target_unit and "controlled_door_pathing" or "controlled_traversal_pathing"),
        VersusModeState.traversal_timeout
    )
    if selected_link then
        mod:info(
            "Versus Mode: controlled %s approaching authored entrance %.1f m away for smart object %s (%s); "
                .. "selected exit is %.1f m away at height delta %+.1f m.",
            tostring(state.breed.name),
            vector3_distance(origin, route_destination),
            tostring(traversal_metadata.smart_object_id),
            tostring(traversal_metadata.layer_type),
            vector3_distance(origin, destination),
            Vector3.z(destination) - Vector3.z(route_destination)
        )
    else
        mod:info(
            door_target_unit
                and "Versus Mode: controlled %s navigating %.1f m through aimed enemy door (height delta %.1f m)."
                or "Versus Mode: controlled %s navigating %.1f m to aimed traversal destination (height delta %.1f m).",
            tostring(state.breed.name),
            vector3_distance(origin, destination),
            Vector3.z(destination) - Vector3.z(origin)
        )
    end

    return true
end

function VersusModeState.door_world_position(door_unit, door_extension, fallback)
    local box_ok, position_box = pcall(function()
        return door_extension and door_extension._broadphase_check_position
    end)

    if box_ok and position_box then
        local position_ok, position = pcall(function()
            return position_box:unbox()
        end)

        if position_ok and position then
            return position
        end
    end

    return live_world_position(door_unit) or fallback
end

function VersusModeState.contextual_traversal_in_front(state, near_position, far_position)
    local origin = state and live_world_position(state.unit)

    if not origin or not near_position then
        return false, -1
    end

    local offset = Vector3.flat(near_position - origin)

    -- Standing exactly on the entrance is valid; use its far side to infer
    -- the intended direction when possible. A purely vertical ledge at the
    -- current horizontal position is also safe to treat as facing forward.
    if vector3_length(offset) <= 0.05 and far_position then
        offset = Vector3.flat(far_position - origin)
    end

    if vector3_length(offset) <= 0.05 then
        return true, 1
    end

    local yaw = state.yaw or 0
    local camera_forward = Vector3(math_sin(yaw), math_cos(yaw), 0)
    local forward_dot = vector3_dot(vector3_normalize(offset), camera_forward)

    return forward_dot >= VersusModeState.contextual_traversal_min_forward_dot, forward_dot
end

function VersusModeState.native_enemy_door_available(door_unit)
    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, nav_graph_system = pcall(function()
        return extension_manager and extension_manager:system("nav_graph_system")
    end)
    local extension_map = system_ok
        and nav_graph_system
        and nav_graph_system._smart_object_id_to_extension

    if type(extension_map) ~= "table" then
        return false
    end

    for smart_object_id, nav_graph_extension in pairs(extension_map) do
        local unit_ok, owner_unit = safe_extension_call(nav_graph_extension, "unit")

        if unit_ok and owner_unit == door_unit then
            local layer_ok, layer_type = safe_extension_call(
                nav_graph_system,
                "smart_object_layer_type",
                smart_object_id
            )
            local graph_ok, graph_added = safe_extension_call(
                nav_graph_extension,
                "nav_graph_added",
                smart_object_id
            )

            if layer_ok and layer_type == "doors" and graph_ok and graph_added then
                return true
            end
        end
    end

    return false
end

function VersusModeState.aimed_enemy_door(state)
    local origin = state and live_world_position(state.unit)

    if not origin then
        return nil
    end

    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, door_system = pcall(function()
        return extension_manager and extension_manager:system("door_system")
    end)
    local extension_map = system_ok and door_system and door_system._unit_to_extension_map

    if type(extension_map) ~= "table" then
        return nil
    end

    local best_unit
    local best_extension
    local best_position
    local best_score = math.huge

    for door_unit, door_extension in pairs(extension_map) do
        if ALIVE[door_unit] then
            local door_position = VersusModeState.door_world_position(door_unit, door_extension)

            if door_position then
                local distance = vector3_distance(door_position, origin)
                local attackers_ok, attackers = safe_extension_call(door_extension, "num_attackers")
                local can_open_ok, can_open = safe_extension_call(door_extension, "can_open")
                local in_front = VersusModeState.contextual_traversal_in_front(state, door_position)

                if distance <= VersusModeState.contextual_traversal_distance
                    and in_front
                    and VersusModeState.native_enemy_door_available(door_unit)
                    and can_open_ok
                    and can_open
                    and (not attackers_ok or type(attackers) ~= "number" or attackers <= 0) then
                    local score = distance

                    if score < best_score then
                        best_unit = door_unit
                        best_extension = door_extension
                        best_position = door_position
                        best_score = score
                    end
                end
            end
        end
    end

    return best_unit, best_extension, best_position
end

function VersusModeState.nearby_controlled_climb_destination(state)
    local origin = state and live_world_position(state.unit)
    local extension_manager = Managers.state and Managers.state.extension
    local system_ok, nav_graph_system = pcall(function()
        return extension_manager and extension_manager:system("nav_graph_system")
    end)
    local smart_object_map = system_ok and nav_graph_system and nav_graph_system._smart_object_id_to_extension

    if not origin or type(smart_object_map) ~= "table" then
        return nil
    end

    local best_destination
    local best_layer
    local best_distance = math.huge
    local best_forward_dot
    local best_score = math.huge
    local best_metadata

    local function consider_candidate(
        smart_object_id,
        near_position,
        far_position,
        near_distance,
        far_distance,
        layer_type,
        bidirectional,
        smart_object_data
    )
        if VersusModeState.controlled_traversal_link_rejected(state, smart_object_id) then
            return
        end

        -- The native movement completion gate treats anything within 1.25 m
        -- as already arrived. Do not offer a smart object whose far endpoint
        -- would therefore complete before its climb/drop action can begin.
        if near_distance > VersusModeState.contextual_traversal_distance or far_distance <= 1.25 then
            return
        end

        -- A one-way ledge may remain loaded from both sides. Only accept its
        -- authored entrance when the controlled enemy is actually on that
        -- side; otherwise an exit just behind/under the player can masquerade
        -- as a valid entrance and create an immediate no-op route.
        if not bidirectional and near_distance > far_distance + 0.15 then
            return
        end

        local in_front, forward_dot =
            VersusModeState.contextual_traversal_in_front(state, near_position, far_position)

        if not in_front then
            return
        end

        if not VersusModeState.controlled_climb_candidate_supported(
            state,
            layer_type,
            near_position,
            far_position,
            smart_object_data,
            origin
        ) then
            return
        end

        local ledge_type = smart_object_data and smart_object_data.ledge_type
        local height_delta = Vector3.z(far_position) - Vector3.z(near_position)

        local vertical = math.abs(height_delta) >= VersusModeState.traversal_minimum_height_delta
        local native_fence = ledge_type == "narrow_fence" or ledge_type == "thick_fence"

        -- Equal-height endpoints are valid for a native vault over an authored
        -- fence or waist-high gate. The previous blanket height gate rejected
        -- those real crossings along with the exposed flat links that caused
        -- apparent mid-air climbs. Require Darktide's own fence classification
        -- for a flat route; generic flat edge/cover links remain unavailable.
        if not vertical and not native_fence then
            return
        end

        -- Keep the old preference for a nearby real climb/drop when it overlaps
        -- a flat fence route, while still allowing the fence by itself.
        local score = near_distance
            + (vertical and 0 or VersusModeState.traversal_flat_fence_score_penalty)

        if score < best_score then
            -- SmartObject:get_entrance_exit_positions returns engine-temporary
            -- Vector3 userdata. It is valid for this query only and becomes a
            -- [Stale Vector3] when a contextual candidate is retained for the
            -- next HUD frame. Own both endpoints before caching the candidate.
            local near_position_box = VersusModeState.controlled_traversal_position_box(near_position)
            local far_position_box = VersusModeState.controlled_traversal_position_box(far_position)

            if not near_position_box or not far_position_box then
                return
            end

            best_destination = far_position_box
            best_layer = layer_type
            best_distance = near_distance
            best_forward_dot = forward_dot
            best_score = score
            best_metadata = {
                bidirectional = bidirectional == true,
                destination_distance = far_distance,
                far_position = far_position_box,
                height_delta = height_delta,
                layer_type = layer_type,
                ledge_type = ledge_type,
                near_position = near_position_box,
                smart_object_id = smart_object_id,
            }
        end
    end

    for smart_object_id, extension in pairs(smart_object_map) do
        local object_ok, smart_object = pcall(extension.smart_object_from_id, extension, smart_object_id)
        local graph_ok, graph_added = safe_extension_call(extension, "nav_graph_added", smart_object_id)

        if object_ok and smart_object and graph_ok and graph_added then
            local layer_ok, layer_type = pcall(smart_object.layer_type, smart_object)

            if layer_ok
                and (layer_type == "ledges"
                    or layer_type == "ledges_with_fence"
                    or layer_type == "cover_ledges") then
                local positions_ok, entrance, exit = pcall(smart_object.get_entrance_exit_positions, smart_object)
                local bidirectional_ok, bidirectional = pcall(smart_object.is_bidirectional, smart_object)
                local data_ok, smart_object_data = pcall(smart_object.data, smart_object)
                smart_object_data = data_ok and type(smart_object_data) == "table"
                    and smart_object_data or nil

                if positions_ok and entrance and exit then
                    local entrance_distance = vector3_distance(origin, entrance)
                    local exit_distance = vector3_distance(origin, exit)
                    local is_bidirectional = bidirectional_ok and bidirectional == true

                    consider_candidate(
                        smart_object_id,
                        entrance,
                        exit,
                        entrance_distance,
                        exit_distance,
                        layer_type,
                        is_bidirectional,
                        smart_object_data
                    )

                    if is_bidirectional then
                        consider_candidate(
                            smart_object_id,
                            exit,
                            entrance,
                            exit_distance,
                            entrance_distance,
                            layer_type,
                            true,
                            smart_object_data
                        )
                    end
                end
            end
        end
    end

    return best_destination, best_layer, best_distance, best_forward_dot, best_metadata
end

function VersusModeState.controlled_contextual_traversal_candidate(state, force_refresh)
    if not state
        or not state.possessed
        or not VersusModeState.controlled_traversal_enabled()
        or not VersusModeState.controlled_traversal_breed_supported(state.breed) then
        if state then
            state.contextual_traversal_candidate = nil
        end

        return nil
    end

    if state.controlled_traversal or state.remote_traversal_active then
        local traversal = state.controlled_traversal

        return {
            busy = true,
            kind = state.remote_traversal_kind
                or traversal and traversal.door_target_unit and "door"
                or "climb",
        }
    end

    if state.attack_deadline or VersusModeState.controlled_traversal_carrying_player(state) then
        state.contextual_traversal_candidate = nil

        return nil
    end

    -- A Realms client has no authoritative minion navigation extension. Use
    -- the complete candidate replicated by the host; querying the client's
    -- partially streamed nav graph produced a text prompt with no trajectory.
    if state.remote_client then
        if not state.remote_traversal_available then
            return nil
        end

        return state.remote_traversal_candidate or {
            kind = state.remote_traversal_kind or "door",
        }
    end

    local t = gameplay_time()

    if not force_refresh and t < (state.contextual_traversal_refresh_at or 0) then
        return state.contextual_traversal_candidate or nil
    end

    state.contextual_traversal_refresh_at = t + VersusModeState.traversal_highlight_refresh_interval

    local candidate

    if VersusModeState.controlled_traversal_breed_supported(state.breed, "door") then
        local door_unit, door_extension, door_position = VersusModeState.aimed_enemy_door(state)

        if door_unit then
            candidate = {
                door_extension = door_extension,
                door_position = door_position,
                door_unit = door_unit,
                kind = "door",
            }
        end
    end

    if not candidate and VersusModeState.controlled_traversal_breed_supported(state.breed, "climb") then
        local destination, layer_type, distance, forward_dot, metadata =
            VersusModeState.nearby_controlled_climb_destination(state)

        if destination and metadata then
            local height_delta = metadata.height_delta or 0
            local destination_box = VersusModeState.controlled_traversal_position_box(destination)
            local near_position_box = VersusModeState.controlled_traversal_position_box(metadata.near_position)
            local far_position_box = VersusModeState.controlled_traversal_position_box(metadata.far_position)

            if destination_box and near_position_box and far_position_box then
                local persistent_metadata = {}

                for key, value in pairs(metadata) do
                    persistent_metadata[key] = value
                end

                persistent_metadata.near_position = near_position_box
                persistent_metadata.far_position = far_position_box
                candidate = {
                    destination = destination_box,
                    distance = distance,
                    forward_dot = forward_dot,
                    kind = height_delta >= VersusModeState.traversal_minimum_height_delta and "climb"
                        or height_delta <= -VersusModeState.traversal_minimum_height_delta and "drop"
                        or "vault",
                    layer_type = layer_type,
                    metadata = persistent_metadata,
                }
            end
        end
    end

    state.contextual_traversal_candidate = candidate

    return candidate
end

function VersusModeState.controlled_traversal_hud_line(state)
    local candidate = VersusModeState.controlled_contextual_traversal_candidate(state)

    if not candidate then
        return nil
    end

    local text_key = candidate.kind == "door" and "controlled_context_action_door"
        or candidate.kind == "drop" and "controlled_context_action_drop"
        or candidate.kind == "vault" and "controlled_context_action_vault"
        or candidate.kind == "climb" and "controlled_context_action_climb"
        or "controlled_context_action"

    return {
        label = VersusModeState.enemy_control_keybind_label("controlled_traverse_keybind"),
        text = mod:localize(text_key),
        kind = candidate.busy and "busy" or "normal",
    }
end

-- Reuse the exact contextual traversal query for presentation. This keeps the
-- highlight honest: if the marker is visible, pressing Jump submits that same
-- oriented smart-object ID and entrance/exit pair. No marker is networked or
-- added to Darktide's global world-marker registry.
mod.traversal_highlight_hud_data = function()
    local state = mod._control

    if not state
        or not state.possessed
        or not VersusModeState.controlled_traversal_enabled()
        or not VersusModeState.controlled_traversal_breed_supported(state.breed, "climb")
        or state.attack_deadline
        or state.controlled_traversal
        or state.remote_traversal_active
        or VersusModeState.controlled_traversal_carrying_player(state) then
        if state then
            state.traversal_highlight_cache = nil
        end

        return nil
    end

    local candidate = VersusModeState.controlled_contextual_traversal_candidate(state)

    if not candidate or candidate.kind == "door" or candidate.busy then
        state.traversal_highlight_cache = nil

        return nil
    end

    local destination = candidate.destination
    local layer_type = candidate.layer_type
    local distance = candidate.distance
    local metadata = candidate.metadata

    local entrance_box = metadata
        and VersusModeState.controlled_traversal_position_box(metadata.near_position)
    local destination_box = metadata
        and VersusModeState.controlled_traversal_position_box(metadata.far_position)

    if not destination or not metadata or not entrance_box or not destination_box then
        state.traversal_highlight_cache = nil
        state.contextual_traversal_candidate = nil

        return nil
    end

    local kind = candidate.kind
    local kind_key = kind == "climb" and "controlled_traversal_highlight_climb"
        or kind == "drop" and "controlled_traversal_highlight_drop"
        or "controlled_traversal_highlight_vault"
    local keybind = VersusModeState.enemy_control_keybind_label("controlled_traverse_keybind")

    state.traversal_highlight_cache = {
        destination = destination_box,
        entrance = entrance_box,
        kind = kind,
        label = mod:localize(
            "controlled_traversal_highlight_label",
            mod:localize(kind_key),
            keybind,
            distance or 0
        ),
        layer_type = layer_type,
        smart_object_id = metadata.smart_object_id,
    }

    return state.traversal_highlight_cache
end

function VersusModeState.start_contextual_traversal(state)
    if not state or not state.possessed or state.remote_client then
        return false
    end

    if not VersusModeState.controlled_traversal_enabled() then
        set_status(state, mod:localize("controlled_traversal_disabled"), 2.5)

        return false
    end

    if state.controlled_traversal then
        set_status(state, mod:localize("controlled_traversal_native_busy"), 2.5)

        return false
    end

    if state.attack_deadline or VersusModeState.controlled_traversal_carrying_player(state) then
        set_status(state, mod:localize("controlled_traversal_attack_busy"), 2.5)

        return false
    end

    local candidate = VersusModeState.controlled_contextual_traversal_candidate(state, true)

    if candidate and candidate.kind == "door" then
        return VersusModeState.start_controlled_door_traversal(state)
    elseif candidate and candidate.destination then
        local metadata = candidate.metadata
        local destination = VersusModeState.controlled_traversal_data_position(candidate.destination)
        local near_position = metadata
            and VersusModeState.controlled_traversal_data_position(metadata.near_position)
        local far_position = metadata
            and VersusModeState.controlled_traversal_data_position(metadata.far_position)

        if not destination or not near_position or not far_position then
            state.contextual_traversal_candidate = nil
            state.traversal_highlight_cache = nil
            set_status(state, mod:localize("controlled_context_nothing_nearby"), 2.5)

            return false
        end

        local traversal_metadata = {}

        for key, value in pairs(metadata) do
            traversal_metadata[key] = value
        end

        traversal_metadata.near_position = near_position
        traversal_metadata.far_position = far_position

        mod:info(
            "Versus Mode: %s selected camera-forward native %s traversal at %.1f m "
                .. "(dot %.2f, height %+.1f m, destination %.1f m, %s) with Jump.",
            tostring(state.breed.name),
            tostring(candidate.layer_type),
            candidate.distance or 0,
            candidate.forward_dot or 1,
            metadata and metadata.height_delta or 0,
            metadata and metadata.destination_distance or 0,
            metadata and metadata.bidirectional and "bidirectional" or "one-way"
        )

        return VersusModeState.start_controlled_traversal(state, destination, nil, traversal_metadata)
    end

    set_status(state, mod:localize("controlled_context_nothing_nearby"), 2.5)

    return false
end

function VersusModeState.start_controlled_door_traversal(state)
    if not state or not state.possessed or state.remote_client then
        return false
    end

    if not VersusModeState.controlled_traversal_enabled() then
        set_status(state, mod:localize("controlled_traversal_disabled"), 2.5)

        return false
    end

    if not VersusModeState.controlled_traversal_breed_supported(state.breed, "door") then
        set_status(state, mod:localize("controlled_traversal_specialist_only"), 2.5)

        return false
    end

    if state.attack_deadline or VersusModeState.controlled_traversal_carrying_player(state) then
        set_status(state, mod:localize("controlled_traversal_attack_busy"), 2.5)

        return false
    end

    if state.controlled_traversal and state.controlled_traversal.native_started then
        set_status(state, mod:localize("controlled_traversal_native_busy"), 2.5)

        return false
    end

    if state.controlled_traversal then
        VersusModeState.finish_controlled_traversal(state, "cancelled", false, true)
    end

    local door_unit, door_extension, door_position = VersusModeState.aimed_enemy_door(state)
    local origin = live_world_position(state.unit)

    if not door_unit or not door_extension or not door_position or not origin then
        set_status(state, mod:localize("controlled_context_nothing_nearby"), 3)

        return false
    end

    local attackers_ok, attackers = safe_extension_call(door_extension, "num_attackers")
    local can_open_ok, can_open = safe_extension_call(door_extension, "can_open")

    if attackers_ok and type(attackers) == "number" and attackers > 0 then
        set_status(state, mod:localize("controlled_door_occupied"), 3)

        return false
    end

    if not can_open_ok or not can_open then
        set_status(state, mod:localize("controlled_door_unavailable"), 3)

        return false
    end

    local direction = Vector3.flat(door_position - origin)
    local breed_actions = BreedActions[state.breed.name]
    local action_data = VersusModeState.controlled_open_door_action_data(
        state,
        breed_actions and breed_actions.open_door
    )

    if not action_data or vector3_length(direction) <= 0.01 then
        set_status(state, mod:localize("controlled_door_unavailable"), 3)

        return false
    end

    direction = vector3_normalize(direction)
    local open_door_time = action_data.open_door_time
    local offset = action_data.open_door_time_offset
    local optional_closing_time = open_door_time
        and open_door_time + (offset or 0.2)
        or offset

    safe_extension_call(state.navigation, "stop")
    safe_extension_call(state.navigation, "set_enabled", false)
    safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
    safe_extension_call(state.locomotion, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))

    local behavior_component = state.blackboard and state.blackboard.behavior

    if behavior_component then
        behavior_component.move_state = "idle"
    end

    local open_ok, open_error = pcall(function()
        door_extension:open(nil, state.unit, optional_closing_time)
    end)

    if not open_ok then
        set_status(state, mod:localize("controlled_door_unavailable"), 3)
        mod:warning(
            "Versus Mode: controlled %s could not invoke the native enemy-door API (%s).",
            tostring(state.breed.name),
            tostring(open_error)
        )

        return false
    end

    safe_anim_event(state.animation, action_data.open_door_anim_event or "idle")
    state.moving = false
    set_status(
        state,
        mod:localize("controlled_traversal_opening_door"),
        math_max(1, (open_door_time or 0) + 0.5)
    )

    mod:info(
        "Versus Mode: controlled %s opened a nearby enemy door at %.1f m through Darktide's native door API.",
        tostring(state.breed.name),
        vector3_distance(origin, door_position)
    )

    return true
end

function VersusModeState.update_controlled_traversal(state)
    local traversal = state and state.controlled_traversal

    if not traversal then
        return false
    end

    local t = gameplay_time()
    local dt = math_max(0, math_min(0.1, t - (traversal.last_update or t)))

    traversal.last_update = t

    if not ALIVE[state.unit] then
        VersusModeState.restore_controlled_traversal_layer_cost(state, traversal)
        state.controlled_traversal = nil

        return true
    end

    if t >= (traversal.deadline or 0) then
        VersusModeState.finish_controlled_traversal(state, mod:localize("controlled_traversal_timeout"))

        return true
    end

    if traversal.native_started then
        local native_action = traversal.native_action
        local action_data = traversal.native_action_data

        if not native_action or not action_data then
            VersusModeState.finish_controlled_traversal(state, "native traversal state was lost")

            return true
        end

        local run_ok, result = pcall(
            native_action.run,
            native_action,
            state.unit,
            state.breed,
            state.blackboard,
            traversal.scratchpad,
            action_data,
            dt,
            t
        )

        if not run_ok or result == "failed" then
            if traversal.native_kind == "climb" and traversal.expected_smart_object_id then
                VersusModeState.reject_controlled_traversal_link(
                    state,
                    traversal.expected_smart_object_id,
                    run_ok and "the native climb action rejected the selected link"
                        or "the native climb action raised an error"
                )
            end

            VersusModeState.finish_controlled_traversal(
                state,
                run_ok and "native " .. tostring(traversal.native_kind or "traversal") .. " rejected" or result
            )

            return true
        elseif result == "done" then
            local completed_kind = traversal.native_kind
            local completed_position = live_world_position(state.unit)

            pcall(
                native_action.leave,
                native_action,
                state.unit,
                state.breed,
                state.blackboard,
                traversal.scratchpad,
                action_data,
                t,
                "done",
                false
            )
            traversal.native_started = nil
            traversal.native_action = nil
            traversal.native_action_data = nil
            traversal.native_kind = nil
            traversal.scratchpad = nil
            -- move_to() can retain the previous route's reached flag for one
            -- update. Require the resumed route to report pending at least
            -- once, or physically reach the destination, before completing.
            traversal.completion_armed = false
            traversal.phase = traversal.door_target_unit and "door_pathing"
                or traversal.expected_smart_object_id and "link_exit_pathing"
                or "pathing"

            if completed_kind == "climb" and traversal.expected_smart_object_id then
                traversal.selected_native_completed = true
                VersusModeState.restore_controlled_traversal_layer_cost(state, traversal)
            end

            if completed_kind == "door" then
                traversal.door_native_completed_at = t
                traversal.mutant_door_progress_at = t
                traversal.mutant_door_retry_at = t + VersusModeState.mutant_door_retry_interval
                traversal.mutant_door_retry_count = 0
                traversal.mutant_door_best_remaining = completed_position
                    and vector3_distance(completed_position, traversal.destination:unbox())
                    or nil
                safe_anim_event(state.animation, "move_fwd")
                state.moving = true
            end

            local behavior_component = state.blackboard and state.blackboard.behavior

            if behavior_component then
                behavior_component.move_state = "moving"
            end

            safe_extension_call(state.navigation, "set_enabled", true, traversal.speed)
            safe_extension_call(state.navigation, "move_to", traversal.destination:unbox())
            set_status(
                state,
                mod:localize(completed_kind == "door" and "controlled_door_crossing" or "controlled_traversal_pathing"),
                math_max(0, traversal.deadline - t)
            )

            if completed_kind == "door" then
                mod:info(
                    "Versus Mode: controlled %s completed native door action; resuming exit route "
                        .. "(Mutant close-timing adjustment=%s).",
                    tostring(state.breed.name),
                    tostring(traversal.mutant_door_timing_adjusted == true)
                )
            end
        end

        return true
    end

    local reached_ok, reached = safe_extension_call(state.navigation, "has_reached_destination")
    local position = live_world_position(state.unit)
    local destination = traversal.destination:unbox()
    local remaining = position and vector3_distance(position, destination) or math.huge
    local failed_ok, failed_attempts = safe_extension_call(state.navigation, "failed_move_attempts")

    if traversal.phase == "entrance_pathing" then
        local entrance = traversal.selected_near_position
            and traversal.selected_near_position:unbox()
        local entrance_remaining = position and entrance
            and vector3_distance(position, entrance)
            or math.huge
        local entrance_best = traversal.entrance_best_remaining or entrance_remaining

        if entrance_remaining + 0.1 < entrance_best then
            traversal.entrance_best_remaining = entrance_remaining
            traversal.entrance_progress_at = t
        end

        if failed_ok and type(failed_attempts) == "number" and failed_attempts >= 3 then
            VersusModeState.retry_controlled_traversal_link(
                state,
                traversal,
                "selected ledge entrance pathfinding failed",
                t
            )

            return true
        end

        if reached_ok and not reached then
            traversal.entrance_completion_armed = true
        end

        local physically_committed = entrance_remaining <= VersusModeState.traversal_entrance_commit_distance
        local stale_reissued = traversal.stale_entrance_reached_at
            and t > traversal.stale_entrance_reached_at
        local footprint_committed = (traversal.entrance_completion_armed or stale_reissued)
            and entrance_remaining <= VersusModeState.controlled_traversal_entrance_distance(state)

        if physically_committed or footprint_committed then
            VersusModeState.commit_controlled_traversal_link(state, traversal, t)

            return true
        end

        if reached_ok
            and reached
            and not traversal.entrance_completion_armed
            and not traversal.stale_entrance_reached_logged then
            traversal.stale_entrance_reached_logged = true
            traversal.stale_entrance_reached_at = t
            local reissued_ok = safe_extension_call(state.navigation, "move_to", entrance)

            mod:info(
                "Versus Mode: controlled %s ignored stale entrance completion %.1f m from smart object %s "
                    .. "and reissued the approach=%s.",
                tostring(state.breed and state.breed.name or "enemy"),
                entrance_remaining,
                tostring(traversal.expected_smart_object_id or "unknown"),
                tostring(reissued_ok == true)
            )
        end

        if traversal.stale_entrance_reached_at
            and t >= traversal.stale_entrance_reached_at + VersusModeState.traversal_stale_entrance_timeout
            and entrance_remaining > VersusModeState.controlled_traversal_entrance_distance(state) then
            VersusModeState.reject_controlled_traversal_link(
                state,
                traversal.expected_smart_object_id,
                "navigation could not acquire the authored entrance"
            )
            VersusModeState.finish_controlled_traversal(state, "selected ledge entrance was unreachable")

            return true
        end

        if traversal.entrance_completion_armed
            and t >= (traversal.entrance_progress_at or traversal.entrance_started_at or t)
                + VersusModeState.traversal_entrance_progress_timeout
            and entrance_remaining > VersusModeState.controlled_traversal_entrance_distance(state) then
            VersusModeState.reject_controlled_traversal_link(
                state,
                traversal.expected_smart_object_id,
                "the entrance approach stopped making progress"
            )
            VersusModeState.finish_controlled_traversal(state, "selected ledge entrance was unreachable")

            return true
        end

        local path_ok, _, next_position = safe_extension_call(
            state.navigation,
            "current_and_next_node_positions_in_path"
        )

        if path_ok and next_position and position then
            local facing = Vector3.flat(next_position - position)

            if vector3_length(facing) > 0.01 then
                safe_extension_call(
                    state.locomotion,
                    "set_wanted_rotation",
                    Quaternion.look(vector3_normalize(facing), vector3_up())
                )
            end
        end

        return true
    end

    if reached_ok and not reached then
        traversal.completion_armed = true
    end

    local selected_climb_pending = traversal.expected_smart_object_id ~= nil
        and traversal.selected_native_completed ~= true

    if not selected_climb_pending
        and (remaining <= 1.25 or traversal.completion_armed and reached_ok and reached) then
        VersusModeState.finish_controlled_traversal(state, "done")

        return true
    end

    if reached_ok
        and reached
        and not traversal.completion_armed
        and not traversal.stale_reached_logged then
        traversal.stale_reached_logged = true
        local reissued_ok = safe_extension_call(state.navigation, "move_to", destination)

        mod:info(
            "Versus Mode: controlled %s ignored stale traversal completion %.1f m from its destination "
                .. "and reissued the fresh route=%s.",
            tostring(state.breed and state.breed.name or "enemy"),
            remaining,
            tostring(reissued_ok == true)
        )
    end

    VersusModeState.update_mutant_door_clearance(state, traversal, t, position, destination)

    if failed_ok and type(failed_attempts) == "number" and failed_attempts >= 3 then
        if selected_climb_pending then
            VersusModeState.retry_controlled_traversal_link(
                state,
                traversal,
                "selected ledge pathfinding failed",
                t
            )
        else
            VersusModeState.finish_controlled_traversal(state, "pathfinding failed")
        end

        return true
    end

    local smart_object = state.blackboard and state.blackboard.nav_smart_object
    local smart_object_present = smart_object and smart_object.id ~= -1
    local smart_object_type = smart_object and smart_object.type
    local smart_object_ready = smart_object
        and smart_object.id ~= -1
        and smart_object.entrance_is_at_bot_progress_on_path
    local selected_interval_matches, selected_interval_detail, selected_parallel_interval =
        VersusModeState.controlled_traversal_interval_matches(traversal, smart_object)

    if selected_climb_pending and traversal.phase == "link_pathing" then
        if selected_parallel_interval
            and traversal.resolved_smart_object_id ~= smart_object.id then
            traversal.resolved_smart_object_id = smart_object.id
            mod:info(
                "Versus Mode: controlled %s accepted a route-equivalent parallel ledge: %s.",
                tostring(state.breed and state.breed.name or "enemy"),
                tostring(selected_interval_detail or smart_object.id)
            )
        end

        if smart_object_present and not selected_interval_matches then
            traversal.unexpected_smart_object_id = smart_object.id
            VersusModeState.retry_controlled_traversal_link(
                state,
                traversal,
                selected_interval_detail or "navigation selected a different ledge",
                t
            )

            return true
        end

        if smart_object_present and selected_interval_matches then
            traversal.expected_link_seen = true
        end

        if not (smart_object_ready and selected_interval_matches)
            and t >= (traversal.link_route_started_at or t) + VersusModeState.traversal_link_acquire_timeout then
            VersusModeState.retry_controlled_traversal_link(
                state,
                traversal,
                "navigation did not acquire the selected ledge",
                t
            )

            return true
        end
    end

    local climb_ready = smart_object_ready
        and not traversal.door_target_unit
        and (not traversal.expected_smart_object_id
            or traversal.phase == "link_pathing" and selected_interval_matches)
        and (smart_object_type == "ledges"
            or smart_object_type == "ledges_with_fence"
            or smart_object_type == "cover_ledges")
    local door_ready = false

    if smart_object_ready
        and smart_object_type == "doors"
        and traversal.door_target_unit
        and traversal.open_door_action_data then
        local target_matches = smart_object.unit == traversal.door_target_unit

        if target_matches then
            local common_ok, at_smart_object = pcall(
                BtConditions.at_smart_object,
                state.unit,
                state.blackboard,
                {},
                nil,
                traversal.open_door_action_data,
                false
            )
            local door_ok, at_door = pcall(
                BtConditions.at_door_smart_object,
                state.unit,
                state.blackboard,
                {},
                nil,
                traversal.open_door_action_data,
                false
            )

            door_ready = common_ok and at_smart_object and door_ok and at_door
        end

        if traversal.last_door_diagnostic_id ~= smart_object.id then
            local door_extension = safe_extension(smart_object.unit, "door_system")
            local can_open_ok, can_open = safe_extension_call(door_extension, "can_open")
            local blocked_ok, nav_blocked = safe_extension_call(door_extension, "nav_blocked")
            local attackers_ok, attackers = safe_extension_call(door_extension, "num_attackers")

            traversal.last_door_diagnostic_id = smart_object.id
            mod:info(
                "Versus Mode: controlled %s reached native door smart object %s "
                    .. "(target_match=%s, vanilla gate=%s, can_open=%s, nav_blocked=%s, attackers=%s).",
                tostring(state.breed.name),
                tostring(smart_object.id),
                tostring(target_matches),
                tostring(door_ready),
                tostring(can_open_ok and can_open or "unknown"),
                tostring(blocked_ok and nav_blocked or "unknown"),
                tostring(attackers_ok and attackers or "unknown")
            )
        end
    end

    if climb_ready or door_ready then
        local native_action = climb_ready and VersusModeState.climb_action or VersusModeState.open_door_action
        local action_data = climb_ready and traversal.climb_action_data or traversal.open_door_action_data
        local native_kind = climb_ready and "climb" or "door"
        local scratchpad = {}
        local enter_ok, enter_error = pcall(
            native_action.enter,
            native_action,
            state.unit,
            state.breed,
            state.blackboard,
            scratchpad,
            action_data,
            t
        )

        if not enter_ok or scratchpad.failed_to_use_smart_object then
            if not enter_ok then
                safe_extension_call(state.navigation, "use_smart_object", false)
                safe_extension_call(state.locomotion, "set_anim_driven", false, false, false)
                safe_extension_call(state.locomotion, "set_movement_type", "snap_to_navmesh")
                safe_extension_call(state.locomotion, "set_anim_translation_scale", Vector3(1, 1, 1))
            end

            local native_error = enter_ok
                and "native smart object was occupied"
                or tostring(enter_error)

            if climb_ready and traversal.expected_smart_object_id then
                VersusModeState.retry_controlled_traversal_link(state, traversal, native_error, t)
            else
                VersusModeState.finish_controlled_traversal(state, native_error)
            end

            return true
        end

        traversal.native_started = true
        traversal.native_action = native_action
        traversal.native_action_data = action_data
        traversal.native_kind = native_kind
        traversal.scratchpad = scratchpad
        traversal.phase = climb_ready and "climbing" or "opening_door"

        if not climb_ready then
            state.moving = false
        end

        if climb_ready then
            local entrance = smart_object.entrance_position:unbox()
            local exit = smart_object.exit_position:unbox()
            local direction_key = Vector3.z(exit) >= Vector3.z(entrance)
                and "controlled_traversal_climbing_up"
                or "controlled_traversal_climbing_down"

            set_status(state, mod:localize(direction_key), math_max(0, traversal.deadline - t))
            mod:info(
                "Versus Mode: controlled %s entered native %s traversal (height delta %.1f m).",
                tostring(state.breed.name),
                tostring(smart_object_type),
                Vector3.z(exit) - Vector3.z(entrance)
            )
        else
            set_status(state, mod:localize("controlled_traversal_opening_door"), math_max(0, traversal.deadline - t))
            mod:info(
                "Versus Mode: controlled %s entered Darktide's native enemy-door action for smart object %s.",
                tostring(state.breed.name),
                tostring(smart_object.id)
            )
        end

        return true
    end

    local path_ok, _, next_position = safe_extension_call(state.navigation, "current_and_next_node_positions_in_path")

    if path_ok and next_position and position then
        local facing = Vector3.flat(next_position - position)

        if vector3_length(facing) > 0.01 then
            safe_extension_call(state.locomotion, "set_wanted_rotation", Quaternion.look(vector3_normalize(facing), vector3_up()))
        end
    end

    return true
end

function VersusModeState.camera_recovery_distance(previous, allowed, dt)
    -- Never smooth inward through a wall. Only the outward recovery eases.
    if not previous or allowed <= previous then
        return allowed
    end

    return math_min(allowed, previous + 8 * math_max(0, math_min(0.1, dt)))
end

function VersusModeState.third_person_camera(state, position, look_direction, flat_forward)
    local specialist_elite_camera = not state.breed.is_boss
        and (is_specialist_breed(state.breed) or VersusModeState.controlled_elite_breeds[state.breed.name])
    -- Perspectives applies its 2 m boom after Darktide's native
    -- character_height * 1.1 up-translation. Breed base_height is the
    -- equivalent stable minion measurement; a flat 1 m from the unit root
    -- incorrectly placed humanoid enemies around waist height.
    local height = specialist_elite_camera
        and ((type(state.breed.base_height) == "number"
            and state.breed.base_height * VersusModeState.specialist_camera_height_scale
            or VersusModeState.specialist_camera_fallback_height)
            + setting("specialist_camera_height_adjustment"))
        or state.remote_camera_height or setting("camera_height")
    local distance = specialist_elite_camera and setting("specialist_camera_distance")
        or state.remote_camera_distance or setting("camera_distance")
    local focus = position + vector3_up() * height
    local manager = Managers.state and Managers.state.camera
    local ok, safe_focus = safe_extension_call(manager, "_smooth_camera_collision",
        focus, position + vector3_up() * 0.5, 0.25, 0.18)

    if ok and safe_focus then
        focus = safe_focus
    end

    local free_aim = Specialist.free_aim(state)
    local wanted

    if specialist_elite_camera then
        -- A positive camera-side offset moves the camera right, placing the
        -- controlled enemy left of the reticle in classic shoulder view.
        local camera_right = Vector3(Vector3.y(flat_forward), -Vector3.x(flat_forward), 0)

        wanted = focus
            - flat_forward * distance
            + camera_right * setting("specialist_camera_horizontal_offset")
    elseif free_aim then
        wanted = focus - flat_forward * distance + vector3_up() * 0.5
    else
        wanted = focus - look_direction * distance
    end
    local hit_ok, collision_position = safe_extension_call(manager, "_smooth_camera_collision",
        wanted, focus, 0.3, 0.2)
    local t = gameplay_time()

    if hit_ok and collision_position then
        local offset = wanted - focus
        local wanted_distance = Vector3.length(offset)
        local allowed = math_min(wanted_distance, Vector3.distance(focus, collision_position))
        local dt = state.camera_collision_at and t - state.camera_collision_at or 0
        local recovered = VersusModeState.camera_recovery_distance(state.camera_collision_distance, allowed, dt)

        state.camera_collision_distance = recovered
        state.camera_collision_at = t
        wanted = focus + Vector3.normalize(offset) * recovered

        if allowed < wanted_distance - 0.25 and t >= (state.camera_collision_log_at or 0) then
            state.camera_collision_log_at = t + 5
            mod:info("Versus Mode: third-person camera collision %.2f -> %.2f m (%s).",
                wanted_distance, recovered, tostring(state.breed and state.breed.name))
        end
    elseif t >= (state.camera_collision_warning_at or 0) then
        state.camera_collision_warning_at = t + 10
        state.camera_collision_distance = nil
        state.camera_collision_at = nil
        mod:warning("Versus Mode: third-person camera collision query unavailable; fixed-distance fallback.")
    end

    -- At zero clearance retain the intended look direction, never look(zero).
    return wanted, Quaternion.look(look_direction, vector3_up())
end

local function update_camera(state)
    local free_flight = Managers.free_flight
    local position = live_world_position(state.unit)

    if free_flight and not free_flight:is_in_free_flight() and not state.camera_recovery_attempted then
        state.camera_recovery_attempted = true
        mod._suppress_freeflight_toggle_frames = 3

        local camera_data = free_flight._free_flight_cameras and free_flight._free_flight_cameras.global

        if camera_data then
            free_flight:_enter_global_free_flight(camera_data)
        end
    end

    if not free_flight or not free_flight:is_in_free_flight() or not position then
        release_possession("camera became unavailable; control released.")

        return
    end

    VersusModeState.refresh_controlled_first_person_visibility(state)
    VersusModeState.update_sniper_scope(state)

    local look_direction, flat_forward = state_look_direction(state)
    local camera_position
    local camera_rotation

    if state.first_person then
        camera_position = sniper_camera_position(state, look_direction, flat_forward)
        camera_rotation = Quaternion.look(look_direction, vector3_up())
    else
        camera_position, camera_rotation = VersusModeState.third_person_camera(state, position, look_direction, flat_forward)
    end

    local scope_progress = state.breed.name == SNIPER_BREED_NAME
        and math_max(0, math_min(1, state.sniper_scope_progress or 0))
        or 0

    if scope_progress > 0 then
        local scope_position = sniper_camera_position(state, look_direction, flat_forward)
        local eased_progress = scope_progress * scope_progress * (3 - 2 * scope_progress)

        camera_position = camera_position + (scope_position - camera_position) * eased_progress
        camera_rotation = Quaternion.look(look_direction, vector3_up())
    end

    state.camera_position = Vector3Box(camera_position)
    state.camera_rotation = camera_rotation
    state.look_direction = look_direction

    free_flight:teleport_camera("global", camera_position, camera_rotation)
end

function VersusModeState.update_remote_camera_pose(state)
    local position = state and live_world_position(state.unit)

    if not position then
        return false
    end

    local look_direction, flat_forward = state_look_direction(state)
    local camera_position
    local camera_rotation

    if state.first_person
        or state.breed.name == SNIPER_BREED_NAME and state.sniper_laser_active then
        camera_position = sniper_camera_position(state, look_direction, flat_forward)
        camera_rotation = Quaternion.look(look_direction, vector3_up())
    else
        camera_position, camera_rotation = VersusModeState.third_person_camera(state, position, look_direction, flat_forward)
    end

    state.camera_position = Vector3Box(camera_position)
    state.camera_rotation = camera_rotation
    state.look_direction = look_direction

    return true
end

function VersusModeState.update_remote_authoritative_movement(state, gunner_shooting)
    local input = state.remote_input
    local t = gameplay_time()
    local forward_amount = input and t - (input.received_at or 0) <= 0.5 and input.forward or 0
    local right_amount = input and t - (input.received_at or 0) <= 0.5 and input.right or 0

    if gunner_shooting then
        VersusModeState.update_gunner_shoot_movement(state, forward_amount, right_amount)

        return
    end

    local forward = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)
    local right = Vector3(math_cos(state.yaw), -math_sin(state.yaw), 0)
    local direction = forward * forward_amount + right * right_amount
    local amount = vector3_length(direction)

    if amount > 0.01 then
        direction = vector3_normalize(direction)

        local speed = (state.breed.run_speed or state.old_max_speed or 4) * setting("move_speed_percent") * 0.01

        state.locomotion:set_wanted_velocity_flat(direction * speed)
        state.locomotion:set_wanted_rotation(Quaternion.look(state.first_person and forward or direction, vector3_up()))

        if not state.moving then
            safe_anim_event(state.animation, "move_fwd")
            state.animation_heartbeat_last_event = "move_fwd"
            state.moving = true
        end
    else
        state.locomotion:set_wanted_velocity_flat(Vector3.zero())

        if state.first_person or Specialist.free_aim(state) then
            state.locomotion:set_wanted_rotation(Quaternion.look(forward, vector3_up()))
        end

        if state.moving then
            safe_anim_event(state.animation, "idle")
            state.animation_heartbeat_last_event = "idle"
            state.moving = false
        end
    end
end

function VersusModeState.update_remote_client_control(state)
    if not state or not state.remote_client then
        return false
    end

    if not ALIVE[state.unit] then
        VersusModeState.release_client_control("controlled enemy disappeared; waiting for the host.", true)

        return false
    end

    VersusModeState.ensure_controlled_animation_lod(state)

    -- Native minion animation RPCs remain the primary path. A mirrored event
    -- waits briefly in this queue and is applied only if the native RPC hook
    -- did not acknowledge the exact event index first.
    VersusModeState.update_remote_animation_fallback(state)

    local t = gameplay_time()

    -- Status packets normally resolve the target immediately. Retry here as
    -- well because a Realms client can receive the target identity before its
    -- corresponding player husk and outline extension finish spawning.
    if t >= (state.next_remote_target_resolution_at or 0) then
        state.next_remote_target_resolution_at = t + 0.25
        VersusModeState.refresh_remote_target_resolution(state)
    end

    if not update_manual_look(state) then
        state.remote_forward = 0
        state.remote_right = 0
    else
        state.remote_forward = Keyboard.button(Keyboard.button_index("w")) - Keyboard.button(Keyboard.button_index("s"))
        state.remote_right = Keyboard.button(Keyboard.button_index("d")) - Keyboard.button(Keyboard.button_index("a"))
    end

    update_camera(state)
    update_manual_aim_preview(state)

    -- A Realms client returns from the main update immediately after this
    -- function, so its local crosshair candidate must be reconciled here,
    -- after the camera ray has updated. Resolving replicated target identity
    -- above is intentionally earlier because the player husk may have spawned
    -- late, but it cannot substitute for this frame's free-aim candidate.
    local presentation_target = VersusModeState.presentation_target_outline(state)

    if state.outlined_target ~= presentation_target then
        refresh_target_outline(state)
    end

    if mod._control ~= state then
        return false
    end

    if t >= (state.next_input_send_at or 0) then
        state.remote_input_sequence = (state.remote_input_sequence or 0) + 1
        state.next_input_send_at = t + 0.05

        local sent, send_error = mod._realms_compat.send_input({
            camera_distance = setting("camera_distance"),
            camera_height = setting("camera_height"),
            first_person = state.first_person == true,
            forward = state.remote_forward or 0,
            pitch = state.pitch,
            right = state.remote_right or 0,
            sequence = state.remote_input_sequence,
            yaw = state.yaw,
        })

        if not sent and t >= (state.input_warning_at or 0) then
            state.input_warning_at = t + 3
            set_status(state, "NETWORK INPUT WAITING: " .. tostring(send_error), 2.5)
        end
    end

    return true
end

function VersusModeState.automatic_respawn_failure(role, reason, peer_id)
    if not role then
        return false
    end

    local t = gameplay_time()
    local readable_reason = tostring(reason or mod:localize("hud_invalid_location"))

    role.automatic_respawn_reason = readable_reason

    if t >= (role.automatic_respawn_notice_at or 0) then
        role.automatic_respawn_notice_at = t + VersusModeState.automatic_respawn_notice_interval

        if peer_id then
            VersusModeState.send_remote_respawn_notice(
                peer_id,
                "notice_automatic_respawn_retry",
                role,
                nil,
                readable_reason
            )
        elseif VersusModeState.local_role() == role then
            VersusModeState.echo_localized("notice_automatic_respawn_retry", VersusModeState.localize_hud_text(readable_reason))
        end

        mod:info(
            "Versus Mode: automatic Random Safe respawn for %s will retry (%s).",
            tostring(role.infected_name or peer_id or "infected player"),
            readable_reason
        )
    end

    return false
end

function VersusModeState.try_respawn(role, automatic)
    role = role or mod._versus_role_test

    if mod._death_camera or not role or VersusModeState.local_role() ~= role or not VersusModeState.local_active() then
        return false
    end

    if not role.respawn_breed then
        VersusModeState.schedule_respawn(role)

        return false
    end

    local remaining = (role.respawn_ready_at or math.huge) - gameplay_time()

    if remaining > 0 then
        VersusModeState.echo_localized(
            "hud_spawn_available_seconds",
            VersusModeState.respawn_label(role.respawn_breed, role.respawn_variant),
            remaining
        )

        return false
    end

    local valid, reason, spawn_position, spawn_rotation = VersusModeState.spawn_position_for_role(role)

    if not valid then
        if automatic then
            return VersusModeState.automatic_respawn_failure(role, reason)
        end

        VersusModeState.echo_localized("hud_cannot_respawn", VersusModeState.localize_hud_text(tostring(reason)))

        return false
    end

    local minion_spawn_manager = Managers.state and Managers.state.minion_spawn

    if not minion_spawn_manager then
        if automatic then
            return VersusModeState.automatic_respawn_failure(role, mod:localize("hud_spawn_manager_unavailable"))
        end

        VersusModeState.echo_localized("hud_spawn_manager_unavailable")

        return false
    end

    local breed_name = role.respawn_breed
    local variant_id = role.respawn_variant
    local param_table = minion_spawn_manager:request_param_table()

    param_table.optional_aggro_state = "aggroed"
    local spawn_ok, spawned_unit = pcall(
        minion_spawn_manager.spawn_minion,
        minion_spawn_manager,
        breed_name,
        spawn_position,
        spawn_rotation,
        2,
        param_table
    )

    if not spawn_ok or not spawned_unit or not ALIVE[spawned_unit] then
        if mod._random_spawn_reservations then
            mod._random_spawn_reservations[role] = nil
        end

        mod:error("Infected spawn failed: " .. tostring(spawned_unit))

        if automatic then
            return VersusModeState.automatic_respawn_failure(role, mod:localize("hud_specialist_spawn_failed"))
        end

        VersusModeState.echo_localized("hud_specialist_spawn_failed")

        return false
    end

    role.respawn_breed = nil
    role.respawn_variant = nil
    role.respawn_ready_at = nil
    role.respawn_ready_notified = nil
    role.spawn_check = nil
    role.spawn_check_at = nil
    role.automatic_respawn_retry_at = nil
    role.automatic_respawn_notice_at = nil
    role.automatic_respawn_reason = nil
    role.automatic_respawn_not_before = nil

    local player = local_player()
    local possessed = player and begin_possession(spawned_unit, player, player.player_unit, nil, role, variant_id)

    if possessed and mod._control then
        mod._control.infected_spawn = true
        role.assigned_boss_unit = spawned_unit
        VersusModeState.publish_roster()

        return true
    end

    pcall(minion_spawn_manager.despawn_minion, minion_spawn_manager, spawned_unit)
    -- A failed possession is a retry of this choice, not a new random life.
    role.respawn_breed = breed_name
    role.respawn_variant = variant_id
    role.respawn_ready_at = gameplay_time()
    role.assigned_boss_unit = nil
    VersusModeState.publish_roster()

    if automatic then
        VersusModeState.automatic_respawn_failure(role, mod:localize("hud_specialist_spawn_failed"))
    end

    return false
end

function VersusModeState.encode_remote_traversal_candidate(payload, candidate)
    if type(payload) ~= "table" or not candidate or candidate.kind == "door" then
        return payload
    end

    local metadata = candidate.metadata
    local near_position = metadata
        and VersusModeState.controlled_traversal_data_position(metadata.near_position)
    local far_position = metadata
        and VersusModeState.controlled_traversal_data_position(metadata.far_position)

    if not near_position or not far_position then
        return payload
    end

    payload.traversal_distance = candidate.distance
    payload.traversal_layer_type = candidate.layer_type
    payload.traversal_smart_object_id = metadata.smart_object_id
    payload.traversal_near_x = Vector3.x(near_position)
    payload.traversal_near_y = Vector3.y(near_position)
    payload.traversal_near_z = Vector3.z(near_position)
    payload.traversal_far_x = Vector3.x(far_position)
    payload.traversal_far_y = Vector3.y(far_position)
    payload.traversal_far_z = Vector3.z(far_position)

    return payload
end

function VersusModeState.decode_remote_traversal_candidate(payload)
    if type(payload) ~= "table"
        or payload.traversal_available ~= true
        or payload.traversal_active == true
        or payload.traversal_kind ~= "climb"
            and payload.traversal_kind ~= "drop"
            and payload.traversal_kind ~= "vault"
        or payload.traversal_layer_type ~= "ledges"
            and payload.traversal_layer_type ~= "ledges_with_fence"
            and payload.traversal_layer_type ~= "cover_ledges" then
        return nil
    end

    local values = {
        payload.traversal_near_x,
        payload.traversal_near_y,
        payload.traversal_near_z,
        payload.traversal_far_x,
        payload.traversal_far_y,
        payload.traversal_far_z,
    }

    for i = 1, 6 do
        local value = values[i]

        if type(value) ~= "number"
            or value ~= value
            or math.abs(value) > 1000000 then
            return nil
        end
    end

    local distance = payload.traversal_distance
    local smart_object_id = payload.traversal_smart_object_id

    if type(distance) ~= "number"
        or distance ~= distance
        or distance < 0
        or distance > VersusModeState.contextual_traversal_distance + 1
        or type(smart_object_id) ~= "number"
        or smart_object_id ~= smart_object_id
        or smart_object_id % 1 ~= 0
        or smart_object_id < 0
        or smart_object_id > 2147483647 then
        return nil
    end

    local near_position = Vector3(values[1], values[2], values[3])
    local far_position = Vector3(values[4], values[5], values[6])
    local near_box = VersusModeState.controlled_traversal_position_box(near_position)
    local far_box = VersusModeState.controlled_traversal_position_box(far_position)

    if not near_box or not far_box then
        return nil
    end

    return {
        destination = far_box,
        distance = distance,
        kind = payload.traversal_kind,
        layer_type = payload.traversal_layer_type,
        metadata = {
            far_position = far_box,
            height_delta = Vector3.z(far_position) - Vector3.z(near_position),
            layer_type = payload.traversal_layer_type,
            near_position = near_box,
            smart_object_id = smart_object_id,
        },
    }
end

function VersusModeState.send_remote_status(peer_id, message, kind, state, notice)
    local traversal_candidate = state
        and VersusModeState.controlled_contextual_traversal_candidate(state)
    local locked_target = state
        and VersusModeState.valid_attack_target(state.locked_target, state)
        and state.locked_target
        or nil
    local outline_target = locked_target
        or state
            and VersusModeState.valid_attack_target(state.manual_aim_hit_unit, state)
            and state.manual_aim_hit_unit
        or state
            and VersusModeState.valid_attack_target(state.attack_target, state)
            and state.attack_target
        or nil
    local target_reference = VersusModeState.remote_target_reference(locked_target)
    local outline_target_reference = VersusModeState.remote_target_reference(outline_target)

    if mod._realms_compat then
        local payload = {
            attack_active = state and state.attack_deadline ~= nil or false,
            attack_cancellable = state and state.requested_attack
                and state.requested_attack.cancellable == true or false,
            attack_label = state and state.requested_attack and state.requested_attack.label or nil,
            attack_phase = state and state.attack_phase,
            casual_combat = state and state.casual_combat,
            grenadier_target_lock = state and state.grenadier_target_lock,
            kind = kind or "info",
            locomotion_event = state
                and not state.attack_deadline
                and not state.controlled_traversal
                and not state.poxburster_armed
                and (state.moving and "move_fwd" or "idle")
                or nil,
            message = message,
            mutant_carrying = state and state.mutant_carrying == true or false,
            netter_cooldown_remaining = state and math_max(0, (state.netter_fire_cooldown_until or 0) - gameplay_time()) or 0,
            notice_breed = notice and notice.breed or nil,
            notice_echo = notice and notice.echo == true or false,
            notice_key = notice and notice.key or nil,
            notice_reason = notice and notice.reason or nil,
            notice_seconds = notice and notice.seconds or nil,
            notice_variant = notice and notice.variant or nil,
            poxburster_armed = state and state.poxburster_armed == true or false,
            sniper_cooldown_remaining = state and math_max(0, (state.sniper_fire_cooldown_until or 0) - gameplay_time()) or 0,
            sniper_laser_active = state and state.sniper_laser_active == true or false,
            sniper_shot_fired = state and state.sniper_shot_fired == true or false,
            target_name = target_reference and target_reference.name
                or locked_target and target_name(locked_target) or nil,
            target_reference = target_reference,
            target_unit_id = target_reference and target_reference.unit_id or nil,
            outline_target_reference = outline_target_reference,
            outline_target_unit_id = outline_target_reference and outline_target_reference.unit_id or nil,
            traversal_active = state and state.controlled_traversal ~= nil or false,
            traversal_available = traversal_candidate ~= nil,
            traversal_kind = traversal_candidate and traversal_candidate.kind or nil,
        }

        VersusModeState.encode_remote_traversal_candidate(payload, traversal_candidate)
        mod._realms_compat.send_status(peer_id, payload)
    end
end

function VersusModeState.send_remote_respawn_notice(peer_id, key, role, seconds, reason)
    if not peer_id or type(key) ~= "string" then
        return false
    end

    VersusModeState.send_remote_status(peer_id, nil, "waiting", nil, {
        breed = role and role.respawn_breed or nil,
        echo = true,
        key = key,
        reason = reason,
        seconds = seconds,
        variant = role and role.respawn_variant or nil,
    })

    return true
end

function VersusModeState.try_remote_respawn(peer_id, payload, automatic)
    peer_id = VersusModeState.normalize_peer_id(peer_id)
    payload = type(payload) == "table" and payload or {}

    if not is_server()
        or not setting("enable_versus_mode")
        or not mod._realms_compat
        or not mod._realms_compat.peer_compatible(peer_id) then
        return false
    end

    local role = VersusModeState.role_for_peer(peer_id)

    if not role or not role.infected_human then
        return false
    end

    if VersusModeState.control_for_peer(peer_id) or role.assigned_boss_unit then
        if not automatic then
            VersusModeState.send_remote_status(peer_id, "You already control an enemy.", "error")
        end

        return false
    end

    local t = gameplay_time()

    if t < (role.remote_spawn_request_at or 0) then
        return false
    end

    role.remote_spawn_request_at = t + 0.2

    if not role.respawn_breed then
        VersusModeState.schedule_respawn(role)
    end

    local remaining = (role.respawn_ready_at or math.huge) - t

    if remaining > 0 then
        if not automatic then
            VersusModeState.send_remote_status(peer_id, string.format(
                "%s will be available in %.1f seconds.",
                VersusModeState.respawn_label(role.respawn_breed, role.respawn_variant),
                remaining
            ), "waiting")
        end

        return false
    end

    local valid, reason, spawn_position, spawn_rotation = VersusModeState.spawn_position_for_role(role, payload)

    if not valid then
        if automatic then
            return VersusModeState.automatic_respawn_failure(role, reason, peer_id)
        end

        VersusModeState.send_remote_status(peer_id, "Cannot respawn — " .. tostring(reason) .. ".", "error")

        return false
    end

    local minion_spawn_manager = Managers.state and Managers.state.minion_spawn

    if not minion_spawn_manager then
        if automatic then
            return VersusModeState.automatic_respawn_failure(role, "The minion spawn manager is unavailable", peer_id)
        end

        VersusModeState.send_remote_status(peer_id, "The minion spawn manager is unavailable.", "error")

        return false
    end

    local breed_name = role.respawn_breed
    local variant_id = role.respawn_variant
    local param_table = minion_spawn_manager:request_param_table()

    param_table.optional_aggro_state = "aggroed"
    local spawn_ok, spawned_unit = pcall(
        minion_spawn_manager.spawn_minion,
        minion_spawn_manager,
        breed_name,
        spawn_position,
        spawn_rotation,
        2,
        param_table
    )

    if not spawn_ok or not spawned_unit or not ALIVE[spawned_unit] then
        if mod._random_spawn_reservations then
            mod._random_spawn_reservations[role] = nil
        end

        if automatic then
            return VersusModeState.automatic_respawn_failure(
                role,
                "The selected infected could not be spawned at this location",
                peer_id
            )
        end

        VersusModeState.send_remote_status(peer_id, "The selected infected could not be spawned at this location.", "error")

        return false
    end

    role.respawn_breed = nil
    role.respawn_variant = nil
    role.respawn_ready_at = nil
    role.respawn_ready_notified = nil
    role.spawn_check = nil
    role.spawn_check_at = nil
    role.automatic_respawn_retry_at = nil
    role.automatic_respawn_notice_at = nil
    role.automatic_respawn_reason = nil
    role.automatic_respawn_not_before = nil

    local possessed = begin_possession(
        spawned_unit,
        role.infected_player,
        role.infected_player and role.infected_player.player_unit,
        peer_id,
        role,
        variant_id
    )
    local state = VersusModeState.control_for_peer(peer_id)

    if possessed and state then
        state.infected_spawn = true
        role.assigned_boss_unit = spawned_unit
        VersusModeState.publish_roster()
        VersusModeState.send_remote_status(peer_id, "Control ready.", "ready", state)

        return true
    end

    pcall(minion_spawn_manager.despawn_minion, minion_spawn_manager, spawned_unit)
    -- A failed possession is a retry of this choice, not a new random life.
    role.respawn_breed = breed_name
    role.respawn_variant = variant_id
    role.respawn_ready_at = gameplay_time()
    role.assigned_boss_unit = nil
    VersusModeState.publish_roster()

    if automatic then
        VersusModeState.automatic_respawn_failure(role, "The selected infected could not be controlled", peer_id)
    end

    return false
end

function VersusModeState.try_bot_respawn(role)
    if not VersusModeState.bot_reinforcement_enabled(role)
        or role.assigned_boss_unit
        or role.autonomous_bot_unit then
        return false
    end

    if not role.respawn_breed then
        VersusModeState.schedule_respawn(role)

        return false
    end

    if gameplay_time() < (role.respawn_ready_at or math.huge) then
        return false
    end

    local valid, reason, spawn_position, spawn_rotation = VersusModeState.spawn_position_for_role(role)

    if not valid then
        return VersusModeState.automatic_respawn_failure(role, reason)
    end

    local minion_spawn_manager = Managers.state and Managers.state.minion_spawn

    if not minion_spawn_manager then
        return VersusModeState.automatic_respawn_failure(role, mod:localize("hud_spawn_manager_unavailable"))
    end

    local breed_name = role.respawn_breed
    local param_table = minion_spawn_manager:request_param_table()

    param_table.optional_aggro_state = "aggroed"
    local spawn_ok, spawned_unit = pcall(
        minion_spawn_manager.spawn_minion,
        minion_spawn_manager,
        breed_name,
        spawn_position,
        spawn_rotation,
        2,
        param_table
    )

    if not spawn_ok or not spawned_unit or not ALIVE[spawned_unit] then
        if mod._random_spawn_reservations then
            mod._random_spawn_reservations[role] = nil
        end

        return VersusModeState.automatic_respawn_failure(
            role,
            mod:localize("hud_specialist_spawn_failed")
        )
    end

    role.respawn_breed = nil
    role.respawn_variant = nil
    role.respawn_ready_at = nil
    role.respawn_ready_notified = nil
    role.spawn_check = nil
    role.spawn_check_at = nil
    role.automatic_respawn_retry_at = nil
    role.automatic_respawn_notice_at = nil
    role.automatic_respawn_reason = nil
    role.automatic_respawn_not_before = nil
    role.assigned_boss_unit = spawned_unit
    role.autonomous_bot_unit = spawned_unit
    role.autonomous_bot_roster_pending = true
    role.autonomous_health_state = {
        unit = spawned_unit,
        breed = VersusModeState.breeds[breed_name],
    }

    local health_setting_id = VersusModeState.controlled_health_setting_id(role.autonomous_health_state)

    if health_setting_id
        and not VersusModeState.rescale_controlled_health(
            role.autonomous_health_state,
            setting(health_setting_id)
        ) then
        mod:warning(
            "Versus Mode: could not apply the Heretic health multiplier to %s's AI %s.",
            tostring(role.infected_name or "bot"),
            tostring(breed_name)
        )
    end

    mod:info(
        "Versus Mode: deployed temporary AI Heretic %s for %s.",
        tostring(breed_name),
        tostring(role.infected_name or "bot")
    )
    VersusModeState.publish_roster()

    return true
end

function VersusModeState.reset_redeployment_geography()
    mod._redeployment_geography_anchor = nil
    mod._redeployment_geography_travel = nil
    mod._redeployment_geography_segment = nil
    mod._redeployment_geography_refresh_at = nil
    mod._redeployment_transition_cooldown_until = nil
end

function VersusModeState.note_redeployment_transition(reason)
    if not is_server() or not VersusModeState.test_active() then
        return false
    end

    local t = gameplay_time()

    if t < (mod._redeployment_transition_cooldown_until or 0) then
        return false
    end

    mod._redeployment_transition_cooldown_until = t
        + VersusModeState.redeployment_transition_cooldown

    local local_role = VersusModeState.local_role()
    local wake_at = t + VersusModeState.redeployment_streaming_settle_time
    local notified = 0
    local waiting = 0

    for _, role in pairs(VersusModeState.roles()) do
        if role.infected_human then
            if role == local_role then
                VersusModeState.echo_localized("notice_strike_team_advanced_redeploy")
                notified = notified + 1
            elseif role.infected_peer_id then
                local peer_id = VersusModeState.normalize_peer_id(role.infected_peer_id)

                if peer_id then
                    local control = VersusModeState.control_for_role(role)

                    VersusModeState.send_remote_status(peer_id, nil, "info", control, {
                        echo = true,
                        key = "notice_strike_team_advanced_redeploy",
                    })
                    notified = notified + 1
                end
            end
        end

        -- Living assignments are never recycled by a geography notification.
        -- A waiting role keeps its configured death countdown, but any stale
        -- failed-location retry is replaced by one fresh scan after streaming
        -- has had a short moment to settle around the advanced strike team.
        if role.respawn_breed and not role.assigned_boss_unit then
            role.spawn_check = nil
            role.spawn_check_at = nil
            role.automatic_respawn_retry_at = wake_at
            role.automatic_respawn_not_before = math_max(
                role.automatic_respawn_not_before or 0,
                wake_at
            )
            role.automatic_respawn_notice_at = 0
            role.automatic_respawn_reason = nil

            if mod._random_spawn_reservations then
                mod._random_spawn_reservations[role] = nil
            end

            waiting = waiting + 1
        end
    end

    mod:info(
        "Versus Mode: strike-team geography transition (%s); notified %d human Heretics "
            .. "and queued %d waiting redeployment scan(s) after %.1f s.",
        tostring(reason or "new area"),
        notified,
        waiting,
        VersusModeState.redeployment_streaming_settle_time
    )

    return notified > 0 or waiting > 0
end

function VersusModeState.update_redeployment_geography()
    if not is_server() or not VersusModeState.test_active() then
        VersusModeState.reset_redeployment_geography()

        return false
    end

    local t = gameplay_time()

    if t < (mod._redeployment_geography_refresh_at or 0) then
        return false
    end

    mod._redeployment_geography_refresh_at = t
        + VersusModeState.redeployment_geography_refresh_interval

    local _, anchor_position, anchor_unit = VersusModeState.random_spawn_survivors()

    if not anchor_position then
        return false
    end

    local main_path = Managers.state and Managers.state.main_path
    local travel_distance
    local segment_index

    if main_path and type(main_path.travel_distance_from_position) == "function" then
        local travel_ok, distance = pcall(
            main_path.travel_distance_from_position,
            main_path,
            anchor_position,
            true
        )

        travel_distance = travel_ok and type(distance) == "number" and distance or nil
    end

    if main_path and anchor_unit and type(main_path.segment_index_by_unit) == "function" then
        local segment_ok, segment = pcall(
            main_path.segment_index_by_unit,
            main_path,
            anchor_unit
        )

        segment_index = segment_ok and type(segment) == "number" and segment or nil
    elseif VersusModeState.main_path_queries
        and type(VersusModeState.main_path_queries.closest_position) == "function" then
        local segment_ok, _, _, _, _, segment = pcall(
            VersusModeState.main_path_queries.closest_position,
            anchor_position
        )

        segment_index = segment_ok and type(segment) == "number" and segment or nil
    end

    local previous_anchor = mod._redeployment_geography_anchor
        and mod._redeployment_geography_anchor:unbox()
    local previous_travel = mod._redeployment_geography_travel
    local previous_segment = mod._redeployment_geography_segment

    if not previous_anchor then
        mod._redeployment_geography_anchor = Vector3Box(anchor_position)
        mod._redeployment_geography_travel = travel_distance
        mod._redeployment_geography_segment = segment_index

        return false
    end

    local spatial_delta = previous_anchor
        and vector3_distance(previous_anchor, anchor_position)
        or 0
    local travel_delta = type(previous_travel) == "number" and type(travel_distance) == "number"
        and math.abs(travel_distance - previous_travel)
        or 0
    local segment_changed = type(previous_segment) == "number"
        and type(segment_index) == "number"
        and segment_index ~= previous_segment

    if segment_changed
        or spatial_delta >= VersusModeState.redeployment_transition_distance
        or travel_delta >= VersusModeState.redeployment_transition_distance then
        -- Advance the baseline even if the explicit-transition debounce is
        -- currently active, preventing the same geography jump from firing a
        -- second advisory after the cooldown expires.
        mod._redeployment_geography_anchor = Vector3Box(anchor_position)
        mod._redeployment_geography_travel = travel_distance
        mod._redeployment_geography_segment = segment_index

        local reason_text = segment_changed
            and string.format("main-path segment %d -> %d", previous_segment, segment_index)
            or string.format("strike team advanced %.1f m", math_max(spatial_delta, travel_delta))

        return VersusModeState.note_redeployment_transition(reason_text)
    end

    return false
end

function VersusModeState.update_automatic_respawns()
    if not is_server()
        or not setting("enable_versus_mode")
        or not VersusModeState.automatic_respawn_enabled()
        or not VersusModeState.random_safe_spawn_enabled() then
        return false
    end

    local t = gameplay_time()
    local attempted = false

    for _, role in pairs(VersusModeState.roles()) do
        local ready = role.respawn_breed
            and t >= (role.respawn_ready_at or math.huge)
            and t >= (role.automatic_respawn_not_before or 0)
            and t >= (role.automatic_respawn_retry_at or 0)
            and t >= (role.spawn_picker_until or 0)
            and not role.assigned_boss_unit

        if ready then
            if not role.infected_human then
                role.automatic_respawn_retry_at = t + VersusModeState.automatic_respawn_retry_interval
                attempted = VersusModeState.try_bot_respawn(role) or attempted
            else
                local local_role = VersusModeState.local_role() == role
                local peer_id = not local_role and VersusModeState.normalize_peer_id(role.infected_peer_id) or nil
                local controllable_peer = local_role or peer_id
                    and mod._realms_compat
                    and mod._realms_compat.peer_compatible(peer_id)

                if controllable_peer
                    and not (local_role and mod._control)
                    and not (peer_id and VersusModeState.control_for_peer(peer_id)) then
                    role.automatic_respawn_retry_at = t + VersusModeState.automatic_respawn_retry_interval

                    if local_role then
                        attempted = VersusModeState.try_respawn(role, true) or attempted
                    else
                        attempted = VersusModeState.try_remote_respawn(peer_id, {}, true) or attempted
                    end
                end
            end
        end
    end

    return attempted
end

function VersusModeState.release_client_control(reason, controlled_unit_dead)
    local state = mod._control
    local pending = mod._pending_remote_control

    mod._pending_remote_control = nil

    if not state or not state.remote_client then
        if pending and reason then
            VersusModeState.echo_notice(tostring(reason))
        end

        return pending ~= nil
    end

    VersusModeState.restore_sniper_scope(state)
    VersusModeState.restore_controlled_first_person_visibility(state)
    VersusModeState.restore_controlled_animation_lod(state)

    if controlled_unit_dead and state.versus_role then
        VersusModeState.start_death_camera(state, state.versus_role)
    end

    state.possessed = false
    clear_target_outline(state)
    destroy_grenade_preview(state)
    Specialist.destroy_hound_preview(state)
    restore_original_first_person_equipment(state)
    restore_camera(state, controlled_unit_dead == true and VersusModeState.local_active())
    mod._control = nil

    if VersusModeState.local_active() then
        VersusModeState.maintain_wait_camera(mod._versus_role_test)
    end

    if reason then
        VersusModeState.echo_notice(tostring(reason))
    end

    return true
end

function VersusModeState.begin_client_control(payload)
    if is_server() or type(payload) ~= "table" or type(payload.unit_id) ~= "number" or type(payload.breed_name) ~= "string" then
        return false
    end

    local role = VersusModeState.local_role()

    if not VersusModeState.breeds[payload.breed_name] then
        return false
    end

    if payload.variant_id ~= nil
        and (type(payload.variant_id) ~= "string" or not VersusModeState.valid_variant(payload.breed_name, payload.variant_id)) then
        return false
    end

    if not role then
        mod._pending_remote_control = {
            deadline = mod._pending_remote_control and mod._pending_remote_control.deadline or gameplay_time() + 8,
            payload = payload,
        }

        return false
    end

    local unit = VersusModeState.unit_from_network_id(payload.unit_id)

    if not unit or not ALIVE[unit] then
        mod._pending_remote_control = {
            deadline = mod._pending_remote_control and mod._pending_remote_control.deadline or gameplay_time() + 8,
            payload = payload,
        }

        return false
    end

    if mod._control and mod._control.remote_client then
        VersusModeState.release_client_control(nil, false)
    end


    VersusModeState.finish_survivor_spectating(role)
    VersusModeState.finish_death_camera(false)
    VersusModeState.recycle_wait_camera_for_possession(role)

    local breed = VersusModeState.breeds[payload.breed_name]
    local blackboard = BLACKBOARDS[unit]
    local state = {
        animation = safe_extension(unit, "animation_system"),
        blackboard = blackboard,
        breed = breed,
        casual_combat = Specialist.casual_breed_supported(breed) and payload.casual_combat ~= false,
        first_person = breed.is_boss ~= true and setting("default_first_person_view") == true,
        grenadier_target_lock = (is_specialist_breed(breed) or VersusModeState.controlled_elite_breeds[breed.name])
            and not (HOUND_BREEDS[breed.name] or MANUAL_AIM_BREEDS[breed.name]),
        versus_role = role,
        network_unit_id = payload.unit_id,
        perception_component = blackboard and blackboard.perception,
        physics_world = blackboard and blackboard.spawn and blackboard.spawn.physics_world or VersusModeState.physics_world(),
        pitch = type(payload.pitch) == "number" and payload.pitch
            or not breed.is_boss and (is_specialist_breed(breed) or VersusModeState.controlled_elite_breeds[breed.name])
                and VersusModeState.specialist_camera_pitch or -0.18,
        player = local_player(),
        player_unit = local_player() and local_player().player_unit,
        possessed = true,
        remote_client = true,
        remote_animation_last_sequence = 0,
        remote_animation_native_credits = {},
        remote_animation_pending = {},
        remote_locomotion_event = nil,
        status_message = "READY",
        status_until = gameplay_time() + 2,
        unit = unit,
        variant_id = payload.variant_id,
        visual_loadout = safe_extension(unit, "visual_loadout_system"),
        yaw = type(payload.yaw) == "number" and payload.yaw or 0,
    }

    if not enter_camera(state) then
        mod._pending_remote_control = {
            deadline = mod._pending_remote_control and mod._pending_remote_control.deadline or gameplay_time() + 8,
            payload = payload,
        }

        return false
    end

    hide_original_first_person_equipment(state)
    VersusModeState.refresh_controlled_first_person_visibility(state, true)
    mod._control = state
    mod._pending_remote_control = nil
    mod._personal_panel_widget_suppression_logged = nil
    mod._personal_panel_suppression_failure_logged = nil
    mod._suppress_smart_tag_until = gameplay_time() + 0.75
    VersusModeState.ensure_controlled_animation_lod(state)
    VersusModeState.echo_localized("notice_realms_assignment", VersusModeState.controlled_label(state))

    return true
end

function VersusModeState.apply_remote_status(payload)
    if type(payload) ~= "table" then
        return
    end

    local state = mod._control
    local semantic_message = VersusModeState.remote_respawn_notice_message(payload)
    local message = semantic_message or type(payload.message) == "string" and payload.message or nil

    if state and state.remote_client then
        state.attack_deadline = payload.attack_active == true and math.huge or nil
        state.remote_attack_cancellable = payload.attack_cancellable == true
        state.remote_attack_label = type(payload.attack_label) == "string" and payload.attack_label or nil
        state.mutant_carrying = payload.mutant_carrying == true
        state.poxburster_armed = payload.poxburster_armed == true
        state.sniper_laser_active = payload.sniper_laser_active == true
        state.sniper_shot_fired = payload.sniper_shot_fired == true
        state.remote_traversal_active = payload.traversal_active == true
        state.remote_traversal_available = payload.traversal_available == true
        state.remote_traversal_kind = payload.traversal_kind == "door" and "door"
            or payload.traversal_kind == "climb" and "climb"
            or payload.traversal_kind == "drop" and "drop"
            or payload.traversal_kind == "vault" and "vault"
            or nil
        state.remote_traversal_candidate = VersusModeState.decode_remote_traversal_candidate(payload)
        state.traversal_highlight_cache = nil

        local locomotion_event = payload.locomotion_event == "move_fwd" and "move_fwd"
            or payload.locomotion_event == "idle" and "idle"
            or nil

        if locomotion_event ~= state.remote_locomotion_event then
            state.remote_locomotion_event = locomotion_event

            if locomotion_event then
                state.animation = safe_extension(state.unit, "animation_system") or state.animation
                safe_anim_event(state.animation, locomotion_event)
            end
        end

        if state.remote_traversal_available
            and state.remote_traversal_kind ~= "door"
            and not state.remote_traversal_candidate then
            state.remote_traversal_available = false
        end

        if type(payload.netter_cooldown_remaining) == "number"
            and payload.netter_cooldown_remaining == payload.netter_cooldown_remaining
            and payload.netter_cooldown_remaining >= 0
            and payload.netter_cooldown_remaining <= 60 then
            state.netter_fire_cooldown_until = gameplay_time() + payload.netter_cooldown_remaining
        end

        if type(payload.sniper_cooldown_remaining) == "number"
            and payload.sniper_cooldown_remaining == payload.sniper_cooldown_remaining
            and payload.sniper_cooldown_remaining >= 0
            and payload.sniper_cooldown_remaining <= 60 then
            state.sniper_fire_cooldown_until = gameplay_time() + payload.sniper_cooldown_remaining
        end

        if type(payload.attack_phase) == "string" then
            state.attack_phase = payload.attack_phase
        end

        if type(payload.casual_combat) == "boolean" and Specialist.casual_supported(state) then
            state.casual_combat = payload.casual_combat
        end

        if type(payload.grenadier_target_lock) == "boolean" then
            state.grenadier_target_lock = payload.grenadier_target_lock
        end

        -- An omitted target clears the previous label. Without this explicit
        -- reset a remote infected HUD could keep showing a survivor's name
        -- after that survivor entered stealth and the host dropped its lock.
        state.remote_target_name = type(payload.target_name) == "string" and payload.target_name or nil

        state.remote_locked_target_reference = type(payload.target_reference) == "table"
            and payload.target_reference
            or (payload.target_unit_id ~= nil or state.remote_target_name)
                and {
                    name = state.remote_target_name,
                    unit_id = payload.target_unit_id,
                }
            or nil
        state.remote_outline_target_reference = type(payload.outline_target_reference) == "table"
            and payload.outline_target_reference
            or payload.outline_target_unit_id ~= nil
                and {
                    name = state.remote_target_name,
                    unit_id = payload.outline_target_unit_id,
                }
            or nil

        VersusModeState.refresh_remote_target_resolution(state)

        if message then
            set_status(state, message, 2.5)
        end
    elseif mod._versus_role_test and message then
        mod._versus_role_test.network_status = message
        mod._versus_role_test.network_status_until = gameplay_time() + 2.5
    end

    if semantic_message and payload.notice_echo == true then
        mod:echo("Versus Mode: " .. semantic_message)
    elseif message and payload.kind == "error" then
        VersusModeState.echo_notice(message)
    end
end

mod.toggle_possession = function(is_pressed, force_action)
    if not force_action and not configured_keybind_should_fire("possess_keybind", is_pressed) then
        return
    end

    if control_input_ui_gated(mod._control) then
        return
    end

    if mod._control and VersusModeState.auto_boss_release_blocked(mod._control) then
        return
    end

    if mod._control and mod._control.remote_client then
        mod._realms_compat.send_action("release", (mod._remote_action_sequence or 0) + 1)
        mod._remote_action_sequence = (mod._remote_action_sequence or 0) + 1
        set_status(mod._control, "Release requested", 2)

        return
    elseif mod._control then
        release_possession("released.")

        return
    end

    if not is_server() then
        if mod._realms_compat and mod._realms_compat.is_client() and setting("enable_versus_mode") then
            local role = VersusModeState.local_role()
            local free_flight = Managers.free_flight
            local camera_position, camera_rotation
            local random_safe = VersusModeState.random_safe_spawn_enabled()

            if role and not random_safe and free_flight and free_flight:is_in_free_flight() then
                camera_position, camera_rotation = free_flight:camera_position_rotation("global")
            end

            if not role then
                VersusModeState.echo_localized("notice_not_assigned_infected")
            elseif not random_safe and (not camera_position or not camera_rotation) then
                VersusModeState.echo_localized("notice_infected_camera_unavailable")
            else
                local payload = {}

                if not random_safe then
                    local forward = Quaternion.forward(camera_rotation)

                    payload.pitch = math.asin(math_max(-1, math_min(1, Vector3.z(forward))))
                    payload.x = Vector3.x(camera_position)
                    payload.y = Vector3.y(camera_position)
                    payload.yaw = math_atan2(Vector3.x(forward), Vector3.y(forward))
                    payload.z = Vector3.z(camera_position)
                end

                local sent, send_error = mod._realms_compat.request_spawn(payload)

                if not sent then
                    VersusModeState.echo_localized("notice_respawn_request_failed", tostring(send_error))
                end
            end

            return
        end

        VersusModeState.echo_localized("notice_possession_host_only")

        return
    end

    local player = local_player()
    local player_unit = player and player.player_unit

    if not player_unit or not ALIVE[player_unit] then
        VersusModeState.echo_localized("notice_local_player_not_alive")

        return
    end

    if setting("enable_versus_mode") then
        local role = VersusModeState.local_role()

        if not role then
            VersusModeState.echo_localized("notice_local_not_assigned_infected")

            return
        end

        VersusModeState.try_respawn()

        return
    end

    local unit, unavailable_reason = find_controllable_enemy(player, player_unit)

    if not unit then
        if unavailable_reason == "daemonhost not awake" then
            VersusModeState.echo_localized("notice_daemonhost_not_awake")
        else
            VersusModeState.echo_localized("notice_no_enemy_in_range", setting("selection_range"))
        end

        return
    end

    begin_possession(unit, player, player_unit)
end

local function request_attack_for_state(state, slot, preferred_target, hound_aim_yaw, hound_aim_pitch, hound_charge_fraction)
    if not state or not state.possessed then
        return
    end

    if not state.controller_peer_id and control_input_ui_gated(state) then
        return
    end

    if state.controlled_traversal then
        if state.controlled_traversal.native_started then
            set_status(state, mod:localize("controlled_traversal_native_busy"), 2.5)

            return
        end

        VersusModeState.finish_controlled_traversal(state, "cancelled", false, true)
    end

    local breed_attacks = resolved_attacks_for_state(state)
    local attack = breed_attacks and breed_attacks[slot]

    if state.remote_client then
        local requested_target = preferred_target

        if not VersusModeState.valid_attack_target(requested_target, state)
            and attack
            and not attack.hound_trajectory
            and not attack.hound_instant_pounce then
            if attack.manual_aim and VersusModeState.valid_attack_target(state.manual_aim_hit_unit, state) then
                requested_target = state.manual_aim_hit_unit
            elseif Specialist.free_aim(state) and attack.grenadier_path ~= "far" then
                requested_target = Specialist.free_aim_attack_target(state)
            end
        end

        VersusModeState.send_client_action("attack_" .. slot, {
            hound_aim_pitch = attack
                and (attack.hound_trajectory or attack.hound_instant_pounce)
                and (hound_aim_pitch or state.pitch)
                or nil,
            hound_aim_yaw = attack
                and (attack.hound_trajectory or attack.hound_instant_pounce)
                and (hound_aim_yaw or state.yaw)
                or nil,
            hound_charge_fraction = attack
                and attack.hound_trajectory
                and hound_charge_fraction
                or nil,
            target_unit_id = VersusModeState.network_unit_id(requested_target),
        })
        set_status(state, "COMMAND SENT: " .. string.upper(slot), 1.5)

        return
    end

    attack = Specialist.resolve_immediate_casual_primary(state, attack, preferred_target)

    if state.breed.name == SNIPER_BREED_NAME and state.sniper_laser_active then
        if slot == "heavy" then
            return
        elseif slot == "primary" then
            local t = gameplay_time()
            local cooldown_until = state.sniper_fire_cooldown_until or 0

            if t < cooldown_until then
                local remaining = cooldown_until - t

                set_status(state, string.format("Longlas cooldown: %.1f s", remaining), remaining)

                return
            end

            stop_manual_motion(state)
            state.requested_attack = attack
            state.sniper_laser_active = nil
            state.sniper_shot_fired = nil
            state.sniper_shot_stop_t = nil
            state.attack_min_until = t + setting("attack_burst_duration")
            state.attack_deadline = t + setting("attack_acquire_timeout")
            state.attack_hard_deadline = t + setting("attack_acquire_timeout") + 10
            state.attack_phase = "FIRING"
            VersusModeState.echo_localized("notice_firing_longlas")

            return
        end
    end

    if not attack then
        set_status(state, string.upper(slot) .. " unavailable for this enemy", 2.5)

        return
    end

    if attack.mutant_throw then
        if not state.attack_deadline or not state.mutant_carrying then
            set_status(state, "No carried target to throw", 2.5)

            return
        end

        state.mutant_force_throw = true
        state.requested_attack = attack
        state.attack_phase = "THROWING"
        VersusModeState.echo_localized("notice_mutant_early_throw")

        return
    end

    start_attack_burst(
        state,
        attack,
        preferred_target,
        hound_aim_yaw,
        hound_aim_pitch,
        hound_charge_fraction
    )
end

mod.primary_attack = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("attack_keybind", is_pressed) then
        return
    end

    request_attack_for_state(mod._control, "primary")
end

mod.heavy_attack = function(is_pressed, force_action, physical_edge)
    local state = mod._control
    local should_fire
    local pressed_edge
    local ignored

    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    -- Hound Heavy is deliberately bound to its physical hold lifetime rather
    -- than the generic Press/Long-hold preference: press begins the live
    -- camera-directed arc and release commits that direction and elevation.
    if state
        and state.possessed
        and HOUND_BREEDS[state.breed.name] then
        if force_action and not physical_edge then
            return
        end

        if physical_edge then
            pressed_edge = is_pressed ~= false
        else
            ignored, pressed_edge = configured_keybind_should_fire("heavy_attack_keybind", is_pressed)
        end

        if control_input_ui_gated(state) then
            if is_pressed == false then
                Specialist.destroy_hound_preview(state)
            end

            return
        end

        if is_pressed ~= false and pressed_edge then
            if state.attack_deadline then
                set_status(state, "Attack already in progress", 1.5)

                return
            end

            state.grenadier_target_lock = false
            set_locked_target(state, nil)
            state.hound_pounce_preview_active = true
            state.hound_pounce_preview_next_update = 0
            state.hound_pounce_charge_started_at = gameplay_time()
            state.hound_pounce_charge_fraction = Specialist.hound_uses_charge_mode() and 0 or nil
            update_manual_aim_preview(state)
            set_status(state, mod:localize("hound_release_to_pounce"), 2.5)

            return
        elseif is_pressed == false and state.hound_pounce_preview_active then
            local solution = state.hound_pounce_preview_solution

            state.hound_pounce_preview_active = nil

            if solution and solution.valid then
                request_attack_for_state(
                    state,
                    "heavy",
                    nil,
                    solution.yaw,
                    solution.pitch,
                    solution.charge_fraction
                )
            else
                set_status(state, mod:localize("hound_no_valid_trajectory"), 2.5)
            end

            Specialist.destroy_hound_preview(state)

            return
        end

        return
    end

    if force_action then
        should_fire = not physical_edge or is_pressed ~= false
    else
        should_fire, pressed_edge = configured_keybind_should_fire("heavy_attack_keybind", is_pressed)
    end

    -- DMF's held trigger calls once on press and once on release. Preserve
    -- the Sniper laser's physical hold lifetime. In Press mode it starts on
    -- the down edge; in Long hold mode the generic threshold dispatcher starts
    -- it later. Either mode stops immediately when the key is released.
    if (not force_action or physical_edge)
        and is_pressed == false
        and state
        and state.possessed
        and state.breed.name == SNIPER_BREED_NAME then
        state.sniper_scope_held = nil

        if state.remote_client then
            VersusModeState.send_client_action("heavy_release")

            return
        end

        if state.sniper_laser_active then
            pause_brain(state)
            set_status(state, "Laser aim released", 1.5)
        end

        return
    end

    if not force_action
        and state
        and state.possessed
        and state.breed.name == SNIPER_BREED_NAME
        and keybind_activation("heavy_attack_keybind") == "press" then
        should_fire = pressed_edge == true
    end

    if not should_fire then
        return
    end

    if state
        and state.possessed
        and state.breed.name == SNIPER_BREED_NAME
        and setting("enable_sniper_scope_zoom") then
        state.sniper_scope_held = true
    end

    request_attack_for_state(mod._control, "heavy")
end

mod.alternate_attack = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("alternate_attack_keybind", is_pressed) then
        return
    end

    request_attack_for_state(mod._control, "alternate")
end

mod.special_attack = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("special_attack_keybind", is_pressed) then
        return
    end

    request_attack_for_state(mod._control, "special")
end

function VersusModeState.send_client_action(action, extra)
    if not mod._realms_compat or not mod._realms_compat.is_client() then
        return false
    end

    mod._remote_action_sequence = (mod._remote_action_sequence or 0) + 1

    return mod._realms_compat.send_action(action, mod._remote_action_sequence, extra)
end

function VersusModeState.cancel_control_action(state)
    if not state or not state.possessed then
        return
    end

    if state.breed
        and HOUND_BREEDS[state.breed.name]
        and state.hound_pounce_preview_active then
        Specialist.destroy_hound_preview(state)
        set_status(state, mod:localize("hound_charge_cancelled"), 2.5)

        return
    end

    if state.remote_client then
        VersusModeState.send_client_action("cancel")
        set_status(state, "CANCEL SENT", 1.5)

        return
    end

    if state.controlled_traversal then
        set_status(state, mod:localize("controlled_traversal_native_busy"), 2.5)

        return
    end

    local attack = state.requested_attack

    if not state.attack_deadline or not attack then
        set_status(state, "No cancellable action in progress", 2)

        return
    end

    if not attack.cancellable then
        set_status(state, attack.label .. " cannot be cancelled", 2)

        return
    end

    if state.breed.name == POXBURSTER_BREED_NAME and state.poxburster_armed then
        set_status(state, "Fuse armed — detonation cannot be cancelled", 2.5)

        return
    end

    local attack_name = attack.label

    pause_brain(state)
    safe_anim_event(state.animation, "idle")
    set_status(state, "CANCELLED: " .. attack_name, 2.5)
    VersusModeState.echo_attack_log_notice("cancelled " .. attack_name .. ".")
end

mod.cancel_action = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("cancel_action_keybind", is_pressed) then
        return
    end

    local state = mod._control

    if state and not state.controller_peer_id and control_input_ui_gated(state) then
        return
    end

    VersusModeState.cancel_control_action(state)
end

mod.toggle_first_person_view = function(is_pressed)
    if is_pressed == false then
        return
    end

    local state = mod._control

    if not state or not state.possessed or control_input_ui_gated(state) then
        return
    end

    if not VersusModeState.first_person_supported(state) then
        set_status(state, mod:localize("first_person_boss_unsupported"), 2.5)

        return
    end

    local enabled = not state.first_person

    if VersusModeState.set_controlled_first_person(state, enabled) then
        set_status(
            state,
            mod:localize(enabled and "first_person_view_enabled" or "third_person_view_enabled"),
            2.5
        )
    end
end

mod.controlled_context_action = function(is_pressed, force_action)
    if not force_action and is_pressed == false then
        return
    end

    local state = mod._control

    if not state or not state.possessed then
        return
    end

    if not state.controller_peer_id and control_input_ui_gated(state) then
        return
    end

    if not VersusModeState.controlled_traversal_enabled() then
        set_status(state, mod:localize("controlled_traversal_disabled"), 2.5)

        return
    end

    if state.remote_client then
        local sent, send_error = VersusModeState.send_client_action("context_traverse")

        if sent then
            set_status(state, mod:localize("controlled_traversal_sent"), 1.5)
        else
            set_status(state, mod:localize("controlled_traversal_failed", tostring(send_error)), 3)
        end

        return
    end

    VersusModeState.start_contextual_traversal(state)
end

-- Existing custom bindings from the two-button prototype retain their saved
-- keys, but now dispatch the single nearby-context action.
mod.controlled_traverse = mod.controlled_context_action
mod.controlled_open_door = mod.controlled_context_action

-- Backward-compatible function name for an existing saved keybind.
mod.attack_burst = mod.primary_attack

local function cycle_control_target(state)
    if not state or not state.possessed then
        return
    end

    if not state.controller_peer_id and control_input_ui_gated(state) then
        return
    end

    if state.remote_client then
        VersusModeState.send_client_action("cycle_target")
        set_status(state, "TARGET CYCLE SENT", 1.5)

        return
    end

    if MANUAL_AIM_BREEDS[state.breed.name] then
        set_status(state, "Manual-aim enemies use the crosshair", 2.5)

        return
    end

    if HOUND_BREEDS[state.breed.name] then
        state.grenadier_target_lock = false
        set_locked_target(state, nil)
        set_status(state, mod:localize("hound_target_lock_disabled"), 2.5)

        return
    end

    if Specialist.free_aim(state) then
        set_status(state, "Enable target lock before cycling targets", 2.5)

        return
    end

    if state.attack_deadline then
        set_status(state, "Cannot change target during an attack", 2)

        return
    end

    local targets = player_side_targets(state)

    if #targets == 0 then
        set_locked_target(state, nil)
        set_status(state, "No valid targets", 2.5)

        return
    end

    -- player_side_targets is freshly sorted by distance from the controlled
    -- enemy. Do not reuse nearest_attack_target: it preserves an existing lock.
    set_locked_target(state, targets[1])
    set_status(state, "LOCKED: " .. target_name(targets[1]), 2)
end

function Specialist.toggle_target_lock(state)
    if not state or not state.possessed then
        return
    end

    if not state.controller_peer_id and control_input_ui_gated(state) then
        return
    end

    if state.remote_client then
        VersusModeState.send_client_action("target_lock")
        set_status(state, "TARGET MODE SENT", 1.5)

        return
    end

    if MANUAL_AIM_BREEDS[state.breed.name] then
        set_status(state, "This specialist already uses manual crosshair aim", 2.5)

        return
    end

    if HOUND_BREEDS[state.breed.name] then
        state.grenadier_target_lock = false
        set_locked_target(state, nil)
        set_status(state, mod:localize("hound_target_lock_disabled"), 2.5)

        return
    end

    if Specialist.casual_supported(state) then
        if state.attack_deadline then
            set_status(state, "Cannot change targeting during an attack", 2)

            return
        end

        state.casual_combat = state.casual_combat ~= true

        -- Crusher and Bulwark retain the existing Auto/Free-aim pairing:
        -- Casual uses a target lock, while Advanced exposes their four direct
        -- camera attacks. Bosses/Captains keep ordinary target cycling in both
        -- combat layouts because free-aim behavior is not safe for their tree.
        if Specialist.target_mode_supported(state) then
            state.grenadier_target_lock = state.casual_combat

            if state.casual_combat then
                state.grenade_preview_solution = nil
                state.manual_aim_position = nil
                state.manual_aim_hit_unit = nil
                state.manual_aim_distance = nil
                destroy_grenade_preview(state)
                Specialist.destroy_hound_preview(state)
                set_locked_target(state, nearest_attack_target(state))
            else
                set_locked_target(state, nil)
                update_manual_aim_preview(state)
            end
        end

        set_status(
            state,
            state.casual_combat and "Casual Combat enabled" or "Advanced Combat enabled",
            2.5
        )

        return
    end

    if not Specialist.target_mode_supported(state) then
        set_status(state, "Target mode unavailable for this enemy", 2.5)

        return
    end

    if state.attack_deadline then
        set_status(state, "Cannot change targeting during an attack", 2)

        return
    end

    if state.grenadier_target_lock == false then
        state.grenadier_target_lock = true
        state.grenade_preview_solution = nil
        state.manual_aim_position = nil
        state.manual_aim_hit_unit = nil
        state.manual_aim_distance = nil
        destroy_grenade_preview(state)
        Specialist.destroy_hound_preview(state)

        local target = nearest_attack_target(state)

        set_locked_target(state, target)
        set_status(state, target and ("TARGET LOCK ON: " .. target_name(target)) or "TARGET LOCK ON: no target", 2.5)
    else
        state.grenadier_target_lock = false
        set_locked_target(state, nil)
        update_manual_aim_preview(state)
        set_status(state, "TARGET LOCK OFF: free aim", 2.5)
    end
end

mod.cycle_target = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("cycle_target_keybind", is_pressed) then
        return
    end

    cycle_control_target(mod._control)
end

mod.toggle_target_lock = function(is_pressed, force_action)
    if not force_action and not VersusModeState.uses_custom_enemy_keybinds() then
        return
    end

    if not force_action and not configured_keybind_should_fire("target_lock_keybind", is_pressed) then
        return
    end

    Specialist.toggle_target_lock(mod._control)
end

function VersusModeState.receive_remote_input(peer_id, payload)
    local state = VersusModeState.control_for_peer(peer_id)

    if not state
        or type(payload) ~= "table"
        or type(payload.sequence) ~= "number"
        or payload.sequence % 1 ~= 0
        or payload.sequence < 0
        or payload.sequence > 2147483647
        or payload.sequence <= (state.remote_input_sequence or 0)
        or type(payload.yaw) ~= "number"
        or type(payload.pitch) ~= "number"
        or type(payload.forward) ~= "number"
        or type(payload.right) ~= "number"
        or payload.yaw ~= payload.yaw
        or payload.pitch ~= payload.pitch
        or payload.forward ~= payload.forward
        or payload.right ~= payload.right
        or math.abs(payload.yaw) > 1000000
        or math.abs(payload.pitch) > 1000000
        or math.abs(payload.forward) > 1000000
        or math.abs(payload.right) > 1000000 then
        return false
    end

    state.remote_input_sequence = payload.sequence
    -- Replicate preferences, not a client-supplied world position. The host
    -- reconstructs and collision-checks the pose using its authoritative unit.
    if type(payload.camera_distance) == "number" and payload.camera_distance == payload.camera_distance then
        state.remote_camera_distance = math_max(3, math_min(14, payload.camera_distance))
    end
    if type(payload.camera_height) == "number" and payload.camera_height == payload.camera_height then
        state.remote_camera_height = math_max(1, math_min(7, payload.camera_height))
    end
    if type(payload.first_person) == "boolean" then
        state.first_person = payload.first_person and VersusModeState.first_person_supported(state) or false
    end
    state.yaw = (payload.yaw + math.pi) % (math.pi * 2) - math.pi

    if state.first_person then
        state.pitch = math_max(-1.25, math_min(1.25, payload.pitch))
    elseif Specialist.free_aim(state) then
        state.pitch = math_max(-0.9, math_min(1.05, payload.pitch))
    else
        state.pitch = math_max(-0.7, math_min(0.35, payload.pitch))
    end

    state.remote_input = {
        forward = math_max(-1, math_min(1, payload.forward)),
        received_at = gameplay_time(),
        right = math_max(-1, math_min(1, payload.right)),
    }

    return true
end

function VersusModeState.receive_remote_action(peer_id, payload)
    if type(payload) ~= "table"
        or type(payload.action) ~= "string"
        or type(payload.sequence) ~= "number"
        or payload.sequence % 1 ~= 0
        or payload.sequence < 0
        or payload.sequence > 2147483647 then
        return false
    end

    if payload.action == "cycle_spawn" or payload.action == "select_spawn" or payload.action == "spawn_picker" then
        local role = VersusModeState.role_for_peer(peer_id)

        if not role
            or not role.infected_human
            or not mod._realms_compat
            or not mod._realms_compat.peer_compatible(peer_id)
            or payload.sequence <= (role.remote_spawn_action_sequence or 0) then
            return false
        end

        role.remote_spawn_action_sequence = payload.sequence

        if not VersusModeState.spawn_selection_enabled() then
            VersusModeState.send_remote_status(peer_id, mod:localize("infected_spawn_selection_disabled"), "error")

            return false
        end

        if payload.action == "spawn_picker" then
            if type(payload.picker_open) ~= "boolean" or VersusModeState.control_for_peer(peer_id) then
                return false
            end
            role.spawn_picker_until = payload.picker_open and gameplay_time() + 6 or nil
            return true
        elseif payload.action == "select_spawn" then
            if type(payload.spawn_breed) ~= "string"
                or payload.spawn_variant ~= nil and type(payload.spawn_variant) ~= "string" then
                return false
            end
            return VersusModeState.cycle_respawn(role, peer_id, payload.spawn_breed, payload.spawn_variant)
        end
        return VersusModeState.cycle_respawn(role, peer_id)
    end

    local state = VersusModeState.control_for_peer(peer_id)

    if not state
        or payload.sequence <= (state.remote_action_sequence or 0)
        or payload.target_unit_id ~= nil and (
            type(payload.target_unit_id) ~= "number"
            or payload.target_unit_id ~= payload.target_unit_id
            or payload.target_unit_id % 1 ~= 0
            or payload.target_unit_id < 0
            or payload.target_unit_id > 2147483647
        )
        or payload.hound_aim_yaw ~= nil and (
            type(payload.hound_aim_yaw) ~= "number"
            or payload.hound_aim_yaw ~= payload.hound_aim_yaw
            or math.abs(payload.hound_aim_yaw) > 1000000
        )
        or payload.hound_aim_pitch ~= nil and (
            type(payload.hound_aim_pitch) ~= "number"
            or payload.hound_aim_pitch ~= payload.hound_aim_pitch
            or math.abs(payload.hound_aim_pitch) > 1000000
        )
        or payload.hound_charge_fraction ~= nil and (
            type(payload.hound_charge_fraction) ~= "number"
            or payload.hound_charge_fraction ~= payload.hound_charge_fraction
            or math.abs(payload.hound_charge_fraction) > 1000000
        )
        or payload.hound_charge_fraction ~= nil and payload.hound_aim_yaw == nil
        or (payload.hound_aim_yaw == nil) ~= (payload.hound_aim_pitch == nil) then
        return false
    end

    state.remote_action_sequence = payload.sequence

    local preferred_target = payload.target_unit_id and VersusModeState.unit_from_network_id(payload.target_unit_id) or nil
    local hound_aim_yaw = payload.hound_aim_yaw
    local hound_aim_pitch = payload.hound_aim_pitch
    local hound_charge_fraction = payload.hound_charge_fraction

    if payload.action == "release" then
        if VersusModeState.auto_boss_release_blocked(state) then
            return true
        end

        VersusModeState.release_control(state, "released.")

        return true
    elseif payload.action == "attack_primary" then
        request_attack_for_state(state, "primary", preferred_target)
    elseif payload.action == "attack_heavy" then
        request_attack_for_state(
            state,
            "heavy",
            preferred_target,
            hound_aim_yaw,
            hound_aim_pitch,
            hound_charge_fraction
        )
    elseif payload.action == "attack_alternate" then
        request_attack_for_state(state, "alternate", preferred_target)
    elseif payload.action == "attack_special" then
        request_attack_for_state(state, "special", preferred_target)
    elseif payload.action == "cycle_target" then
        cycle_control_target(state)
    elseif payload.action == "target_lock" then
        Specialist.toggle_target_lock(state)
    elseif payload.action == "context_traverse"
        or payload.action == "traverse"
        or payload.action == "open_door" then
        VersusModeState.start_contextual_traversal(state)
    elseif payload.action == "cancel" then
        VersusModeState.cancel_control_action(state)
    elseif payload.action == "heavy_release" and state.breed.name == SNIPER_BREED_NAME then
        if state.sniper_laser_active then
            pause_brain(state)
            set_status(state, "Laser aim released", 1.5)
        end
    else
        return false
    end

    VersusModeState.send_remote_status(
        peer_id,
        state.status_message or state.attack_phase or "READY",
        (state.attack_deadline or state.controlled_traversal) and "busy" or "ready",
        state
    )

    return true
end

function VersusModeState.realms_preparation()
    local realms_mod = get_mod("Realms")

    return realms_mod and realms_mod._preparation or nil
end

function VersusModeState.realms_lobby_waiting()
    local preparation = VersusModeState.realms_preparation()
    local waiting_ok, waiting = pcall(function()
        return preparation and preparation.is_waiting and preparation.is_waiting()
    end)

    return waiting_ok and waiting == true
end

function VersusModeState.begin_realms_preparation_roster()
    mod._realms_preparation_active = true
    mod._infected_lobby_plan = {
        revision = 0,
        selected = {},
    }
    mod._replicated_lobby_plan = nil
    mod._pending_lobby_roster_application = nil
    mod:info("Versus Mode: started a fresh Realms preparation roster plan.")

    return true
end

function VersusModeState.realms_lobby_host()
    local preparation = VersusModeState.realms_preparation()
    local bridge = mod._realms_compat
    local role_ok, role = pcall(function()
        return preparation and preparation.role and preparation.role()
    end)

    return (VersusModeState.realms_lobby_waiting() or mod._realms_preparation_active == true)
        and role_ok
        and role == "host"
        and bridge
        and bridge.is_connection_host
        and bridge.is_connection_host()
        or false
end

function VersusModeState.lobby_plan_locked()
    local preparation = VersusModeState.realms_preparation()

    if not preparation then
        return false
    end

    local finalizing_ok, finalizing = pcall(function()
        return preparation.is_finalizing and preparation.is_finalizing()
    end)
    local countdown_ok, countdown = pcall(function()
        return preparation.countdown_remaining and preparation.countdown_remaining()
    end)

    return finalizing_ok and finalizing == true
        or countdown_ok and type(countdown) == "number" and countdown > 0
        or false
end

function VersusModeState.lobby_player_rows()
    local preparation = VersusModeState.realms_preparation()
    local rows_ok, rows = pcall(function()
        return preparation and preparation.player_rows and preparation.player_rows()
    end)

    return rows_ok and type(rows) == "table" and rows or {}
end

function VersusModeState.normalized_roster_name(name)
    if name == nil then
        return nil
    end

    local normalized = string.lower(tostring(name))
    normalized = string.gsub(normalized, "^%s+", "")
    normalized = string.gsub(normalized, "%s+$", "")

    return normalized ~= "" and normalized or nil
end

function VersusModeState.lobby_row_identity(row, field)
    if type(row) ~= "table" then
        return nil
    end

    local value = row[field]

    if type(value) == "function" then
        local ok, result = pcall(value, row)

        value = ok and result or nil
    end

    if value == nil and row.player and type(row.player[field]) == "function" then
        local ok, result = pcall(row.player[field], row.player)

        value = ok and result or nil
    end

    if value == nil and type(row.profile) == "table" then
        value = row.profile[field]
    end

    return value ~= nil and string.lower(tostring(value)) or nil
end

function VersusModeState.lobby_plan()
    local plan = mod._infected_lobby_plan

    if not plan then
        plan = {
            revision = 0,
            selected = {},
        }
        mod._infected_lobby_plan = plan
    end

    return plan
end


function VersusModeState.lobby_local_peer_id()
    local peer_ok, peer_id = pcall(function()
        return Network and Network.peer_id and Network.peer_id()
    end)

    return peer_ok and VersusModeState.normalize_peer_id(peer_id) or nil
end


function VersusModeState.lobby_plan_payload()
    local plan = VersusModeState.lobby_plan()
    local payload = {
        locked = VersusModeState.lobby_plan_locked(),
        revision = plan.revision or 0,
        roles = {},
    }

    for peer_id, entry in pairs(plan.selected or {}) do
        payload.roles[#payload.roles + 1] = {
            account_id = entry.account_id,
            character_id = entry.character_id,
            name = tostring(entry.name or peer_id),
            peer_id = peer_id,
        }
    end

    table.sort(payload.roles, function(a, b)
        return a.peer_id < b.peer_id
    end)

    return payload
end


function VersusModeState.publish_lobby_plan(recipient)
    local bridge = mod._realms_compat

    if not bridge
        or not bridge.is_connection_host
        or not bridge.is_connection_host()
        or not bridge.available()
        or not bridge.send_lobby_plan then
        return false
    end

    local sent, send_error = bridge.send_lobby_plan(VersusModeState.lobby_plan_payload(), recipient)

    if not sent then
        mod:info("Versus Mode: lobby roster synchronization deferred: %s", tostring(send_error))
    end

    return sent
end


function VersusModeState.prune_lobby_plan(rows)
    -- Once countdown/finalization begins, Realms can briefly rebuild its
    -- preparation player rows. Never interpret that transition as every
    -- selected Heretic leaving, and never mutate the live plan after its
    -- gameplay handoff has been snapshotted.
    if mod._pending_lobby_roster_application or VersusModeState.lobby_plan_locked() then
        return false
    end

    local plan = VersusModeState.lobby_plan()
    local present = {}
    local changed = false

    for i = 1, #(rows or {}) do
        local peer_id = VersusModeState.normalize_peer_id(rows[i].peer_id)

        if peer_id then
            present[peer_id] = true
        end
    end

    for peer_id in pairs(plan.selected) do
        if not present[peer_id] then
            plan.selected[peer_id] = nil
            changed = true
        end
    end

    if changed then
        plan.revision = (plan.revision or 0) + 1
        VersusModeState.publish_lobby_plan()
    end

    return changed
end


function VersusModeState.remove_lobby_peer(peer_id)
    peer_id = VersusModeState.normalize_peer_id(peer_id)

    if not peer_id then
        return false
    end

    local plan = mod._infected_lobby_plan

    if not plan or not plan.selected[peer_id] then
        return false
    end

    plan.selected[peer_id] = nil
    plan.revision = (plan.revision or 0) + 1
    VersusModeState.publish_lobby_plan()

    return true
end


function VersusModeState.apply_replicated_lobby_plan(payload)
    if type(payload) ~= "table"
        or type(payload.roles) ~= "table" then
        return false
    end

    local selected = {}

    for i = 1, #payload.roles do
        local entry = payload.roles[i]
        local peer_id = type(entry) == "table" and VersusModeState.normalize_peer_id(entry.peer_id) or nil

        if peer_id then
            selected[peer_id] = {
                account_id = VersusModeState.lobby_row_identity(entry, "account_id"),
                character_id = VersusModeState.lobby_row_identity(entry, "character_id"),
                name = tostring(entry.name or peer_id),
                peer_id = peer_id,
            }
        end
    end

    mod._replicated_lobby_plan = {
        locked = payload.locked == true,
        revision = type(payload.revision) == "number" and payload.revision or 0,
        selected = selected,
    }

    return true
end


function VersusModeState.lobby_role_label(peer_id)
    peer_id = VersusModeState.normalize_peer_id(peer_id)

    if not peer_id then
        return ""
    end

    local bridge = mod._realms_compat
    local host = bridge
        and bridge.is_connection_host
        and bridge.is_connection_host()
    local plan = host and VersusModeState.lobby_plan() or mod._replicated_lobby_plan

    if not plan then
        return ""
    end

    local infected = plan and plan.selected and plan.selected[peer_id] ~= nil

    return " [" .. mod:localize(infected and "infected_lobby_role_infected" or "infected_lobby_role_survivor") .. "]"
end


mod.infected_lobby_planning_active = function()
    return VersusModeState.realms_lobby_host()
end


mod.infected_lobby_plan_locked = function()
    return VersusModeState.lobby_plan_locked()
end


mod.infected_lobby_snapshot = function()
    local snapshot = {}
    local rows = VersusModeState.lobby_player_rows()
    local bridge = mod._realms_compat
    local local_peer_id = VersusModeState.lobby_local_peer_id()
    local locked = VersusModeState.lobby_plan_locked()
    local plan = VersusModeState.lobby_plan()

    if VersusModeState.realms_lobby_host() then
        VersusModeState.prune_lobby_plan(rows)
    end

    for i = 1, #rows do
        local row = rows[i]
        local peer_id = VersusModeState.normalize_peer_id(row.peer_id)
        local local_host = peer_id and peer_id == local_peer_id
        local compatible = local_host
            or bridge and bridge.peer_compatible(peer_id)

        if peer_id then
            snapshot[#snapshot + 1] = {
                token = peer_id,
                name = tostring(row.name or peer_id),
                kind = local_host and mod:localize("versus_roster_kind_host")
                    or compatible and mod:localize("versus_roster_kind_realms_ready")
                    or mod:localize("versus_roster_kind_version_required", mod.version),
                infected = plan.selected[peer_id] ~= nil,
                selectable = not locked and compatible == true,
            }
        end
    end

    return snapshot
end


mod.apply_infected_lobby_selection = function(selected_tokens)
    if not setting("enable_versus_mode") then
        return false, mod:localize("versus_roster_error_enable_mode")
    end

    if not VersusModeState.realms_lobby_host() then
        return false, mod:localize("infected_lobby_error_host")
    end

    if VersusModeState.lobby_plan_locked() then
        return false, mod:localize("infected_lobby_error_locked")
    end

    local rows = VersusModeState.lobby_player_rows()
    local row_by_peer = {}
    local desired = {}
    local desired_count = 0
    local local_peer_id = VersusModeState.lobby_local_peer_id()

    for i = 1, #rows do
        local peer_id = VersusModeState.normalize_peer_id(rows[i].peer_id)

        if peer_id then
            row_by_peer[peer_id] = rows[i]
        end
    end

    for token, selected in pairs(selected_tokens or {}) do
        local peer_id = selected and VersusModeState.normalize_peer_id(token) or nil
        local row = peer_id and row_by_peer[peer_id] or nil
        local compatible = peer_id == local_peer_id
            or mod._realms_compat and mod._realms_compat.peer_compatible(peer_id)

        if row and not compatible then
            return false, mod:localize("versus_roster_error_client_version", tostring(row.name), mod.version)
        end

        if row and compatible and not desired[peer_id] then
            desired[peer_id] = {
                account_id = VersusModeState.lobby_row_identity(row, "account_id"),
                character_id = VersusModeState.lobby_row_identity(row, "character_id"),
                local_host = peer_id == local_peer_id,
                name = tostring(row.name or peer_id),
                peer_id = peer_id,
            }
            desired_count = desired_count + 1
        end
    end

    if desired_count > 0 and desired_count >= #rows then
        return false, mod:localize("versus_roster_error_survivor_required")
    end

    local plan = VersusModeState.lobby_plan()

    plan.selected = desired
    plan.revision = (plan.revision or 0) + 1
    mod._pending_lobby_roster_application = nil
    VersusModeState.publish_lobby_plan()

    return true, mod:localize("infected_lobby_saved", desired_count, math_max(0, #rows - desired_count))
end


mod.clear_infected_lobby_selection = function()
    if not VersusModeState.realms_lobby_host() then
        return false, mod:localize("infected_lobby_error_host")
    end

    if VersusModeState.lobby_plan_locked() then
        return false, mod:localize("infected_lobby_error_locked")
    end

    local plan = VersusModeState.lobby_plan()

    table.clear(plan.selected)
    plan.revision = (plan.revision or 0) + 1
    VersusModeState.publish_lobby_plan()

    return true, mod:localize("infected_lobby_cleared")
end


function VersusModeState.queue_lobby_plan_application()
    local plan = mod._infected_lobby_plan

    if not plan or not next(plan.selected or {}) then
        mod._pending_lobby_roster_application = nil

        return false
    end

    local selected = {}
    local selected_count = 0

    for peer_id, entry in pairs(plan.selected) do
        entry = type(entry) == "table" and entry or {}
        selected[peer_id] = {
            account_id = entry.account_id,
            character_id = entry.character_id,
            local_host = entry.local_host == true,
            name = tostring(entry.name or peer_id),
            peer_id = entry.peer_id or peer_id,
        }
        selected_count = selected_count + 1
    end

    mod._pending_lobby_roster_application = {
        deadline = nil,
        next_try_at = 0,
        revision = plan.revision or 0,
        selected = selected,
        selected_count = selected_count,
    }
    mod:info(
        "Versus Mode: queued Realms lobby roster revision %s as an immutable gameplay snapshot (%d selected).",
        tostring(plan.revision),
        selected_count
    )

    return true
end

function VersusModeState.lobby_plan_candidate_match(entry, peer_id, candidates, used_candidates)
    entry = type(entry) == "table" and entry or {}
    used_candidates = used_candidates or {}

    for i = 1, #candidates do
        local candidate = candidates[i]

        if not used_candidates[i] and candidate.peer_id == peer_id then
            return i, "peer ID"
        end
    end

    if entry.local_host then
        for i = 1, #candidates do
            if not used_candidates[i] and candidates[i].local_human then
                return i, "local host"
            end
        end
    end

    for _, identity in ipairs({
        { entry.account_id, "account ID", "account_id" },
        { entry.character_id, "character ID", "character_id" },
    }) do
        if identity[1] then
            for i = 1, #candidates do
                local candidate = candidates[i]

                if not used_candidates[i] and candidate[identity[3]] == identity[1] then
                    return i, identity[2]
                end
            end
        end
    end

    -- Realms can rebuild its preparation player rows when ownership moves
    -- from the preparation connection to the mission connection. If no stable
    -- identifier survived, accept an exact name only when it identifies one
    -- and only one currently loaded player.
    local wanted_name = VersusModeState.normalized_roster_name(entry.name)
    local matched_index

    if wanted_name then
        for i = 1, #candidates do
            local candidate = candidates[i]

            if not used_candidates[i]
                and VersusModeState.normalized_roster_name(candidate.name) == wanted_name then
                if matched_index then
                    return nil
                end

                matched_index = i
            end
        end
    end

    return matched_index, matched_index and "unique display name" or nil
end


function VersusModeState.update_lobby_plan_application()
    local pending = mod._pending_lobby_roster_application

    if not pending or not is_server() then
        return false
    end

    local t = main_time()

    pending.deadline = pending.deadline or (t + 20)

    if t < (pending.next_try_at or 0) then
        return false
    end

    pending.next_try_at = t + 0.5

    local candidates = VersusModeState.candidates()
    local selected = pending.selected or {}
    local selected_tokens = {}
    local matched = {}
    local used_candidates = {}
    local selected_count = pending.selected_count or 0
    local matched_count = 0

    for peer_id, entry in pairs(selected) do
        local candidate_index, match_method = VersusModeState.lobby_plan_candidate_match(
            entry,
            peer_id,
            candidates,
            used_candidates
        )
        local candidate = candidate_index and candidates[candidate_index]

        if candidate then
            selected_tokens[tostring(candidate.unique_id)] = true
            matched[peer_id] = true
            used_candidates[candidate_index] = true
            matched_count = matched_count + 1

            if not pending.logged_matches or pending.logged_matches[peer_id] ~= candidate.unique_id then
                pending.logged_matches = pending.logged_matches or {}
                pending.logged_matches[peer_id] = candidate.unique_id
                mod:info(
                    "Versus Mode: matched preparation Heretic %s (%s) to gameplay player %s via %s.",
                    tostring(entry.name or peer_id),
                    tostring(peer_id),
                    tostring(candidate.name or candidate.unique_id),
                    tostring(match_method)
                )
            end
        end
    end

    local timed_out = t >= pending.deadline

    if (#candidates < 2 or matched_count < selected_count) and not timed_out then
        return false
    end

    if timed_out and matched_count < selected_count then
        for peer_id in pairs(selected) do
            if not matched[peer_id] then
                mod:warning("Versus Mode: skipped missing lobby-selected peer %s during gameplay assignment.", peer_id)
            end
        end
    end

    if #candidates < 2 then
        mod._pending_lobby_roster_application = nil
        mod:warning("Versus Mode: could not apply the saved Realms lobby roster because player units never became ready.")
        VersusModeState.echo_notice(mod:localize("infected_lobby_apply_failed"))

        return false
    end

    local applied, message = mod.apply_versus_roster_selection(selected_tokens)

    if applied then
        mod._pending_lobby_roster_application = nil
        VersusModeState.echo_notice(mod:localize("infected_lobby_applied"))
        mod:info(
            "Versus Mode: applied Realms lobby roster revision %s from its immutable snapshot: %s",
            tostring(pending.revision),
            tostring(message)
        )

        return true
    end

    if timed_out then
        mod._pending_lobby_roster_application = nil
        mod:warning("Versus Mode: could not apply the saved Realms lobby roster: %s", tostring(message))
        VersusModeState.echo_notice(mod:localize("infected_lobby_apply_failed"))
    end

    return false
end


function VersusModeState.install_realms_lobby_legend_localization(legend)
    if not legend then
        return false
    end

    if legend._versus_mode_original_update_widget_text then
        return true
    end

    local original_update = legend._update_widget_text

    if type(original_update) ~= "function" then
        return false
    end

    local installed = pcall(function()
        legend._versus_mode_original_update_widget_text = original_update
        legend._update_widget_text = function(self, entry)
            if entry and entry.display_name == "infected_lobby_open_planner" then
                local rendered, text = pcall(
                    VersusModeState.text.add_button_hint,
                    entry.input_action,
                    mod:localize(entry.display_name),
                    nil,
                    nil,
                    true
                )

                if rendered and entry.widget and entry.widget.content then
                    entry.widget.content.text = text
                    entry.recalcultate_text_width = true

                    return
                end
            end

            return original_update(self, entry)
        end
    end)

    return installed
end


function VersusModeState.add_realms_preparation_lobby_entry(view)
    local legend = view and view._input_legend_element

    if not legend or view._versus_mode_lobby_entry_id then
        return view and view._versus_mode_lobby_entry_id ~= nil or false
    end

    VersusModeState.install_realms_lobby_legend_localization(legend)

    local added, entry_id = pcall(
        legend.add_entry,
        legend,
        "infected_lobby_open_planner",
        "hotkey_menu_special_1",
        function()
            return VersusModeState.realms_lobby_host()
                and setting("enable_versus_mode")
                and setting("enable_versus_roster_menu")
                and not VersusModeState.lobby_plan_locked()
        end,
        function()
            mod.toggle_versus_roster_menu(true, true)
        end,
        "right_alignment"
    )

    if not added then
        mod:warning("Versus Mode: could not add the Realms preparation roster action: %s", tostring(entry_id))

        return false
    end

    -- Some InputLegend revisions return nil even after accepting the entry.
    -- Keep an explicit sentinel so a late repair cannot register E twice.
    view._versus_mode_lobby_entry_id = entry_id or true

    return true
end


function VersusModeState.decorate_realms_preparation_rows(view)
    local grid = view and view._player_grid
    local widgets = grid and grid.widgets and grid:widgets() or nil
    local decorated = 0

    for i = 1, #(widgets or {}) do
        local widget = widgets[i]
        local element = widget.content and widget.content.element

        if element and element.peer_id and element.player_name then
            widget.content.player_name = tostring(element.player_name)
                .. VersusModeState.lobby_role_label(element.peer_id)
            decorated = decorated + 1
        end
    end

    return decorated
end


function VersusModeState.active_realms_preparation_view()
    local ui_manager = Managers and Managers.ui

    if not ui_manager or type(ui_manager.view_instance) ~= "function" then
        return nil
    end

    local found, view = pcall(ui_manager.view_instance, ui_manager, "realms_preparation_view")

    return found and view or nil
end


function VersusModeState.repair_active_realms_preparation_view()
    local view = VersusModeState.active_realms_preparation_view()

    if not view then
        return false
    end

    VersusModeState.add_realms_preparation_lobby_entry(view)
    VersusModeState.decorate_realms_preparation_rows(view)

    return true
end


function VersusModeState.install_realms_preparation_view_class(view_class)
    if mod._realms_preparation_hooks_installed then
        VersusModeState.repair_active_realms_preparation_view()

        return true
    end

    if type(view_class) ~= "table"
        or type(view_class._setup_input_legend) ~= "function"
        or type(view_class._present_player_rows) ~= "function" then
        return false
    end

    mod._realms_preparation_hooks_installed = true

    mod:hook_safe(view_class, "_setup_input_legend", function(view)
        VersusModeState.add_realms_preparation_lobby_entry(view)
    end)

    mod:hook_safe(view_class, "_present_player_rows", function(view)
        VersusModeState.decorate_realms_preparation_rows(view)
    end)

    -- If Realms finished constructing its view before this callback ran, patch
    -- that live instance as well as all future preparation views.
    VersusModeState.repair_active_realms_preparation_view()
    mod:info("Versus Mode: installed optional Realms 0.7 preparation-roster hooks without modifying Realms.")

    return true
end


function VersusModeState.install_realms_preparation_hooks()
    if mod._realms_preparation_hooks_installed then
        VersusModeState.repair_active_realms_preparation_view()

        return true
    end

    if not get_mod("Realms") then
        return false
    end

    -- Realms registers its view at mod startup but deliberately requires the
    -- implementation only when the preparation screen opens. CLASS therefore
    -- contains an incomplete placeholder during on_all_mods_loaded. Install a
    -- delayed module callback instead of treating that normal state as fatal.
    if not mod._realms_preparation_require_hook_registered
        and type(mod.hook_require) == "function" then
        mod._realms_preparation_require_hook_registered = true
        mod:hook_require(
            "Realms/scripts/mods/Realms/views/preparation_view/preparation_view",
            function(view_class)
                VersusModeState.install_realms_preparation_view_class(view_class)
            end
        )
    end

    local view_class = CLASS and CLASS.RealmsPreparationView

    if VersusModeState.install_realms_preparation_view_class(view_class) then
        return true
    end

    if not mod._realms_preparation_hook_deferred_logged then
        mod._realms_preparation_hook_deferred_logged = true
        mod:info("Versus Mode: Realms preparation roster hook deferred until the view module loads.")
    end

    return false
end


mod.versus_roster_snapshot = function()
    local snapshot = {}
    local candidates = VersusModeState.candidates()
    local bridge = mod._realms_compat

    for i = 1, #candidates do
        local candidate = candidates[i]
        local compatible = candidate.local_human
            or not candidate.human
            or bridge and bridge.peer_compatible(candidate.peer_id)

        snapshot[#snapshot + 1] = {
            token = tostring(candidate.unique_id),
            name = candidate.name,
            kind = candidate.local_human and mod:localize("versus_roster_kind_host")
                or not candidate.human and mod:localize("versus_roster_kind_bot")
                or compatible and mod:localize("versus_roster_kind_realms_ready")
                or mod:localize("versus_roster_kind_version_required", mod.version),
            infected = VersusModeState.role_for_unique_id(candidate.unique_id) ~= nil,
            selectable = compatible == true,
        }
    end

    return snapshot
end

mod.apply_versus_roster_selection = function(selected_tokens)
    if not setting("enable_versus_mode") then
        return false, mod:localize("versus_roster_error_enable_mode")
    end

    if not setting("enable_versus_roster_menu") then
        return false, mod:localize("versus_roster_error_menu_disabled")
    end

    if not is_server() then
        return false, mod:localize("versus_roster_error_host_assign")
    end

    if VersusModeState.any_authoritative_control() then
        return false, mod:localize("versus_roster_error_release_before_change")
    end

    local candidates = VersusModeState.candidates()
    local candidate_by_token = {}
    local desired = {}
    local desired_count = 0

    for i = 1, #candidates do
        candidate_by_token[tostring(candidates[i].unique_id)] = candidates[i]
    end

    for token, selected in pairs(selected_tokens or {}) do
        local candidate = selected and candidate_by_token[tostring(token)] or nil

        if candidate
            and candidate.human
            and not candidate.local_human
            and (not mod._realms_compat or not mod._realms_compat.peer_compatible(candidate.peer_id)) then
            return false, mod:localize(
                "versus_roster_error_client_version",
                candidate.name,
                mod.version
            )
        end

        if candidate and not desired[candidate.unique_id] then
            desired[candidate.unique_id] = candidate
            desired_count = desired_count + 1
        end
    end

    if desired_count > 0 and desired_count >= #candidates then
        return false, mod:localize("versus_roster_error_survivor_required")
    end

    local added = {}

    for unique_id, candidate in pairs(desired) do
        if not VersusModeState.role_for_unique_id(unique_id) then
            local assigned, assign_error, assigned_role = VersusModeState.assign_candidate(candidate)

            if not assigned then
                for i = 1, #added do
                    VersusModeState.clear_role(added[i])
                end

                return false, tostring(assign_error)
            end

            added[#added + 1] = assigned_role
        end
    end

    local remove = {}

    for unique_id, role in pairs(VersusModeState.roles()) do
        if not desired[unique_id] then
            remove[#remove + 1] = role
        end
    end

    for i = 1, #remove do
        VersusModeState.clear_role(remove[i])
    end

    VersusModeState.local_role()
    VersusModeState.notify_composition_changed()

    local survivor_count = math_max(0, #candidates - desired_count)
    local message = mod:localize(
        survivor_count == 1 and "versus_roster_applied_singular" or "versus_roster_applied_plural",
        desired_count,
        survivor_count
    )

    VersusModeState.echo_notice(message)
    -- A manual in-mission correction supersedes any preparation plan that was
    -- still waiting for an identity match. Do not let that stale request fire
    -- later after a controlled Heretic has already deployed.
    mod._pending_lobby_roster_application = nil

    return true, message
end

mod.clear_versus_roster = function()
    if not is_server() then
        return false, mod:localize("versus_roster_error_host_restore")
    end

    if VersusModeState.any_authoritative_control() then
        return false, mod:localize("versus_roster_error_release_before_restore")
    end

    VersusModeState.clear("cleared from roster menu")

    return true, mod:localize("versus_roster_restored_all")
end

mod.toggle_versus_roster_menu = function(is_pressed, force_action)
    if not force_action and not configured_keybind_should_fire("infected_menu_keybind", is_pressed) then
        return
    end

    if not setting("enable_versus_mode") then
        VersusModeState.echo_localized("versus_roster_error_enable_mode")

        return
    end

    if not setting("enable_versus_roster_menu") then
        VersusModeState.echo_localized("versus_roster_error_menu_disabled")

        return
    end

    local lobby_host = VersusModeState.realms_lobby_host()

    if not is_server() and not lobby_host then
        VersusModeState.echo_localized("versus_roster_error_host_open")

        return
    end

    local ui_manager = Managers.ui

    if not ui_manager then
        return
    end

    if ui_manager:view_instance(VersusModeState.roster_view_name) then
        ui_manager:close_view(VersusModeState.roster_view_name)
    else
        ui_manager:open_view(VersusModeState.roster_view_name, nil, nil, nil, nil, {})
    end
end

mod.cycle_infected_spawn = function(is_pressed, force_action)
    if not force_action and not configured_keybind_should_fire("cycle_infected_spawn_keybind", is_pressed) then
        return
    end

    if control_input_ui_gated(mod._control) then
        return
    end

    if not setting("enable_versus_mode") then
        mod:echo("Versus Mode: " .. mod:localize("versus_role_required"))

        return
    end

    if not VersusModeState.spawn_selection_enabled() then
        mod:echo("Versus Mode: " .. mod:localize("infected_spawn_selection_disabled"))

        return
    end

    local role = VersusModeState.local_role()

    if not role then
        mod:echo("Versus Mode: " .. mod:localize("infected_assignment_required"))

        return
    end

    if mod._control or role.assigned_boss_unit then
        mod:echo("Versus Mode: " .. mod:localize("infected_spawn_cycle_waiting_only"))

        return
    end

    Managers.ui:open_view("versus_mode_spawn_view", nil, nil, nil, nil, {})
end

mod.spawn_picker_choices = function()
    local choices = VersusModeState.available_spawn_choices()
    local result = {}
    for i = 1, #choices do
        local entry = choices[i]
        result[i] = {
            name = entry.name, variant_id = entry.variant_id,
            label = VersusModeState.respawn_label(entry.name, entry.variant_id),
            portrait = ENEMY_PORTRAITS[entry.name] or ENEMY_PORTRAIT_FALLBACK,
        }
    end
    return result
end

mod.spawn_picker_available = function()
    local role = VersusModeState.local_role()
    return setting("enable_versus_mode") and VersusModeState.spawn_selection_enabled()
        and role and role.infected_human and not role.assigned_boss_unit
        and not mod._control and not mod._death_camera
end

mod.spawn_picker_hold = function(open)
    local role = VersusModeState.local_role()
    if is_server() then
        if role then
            role.spawn_picker_until = open and gameplay_time() + 6 or nil
        end
    else
        return VersusModeState.send_client_action("spawn_picker", { picker_open = open })
    end
end

mod.spawn_picker_select = function(entry)
    if not entry or not mod.spawn_picker_available() then
        return false
    end
    if is_server() then
        return VersusModeState.cycle_respawn(VersusModeState.local_role(), nil, entry.name, entry.variant_id)
    end
    return VersusModeState.send_client_action("select_spawn", {
        spawn_breed = entry.name, spawn_variant = entry.variant_id,
    })
end

-- Existing saved binds from the selector prototype now open the roster menu.
mod.cycle_infected_candidate = mod.toggle_versus_roster_menu
mod.toggle_selected_infected = mod.toggle_versus_roster_menu

function VersusModeState.hud_data()
    if mod._death_camera
        or not setting("enable_versus_mode")
        or not setting("show_control_hud") then
        return nil
    end

    local role = VersusModeState.local_role()
    local notice = mod._last_survivor_notice

    if notice and gameplay_time() < notice.expires_at and not VersusModeState.local_active() then
        return {
            header = mod:localize("last_survivor_title"),
            boss_name = notice.name,
            target_label = mod:localize("last_survivor_time"),
            target_mode = mod:localize("hud_seconds_short", math_max(0, notice.expires_at - gameplay_time())),
            target_name = mod:localize("last_survivor_ability"),
            status = mod:localize("last_survivor_once"),
            status_kind = "ready",
            locked = false,
            show_crosshair = false,
            action_lines = {
                { label = "-50%", text = mod:localize("last_survivor_defence"), kind = "ready" },
                { label = "+", text = mod:localize("last_survivor_mobility"), kind = "ready" },
            },
        }
    end

    if role and VersusModeState.local_active() then
        local breed_name = role.respawn_breed
        local breed_label = VersusModeState.respawn_label(breed_name, role.respawn_variant)
        local remaining = breed_name and math_max(0, (role.respawn_ready_at or math.huge) - gameplay_time()) or math.huge
        local ready = breed_name and remaining <= 0
        local random_safe = VersusModeState.random_safe_spawn_enabled()
        local automatic = random_safe and VersusModeState.automatic_respawn_enabled()
        local valid = false
        local reason

        if ready and random_safe then
            valid = true
            reason = mod:localize("hud_host_choose_safe_spawn")
        elseif ready then
            valid, reason = VersusModeState.spawn_validation(false)
        elseif breed_name then
            reason = mod:localize("hud_available_in", remaining)
        else
            reason = mod:localize("hud_selecting_next_specialist")
        end

        local network_status = role.network_status
            and gameplay_time() <= (role.network_status_until or 0)
            and VersusModeState.localize_hud_text(role.network_status)
        local spectator_name = role.spectator_target_name

        return {
            header = mod:localize("hud_header_infected_respawn"),
            boss_name = spectator_name and mod:localize("hud_spectating_survivor", spectator_name)
                or mod:localize(random_safe and "hud_spectator_fallback" or "hud_free_flight"),
            target_label = mod:localize("hud_next_spawn"),
            target_mode = mod:localize(ready and "hud_state_ready" or "hud_state_waiting"),
            target_name = breed_label,
            target_distance = nil,
            status = network_status
                or role.automatic_respawn_reason and mod:localize(
                    "notice_automatic_respawn_retry",
                    VersusModeState.localize_hud_text(role.automatic_respawn_reason)
                )
                or ready and automatic and mod:localize("hud_automatic_spawn_searching")
                or ready and random_safe and mod:localize("hud_ready_host_safe_spawn")
                or ready and (valid and mod:localize("hud_ready_hidden")
                    or mod:localize("hud_blocked_reason", VersusModeState.localize_hud_text(reason or mod:localize("hud_invalid_location"))))
                or VersusModeState.localize_hud_text(reason),
            status_kind = ready and valid and "ready" or "busy",
            locked = false,
            show_crosshair = ready and not random_safe,
            action_lines = {
                {
                    label = automatic and "AUTO" or configured_keybind_label("possess_keybind"),
                    text = ready and automatic and mod:localize("hud_automatic_random_safe_spawn", breed_label)
                        or ready and random_safe and mod:localize("hud_random_safe_spawn_action", breed_label)
                        or ready and (valid and mod:localize("hud_respawn_here", breed_label) or mod:localize("hud_respawn_blocked"))
                        or breed_name and mod:localize("hud_respawn_unlocks", remaining)
                        or mod:localize("hud_waiting_assignment"),
                    kind = ready and valid and "ready" or "busy",
                },
                {
                    label = VersusModeState.native_binding_label("spectate_next"),
                    text = spectator_name and mod:localize("hud_cycle_survivor_spectator")
                        or mod:localize("hud_no_survivor_spectator"),
                    kind = spectator_name and "normal" or "busy",
                },
                {
                    label = configured_keybind_label("cycle_infected_spawn_keybind"),
                    text = VersusModeState.spawn_selection_enabled()
                        and mod:localize("infected_spawn_cycle_hud")
                        or mod:localize("infected_spawn_cycle_hud_disabled"),
                    kind = VersusModeState.spawn_selection_enabled() and "ready" or "normal",
                },
                is_server()
                    and { label = configured_keybind_label("infected_menu_keybind"), text = mod:localize("hud_open_roster_menu"), kind = "normal" }
                    or { label = "REALMS", text = mod:localize(random_safe and "hud_realms_host_selects_spawn" or "hud_realms_host_validates_spawn"), kind = "normal" },
            },
        }
    end

    local candidates = VersusModeState.candidates()
    local infected_count = VersusModeState.count()
    local survivor_count = math_max(0, #candidates - infected_count)
    local menu_enabled = setting("enable_versus_roster_menu")

    return {
        header = mod:localize("hud_header_realms_infected"),
        boss_name = mod:localize(infected_count > 0 and "hud_roster_applied" or "hud_roster_not_set"),
        target_label = mod:localize("hud_infected"),
        target_mode = tostring(infected_count),
        target_name = mod:localize("hud_survivor_count", survivor_count),
        target_distance = nil,
        status = mod:localize(is_server()
            and (menu_enabled and "hud_host_roster_ready" or "hud_roster_menu_disabled")
            or "hud_waiting_host_roster"),
        status_kind = is_server() and menu_enabled and "ready" or "busy",
        locked = false,
        show_crosshair = false,
        action_lines = {
            is_server() and {
                label = configured_keybind_label("infected_menu_keybind"),
                text = mod:localize(menu_enabled and "hud_open_roster_menu" or "hud_enable_roster_menu"),
                kind = menu_enabled and "ready" or "busy",
            } or { label = "REALMS", text = mod:localize("hud_versus_mode_connected", mod.version), kind = "normal" },
        },
    }
end

mod.target_lock_marker_hud_data = function()
    local state = mod._control

    if not state or not state.possessed or not setting("show_target_outline") then
        return nil
    end

    local unit = VersusModeState.locked_target_for_state(state)

    if not unit then
        return nil
    end

    local feet = live_world_position(unit)
    local head = node_world_position(unit, "j_head")
        or feet and (feet + vector3_up() * 1.55)

    if not feet or not head then
        return nil
    end

    return {
        feet = feet,
        head = head,
        unit = unit,
    }
end

mod.control_hud_data = function()
    if mod._death_camera then
        return nil
    end

    local state = mod._control

    if not state or not state.possessed then
        return VersusModeState.hud_data()
    end

    if not setting("show_control_hud") then
        return nil
    end

    if state.breed.name == NETTER_BREED_NAME then
        local t = gameplay_time()
        local firing = state.attack_deadline ~= nil
        local distance = state.manual_aim_distance
        local variant = state.variant_id == "sniper_netter"
        local range_limit = variant and 28 or 14
        local cooldown_remaining = variant and math_max(0, (state.netter_fire_cooldown_until or 0) - t) or 0
        local reaches_target = distance ~= nil and distance <= range_limit
        local ready = not firing and distance ~= nil and cooldown_remaining <= 0 and (not variant or reaches_target)
        local aim_unit = state.manual_aim_hit_unit
        local aim_name = VersusModeState.valid_attack_target(aim_unit, state)
            and mod:localize("hud_target_under_crosshair", target_name(aim_unit))
            or aim_unit and mod:localize("hud_world_point_unlocked")
            or mod:localize("hud_open_space_unlocked")
        local fire_state = firing and mod:localize("hud_state_active")
            or cooldown_remaining > 0 and mod:localize("variant_attack_cooldown", cooldown_remaining)
            or not distance and mod:localize("hud_state_no_aim")
            or variant and not reaches_target and mod:localize("variant_attack_out_of_range", distance, range_limit)
            or reaches_target and mod:localize("hud_state_ready")
            or mod:localize("hud_ready_net_expires")
        local status = firing and VersusModeState.localize_hud_text(state.attack_phase or "FIRING")
            or state.status_message and t <= (state.status_until or 0) and state.status_message ~= "READY"
                and VersusModeState.localize_hud_text(state.status_message)
            or cooldown_remaining > 0 and mod:localize("variant_attack_cooldown", cooldown_remaining)
            or variant and distance and not reaches_target and mod:localize("variant_attack_out_of_range", distance, range_limit)
            or ready and reaches_target and mod:localize("hud_state_ready")
            or ready and mod:localize("hud_shot_net_expires")
            or mod:localize("hud_state_no_aim")
        local primary_label = VersusModeState.localize_attack_label(variant and "Fire Long-range Net" or "Fire Net")

        return {
            header = variant and mod:localize("sniper_netter_control_header") or mod:localize("hud_header_netter_control"),
            boss_name = VersusModeState.controlled_label(state),
            target_label = mod:localize("hud_crosshair"),
            target_mode = mod:localize("hud_free_aim"),
            target_name = aim_name,
            target_distance = distance,
            primary = primary_label .. " — " .. fire_state,
            primary_kind = ready and "ready" or "busy",
            heavy = mod:localize("hud_unavailable"),
            heavy_kind = "normal",
            alternate = mod:localize("hud_unavailable"),
            alternate_kind = "normal",
            special = mod:localize("hud_unavailable"),
            special_kind = "normal",
            status = status,
            status_kind = ready and "ready" or "busy",
            locked = false,
            show_crosshair = true,
            crosshair_kind = ready and "ready" or "busy",
            action_lines = {
                { label = attack_keybind_label("primary"), text = primary_label .. " — " .. fire_state, kind = ready and "ready" or "busy" },
                VersusModeState.controlled_traversal_hud_line(state),
            },
        }
    end

    if state.breed.name == SNIPER_BREED_NAME then
        local t = gameplay_time()
        local cooldown_remaining = math_max(0, (state.sniper_fire_cooldown_until or 0) - t)
        local laser_active = state.sniper_laser_active == true
        local firing = state.attack_deadline ~= nil and not laser_active
        local ready = not firing and cooldown_remaining <= 0
        local laser_ready = not firing
        local aim_unit = state.manual_aim_hit_unit
        local aim_name = VersusModeState.valid_attack_target(aim_unit, state) and target_name(aim_unit)
            or aim_unit and mod:localize("hud_world")
            or mod:localize("hud_open_space")
        local status

        if state.sniper_shot_fired then
            status = mod:localize("hud_state_fired")
        elseif laser_active then
            status = mod:localize("hud_state_laser_aiming")
        elseif firing then
            status = mod:localize("hud_state_charging_aiming")
        elseif cooldown_remaining > 0 then
            status = mod:localize("hud_cooldown_seconds", cooldown_remaining)
        elseif state.status_message and t <= (state.status_until or 0) and state.status_message ~= "READY" then
            status = VersusModeState.localize_hud_text(state.status_message)
        else
            status = mod:localize("hud_state_ready")
        end

        local longlas_label = VersusModeState.localize_attack_label("Fire Longlas")
        local laser_label = VersusModeState.localize_attack_label("Aim Laser")
        local fire_state = mod:localize(ready and "hud_state_ready" or firing and "hud_state_active" or "hud_state_cooldown")
        local laser_state = mod:localize(laser_active and "hud_state_active" or laser_ready and "hud_state_ready" or "hud_state_busy")

        return {
            header = mod:localize("hud_header_sniper_control"),
            boss_name = VersusModeState.controlled_label(state),
            target_label = mod:localize("hud_aim"),
            target_mode = mod:localize("hud_manual"),
            target_name = aim_name,
            target_distance = state.manual_aim_distance,
            primary = longlas_label .. " — " .. fire_state,
            primary_kind = ready and "ready" or "busy",
            heavy = mod:localize("hud_hold_action", laser_label) .. " — " .. laser_state,
            heavy_kind = laser_active and "busy" or laser_ready and "ready" or "busy",
            alternate = mod:localize("hud_unavailable"),
            alternate_kind = "normal",
            special = mod:localize("hud_unavailable"),
            special_kind = "normal",
            status = status,
            status_kind = ready and not laser_active and "ready" or "busy",
            locked = false,
            show_crosshair = setting("show_sniper_crosshair"),
            crosshair_kind = ready and "ready" or "busy",
            action_lines = {
                { label = attack_keybind_label("primary"), text = longlas_label .. " — " .. fire_state, kind = ready and "ready" or "busy" },
                { label = attack_keybind_label("heavy"), text = mod:localize("hud_hold_action", laser_label) .. " — " .. laser_state, kind = laser_active and "busy" or laser_ready and "ready" or "busy" },
                VersusModeState.controlled_traversal_hud_line(state),
            },
        }
    end

    local attacks = resolved_attacks_for_state(state) or {}
    local grenadier_manual = GRENADIER_BREEDS[state.breed.name] and state.grenadier_target_lock == false
    local specialist_manual = Specialist.free_aim(state)
    local grenade_solution = grenadier_manual and state.grenade_preview_solution
    local hound_previewing = state.hound_pounce_preview_active == true
    local hound_solution = hound_previewing and state.hound_pounce_preview_solution
    local locked_target = VersusModeState.valid_attack_target(state.locked_target, state) and state.locked_target
        or state.remote_client
            and VersusModeState.valid_attack_target(state.remote_locked_target, state)
            and state.remote_locked_target
        or nil
    local attack_target = VersusModeState.valid_attack_target(state.attack_target, state) and state.attack_target or nil
    local manual_target = VersusModeState.valid_attack_target(state.manual_aim_hit_unit, state)
        and state.manual_aim_hit_unit or nil
    local proxy_target = locked_target or attack_target or nearest_attack_target(state)
    local target = hound_previewing and hound_solution and hound_solution.target_unit
        or specialist_manual and manual_target
        or proxy_target
    local boss_position = live_world_position(state.unit)
    local target_position = live_world_position(target)
    local distance

    if hound_previewing then
        distance = hound_solution and hound_solution.distance
    elseif grenadier_manual then
        distance = grenade_solution and grenade_solution.distance
    elseif specialist_manual then
        distance = state.manual_aim_distance
    else
        distance = boss_position and target_position and vector3_distance(boss_position, target_position)
    end
    local proxy_position = live_world_position(proxy_target)
    local proxy_distance = boss_position and proxy_position and vector3_distance(boss_position, proxy_position)
    local has_line_of_sight = false
    local status

    if target and state.perception then
        local ok, result = safe_extension_call(state.perception, "immediate_line_of_sight_check", target)

        has_line_of_sight = ok and result or false
    end

    local function attack_display(attack)
        if not attack then
            return mod:localize("hud_unavailable"), "normal"
        end

        local attack_label = VersusModeState.localize_attack_label(attack)

        if attack.mutant_throw then
            local ready = state.mutant_carrying == true

            return attack_label .. " — " .. mod:localize(ready and "hud_state_ready" or "hud_state_no_carried_target"), ready and "ready" or "busy"
        end

        if attack.hound_trajectory then
            local previewing = state.hound_pounce_preview_active == true
            local ready = previewing and hound_solution and hound_solution.valid and not state.attack_deadline
            local range_state

            if state.attack_deadline then
                range_state = mod:localize("hud_state_active")
            elseif previewing and Specialist.hound_uses_charge_mode() then
                local charge = hound_solution and hound_solution.charge_fraction
                    or state.hound_pounce_charge_fraction
                    or 0
                local percent = math.floor(math_max(0, math_min(1, charge)) * 100 + 0.5)

                range_state = hound_solution and hound_solution.valid
                    and mod:localize("hound_charge_status", percent)
                    or mod:localize("hound_charge_blocked_status", percent)
            elseif ready then
                range_state = mod:localize("hound_release_to_pounce_short")
            elseif previewing then
                range_state = mod:localize("hound_no_valid_trajectory")
            else
                range_state = mod:localize("hound_hold_to_preview")
            end

            return attack_label .. " — " .. range_state, ready and "ready" or previewing and "busy" or "normal"
        end

        if grenadier_manual and attack.grenadier_path == "far" then
            local ready = grenade_solution and grenade_solution.valid and not state.attack_deadline
            local has_impact = grenade_solution and grenade_solution.has_impact
            local area_radius = grenade_solution and grenade_solution.area_radius or GRENADE_AREA_RADIUS[state.breed.name] or 5
            local range_state = state.attack_deadline and mod:localize("hud_state_active")
                or ready and has_impact and mod:localize("hud_state_ready")
                or ready and mod:localize("hud_ready_open_arc")
                or mod:localize("hud_state_no_trajectory")

            return mod:localize("hud_grenade_attack_area", attack_label, range_state, area_radius), ready and "ready" or "busy"
        end

        if specialist_manual and attack.free_aim_melee then
            local range_state = state.attack_deadline and state.requested_attack == attack
                and mod:localize("hud_state_active") or mod:localize("hud_state_ready")

            return mod:localize(
                "hud_ranged_attack",
                attack_label,
                VersusModeState.localize_range_text(attack.range_text or ""),
                range_state
            ), state.attack_deadline and "busy" or "ready"
        end

        if state.breed.name == "chaos_spawn" and attack.action_name == "leap" then
            local leap_range_min = attack.range_min or ChaosSpawnSettings.min_leap_distance
            local leap_range_max = attack.range_max or Specialist.spawn_leap_command_max_distance
            local behavior_component = state.blackboard and state.blackboard.behavior
            local native_target_matches = state.perception_component
                and state.perception_component.target_unit == target
            local trajectory_ready = native_target_matches
                and behavior_component
                and behavior_component.should_leap == true
            local range_state
            local ready = false
            local leap_active = state.attack_deadline
                and state.requested_attack
                and state.requested_attack.action_name == "leap"

            if not distance then
                range_state = mod:localize("hud_state_no_target")
            elseif distance < leap_range_min then
                range_state = mod:localize("hud_state_too_close")
            elseif distance > leap_range_max then
                range_state = mod:localize("hud_state_too_far")
            elseif not has_line_of_sight then
                range_state = mod:localize("hud_state_no_los")
            elseif leap_active then
                range_state = state.spawn_leap_failure
                    or state.spawn_leap_native_state and state.attack_phase
                    or mod:localize("spawn_leap_checking_arc")
            elseif trajectory_ready then
                range_state = mod:localize("hud_state_ready")
                ready = true
            else
                range_state = mod:localize("spawn_leap_arc_check_on_press")
                ready = true
            end

            return mod:localize(
                "hud_ranged_attack",
                attack_label,
                mod:localize(
                    "hud_spawn_leap_target_range",
                    string.format("%g", leap_range_min),
                    string.format("%g", leap_range_max)
                ),
                range_state
            ), ready and "ready" or "busy"
        end

        if not attack.range_min and not attack.range_max then
            return attack_label, "normal"
        end

        local range_text = VersusModeState.localize_range_text(attack.range_text or "")
        local attack_distance = grenadier_manual and attack.grenadier_path == "close" and proxy_distance or distance
        local range_ready = attack_distance ~= nil
        local range_state

        if not attack_distance then
            range_ready = false
            range_state = mod:localize("hud_state_no_target")
        elseif attack.range_min and (attack.range_min_exclusive and attack_distance <= attack.range_min or not attack.range_min_exclusive and attack_distance < attack.range_min) then
            range_ready = false
            range_state = mod:localize("hud_state_too_close")
        elseif attack.range_max and attack_distance > attack.range_max then
            range_ready = false
            range_state = mod:localize("hud_state_too_far")
        elseif attack.requires_line_of_sight and not has_line_of_sight then
            range_ready = false
            range_state = mod:localize("hud_state_no_los")
        else
            range_state = mod:localize("hud_state_ready")
        end

        return mod:localize("hud_ranged_attack", attack_label, range_text, range_state), range_ready and "ready" or "busy"
    end

    if state.attack_deadline then
        local attack_name = VersusModeState.localize_attack_label(
            state.remote_attack_label or state.requested_attack or "Native Attack"
        )
        local cancel_hint = state.requested_attack
            and state.requested_attack.cancellable
            and not state.poxburster_armed
            and mod:localize("hud_cancel_hint", attack_keybind_label("cancel"))
            or ""

        status = mod:localize(
            "hud_attack_status",
            VersusModeState.localize_hud_text(state.attack_phase or "ACQUIRING"),
            attack_name,
            cancel_hint
        )
    elseif state.status_message and gameplay_time() <= (state.status_until or 0) then
        status = VersusModeState.localize_hud_text(state.status_message)
    elseif grenadier_manual and (not grenade_solution or not grenade_solution.valid) then
        status = mod:localize("hud_no_valid_trajectory")
    elseif grenadier_manual and not grenade_solution.has_impact then
        status = mod:localize("hud_ready_landing_unconfirmed")
    else
        status = mod:localize("hud_state_ready")
    end

    local primary_text, primary_kind = attack_display(attacks.primary)
    local heavy_text, heavy_kind = attack_display(attacks.heavy)
    local alternate_text, alternate_kind = attack_display(attacks.alternate)
    local special_text, special_kind = attack_display(attacks.special)
    local action_lines = {}
    local target_cycle_available, target_lock_available = VersusModeState.target_hud_capabilities(state)

    if target_cycle_available then
        local cycle_label = VersusModeState.enemy_control_keybind_label("cycle_target_keybind")

        action_lines[#action_lines + 1] = {
            label = cycle_label,
            text = mod:localize(state.grenadier_target_lock == false and "hud_cycle_target_lock_only" or "hud_cycle_target"),
            kind = state.grenadier_target_lock == false and "normal" or "ready",
        }
    end

    if target_lock_available then
        local lock_label, hold_available = VersusModeState.enemy_control_keybind_label("target_lock_keybind")
        local casual_mode = Specialist.casual_supported(state)
        local mode_enabled = casual_mode and state.casual_combat == true
            or not casual_mode and state.grenadier_target_lock ~= false

        action_lines[#action_lines + 1] = {
            label = lock_label,
            text = hold_available
                and mod:localize(casual_mode
                    and (mode_enabled and "hud_casual_combat_on" or "hud_casual_combat_off")
                    or state.grenadier_target_lock == false and "hud_target_lock_off"
                    or "hud_target_lock_on")
                or mod:localize("hud_target_lock_hold_unavailable"),
            kind = hold_available and (mode_enabled and "ready" or "busy") or "busy",
        }
    end

    local traversal_hud_line = VersusModeState.controlled_traversal_hud_line(state)

    if traversal_hud_line then
        action_lines[#action_lines + 1] = traversal_hud_line
    end

    if attacks.primary then
        action_lines[#action_lines + 1] = { label = attack_keybind_label("primary"), text = primary_text, kind = primary_kind }
    end

    if attacks.heavy then
        action_lines[#action_lines + 1] = { label = attack_keybind_label("heavy"), text = heavy_text, kind = heavy_kind }
    end

    if attacks.alternate then
        action_lines[#action_lines + 1] = { label = attack_keybind_label("alternate"), text = alternate_text, kind = alternate_kind }
    end

    if attacks.special then
        action_lines[#action_lines + 1] = { label = attack_keybind_label("special"), text = special_text, kind = special_kind }
    end

    local cancel_line = VersusModeState.cancel_action_hud_line(state, attacks)

    if cancel_line then
        action_lines[#action_lines + 1] = cancel_line
    end

    local generic_specialist = is_specialist_breed(state.breed) and not ATTACKS[state.breed.name]
    local generic_boss = state.breed.is_boss and not ATTACKS[state.breed.name]

    return {
        header = GRENADIER_BREEDS[state.breed.name] and mod:localize("hud_header_grenadier_control")
            or generic_specialist and mod:localize("hud_header_specialist_control")
            or generic_boss and mod:localize("hud_header_boss_native")
            or nil,
        boss_name = VersusModeState.controlled_label(state),
        target_mode = mod:localize(hound_previewing and "hud_pounce_aim"
            or Specialist.casual_supported(state) and state.casual_combat == true and "hud_casual"
            or Specialist.casual_supported(state) and specialist_manual and "hud_advanced_free_aim"
            or Specialist.casual_supported(state) and "hud_advanced"
            or specialist_manual and "hud_free_aim"
            or locked_target and "hud_locked"
            or "hud_auto"),
        target_name = hound_previewing and (
            hound_solution and hound_solution.valid and mod:localize("hound_manual_trajectory")
            or mod:localize("hound_no_valid_trajectory")
        ) or grenadier_manual and (
            grenade_solution and grenade_solution.has_impact and mod:localize("hud_predicted_impact")
            or grenade_solution and grenade_solution.valid and mod:localize("hud_open_trajectory")
            or mod:localize("hud_no_trajectory")
        ) or specialist_manual and VersusModeState.localize_hud_text(target_name(target))
            or state.remote_target_name
            or VersusModeState.localize_hud_text(target_name(target)),
        target_distance = distance,
        primary = primary_text,
        primary_kind = primary_kind,
        heavy = heavy_text,
        heavy_kind = heavy_kind,
        alternate = alternate_text,
        alternate_kind = alternate_kind,
        special = special_text,
        special_kind = special_kind,
        status = status,
        locked = locked_target ~= nil,
        show_crosshair = specialist_manual or state.hound_pounce_preview_active == true,
        crosshair_kind = hound_solution and hound_solution.valid and "ready"
            or grenade_solution and grenade_solution.valid and "ready"
            or "busy",
        action_lines = action_lines,
    }
end

mod.grenade_trajectory_hud_data = function()
    local state = mod._control

    if not state or not state.possessed then
        return nil
    end

    local solution

    if HOUND_BREEDS[state.breed.name] and state.hound_pounce_preview_active then
        solution = state.hound_pounce_preview_solution
    elseif GRENADIER_BREEDS[state.breed.name] and state.grenadier_target_lock == false then
        solution = state.grenade_preview_solution
    end

    if not solution or not solution.points or #solution.points < 2 then
        return nil
    end

    return solution
end

mod.controlled_enemy_status_data = function()
    local state = mod._control

    if not state or not state.possessed or not setting("replace_player_panel") or not ALIVE[state.unit] then
        return nil
    end

    local health_extension = safe_extension(state.unit, "health_system")

    if not health_extension then
        return nil
    end

    local current_ok, current_health = safe_extension_call(health_extension, "current_health")
    local max_ok, max_health = safe_extension_call(health_extension, "max_health")

    if not current_ok or not max_ok or type(current_health) ~= "number" or type(max_health) ~= "number" or max_health <= 0 then
        return nil
    end

    return {
        name = VersusModeState.controlled_label(state),
        portrait = ENEMY_PORTRAITS[state.breed.name] or ENEMY_PORTRAIT_FALLBACK,
        current_health = math_max(0, current_health),
        max_health = max_health,
        health_percent = math_min(1, math_max(0, current_health / max_health)),
    }
end

function VersusModeState.log_controlled_death(state, health_extension, current_health)
    if not state or state.death_diagnostic_logged then
        return
    end

    state.death_diagnostic_logged = true

    local death_component = state.blackboard and state.blackboard.death
    local damage_profile = death_component and death_component.damage_profile_name or "unknown"
    local damage_type = death_component and death_component.killing_damage_type or "unknown"
    local attacker_ok, attacker_unit = safe_extension_call(health_extension, "last_damaging_unit")
    local attacker_name = "none"

    if attacker_ok and attacker_unit then
        local player_spawn = Managers.state and Managers.state.player_unit_spawn
        local owner_ok = false
        local owner

        if player_spawn then
            owner_ok, owner = pcall(player_spawn.owner, player_spawn, attacker_unit)
        end

        if owner_ok and owner then
            attacker_name = VersusModeState.player_name(owner)
        else
            local attacker_data = safe_extension(attacker_unit, "unit_data_system")
            local attacker_breed_ok, attacker_breed = safe_extension_call(attacker_data, "breed")

            attacker_name = attacker_breed_ok and attacker_breed and tostring(attacker_breed.name)
                or tostring(attacker_unit)
        end
    end

    local traversal = state.controlled_traversal
    local position = live_world_position(state.unit)
    local destination

    if traversal and traversal.destination then
        local destination_ok, value = pcall(traversal.destination.unbox, traversal.destination)

        destination = destination_ok and value or nil
    end

    local remaining = position and destination and vector3_distance(position, destination) or -1
    local door_extension = traversal and safe_extension(traversal.door_target_unit, "door_system")
    local blocked_ok, nav_blocked = safe_extension_call(door_extension, "nav_blocked")

    mod:info(
        "Versus Mode: controlled death diagnostic breed=%s health=%s profile=%s damage_type=%s "
            .. "attacker=%s position=%s traversal=%s remaining=%.1f door_nav_blocked=%s.",
        tostring(state.breed and state.breed.name or "unknown"),
        tostring(current_health),
        tostring(damage_profile),
        tostring(damage_type),
        tostring(attacker_name),
        VersusModeState.position_diagnostic(position),
        tostring(traversal and traversal.phase or "none"),
        remaining,
        tostring(blocked_ok and nav_blocked or "unknown")
    )
end

local function fire_configured_keybind(binding_id)
    local function_name = KEYBIND_FUNCTION_NAMES[binding_id]
    local handler = function_name and mod[function_name]

    if handler then
        handler(true, true)
    end
end

function VersusModeState.reset_vanilla_enemy_input()
    mod._vanilla_weapon_swap_state = nil
end

function VersusModeState.update_vanilla_enemy_input(state, input_gated)
    if VersusModeState.uses_custom_enemy_keybinds() or not state or not state.possessed then
        VersusModeState.reset_vanilla_enemy_input()

        return
    end

    if input_gated then
        local breed_name = state.breed and state.breed.name

        if HOUND_BREEDS[breed_name] and state.hound_pounce_preview_active then
            state.hound_pounce_preview_active = nil
            Specialist.destroy_hound_preview(state)
        elseif breed_name == SNIPER_BREED_NAME and state.sniper_laser_active then
            mod.heavy_attack(false, true, true)
            state.sniper_laser_active = nil
        end

        VersusModeState.reset_vanilla_enemy_input()

        return
    end

    local input_service = VersusModeState.ingame_input_service()

    if not input_service then
        VersusModeState.reset_vanilla_enemy_input()

        return
    end

    if VersusModeState.native_input_action(input_service, "action_one_pressed") then
        mod.primary_attack(true, true)
    end

    if VersusModeState.native_input_action(input_service, "action_two_pressed") then
        mod.heavy_attack(true, true, true)
    end

    if VersusModeState.native_input_action(input_service, "action_two_release") then
        mod.heavy_attack(false, true, true)
    end

    if VersusModeState.native_input_action(input_service, "weapon_extra_pressed") then
        mod.alternate_attack(true, true)
    end

    if VersusModeState.native_input_action(input_service, "combat_ability_pressed") then
        mod.special_attack(true, true)
    end

    if VersusModeState.native_input_action(input_service, "sprint") then
        mod.cancel_action(true, true)
    end

    if VersusModeState.native_input_action(input_service, "jump") then
        mod.controlled_context_action(true, true)
    end

    local swap_pressed = VersusModeState.native_input_action(input_service, "quick_wield")
    local swap = mod._vanilla_weapon_swap_state

    if swap_pressed then
        local key_info = VersusModeState.native_binding_key_info("quick_wield")

        if VersusModeState.native_quick_wield_holdable(key_info) then
            mod._vanilla_weapon_swap_state = {
                key_info = key_info,
                started_at = gameplay_time(),
                long_action_fired = false,
            }
        else
            -- Mouse-wheel bindings generate a one-frame pulse and cannot
            -- express a hold. Preserve their tap-to-cycle behavior while the
            -- HUD directs the player to a holdable binding or custom profile
            -- for Target Lock.
            mod.cycle_target(true, true)
            mod._vanilla_weapon_swap_state = nil
        end
    elseif swap then
        local held, held_available = VersusModeState.native_quick_wield_held(input_service, swap.key_info)

        if not held_available then
            -- A device disconnect or an unsupported physical binding must not
            -- turn a failed hold probe into an unintended target-lock toggle.
            mod.cycle_target(true, true)
            mod._vanilla_weapon_swap_state = nil
        elseif held then
            if not swap.long_action_fired
                and gameplay_time() - (swap.started_at or gameplay_time()) >= setting("long_hold_threshold") then
                swap.long_action_fired = true
                mod.toggle_target_lock(true, true)
            end
        else
            if not swap.long_action_fired then
                mod.cycle_target(true, true)
            end

            mod._vanilla_weapon_swap_state = nil
        end
    end
end

function VersusModeState.update_authoritative_remote_control(state)
    if not state or not state.possessed then
        return
    end

    if not is_server() then
        VersusModeState.release_control(state, "server authority was lost; control released.", true)

        return
    end

    if not ALIVE[state.unit] then
        VersusModeState.release_control(state, "controlled enemy died; control released.", nil, true)

        return
    end

    local controlled_health = safe_extension(state.unit, "health_system")
    local health_ok, current_health = safe_extension_call(controlled_health, "current_health")

    if not HEALTH_ALIVE[state.unit]
        or health_ok and type(current_health) == "number" and current_health <= 0 then
        VersusModeState.log_controlled_death(state, controlled_health, current_health)
        VersusModeState.release_control(state, "controlled enemy died; native death resumed.", nil, true)

        return
    end

    if VersusModeState.begin_normal_daemonhost_leave(state) then
        return
    end

    local behavior = safe_extension(state.unit, "behavior_system")
    local navigation = safe_extension(state.unit, "navigation_system")
    local locomotion = safe_extension(state.unit, "locomotion_system")
    local perception = safe_extension(state.unit, "perception_system")

    if not behavior or not navigation or not locomotion or not perception then
        VersusModeState.release_control(state, "controlled enemy was removed; control released.")

        return
    end

    state.behavior = behavior
    state.navigation = navigation
    state.locomotion = locomotion
    state.perception = perception
    state.animation = safe_extension(state.unit, "animation_system") or state.animation
    VersusModeState.ensure_controlled_animation_lod(state)

    if state.locked_target and not VersusModeState.valid_attack_target(state.locked_target, state) then
        set_locked_target(state, nil)
        set_status(state, "Locked target lost; AUTO targeting", 2.5)
    end

    local presentation_target = VersusModeState.presentation_target_outline(state)

    if state.outlined_target ~= presentation_target then
        refresh_target_outline(state)
    end

    if (Specialist.target_mode_supported(state) and state.grenadier_target_lock ~= false
        or Specialist.casual_supported(state) and state.casual_combat == true)
        and not state.locked_target
        and not state.attack_deadline then
        set_locked_target(state, nearest_attack_target(state))
    end

    refresh_engine_position(state.unit)
    VersusModeState.update_remote_camera_pose(state)

    if state.attack_deadline then
        local t = gameplay_time()

        if state.breed.name == SNIPER_BREED_NAME and state.sniper_shot_fired and t >= (state.sniper_shot_stop_t or 0) then
            state.sniper_fire_cooldown_until = state.sniper_fire_cooldown_until or (t + SNIPER_FIRE_COOLDOWN)
            pause_brain(state)
            set_status(state, "Longlas recharging", SNIPER_FIRE_COOLDOWN)
        else
            local target = state.attack_target
            local targetless = state.requested_attack and state.requested_attack.targetless

            if not targetless and not VersusModeState.valid_attack_target(target, state) then
                if state.requested_attack and state.requested_attack.casual_command then
                    target = nil
                else
                    target = nearest_attack_target(state)
                end

                state.attack_target = target
            end

            if not targetless and not target then
                pause_brain(state)
                set_status(state, "Attack cancelled: target lost", 2.5)
            else
                if not targetless and state.perception_component then
                    state.perception_component.lock_target = false
                end

                if not targetless and state.perception and state.perception_component and state.perception_component.target_unit ~= target then
                    safe_extension_call(state.perception, "_set_target_unit", target)
                end

                local attacking = state.poxburster_armed
                    or running_offensive_action(state)
                    or VersusModeState.spawn_leap_interrupted(state)
                    or VersusModeState.hound_pounce_in_progress(state)

                if VersusModeState.finish_failed_spawn_leap(state) then
                    -- The native leap leaf rejected its final navmesh or
                    -- collision check; its specific status is retained.
                elseif state.command_action_complete then
                    pause_brain(state)
                    set_status(state, "READY", 1)
                elseif attacking then
                    state.attack_started = true
                    state.attack_phase = state.poxburster_armed and "FUSE ARMED"
                        or MANUAL_AIM_BREEDS[state.breed.name] and "AIMING"
                        or MUTANT_BREEDS[state.breed.name] and state.attack_phase
                        or state.spawn_leap_native_state and state.attack_phase
                        or "EXECUTING"
                end

                if VersusModeState.attack_command_should_stop(state, t, attacking) then
                    pause_brain(state)
                    set_status(state, "READY", 1)
                elseif state.attack_deadline and not state.attack_started and t >= state.attack_deadline then
                    local leap_timeout = state.breed.name == "chaos_spawn"
                        and state.requested_attack
                        and state.requested_attack.action_name == "leap"
                        and mod:localize("spawn_leap_no_trajectory")

                    pause_brain(state)
                    set_status(state, leap_timeout or "Attack unavailable from this position", 3)
                end
            end
        end

        if state.attack_deadline and state.attack_started
            and state.requested_attack and state.requested_attack.gunner_combat_range == "far" then
            VersusModeState.update_remote_authoritative_movement(state, true)
        end
    else
        if not VersusModeState.update_controlled_traversal(state) then
            VersusModeState.update_remote_authoritative_movement(state)
        end

        VersusModeState.refresh_control_animation(state)
    end

    if VersusModeState.control_for_peer(state.controller_peer_id) == state then
        VersusModeState.update_remote_camera_pose(state)
        update_manual_aim_preview(state)

        local t = gameplay_time()

        if t >= (state.next_status_sync_at or 0) then
            state.next_status_sync_at = t + 0.15
            VersusModeState.send_remote_status(
                state.controller_peer_id,
                state.status_message and t <= (state.status_until or 0) and state.status_message or state.attack_phase or "READY",
                (state.attack_deadline or state.controlled_traversal) and "busy" or "ready",
                state
            )
        end
    end
end

function VersusModeState.update_remote_controls()
    local pending = {}

    for _, state in pairs(mod._remote_controls or {}) do
        pending[#pending + 1] = state
    end

    for i = 1, #pending do
        VersusModeState.update_authoritative_remote_control(pending[i])
    end
end

mod.update = function(dt)
    if mod._realms_compat then
        mod._realms_compat.update(setting("enable_versus_mode"))
    end

    VersusModeState.update_lobby_plan_application()
    VersusModeState.maintain()
    VersusModeState.update_wait_camera_input(dt)
    VersusModeState.refresh_infected_stealth_visibility()
    VersusModeState.update_death_camera(dt)
    VersusModeState.update_survivor_spectating(dt)
    VersusModeState.refresh_possession_camera_player_body()
    VersusModeState.update_redeployment_geography()
    local picker_ui = Managers.ui
    if picker_ui and picker_ui:view_instance("versus_mode_spawn_view") then
        if mod.spawn_picker_available() then
            if is_server() then mod.spawn_picker_hold(true) end
        else
            picker_ui:close_view("versus_mode_spawn_view")
        end
    end
    VersusModeState.update_automatic_respawns()
    VersusModeState.update_last_survivor()
    VersusModeState.update_last_survivor_notice()
    VersusModeState.try_assign_pending_boss()
    VersusModeState.update_remote_controls()

    if mod._pending_remote_control then
        local pending = mod._pending_remote_control

        if gameplay_time() <= pending.deadline then
            VersusModeState.begin_client_control(pending.payload)
        else
            mod._pending_remote_control = nil
            VersusModeState.echo_localized("notice_assigned_enemy_unavailable")
        end
    end

    local hold_threshold = setting("long_hold_threshold")
    local hold_time = gameplay_time()
    local state = mod._control
    local input_gated = control_input_ui_gated(state)

    VersusModeState.update_vanilla_enemy_input(state, input_gated)

    -- Each DMF binding owns an independent timer, even when several actions
    -- share the same physical key. A Press action is resolved on release; a
    -- Long hold action is dispatched once when its timer crosses the threshold.
    for binding_id, hold in pairs(mod._keybind_holds or {}) do
        if hold.is_down
            and not hold.long_hold
            and hold_time - (hold.started_at or hold_time) >= hold_threshold then
            hold.long_hold = true

            if keybind_activation(binding_id) == "hold" then
                -- Consume the long action even when UI focus blocks it. This
                -- prevents the release edge from leaking gameplay input after
                -- a menu, chat box, popup or ImGui window closes.
                hold.long_action_fired = true

                if not input_gated then
                    fire_configured_keybind(binding_id)
                end
            end
        end
    end

    -- A Long-hold Possess action can create or release control above, so do not
    -- rely on the state snapshot captured before dispatch.
    state = mod._control

    if state and state.remote_client then
        VersusModeState.update_remote_client_control(state)

        return
    end

    if not state then
        if mod._suppress_freeflight_toggle_frames > 0 then
            mod._suppress_freeflight_toggle_frames = mod._suppress_freeflight_toggle_frames - 1
        end

        return
    end

    if not state.possessed then
        release_possession("initialization did not complete; control released.")

        return
    end

    if not is_server() then
        release_possession("server authority was lost; control released.")

        return
    end

    if not ALIVE[state.unit] then
        release_possession("controlled enemy died; control released.", nil, true)

        return
    end

    -- ALIVE remains true throughout a minion's native death animation. Detect
    -- depleted health before behavior/navigation extensions are removed, then
    -- release direct control and let the breed-specific death action run.
    local controlled_health = safe_extension(state.unit, "health_system")
    local health_ok, current_health = safe_extension_call(controlled_health, "current_health")

    if not HEALTH_ALIVE[state.unit]
        or health_ok and type(current_health) == "number" and current_health <= 0 then
        VersusModeState.log_controlled_death(state, controlled_health, current_health)
        release_possession("controlled enemy died; native death resumed.", nil, true)

        return
    end

    if VersusModeState.begin_normal_daemonhost_leave(state) then
        return
    end

    local behavior = safe_extension(state.unit, "behavior_system")
    local navigation = safe_extension(state.unit, "navigation_system")
    local locomotion = safe_extension(state.unit, "locomotion_system")
    local perception = safe_extension(state.unit, "perception_system")

    if not behavior or not navigation or not locomotion or not perception then
        release_possession("controlled enemy was removed; control released.")

        return
    end

    -- Creature Spawner can rebuild extensions before ALIVE changes. Refresh
    -- the references every frame so a retained destroyed userdata is never
    -- used after a despawn/replacement boundary.
    state.behavior = behavior
    state.navigation = navigation
    state.locomotion = locomotion
    state.perception = perception
    state.animation = safe_extension(state.unit, "animation_system") or state.animation
    VersusModeState.ensure_controlled_animation_lod(state)

    if state.locked_target and not VersusModeState.valid_attack_target(state.locked_target, state) then
        set_locked_target(state, nil)
        set_status(state, "Locked target lost; AUTO targeting", 2.5)
    end

    local presentation_target = VersusModeState.presentation_target_outline(state)

    if state.outlined_target ~= presentation_target then
        refresh_target_outline(state)
    end

    if (Specialist.target_mode_supported(state) and state.grenadier_target_lock ~= false
        or Specialist.casual_supported(state) and state.casual_combat == true)
        and not state.locked_target
        and not state.attack_deadline then
        set_locked_target(state, nearest_attack_target(state))
    end

    refresh_engine_position(state.unit)

    if state.attack_deadline then
        local t = gameplay_time()

        -- Camera rotation remains player-controlled throughout every attack.
        -- Committed melee/projectile headings stay frozen separately, while
        -- Mutant steering and continuous ranged aim intentionally remain live.
        if state.attack_started and state.requested_attack
            and state.requested_attack.gunner_combat_range == "far" then
            update_manual_movement(state, true)
        else
            update_manual_look(state)
        end

        if state.breed.name == SNIPER_BREED_NAME and state.sniper_shot_fired and t >= (state.sniper_shot_stop_t or 0) then
            state.sniper_fire_cooldown_until = state.sniper_fire_cooldown_until or (t + SNIPER_FIRE_COOLDOWN)
            pause_brain(state)
            set_status(state, "Longlas recharging", SNIPER_FIRE_COOLDOWN)
        else
            local target = state.attack_target
            local targetless = state.requested_attack and state.requested_attack.targetless

            if not targetless and not VersusModeState.valid_attack_target(target, state) then
                if state.requested_attack and state.requested_attack.casual_command then
                    target = nil
                else
                    target = nearest_attack_target(state)
                end

                state.attack_target = target
            end

            if not targetless and not target then
                pause_brain(state)
                set_status(state, "Attack cancelled: target lost", 2.5)
            else
                if not targetless and state.perception_component then
                    state.perception_component.lock_target = false
                end

                if not targetless and state.perception and state.perception_component and state.perception_component.target_unit ~= target then
                    safe_extension_call(state.perception, "_set_target_unit", target)
                end

                local attacking = state.poxburster_armed
                    or running_offensive_action(state)
                    or VersusModeState.spawn_leap_interrupted(state)
                    or VersusModeState.hound_pounce_in_progress(state)

                if VersusModeState.finish_failed_spawn_leap(state) then
                    -- Keep the trajectory-specific failure instead of READY.
                elseif state.command_action_complete then
                    pause_brain(state)
                    set_status(state, "READY", 1)
                elseif attacking then
                    if not state.attack_started then
                        local attack_name = state.requested_attack and state.requested_attack.label or "Native Attack"

                        VersusModeState.echo_attack_log_notice("started " .. attack_name .. ".")
                    end

                    state.attack_started = true
                    state.attack_phase = state.poxburster_armed and "FUSE ARMED"
                        or MANUAL_AIM_BREEDS[state.breed.name] and "AIMING"
                        or MUTANT_BREEDS[state.breed.name] and state.attack_phase
                        or state.spawn_leap_native_state and state.attack_phase
                        or "EXECUTING"
                end

                if VersusModeState.attack_command_should_stop(state, t, attacking) then
                    pause_brain(state)
                    set_status(state, "READY", 1)
                elseif state.attack_deadline and not state.attack_started and t >= state.attack_deadline then
                    local leap_timeout = state.breed.name == "chaos_spawn"
                        and state.requested_attack
                        and state.requested_attack.action_name == "leap"
                        and mod:localize("spawn_leap_no_trajectory")

                    pause_brain(state)
                    set_status(state, leap_timeout or "Attack unavailable from this position", 3)

                    if leap_timeout then
                        VersusModeState.echo_notice(leap_timeout)
                    else
                        VersusModeState.echo_localized("notice_native_attack_timeout")
                    end
                end
            end
        end
    else
        -- Traversal owns locomotion and unit facing, but the player must
        -- retain camera control after committing the destination. Reading
        -- look input here changes only yaw/pitch; the native path/climb
        -- remains authoritative for physical movement and rotation.
        if VersusModeState.update_controlled_traversal(state) then
            update_manual_look(state)
        else
            update_manual_movement(state)
        end

        VersusModeState.refresh_control_animation(state)
    end

    if mod._control then
        update_camera(state)
        update_manual_aim_preview(state)
    end
end

mod:hook(VersusModeState.boss_extension, "extensions_ready", function(func, self, ...)
    local result = func(self, ...)

    self._versus_mode_classification_ready = true
    VersusModeState.queue_normal_boss(self._unit, self)

    return result
end)

mod:hook(VersusModeState.stagger, "apply_stagger", function(
    func,
    unit,
    damage_profile,
    damage_profile_lerp_values,
    target_settings,
    attacking_unit,
    power_level,
    charge_level,
    is_critical_strike,
    is_backstab,
    is_flanking,
    hit_weakspot,
    dropoff_scalar,
    attack_direction,
    attack_type,
    attack_result,
    herding_template_or_nil,
    hit_shield,
    damage_type
)
    local scale = VersusModeState.controlled_boss_cc_scale(unit)

    if scale == nil then
        return func(
            unit,
            damage_profile,
            damage_profile_lerp_values,
            target_settings,
            attacking_unit,
            power_level,
            charge_level,
            is_critical_strike,
            is_backstab,
            is_flanking,
            hit_weakspot,
            dropoff_scalar,
            attack_direction,
            attack_type,
            attack_result,
            herding_template_or_nil,
            hit_shield,
            damage_type
        )
    end

    if scale <= 0 then
        return false, nil
    end

    local applied, stagger_type = func(
        unit,
        damage_profile,
        damage_profile_lerp_values,
        target_settings,
        attacking_unit,
        type(power_level) == "number" and power_level * scale or power_level,
        charge_level,
        is_critical_strike,
        is_backstab,
        is_flanking,
        hit_weakspot,
        dropoff_scalar,
        attack_direction,
        attack_type,
        attack_result,
        herding_template_or_nil,
        hit_shield,
        damage_type
    )

    if applied and scale < 1 then
        local blackboard = BLACKBOARDS[unit]
        local stagger_component = blackboard and Blackboard.write_component(blackboard, "stagger")

        if stagger_component then
            stagger_component.duration = (stagger_component.duration or 0) * scale
            stagger_component.length = (stagger_component.length or 1) * scale
        end
    end

    return applied, stagger_type
end)

mod:hook(VersusModeState.stagger, "force_stagger", function(func, unit, stagger_type, attack_direction, duration, length_scale, immune_time, attacker_unit, ignore_no_stagger)
    local scale = VersusModeState.controlled_boss_cc_scale(unit)

    if scale == nil then
        return func(unit, stagger_type, attack_direction, duration, length_scale, immune_time, attacker_unit, ignore_no_stagger)
    end

    if scale <= 0 then
        return
    end

    return func(
        unit,
        stagger_type,
        attack_direction,
        type(duration) == "number" and duration * scale or duration,
        type(length_scale) == "number" and length_scale * scale or length_scale,
        immune_time,
        attacker_unit,
        ignore_no_stagger
    )
end)

mod:hook(VersusModeState.minion_buff_extension, "add_internally_controlled_buff", function(func, self, template_name, t, ...)
    local scale = (template_name == "taunted" or template_name == "taunted_short")
        and VersusModeState.controlled_boss_cc_scale(self._unit)
        or nil

    if scale ~= nil and scale <= 0 then
        return
    end

    local result = func(self, template_name, t, ...)

    if scale ~= nil then
        VersusModeState.scale_taunt_buffs(self, scale)
    end

    return result
end)

mod:hook(VersusModeState.minion_buff_extension, "add_externally_controlled_buff", function(func, self, template_name, t, ...)
    local scale = (template_name == "taunted" or template_name == "taunted_short")
        and VersusModeState.controlled_boss_cc_scale(self._unit)
        or nil

    if scale ~= nil and scale <= 0 then
        return false, nil
    end

    local client_tried, local_index = func(self, template_name, t, ...)

    if scale ~= nil then
        VersusModeState.scale_taunt_buffs(self, scale)
    end

    return client_tried, local_index
end)

mod:hook(HumanGameplay, "_get_input", function(func, self, ...)
    local input = func(self, ...)

    if mod._control or mod._death_camera then
        return input:null_service()
    end

    return input
end)

-- When the selected infected is the only human, vanilla's all-dead check
-- ignores every surviving bot and immediately fails the mission. In the test
-- role only, count bots as survivors across the standard co-op variants.
mod:hook(VersusModeState.game_mode_coop, "_all_players_dead", VersusModeState.all_players_dead)
mod:hook(VersusModeState.game_mode_survival, "_all_players_dead", VersusModeState.all_players_dead)
mod:hook(VersusModeState.game_mode_expedition, "_all_players_dead", VersusModeState.all_players_dead)
mod:hook(VersusModeState.expedition_logic, "_all_players_dead", VersusModeState.all_players_dead)

-- In the infected-role test, survivor bots participate in the same mission
-- volume population as survivor humans. Keep each native condition's meaning:
-- all/half/one still require all/half/one, but the selected hogtied infected
-- shell is never counted as a survivor.
mod:hook(VersusModeState.trigger_all_players, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.all_progression_units_inside(self, volume_id)
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_all_alive_players, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.all_progression_units_inside(self, volume_id, "alive")
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_all_players_no_enemies, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.all_progression_units_inside_no_enemies(self, volume_id)
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_half_players, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        local inside, total = VersusModeState.progression_units_inside_count(self, volume_id)

        return total > 0 and inside >= total / 2
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_one_player, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.any_progression_unit_inside(self, volume_id)
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_only_enter, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.any_progression_unit_inside(self, volume_id)
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_end_zone, "filter_passed", function(func, self, filter_unit, volume_id, ...)
    if VersusModeState.test_active() then
        return VersusModeState.all_progression_units_inside(self, volume_id, "end_zone")
    end

    return func(self, filter_unit, volume_id, ...)
end)

mod:hook(VersusModeState.trigger_half_players, "_is_player", function(func, self, unit, ...)
    if VersusModeState.test_active() then
        return VersusModeState.progression_entering_unit(unit)
    end

    return func(self, unit, ...)
end)

mod:hook(VersusModeState.trigger_one_player, "_is_player", function(func, self, unit, ...)
    if VersusModeState.test_active() then
        return VersusModeState.progression_entering_unit(unit)
    end

    return func(self, unit, ...)
end)

mod:hook(VersusModeState.trigger_only_enter, "_is_player", function(func, self, unit, ...)
    if VersusModeState.test_active() then
        return VersusModeState.progression_entering_unit(unit)
    end

    return func(self, unit, ...)
end)

-- Level flow normally teleports bots through doors and onto moving platforms.
-- During the SoloPlay infected test they must reach the same space themselves;
-- an all-players platform only reports ready after every eligible bot's real
-- unit overlaps its passenger volume.
mod:hook(VersusModeState.door_extension, "teleport_bots", function(func, self, ...)
    if VersusModeState.test_active() then
        return
    end

    return func(self, ...)
end)

mod:hook(VersusModeState.moveable_platform_extension, "_get_passengers_onboard_info", function(func, self, ...)
    if VersusModeState.test_active() then
        return VersusModeState.platform_all_players_inside(self)
    end

    return func(self, ...)
end)

mod:hook(VersusModeState.moveable_platform_extension, "_handle_friendly_bots_on_set_direction", function(func, self, ...)
    if VersusModeState.test_active() then
        return
    end

    return func(self, ...)
end)

mod:hook(VersusModeState.moveable_platform_extension, "_set_bot_onboard", function(func, self, ...)
    if VersusModeState.test_active() then
        return
    end

    return func(self, ...)
end)

mod:hook(VersusModeState.moveable_platform_extension, "teleport_bots_to_node", function(func, self, ...)
    if VersusModeState.test_active() then
        return
    end

    return func(self, ...)
end)

-- A moving platform also has a passenger-correction path that bypasses every
-- public bot helper and teleports the unit directly during fixed update.
mod:hook(VersusModeState.moveable_platform_extension, "_teleport_player_onboard", function(func, self, unit, ...)
    if VersusModeState.test_active() then
        local spawn_manager = Managers.state and Managers.state.player_unit_spawn
        local player = spawn_manager and unit and spawn_manager:owner(unit)

        if player and (not VersusModeState.player_is_human(player) or VersusModeState.is_unit(unit)) then
            return
        end
    end

    return func(self, unit, ...)
end)

-- The player-bot behavior tree has an independent recovery teleport when a
-- path repeatedly fails or a level script sets level_forced_teleport. This is
-- the path that remains after door/platform helper teleports are suppressed.
-- Clear the pending request and let the bot keep solving a physical route.
mod:hook(BtConditions, "cant_reach_ally", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running)
    if VersusModeState.test_active() then
        local follow_component = blackboard and blackboard.follow

        if follow_component and follow_component.level_forced_teleport then
            follow_component.level_forced_teleport = false

            pcall(function()
                follow_component.level_forced_teleport_position:store(Vector3.zero())
            end)
        end

        return false
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running)
end)

mod:hook(BtConditions, "is_too_far_from_ally", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running)
    if VersusModeState.test_active() then
        return false
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running)
end)

-- The generated bot selector inlines its recovery conditions, so hooks on the
-- shared BtConditions table cannot prevent this action from running. Finish
-- the action without moving the bot, clear any scripted destination, and let
-- the behavior tree try to find a physical route again.
mod:hook(VersusModeState.bot_teleport_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    if VersusModeState.test_active() and not VersusModeState.is_unit(unit) then
        local follow_component = scratchpad and scratchpad.follow_component or blackboard and blackboard.follow

        if follow_component then
            follow_component.level_forced_teleport = false
            follow_component.has_teleported = true
            follow_component.needs_destination_refresh = true

            pcall(function()
                follow_component.level_forced_teleport_position:store(Vector3.zero())
            end)
        end

        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

-- Some mission flow events call PlayerMovement.teleport directly instead of
-- the bot/door/platform helpers. Guard only those callback scopes, preserving
-- ordinary player teleports and bot navigation transitions such as drops.
mod:hook(VersusModeState.flow_callbacks, "teleport_team_to_locations", function(func, params)
    VersusModeState.note_camera_transition("team teleport flow callback")

    return VersusModeState.run_without_bot_event_teleports(func, params)
end)

mod:hook(VersusModeState.flow_callbacks, "teleport_player_by_local_id", function(func, params)
    VersusModeState.note_camera_transition("player teleport flow callback")

    return VersusModeState.run_without_bot_event_teleports(func, params)
end)

mod:hook(VersusModeState.player_movement, "teleport", function(func, player, ...)
    if VersusModeState.survivor_bot_is_frozen(player) then
        return
    end

    if mod._versus_role_event_teleport_guard and VersusModeState.test_active() and player then
        if not VersusModeState.player_is_human(player) or VersusModeState.is_unit(player.player_unit) then
            return
        end
    end

    if player and valid_player_target(player.player_unit) then
        VersusModeState.note_camera_transition("survivor movement teleport")
    end

    return func(player, ...)
end)

-- The strict freeze switch must also catch teleports already queued through a
-- physics-safe callback and direct fixed-update teleports.
mod:hook(VersusModeState.player_movement, "_teleport", function(func, unit, ...)
    if VersusModeState.survivor_bot_unit_is_frozen(unit) then
        return
    end

    if valid_player_target(unit) then
        VersusModeState.note_camera_transition("survivor fixed-update teleport")
    end

    return func(unit, ...)
end)

-- Live test switch: suppress a survivor bot's complete input frame so it
-- remains stationary without disabling or rebuilding its behavior brain.
-- Releasing the switch lets the next normal input update resume immediately.
mod:hook(VersusModeState.bot_unit_input, "update", function(func, self, unit, dt, t)
    local result = func(self, unit, dt, t)

    if VersusModeState.survivor_bot_is_frozen(self._player) then
        table.clear(self._input)
        table.clear(self._ephemeral_input)

        self._move.x = 0
        self._move.y = 0
        self._dodge = false
        self._interact = false
        self._interact_held = false
    end

    return result
end)

mod:hook(VersusModeState.bot_unit_input, "get", function(func, self, action)
    if VersusModeState.survivor_bot_is_frozen(self._player) then
        if action == "move" then
            return Vector3.zero()
        end

        return nil
    end

    return func(self, action)
end)

-- Hiding the shell's mesh does not remove an already-created party nameplate.
-- Remove that retained marker on every nameplate scan; clearing the role lets
-- the following scan recreate it normally for the restored survivor.
mod:hook(VersusModeState.nameplates, "_nameplate_extension_scan", function(func, self, ...)
    local result = func(self, ...)

    VersusModeState.remove_shell_nameplate(self)
    VersusModeState.remove_hidden_survivor_nameplates(self)

    return result
end)

-- Treat the selected shell as a role outside the survivor strike team without
-- mutating Darktide's network player identity or side registration. The role
-- remains visible to VersusMode's own roster selector, while vanilla team
-- panels, nameplates and compass consumers of the gameplay composition omit it.
mod:hook(VersusModeState.player_compositions, "players", function(func, composition_name, result_table, ...)
    local result = func(composition_name, result_table, ...)

    if composition_name == "game_session_players"
        and setting("hide_infected_team_panel")
        and result then
        for unique_id in pairs(VersusModeState.roles()) do
            result[unique_id] = nil
        end
    end

    return result
end)

-- The infected shell deliberately uses Darktide's native hogtied state so
-- trigger volumes, end zones, AI target tables and defeat checks already
-- exclude it. Block the normal rescue interaction to keep that role stable
-- until the host explicitly restores it with the Apply binding.
mod:hook(VersusModeState.player_death, "die", function(func, unit, ...)
    if VersusModeState.is_unit(unit) then
        return
    end

    return func(unit, ...)
end)

mod:hook(VersusModeState.rescue_interaction, "interactee_condition_func", function(func, self, interactee_unit, ...)
    if VersusModeState.is_unit(interactee_unit) then
        return false
    end

    return func(self, interactee_unit, ...)
end)

-- Ordinary captured survivors are moved forward to active rescue beacons.
-- The infected shell is not a missing survivor and must not reserve or move
-- through those mission-progress slots.
mod:hook(VersusModeState.respawn_beacon_system, "_update_hogtied_players", function(func, self, ...)
    local should_move, players = func(self, ...)

    if players then
        for i = #players, 1, -1 do
            local player = players[i]
            local infected = false

            for _, role in pairs(VersusModeState.roles()) do
                if role.infected_player == player then
                    infected = true

                    break
                end
            end

            if infected then
                table.remove(players, i)
            end
        end

        if #players == 0 then
            should_move = false
        end
    end

    return should_move, players
end)

function VersusModeState.install_client_view_hooks()
    -- Hogtied players normally use Primary/spectate_next to cycle through
    -- living survivors. Versus Mode binds Primary to an enemy attack, so that
    -- same input could silently replace our controlled streaming reference.
    -- Keep that internal reference host-selected and expose neither observer
    -- status nor a survivor follow unit to other client systems.
    mod:hook(VersusModeState.camera_handler, "update", function(func, self, ...)
        local role = VersusModeState.camera_handler_role(self)

        if role then
            VersusModeState.isolate_observer_camera(role, self, "pre-update")
        end

        local result = func(self, ...)

        role = VersusModeState.camera_handler_role(self)

        if role and not VersusModeState.cinematic_camera_active() then
            VersusModeState.isolate_observer_camera(role, self, "post-update")

            return role.infected_unit
        end

        return result
    end)

    mod:hook(VersusModeState.camera_handler, "_next_follow_unit", function(func, self, ...)
        local role = VersusModeState.camera_handler_role(self)

        if role and not VersusModeState.cinematic_camera_active() then
            if not role.camera_cycle_block_logged then
                role.camera_cycle_block_logged = true
                mod:info("Versus Mode: blocked native survivor spectate cycling for infected input.")
            end

            return nil
        end

        return func(self, ...)
    end)

    mod:hook(VersusModeState.camera_handler, "_switch_follow_target", function(func, self, new_unit, ...)
        local role = VersusModeState.camera_handler_role(self)

        if role and not VersusModeState.cinematic_camera_active() then
            if not role.camera_streaming_switch and not role.camera_restoring then
                new_unit = valid_player_target(role.streaming_anchor_unit)
                    and role.streaming_anchor_unit
                    or role.infected_unit
            end

            self._first_person_spectating_mode = false

            local result = func(self, new_unit, ...)
            local wwise_sync = Managers.wwise_game_sync

            if wwise_sync and wwise_sync.set_followed_player_unit then
                pcall(wwise_sync.set_followed_player_unit, wwise_sync, nil)
            end

            return result
        end

        return func(self, new_unit, ...)
    end)

    mod:hook(VersusModeState.camera_handler, "is_observing", function(func, self, ...)
        if VersusModeState.camera_handler_role(self) and not VersusModeState.cinematic_camera_active() then
            return false
        end

        return func(self, ...)
    end)

    mod:hook(VersusModeState.camera_handler, "camera_follow_unit", function(func, self, ...)
        local role = VersusModeState.camera_handler_role(self)

        if role and not VersusModeState.cinematic_camera_active() then
            -- The handler's internal unit is only a streaming reference. Other
            -- client systems must not treat it as the observed survivor.
            return nil
        end

        return func(self, ...)
    end)

    mod:hook(VersusModeState.camera_handler, "_update_player_mood", function(func, self, ...)
        local role = VersusModeState.camera_handler_role(self)

        if role and not role.camera_restoring and not VersusModeState.cinematic_camera_active() then
            VersusModeState.clear_observer_moods(role, self)

            return
        end

        return func(self, ...)
    end)

    -- Block every later attempt to re-mark a survivor as the local camera
    -- target. PlayerUnitFxExtension uses this flag directly for exclusive
    -- screen particles and sounds, independently of CameraHandler's cached
    -- follow unit, which is why 0.11.3's field-only guard missed the leak.
    local function block_infected_player_follow(func, self, is_followed, first_person_spectating, ...)
        local role = VersusModeState.local_active() and mod._versus_role_test or nil

        if role and not role.camera_restoring and not VersusModeState.cinematic_camera_active() then
            return func(self, false, false, ...)
        end

        return func(self, is_followed, first_person_spectating, ...)
    end

    mod:hook(VersusModeState.player_unit_first_person, "set_camera_follow_target", block_infected_player_follow)
    mod:hook(VersusModeState.player_husk_first_person, "set_camera_follow_target", block_infected_player_follow)

    -- The host owns the infected shell's hogtied state. A host-only camera mod
    -- can therefore replicate a camera-tree node that does not exist under the
    -- client's third-person tree. CameraHandler dereferences that missing node
    -- before the global free-flight viewport can mask it, crashing the client.
    -- Keep the hidden local shell on vanilla's known-good hogtied node. A live
    -- survivor used only as the streaming root is forced to third person so
    -- its arms/equipment cannot leak beneath the separate free-flight view.
    local function guard_infected_shell_camera_node(func, self, ...)
        local tree, node, object, ignore_offset = func(self, ...)
        local role = VersusModeState.local_active() and mod._versus_role_test or nil

        if role and (role.infected_unit == self._unit or role.streaming_anchor_unit == self._unit) then
            local expected_node = role.infected_unit == self._unit and "hogtied" or "third_person"

            if not role.camera_node_guard_logged and (tree ~= "third_person" or node ~= expected_node) then
                role.camera_node_guard_logged = true
                mod:info(
                    "Versus Mode: corrected native stream camera node %s/%s to third_person/%s.",
                    tostring(tree),
                    tostring(node),
                    expected_node
                )
            end

            return "third_person", expected_node, nil, ignore_offset
        end

        return tree, node, object, ignore_offset
    end

    mod:hook(VersusModeState.player_unit_camera, "camera_tree_node", guard_infected_shell_camera_node)
    mod:hook(VersusModeState.player_husk_camera, "camera_tree_node", guard_infected_shell_camera_node)

    -- A remote camera mod can replicate a node name from a different tree
    -- (for example a hub-only node paired with the mission third-person
    -- tree). Vanilla assumes that pair is valid and dereferences nil. This
    -- can affect an ordinary Operative during death/observer transitions as
    -- well as the hidden Heretic shell, so retain a known node from the
    -- requested tree for every local player while Versus Mode is enabled.
    mod:hook(VersusModeState.camera_manager, "set_camera_node", function(func, self, viewport_name, tree_id, node_name, ...)
        local viewport_trees = self._node_trees and self._node_trees[viewport_name]
        local tree = viewport_trees and viewport_trees[tree_id]
        local nodes = tree and tree.nodes

        if setting("enable_versus_mode") and nodes and not nodes[node_name] then
            local current_node = self.current_camera_node and self:current_camera_node(viewport_name)
            local fallback_node = current_node and nodes[current_node] and current_node
            local player = local_player()
            local player_unit = player and player.player_unit

            if not fallback_node
                and player_unit
                and VersusModeState.player_is_hogtied(player_unit)
                and nodes.hogtied then
                fallback_node = "hogtied"
            end

            fallback_node = fallback_node
                or nodes.third_person and "third_person"
                or nodes.hogtied and "hogtied"

            if fallback_node then
                local log_key = tostring(tree_id) .. "/" .. tostring(node_name)

                if mod._camera_node_guard_log_key ~= log_key then
                    mod._camera_node_guard_log_key = log_key
                    mod:info(
                        "Versus Mode: rejected invalid camera node %s; retained %s/%s.",
                        log_key,
                        tostring(tree_id),
                        tostring(fallback_node)
                    )
                end

                return func(self, viewport_name, tree_id, fallback_node, ...)
            end
        end

        return func(self, viewport_name, tree_id, node_name, ...)
    end)

    -- Global free flight renders with the bottom gameplay viewport's shading
    -- callback. Apply the death-only override after Darktide has blended its
    -- normal environment and moods; on the first frame after cleanup, the
    -- native callback owns these values again without a persisted mood.
    mod:hook(VersusModeState.camera_manager, "shading_callback", function(
        func,
        self,
        world,
        shading_environment,
        viewport,
        default_shading_environment_resource
    )
        local result = func(
            self,
            world,
            shading_environment,
            viewport,
            default_shading_environment_resource
        )
        local death_camera = mod._death_camera
        local amount = death_camera and death_camera.greyscale_amount or 0

        if amount > 0 and self._world == world then
            ShadingEnvironment.set_scalar(shading_environment, "grey_scale_enabled", 1)
            ShadingEnvironment.set_scalar(shading_environment, "grey_scale_amount", math_min(1, amount))
            ShadingEnvironment.set_vector3(
                shading_environment,
                "grey_scale_weights",
                Vector3(0.33, 0.33, 0.33)
            )
        end

        return result
    end)

    -- Vanilla free flight accumulates unrestricted local-axis pitch and roll,
    -- which allows the waiting infected camera to pass vertical and invert.
    -- After every normal free-flight update, rebuild an upright rotation from
    -- its forward vector and clamp pitch to about +/-77 degrees. This applies
    -- only while the local infected is waiting, never during possession or
    -- ordinary developer free flight.
    mod:hook(FreeFlightManager, "_update_camera", function(func, self, input, dt, camera_data, ...)
        if mod._death_camera then
            return
        end

        if VersusModeState.local_active() and not mod._control then
            local role = mod._versus_role_test
            local gated = mouse_look_ui_gate()
            local t = gameplay_time()

            if role
                and role.spectator_active
                and VersusModeState.spectator_target_valid(role.spectator_target_unit) then
                return
            end

            if gated then
                role.wait_camera_input_block_until = t + UI_INPUT_RELEASE_GRACE

                return
            elseif t < (role.wait_camera_input_block_until or 0) then
                return
            end
        end

        local result = func(self, input, dt, camera_data, ...)

        if VersusModeState.local_active()
            and not mod._control
            and camera_data
            and camera_data.projection_type == Camera.PERSPECTIVE then
            local position, rotation = self:camera_position_rotation("global")

            if position and rotation then
                local forward = Quaternion.forward(rotation)
                local pitch_limit_z = math_sin(1.35)
                local z = math_max(-pitch_limit_z, math_min(pitch_limit_z, Vector3.z(forward)))
                local horizontal = math.sqrt(math_max(0, 1 - z * z))
                local yaw = math_atan2(Vector3.x(forward), Vector3.y(forward))
                local upright_forward = Vector3(math_sin(yaw) * horizontal, math_cos(yaw) * horizontal, z)

                self:teleport_camera("global", position, Quaternion.look(upright_forward, vector3_up()))
            end
        end

        return result
    end)

    -- The infected waiting state owns its own free-flight camera and status
    -- HUD. This element draws both AWAITING RESCUE and the bottom-centre
    -- Spectating / cycle-player instructions, so suppress its complete update.
    mod:hook(VersusModeState.spectator_text, "update", function(func, self, ...)
        if VersusModeState.local_active() then
            self._update_spectator_text = true

            return
        end

        return func(self, ...)
    end)

    mod:hook(VersusModeState.spectator_text, "draw", function(func, self, ...)
        if VersusModeState.local_active() then
            return
        end

        return func(self, ...)
    end)

    -- Survivor tags, Emperor Vision and outline-enhancement mods all converge
    -- on the local OutlineSystem. Keep their stacks intact, but hide minion
    -- layers in every infected view and player layers while that survivor has
    -- a native invisible/unperceivable keyword. VersusMode then places its
    -- persistent white/red Operative layer above the remaining player stack.
    mod:hook(VersusModeState.outline_system, "update", function(func, self, ...)
        local suppress = VersusModeState.local_infected_view()
        local allied_units = suppress and setting("show_allied_heretic_outlines")
            and VersusModeState.allied_heretic_units()
            or {}

        if self._unit_extension_data then
            for unit, extension in pairs(self._unit_extension_data) do
                if extension.visible_material_layers == VersusModeState.suppressed_outline_marker
                    and (not suppress
                        or extension.name == "MinionOutlineExtension" and allied_units[unit]
                        or extension.name == "PlayerUnitOutlineExtension"
                            and not VersusModeState.player_is_hidden_from_infected(unit)) then
                    extension.visible_material_layers = nil
                end
            end
        end

        VersusModeState.refresh_allied_heretic_outlines(self, allied_units)

        local result = func(self, ...)

        if suppress and self._unit_extension_data then
            for unit, extension in pairs(self._unit_extension_data) do
                local suppress_extension = extension.name == "MinionOutlineExtension"
                        and not allied_units[unit]
                    or extension.name == "PlayerUnitOutlineExtension"
                        and VersusModeState.player_is_hidden_from_infected(unit)

                if suppress_extension
                    and extension.visible_material_layers
                    and extension.visible_material_layers ~= VersusModeState.suppressed_outline_marker then
                    pcall(self._hide_outline, self, unit, extension)
                    extension.visible_material_layers = VersusModeState.suppressed_outline_marker
                end
            end
        end

        for unit in pairs(allied_units) do
            VersusModeState.set_outline_material_color(
                unit,
                VersusModeState.allied_heretic_outline_material_layers,
                VersusModeState.allied_heretic_outline_color
            )
        end

        local state = mod._control

        VersusModeState.refresh_operative_outlines(self, state, not suppress)

        return result
    end)
end

-- The smart-tag HUD owns a separate Ingame input service, so nulling the
-- player's HumanGameplay input is not enough to stop a shared target-cycle /
-- ping key from creating a vanilla tag. Intercepting the system call also
-- survives HUD replacements such as Markers Improved All-in-One. Only the
-- possessing local player's tag actions are suppressed; tags from every other
-- player continue through unchanged.
mod:hook(SmartTagSystem, "set_tag", function(func, self, template_name, tagger_unit, target_unit, target_location)
    if suppress_possession_smart_tag(tagger_unit) then
        return
    end

    return func(self, template_name, tagger_unit, target_unit, target_location)
end)

mod:hook(SmartTagSystem, "trigger_tag_interaction", function(func, self, tag_id, interactor_unit, target_unit, optional_alternate)
    if suppress_possession_smart_tag(interactor_unit) then
        return
    end

    return func(self, tag_id, interactor_unit, target_unit, optional_alternate)
end)

-- Darktide's stealth effect deliberately leaves allies half-visible. In an
-- infected view, promote only native invisible/unperceivable survivors to a
-- complete fade. Hooking the setter closes the first-frame ordering gap where
-- StealthEffects could otherwise overwrite our update with its 0.5 value.
mod:hook(VersusModeState.fade_system, "set_min_fade", function(func, self, unit, min_fade, ...)
    if not mod._restoring_infected_stealth_visibility
        and VersusModeState.local_infected_view()
        and VersusModeState.player_is_hidden_from_infected(unit) then
        min_fade = 1
    end

    return func(self, unit, min_fade, ...)
end)

-- Markers Improved All-in-One replaces _draw_markers during its own load, so
-- this hook is deliberately installed from on_all_mods_loaded below. Skipping
-- the draw call leaves every marker registered and untouched; they reappear
-- normally as soon as possession ends.
local function install_world_marker_compatibility_hook()
    if mod._world_marker_compatibility_hooked then
        return
    end

    mod._world_marker_compatibility_hooked = true

    mod:hook(HudElementWorldMarkers, "_draw_markers", function(func, self, ...)
        local state = mod._control

        if state and state.possessed or VersusModeState.local_active() then
            return
        end

        return func(self, ...)
    end)
end

-- Realms hot-join profile sync can occasionally leave a cosmetic slot absent
-- on the joining client even though the authoritative host immediately sends
-- an equip-from-profile RPC for that slot. Vanilla treats the resulting N/A
-- client item as a fatal profile mismatch. Repair only that missing cosmetic
-- entry from the host's exact network item name. Existing but different items
-- and wieldable slots still pass through unchanged and retain vanilla's fatal
-- mismatch check, so this cannot hide a real weapon/profile disagreement.
local function install_realms_profile_visual_repair()
    local NetworkLookup = require("scripts/network_lookup/network_lookup")
    local PlayerHuskVisualLoadoutExtension = require(
        "scripts/extension_systems/visual_loadout/player_husk_visual_loadout_extension"
    )

    if rawget(PlayerHuskVisualLoadoutExtension, "__versus_mode_realms_profile_visual_repair") then
        return
    end

    rawset(PlayerHuskVisualLoadoutExtension, "__versus_mode_realms_profile_visual_repair", true)

    local function realms_client_active()
        local connection = Managers.connection

        if not connection or not connection:is_client() then
            return false
        end

        local realms = get_mod("Realms")

        if not realms or type(realms.network_is_available) ~= "function" then
            return false
        end

        local ok, available = pcall(realms.network_is_available)

        return ok and available == true
    end

    mod:hook(PlayerHuskVisualLoadoutExtension, "rpc_player_equip_item_from_profile_to_slot", function(
        func,
        self,
        channel_id,
        go_id,
        slot_id,
        debug_item_id,
        ...
    )
        if realms_client_active() then
            local slot_name = NetworkLookup.player_inventory_slot_names[slot_id]
            local debug_item_name = NetworkLookup.player_item_names[debug_item_id]
            local slot_config = slot_name and self._slot_configuration and self._slot_configuration[slot_name]
            local player = self._player
            local profile = player and player:profile()
            local visual_loadout = profile and profile.visual_loadout
            local client_item = visual_loadout and visual_loadout[slot_name]

            if slot_config and not slot_config.wieldable and debug_item_name and not client_item then
                local item = self._item_definitions and self._item_definitions[debug_item_name]

                if item and item.name == debug_item_name then
                    if not visual_loadout then
                        visual_loadout = {}
                        profile.visual_loadout = visual_loadout
                    end

                    visual_loadout[slot_name] = item

                    local peer_id = player:peer_id()
                    local log_key = string.format("%s:%s", tostring(peer_id), slot_name)

                    mod._realms_profile_visual_repairs = mod._realms_profile_visual_repairs or {}

                    if not mod._realms_profile_visual_repairs[log_key] then
                        mod._realms_profile_visual_repairs[log_key] = true
                        mod:info(
                            "Versus Mode: repaired missing Realms profile item `%s` in `%s` for peer %s.",
                            debug_item_name,
                            slot_name,
                            tostring(peer_id)
                        )
                    end
                end
            end
        end

        return func(self, channel_id, go_id, slot_id, debug_item_id, ...)
    end)
end

-- These HUD elements come from vanilla Darktide and common HUD mods.
-- Temporarily marking only their draw entries invisible avoids changing any
-- settings or persistent HUD state; their exact previous visibility returns
-- after this draw call. The two retained-mode right-side handlers are also
-- torn down for the frame so their cached weapon/ability widgets cannot remain
-- visible while the player is controlling an enemy.
local function install_possession_hud_compatibility_hook()
    if mod._possession_hud_compatibility_hooked then
        return
    end

    mod._possession_hud_compatibility_hooked = true

    local function suppress_local_player_panel(hud)
        local elements = hud._elements
        local team_panel = elements and elements.HudElementTeamPanelHandler

        if not team_panel then
            return nil
        end

        local player_panels = team_panel._player_panels_array
        local player_data = team_panel._player_panel_by_unique_id and team_panel._player_panel_by_unique_id[team_panel._my_unique_id]
        local player_index
        local state = mod._control
        local original_player = state and state.player or local_player()
        local original_peer_id = VersusModeState.player_peer_id(original_player)
        local original_local_id = VersusModeState.player_local_id(original_player)
        local personal_slot_data
        local personal_slot_index

        for i = 1, player_panels and #player_panels or 0 do
            local candidate = player_panels[i]
            local candidate_player = candidate and candidate.player
            local candidate_peer_id = VersusModeState.player_peer_id(candidate_player)
            local candidate_local_id = VersusModeState.player_local_id(candidate_player)
            local identity_match = original_player and candidate_player == original_player
                or original_peer_id and candidate_peer_id == original_peer_id
                    and (original_local_id == nil
                        or tostring(candidate_local_id) == tostring(original_local_id))
            local panel_class = candidate and candidate.panel
                and tostring(candidate.panel.__class_name or "") or ""
            local personal_slot = candidate
                and (candidate.scenegraph_id == "local_player"
                    or string.find(panel_class, "PersonalPlayerPanel", 1, true) ~= nil)

            if personal_slot and not personal_slot_data then
                personal_slot_data = candidate
                personal_slot_index = i
            end

            if candidate and (candidate == player_data or candidate.is_my_player or identity_match) then
                player_data = candidate
                player_index = i

                break
            end
        end

        -- During Realms possession the original Heretic shell is removed from
        -- the Strike Team composition. The HUD can instead anchor a survivor
        -- in the native personal slot without marking it as `is_my_player`.
        -- Suppress that explicitly personal slot, never an arbitrary teammate.
        if not player_index and personal_slot_data then
            player_data = personal_slot_data
            player_index = personal_slot_index
        end

        local panel = player_data and player_data.panel

        if not player_data or not panel then
            return nil
        end

        local snapshot = {
            player_panels = player_panels,
            player_index = player_index,
            player_data = player_data,
            player_panel_by_unique_id = team_panel._player_panel_by_unique_id,
            unique_id = player_data.unique_id,
            ui_renderer = hud._ui_renderer,
            panel = panel,
        }

        -- This is the panel's native retained-mode teardown. In addition to
        -- ordinary widgets, it destroys the separately-managed health/wound
        -- segment widgets that otherwise survive until a menu refresh.
        panel:set_visible(false, snapshot.ui_renderer, true)

        -- Removing the entry makes the vanilla team-panel loop skip the local
        -- player even when Custom HUD has replaced the handler's draw method.
        if player_index then
            table.remove(player_panels, player_index)
        end

        if snapshot.player_panel_by_unique_id and snapshot.unique_id then
            snapshot.player_panel_by_unique_id[snapshot.unique_id] = nil
        end

        if not mod._personal_panel_widget_suppression_logged then
            mod._personal_panel_widget_suppression_logged = true
            mod:info("Native local-player panel detached from HUD draw during possession.")
        end

        return snapshot
    end

    local function restore_local_player_panel(snapshot)
        if not snapshot then
            return
        end

        if snapshot.player_index then
            table.insert(snapshot.player_panels, snapshot.player_index, snapshot.player_data)
        end

        if snapshot.player_panel_by_unique_id and snapshot.unique_id then
            snapshot.player_panel_by_unique_id[snapshot.unique_id] = snapshot.player_data
        end

        -- Mark the retained passes dirty again so the native panel returns on
        -- the first frame after possession ends.
        snapshot.panel:set_visible(true, snapshot.ui_renderer, true)
    end

    mod:hook(UIHud, "draw", function(func, self, ...)
        local state = mod._control
        local visible = self._currently_visible_elements
        local possessing = state and state.possessed
        local infected_view = VersusModeState.local_active()

        if not possessing and not infected_view or not visible then
            return func(self, ...)
        end

        local old_crosshair = visible.HudElementCrosshair
        local old_crosshair_hud = visible.HudElementCrosshairHud
        local old_crit = visible.HudElementCrit
        local old_dodge_count = visible.HudElementDodgeCount
        local old_player_ability_handler = visible.HudElementPlayerAbilityHandler
        local old_player_weapon_handler = visible.HudElementPlayerWeaponHandler
        local old_weapon_counter = visible.HudElementWeaponCounter
        local personal_panel_snapshot = possessing and setting("replace_player_panel") and suppress_local_player_panel(self)
        local elements = self._elements
        local ui_renderer = self._ui_renderer
        local player_ability_handler = elements and elements.HudElementPlayerAbilityHandler
        local player_weapon_handler = elements and elements.HudElementPlayerWeaponHandler

        if possessing and setting("replace_player_panel") and not personal_panel_snapshot and not mod._personal_panel_suppression_failure_logged then
            mod._personal_panel_suppression_failure_logged = true
            mod:info("Versus Mode: no native personal-player panel is present during possession; no HUD panel was detached.")
        end

        visible.HudElementCrosshair = false
        visible.HudElementCrosshairHud = false
        visible.HudElementCrit = false
        visible.HudElementDodgeCount = false
        visible.HudElementPlayerAbilityHandler = false
        visible.HudElementPlayerWeaponHandler = false
        visible.HudElementWeaponCounter = false

        if old_player_ability_handler and player_ability_handler and player_ability_handler.set_visible then
            player_ability_handler:set_visible(false, ui_renderer, true)
        end

        if old_player_weapon_handler and player_weapon_handler and player_weapon_handler.set_visible then
            player_weapon_handler:set_visible(false, ui_renderer, true)
        end

        func(self, ...)

        restore_local_player_panel(personal_panel_snapshot)
        if old_player_ability_handler and player_ability_handler and player_ability_handler.set_visible then
            player_ability_handler:set_visible(true, ui_renderer, true)
        end

        if old_player_weapon_handler and player_weapon_handler and player_weapon_handler.set_visible then
            player_weapon_handler:set_visible(true, ui_renderer, true)
        end

        visible.HudElementCrosshair = old_crosshair
        visible.HudElementCrosshairHud = old_crosshair_hud
        visible.HudElementCrit = old_crit
        visible.HudElementDodgeCount = old_dodge_count
        visible.HudElementPlayerAbilityHandler = old_player_ability_handler
        visible.HudElementPlayerWeaponHandler = old_player_weapon_handler
        visible.HudElementWeaponCounter = old_weapon_counter
    end)

end

function VersusModeState.install_remote_animation_repair_hooks()
    if mod._remote_animation_repair_hooks_installed then
        return
    end

    mod._remote_animation_repair_hooks_installed = true

    -- Observe the exact event index that MinionAnimationExtension sends. The
    -- capture marker exists only for the duration of one controlled call, so
    -- unrelated Darktide RPCs pass through without allocation or inspection.
    mod:hook(VersusModeState.game_session_manager, "send_rpc_clients", function(func, self, rpc_name, ...)
        VersusModeState.capture_remote_animation_rpc(rpc_name, ...)

        return func(self, rpc_name, ...)
    end)

    mod:hook(VersusModeState.game_session_manager, "send_rpc_clients_except", function(func, self, rpc_name, except_channel_id, ...)
        VersusModeState.capture_remote_animation_rpc(rpc_name, ...)

        return func(self, rpc_name, except_channel_id, ...)
    end)

    mod:hook(VersusModeState.minion_animation, "anim_event", function(func, self, event_name, optional_except_channel_id)
        local state = self._is_server and VersusModeState.control_for_unit(self._unit) or nil

        if not state or not state.possessed or not state.controller_peer_id then
            return func(self, event_name, optional_except_channel_id)
        end

        local unit_id = state.network_unit_id
            or self._game_object_id
            or VersusModeState.network_unit_id(self._unit)

        if type(unit_id) ~= "number" then
            return func(self, event_name, optional_except_channel_id)
        end

        local previous_capture = mod._remote_animation_capture
        local capture = {
            event_name = event_name,
            rpc_name = "rpc_minion_anim_event",
            unit_id = unit_id,
        }

        mod._remote_animation_capture = capture

        local result = func(self, event_name, optional_except_channel_id)

        mod._remote_animation_capture = previous_capture
        VersusModeState.send_remote_animation_capture(state, capture)

        return result
    end)

    mod:hook(VersusModeState.minion_animation, "anim_event_with_variable_float", function(func, self, event_name, variable_name, variable_value)
        local state = self._is_server and VersusModeState.control_for_unit(self._unit) or nil

        if not state or not state.possessed or not state.controller_peer_id then
            return func(self, event_name, variable_name, variable_value)
        end

        local unit_id = state.network_unit_id
            or self._game_object_id
            or VersusModeState.network_unit_id(self._unit)

        if type(unit_id) ~= "number" then
            return func(self, event_name, variable_name, variable_value)
        end

        local previous_capture = mod._remote_animation_capture
        local capture = {
            event_name = event_name,
            rpc_name = "rpc_minion_anim_event_variable_float",
            unit_id = unit_id,
        }

        mod._remote_animation_capture = capture

        local result = func(self, event_name, variable_name, variable_value)

        mod._remote_animation_capture = previous_capture
        VersusModeState.send_remote_animation_capture(state, capture)

        return result
    end)

    -- A native event that reaches the client cancels its exact queued mirror.
    -- If the mirror arrives second, this same record is consumed as a credit.
    -- Only a genuinely absent native RPC survives the short fallback delay.
    mod:hook(VersusModeState.animation_system, "rpc_minion_anim_event", function(func, self, channel_id, unit_id, event_index)
        local result = func(self, channel_id, unit_id, event_index)

        VersusModeState.note_remote_animation_rpc(unit_id, event_index)

        return result
    end)

    mod:hook(VersusModeState.animation_system, "rpc_minion_anim_event_variable_float", function(func, self, channel_id, unit_id, event_index, variable_index, variable_value, variable_name)
        local result = func(
            self,
            channel_id,
            unit_id,
            event_index,
            variable_index,
            variable_value,
            variable_name
        )

        VersusModeState.note_remote_animation_rpc(unit_id, event_index, variable_index)

        return result
    end)
end

-- Charge is authored for the Captain's melee phase. The command descriptors
-- above now request that native weapon switch before this leaf can enter. Do
-- not inject attack_charge_start_fwd here: BtChargeAction deliberately waits
-- for its navigation route, then owns the animation and every later state.
-- The hooks below are telemetry only, so a log can distinguish route entry,
-- the real authored wind-up and physical charge movement.
mod:hook(VersusModeState.charge_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack
    local controlled_captain_charge = state
        and state.unit == unit
        and state.attack_deadline
        and state.breed
        and CAPTAIN_BREEDS[state.breed.name]
        and attack
        and attack.captain_charge == true

    if controlled_captain_charge then
        local visual_loadout = state.visual_loadout or safe_extension(unit, "visual_loadout_system")
        local wielded_ok, wielded_slot = safe_extension_call(visual_loadout, "wielded_slot_name")

        scratchpad.versus_mode_captain_charge_state = state
        state.captain_charge_native_state = scratchpad.state or "buildup"
        state.attack_phase = "CHARGE APPROACH"
        mod:info(
            "Versus Mode: %s Charge entered native route buildup with %s wielded; waiting for the authored wind-up.",
            tostring(state.breed.name),
            wielded_ok and tostring(wielded_slot) or "an unknown slot"
        )
    end

    return result
end)

mod:hook(VersusModeState.charge_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = scratchpad.versus_mode_captain_charge_state

    if state
        and state.unit == unit
        and VersusModeState.control_for_unit(unit) == state
        and state.attack_deadline
        and state.requested_attack
        and state.requested_attack.captain_charge == true then
        state.captain_charge_native_state = scratchpad.state or state.captain_charge_native_state

        if scratchpad.started_charge_anim and not scratchpad.versus_mode_charge_animation_logged then
            scratchpad.versus_mode_charge_animation_logged = true
            state.attack_phase = "CHARGE WIND-UP"
            mod:info("Versus Mode: Captain Charge native authored wind-up started.")
        end

        if scratchpad.state == "charging" and not scratchpad.versus_mode_charge_movement_logged then
            scratchpad.versus_mode_charge_movement_logged = true
            state.attack_phase = "EXECUTING"
            mod:info("Versus Mode: Captain Charge native movement started.")
        end
    end

    return result
end)

-- Keep Captain weapon transitions native and visible. The switch leaf sits
-- above the attack selectors, so a queued command needs its own full
-- acquisition window after the authored draw finishes; otherwise a transient
-- block/stagger or phase update can consume Casual Primary's original window.
mod:hook(VersusModeState.switch_weapon_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local requested = state and state.requested_attack
    local weapon_switch_component = blackboard and blackboard.weapon_switch
    local wanted_slot = weapon_switch_component and weapon_switch_component.wanted_weapon_slot
    local controlled_switch = state
        and state.unit == unit
        and state.attack_deadline
        and state.breed
        and CAPTAIN_BREEDS[state.breed.name]
        and requested
        and requested.captain_weapon_slot == wanted_slot
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)

    if controlled_switch then
        local switch_finished_t = scratchpad.switch_finished_timing or t
        local native_duration = math_max(0, switch_finished_t - t)

        state.attack_phase = "SWITCHING WEAPON"
        state.attack_deadline = math_max(
            state.attack_deadline or 0,
            switch_finished_t + Specialist.captain_post_switch_acquire_grace
        )

        mod:info(
            "Versus Mode: Captain switching %s -> %s with %.2f s native draw; queued attack protected until %.2f.",
            tostring(scratchpad.slot_that_got_unwielded or "unarmed"),
            tostring(wanted_slot),
            native_duration,
            state.attack_deadline
        )
    end

    return result
end)

-- The phase updater runs independently of the behavior brain. Suppress it for
-- a possessed ordinary Captain so it cannot combine a retained melee phase
-- with a commanded far range between two shotgun/plasma attacks. Release
-- restores one coherent phase/range pair before this updater is allowed again.
mod:hook(VersusModeState.combat_range_user_behavior, "update_minion_phase", function(func, self, unit, blackboard, dt, t)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.attack_deadline and VersusModeState.gunner_breeds[state.breed.name] then
        -- Hold the commanded shooting/melee range until the native leaf starts.
        return
    end

    if state and state.possessed and CAPTAIN_BREEDS[state.breed.name] then
        return
    end

    return func(self, unit, blackboard, dt, t)
end)

mod:hook(MinionPerceptionExtension, "update", function(func, self, unit, dt, t, ...)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.attack_deadline and state.unit == unit and state.perception == self and VersusModeState.valid_attack_target(state.attack_target, state) then
        if VersusModeState.update_controlled_perception(state, self) then
            return
        end
    end

    return func(self, unit, dt, t, ...)
end)

-- Pack Master summon is a root action with a persistent shared scratchpad.
-- Possession can interrupt an autonomous summon, and vanilla leave() then
-- completes that old summon after the brain has already been paused. Mark each
-- deliberate manual run and reset the leaf-local lifecycle fields so a previous
-- `summoned_success` value cannot turn the next Special command into an empty
-- animation or a permanently running action.
mod:hook(BtSummonMinionsAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_houndmaster = state
        and state.unit == unit
        and breed
        and breed.name == "chaos_ogryn_houndmaster"
    local attack = controlled_houndmaster and state.requested_attack
    local manual_summon = state
        and state.attack_deadline
        and attack
        and attack.summon_hounds == true

    if controlled_houndmaster then
        scratchpad.versus_mode_manual_summon = manual_summon or nil
        scratchpad.versus_mode_blocked_summon = not manual_summon or nil

        if not manual_summon then
            return
        end

        scratchpad.summoned_success = nil
        scratchpad.delay = nil
        scratchpad.pre_stinger = nil
        scratchpad.shout_wwise_event_timing = nil

        local summon_component = blackboard and Blackboard.write_component(blackboard, "summon")

        if summon_component then
            summon_component.amount = 0
            summon_component.next_summon_t = 0
        end
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, t)
end)

mod:hook(BtSummonMinionsAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    if scratchpad.versus_mode_blocked_summon then
        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

-- The native visible-player path searches for a hidden main-path position.
-- Realm arenas and Psykhanium rooms frequently have no such point, so the
-- action reports success without spawning anything. For a deliberate manual
-- command only, use the native close navmesh placement around the Pack Master.
mod:hook(BtSummonMinionsAction, "_summon_minions", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    if not scratchpad.versus_mode_manual_summon then
        return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    end

    local old_should_spawn_in_los = action_data.should_spawn_in_los

    action_data.should_spawn_in_los = true

    local ok, error_message = pcall(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)

    action_data.should_spawn_in_los = old_should_spawn_in_los

    if not ok then
        error(error_message)
    end

    local summoned_extension = scratchpad.summoned_minions_extension
    local tracked_ok, tracked_hounds = summoned_extension and safe_extension_call(summoned_extension, "summoned_minions")
    local tracked_count = tracked_ok and type(tracked_hounds) == "table" and #tracked_hounds or 0

    mod:info(string.format("Manual Pack Master summon completed with %d tracked hound(s).", tracked_count))
end)

-- BtSummonMinionsAction normally completes an unfinished summon from leave().
-- Never do that for a controlled Pack Master: cancellation, a new command,
-- possession start and destructive despawn must not turn an interrupted or
-- inherited summon into an unexpected pack. Completed manual summons have
-- already spawned inside run() and need no leave-side work.
mod:hook(BtSummonMinionsAction, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)

    if breed and breed.name == "chaos_ogryn_houndmaster"
        and (destroy or state and state.unit == unit or scratchpad.versus_mode_blocked_summon) then
        return
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
end)

-- Player-controlled gunners do not need the AI's aim/turn anticipation.
-- Enter shooting through the native action so weapon setup and burst cadence
-- remain intact. The short-lived copy avoids changing ordinary AI templates.
mod:hook(BtShootAction, "_update_aiming", function(func, self, unit, t, scratchpad, action_data, breed)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if not state or state.unit ~= unit or not state.attack_deadline
        or not VersusModeState.gunner_breeds[state.breed.name]
        or not attack or attack.gunner_combat_range ~= "far" then
        return func(self, unit, t, scratchpad, action_data, breed)
    end

    MinionAttack.aim_at_target(unit, scratchpad, t, action_data, breed)
    scratchpad.rotation_duration = nil
    scratchpad.start_rotation_timing = nil
    if scratchpad.is_anim_rotation_driven then
        MinionMovement.set_anim_rotation_driven(scratchpad, false)
    end
    local MinionPerception = require("scripts/utilities/minion_perception")
    MinionPerception.set_target_lock(unit, scratchpad.perception_component, false)
    local immediate_action = table.clone(action_data)
    immediate_action.before_shoot_effect_template_timing = 0
    self:_start_shooting(unit, t, scratchpad, immediate_action)
    state.attack_phase = "FIRING"
end)

-- Ranged actions can hand control to AI strafing while they shoot.
-- Possession already supplies deliberate WASD positioning, so suppress
-- that autonomous transition during an explicit ranged command.
mod:hook(BtShootAction, "_try_start_strafe_shooting", function(func, self, unit, t, scratchpad, action_data, breed)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and (attack.single_shoot_cycle
            or CAPTAIN_BREEDS[state.breed.name] and attack.captain_combat_range == "far") then
        return
    end

    return func(self, unit, t, scratchpad, action_data, breed)
end)

-- BtShootAction normally loops from its cooldown back into aiming and can fire
-- indefinitely while its selector remains active. Casual Primary promises one
-- button press = one attack, so finish the command when Darktide reports the
-- last projectile of the selected shotgun/plasma cycle. Advanced ranged
-- commands and ordinary AI retain the native repeat behavior.
mod:hook(BtShootAction, "_update_shooting", function(func, self, unit, t, scratchpad, action_data, breed)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state and state.unit == unit and state.attack_deadline
        and attack and attack.gunner_combat_range == "far" then
        if state.gunner_shoot_move_event and scratchpad.is_anim_rotation_driven then
            MinionMovement.set_anim_rotation_driven(scratchpad, false)
            state.gunner_shoot_rotation_released = true
        elseif not state.gunner_shoot_move_event and state.gunner_shoot_rotation_released then
            MinionMovement.set_anim_rotation_driven(scratchpad, true)
            state.gunner_shoot_rotation_released = nil
        end
    end

    local fired_last_shot = func(self, unit, t, scratchpad, action_data, breed)

    if state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and attack.casual_command
        and attack.single_shoot_cycle
        and fired_last_shot then
        state.command_action_complete = true
        state.attack_min_until = 0
        state.attack_phase = "FIRED"
    end

    return fired_last_shot
end)

-- Manual Heavy pounces do not run toward the internal proxy target first.
-- Completing the native approach leaf immediately lets the normal leap leaf
-- own its wind-up, airborne collision, dodge, landing and pin state machine.
mod:hook(Specialist.hound_approach_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and (attack.hound_trajectory or attack.hound_instant_pounce)
        and state.hound_manual_pounce_active then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())
    end

    return result
end)

mod:hook(Specialist.hound_approach_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and (attack.hound_trajectory or attack.hound_instant_pounce)
        and state.hound_manual_pounce_active then
        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

-- Use the stationary short-leap wind-up for a manual pounce. Temporarily
-- presenting a short proxy distance lets native enter() choose the matching
-- animation without making the proxy part of the committed trajectory.
mod:hook(BtChaosHoundLeapAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local manual_pounce = state
        and state.unit == unit
        and state.attack_deadline
        and state.requested_attack
        and (state.requested_attack.hound_trajectory or state.requested_attack.hound_instant_pounce)
        and state.hound_manual_pounce_active
        and state.hound_committed_solution
    local perception_component = manual_pounce and blackboard.perception
    local old_target_distance = perception_component and perception_component.target_distance

    if perception_component then
        perception_component.target_distance = 0
    end

    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)

    if perception_component then
        perception_component.target_distance = old_target_distance

        local launch_velocity = state.hound_committed_solution.launch_velocity

        if launch_velocity then
            scratchpad.versus_mode_manual_velocity = Vector3Box(launch_velocity:unbox())
        end
    end

    return result
end)

-- Keep the short wind-up stationary and bypass native target prediction. The
-- remainder of the leap action stays native after _leap() receives the manual
-- velocity, including collision sweeps, dodges, wall reactions and pinning.
mod:hook(BtChaosHoundLeapAction, "_update_starting_state", function(func, self, unit, scratchpad, action_data, dt, t, locomotion_extension, perception_component, target_unit)
    local manual_velocity = scratchpad.versus_mode_manual_velocity

    if not manual_velocity then
        return func(self, unit, scratchpad, action_data, dt, t, locomotion_extension, perception_component, target_unit)
    end

    local launch_velocity = manual_velocity:unbox()
    local flat_direction = Vector3.flat(launch_velocity)

    locomotion_extension:set_wanted_velocity_flat(Vector3.zero())

    if vector3_length(flat_direction) > 0.01 then
        locomotion_extension:set_wanted_rotation(Quaternion.look(vector3_normalize(flat_direction), vector3_up()))
    end

    MinionAttack.push_friendly_minions(unit, scratchpad, action_data, t)
    MinionAttack.push_nearby_enemies(unit, scratchpad, action_data, target_unit)

    if scratchpad.aoe_bot_threat_timing and t >= scratchpad.aoe_bot_threat_timing then
        self:_create_bot_aoe_threats(unit, scratchpad, action_data, target_unit)
        scratchpad.aoe_bot_threat_timing = nil
    end

    if t >= scratchpad.start_duration then
        scratchpad.start_duration = nil
        self:_leap(unit, scratchpad, action_data, POSITION_LOOKUP[unit] + Vector3(0, 0, 0.1), launch_velocity)
    end

    return "running"
end)

-- The behavior tree calculates a conventional target-directed leap only to
-- reach this native transition. Replace that final velocity with the exact
-- host-validated camera arc committed when Heavy was released.
mod:hook(BtChaosHoundLeapAction, "_leap", function(func, self, unit, scratchpad, action_data, start_position, leap_velocity)
    local state = VersusModeState.control_for_unit(unit)
    local solution = state and state.hound_committed_solution
    local launch_velocity = solution and solution.launch_velocity and solution.launch_velocity:unbox()

    if state
        and state.unit == unit
        and state.attack_deadline
        and state.requested_attack
        and (state.requested_attack.hound_trajectory or state.requested_attack.hound_instant_pounce)
        and state.hound_manual_pounce_active
        and launch_velocity
        and vector3_length(launch_velocity) > 0.01 then
        local flat_direction = Vector3.flat(launch_velocity)

        if vector3_length(flat_direction) > 0.01 then
            scratchpad.locomotion_extension:set_wanted_rotation(Quaternion.look(vector3_normalize(flat_direction), vector3_up()))
        end

        state.hound_manual_pounce_started = true
        state.hound_manual_pounce_started_at = gameplay_time()

        return func(self, unit, scratchpad, action_data, start_position, launch_velocity)
    end

    return func(self, unit, scratchpad, action_data, start_position, leap_velocity)
end)

-- Psykhanium/Realm targets can be valid player units without appearing in the
-- Hound side's native ai_ground_target_units lookup. The leap action otherwise
-- sees the physical overlap but deliberately rejects it, so no pounce_target
-- reaches BtChaosHoundTargetPouncedAction and the player is never disabled.
-- Expose every valid survivor for the duration of a manual collision query,
-- preserving all of Darktide's dodge, ladder and overlap checks without
-- privileging the internal behavior-tree proxy.
mod:hook(BtChaosHoundLeapAction, "_check_colliding_players", function(func, self, unit, scratchpad, action_data, ignore_dot_check)
    local state = VersusModeState.control_for_unit(unit)
    local manual_pounce = state
        and state.unit == unit
        and HOUND_BREEDS[state.breed.name]
        and state.attack_deadline
        and state.requested_attack
        and (state.requested_attack.hound_trajectory or state.requested_attack.hound_instant_pounce)
        and state.hound_manual_pounce_active

    if not manual_pounce and (not state
        or state.unit ~= unit
        or not HOUND_BREEDS[state.breed.name]
        or not state.attack_deadline
        or not VersusModeState.valid_attack_target(state.attack_target, state)) then
        return func(self, unit, scratchpad, action_data, ignore_dot_check)
    end

    local side = scratchpad.side_system and scratchpad.side_system.side_by_unit[unit]
    local ground_targets = side and side.ai_ground_target_units

    if not ground_targets then
        return func(self, unit, scratchpad, action_data, manual_pounce and true or ignore_dot_check)
    end

    local added_targets = {}

    if manual_pounce then
        local targets = player_side_targets(state, true)

        for i = 1, #targets do
            local target = targets[i]

            if (target ~= state.player_unit or not state.versus_role)
                and valid_player_target(target)
                and not ground_targets[target] then
                ground_targets[target] = true
                added_targets[#added_targets + 1] = target
            end
        end
    elseif not ground_targets[state.attack_target] then
        ground_targets[state.attack_target] = true
        added_targets[1] = state.attack_target
    end

    local ok, result = pcall(func, self, unit, scratchpad, action_data, manual_pounce and true or ignore_dot_check)

    for i = 1, #added_targets do
        ground_targets[added_targets[i]] = nil
    end

    if not ok then
        error(result)
    end

    return result
end)

-- A Mutant's normal charge node owns the whole grab/smash/throw sequence. Keep
-- that native sequence intact, but allow Special to advance a currently held
-- victim to its own safe throw setup rather than fabricating a player release.
mod:hook(BtMutantChargerChargeAction, "_is_facing_target", function(func, self, unit, scratchpad)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == "mutant" then
        return true
    end

    return func(self, unit, scratchpad)
end)

mod:hook(BtMutantChargerChargeAction, "_update_ray_can_go", function(func, self, unit, scratchpad)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == "mutant" then
        scratchpad.navmesh_ray_can_go = true

        return
    end

    return func(self, unit, scratchpad)
end)

mod:hook(BtMutantChargerChargeAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_mutant = state
        and state.unit == unit
        and MUTANT_BREEDS[state.breed.name]
        and state.attack_deadline
    local carrying = controlled_mutant
        and scratchpad.state == "grabbed_target"
        and ALIVE[scratchpad.grabbed_target]

    if controlled_mutant then
        state.mutant_carrying = carrying == true

        if state.mutant_force_throw and carrying then
            self:_align_throwing(unit, scratchpad, action_data)

            scratchpad.grab_target_duration = nil
            scratchpad.charge_with_target_t = nil

            self:_start_throwing_target(unit, scratchpad, action_data, t)

            state.mutant_force_throw = nil
            state.mutant_carrying = nil
            state.attack_started = true
            state.attack_phase = "THROWING"
        end
    end

    local result = func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)

    if VersusModeState.control_for_unit(unit) == state and controlled_mutant then
        local grabbed_target = scratchpad.state == "grabbed_target" and ALIVE[scratchpad.grabbed_target]
            and scratchpad.grabbed_target
            or nil

        state.mutant_carrying = grabbed_target ~= nil

        -- Native charge speed and collision handling remain authoritative; the
        -- possessed player's yaw replaces only the AI's wanted direction.
        if scratchpad.state == "charging" then
            local forward = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)
            local speed = scratchpad.current_charge_speed
                or vector3_length(scratchpad.locomotion_extension:current_velocity())

            if vector3_length(forward) > 0.01 then
                forward = vector3_normalize(forward)
                scratchpad.locomotion_extension:set_rotation_speed(action_data.rotation_speed)
                scratchpad.locomotion_extension:set_wanted_rotation(Quaternion.look(forward, vector3_up()))

                if speed and speed > 0.01 then
                    local velocity = forward * speed

                    scratchpad.locomotion_extension:set_wanted_velocity(velocity)
                    scratchpad.velocity_stored:store(velocity)
                end
            end

            state.attack_phase = mod:localize("mutant_manual_steer")
        elseif grabbed_target then
            state.attack_phase = "CARRYING"
        elseif scratchpad.state == "throwing" then
            state.attack_phase = "THROWING"
        end

    end

    return result
end)

mod:hook(BtMutantChargerChargeAction, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack
    local direct_charge = state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == "mutant"
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if direct_charge and reason == "done" and VersusModeState.control_for_unit(unit) == state then
        state.direct_attack_complete = true
        state.attack_min_until = 0
    end

    return result
end)

-- When enabled, prefer the direction the controller is facing for both the
-- automatic throw and the Special early throw. Retain the native randomized
-- safe-direction search whenever that exact trajectory is obstructed.
mod:hook(BtMutantChargerChargeAction, "_align_throwing", function(func, self, unit, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_mutant = state
        and state.unit == unit
        and MUTANT_BREEDS[state.breed.name]
        and state.attack_deadline
        and scratchpad.state == "grabbed_target"
        and ALIVE[scratchpad.grabbed_target]

    if controlled_mutant and setting("enable_mutant_throw_direction_adjustment") then
        local direction = Vector3(math_sin(state.yaw), math_cos(state.yaw), 0)

        if vector3_length(direction) > 0.01 then
            direction = vector3_normalize(direction)

            local position_up = POSITION_LOOKUP[unit] + vector3_up() * 1.5
            local position_down = POSITION_LOOKUP[unit] + vector3_up() * 0.5
            local up_test_position = position_up + direction * action_data.throw_test_distance
            local down_test_position = position_down + direction * action_data.throw_test_distance
            local up_hit = self:_ray_cast(scratchpad.physics_world, position_up, up_test_position)
            local down_hit = self:_ray_cast(scratchpad.physics_world, position_down, down_test_position)

            if not up_hit and not down_hit then
                local trajectory_ok, adjusted_direction = self:_test_throw_trajectory(
                    unit,
                    scratchpad,
                    action_data,
                    direction,
                    down_test_position
                )

                if trajectory_ok then
                    scratchpad.throw_rotation = QuaternionBox(Quaternion.look(adjusted_direction or direction))
                    scratchpad.fallback_throw_position = nil
                    state.mutant_throw_direction_applied = true

                    return
                end
            end
        end

        state.mutant_throw_direction_applied = nil
    end

    return func(self, unit, scratchpad, action_data)
end)

-- Camera-directed melee uses a real survivor only as the native behavior-tree
-- proxy. Substitute the committed camera point only while the animation is
-- selected on enter; never replace POSITION_LOOKUP during run(), because the
-- native damage code also reads it for its physical reach test. Live facing is
-- supplied through the rotation hook below, leaving actual collision and range
-- authoritative. Stationary attacks remain planted in both aiming modes.
-- Bulwark's Advancing Strike retains its native forward movement, as does
-- every deliberately mobile Charge.
function VersusModeState.enforce_camera_melee_motion(state, scratchpad)
    if not state or not scratchpad or not state.requested_attack then
        return false
    end

    local navigation = scratchpad.navigation_extension or state.navigation
    local locomotion = scratchpad.locomotion_extension or state.locomotion

    if state.requested_attack.stationary then
        safe_extension_call(navigation, "set_enabled", false)
        safe_extension_call(locomotion, "set_wanted_velocity_flat", Vector3.zero())
        -- Some elite melee variants leave their animation-translation scale
        -- active even after set_anim_driven(false), which presents as a slow
        -- backward slide. Zero both motion sources for attacks explicitly
        -- marked planted, then restore the shared locomotion scale on every
        -- leave/cancel path.
        safe_extension_call(locomotion, "set_anim_translation_scale", Vector3.zero())
        state.camera_melee_translation_suppressed = true

        if scratchpad.is_anim_driven then
            safe_extension_call(locomotion, "use_lerp_rotation", true)
            safe_extension_call(locomotion, "set_anim_driven", false, false, false)
            safe_extension_call(locomotion, "set_anim_rotation_scale", 1)
            scratchpad.is_anim_driven = false
        end
    elseif state.camera_melee_move_destination then
        safe_extension_call(
            navigation,
            "move_to",
            state.camera_melee_move_destination:unbox()
        )
    end

    return true
end

mod:hook(VersusModeState.melee_attack_action, "_rotate_towards_target_unit", function(func, self, unit, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if not Specialist.camera_melee_active(state, unit) then
        return func(self, unit, scratchpad, action_data)
    end

    local direction = Vector3(math_sin(state.command_aim_yaw or state.yaw), math_cos(state.command_aim_yaw or state.yaw), 0)
    local rotation = Quaternion.look(direction, vector3_up())

    if not action_data.dont_rotate_towards_target then
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_rotation", rotation)
    end

    return rotation
end)

mod:hook(VersusModeState.melee_attack_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local camera_melee = Specialist.camera_melee_active(state, unit)
    local stationary_melee = Specialist.stationary_melee_active(state, unit)

    if not camera_melee and not stationary_melee then
        return func(self, unit, breed, blackboard, scratchpad, action_data, t)
    end

    if not camera_melee then
        local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)

        VersusModeState.enforce_camera_melee_motion(state, scratchpad)

        return result
    end

    local target = blackboard.perception and blackboard.perception.target_unit
    local proxy_position = Specialist.camera_proxy_target_position(state, unit, target)
    local old_target_position = target and POSITION_LOOKUP[target]

    if proxy_position and old_target_position then
        POSITION_LOOKUP[target] = proxy_position
    end

    local ok, result = pcall(func, self, unit, breed, blackboard, scratchpad, action_data, t)

    if old_target_position then
        POSITION_LOOKUP[target] = old_target_position
    end

    if not ok then
        error(result)
    end

    local direction = Vector3(math_sin(state.command_aim_yaw or state.yaw), math_cos(state.command_aim_yaw or state.yaw), 0)

    VersusModeState.enforce_camera_melee_motion(state, scratchpad)

    safe_extension_call(scratchpad.locomotion_extension, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))

    return result
end)

mod:hook(VersusModeState.melee_attack_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)
    local camera_melee = Specialist.camera_melee_active(state, unit)
    local stationary_melee = Specialist.stationary_melee_active(state, unit)

    if not camera_melee and not stationary_melee then
        return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    end

    -- Moving melee reads navigation_extension:destination() during run. Put
    -- the committed camera-forward point back before native movement samples
    -- it, then enforce planted/root-motion policy again after native updates.
    VersusModeState.enforce_camera_melee_motion(state, scratchpad)

    local result, evaluate_utility_next_frame, update_rate = func(
        self,
        unit,
        breed,
        blackboard,
        scratchpad,
        action_data,
        dt,
        t
    )

    VersusModeState.enforce_camera_melee_motion(state, scratchpad)

    if camera_melee then
        local direction = Vector3(math_sin(state.command_aim_yaw or state.yaw), math_cos(state.command_aim_yaw or state.yaw), 0)

        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))
    end

    return result, evaluate_utility_next_frame, update_rate
end)

mod:hook(VersusModeState.melee_attack_action, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local direct_melee = Specialist.camera_melee_active(state, unit)
        or Specialist.stationary_melee_active(state, unit)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if direct_melee and reason == "done" and VersusModeState.control_for_unit(unit) == state then
        state.direct_attack_complete = true
        state.attack_min_until = 0
    end

    if direct_melee and VersusModeState.control_for_unit(unit) == state then
        if state.requested_attack and state.requested_attack.stationary then
            safe_extension_call(scratchpad.navigation_extension or state.navigation, "set_enabled", false)
            safe_extension_call(scratchpad.locomotion_extension or state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
        end

        if state.camera_melee_translation_suppressed then
            safe_extension_call(
                scratchpad.locomotion_extension or state.locomotion,
                "set_anim_translation_scale",
                Vector3(1, 1, 1)
            )
            state.camera_melee_translation_suppressed = nil
        end

        state.camera_melee_move_destination = nil
    end

    return result
end)

-- Free-aim Flame Stream and Gunner volleys use the camera point for native
-- aiming. The survivor remains the native replication and damage proxy.
mod:hook(MinionAttack, "get_aim_position", function(func, unit, scratchpad, optional_line_of_sight_id, optional_aim_node_name)
    local state = VersusModeState.control_for_unit(unit)
    local flamer_aim_position = Specialist.direct_attack_active(state, unit, "flamer")
        and Specialist.flamer_aim_position(state)

    if flamer_aim_position then
        -- Cultist Flamer aiming normally prefers the live target's aim node
        -- whenever perception reports line of sight. The survivor remains the
        -- native replication/damage proxy, but never supplies aim in free aim.
        return flamer_aim_position
    end

    local gunner_aim_position = state
        and state.unit == unit
        and VersusModeState.gunner_breeds[state.breed.name]
        and state.attack_deadline
        and state.requested_attack
        and state.requested_attack.camera_directed
        and state.requested_attack.gunner_combat_range == "far"
        and Specialist.free_aim(state)
        and camera_aim_ray(state)

    if gunner_aim_position then
        return gunner_aim_position
    end

    return func(unit, scratchpad, optional_line_of_sight_id, optional_aim_node_name)
end)

mod:hook(VersusModeState.flamer_approach_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if Specialist.direct_attack_active(state, unit, "flamer") then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())
    end

    return result
end)

mod:hook(VersusModeState.flamer_approach_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)

    if Specialist.direct_attack_active(state, unit, "flamer") then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

mod:hook(VersusModeState.shoot_liquid_beam_action, "_try_start_strafe_shooting", function(func, self, unit, t, scratchpad, action_data, breed)
    local state = VersusModeState.control_for_unit(unit)

    if Specialist.direct_attack_active(state, unit, "flamer") then
        return
    end

    return func(self, unit, t, scratchpad, action_data, breed)
end)

mod:hook(VersusModeState.shoot_liquid_beam_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if Specialist.direct_attack_active(state, unit, "flamer") then
        scratchpad.perception_component.lock_target = false
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())
    end

    return result
end)

mod:hook(VersusModeState.shoot_liquid_beam_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)

    if not Specialist.direct_attack_active(state, unit, "flamer") then
        return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    end

    Specialist.flamer_shot_positions(state, unit, action_data)

    local target = scratchpad.perception_component and scratchpad.perception_component.target_unit
    local aim_position = Specialist.flamer_aim_position(state)
    local old_target_position = target and POSITION_LOOKUP[target]

    if not target or not aim_position or not old_target_position then
        -- A one-frame camera/proxy lookup gap must not fall through to native
        -- survivor-node aiming or finish the leaf. The command-level hard
        -- deadline remains authoritative if valid data never returns.
        state.attack_phase = state.flamer_stream_started_at and "FIRING" or "IGNITING"

        return "running"
    end

    POSITION_LOOKUP[target] = aim_position
    safe_extension_call(scratchpad.perception_extension, "set_last_los_position", target, aim_position)
    scratchpad.perception_component.has_line_of_sight = true
    scratchpad.perception_component.lock_target = false
    safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
    safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

    -- The native liquid beam freezes its starting endpoint when the stream
    -- begins and only follows the proxy target with the far endpoint. Refresh
    -- both endpoints from the current camera ray before every native update so
    -- Scab and Dreg streams stay aligned throughout the complete attack.
    local from_ok, live_shot_from, distance_to_from = pcall(self._get_from_shoot_pos, self, unit, scratchpad, action_data)
    local to_ok, live_shot_to = pcall(self._get_to_shoot_pos, self, unit, scratchpad, action_data)

    if from_ok and live_shot_from then
        state.flamer_shot_from = state.flamer_shot_from or Vector3Box(live_shot_from)
        state.flamer_shot_from:store(live_shot_from)

        if scratchpad.from_shot_position then
            scratchpad.from_shot_position:store(live_shot_from)
        end

        if type(distance_to_from) == "number" then
            scratchpad.distance_to_from = distance_to_from
        end
    end

    if to_ok and live_shot_to then
        state.flamer_shot_to = state.flamer_shot_to or Vector3Box(live_shot_to)
        state.flamer_shot_to:store(live_shot_to)

        if scratchpad.to_shot_position then
            scratchpad.to_shot_position:store(live_shot_to)
        end
    end

    local ok, result = pcall(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)

    POSITION_LOOKUP[target] = old_target_position

    if not ok then
        error(result)
    end

    if aim_position and scratchpad.aim_component then
        scratchpad.aim_component.controlled_aiming = true
        scratchpad.aim_component.controlled_aim_position:store(aim_position)
    end

    scratchpad.perception_component.lock_target = false

    if scratchpad.shoot_state == "shooting" or scratchpad.shooting_liquid_beam then
        state.flamer_stream_started_at = state.flamer_stream_started_at or t
        state.attack_started = true
    end

    if result == "done" and state.flamer_stream_started_at then
        local expected_duration = (action_data.attack_duration or 0)
            + (action_data.attack_finished_grace_period or 0)
        local expected_end = state.flamer_stream_started_at + expected_duration

        if t < expected_end - 0.05 then
            if not state.flamer_early_done_logged then
                state.flamer_early_done_logged = true
                mod:warning(
                    "Versus Mode: suppressed premature %s Flame Stream completion %.2f s after ignition.",
                    tostring(state.breed.name),
                    t - state.flamer_stream_started_at
                )
            end

            result = "running"
        end
    end

    state.attack_phase = result == "running"
        and (state.flamer_stream_started_at and "FIRING" or "IGNITING")
        or "COMPLETE"

    return result
end)

mod:hook(VersusModeState.shoot_liquid_beam_action, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local direct_stream = Specialist.direct_attack_active(state, unit, "flamer")
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if direct_stream and VersusModeState.control_for_unit(unit) == state then
        state.flamer_shot_from = nil
        state.flamer_shot_to = nil
    end

    if direct_stream and reason == "done" and VersusModeState.control_for_unit(unit) == state then
        if state.flamer_stream_started_at then
            state.direct_attack_complete = true
            state.attack_min_until = 0
        elseif not state.flamer_retry_logged then
            state.flamer_retry_logged = true
            mod:warning(
                "Versus Mode: %s Flame Stream leaf ended before ignition; retrying within the command window.",
                tostring(state.breed.name)
            )
        end
    end

    return result
end)

mod:hook(BtPoxwalkerBomberApproachAction, "_update_move_to", function(func, self, t, scratchpad, action_data, target_unit)
    local navigation = scratchpad.navigation_extension
    local state = navigation and VersusModeState.control_for_unit(navigation._unit)

    if Specialist.direct_attack_active(state, state and state.unit, "poxburster") then
        -- Native run still handles pushing, fuse and death. It must not path
        -- toward the proxy survivor required by the native perception API.
        return
    end

    return func(self, t, scratchpad, action_data, target_unit)
end)

mod:hook(BtPoxwalkerBomberApproachAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == "poxburster" then
        local yaw = state.command_aim_yaw or state.yaw
        local direction = Vector3(math_sin(yaw), math_cos(yaw), 0)

        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))
        scratchpad.versus_mode_lunge_yaw = yaw
        scratchpad.behavior_component.move_state = "attacking"
        self:_start_lunge(unit, blackboard, scratchpad, action_data, scratchpad.perception_component.target_unit, t)
        scratchpad.versus_mode_direct_lunge = true
        state.poxburster_armed = true
        state.attack_started = true
        state.attack_phase = "FUSE ARMED"
        mod:info("Versus Mode: Pox Burster aimed lunge committed yaw=%.3f, movement=%.3f s, fuse=%.3f s.",
            yaw, action_data.move_during_lunge_duration, action_data.fuse_timer)
    end

    return result
end)

mod:hook(BtPoxwalkerBomberApproachAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack
    local direct_lunge = state
        and state.unit == unit
        and state.attack_deadline
        and Specialist.free_aim(state)
        and attack
        and attack.direct_native == "poxburster"

    if direct_lunge then
        local yaw = scratchpad.versus_mode_lunge_yaw or state.command_aim_yaw or state.yaw
        local direction = Vector3(math_sin(yaw), math_cos(yaw), 0)

        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_rotation", Quaternion.look(direction, vector3_up()))

        if not scratchpad.versus_mode_direct_lunge then
            scratchpad.behavior_component.move_state = "attacking"
            scratchpad.versus_mode_lunge_yaw = yaw
            self:_start_lunge(unit, blackboard, scratchpad, action_data, scratchpad.perception_component.target_unit, t)
            scratchpad.versus_mode_direct_lunge = true
        end

    end

    local result = func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)

    if direct_lunge and HEALTH_ALIVE[unit] and result == "running" then
        local yaw = scratchpad.versus_mode_lunge_yaw
        local speed = 0

        if dt > 0 and t < (scratchpad.move_during_lunge_duration or 0) then
            speed = VersusModeState.minion_movement.get_animation_wanted_movement_speed(unit, dt)
        end

        -- Use the native animation's speed with the same collision-aware
        -- locomotion used by controlled walking, but never AI target steering.
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat",
            Vector3(math_sin(yaw), math_cos(yaw), 0) * speed)
    end

    if state
        and state.unit == unit
        and state.breed.name == POXBURSTER_BREED_NAME
        and state.attack_deadline then
        local death_component = blackboard and blackboard.death
        local fuse_timer = death_component and death_component.fuse_timer or 0

        if scratchpad.state == "lunging" or fuse_timer > 0 then
            state.poxburster_armed = true
            state.attack_started = true
            state.attack_phase = "FUSE ARMED"
        end
    end

    return result
end)

local function update_controlled_sniper_aim(self, state, unit, scratchpad, action_data)
    local camera_aim_position, hit_unit, camera_distance = camera_aim_ray(state)

    if not camera_aim_position then
        return false
    end

    if VersusModeState.valid_attack_target(hit_unit, state) then
        state.attack_target = hit_unit

        if state.perception and state.perception_component and state.perception_component.target_unit ~= hit_unit then
            safe_extension_call(state.perception, "_set_target_unit", hit_unit)
        end
    end

    local laser_aim_position = camera_aim_position
    local attachment_ok, attachment_unit, node = pcall(
        MinionVisualLoadout.attachment_unit_and_node_from_node_name,
        scratchpad.weapon_item,
        action_data.fx_source_name
    )

    if attachment_ok and attachment_unit and node then
        local position_ok, muzzle_position = pcall(Unit.world_position, attachment_unit, node)

        if position_ok and muzzle_position then
            local _, ray_position = self:_ray_cast(scratchpad, muzzle_position, camera_aim_position, action_data.max_distance or SNIPER_AIM_DISTANCE)

            laser_aim_position = ray_position or camera_aim_position
        end
    end

    local network_min, network_max = NetworkConstants.min_position, NetworkConstants.max_position

    laser_aim_position[1] = math.clamp(laser_aim_position[1], network_min, network_max)
    laser_aim_position[2] = math.clamp(laser_aim_position[2], network_min, network_max)
    laser_aim_position[3] = math.clamp(laser_aim_position[3], network_min, network_max)

    scratchpad.current_aim_position:store(laser_aim_position)
    scratchpad.aim_component.controlled_aiming = true
    scratchpad.aim_component.controlled_aim_position:store(laser_aim_position)

    local spawn_component = scratchpad.spawn_component

    if spawn_component and spawn_component.game_session and spawn_component.game_object_id then
        GameSession.set_game_object_field(spawn_component.game_session, spawn_component.game_object_id, "laser_aim_position", laser_aim_position)
    end

    if state.perception_component then
        state.perception_component.has_line_of_sight = true
        state.perception_component.target_distance = camera_distance or state.perception_component.target_distance
    end

    local _, flat_forward = state_look_direction(state)

    if scratchpad.locomotion_extension then
        scratchpad.locomotion_extension:set_wanted_velocity_flat(Vector3.zero())
        scratchpad.locomotion_extension:set_wanted_rotation(Quaternion.look(flat_forward, vector3_up()))
    end

    state.manual_aim_position = laser_aim_position
    state.manual_aim_hit_unit = hit_unit
    state.manual_aim_distance = camera_distance

    return true
end

mod:hook(BtSniperShootAction, "_calculate_aim_animation_type", function(func, self, unit, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.unit == unit and state.breed.name == SNIPER_BREED_NAME then
        return "standing"
    end

    return func(self, unit, scratchpad, action_data)
end)

mod:hook(BtSniperShootAction, "_aim", function(func, self, unit, t, dt, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.unit == unit and state.breed.name == SNIPER_BREED_NAME and state.attack_deadline then
        if update_controlled_sniper_aim(self, state, unit, scratchpad, action_data) then
            return true, true
        end
    end

    return func(self, unit, t, dt, scratchpad, action_data)
end)

mod:hook(BtSniperShootAction, "_update_aiming", function(func, self, unit, t, dt, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state
        and state.unit == unit
        and state.breed.name == SNIPER_BREED_NAME
        and state.attack_deadline
        and attack
        and attack.laser_only then
        if update_controlled_sniper_aim(self, state, unit, scratchpad, action_data) then
            scratchpad.shoot_state = "aiming"
            scratchpad.target_is_in_sight_duration = 0
            scratchpad.scope_reflection_timing = nil
            scratchpad.shoot_at_t = nil
            scratchpad.next_threat_timing = nil

            local spawn_component = scratchpad.spawn_component

            if spawn_component and spawn_component.game_session and spawn_component.game_object_id then
                pcall(GameSession.set_game_object_field, spawn_component.game_session, spawn_component.game_object_id, "in_sight_duration", 0)
            end

            state.attack_phase = "LASER AIMING"

            return
        end
    end

    if state and state.unit == unit and state.breed.name == SNIPER_BREED_NAME
        and state.attack_deadline and attack and not attack.laser_only
        and update_controlled_sniper_aim(self, state, unit, scratchpad, action_data) then
        scratchpad.shoot_at_t = nil
        scratchpad.next_threat_timing = nil
        scratchpad.scope_reflection_timing = nil
        self:_start_shooting(unit, t, scratchpad, action_data)
        return
    end

    return func(self, unit, t, dt, scratchpad, action_data)
end)

mod:hook(BtSniperShootAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.unit == unit and state.breed.name == SNIPER_BREED_NAME then
        if state.navigation and state.navigation:enabled() then
            state.navigation:set_enabled(false)
        end

        if state.locomotion then
            state.locomotion:set_wanted_velocity_flat(Vector3.zero())
        end

        state.attack_phase = "AIMING"
    end

    return result
end)

-- Netgunner aiming is normally hard-wired to its perception target. During
-- possession, keep the native wind-up, projectile sweep and drag logic, but
-- feed its aim box from the possession camera ray.
--
-- The generated tree normally places an approach action before shoot_net.
-- The selector override should skip it, but the tree can retain/re-enter the
-- previous running child for one evaluation frame. Intercept the action too,
-- so a manually commanded Netter can never translate toward its proxy target.
mod:hook(BtRenegadeNetgunnerApproachAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and state.breed.name == NETTER_BREED_NAME
        and state.requested_attack
        and state.requested_attack.action_name == "shoot_net"
        and state.attack_deadline then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

        if not state.netter_approach_bypass_logged then
            state.netter_approach_bypass_logged = true
            mod:info("Bypassing Netter approach action for commanded free-aim shot.")
        end
    end

    return result
end)

mod:hook(BtRenegadeNetgunnerApproachAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and state.breed.name == NETTER_BREED_NAME
        and state.requested_attack
        and state.requested_attack.action_name == "shoot_net"
        and state.attack_deadline then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

mod:hook(BtShootNetAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.unit == unit and state.breed.name == NETTER_BREED_NAME and state.requested_attack and state.requested_attack.action_name == "shoot_net" then
        -- The native difficulty table can request a burst of multiple nets.
        -- Direct control treats one Primary press as exactly one projectile.
        scratchpad.num_shots = 1
        state.net_shot_complete = nil
        safe_extension_call(state.navigation, "set_enabled", false)
        safe_extension_call(state.locomotion, "set_wanted_velocity_flat", Vector3.zero())
    end

    return result
end)

mod:hook(BtShootNetAction, "_update_aiming", function(func, self, unit, t, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if not state or state.breed.name ~= NETTER_BREED_NAME or state.unit ~= unit or not state.attack_deadline then
        return func(self, unit, t, scratchpad, action_data)
    end

    local aim_position, hit_unit, distance = camera_aim_ray(state)

    if not aim_position then
        return func(self, unit, t, scratchpad, action_data)
    end

    state.manual_aim_position = aim_position
    state.manual_aim_hit_unit = hit_unit
    state.manual_aim_distance = distance

    local _, flat_forward = state_look_direction(state)

    scratchpad.locomotion_extension:set_wanted_rotation(Quaternion.look(flat_forward, vector3_up()))
    scratchpad.current_aim_position:store(aim_position)
    state.attack_phase = "AIMING NET"

    -- The camera aim is already prepared; skip the AI's net wind-up timer.
    self:_start_shooting(unit, scratchpad, action_data)
    state.attack_phase = "FIRED"
end)

mod:hook(BtShootNetAction, "_start_shooting", function(func, self, unit, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if not state
        or state.unit ~= unit
        or state.variant_id ~= "sniper_netter"
        or not state.requested_attack
        or state.requested_attack.action_name ~= "shoot_net" then
        return func(self, unit, scratchpad, action_data)
    end

    local variant_action_data = table.clone(action_data)

    variant_action_data.max_net_distance = state.requested_attack.manual_range_max or 28

    local result = func(self, unit, scratchpad, variant_action_data)

    state.netter_fire_cooldown_until = gameplay_time() + (state.requested_attack.cooldown_duration or 5)
    mod:info("Versus Mode: Sniper Netter fired; 28 m sweep and 5.0 s cooldown applied.")

    return result
end)

mod:hook(BtShootNetAction, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_shot = state
        and state.unit == unit
        and state.breed.name == NETTER_BREED_NAME
        and state.requested_attack
        and state.requested_attack.action_name == "shoot_net"
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if controlled_shot and VersusModeState.control_for_unit(unit) == state then
        state.net_shot_complete = true
        state.attack_min_until = 0
        state.attack_phase = "FIRED"
    end

    return result
end)

-- As with the Netter approach guard, this catches a far-combat follow child
-- retained from the frame before a direct-control command. The committed
-- solution is already authoritative, so no controlled Grenadier may navigate
-- to an AI-selected throwing position in either lock or free-aim mode.
mod:hook(BtGrenadierFollowAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far"
        and state.attack_deadline then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

        if not state.grenadier_follow_bypass_logged then
            state.grenadier_follow_bypass_logged = true
            mod:info("Bypassing Grenadier follow action for commanded stationary throw.")
        end
    end

    return result
end)

mod:hook(BtGrenadierFollowAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far"
        and state.attack_deadline then
        safe_extension_call(scratchpad.navigation_extension, "set_enabled", false)
        safe_extension_call(scratchpad.locomotion_extension, "set_wanted_velocity_flat", Vector3.zero())

        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

-- A retained native follow child can return "done" and advance its sequence
-- directly into BtGrenadierThrowAction during the same behavior-tree update.
-- That transition does not necessarily pass through our forced selector again,
-- leaving the component's initialization value (an empty string) in place.
-- Recommit at the final action boundary and never pass an empty animation event
-- into Stingray, which treats it as event ID 00000000 and terminates the game.
mod:hook(BtGrenadierThrowAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_stationary_throw = state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far"

    if controlled_stationary_throw then
        commit_grenade_solution(state, blackboard)

        local throw_grenade_component = blackboard and blackboard.throw_grenade
        local anim_event = throw_grenade_component and throw_grenade_component.anim_event
        local valid_anim_event = type(anim_event) == "string"
            and anim_event ~= ""
            and action_data.throw_timings
            and action_data.throw_timings[anim_event] ~= nil
            and action_data.action_durations
            and action_data.action_durations[anim_event] ~= nil

        if not valid_anim_event then
            -- The committed solution normally supplies this. If another hook or
            -- a retained tree node cleared it, recover from the breed's native
            -- throw events while still validating the timing tables expected by
            -- BtGrenadierThrowAction._start_aiming.
            local breed_actions = BreedActions[state.breed.name]
            local follow_data = breed_actions and breed_actions.follow
            local throw_anim_events = follow_data and follow_data.throw_anim_events
            local fallback_groups = {
                "long",
                "medium",
                "close",
            }

            for i = 1, #fallback_groups do
                local events = throw_anim_events and throw_anim_events[fallback_groups[i]]
                local candidate = events and events[1]

                if type(candidate) == "string"
                    and candidate ~= ""
                    and action_data.throw_timings
                    and action_data.throw_timings[candidate] ~= nil
                    and action_data.action_durations
                    and action_data.action_durations[candidate] ~= nil then
                    anim_event = candidate
                    valid_anim_event = true

                    if throw_grenade_component then
                        throw_grenade_component.anim_event = candidate
                    end

                    if state.grenade_committed_solution then
                        state.grenade_committed_solution.anim_event = candidate
                    end

                    mod:warning("Recovered a missing controlled Grenadier throw animation with native event '%s'.", candidate)

                    break
                end
            end
        end

        if not valid_anim_event then
            -- Complete this behavior leaf without entering the native action.
            -- Its run method will return done immediately, and the initialized
            -- perception field keeps the corresponding leave path safe.
            scratchpad.throw_timing = nil
            scratchpad.start_drop_grenade_timing = nil
            scratchpad.action_duration = t
            scratchpad.perception_component = blackboard and blackboard.perception
            scratchpad.locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
            state.grenade_throw_complete = true
            state.attack_min_until = 0
            state.attack_phase = "INVALID THROW ANIMATION"
            state.grenade_committed_solution = nil

            mod:error("Cancelled a controlled Grenadier throw because no valid native animation event was available.")

            return
        end
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, t)
end)

mod:hook(BtGrenadierThrowAction, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local controlled_stationary_throw = state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far"
    local pending_throw = controlled_stationary_throw
        and scratchpad.throw_timing ~= nil
        and not state.grenade_projectile_spawned

    if pending_throw then
        -- Native interruption drops a second projectile from the hand once
        -- start_drop_grenade_timing has elapsed. That fallback conflicts with
        -- our committed launch when damage/stagger exits the action.
        -- Treat interruption as a clean cancellation instead.
        scratchpad.start_drop_grenade_timing = nil
    end

    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if controlled_stationary_throw and VersusModeState.control_for_unit(unit) == state then
        state.grenade_throw_complete = true
        state.attack_min_until = 0
        state.attack_phase = state.grenade_projectile_spawned and "THROWN" or "INTERRUPTED"
        state.grenade_committed_solution = nil
    end

    return result
end)

mod:hook(BtGrenadierThrowAction, "_update_grenade_throwing", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far" then
        -- Keep both the facing rotation and launch data pinned to the
        -- committed stationary solution throughout the wind-up animation.
        commit_grenade_solution(state, blackboard)
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, t)
end)

mod:hook(BtGrenadierThrowAction, "_throw_grenade", function(func, self, unit, breed, scratchpad, action_data, throw_type, throw_position, throw_direction, blackboard, t, optional_owner_velocity)
    local state = VersusModeState.control_for_unit(unit)
    local solution = state and state.grenade_committed_solution
    local controlled_stationary_throw = state
        and state.unit == unit
        and GRENADIER_BREEDS[state.breed.name]
        and state.requested_attack
        and state.requested_attack.grenadier_path == "far"

    if controlled_stationary_throw
        and throw_type == "throw"
        and solution
        and solution.valid then
        -- Reassert the committed stationary solution at the final native
        -- spawn boundary. This prevents target/perception updates and other
        -- action hooks from changing the solved projectile direction.
        throw_position = solution.throw_position:unbox()
        throw_direction = solution.throw_direction:unbox()
        optional_owner_velocity = nil
    end

    local result = func(self, unit, breed, scratchpad, action_data, throw_type, throw_position, throw_direction, blackboard, t, optional_owner_velocity)

    if controlled_stationary_throw and throw_type == "throw" and VersusModeState.control_for_unit(unit) == state then
        state.grenade_projectile_spawned = true
        state.attack_phase = "THROWN"
    end

    return result
end)

mod:hook(MinionAttack, "shoot", function(func, unit, scratchpad, action_data)
    local state = VersusModeState.control_for_unit(unit)

    if state
        and state.unit == unit
        and state.breed.name == SNIPER_BREED_NAME
        and state.requested_attack
        and state.requested_attack.laser_only then
        return
    end

    local result = func(unit, scratchpad, action_data)

    if state
        and state.unit == unit
        and state.breed.name == SNIPER_BREED_NAME
        and state.requested_attack
        and state.requested_attack.action_name == "shoot" then
        local t = gameplay_time()

        state.sniper_shot_fired = true
        state.sniper_shot_stop_t = t + 0.1
        state.sniper_fire_cooldown_until = t + SNIPER_FIRE_COOLDOWN
        state.attack_phase = "FIRED"
    end

    return result
end)

mod:hook(Utility, "get_action_utility", function(func, action, blackboard, t, utility_data)
    local state = VersusModeState.control_for_blackboard(blackboard)
    local requested = state and state.requested_attack

    if not state or not state.attack_deadline or state.blackboard ~= blackboard or state.breed.name == "chaos_beast_of_nurgle" or not requested or not requested.action_name then
        return func(action, blackboard, t, utility_data)
    end

    local score = func(action, blackboard, t, utility_data)

    if action.name == requested.action_name then
        if score > 0 then
            state.attack_phase = "SELECTING"

            return score + 1000000
        end

        return 0
    end

    if action.name == "follow" or action.name == "erratic_follow" then
        if score > 0 then
            state.attack_phase = "APPROACHING"
        end

        return score
    end

    return 0
end)

-- The ordinary Captain root selectors are generated code: their stim test is
-- inlined instead of calling BtConditions.minion_can_use_special_action. Hide
-- only can_use_stim for the duration of a commanded evaluation so that branch
-- cannot preempt a draw, bounded approach, or strike; restore the component
-- immediately, including when the native selector raises an error.
for i = 1, #VersusModeState.captain_root_selectors do
    local captain_selector = VersusModeState.captain_root_selectors[i]

    mod:hook(captain_selector, "evaluate", function(func, self, unit, blackboard, ...)
        local state = VersusModeState.control_for_unit(unit)
        local requested = state and state.requested_attack
        local stim_component = blackboard and blackboard.stim
        local suppress_stim = state
            and state.unit == unit
            and state.breed
            and CAPTAIN_BREEDS[state.breed.name]
            and state.attack_deadline
            and requested
            and stim_component ~= nil
        local original_can_use_stim

        if suppress_stim then
            original_can_use_stim = stim_component.can_use_stim
            stim_component.can_use_stim = false
        end

        local ok, result = pcall(func, self, unit, blackboard, ...)

        if suppress_stim then
            stim_component.can_use_stim = original_can_use_stim
        end

        if not ok then
            error(result)
        end

        return result
    end)
end

-- A controlled Scab or Dreg in cover still needs its combat selector for
-- a deliberate gunfire or melee command. Restore cover after evaluation.
for i = 1, #VersusModeState.gunner_root_selectors do
    local gunner_selector = VersusModeState.gunner_root_selectors[i]

    mod:hook(gunner_selector, "evaluate", function(func, self, unit, blackboard, ...)
        local state = VersusModeState.control_for_unit(unit)
        local cover = blackboard and blackboard.cover

        if not (state and state.unit == unit and state.attack_deadline and cover) then
            return func(self, unit, blackboard, ...)
        end

        local had_cover = cover.has_cover
        cover.has_cover = false
        local ok, result = pcall(func, self, unit, blackboard, ...)
        cover.has_cover = had_cover

        if not ok then
            error(result)
        end

        return result
    end)
end

mod:hook(BtConditions, "can_shoot_net", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
    local state = VersusModeState.control_for_unit(unit)

    if state and state.unit == unit and state.breed.name == NETTER_BREED_NAME and state.attack_deadline and state.requested_attack and state.requested_attack.action_name == "shoot_net" then
        return true
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
end)

mod:hook(BtConditions, "minion_can_use_special_action", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
    local state = VersusModeState.control_for_unit(unit)
    local requested = state and state.requested_attack

    -- A ready Captain or Gunner stim selector sits above combat and can
    -- consume a player command. Defer it for the short command window.
    if state
        and state.unit == unit
        and (CAPTAIN_BREEDS[state.breed.name] or VersusModeState.gunner_breeds[state.breed.name])
        and state.attack_deadline
        and requested then
        return false
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
end)

mod:hook(BtConditions, "captain_can_use_special_actions", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
    local state = VersusModeState.control_for_unit(unit)
    local requested = state and state.requested_attack

    -- The specials utility selector is ordered before every Captain weapon
    -- selector. While Adaptive is waiting for a draw or an in-range ordinary
    -- strike, an autonomous kick/charge/shield action must not steal the tree.
    -- An explicit Charge command names this selector and remains allowed.
    if state
        and state.unit == unit
        and CAPTAIN_BREEDS[state.breed.name]
        and state.attack_deadline
        and requested
        and requested.selector_name ~= "renegade_captain_specials" then
        return false
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
end)

mod:hook(BtConditions, "chaos_spawn_should_leap", function(func, unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
    local state = VersusModeState.control_for_unit(unit)
    local requested = state and state.requested_attack

    -- Leap sits above the Spawn's melee utility selector. A Casual Primary
    -- deliberately excludes it, and an explicit Claw/Combo command must not
    -- be replaced by a coincidentally ready autonomous leap.
    if state
        and state.unit == unit
        and state.attack_deadline
        and requested
        and requested.action_name ~= "leap" then
        return false
    end

    return func(unit, blackboard, scratchpad, condition_args, action_data, is_running, dt)
end)

mod:hook(BtRandomUtilityNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state and state.attack_deadline then
        handled, leaf_node = evaluate_forced_twin_grenade(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)

        if not handled then
            handled, leaf_node = Specialist.evaluate_casual_utility_attack(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end

        if not handled then
            handled, leaf_node = evaluate_forced_utility_attack(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

mod:hook(BtRenegadeSniperSelectorNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state and state.attack_deadline then
        handled, leaf_node = evaluate_forced_sniper_shot(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

mod:hook(BtRenegadeNetgunnerSelectorNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state and state.attack_deadline then
        handled, leaf_node = evaluate_forced_netter_shot(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

local function hook_grenadier_selector(selector_class)
    mod:hook(selector_class, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        local state = VersusModeState.control_for_unit(unit)
        local handled, leaf_node

        if state and state.attack_deadline then
            handled, leaf_node = evaluate_forced_grenadier_attack(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end

        if handled then
            return leaf_node
        end

        return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end)
end

hook_grenadier_selector(BtRenegadeGrenadierSelectorNode)
hook_grenadier_selector(BtCultistGrenadierSelectorNode)

function Specialist.install_direct_selector_hooks()
    for i = 1, #VersusModeState.direct_specialist_selectors do
        local selector_class = VersusModeState.direct_specialist_selectors[i]

        mod:hook(selector_class, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
            local state = VersusModeState.control_for_unit(unit)
            local handled, leaf_node

            if state and state.attack_deadline then
                handled, leaf_node = Specialist.evaluate_forced_direct_attack(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
            end

            if handled then
                return leaf_node
            end

            return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
        end)
    end
end

Specialist.install_direct_selector_hooks()

-- Normal Daemonhosts leave after their first player kill. Possession pauses
-- the selector that normally makes this transition, so mark the native
-- death-leave child explicitly before releasing control. The weak marker
-- disappears with the unit and never affects ritual Daemonhosts.
mod:hook(VersusModeState.daemonhost_selector, "evaluate", function(
    func,
    self,
    unit,
    blackboard,
    scratchpad,
    dt,
    t,
    evaluate_utility,
    node_data,
    old_running_child_nodes,
    new_running_child_nodes,
    last_leaf_node_running
)
    local force_leave = mod._daemonhost_forced_leave and mod._daemonhost_forced_leave[unit]
    local leave_node = force_leave and self._selector_children and self._selector_children[1]

    if leave_node then
        new_running_child_nodes[self.identifier] = leave_node

        return leave_node
    end

    return func(
        self,
        unit,
        blackboard,
        scratchpad,
        dt,
        t,
        evaluate_utility,
        node_data,
        old_running_child_nodes,
        new_running_child_nodes,
        last_leaf_node_running
    )
end)

-- Ritual Daemonhosts are encounter objectives rather than one-victim hazards.
-- Hide only their player-death counter while the native selector evaluates;
-- the real value is restored immediately and the ordinary death child remains
-- fully native, so they stay until killed without changing combat behavior.
mod:hook(VersusModeState.mutator_daemonhost_selector, "evaluate", function(
    func,
    self,
    unit,
    blackboard,
    scratchpad,
    dt,
    t,
    evaluate_utility,
    node_data,
    old_running_child_nodes,
    new_running_child_nodes,
    last_leaf_node_running
)
    local statistics = blackboard and blackboard.statistics
    local player_deaths = statistics and statistics.player_deaths

    if type(player_deaths) ~= "number" or player_deaths <= 0 then
        return func(
            self,
            unit,
            blackboard,
            scratchpad,
            dt,
            t,
            evaluate_utility,
            node_data,
            old_running_child_nodes,
            new_running_child_nodes,
            last_leaf_node_running
        )
    end

    statistics.player_deaths = 0

    local ok, result = pcall(
        func,
        self,
        unit,
        blackboard,
        scratchpad,
        dt,
        t,
        evaluate_utility,
        node_data,
        old_running_child_nodes,
        new_running_child_nodes,
        last_leaf_node_running
    )

    statistics.player_deaths = player_deaths

    if not ok then
        error(result)
    end

    return result
end)

mod:hook(BtChaosSpawnSelectorNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state and state.attack_deadline then
        handled, leaf_node = evaluate_forced_spawn_leap(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

-- A selector entry only proves that the wind-up animation began. Track the
-- native leap action's own trajectory calculation and physical launch so the
-- log and HUD can distinguish those stages precisely.
mod:hook(VersusModeState.chaos_spawn_leap_action, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state and state.unit == unit and state.attack_deadline and attack and attack.action_name == "leap" then
        scratchpad.versus_mode_spawn_leap_state = state
        state.spawn_leap_native_state = scratchpad.state or "starting_movement"
        state.attack_phase = mod:localize("spawn_leap_windup")
        local motion_isolated = Specialist.suspend_controlled_spawn_leap_navigation(state, scratchpad)

        if not motion_isolated then
            mod:warning("Versus Mode: Chaos Spawn Leap could not isolate its native locomotion speed.")
        end

        mod:info("Versus Mode: Chaos Spawn Leap entered native wind-up.")
    end

    return result
end)

mod:hook(VersusModeState.chaos_spawn_leap_action, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    -- Restore before the native cleanup so interruption, cancellation, target
    -- loss and ordinary completion all release the temporary speed ceiling.
    Specialist.restore_controlled_spawn_leap_navigation(scratchpad)

    return func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
end)

mod:hook(VersusModeState.chaos_spawn_leap_action, "_try_start_leap", function(func, self, unit, scratchpad, action_data, t, self_position, target_position)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack
    local controlled_leap = state
        and state.unit == unit
        and state.attack_deadline
        and attack
        and attack.action_name == "leap"
    -- Keep Darktide's native navmesh, target, raycast and collision validation.
    -- Its authored 15 m/s speed cannot solve level-ground long-range requests,
    -- so expose a bounded command-specific speed only for this synchronous
    -- native calculation and restore the shared setting before returning.
    local native_speed = ChaosSpawnSettings.leap_speed
    local solver_speed = controlled_leap
        and Specialist.controlled_spawn_leap_solver_speed(self_position, target_position, action_data)
        or native_speed
    local use_extended_speed = controlled_leap
        and type(native_speed) == "number"
        and type(solver_speed) == "number"
        and solver_speed > native_speed
    local success

    if use_extended_speed then
        ChaosSpawnSettings.leap_speed = solver_speed

        local call_ok, result = pcall(
            func,
            self,
            unit,
            scratchpad,
            action_data,
            t,
            self_position,
            target_position
        )

        ChaosSpawnSettings.leap_speed = native_speed

        if not call_ok then
            error(result)
        end

        success = result
    else
        success = func(self, unit, scratchpad, action_data, t, self_position, target_position)
    end

    if controlled_leap then
        state.spawn_leap_solver_speed = solver_speed
        state.spawn_leap_landing_offset = ChaosSpawnSettings.offset_in_front_of_target
        state.spawn_leap_contact_tolerance = 0
        state.spawn_leap_calculation_distance = vector3_distance(self_position, target_position)
        state.spawn_leap_target_position = Vector3Box(target_position)

        if scratchpad.leap_start_position then
            state.spawn_leap_start_position = Vector3Box(scratchpad.leap_start_position:unbox())
        end

        if success then
            local native_effective, native_error, impact_radius = Specialist.spawn_leap_native_path_is_effective(
                scratchpad,
                target_position,
                action_data
            )

            state.spawn_leap_native_predicted_error = native_error

            if not native_effective then
                local clearance = Specialist.controlled_spawn_leap_clearance_solution(
                    scratchpad,
                    target_position,
                    action_data
                )

                if clearance then
                    scratchpad.leap_velocity = Vector3Box(clearance.velocity)
                    state.spawn_leap_landing_offset = clearance.landing_offset
                    state.spawn_leap_contact_tolerance = clearance.impact_radius
                    state.spawn_leap_clearance_height = clearance.clearance_height
                    state.spawn_leap_predicted_error = clearance.impact_error

                    mod:info(
                        "Versus Mode: Chaos Spawn Leap replaced an ineffective %.2f m native landing with a %.2f m clearance arc (%.2f m/s, %.2f s, predicted target error %.2f m).",
                        native_error or -1,
                        clearance.clearance_height,
                        clearance.speed,
                        clearance.flight_time,
                        clearance.impact_error
                    )
                else
                    success = false
                    mod:warning(
                        "Versus Mode: Chaos Spawn Leap rejected an ineffective %.2f m native landing; no collision-safe arc reached the %.2f m impact radius.",
                        native_error or -1,
                        impact_radius or -1
                    )
                end
            end
        end
    end

    if controlled_leap then
        if success then
            state.attack_phase = mod:localize("spawn_leap_arc_locked")

            if not state.spawn_leap_clearance_height then
                mod:info(
                    "Versus Mode: Chaos Spawn Leap native trajectory accepted (request %.2f m, calculation %.2f m, solver %.2f m/s, authored stand-off %.2f m, predicted target error %.2f m).",
                    state.spawn_leap_request_distance or -1,
                    state.spawn_leap_calculation_distance or -1,
                    state.spawn_leap_solver_speed or -1,
                    state.spawn_leap_landing_offset or -1,
                    state.spawn_leap_native_predicted_error or -1
                )
            end
        else
            state.spawn_leap_failure = mod:localize("spawn_leap_no_trajectory")
            state.attack_phase = state.spawn_leap_failure
            mod:warning(
                "Versus Mode: Chaos Spawn Leap native trajectory rejected after wind-up (solver %.2f m/s).",
                state.spawn_leap_solver_speed or -1
            )
        end
    end

    return success
end)

mod:hook(VersusModeState.chaos_spawn_leap_action, "_leap", function(func, self, scratchpad)
    local result = func(self, scratchpad)
    local state = scratchpad.versus_mode_spawn_leap_state

    if state
        and state.unit
        and VersusModeState.control_for_unit(state.unit) == state
        and state.attack_deadline
        and state.requested_attack
        and state.requested_attack.action_name == "leap" then
        state.spawn_leap_launched = true
        state.spawn_leap_native_state = "leaping"
        state.attack_phase = mod:localize("spawn_leap_launched")
        mod:info("Versus Mode: Chaos Spawn Leap physically launched.")
    end

    return result
end)

mod:hook(VersusModeState.chaos_spawn_leap_action, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    local state = VersusModeState.control_for_unit(unit)
    local attack = state and state.requested_attack

    if state and state.unit == unit and state.attack_deadline and attack and attack.action_name == "leap" then
        local native_state = scratchpad.state

        state.spawn_leap_native_state = native_state or state.spawn_leap_native_state

        if native_state == "setup_leap" and not state.spawn_leap_launched then
            state.attack_phase = mod:localize("spawn_leap_arc_locked")
        elseif native_state == "leaping" or native_state == "falling" then
            state.attack_phase = mod:localize("spawn_leap_launched")
        elseif native_state == "landing" then
            state.attack_phase = mod:localize("spawn_leap_landing")

            if not state.spawn_leap_landing_logged then
                local current_position = live_world_position(unit)
                local start_position = state.spawn_leap_start_position
                    and state.spawn_leap_start_position:unbox()
                local target_position = state.spawn_leap_target_position
                    and state.spawn_leap_target_position:unbox()

                state.spawn_leap_landing_logged = true

                if current_position and start_position and target_position then
                    local travelled = vector3_length(Vector3.flat(current_position - start_position))
                    local target_error = vector3_length(Vector3.flat(target_position - current_position))

                    mod:info(
                        "Versus Mode: Chaos Spawn Leap reached landing state after %.2f m; %.2f m from committed target point.",
                        travelled,
                        target_error
                    )
                end
            end
        end

        if result == "failed" and not state.spawn_leap_failure then
            state.spawn_leap_failure = mod:localize("spawn_leap_target_lost")
            state.attack_phase = state.spawn_leap_failure
        elseif result == "done" then
            state.command_action_complete = true
            state.attack_min_until = 0
        end
    end

    return result
end)

mod:hook(BtChaosOgrynHoundmasterSelectorNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state and state.attack_deadline then
        handled, leaf_node = evaluate_forced_houndmaster_command(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

mod:hook(BtChaosBeastOfNurgleSelectorNode, "evaluate", function(func, self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    local state = VersusModeState.control_for_unit(unit)
    local handled, leaf_node

    if state then
        handled, leaf_node = evaluate_forced_beast_attack(self, state, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
    end

    if handled then
        return leaf_node
    end

    return func(self, unit, blackboard, scratchpad, dt, t, evaluate_utility, node_data, old_running_child_nodes, new_running_child_nodes, last_leaf_node_running)
end)

mod:hook(BtBeastOfNurgleSpitOutAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local state = VersusModeState.control_for_unit(unit)
    local behavior_component = blackboard and blackboard.behavior
    local consumed_unit = behavior_component and behavior_component.consumed_unit

    if state and state.unit == unit and state.breed.name == "chaos_beast_of_nurgle" and not valid_player_target(consumed_unit) then
        -- A possession pause can leave the native spit-out leaf selected after
        -- its consumed player has already been released. Native enter assumes
        -- the unit exists and crashes while fetching unit_data_system.
        local locomotion_extension = safe_extension(unit, "locomotion_system")

        scratchpad.versus_mode_abort_spit_out = true
        scratchpad.behavior_component = behavior_component
        scratchpad.perception_component = blackboard.perception
        scratchpad.locomotion_extension = locomotion_extension
        scratchpad.original_rotation_speed = locomotion_extension and locomotion_extension:rotation_speed() or 0
        scratchpad.consumed_unit = nil
        state.attack_phase = "RECOVERING"

        return
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, t)
end)

mod:hook(BtBeastOfNurgleConsumeAction, "leave", function(func, self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)
    local state = VersusModeState.control_for_unit(unit)
    local was_controlled_consume = state and state.unit == unit and state.requested_attack and state.requested_attack.beast_path == "consume"
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t, reason, destroy)

    if was_controlled_consume and VersusModeState.control_for_unit(unit) == state then
        -- Whether it connected or missed, one native Consume animation is one
        -- command. If it missed the hand-to-target radius, do not immediately
        -- re-enter the sequence and replay the animation.
        state.consume_attempt_complete = true

        if not HEALTH_ALIVE[blackboard.behavior.consumed_unit] then
            state.attack_phase = "MISSED"
            state.attack_min_until = 0
        end
    end

    return result
end)

local function stop_controlled_spawn_grab_motion(unit, scratchpad)
    local state = VersusModeState.control_for_unit(unit)

    if not state or state.unit ~= unit or state.breed.name ~= "chaos_spawn" or not state.requested_attack or state.requested_attack.action_name ~= "grab" then
        return
    end

    local navigation_extension = scratchpad.navigation_extension
    local locomotion_extension = scratchpad.locomotion_extension

    if navigation_extension and navigation_extension:enabled() then
        navigation_extension:set_enabled(false)
    end

    if locomotion_extension then
        locomotion_extension:set_wanted_velocity_flat(Vector3.zero())
    end

    scratchpad.versus_mode_grab_motion_guard = true
end

mod:hook(BtChaosSpawnGrabAction, "enter", function(func, self, unit, breed, blackboard, scratchpad, action_data, t)
    local result = func(self, unit, breed, blackboard, scratchpad, action_data, t)

    stop_controlled_spawn_grab_motion(unit, scratchpad)

    return result
end)

mod:hook(BtChaosSpawnGrabAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    if scratchpad.versus_mode_grab_motion_guard then
        if scratchpad.locomotion_extension then
            scratchpad.locomotion_extension:set_wanted_velocity_flat(Vector3.zero())
        end

        if scratchpad.navigation_extension and scratchpad.navigation_extension:enabled() then
            scratchpad.navigation_extension:set_enabled(false)
        end
    end

    local result = func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)

    if scratchpad.versus_mode_grab_motion_guard and scratchpad.locomotion_extension then
        scratchpad.locomotion_extension:set_wanted_velocity_flat(Vector3.zero())
    end

    return result
end)

mod:hook(BtBeastOfNurgleSpitOutAction, "run", function(func, self, unit, breed, blackboard, scratchpad, action_data, dt, t)
    if scratchpad.versus_mode_abort_spit_out then
        return "done"
    end

    return func(self, unit, breed, blackboard, scratchpad, action_data, dt, t)
end)

mod:hook(FreeFlightManager, "_check_toggle", function(func, self, ...)
    if mod._control or VersusModeState.local_active() or mod._suppress_freeflight_toggle_frames > 0 then
        return
    end

    return func(self, ...)
end)

function VersusModeState.release_remote_controls(reason, suppress_respawn)
    local pending = {}

    for _, state in pairs(mod._remote_controls or {}) do
        pending[#pending + 1] = state
    end

    for i = 1, #pending do
        VersusModeState.release_control(pending[i], reason, suppress_respawn)
    end

    mod._remote_controls = nil
end

mod.on_game_state_changed = function(status, state_name)
    if state_name == "RealmsPreparationState" and status == "enter" then
        VersusModeState.begin_realms_preparation_roster()
        -- Realms lazy-loads the preparation view after on_all_mods_loaded.
        -- Retry at the state boundary and repair an instance if it won the race.
        VersusModeState.install_realms_preparation_hooks()
        VersusModeState.repair_active_realms_preparation_view()
    elseif state_name == "RealmsPreparationState" and status == "exit" then
        mod._realms_preparation_active = nil
    elseif state_name == "StateGameplay" and status == "enter" then
        VersusModeState.restore_possession_camera_player_body()
        VersusModeState.finish_death_camera(false)
        VersusModeState.clear_replicated_host_state()
        mod._random_spawn_reservations = {}
        mod._random_spawn_history = {}
        VersusModeState.reset_redeployment_geography()
        VersusModeState.reset_last_survivor()
        VersusModeState.queue_lobby_plan_application()

        local ui_manager = Managers.ui

        if ui_manager and ui_manager:view_instance(VersusModeState.roster_view_name) then
            ui_manager:close_view(VersusModeState.roster_view_name)
        end
    elseif state_name == "StateGameplay" and status == "exit" then
        VersusModeState.clear_allied_heretic_outlines()
        VersusModeState.clear_operative_outlines()
        VersusModeState.finish_death_camera(false)
        VersusModeState.clear_infected_stealth_visibility()
        VersusModeState.reset_last_survivor()
        release_possession(nil, true)
        VersusModeState.release_remote_controls(nil, true)
        VersusModeState.clear()
        VersusModeState.reset_owned_free_flight_manager("gameplay exit")
        mod._versus_role_test = nil
        mod._versus_roles = nil
        mod._infected_selector_state = nil
        mod._pending_normal_bosses = nil
        mod._versus_mode_checked_bosses = nil
        mod._daemonhost_forced_leave = nil
        mod._pending_remote_control = nil
        mod._remote_action_sequence = nil
        mod._host_infected_spawn_selection_enabled = nil
        mod._host_specialist_variants_enabled = nil
        mod._random_spawn_reservations = nil
        mod._random_spawn_history = nil
        VersusModeState.reset_redeployment_geography()
        VersusModeState.clear_replicated_host_state()
        mod._realms_profile_visual_repairs = nil
        mod._keybind_holds = {}
        mod._infected_lobby_plan = nil
        mod._replicated_lobby_plan = nil
        mod._pending_lobby_roster_application = nil
        mod._realms_preparation_active = nil
        VersusModeState.restore_possession_camera_player_body()
    end
end

mod.on_all_mods_loaded = function()
    VersusModeState.ensure_outline_settings()
    VersusModeState.install_client_view_hooks()
    VersusModeState.install_remote_animation_repair_hooks()
    install_realms_profile_visual_repair()
    install_world_marker_compatibility_hook()
    install_possession_hud_compatibility_hook()
    VersusModeState.install_realms_preparation_hooks()

    if mod._realms_compat then
        mod._realms_compat.install({
            client_ready = function(peer_id, compatible, peer_status)
                if VersusModeState.realms_lobby_host() then
                    if not compatible then
                        VersusModeState.remove_lobby_peer(peer_id)
                    end

                    VersusModeState.publish_lobby_plan(peer_id)

                    return
                end

                if not is_server() then
                    return
                end

                local role = VersusModeState.role_for_peer(peer_id)

                if role and not compatible then
                    local state = VersusModeState.control_for_peer(peer_id)

                    if state then
                        VersusModeState.release_control(state, "client compatibility was lost; control released.", true)
                    end

                    VersusModeState.clear_role(role, string.format(
                        "client requires Versus Mode %s (reported %s)",
                        mod.version,
                        peer_status and peer_status.version or "unknown"
                    ))
                end

                VersusModeState.publish_roster(peer_id)
            end,
            lobby_plan = VersusModeState.apply_replicated_lobby_plan,
            roster = VersusModeState.apply_replicated_roster,
            spawn = VersusModeState.try_remote_respawn,
            input = VersusModeState.receive_remote_input,
            action = VersusModeState.receive_remote_action,
            animation = VersusModeState.apply_remote_animation,
            control = VersusModeState.begin_client_control,
            status = VersusModeState.apply_remote_status,
            release = function(payload)
                payload = type(payload) == "table" and payload or {}
                VersusModeState.release_client_control(payload.reason, payload.controlled_unit_dead)
            end,
            peer_left = function(peer_id, departed_host)
                if mod._realms_compat.is_connection_host
                    and mod._realms_compat.is_connection_host() then
                    VersusModeState.remove_lobby_peer(peer_id)
                end

                if is_server() then
                    local state = VersusModeState.control_for_peer(peer_id)
                    local role = VersusModeState.role_for_peer(peer_id)

                    if state then
                        mod._remote_controls[peer_id] = nil
                        state.controller_peer_id = nil
                        VersusModeState.release_control(state, nil, true)
                    end

                    if role then
                        VersusModeState.clear_role(role, "player left the Realms session")
                    end
                elseif departed_host then
                    VersusModeState.release_client_control("Realms host disconnected; control released.", true)
                    VersusModeState.clear()
                    VersusModeState.clear_replicated_host_state()
                    mod._pending_remote_control = nil
                    mod._replicated_lobby_plan = nil
                end
            end,
        })
    end
end

mod.on_setting_changed = function(setting_id)
    local state = mod._control

    if mod._keybind_holds and string.find(setting_id, "keybind", 1, true) then
        -- Bind and activation changes are made in menus. Clear every timer so
        -- a held edge from the previous configuration cannot survive a live
        -- rebind or activation-mode change.
        mod._keybind_holds = {}
    end

    if setting_id == "use_custom_enemy_keybinds" then
        VersusModeState.reset_vanilla_enemy_input()

        if state and state.breed and HOUND_BREEDS[state.breed.name] and state.hound_pounce_preview_active then
            state.hound_pounce_preview_active = nil
            Specialist.destroy_hound_preview(state)
        elseif state and state.breed and state.breed.name == SNIPER_BREED_NAME and state.sniper_laser_active then
            mod.heavy_attack(false, true, true)
            state.sniper_laser_active = nil
        end
    end

    if setting_id == "hound_heavy_trajectory_mode"
        and state
        and state.breed
        and HOUND_BREEDS[state.breed.name]
        and state.hound_pounce_preview_active then
        Specialist.destroy_hound_preview(state)
        set_status(state, mod:localize("hound_charge_cancelled"), 2.5)
    end

    if setting_id == "show_target_outline" then
        if state then
            refresh_target_outline(state)
        end

        if not setting("show_target_outline") then
            VersusModeState.clear_operative_outlines()
        end
    end

    if setting_id == "show_allied_heretic_outlines" and not setting("show_allied_heretic_outlines") then
        VersusModeState.clear_allied_heretic_outlines()
    end

    if is_server()
        and (setting_id == "controlled_boss_health_multiplier"
            or setting_id == "controlled_specialist_health_multiplier"
            or setting_id == "controlled_elite_health_multiplier") then
        if state and VersusModeState.controlled_health_setting_id(state) == setting_id then
            VersusModeState.rescale_controlled_health(state, setting(setting_id))
        end

        for _, remote_state in pairs(mod._remote_controls or {}) do
            if VersusModeState.controlled_health_setting_id(remote_state) == setting_id then
                VersusModeState.rescale_controlled_health(remote_state, setting(setting_id))
            end
        end

        for _, role in pairs(VersusModeState.roles()) do
            local bot_state = role.autonomous_health_state

            if VersusModeState.controlled_health_setting_id(bot_state) == setting_id then
                VersusModeState.rescale_controlled_health(bot_state, setting(setting_id))
            end
        end
    end

    if setting_id == "enable_last_survivor_buff" and not setting("enable_last_survivor_buff") then
        local last_survivor = VersusModeState.last_survivor_state()

        if last_survivor.active then
            VersusModeState.remove_last_survivor_buffs(last_survivor.active)
            last_survivor.active = nil
            mod._last_survivor_notice = nil
            VersusModeState.publish_roster()
        end

        VersusModeState.suspend_last_survivor_trigger()
    end

    if setting_id == "enable_specialist_variants" and not setting("enable_specialist_variants") then
        for _, role in pairs(VersusModeState.roles()) do
            role.respawn_variant = nil
        end
    end

    if setting_id == "enable_random_safe_spawn" and not setting("enable_random_safe_spawn") then
        mod._random_spawn_reservations = {}
    end

    if setting_id == "enable_automatic_respawn" and not setting("enable_automatic_respawn") then
        for _, role in pairs(VersusModeState.roles()) do
            role.automatic_respawn_retry_at = nil
            role.automatic_respawn_notice_at = nil
            role.automatic_respawn_reason = nil
            role.automatic_respawn_not_before = nil
        end
    end

    if setting_id == "enable_controlled_traversal" and not setting("enable_controlled_traversal") then
        if mod._control and not mod._control.remote_client then
            VersusModeState.finish_controlled_traversal(mod._control, "cancelled", false, true)
        end

        for _, remote_state in pairs(mod._remote_controls or {}) do
            VersusModeState.finish_controlled_traversal(remote_state, "cancelled", false, true)
        end
    end

    if is_server()
        and (setting_id == "enable_specialist_variants"
            or setting_id == "enable_infected_spawn_selection"
            or setting_id == "enable_automatic_respawn"
            or setting_id == "enable_random_safe_spawn"
            or setting_id == "enable_controlled_traversal") then
        VersusModeState.roster_changed()
    end

    if setting_id == "enable_versus_mode" and not setting("enable_versus_mode") then
        VersusModeState.reset_last_survivor(true)

        if mod._control then
            release_possession("infected-role test disabled; control released.")
        end

        VersusModeState.release_remote_controls("infected-role test disabled; control released.", true)
        VersusModeState.clear("test disabled in Mod Options")
        VersusModeState.clear_replicated_host_state()
        mod._pending_normal_bosses = nil
        mod._versus_mode_checked_bosses = nil
        mod._infected_lobby_plan = nil
        mod._replicated_lobby_plan = nil
        mod._pending_lobby_roster_application = nil
        mod._realms_preparation_active = nil
        VersusModeState.reset_owned_free_flight_manager("Versus Mode disabled")
    elseif setting_id == "enable_versus_roster_menu" and not setting("enable_versus_roster_menu") then
        local ui_manager = Managers.ui

        if ui_manager and ui_manager:view_instance(VersusModeState.roster_view_name) then
            ui_manager:close_view(VersusModeState.roster_view_name)
        end
    elseif setting_id == "hide_infected_team_panel" then
        VersusModeState.notify_composition_changed()
    elseif setting_id == "freeze_survivor_bots" then
        VersusModeState.echo_localized(setting("freeze_survivor_bots")
            and "notice_survivor_bots_frozen"
            or "notice_survivor_bots_resumed")
    end

    if setting_id == "enable_versus_mode" and mod._realms_compat then
        mod._realms_compat.reset_client_hello()
    end
end

mod.on_disabled = function()
    if mod._control and mod._control.remote_client then
        VersusModeState.send_client_action("release")
    end

    VersusModeState.clear_allied_heretic_outlines()
    VersusModeState.clear_operative_outlines()
    VersusModeState.finish_death_camera(false)
    VersusModeState.clear_infected_stealth_visibility()
    release_possession("mod disabled; control released.", true)
    VersusModeState.reset_last_survivor(true)
    VersusModeState.release_remote_controls("mod disabled; control released.", true)
    VersusModeState.clear("mod disabled")
    VersusModeState.clear_replicated_host_state()
    mod._versus_roles = nil
    mod._infected_selector_state = nil
    mod._pending_normal_bosses = nil
    mod._versus_mode_checked_bosses = nil
    mod._daemonhost_forced_leave = nil
    mod._pending_remote_control = nil
    mod._host_infected_spawn_selection_enabled = nil
    mod._host_specialist_variants_enabled = nil
    mod._random_spawn_reservations = nil
    mod._random_spawn_history = nil
    VersusModeState.reset_redeployment_geography()
    mod._keybind_holds = {}
    mod._infected_lobby_plan = nil
    mod._replicated_lobby_plan = nil
    mod._pending_lobby_roster_application = nil
    mod._realms_preparation_active = nil
    VersusModeState.reset_owned_free_flight_manager("mod disabled")
    VersusModeState.restore_possession_camera_player_body()
end

mod.on_unload = function()
    VersusModeState.clear_allied_heretic_outlines()
    VersusModeState.clear_operative_outlines()
    VersusModeState.finish_death_camera(false)
    VersusModeState.clear_infected_stealth_visibility()
    VersusModeState.reset_last_survivor()
    release_possession(nil, true)
    VersusModeState.release_remote_controls(nil, true)
    VersusModeState.clear()
    VersusModeState.clear_replicated_host_state()
    mod._versus_roles = nil
    mod._infected_selector_state = nil
    mod._pending_normal_bosses = nil
    mod._versus_mode_checked_bosses = nil
    mod._daemonhost_forced_leave = nil
    mod._pending_remote_control = nil
    mod._host_infected_spawn_selection_enabled = nil
    mod._host_specialist_variants_enabled = nil
    mod._random_spawn_reservations = nil
    mod._random_spawn_history = nil
    VersusModeState.reset_redeployment_geography()
    mod._infected_lobby_plan = nil
    mod._replicated_lobby_plan = nil
    mod._pending_lobby_roster_application = nil
    mod._realms_preparation_active = nil
    VersusModeState.reset_owned_free_flight_manager("mod unload")
    VersusModeState.restore_possession_camera_player_body()
end

-- Keep the HUD module in this already-loaded main script. Some mod update
-- workflows replace existing files but silently omit newly added subfolders;
-- preloading it here makes UIHud.require() independent of a second Lua file.
local EMBEDDED_HUD_MODULE = "VersusMode/scripts/mods/VersusMode/VersusMode"
local HUD_MAX_LINES = 12
local HUD_WIDTH = 620
local HUD_LINE_HEIGHT = 25
local HUD_COLORS = {
    header = { 255, 237, 185, 92 },
    locked = { 255, 255, 42, 32 },
    auto = { 255, 238, 194, 91 },
    normal = { 255, 232, 232, 225 },
    ready = { 255, 120, 235, 145 },
    busy = { 255, 255, 188, 75 },
    shadow = { 220, 0, 0, 0 },
}
local ENEMY_PANEL_WIDTH = 510
local ENEMY_PANEL_HEIGHT = 100
local ENEMY_HEALTH_WIDTH = 279
local ENEMY_HEALTH_HEIGHT = 18
local GRENADE_HUD_ARC_SEGMENTS = 128
local GRENADE_HUD_AREA_SEGMENTS = 32
local GRENADE_HUD_IMPACT_SIZE = 18
local function grenade_hud_visibility(content_id)
    return function(content)
        return content[content_id] == true
    end
end

local function build_grenade_hud_passes()
    local trajectory_passes = {}

    for i = 1, GRENADE_HUD_ARC_SEGMENTS do
        local id = "arc_" .. i

        trajectory_passes[#trajectory_passes + 1] = {
            pass_type = "rotated_texture",
            value = "content/ui/materials/backgrounds/default_square",
            style_id = id,
            visibility_function = grenade_hud_visibility(id),
            style = {
                size = { 1, 4 },
                offset = { 0, 0, 1 },
                pivot = { 0, 2 },
                angle = 0,
                color = { 245, 255, 190, 75 },
            },
        }
    end

    for i = 1, GRENADE_HUD_AREA_SEGMENTS do
        local id = "area_" .. i

        trajectory_passes[#trajectory_passes + 1] = {
            pass_type = "rotated_texture",
            value = "content/ui/materials/backgrounds/default_square",
            style_id = id,
            visibility_function = grenade_hud_visibility(id),
            style = {
                size = { 1, 2 },
                offset = { 0, 0, 2 },
                pivot = { 0, 1 },
                angle = 0,
                color = { 90, 100, 255, 130 },
            },
        }
    end

    for i = 1, 2 do
        local id = "impact_" .. i

        trajectory_passes[#trajectory_passes + 1] = {
            pass_type = "rotated_texture",
            value = "content/ui/materials/backgrounds/default_square",
            style_id = id,
            visibility_function = grenade_hud_visibility(id),
            style = {
                size = { 1, 4 },
                offset = { 0, 0, 3 },
                pivot = { 0, 2 },
                angle = 0,
                color = { 255, 120, 255, 140 },
            },
        }
    end

    return trajectory_passes
end

function VersusModeState.build_target_lock_marker_passes()
    local passes = {}
    local segment_ids = {
        "top_left_horizontal",
        "top_left_vertical",
        "top_right_horizontal",
        "top_right_vertical",
        "bottom_left_horizontal",
        "bottom_left_vertical",
        "bottom_right_horizontal",
        "bottom_right_vertical",
    }

    for i = 1, #segment_ids do
        local id = segment_ids[i]

        passes[#passes + 1] = {
            pass_type = "rect",
            style_id = id,
            style = {
                size = { 12, 3 },
                offset = { 0, 0, 2 },
                color = { 245, 255, 38, 28 },
            },
        }
    end

    passes[#passes + 1] = {
        pass_type = "text",
        value_id = "label",
        style_id = "label",
        value = "",
        style = {
            font_type = "proxima_nova_bold",
            font_size = 17,
            text_horizontal_alignment = "center",
            text_vertical_alignment = "center",
            size = { 100, 24 },
            offset = { 0, 0, 3 },
            text_color = { 255, 255, 48, 38 },
            drop_shadow = true,
        },
    }

    return passes
end

function VersusModeState.build_traversal_highlight_passes()
    local passes = {}
    local segment_ids = {
        "route",
        "entrance_1",
        "entrance_2",
        "entrance_3",
        "entrance_4",
        "destination_1",
        "destination_2",
    }

    for i = 1, #segment_ids do
        local id = segment_ids[i]

        passes[#passes + 1] = {
            pass_type = "rotated_texture",
            value = "content/ui/materials/backgrounds/default_square",
            style_id = id,
            visibility_function = grenade_hud_visibility(id),
            style = {
                size = { 1, 3 },
                offset = { 0, 0, 1 },
                pivot = { 0, 1.5 },
                angle = 0,
                color = { 245, 110, 255, 150 },
            },
        }
    end

    passes[#passes + 1] = {
        pass_type = "text",
        value_id = "label",
        style_id = "label",
        value = "",
        visibility_function = grenade_hud_visibility("label_visible"),
        style = {
            font_type = "proxima_nova_bold",
            font_size = 18,
            text_horizontal_alignment = "left",
            text_vertical_alignment = "center",
            size = { 420, 30 },
            offset = { 0, 0, 3 },
            text_color = { 255, 150, 255, 175 },
            drop_shadow = true,
        },
    }

    return passes
end

local function build_embedded_hud_definitions()
    local passes = {}
    local trajectory_passes = build_grenade_hud_passes()
    local traversal_highlight_passes = VersusModeState.build_traversal_highlight_passes()

    for i = 1, HUD_MAX_LINES do
        local id = "line_" .. i
        local y = (i - 1) * HUD_LINE_HEIGHT

        passes[#passes + 1] = {
            pass_type = "text",
            value_id = id,
            style_id = id .. "_shadow",
            value = "",
            style = {
                font_type = "proxima_nova_bold",
                font_size = 18,
                text_horizontal_alignment = "left",
                text_vertical_alignment = "top",
                size = { HUD_WIDTH, HUD_LINE_HEIGHT + 5 },
                offset = { 2, y + 2, 1 },
                text_color = HUD_COLORS.shadow,
            },
        }
        passes[#passes + 1] = {
            pass_type = "text",
            value_id = id,
            style_id = id,
            value = "",
            style = {
                font_type = "proxima_nova_bold",
                font_size = 18,
                text_horizontal_alignment = "left",
                text_vertical_alignment = "top",
                size = { HUD_WIDTH, HUD_LINE_HEIGHT + 5 },
                offset = { 0, y, 2 },
                text_color = HUD_COLORS.normal,
            },
        }
    end

    return {
        scenegraph_definition = {
            screen = UIWorkspaceSettings.screen,
            versus_mode_hud = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = { HUD_WIDTH, HUD_MAX_LINES * HUD_LINE_HEIGHT + 10 },
                position = { 40, 210, 70 },
            },
            versus_mode_crosshair = {
                parent = "screen",
                horizontal_alignment = "center",
                vertical_alignment = "center",
                size = { 64, 64 },
                position = { 0, 0, 80 },
            },
            grenade_trajectory = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = { 0, 0 },
                position = { 0, 0, 90 },
            },
            traversal_highlight = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = { 0, 0 },
                position = { 0, 0, 91 },
            },
            target_lock_marker = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "top",
                size = { 0, 0 },
                position = { 0, 0, 92 },
            },
            enemy_status_panel = {
                parent = "screen",
                horizontal_alignment = "left",
                vertical_alignment = "bottom",
                size = { ENEMY_PANEL_WIDTH, ENEMY_PANEL_HEIGHT },
                position = { 17, -50, 75 },
            },
            enemy_portrait = {
                parent = "enemy_status_panel",
                horizontal_alignment = "left",
                vertical_alignment = "center",
                size = { 90, 90 },
                position = { 20, 0, 2 },
            },
            enemy_name = {
                parent = "enemy_status_panel",
                horizontal_alignment = "left",
                vertical_alignment = "center",
                size = { 350, 28 },
                position = { 128, -22, 3 },
            },
            enemy_health = {
                parent = "enemy_status_panel",
                horizontal_alignment = "left",
                vertical_alignment = "center",
                size = { ENEMY_HEALTH_WIDTH, ENEMY_HEALTH_HEIGHT },
                position = { 128, 15, 3 },
            },
        },
        widget_definitions = {
            panel = UIWidget.create_definition(passes, "versus_mode_hud"),
            crosshair = UIWidget.create_definition({
                {
                    pass_type = "text",
                    value_id = "crosshair",
                    style_id = "crosshair",
                    value = "+",
                    style = {
                        font_type = "proxima_nova_bold",
                        font_size = 30,
                        text_horizontal_alignment = "center",
                        text_vertical_alignment = "center",
                        size = { 64, 64 },
                        offset = { 0, 0, 1 },
                        text_color = HUD_COLORS.ready,
                    },
                },
            }, "versus_mode_crosshair"),
            sniper_scope = UIWidget.create_definition({
                {
                    pass_type = "texture",
                    value = "content/ui/materials/masks/gradient_vignette",
                    style_id = "scope_vignette",
                    style = {
                        color = { 0, 0, 0, 0 },
                    },
                },
                {
                    pass_type = "texture",
                    value = "content/ui/materials/backgrounds/default_square",
                    style_id = "scope_dot",
                    style = {
                        horizontal_alignment = "center",
                        vertical_alignment = "center",
                        size = { 4, 4 },
                        offset = { -2, -2, 6 },
                        color = { 0, 245, 245, 235 },
                    },
                },
            }, "screen"),
            grenade_trajectory = UIWidget.create_definition(trajectory_passes, "grenade_trajectory"),
            traversal_highlight = UIWidget.create_definition(traversal_highlight_passes, "traversal_highlight"),
            target_lock_marker = UIWidget.create_definition(
                VersusModeState.build_target_lock_marker_passes(),
                "target_lock_marker"
            ),
            enemy_background = UIWidget.create_definition({
                {
                    pass_type = "texture",
                    value = "content/ui/materials/backgrounds/default_square",
                    style = {
                        color = { 95, 0, 0, 0 },
                    },
                },
            }, "enemy_status_panel"),
            enemy_portrait = UIWidget.create_definition({
                {
                    pass_type = "texture",
                    value_id = "portrait",
                    value = ENEMY_PORTRAIT_FALLBACK,
                    style_id = "portrait",
                    style = {
                        color = { 255, 255, 255, 255 },
                    },
                },
            }, "enemy_portrait"),
            enemy_name = UIWidget.create_definition({
                {
                    pass_type = "text",
                    value_id = "name",
                    value = "",
                    style_id = "name",
                    style = {
                        font_type = "proxima_nova_bold",
                        font_size = 22,
                        text_horizontal_alignment = "left",
                        text_vertical_alignment = "center",
                        text_color = HUD_COLORS.header,
                        drop_shadow = true,
                    },
                },
            }, "enemy_name"),
            enemy_health_background = UIWidget.create_definition({
                {
                    pass_type = "texture",
                    value = "content/ui/materials/backgrounds/default_square",
                    style = {
                        color = { 210, 20, 20, 20 },
                    },
                },
            }, "enemy_health"),
            enemy_health_fill = UIWidget.create_definition({
                {
                    pass_type = "texture",
                    value = "content/ui/materials/hud/backgrounds/boss_health_fill",
                    style_id = "fill",
                    style = {
                        horizontal_alignment = "left",
                        size = { ENEMY_HEALTH_WIDTH, ENEMY_HEALTH_HEIGHT },
                        color = { 255, 115, 215, 125 },
                    },
                },
            }, "enemy_health"),
            enemy_health_text = UIWidget.create_definition({
                {
                    pass_type = "text",
                    value_id = "health",
                    value = "",
                    style_id = "health",
                    style = {
                        font_type = "machine_medium",
                        font_size = 17,
                        text_horizontal_alignment = "center",
                        text_vertical_alignment = "center",
                        text_color = { 255, 245, 245, 240 },
                        drop_shadow = true,
                        offset = { 0, 0, 2 },
                    },
                },
            }, "enemy_health"),
        },
    }
end

local HudElementVersusMode = class("HudElementVersusMode", "HudElementBase")
local embedded_hud_definitions = build_embedded_hud_definitions()

local function hud_color_with_opacity(source, opacity)
    return {
        math.floor(source[1] * opacity + 0.5),
        source[2],
        source[3],
        source[4],
    }
end

HudElementVersusMode.init = function(self, parent, draw_layer, start_scale)
    HudElementVersusMode.super.init(self, parent, draw_layer, start_scale, embedded_hud_definitions)

    self._versus_mode_refresh_timer = 0
    self._versus_mode_line_cache = {}
    self._widgets_by_name.panel.content.visible = false
    self._widgets_by_name.crosshair.content.visible = false
    self._widgets_by_name.sniper_scope.content.visible = false
    self._widgets_by_name.grenade_trajectory.content.visible = false
    self._widgets_by_name.traversal_highlight.content.visible = false
    self._widgets_by_name.target_lock_marker.content.visible = false
    self._widgets_by_name.enemy_background.content.visible = false
    self._widgets_by_name.enemy_portrait.content.visible = false
    self._widgets_by_name.enemy_name.content.visible = false
    self._widgets_by_name.enemy_health_background.content.visible = false
    self._widgets_by_name.enemy_health_fill.content.visible = false
    self._widgets_by_name.enemy_health_text.content.visible = false
end

HudElementVersusMode._refresh_sniper_scope = function(self)
    local widget = self._widgets_by_name.sniper_scope
    local progress = VersusModeState.sniper_scope_hud_progress()

    widget.content.visible = progress > 0.001

    if not widget.content.visible then
        return
    end

    widget.style.scope_vignette.color[1] = math.floor(205 * progress + 0.5)

    widget.style.scope_dot.color[1] = math.floor(245 * progress + 0.5)
end

HudElementVersusMode._refresh_grenade_trajectory = function(self, ui_renderer)
    local widget = self._widgets_by_name.grenade_trajectory
    local data = mod.grenade_trajectory_hud_data and mod.grenade_trajectory_hud_data()
    local free_flight = Managers.free_flight
    local camera

    -- Possession is rendered through Darktide's global free-flight viewport.
    -- UIHud:player_camera() caches the original player viewport camera, which
    -- projects the same world points into an unrelated part of the screen.
    if free_flight and free_flight:is_in_free_flight() then
        local camera_ok, free_flight_camera = pcall(free_flight.camera, free_flight, "global")

        camera = camera_ok and free_flight_camera or nil
    end

    camera = camera or self._parent and self._parent:player_camera()

    if not data or not camera or not ui_renderer then
        widget.content.visible = false

        return
    end

    widget.content.visible = true

    local inverse_scale = ui_renderer.inverse_scale or 1
    local valid_color = data.valid and { 245, 255, 190, 75 } or { 230, 255, 120, 50 }
    local bounce_color = data.valid and { 245, 105, 220, 255 } or valid_color
    local area_color = data.valid and { 90, 100, 255, 130 } or { 90, 255, 65, 50 }
    local impact_color = data.valid and { 255, 120, 255, 140 } or { 255, 255, 80, 60 }

    local function project(world_position)
        local inside = Camera.inside_frustum(camera, world_position) > 0
        local screen_position, distance = Camera.world_to_screen(camera, world_position)
        local visible = inside and distance and distance > 0

        if visible then
            return screen_position.x * inverse_scale, screen_position.y * inverse_scale
        end

        return nil, nil
    end

    local function set_segment(content_id, from_x, from_y, to_x, to_y, color, thickness)
        local visible = from_x ~= nil and from_y ~= nil and to_x ~= nil and to_y ~= nil

        if not visible then
            widget.content[content_id] = false

            return
        end

        local delta_x = to_x - from_x
        local delta_y = to_y - from_y
        local length = math.sqrt(delta_x * delta_x + delta_y * delta_y)

        if length < 0.5 then
            widget.content[content_id] = false

            return
        end

        local style = widget.style[content_id]

        widget.content[content_id] = true
        style.size[1] = length
        style.size[2] = thickness
        style.offset[1] = from_x
        style.offset[2] = from_y - thickness * 0.5
        style.pivot[1] = 0
        style.pivot[2] = thickness * 0.5
        -- Rotated UI textures use the opposite angular direction from the
        -- projected screen-space Y axis. Negate the segment angle so adjacent
        -- endpoints meet instead of producing detached mirrored dashes.
        style.angle = -math_atan2(delta_y, delta_x)
        style.color = color
    end

    local point_count = math_min(#data.points, GRENADE_HUD_ARC_SEGMENTS + 1)
    local previous_x, previous_y

    if point_count > 0 then
        previous_x, previous_y = project(data.points[1]:unbox())
    end

    for i = 1, GRENADE_HUD_ARC_SEGMENTS do
        if i < point_count then
            local current_x, current_y = project(data.points[i + 1]:unbox())
            local segment_color = data.bounce_segments and data.bounce_segments[i] and bounce_color or valid_color

            set_segment("arc_" .. i, previous_x, previous_y, current_x, current_y, segment_color, 4)
            previous_x, previous_y = current_x, current_y
        else
            widget.content["arc_" .. i] = false
        end
    end

    if data.impact_position then
        local center = data.impact_position:unbox() + vector3_up() * 0.06
        local radius = data.area_radius or 5
        local area_points = {}
        local impact_x, impact_y = project(center)

        if impact_x and impact_y then
            local half_size = GRENADE_HUD_IMPACT_SIZE * 0.5

            set_segment("impact_1", impact_x - half_size, impact_y, impact_x + half_size, impact_y, impact_color, 4)
            set_segment("impact_2", impact_x, impact_y - half_size, impact_x, impact_y + half_size, impact_color, 4)
        else
            widget.content.impact_1 = false
            widget.content.impact_2 = false
        end

        if data.show_area ~= false then
            for i = 1, GRENADE_HUD_AREA_SEGMENTS do
                local angle = (i - 1) / GRENADE_HUD_AREA_SEGMENTS * math.pi * 2
                local position = center + Vector3(math_cos(angle), math_sin(angle), 0) * radius

                area_points[i] = { project(position) }
            end

            for i = 1, GRENADE_HUD_AREA_SEGMENTS do
                local next_i = i % GRENADE_HUD_AREA_SEGMENTS + 1
                local from = area_points[i]
                local to = area_points[next_i]

                set_segment("area_" .. i, from[1], from[2], to[1], to[2], area_color, 2)
            end
        else
            for i = 1, GRENADE_HUD_AREA_SEGMENTS do
                widget.content["area_" .. i] = false
            end
        end
    else
        widget.content.impact_1 = false
        widget.content.impact_2 = false

        for i = 1, GRENADE_HUD_AREA_SEGMENTS do
            widget.content["area_" .. i] = false
        end
    end
end

HudElementVersusMode._refresh_traversal_highlight = function(self, ui_renderer)
    local widget = self._widgets_by_name.traversal_highlight
    local data = mod.traversal_highlight_hud_data and mod.traversal_highlight_hud_data()
    local segment_ids = {
        "route",
        "entrance_1",
        "entrance_2",
        "entrance_3",
        "entrance_4",
        "destination_1",
        "destination_2",
    }
    local free_flight = Managers.free_flight
    local camera

    if free_flight and free_flight:is_in_free_flight() then
        local camera_ok, free_flight_camera = pcall(free_flight.camera, free_flight, "global")

        camera = camera_ok and free_flight_camera or nil
    end

    camera = camera or self._parent and self._parent:player_camera()

    if not data or not camera or not ui_renderer then
        widget.content.visible = false
        widget.content.label_visible = false

        for i = 1, #segment_ids do
            widget.content[segment_ids[i]] = false
        end

        return
    end

    local inverse_scale = ui_renderer.inverse_scale or 1
    local color = data.kind == "drop" and { 245, 255, 185, 75 }
        or data.kind == "vault" and { 245, 90, 210, 255 }
        or { 245, 110, 255, 150 }
    local text_color = { 255, color[2], color[3], color[4] }

    local function project(world_position)
        local inside = Camera.inside_frustum(camera, world_position) > 0
        local screen_position, distance = Camera.world_to_screen(camera, world_position)

        if inside and distance and distance > 0 then
            return screen_position.x * inverse_scale, screen_position.y * inverse_scale
        end

        return nil, nil
    end

    local function set_segment(id, from_x, from_y, to_x, to_y, thickness)
        if not from_x or not from_y or not to_x or not to_y then
            widget.content[id] = false

            return
        end

        local delta_x = to_x - from_x
        local delta_y = to_y - from_y
        local length = math.sqrt(delta_x * delta_x + delta_y * delta_y)

        if length < 0.5 then
            widget.content[id] = false

            return
        end

        local style = widget.style[id]

        widget.content[id] = true
        style.size[1] = length
        style.size[2] = thickness
        style.offset[1] = from_x
        style.offset[2] = from_y - thickness * 0.5
        style.pivot[1] = 0
        style.pivot[2] = thickness * 0.5
        style.angle = -math_atan2(delta_y, delta_x)
        style.color = color
    end

    local entrance = data.entrance:unbox() + vector3_up() * 0.35
    local destination = data.destination:unbox() + vector3_up() * 0.35
    local entrance_x, entrance_y = project(entrance)
    local destination_x, destination_y = project(destination)

    if not entrance_x then
        widget.content.visible = false
        widget.content.label_visible = false

        for i = 1, #segment_ids do
            widget.content[segment_ids[i]] = false
        end

        return
    end

    widget.content.visible = true
    widget.content.label_visible = true
    widget.content.label = data.label
    widget.style.label.offset[1] = entrance_x + 18
    widget.style.label.offset[2] = entrance_y - 42
    widget.style.label.text_color = text_color

    local marker_size = 12

    set_segment("entrance_1", entrance_x, entrance_y - marker_size, entrance_x + marker_size, entrance_y, 4)
    set_segment("entrance_2", entrance_x + marker_size, entrance_y, entrance_x, entrance_y + marker_size, 4)
    set_segment("entrance_3", entrance_x, entrance_y + marker_size, entrance_x - marker_size, entrance_y, 4)
    set_segment("entrance_4", entrance_x - marker_size, entrance_y, entrance_x, entrance_y - marker_size, 4)
    set_segment("route", entrance_x, entrance_y, destination_x, destination_y, 3)
    set_segment("destination_1", destination_x and destination_x - 6, destination_y, destination_x and destination_x + 6, destination_y, 3)
    set_segment("destination_2", destination_x, destination_y and destination_y - 6, destination_x, destination_y and destination_y + 6, 3)
end

HudElementVersusMode._refresh_target_lock_marker = function(self, ui_renderer, t)
    local widget = self._widgets_by_name.target_lock_marker
    local data = mod.target_lock_marker_hud_data and mod.target_lock_marker_hud_data()
    local free_flight = Managers.free_flight
    local camera

    if free_flight and free_flight:is_in_free_flight() then
        local camera_ok, free_flight_camera = pcall(free_flight.camera, free_flight, "global")

        camera = camera_ok and free_flight_camera or nil
    end

    camera = camera or self._parent and self._parent:player_camera()

    if not data or not camera or not ui_renderer then
        widget.content.visible = false

        return
    end

    local center = (data.head + data.feet) * 0.5

    if Camera.inside_frustum(camera, center) <= 0 then
        widget.content.visible = false

        return
    end

    local head_screen, head_distance = Camera.world_to_screen(camera, data.head)
    local feet_screen, feet_distance = Camera.world_to_screen(camera, data.feet)

    if not head_screen or not feet_screen
        or not head_distance or head_distance <= 0
        or not feet_distance or feet_distance <= 0 then
        widget.content.visible = false

        return
    end

    local inverse_scale = ui_renderer.inverse_scale or 1
    local head_x = head_screen.x * inverse_scale
    local head_y = head_screen.y * inverse_scale
    local feet_x = feet_screen.x * inverse_scale
    local feet_y = feet_screen.y * inverse_scale
    local measured_height = math.abs(feet_y - head_y)
    local box_height = math_min(240, math_max(44, measured_height + 24))
    local box_width = math_min(110, math_max(34, box_height * 0.48))
    local center_x = (head_x + feet_x) * 0.5
    local center_y = (head_y + feet_y) * 0.5
    local left = center_x - box_width * 0.5
    local right = center_x + box_width * 0.5
    local top = center_y - box_height * 0.5
    local bottom = center_y + box_height * 0.5
    local corner = math_min(24, math_max(11, box_width * 0.3))
    local thickness = 3
    local pulse = 0.5 + 0.5 * math_sin((t or 0) * 6)
    local alpha = math.floor(205 + 50 * pulse + 0.5)
    local color = { alpha, 255, 38, 28 }

    local function set_segment(id, x, y, width, height)
        local style = widget.style[id]

        style.offset[1] = x
        style.offset[2] = y
        style.size[1] = width
        style.size[2] = height
        style.color = color
    end

    set_segment("top_left_horizontal", left, top, corner, thickness)
    set_segment("top_left_vertical", left, top, thickness, corner)
    set_segment("top_right_horizontal", right - corner, top, corner, thickness)
    set_segment("top_right_vertical", right - thickness, top, thickness, corner)
    set_segment("bottom_left_horizontal", left, bottom - thickness, corner, thickness)
    set_segment("bottom_left_vertical", left, bottom - corner, thickness, corner)
    set_segment("bottom_right_horizontal", right - corner, bottom - thickness, corner, thickness)
    set_segment("bottom_right_vertical", right - thickness, bottom - corner, thickness, corner)

    widget.content.visible = true
    widget.content.label = mod:localize("hud_target_lock_marker")
    widget.style.label.size[1] = box_width + 24
    widget.style.label.offset[1] = left - 12
    widget.style.label.offset[2] = top - 27
    widget.style.label.text_color = { alpha, 255, 48, 38 }
end

HudElementVersusMode._refresh_enemy_status = function(self)
    local data = mod.controlled_enemy_status_data and mod.controlled_enemy_status_data()
    local widget_names = {
        "enemy_background",
        "enemy_portrait",
        "enemy_name",
        "enemy_health_background",
        "enemy_health_fill",
        "enemy_health_text",
    }

    for _, name in ipairs(widget_names) do
        self._widgets_by_name[name].content.visible = data ~= nil
    end

    if not data then
        return
    end

    self:set_scenegraph_position("enemy_status_panel", setting("enemy_panel_x"), setting("enemy_panel_y"))

    self._widgets_by_name.enemy_portrait.content.portrait = data.portrait
    self._widgets_by_name.enemy_name.content.name = data.name
    self._widgets_by_name.enemy_health_text.content.health = string.format("%d / %d", math.floor(data.current_health + 0.5), math.floor(data.max_health + 0.5))

    local fill_style = self._widgets_by_name.enemy_health_fill.style.fill

    fill_style.size[1] = math_max(1, math.floor(ENEMY_HEALTH_WIDTH * data.health_percent + 0.5))

    if data.health_percent <= 0.2 then
        fill_style.color = { 255, 225, 60, 55 }
    elseif data.health_percent <= 0.5 then
        fill_style.color = { 255, 235, 175, 65 }
    else
        fill_style.color = { 255, 115, 215, 125 }
    end
end

HudElementVersusMode._set_versus_mode_line = function(self, index, value, kind, opacity)
    local panel = self._widgets_by_name.panel
    local id = "line_" .. index

    if self._versus_mode_line_cache[index] ~= value then
        panel.content[id] = value
        self._versus_mode_line_cache[index] = value
    end

    panel.style[id].text_color = hud_color_with_opacity(HUD_COLORS[kind] or HUD_COLORS.normal, opacity)
    panel.style[id .. "_shadow"].text_color = hud_color_with_opacity(HUD_COLORS.shadow, opacity)
end

HudElementVersusMode._refresh_versus_mode = function(self)
    local panel = self._widgets_by_name.panel
    local data = mod.control_hud_data and mod.control_hud_data()

    if not data then
        panel.content.visible = false
        self._widgets_by_name.crosshair.content.visible = false

        return
    end

    panel.content.visible = true

    local crosshair = self._widgets_by_name.crosshair
    local opacity = setting("hud_text_opacity") / 100

    crosshair.content.visible = data.show_crosshair or false

    if crosshair.content.visible then
        crosshair.style.crosshair.text_color = hud_color_with_opacity(HUD_COLORS[data.crosshair_kind] or HUD_COLORS.normal, opacity)
    end

    local x = setting("hud_x")
    local y = setting("hud_y")
    local font_size = setting("hud_font_size")
    local line_height = font_size + 7

    self:set_scenegraph_position("versus_mode_hud", x, y)

    for i = 1, HUD_MAX_LINES do
        local id = "line_" .. i

        panel.style[id].font_size = font_size
        panel.style[id].offset[2] = (i - 1) * line_height
        panel.style[id .. "_shadow"].font_size = font_size
        panel.style[id .. "_shadow"].offset[2] = (i - 1) * line_height + 2
    end

    local distance = data.target_distance and mod:localize("hud_distance_suffix", data.target_distance) or ""
    local target_kind = data.locked and "locked" or "auto"
    local status_kind = data.status_kind or (data.status == mod:localize("hud_state_ready") and "ready" or "busy")
    local header = data.header or mod:localize("hud_header_versus_mode")
    local target_label = data.target_label or mod:localize("hud_target")

    self:_set_versus_mode_line(1, header .. " — " .. data.boss_name, "header", opacity)
    self:_set_versus_mode_line(2, mod:localize("hud_target_line", target_label, data.target_mode, data.target_name, distance), target_kind, opacity)

    local line_index = 3

    for _, action_line in ipairs(data.action_lines or {}) do
        if line_index >= HUD_MAX_LINES then
            break
        end

        self:_set_versus_mode_line(line_index, mod:localize("hud_action_line", action_line.label, action_line.text), action_line.kind or "normal", opacity)
        line_index = line_index + 1
    end

    self:_set_versus_mode_line(line_index, mod:localize("hud_status_line", data.status), status_kind, opacity)
    line_index = line_index + 1

    for i = line_index, HUD_MAX_LINES do
        self:_set_versus_mode_line(i, "", "normal", opacity)
    end
end

HudElementVersusMode.update = function(self, dt, t, ui_renderer, render_settings, input_service)
    HudElementVersusMode.super.update(self, dt, t, ui_renderer, render_settings, input_service)

    self:_refresh_sniper_scope()
    self:_refresh_grenade_trajectory(ui_renderer)
    self:_refresh_traversal_highlight(ui_renderer)
    self:_refresh_target_lock_marker(ui_renderer, t)

    self._versus_mode_refresh_timer = self._versus_mode_refresh_timer - dt

    if self._versus_mode_refresh_timer <= 0 then
        self._versus_mode_refresh_timer = 0.1
        self:_refresh_versus_mode()
        self:_refresh_enemy_status()
    end
end

mod._embedded_hud_class = HudElementVersusMode

mod:register_hud_element({
    class_name = "HudElementVersusMode",
    filename = EMBEDDED_HUD_MODULE,
    use_hud_scale = true,
    visibility_groups = {
        "alive",
    },
})
