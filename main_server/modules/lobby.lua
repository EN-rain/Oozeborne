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

function M.match_init(context, setupstate)
    local gamestate = {
        tick = 0,
        phase = "lobby",
        room_code = setupstate.room_code or "",
        host_user_id = setupstate.host_user_id or "",
        players = {}
    }

    if gamestate.host_user_id ~= "" then
        gamestate.players[gamestate.host_user_id] = {
            pos_x = 400.0,
            pos_y = 300.0,
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
    state.players[presence.user_id] = {
        pos_x = existing.pos_x or 400.0,
        pos_y = existing.pos_y or 300.0,
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
    nk.logger_info("match_join_attempt user=" .. presence.user_id .. " ign=" .. requested_ign .. " is_host=" .. tostring(state.players[presence.user_id].is_host))
    return state, true
end

function M.match_join(context, dispatcher, tick, state, presences)
    for _, p in ipairs(presences) do
        local player = state.players[p.user_id]
        if not player then
            player = {
                pos_x = 400.0, pos_y = 300.0,
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
            nk.logger_info("OP_START_GAME received from " .. message.sender.user_id .. " host_user_id=" .. tostring(state.host_user_id) .. " sender_is_host=" .. tostring(sender_is_host))

            if message.sender.user_id == state.host_user_id or sender_is_host then
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
                dispatcher.broadcast_message(OP_START_GAME, start_payload)
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
                end
            end
        end
    end

    local dt = 1.0 / TICKRATE
    for _, player in pairs(state.players) do
        player.pos_x = math.max(0, math.min(800, player.pos_x + player.vel_x * dt))
        player.pos_y = math.max(0, math.min(600, player.pos_y + player.vel_y * dt))
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
