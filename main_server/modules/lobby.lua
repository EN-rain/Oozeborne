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
local DEFAULT_PLAYER_SPEED = 100.0
local DEFAULT_DASH_SPEED = 400.0
local SNAP_THRESHOLD = 50.0
local MIN_PLAYERS_TO_START = 1
local PLAYER_RADIUS = 6.0
local ATTACK_COOLDOWN_MS = 500  -- Minimum ms between attacks
local ATTACK_RANGE = 60.0     -- Max distance from player to attack origin
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
    -- Players do not collide with each other
    return false
end

local function resolve_remaining_overlaps(state)
    -- Players do not collide with each other, skip overlap resolution
    return
end

-- Admin role constants
local ADMIN_ROLE = {
    NONE = 0,
    MODERATOR = 1,
    ADMIN = 2,
    SUPER_ADMIN = 3
}

-- Check if user has admin role from their storage/metadata
local function get_user_admin_role(user_id)
    local admin_role = ADMIN_ROLE.NONE
    
    -- Try to read from user storage
    local ok, objects = pcall(nk.storage_read, {
        {collection = "user_roles", key = user_id}
    })
    
    if ok and objects and #objects > 0 then
        local data = objects[1].value
        if data and data.role then
            admin_role = data.role
        end
    end
    
    -- Also check user metadata as fallback
    local ok2, users = pcall(nk.users_get_id, {user_id})
    if ok2 and users and #users > 0 then
        local user = users[1]
        if user.metadata and user.metadata.admin_role then
            admin_role = math.max(admin_role, tonumber(user.metadata.admin_role) or 0)
        end
    end
    
    if admin_role > ADMIN_ROLE.NONE then
        nk.logger_info("User " .. user_id .. " has admin role: " .. tostring(admin_role))
    end
    
    return admin_role
end

-- Check if user can perform admin actions
local function is_admin(player)
    return player and (player.is_host or (player.admin_role and player.admin_role >= ADMIN_ROLE.ADMIN))
end

