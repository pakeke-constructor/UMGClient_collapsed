

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
end



local function compare(a, b)
    return a.order < b.order
end

local function update_event_function_list(self, name, responselist)
    local funcs = {}
    table.sort(responselist, compare)
    for _, resp in ipairs(responselist) do
        assert(resp.func, "?")
        table.insert(funcs, resp.func)
    end
    self.events[name] = funcs
end


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
function EventBus:call(name, ...)
    local arr = self.events[name] or EMPTY
    for i=1, #arr do
        arr[i](...)
    end
end



function EventBus:clear()
    self.events = {}
    self.event_to_responselist = setmetatable({
        -- [event_name] = { function list }
    }, hash_mt);
end


return EventBus


