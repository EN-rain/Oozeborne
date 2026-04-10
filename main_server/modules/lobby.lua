local nk = require("nakama")

local M = {}

-- Op codes
local OP_INPUT = 1
local OP_STATE = 2
local OP_PLAYER_JOIN = 3
local OP_PLAYER_LEAVE = 4
local OP_START_GAME = 5

-- Constants
local TICKRATE = 20
local PLAYER_SPEED = 100.0
local SNAP_THRESHOLD = 50.0
local MIN_PLAYERS_TO_START = 2
local PLAYER_RADIUS = 6.0
local PLAYER_SEPARATION_EPSILON = 0.01
local WORLD_MIN_X = 0.0
local WORLD_MAX_X = 800.0
local WORLD_MIN_Y = 0.0
local WORLD_MAX_Y = 600.0
local SPAWN_POINTS = {
    {x = 360.0, y = 300.0},
    {x = 440.0, y = 300.0},
    {x = 400.0, y = 240.0},
    {x = 400.0, y = 360.0}
}

local function clamp_player_to_world(player)
    player.pos_x = math.max(WORLD_MIN_X, math.min(WORLD_MAX_X, player.pos_x))
    player.pos_y = math.max(WORLD_MIN_Y, math.min(WORLD_MAX_Y, player.pos_y))
end

