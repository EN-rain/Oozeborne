-- Room Registry RPC Module for Nakama
-- Uses in-memory registry for room code -> match_id mapping

local nk = require("nakama")
local MATCH_HANDLER_NAME = "lobby"

-- In-memory room registry (persists while server is running)
local room_registry = {}

-- RPC: Create room - creates match and stores room code
local function rpc_create_room(context, payload)
    nk.logger_info("create_room called with payload: " .. payload)
    
    local request = nk.json_decode(payload)
    local room_code = request.room_code
    local host_ign = request.host_ign
    
    if not room_code or room_code == "" then
        return nk.json_encode({error = "room code is required"})
    end
    
    -- Create an authoritative match using the lobby handler
    local match_id = nk.match_create(MATCH_HANDLER_NAME, {
        room_code = room_code,
        host_ign = host_ign,
        host_user_id = context.user_id
    })
    
    nk.logger_info("Created match: " .. match_id .. " for room: " .. room_code)
    
    -- Store in memory
    room_registry[room_code] = {
        match_id = match_id,
        host_ign = host_ign,
        created_at = os.time()
    }
    
    nk.logger_info("Room created: " .. room_code .. " -> match_id: " .. match_id)
    
    return nk.json_encode({
        match_id = match_id,
        success = true
    })
end

-- RPC: Join room by code - looks up match_id from registry
local function rpc_join_room(context, payload)
    nk.logger_info("join_room called with payload: " .. payload)
    
    local request = nk.json_decode(payload)
    local room_code = request.room_code
    
    if not room_code or room_code == "" then
        nk.logger_error("Room code is missing or empty")
        return nk.json_encode({error = "room code is required"})
    end
    
    local room_data = room_registry[room_code]
    
    if not room_data then
        nk.logger_error("Room not found: " .. room_code)
        return nk.json_encode({error = "room not found"})
    end
    
    nk.logger_info("Room found: " .. room_code .. " -> match_id: " .. room_data.match_id)
    
    return nk.json_encode({
        match_id = room_data.match_id,
        host_ign = room_data.host_ign
    })
end

-- RPC: Delete room - called when host disconnects
local function rpc_delete_room(context, payload)
    local request = nk.json_decode(payload)
    local room_code = request.room_code
    
    if not room_code or room_code == "" then
        return nk.json_encode({error = "room code is required"})
    end
    
    room_registry[room_code] = nil
    
    nk.logger_info("Room deleted: " .. room_code)
    
    return nk.json_encode({success = true})
end

-- Register RPC functions
nk.register_rpc(rpc_create_room, "create_room")
nk.register_rpc(rpc_join_room, "join_room")
nk.register_rpc(rpc_delete_room, "delete_room")

nk.logger_info("Room registry RPC module initialized (in-memory)")
