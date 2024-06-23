
--[[

async_task object that recursively downloads mods.

]]


local ugch = require("src.common.ugc_handler.ugch")



local ModDownloader = AsyncTask()


local function downloadMod(self, mod)
    local mod_struct = self.mod_struct
    local id = ugch.check_id(mod)
    if not id then
        -- id is not valid, which means that `to_download` is a local mod.
        -- Since local mods (by nature) can't be downloaded, we invoke a fail and return.
        self:fail("Don't have the required local mods!")
        return
    end

    self:yield(0, "Subscribing to mod: " .. tostring(id))
    ugch.subscribe(id, function(ok, er)
        if not ok then
            self:fail("Couldn't subscribe to mod: " .. tostring(id) .. " with error: " .. er)
            return
        end
    end)

    while mod == mod_struct:get_mod_to_download() do
        -- we wait fully until the mod is downloaded
        -- TODO: Use luasteam.UGC.getItemDownloadInfo(id) here.
        local progress = 0.5
        self:yield(progress, ("Waiting for %d to download."):format(id))
    end

    self:yield(0, "Subscribed to mod!")
end


function ModDownloader:run()
    -- downloads all UGCs specified by the mod_struct
    local mod_struct = self.mod_struct

    self:yield(0, "Resolving dependencies")

    local to_download = mod_struct:get_mod_to_download()
    while to_download do
        downloadMod(self, to_download)
        to_download = mod_struct:get_mod_to_download()
    end
end




function ModDownloader:init(mod_struct)
    assert(type(mod_struct) == "table", "?")
    self.mod_struct = mod_struct
end



return ModDownloader

