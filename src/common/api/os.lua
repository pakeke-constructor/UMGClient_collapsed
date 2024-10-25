

return function()
    local os_api = {
        time = os.time,
        date = os.date,
        clock = os.clock
    }
    return os_api
end

