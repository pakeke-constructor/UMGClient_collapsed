local TimingRingBuffer = require("src.common.timing_ring_buffer")

---@class EventBus
local EventBus = tools.SafeClass()

local hash_mt = {
    __index = function(t,k)
        t[k] = {}
        return t[k]
    end
}


function EventBus:init()
    tools.inlineMethods(self)
    self.event_to_responselist = setmetatable({
        -- [event_name] = { response_obj list }
    }, hash_mt)
    self.events = {}

    if constants.PROFILE_EVENT_BUS then
        ---@type table<string, TimingRingBuffer>
        self.event_time_measurements = {}
    end
end

if false then
    ---@return EventBus
    function EventBus() end ---@diagnostic disable-line: cast-local-type, missing-return
end


local function compare(a, b)
    return a.order < b.order
end

---@param self EventBus
---@param name string
---@param responselist {func:function,order:integer}
local function update_event_function_list(self, name, responselist)
    local funcs = {}
    table.sort(responselist, compare)
    for _, resp in ipairs(responselist) do
        assert(resp.func, "?")
        table.insert(funcs, resp.func)
    end
    self.events[name] = funcs
end

---@param name string
---@param func function
---@diagnostic disable-next-line: duplicate-set-field
function EventBus:on(name, func) end

---@param name string
---@param order_or_func integer
---@param func_or_nil function
---@diagnostic disable-next-line: duplicate-set-field
function EventBus:on(name, order_or_func, func_or_nil)
    local order, func
    if type(order_or_func) == "number" then
        func = func_or_nil
        order = order_or_func
    else
        func = order_or_func
    end
    if type(func) ~= "function" then
        error(("expects a function as final arg. Got: %s"):format(type(func)))
    end

    local response_obj = {
        func = func,
        order = order or 0
    }

    local arr = self.event_to_responselist[name]
    table.insert(arr, response_obj)
    --[[
        TODO:
        We can make this a bit faster. currently, this is O(n) time+space.
        Instead of inserting it in, and then sorting the result list,
        we can binary search for the position and insert directly.

        (Not top priority tho, since this only affects load times.)
    ]]
    update_event_function_list(self, name, arr)
end


local EMPTY = {}
---@param name string
---@param ... any
function EventBus:_callDirect(name, ...)
    local arr = self.events[name] or EMPTY
    for i=1, #arr do
        arr[i](...)
    end
end

local getTime = love.timer.getTime
---@param name string
---@param ... any
function EventBus:call(name, ...)
    if not constants.PROFILE_EVENT_BUS then
        return self:_callDirect(name, ...)
    end

    local arr = self.events[name] or EMPTY
    if #arr > 0 then
        local rb = self.event_time_measurements[name]
        if not rb then
            rb = TimingRingBuffer()
            self.event_time_measurements[name] = rb
        end

        local t = getTime() * 1000

        for i = 1, #arr do
            arr[i](...)
        end

        rb:add(getTime() * 1000 - t)
    end
end



function EventBus:clear()
    self.events = {}
    self.event_to_responselist = setmetatable({
        -- [event_name] = { function list }
    }, hash_mt);
end


if constants.PROFILE_EVENT_BUS then

function EventBus:getProfilerReport()
    ---@type table<string, {sampleCount:integer,average:number}>
    local result = {}
    for k, v in pairs(self.event_time_measurements) do
        result[k] = {sampleCount = v:sampleCount(), average = v:average()}
    end
    return result
end

end


return EventBus