local function get_spawn_point_for_index(index)
    local spawn = SPAWN_POINTS[((index - 1) % #SPAWN_POINTS) + 1]
    return spawn.x, spawn.y
end

local function get_next_spawn_point(state)
    local player_count = 0
    for _, _ in pairs(state.players) do
        player_count = player_count + 1
    end
    return get_spawn_point_for_index(player_count + 1)
end

local function log_player_positions(context, state, prefix)
    local parts = {}
    for user_id, player in pairs(state.players) do
        table.insert(parts, user_id:sub(1, 8) .. "=" .. math.floor(player.pos_x + 0.5) .. "," .. math.floor(player.pos_y + 0.5))
    end
    table.sort(parts)
    nk.logger_info(prefix .. " match=" .. context.match_id .. " players=[" .. table.concat(parts, " | ") .. "]")
end

local function is_overlapping(player_a, player_b)
    local dx = player_a.pos_x - player_b.pos_x
    local dy = player_a.pos_y - player_b.pos_y
    local min_distance = PLAYER_RADIUS * 2.0
    return (dx * dx + dy * dy) < (min_distance * min_distance)
end

local function would_cross_player(start_x, start_y, end_x, end_y, other_player)
    local seg_x = end_x - start_x
    local seg_y = end_y - start_y
    local seg_len_sq = seg_x * seg_x + seg_y * seg_y
    local radius = PLAYER_RADIUS * 2.0

    if seg_len_sq <= PLAYER_SEPARATION_EPSILON then
        local dx = end_x - other_player.pos_x
        local dy = end_y - other_player.pos_y
        return (dx * dx + dy * dy) < (radius * radius)
    end

    local to_other_x = other_player.pos_x - start_x
    local to_other_y = other_player.pos_y - start_y
    local t = (to_other_x * seg_x + to_other_y * seg_y) / seg_len_sq
    t = math.max(0.0, math.min(1.0, t))

    local closest_x = start_x + seg_x * t
    local closest_y = start_y + seg_y * t
    local dx = closest_x - other_player.pos_x
    local dy = closest_y - other_player.pos_y
    return (dx * dx + dy * dy) < (radius * radius)
end

local function is_blocked_by_any_player(state, moving_user_id, start_x, start_y, end_x, end_y)
    local probe = { pos_x = end_x, pos_y = end_y }
    for other_id, other in pairs(state.players) do
        if other_id ~= moving_user_id and other then
            if is_overlapping(probe, other) or would_cross_player(start_x, start_y, end_x, end_y, other) then
                return true
            end
        end
    end
    return false
end

local function resolve_remaining_overlaps(state)
    local player_ids = {}
    for user_id, _ in pairs(state.players) do
        table.insert(player_ids, user_id)
    end

    table.sort(player_ids)

    for i = 1, #player_ids do
        local player_a = state.players[player_ids[i]]
        if player_a then
            for j = i + 1, #player_ids do
                local player_b = state.players[player_ids[j]]
                if player_b and is_overlapping(player_a, player_b) then
                    local dx = player_a.pos_x - player_b.pos_x
                    local dy = player_a.pos_y - player_b.pos_y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    local min_distance = PLAYER_RADIUS * 2.0

                    local nx = 1.0
                    local ny = 0.0
                    if distance > PLAYER_SEPARATION_EPSILON then
                        nx = dx / distance
                        ny = dy / distance
                    end

                    local overlap = min_distance - distance + PLAYER_SEPARATION_EPSILON
                    local correction = overlap * 0.5

                    player_a.pos_x = player_a.pos_x + nx * correction
                    player_a.pos_y = player_a.pos_y + ny * correction
                    player_b.pos_x = player_b.pos_x - nx * correction
                    player_b.pos_y = player_b.pos_y - ny * correction

                    clamp_player_to_world(player_a)
                    clamp_player_to_world(player_b)
                end
            end
        end
    end
end

local function move_players_with_blocking(state, dt)
    local player_ids = {}
    for user_id, _ in pairs(state.players) do
        table.insert(player_ids, user_id)
    end

    table.sort(player_ids)

    for _, user_id in ipairs(player_ids) do
        local player = state.players[user_id]
        if player then
            local previous_x = player.pos_x
            local previous_y = player.pos_y

            local proposed_x = previous_x + player.vel_x * dt
            proposed_x = math.max(WORLD_MIN_X, math.min(WORLD_MAX_X, proposed_x))
            if not is_blocked_by_any_player(state, user_id, previous_x, previous_y, proposed_x, previous_y) then
                player.pos_x = proposed_x
            else
                player.vel_x = 0.0
            end

            local current_x = player.pos_x
            local proposed_y = previous_y + player.vel_y * dt
            proposed_y = math.max(WORLD_MIN_Y, math.min(WORLD_MAX_Y, proposed_y))
            if not is_blocked_by_any_player(state, user_id, current_x, previous_y, current_x, proposed_y) then
                player.pos_y = proposed_y
            else
                player.vel_y = 0.0
            end

            clamp_player_to_world(player)
        end
    end

    resolve_remaining_overlaps(state)
end

function M.match_init(context, setupstate)
    local gamestate = {
        tick = 0,
        phase = "lobby",
        room_code = setupstate.room_code or "",
        host_user_id = setupstate.host_user_id or "",
        players = {}
    }

    if gamestate.host_user_id ~= "" then
        local spawn_x, spawn_y = get_spawn_point_for_index(1)
        gamestate.players[gamestate.host_user_id] = {
            pos_x = spawn_x,
            pos_y = spawn_y,
            vel_x = 0.0,
            vel_y = 0.0,
            facing = 1,
            ign = setupstate.host_ign or "",
            is_host = true,
            input_seq = 0,
            is_attacking = false,
            is_dashing = false,
            attack_rotation = 0.0
        }
        nk.logger_info("match_init host=" .. gamestate.host_user_id .. " spawn=" .. spawn_x .. "," .. spawn_y)
    end

    local label = "authoritative_game"
    nk.logger_info("Match initialized: " .. context.match_id)
    return gamestate, TICKRATE, label
end

function M.match_join_attempt(context, dispatcher, tick, state, presence, metadata)
    local requested_ign = presence.username
    if metadata and metadata.ign and metadata.ign ~= "" then
        requested_ign = metadata.ign
    end

    if state.host_user_id == "" then
        state.host_user_id = presence.user_id
        nk.logger_info("Host user id was empty, defaulting host to first joiner " .. presence.user_id)
    end

    local existing = state.players[presence.user_id] or {}
    local spawn_x = existing.pos_x
    local spawn_y = existing.pos_y
    if spawn_x == nil or spawn_y == nil then
        spawn_x, spawn_y = get_next_spawn_point(state)
    end
    state.players[presence.user_id] = {
        pos_x = spawn_x,
        pos_y = spawn_y,
        vel_x = existing.vel_x or 0.0,
        vel_y = existing.vel_y or 0.0,
        facing = existing.facing or 1,
        ign = requested_ign,
        is_host = presence.user_id == state.host_user_id,
        input_seq = existing.input_seq or 0,
        is_attacking = existing.is_attacking or false,
        is_dashing = existing.is_dashing or false,
        attack_rotation = existing.attack_rotation or 0.0
    }
    nk.logger_info("match_join_attempt user=" .. presence.user_id .. " ign=" .. requested_ign .. " is_host=" .. tostring(state.players[presence.user_id].is_host) .. " spawn=" .. spawn_x .. "," .. spawn_y)
    return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
    for _, p in ipairs(presences) do
        local player = state.players[p.user_id]
        if not player then
            local spawn_x, spawn_y = get_next_spawn_point(state)
            player = {
                pos_x = spawn_x, pos_y = spawn_y,
                vel_x = 0.0, vel_y = 0.0,
                facing = 1, ign = p.username,
                is_host = p.user_id == state.host_user_id,
                input_seq = 0,
                is_attacking = false, is_dashing = false,
                attack_rotation = 0.0
            }
            state.players[p.user_id] = player
        end

        local join_msg = nk.json_encode({
            user_id = p.user_id,
            ign = player.ign,
            is_host = player.is_host or false,
            pos = {x = player.pos_x, y = player.pos_y},
            phase = state.phase
        })
        nk.logger_info("match_join broadcast user=" .. p.user_id .. " spawn=" .. player.pos_x .. "," .. player.pos_y .. " phase=" .. state.phase)
        dispatcher.broadcast_message(OP_PLAYER_JOIN, join_msg)
    end
    return state
end

function M.match_leave(context, dispatcher, tick, state, presences)
    for _, p in ipairs(presences) do
        state.players[p.user_id] = nil
        dispatcher.broadcast_message(OP_PLAYER_LEAVE, nk.json_encode({user_id = p.user_id}))
    end
    return state
end

function M.match_loop(context, dispatcher, tick, state, messages)
    state.tick = tick

    for _, message in ipairs(messages) do
        if message.op_code == OP_INPUT then
            local input = nk.json_decode(message.data)
            if input and state.players[message.sender.user_id] then
                local player = state.players[message.sender.user_id]
                local move_x, move_y = input.move_x or 0, input.move_y or 0
                local len = math.sqrt(move_x * move_x + move_y * move_y)
                if len > 1.0 then move_x, move_y = move_x / len, move_y / len end
                player.vel_x, player.vel_y = move_x * PLAYER_SPEED, move_y * PLAYER_SPEED
                if input.facing ~= nil then
                    player.facing = input.facing
                elseif move_x > 0 then
                    player.facing = 1
                elseif move_x < 0 then
                    player.facing = -1
                end
                player.input_seq = input.seq or player.input_seq + 1
                player.is_attacking = input.is_attacking or false
                player.is_dashing = input.is_dashing or false
                player.attack_rotation = input.attack_rotation or 0.0
            end
        elseif message.op_code == OP_START_GAME then
            local sender_player = state.players[message.sender.user_id]
            local sender_is_host = sender_player and sender_player.is_host or false
            local player_count = 0
            for _ in pairs(state.players) do
                player_count = player_count + 1
            end
            nk.logger_info("OP_START_GAME received from " .. message.sender.user_id .. " host_user_id=" .. tostring(state.host_user_id) .. " sender_is_host=" .. tostring(sender_is_host))

            if message.sender.user_id == state.host_user_id or sender_is_host then
                if player_count < MIN_PLAYERS_TO_START then
                    nk.logger_warn("Ignoring OP_START_GAME for match " .. context.match_id .. " because player_count=" .. tostring(player_count))
                else
                state.host_user_id = message.sender.user_id
                if sender_player then
                    sender_player.is_host = true
                end
                state.phase = "in_game"
                local start_payload = nk.json_encode({
                    type = "start_game",
                    phase = state.phase,
                    started_by = message.sender.user_id
                })
                nk.logger_info("Host started game, switching match phase to in_game for match " .. context.match_id)
                log_player_positions(context, state, "start_game positions")
                dispatcher.broadcast_message(OP_START_GAME, start_payload)
                end
            else
                nk.logger_warn("Ignoring OP_START_GAME from non-host user " .. message.sender.user_id)
            end
        elseif message.op_code == 0 then
            local info = nk.json_decode(message.data)
            if info and state.players[message.sender.user_id] then
                local player = state.players[message.sender.user_id]
                if info.type == "player_info" then
                    if info.ign and info.ign ~= "" then player.ign = info.ign end
                    if info.is_host == true then
                        state.host_user_id = message.sender.user_id
                    end
                    player.is_host = message.sender.user_id == state.host_user_id
                elseif info.type == "chat_message" then
                    -- Relay chat messages to all players
                    dispatcher.broadcast_message(0, nk.json_encode({
                        type = "chat_message",
                        sender = info.sender,
                        message = info.message
                    }))
                elseif info.type == "lobby_name" or info.type == "request_players" or info.type == "class_selected" then
                    -- Relay these message types to all players
                    dispatcher.broadcast_message(0, message.data)
                end
            end
        end
    end

    local dt = 1.0 / TICKRATE
    move_players_with_blocking(state, dt)

    if tick <= 5 or (state.phase == "in_game" and tick % 20 == 0) then
        log_player_positions(context, state, "tick=" .. tick)
    end

    if next(state.players) then
        local snapshot = {
            tick = tick,
            timestamp = os.time(),
            phase = state.phase,
            host_user_id = state.host_user_id,
            players = {}
        }
        for uid, p in pairs(state.players) do
            table.insert(snapshot.players, {
                user_id = uid, pos = {x = p.pos_x, y = p.pos_y},
                vel = {x = p.vel_x, y = p.vel_y}, facing = p.facing,
                ign = p.ign, is_host = p.is_host or false,
                input_seq = p.input_seq or 0,
                is_attacking = p.is_attacking or false,
                is_dashing = p.is_dashing or false,
                attack_rotation = p.attack_rotation or 0.0
            })
        end
        dispatcher.broadcast_message(OP_STATE, nk.json_encode(snapshot))
    end

    return state
end

function M.match_terminate(context, dispatcher, tick, state, grace_seconds)
    return state
end

function M.match_signal(context, dispatcher, tick, state, data)
    return state, data
end

return M
