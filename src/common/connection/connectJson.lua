
--[[

Connect-Json:

"ConnectJson" is the json object that is sent from Client --> Server
when the client is first connecting to the server.

This file just serves to validate/correct stuff, 
as a single-source of truth.

What's unique, is that it's *not* sent through a Boxer packet.
It's sent as a raw string upon connecting.

Think of it like an "initial greeting."

ConnectJson payload:

{
    "connect": "connect", // (just a sanity-check flag; is constant.)

    "clientId": "93844859387567e596", // should be steam id
    "username": "playr_2334", // The display username

    // TODO, NYI- steam auth token.
    "auth": "0x309544546895656"
}

]]

local connectJson = tools.SafeTable()


local VALID_KEYS = {
    connect = true, 
    clientId = true, 
    username = true
}



local function parseUsername(username)
    -- Remove alphanumeric characters from username
    username = username:gsub(constants.INVALID_USERNAME_CHARACTERS,'')
    -- username can't be more than X characters:
    local maxSize = constants.MAX_USERNAME_LENGTH
    username = username:sub(1, math.min(#username, maxSize))
    return username
end


local function autoCorrect(connJson)
    connJson.username = parseUsername(connJson.username)
end


local function validate(connJson)
    --[[
        validates the connect-json;
        that is, the json that is sent from client -> server upon connecting.
        The json contains information about clientId, username, auth, etc.

    ]]
    if type(connJson) ~= "table" then
        return false, "connJson not table"
    end

    for k,v in pairs(connJson) do
        if not VALID_KEYS[k] then
            return false, "invalid key: " .. k
        end
    end

    if connJson.connect ~= "connect" then
        return false, "connJson had no .connect sanity-check flag"
    end

    if type(connJson.username) ~= "string" then
        return false, "connJson had no username"
    end
    if type(connJson.clientId) ~= "string" then
        return false, "connJson had no clientId"
    end

    return true -- OK!
end




function connectJson.serialize(tabl)
    assert(validate(tabl))
    autoCorrect(tabl)
    return json.encode(tabl)
end



function connectJson.tryDeserialize(jsonData)
    local ok, connJson = pcall(json.decode, jsonData)
    if not ok then
        log.error("couldn't decode json: ", connJson)
        return false
    end

    local ok2, er = validate(connJson)
    if not ok2 then
        log.error("Invalid connectJson: ", er)
        return false
    end

    return connJson
end




return connectJson
