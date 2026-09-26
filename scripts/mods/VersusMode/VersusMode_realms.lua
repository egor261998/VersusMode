local mod = get_mod("VersusMode")

local RealmsBridge = {}

local PROTOCOL_VERSION = 1
local HELLO_RETRY_INTERVAL = 2
local RPC_HELLO = "vm_hello"
local RPC_LOBBY_PLAN = "vm_lobby_plan"
local RPC_ROSTER = "vm_roster"
local RPC_SPAWN = "vm_spawn"
local RPC_INPUT = "vm_input"
local RPC_ACTION = "vm_action"
local RPC_CONTROL = "vm_control"
local RPC_STATUS = "vm_status"
local RPC_ANIMATION = "vm_animation"
local RPC_RELEASE = "vm_release"

local realms
local handlers
local compatible_peers = {}
local hello_acknowledged = false
local next_hello_at = 0
local phase_key
local last_host_peer_id

local function normalize_peer_id(peer_id)
    return peer_id and string.lower(tostring(peer_id)) or nil
end

local function connection()
    return Managers.connection
end

local function preparation_role()
    local preparation = realms and realms._preparation
    local ok, role = pcall(function()
        return preparation and preparation.role and preparation.role()
    end)

    return ok and role or nil
end

local function is_connection_host()
    local current = connection()

    if current and current:is_host() then
        return true
    end

    return preparation_role() == "host"
end

local function is_connection_client()
    local current = connection()

    if current and current:is_client() then
        return true
    end

    return preparation_role() == "client"
end

local function is_host()
    local game_session = Managers.state and Managers.state.game_session

    return is_connection_host()
        and game_session
        and game_session:is_server()
        or false
end

local function is_client()
    return is_connection_client()
end

local function host_peer_id()
    local current = connection()
    local current_host = current and current:is_client() and normalize_peer_id(current:host()) or nil

    last_host_peer_id = current_host or last_host_peer_id

    return last_host_peer_id
end

local function from_host(sender_peer_id)
    local expected = host_peer_id()

    return expected and normalize_peer_id(sender_peer_id) == expected or false
end

local function valid_payload(payload)
    return type(payload) == "table" and payload.protocol == PROTOCOL_VERSION
end

local function invoke(name, ...)
    local handler = handlers and handlers[name]

    if handler then
        return handler(...)
    end
end

local function register_rpc(name, callback)
    local registered, register_error = realms.network_register(mod, name, callback)

    if not registered then
        mod:error("Versus Mode: failed registering Realms RPC %s: %s", name, tostring(register_error))
    end

    return registered
end

local function send(name, recipient, payload)
    if not realms or not realms.network_is_available or not realms.network_is_available() then
        return false, "Realms mod networking is unavailable"
    end

    payload = payload or {}
    payload.protocol = PROTOCOL_VERSION

    return realms.network_send(mod, name, recipient, payload)
end

local function receive_hello(sender_peer_id, payload)
    if not is_connection_host() or not valid_payload(payload) then
        return
    end

    local peer_id = normalize_peer_id(sender_peer_id)
    local compatible = payload.version == mod.version and payload.enabled == true

    compatible_peers[peer_id] = {
        compatible = compatible,
        enabled = payload.enabled == true,
        version = tostring(payload.version or "unknown"),
    }

    mod:info(
        "Versus Mode: client handshake %s (version %s, Heretic role %s, compatible %s).",
        tostring(peer_id),
        compatible_peers[peer_id].version,
        compatible_peers[peer_id].enabled and "enabled" or "disabled",
        compatible and "yes" or "no"
    )

    invoke("client_ready", peer_id, compatible, compatible_peers[peer_id])
end

local function receive_lobby_plan(sender_peer_id, payload)
    if not is_connection_client() or not from_host(sender_peer_id) or not valid_payload(payload) then
        return
    end

    hello_acknowledged = true
    invoke("lobby_plan", payload)
