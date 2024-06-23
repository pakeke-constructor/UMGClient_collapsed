
--[[

AsyncTask is a metaclass,
Used to represent an abstract async task that is running.

Internally, represented as a coroutine.

Useful for anything async, like downloading or requests.


]]

local AsyncTask = {}




local function tryCall(self, methodName, ...)
    local func = self[methodName]
    if func then
        func(self, ...)
    end
end


-- Finish-flags:
-- ATask will be assigned one of these when finished:
local SUCCESS = 1
local FAIL = 2



local function isDead(self)
    return coroutine.status(self.thread) == "dead"
end



function AsyncTask:isFinished()
    --[[
    A dead coroutine should always count as "finished".
    This is because if a coroutine errors, it dies.

    If a coroutine is dead, but it doesn't have a finish-flag,
    then it is said to have finished non-gracefully.
    An error should be printed to console.
    ]]
    return isDead(self) or self.finishedFlag
end


function AsyncTask:hasFailed()
    return self.finishedFlag == FAIL
end


function AsyncTask:hasSucceeded()
    return self.finishedFlag == SUCCESS
end


-- resumes the task
function AsyncTask:resume()
    local _, err = coroutine.resume(self.thread, self)
    if isDead(self) and (not self.finishedFlag) then
        log.error("AsyncTask errored non-gracefully:\n    ", err)
    end
end



--[[
    yields coroutine, and (optionally) updates the `progress` value.

    Should be used by the code that is defining what the task is doing,
    NOT by the code that is running the task.
   
    atask:yield(0.5)

    We can also give a description:
    atask:yield(0.6, "downloading world...")
]]
function AsyncTask:yield(progress, description)
    if progress then
        self:setProgress(progress, description)
    end
    coroutine.yield()
end



--[[
    Sets the progress and description of the AsyncTask.

    `description` should be a human-readable string!
    It will be displayed to the user!
]]
local setProgressTc = tc.assert("table", "number", "string?")
function AsyncTask:setProgress(progress, description)
    setProgressTc(self, progress, description)
    assert(type(progress) == "number","?")
    self.progress = progress
    if description then
        self.description = description
    end
end



function AsyncTask:fail(reason)
    --[[
        this should be called from inside the coroutine!!
    ]]
    self.finishedFlag = FAIL
    self.failReason = reason
    tryCall(self, "onFail", reason)
    error(reason)
end


function AsyncTask:succeed()
    --[[
        this is called from WITHIN the coroutine automatically after `:run`.
        You can call it early if you want to, however.
    ]]
    tryCall(self, "onSuccess")
    self.finishedFlag = SUCCESS
end




--[[
    OVERRIDES:
]]
function AsyncTask:run()
    --[[
        This is the the async function to run.
        This function should call `obj:yield(...)` at regular intervals.
    ]] 
end

function AsyncTask:init()
end

-- TODO:
-- Do we need these two callbacks?
function AsyncTask:onFail()
end

function AsyncTask:onSuccess()
end
--[[
    -------------------
]]



local function newAsyncTask(cls, ...)
    --[[
        NOTE:
        This is for creating AsyncTask objects.
        Not classes!
    ]]
    assert(cls.run, "AsyncTask did not have a `run` function!")
    local self = setmetatable({}, cls)

    tryCall(self, "init", ...)

    self.thread = coroutine.create(function()
        self:run()
        self:succeed()
    end)

    -- fail state, and fail reason:
    self.finished = false
    self.failReason = ""

    self.progress = 0
    self.description = ""

    self:resume()
    return self
end



local clsMt = {__call = newAsyncTask}


local function newAsyncTaskClass()
    --[[
        NOTE:
        This is for creating AsyncTask CLASSES, NOT ATASK OBJECTS!
    ]]
    local cls = {}
    setmetatable(cls, clsMt)

    for k,v in pairs(AsyncTask) do
        cls[k] = v
    end

    cls.__index = cls
    return cls
end




if constants.TEST then
    local MyTask = newAsyncTaskClass()

    function MyTask:init()
        self.count = 0
    end

    function MyTask:run()
        for _=1, 3 do
            self.count = self.count + 1
            self:yield()
        end
    end

    local t = MyTask()

    for _=1, 3 do
        t:resume()
    end
    assert(t.count == 3, tostring(t.count))
    log.trace("[AsyncTask] Tests passed")
end



return newAsyncTaskClass

