

local ip = {}

function ip.ip_to_i32(ip_str)
    local buffer = {}
    
    for v in ip_str:gmatch("[^%.]+") do
        table.insert(buffer, v)
    end

    if type(ip_str) ~= "string" then
        error("Bad type for ip_str: ", type(ip_str))
    end

    if #buffer ~= 4 then
        error("peer -> ip_port failed: bad ipv4 addy:  " .. tostring(ip_str))
    end

    local am = 1
    local ret = 0
    for i=4, 1, -1 do
        local n = tonumber(buffer[i], 10)
        if n then
            ret = ret + n * am
            am = am * (2^8)
        else
            return nil
        end
    end
    return ret
end


function ip.i32_to_ip(n)
    assert(type(n) == "number", "i32 to ipv4 btw")
    local n1 = math.floor(n / (2^24)) 
    local n2 = math.floor((n - n1*(2^24)) / (2^16))
    local n3 = math.floor((n - n1*(2^24) - n2*(2^16)) / (2^8))
    local n4 = math.floor((n - n1*(2^24) - n2*(2^16) - n3*(2^8)))
    return n1.."."..n2.."."..n3.."."..n4
end


if constants.TEST then
    local function test(a1)
        local a2 = ip.i32_to_ip(ip.ip_to_i32(a1))
        assert(a1 == a2, "difference: " .. a2 .. "  ---  " .. a1)
    end

    local ans = 2050642459
    local a = "122.58.82.27"
    assert(ip.ip_to_i32(a) == ans)

    test("0.0.0.0")
    test("255.255.255.255")
    test("23.234.10.200")
    test("34.234.22.0")
end


return ip