end

local function receive_roster(sender_peer_id, payload)
    if not is_client() or not from_host(sender_peer_id) or not valid_payload(payload) then
        return
    end

    hello_acknowledged = true
    mod:info(
        "Versus Mode: received Heretic roster revision %s with %d roles.",
        tostring(payload.revision or "unknown"),
        type(payload.roles) == "table" and #payload.roles or 0
    )
    invoke("roster", payload)
end

local function receive_spawn(sender_peer_id, payload)
    if is_host() and valid_payload(payload) then
        invoke("spawn", normalize_peer_id(sender_peer_id), payload)
    end
end

local function receive_input(sender_peer_id, payload)
    if is_host() and valid_payload(payload) then
        invoke("input", normalize_peer_id(sender_peer_id), payload)
    end
end

local function receive_action(sender_peer_id, payload)
    if is_host() and valid_payload(payload) then
        invoke("action", normalize_peer_id(sender_peer_id), payload)
    end
end

local function receive_control(sender_peer_id, payload)
    if is_client() and from_host(sender_peer_id) and valid_payload(payload) then
        invoke("control", payload)
    end
end

local function receive_status(sender_peer_id, payload)
    if is_client() and from_host(sender_peer_id) and valid_payload(payload) then
        invoke("status", payload)
    end
end

local function receive_animation(sender_peer_id, payload)
    if is_client() and from_host(sender_peer_id) and valid_payload(payload) then
        invoke("animation", payload)
    end
end

local function receive_release(sender_peer_id, payload)
    if is_client() and from_host(sender_peer_id) and valid_payload(payload) then
        invoke("release", payload)
    end
end

function RealmsBridge.install(callbacks)
    handlers = callbacks or {}
    realms = get_mod("Realms")

    if not realms
        or type(realms.network_register) ~= "function"
        or type(realms.network_send) ~= "function"
        or type(realms.network_is_available) ~= "function"
        or type(realms.network_on_peer_joined) ~= "function"
        or type(realms.network_on_peer_left) ~= "function" then
        realms = nil
        mod:info("Versus Mode: Realms 0.6.1 mod-network API not found; SoloPlay support remains active.")

        return false
    end

    local registered = register_rpc(RPC_HELLO, receive_hello)
        and register_rpc(RPC_LOBBY_PLAN, receive_lobby_plan)
        and register_rpc(RPC_ROSTER, receive_roster)
        and register_rpc(RPC_SPAWN, receive_spawn)
        and register_rpc(RPC_INPUT, receive_input)
        and register_rpc(RPC_ACTION, receive_action)
        and register_rpc(RPC_CONTROL, receive_control)
        and register_rpc(RPC_STATUS, receive_status)
        and register_rpc(RPC_ANIMATION, receive_animation)
        and register_rpc(RPC_RELEASE, receive_release)

    if not registered then
        realms = nil

        return false
    end

    realms.network_on_peer_joined(mod, function(peer_id)
        peer_id = normalize_peer_id(peer_id)

        if is_connection_client() and peer_id == host_peer_id() then
            hello_acknowledged = false
            next_hello_at = 0
        end

        invoke("peer_joined", peer_id)
    end)

    realms.network_on_peer_left(mod, function(peer_id)
        peer_id = normalize_peer_id(peer_id)
        local departed_host = is_connection_client() and peer_id == host_peer_id()

        compatible_peers[peer_id] = nil

        if departed_host then
            hello_acknowledged = false
        end

        invoke("peer_left", peer_id, departed_host)
    end)

    mod:info("Versus Mode: Realms network bridge registered (protocol %d).", PROTOCOL_VERSION)

    return true
end

