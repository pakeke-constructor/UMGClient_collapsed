

local oks = {
    "getMaxSourceEffects",
    "isEffectsSupported",
    "setMixWithSystem",
    "stop",
    "getPlaybackDevices",
    "setPlaybackDevice",
    "getPlaybackDevice",
    "setEffect",
    "getActiveEffects",
    "getActiveSourceCount",
    "play",
    "pause",
    "setVolume",
    "getVolume",
    "setOrientation",
    "getOrientation",
    "setVelocity",
    "getVelocity",
    "setDopplerScale",
    "getDopplerScale",
    "setDistanceModel",
    "getDistanceModel",
    "getRecordingDevices",
    "setPosition",
    "getEffect",
    "getPosition",
    "getMaxSceneEffects"
}



return function(lobj)
    local audio = {}

    for _,key in ipairs(oks) do
        assert(love.audio, "wot?")
        audio[key] = love.audio[key]
    end

    function audio.newSource(a,...)
        if type(a) == "string"  then
            -- its a filename, convert first arg to filedata in local region
            local path = a
            local filedata = lobj.fsysObj:newFileData(path)
            return love.audio.newSource(filedata, ...)
        end

        return love.audio.newSource(a,...) -- a is not a path, so OK.
    end

    audio.newQueueableSource = love.audio.newQueueableSource

    return audio
end

