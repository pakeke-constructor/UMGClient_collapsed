---@class TimingRingBuffer
local TimingRingBuffer = tools.SafeClass()

function TimingRingBuffer:init(bufsize)
    bufsize = bufsize or 1000
    assert(bufsize > 0)
    ---@type number[]
    self.buffer = {}
    self.index = 1
    self.size = bufsize
end

if false then
    ---@param bufsize integer?
    ---@return TimingRingBuffer
    function TimingRingBuffer(bufsize) end ---@diagnostic disable-line: cast-local-type, missing-return
end

---@param dt number
function TimingRingBuffer:add(dt)
    self.buffer[self.index] = dt
    self.index = (self.index % self.size) + 1
end

function TimingRingBuffer:average()
    local result = 0
    local bufcount = #self.buffer

    if bufcount > 0 then
        for _, v in ipairs(self.buffer) do
            result = result + v
        end

        result = result / bufcount
    end

    return result
end

function TimingRingBuffer:sampleCount()
    return #self.buffer
end

return TimingRingBuffer
