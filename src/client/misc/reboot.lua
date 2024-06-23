
--[[
    helper module for setting / wiping reboot options
]]



local LaunchOptions = require("src.common.misc.LaunchOptions")


local reboot = {}


local FILE_NAME = constants.REBOOT_FILE


function reboot.write_options(launch_options)
    --[[
        TODO: This method shouldn't take a table here.
        We should instead get the data directly inside of this function
    ]]
    local data = launch_options:serialize()
    love.filesystem.write(FILE_NAME, data)
end



function reboot.should_reboot()
    local exists = love.filesystem.getInfo(FILE_NAME)
    return exists
end



function reboot.clear_options()
    if love.filesystem.getInfo(FILE_NAME) then
        local ok = love.filesystem.remove(FILE_NAME)
        if (not ok) then
            log.warn("failed to clear reboot options")
        end
    end
end



function reboot.read_options()
    local dat = love.filesystem.read(FILE_NAME)
    local tabl, err = LaunchOptions.deserialize(dat)
    if tabl then
        return tabl
    end
    return nil, err
end



return reboot