function RealmsBridge.update(enabled)
    if not realms then
        return
    end

    local current = connection()
    local available = realms.network_is_available()
    local new_phase_key = available and (current and tostring(current) or preparation_role()) or nil

    if new_phase_key ~= phase_key then
        phase_key = new_phase_key
        hello_acknowledged = false
        next_hello_at = 0

        -- Clear only after the transport actually disappears. Clearing again
        -- on the first available frame can race a preparation-phase hello that
        -- arrived just before this update, leaving an acknowledged client with
        -- no compatible host record.
        if not new_phase_key then
            table.clear(compatible_peers)
            last_host_peer_id = nil
        end
    end

    if not phase_key or not is_connection_client() or hello_acknowledged or not available then
        return
    end

    local t = Managers.time and Managers.time:time("main") or 0

    if t < next_hello_at then
        return
    end

    local sent = send(RPC_HELLO, "host", {
        enabled = enabled == true,
        version = mod.version,
    })

    if sent then
        next_hello_at = t + HELLO_RETRY_INTERVAL
    end
end

function RealmsBridge.reset_client_hello()
    hello_acknowledged = false
    next_hello_at = 0
end

function RealmsBridge.available()
    return realms and realms.network_is_available and realms.network_is_available() or false
end

function RealmsBridge.is_host()
    return realms ~= nil and is_host()
end

function RealmsBridge.is_client()
    return realms ~= nil and is_client()
end

function RealmsBridge.is_connection_host()
    return realms ~= nil and is_connection_host()
end

function RealmsBridge.is_connection_client()
    return realms ~= nil and is_connection_client()
end

function RealmsBridge.peer_compatible(peer_id)
    local peer = compatible_peers[normalize_peer_id(peer_id)]

    return peer and peer.compatible == true or false
end

function RealmsBridge.peer_status(peer_id)
    return compatible_peers[normalize_peer_id(peer_id)]
end

function RealmsBridge.send_roster(payload, recipient)
    return send(RPC_ROSTER, recipient or "others", payload)
end

function RealmsBridge.send_lobby_plan(payload, recipient)
    return send(RPC_LOBBY_PLAN, recipient or "others", payload)
end

function RealmsBridge.request_spawn(payload)
    return send(RPC_SPAWN, "host", payload)
end

function RealmsBridge.send_input(payload)
    return send(RPC_INPUT, "host", payload)
end

function RealmsBridge.send_action(action, sequence, extra)
    local payload = {
        action = action,
        sequence = sequence,
    }

    -- Action metadata is intentionally whitelisted instead of merging an
    -- arbitrary client table into the RPC payload.
    if extra and type(extra.target_unit_id) == "number" then
        payload.target_unit_id = extra.target_unit_id
    end

    if extra and type(extra.hound_aim_yaw) == "number" and type(extra.hound_aim_pitch) == "number" then
        payload.hound_aim_yaw = extra.hound_aim_yaw
        payload.hound_aim_pitch = extra.hound_aim_pitch
    end

    if extra and type(extra.hound_charge_fraction) == "number" then
        payload.hound_charge_fraction = math.max(0, math.min(1, extra.hound_charge_fraction))
    end

    if extra and type(extra.spawn_breed) == "string" then
        payload.spawn_breed = extra.spawn_breed
    end
    if extra and type(extra.spawn_variant) == "string" then
        payload.spawn_variant = extra.spawn_variant
    end
    if extra and type(extra.picker_open) == "boolean" then
        payload.picker_open = extra.picker_open
    end

    return send(RPC_ACTION, "host", payload)
end

function RealmsBridge.assign_control(peer_id, payload)
    return send(RPC_CONTROL, peer_id, payload)
end

function RealmsBridge.send_status(peer_id, payload)
    return send(RPC_STATUS, peer_id, payload)
end

function RealmsBridge.send_animation(peer_id, payload)
    return send(RPC_ANIMATION, peer_id, payload)
end

function RealmsBridge.release_control(peer_id, reason, controlled_unit_dead)
    return send(RPC_RELEASE, peer_id, {
        controlled_unit_dead = controlled_unit_dead == true,
        reason = reason,
    })
end

return RealmsBridge