-- Check if user can perform moderator actions
local function is_moderator(player)
    return player and (player.is_host or (player.admin_role and player.admin_role >= ADMIN_ROLE.MODERATOR))
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
            -- Skip server-side movement for dashing players.
            -- The client is authoritative for dash movement (uses move_and_slide
            -- with wall collisions). Server just relays the client position.
            if player.is_dashing then
                -- Use velocity direction to estimate position, but clamp to world
                local proposed_x = player.pos_x + player.vel_x * dt
                local proposed_y = player.pos_y + player.vel_y * dt
                player.pos_x = math.max(WORLD_MIN_X, math.min(WORLD_MAX_X, proposed_x))
                player.pos_y = math.max(WORLD_MIN_Y, math.min(WORLD_MAX_Y, proposed_y))
            else
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
        local admin_role = get_user_admin_role(gamestate.host_user_id)
        gamestate.players[gamestate.host_user_id] = {
            pos_x = spawn_x,
            pos_y = spawn_y,
            vel_x = 0.0,
            vel_y = 0.0,
            facing = 1,
            ign = setupstate.host_ign or "",
            is_host = true,
            admin_role = admin_role,
            input_seq = 0,
            is_attacking = false,
            is_dashing = false,
            attack_rotation = 0.0,
            attack_seq = 0,
            dash_seq = 0,
            slime_variant = "blue",
            speed = DEFAULT_PLAYER_SPEED,
            dash_speed = DEFAULT_DASH_SPEED,
            last_attack_time = 0,
            attack_damage = 10
        }
        nk.logger_info("match_init host=" .. gamestate.host_user_id .. " spawn=" .. spawn_x .. "," .. spawn_y .. " admin_role=" .. tostring(admin_role))
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
    
    local admin_role = get_user_admin_role(presence.user_id)
    state.players[presence.user_id] = {
        pos_x = spawn_x,
        pos_y = spawn_y,
        vel_x = existing.vel_x or 0.0,
        vel_y = existing.vel_y or 0.0,
        facing = existing.facing or 1,
        ign = requested_ign,
        is_host = presence.user_id == state.host_user_id,
        admin_role = admin_role,
        input_seq = existing.input_seq or 0,
        is_attacking = existing.is_attacking or false,
        is_dashing = existing.is_dashing or false,
        attack_rotation = existing.attack_rotation or 0.0,
        attack_seq = existing.attack_seq or 0,
        dash_seq = existing.dash_seq or 0,
        slime_variant = existing.slime_variant or "blue",
        speed = existing.speed or DEFAULT_PLAYER_SPEED,
        dash_speed = existing.dash_speed or DEFAULT_DASH_SPEED
    }
    nk.logger_info("match_join_attempt user=" .. presence.user_id .. " ign=" .. requested_ign .. " is_host=" .. tostring(state.players[presence.user_id].is_host) .. " admin_role=" .. tostring(admin_role) .. " spawn=" .. spawn_x .. "," .. spawn_y)
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
                attack_rotation = 0.0,
                attack_seq = 0,
                dash_seq = 0,
                slime_variant = "blue",
                speed = DEFAULT_PLAYER_SPEED,
                dash_speed = DEFAULT_DASH_SPEED,
                last_attack_time = 0,
                attack_damage = 10
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
                local speed = player.speed or DEFAULT_PLAYER_SPEED
                if input.is_dashing then
                    speed = player.dash_speed or DEFAULT_DASH_SPEED
                end
                player.vel_x, player.vel_y = move_x * speed, move_y * speed
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
                if input.attack_seq and input.attack_seq > (player.attack_seq or 0) then
                    player.attack_seq = input.attack_seq
                end
                if input.dash_seq and input.dash_seq > (player.dash_seq or 0) then
                    player.dash_seq = input.dash_seq
                end
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
            nk.logger_info("Received op_code=0 message type=" .. (info and info.type or "nil") .. " from=" .. message.sender.user_id)
            if info and state.players[message.sender.user_id] then
                if info.type == "player_info" then
                    -- Update the TARGET player (from data.user_id), not the sender
                    local target_id = info.user_id or message.sender.user_id
                    if state.players[target_id] then
                        local target_player = state.players[target_id]
                        if info.ign and info.ign ~= "" then target_player.ign = info.ign end
                        if info.slime_variant and info.slime_variant ~= "" then target_player.slime_variant = info.slime_variant end
                        if info.speed and info.speed > 0 then target_player.speed = info.speed end
                        if info.dash_speed and info.dash_speed > 0 then target_player.dash_speed = info.dash_speed end
                        if info.is_host == true then
                            state.host_user_id = target_id
                        end
                        target_player.is_host = target_id == state.host_user_id
                    end
                    -- Relay player_info to all other clients so they see correct names
                    dispatcher.broadcast_message(0, message.data)
                elseif info.type == "chat_message" then
                    -- Relay chat messages to all players
                    nk.logger_info("Relaying chat_message: sender=" .. tostring(info.sender) .. " message=" .. tostring(info.message))
                    dispatcher.broadcast_message(0, nk.json_encode({
                        type = "chat_message",
                        sender = info.sender,
                        message = info.message
                    }))
                elseif info.type == "player_attack" then
                    -- Validate attack: cooldown + range check
                    local sender_player = state.players[message.sender.user_id]
                    if sender_player then
                        local now = nk.time() * 1000  -- ms
                        local time_since_last = now - (sender_player.last_attack_time or 0)
                        if time_since_last >= ATTACK_COOLDOWN_MS then
                            -- Validate attack position is within range of player
                            local ax = tonumber(info.attack_x) or sender_player.pos_x
                            local ay = tonumber(info.attack_y) or sender_player.pos_y
                            local dx = ax - sender_player.pos_x
                            local dy = ay - sender_player.pos_y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist <= ATTACK_RANGE then
                                sender_player.last_attack_time = now
                                -- Broadcast validated attack with damage
                                dispatcher.broadcast_message(0, nk.json_encode({
                                    type = "player_attack",
                                    user_id = message.sender.user_id,
                                    attack_x = ax,
                                    attack_y = ay,
                                    attack_rotation = info.attack_rotation or 0.0,
                                    attack_seq = info.attack_seq or 0,
                                    damage = sender_player.attack_damage or 10
                                }))
                            else
                                nk.logger_info("Attack rejected: out of range dist=" .. tostring(dist))
                            end
                        else
                            nk.logger_info("Attack rejected: cooldown remaining=" .. tostring(ATTACK_COOLDOWN_MS - time_since_last))
                        end
                    end
                elseif info.type == "enemy_hit" then
                    -- Relay enemy damage events to all other clients for sync
                    local sender_player = state.players[message.sender.user_id]
                    if sender_player then
                        dispatcher.broadcast_message(0, nk.json_encode({
                            type = "enemy_hit",
                            user_id = message.sender.user_id,
                            enemy_x = tonumber(info.enemy_x) or 0,
                            enemy_y = tonumber(info.enemy_y) or 0,
                            damage = tonumber(info.damage) or 1,
                            hit_seq = tonumber(info.hit_seq) or 0
                        }))
                    end
                elseif info.type == "lobby_name" or info.type == "request_players" or info.type == "class_selected" or info.type == "player_loaded" then
                    -- Update slime_variant from class_selected
                    if info.type == "class_selected" and info.user_id and state.players[info.user_id] then
                        if info.slime_variant and info.slime_variant ~= "" then
                            state.players[info.user_id].slime_variant = info.slime_variant
                        end
                    end
                    -- Relay these message types to all players
                    dispatcher.broadcast_message(0, message.data)
                elseif info.type == "admin_action" then
                    -- Admin actions - check if sender has admin privileges
                    local sender = state.players[message.sender.user_id]
                    if is_admin(sender) then
                        nk.logger_info("Admin action: " .. tostring(info.action) .. " from " .. message.sender.user_id .. " (admin_role=" .. tostring(sender.admin_role) .. ")")
                        if info.action == "kick" then
                            -- Kick player from match
                            local target_id = info.target_user_id
                            if state.players[target_id] then
                                dispatcher.broadcast_message(0, nk.json_encode({
                                    type = "admin_action",
                                    action = "kicked",
                                    target_user_id = target_id,
                                    reason = info.reason or ""
                                }))
                                state.players[target_id] = nil
                            end
                        elseif info.action == "ban" then
                            -- Ban player (kick + store ban)
                            local target_id = info.target_user_id
                            if state.players[target_id] then
                                -- Store ban in user storage
                                nk.storage_write({
                                    {collection = "bans", key = target_id, value = {banned = true, reason = info.reason or "", banned_by = message.sender.user_id}}
                                })
                                dispatcher.broadcast_message(0, nk.json_encode({
                                    type = "admin_action",
                                    action = "banned",
                                    target_user_id = target_id,
                                    reason = info.reason or ""
                                }))
                                state.players[target_id] = nil
                            end
                        elseif info.action == "change_host" then
                            -- Change host
                            local new_host = info.target_user_id
                            if state.players[new_host] then
                                state.host_user_id = new_host
                                state.players[new_host].is_host = true
                                if state.players[message.sender.user_id] then
                                    state.players[message.sender.user_id].is_host = false
                                end
                                dispatcher.broadcast_message(0, nk.json_encode({
                                    type = "admin_action",
                                    action = "host_changed",
                                    new_host_id = new_host
                                }))
                            end
                        elseif info.action == "force_start" then
                            -- Force start game
                            state.phase = "in_game"
                            dispatcher.broadcast_message(5, nk.json_encode({type = "force_start"}))
                        elseif info.action == "close_lobby" then
                            -- Close lobby - kick all players
                            dispatcher.broadcast_message(0, nk.json_encode({
                                type = "admin_action",
                                action = "lobby_closed",
                                reason = info.reason or "Admin closed lobby"
                            }))
                            state.players = {}
                        elseif info.action == "teleport" then
                            -- Teleport player
                            dispatcher.broadcast_message(0, nk.json_encode({
                                type = "admin_action",
                                action = "teleport",
                                target_user_id = info.target_user_id,
                                x = info.x,
                                y = info.y
                            }))
                        elseif info.action == "set_role" then
                            -- Set player role (super admin only)
                            if sender.admin_role and sender.admin_role >= ADMIN_ROLE.SUPER_ADMIN then
                                local target_id = info.target_user_id
                                local new_role = info.role or 0
                                if state.players[target_id] then
                                    state.players[target_id].admin_role = new_role
                                    nk.storage_write({
                                        {collection = "user_roles", key = target_id, value = {role = new_role}}
                                    })
                                    dispatcher.broadcast_message(0, nk.json_encode({
                                        type = "admin_action",
                                        action = "role_set",
                                        target_user_id = target_id,
                                        role = new_role
                                    }))
                                end
                            end
                        end
                    else
                        nk.logger_warn("Unauthorized admin action attempt from " .. message.sender.user_id)
                    end
                elseif info.type == "admin_broadcast" then
                    -- Admin broadcast - relay to all players
                    dispatcher.broadcast_message(0, nk.json_encode({
                        type = "chat_message",
                        sender = info.sender or "ADMIN",
                        message = info.message
                    }))
                end
            else
                nk.logger_warn("op_code=0 message from unknown player or invalid data")
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
                attack_rotation = p.attack_rotation or 0.0,
                attack_seq = p.attack_seq or 0,
                dash_seq = p.dash_seq or 0,
                slime_variant = p.slime_variant or "blue",
                speed = p.speed or DEFAULT_PLAYER_SPEED,
                dash_speed = p.dash_speed or DEFAULT_DASH_SPEED
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
