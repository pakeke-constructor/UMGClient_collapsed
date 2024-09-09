

--[[

Same as constants, but the values of these fields can change!

]]


return {
    show_ingame_nerd_stats = false, -- shows memory and fps values

    ticks_per_second = 30; -- aim for this TPS for server

    ingame_paused = false; -- whether the ingame client is paused
    is_world_persistent = false, -- whether the world is persistent or not.
    -- Only used on serverside currently.

    src_udp_port = nil; -- The port that we are currently using.
    -- This is needed, because we need the UDP sockets and the ENet peer to share src ports for holepunch.
    -- (Also, we don't know what port is going to be chosen before runtime.)
}


