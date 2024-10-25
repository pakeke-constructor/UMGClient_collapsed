
local path = tools.path(...)

local QuestionBus = require("src.common.session.buses.QuestionBus.QuestionBus")
local EventBus = require("src.common.session.buses.EventBus.EventBus")

local CyWorld = require("src.common.session.cy.cy").World


local Packer = require("src.common.session.Packer.Packer")


---@class UMGSession
local UMGSession = tools.SafeClass()





function UMGSession:init()
    self.eventBus = EventBus()
    self.questionBus = QuestionBus()

    self.cyWorld = CyWorld({
        eventBus = self.eventBus
    })

    self.packer = Packer({
        cyWorld = self.cyWorld
    })
end

if false then
    ---@return UMGSession
    function UMGSession() end ---@diagnostic disable-line: cast-local-type, missing-return
end


function UMGSession:serializeWorld()
    self.cyWorld:flush()
    local allGroup = self.cyWorld:group()
    local cpy = {}
    for _, ent in ipairs(allGroup) do
        table.insert(cpy, ent)
    end
    return self.packer:serializeVolatileNoIdReferences(cpy)
end


function UMGSession:deserializeWorld(data)
    self.cyWorld:flush()
    local ok, err = self.packer:deserializeVolatile(data)
    if (not ok) and err then
        log.error("Unable to deserialize world: ", err)
    end
    self.cyWorld:flush()
end





function UMGSession:group(...)
    local group = self.cyWorld:group(...)
    
    local alias = tostring(group) -- 
    self.packer:register(group, alias)
    return group
end



function UMGSession:newEntityType(typename, tabl)
    -- we call @newEntityType with the table BEFORE we define with cy.
    -- (This allows systems to mutate the definition before its registered.)
    self.eventBus:call("@newEntityType", tabl, typename)

    local etype = self.cyWorld:newEntityType(typename, tabl)

    self.packer:registerEntityType(typename, etype)

    return etype
end



function UMGSession:tick(dt)
    self.eventBus:call("@tick", dt)
end



function UMGSession:flush()
    self.cyWorld:flush()
end


function UMGSession:update(dt)
    self.eventBus:call("@update", dt)
end



if constants.PROFILE_EVENT_BUS then

---@param f love.File
---@param report table<string, EventBusProfileReport|EventBusProfileReportParent>
---@param indent integer
local function writeReport(f, report, indent)
    if next(report) then
        local tab = string.rep(" ", indent)

        local numericReport = {}
        for k, v in pairs(report) do
            numericReport[#numericReport+1] = {k, v.sampleCount, v.average * 1000, v.child}
        end

        -- Sort by sample count then by average time, by highest.
        table.sort(numericReport, function(a, b)
            if a[2] == b[2] then
                return a[3] > b[3]
            else
                return a[2] > b[2]
            end
        end)

        for _, v in ipairs(numericReport) do
            f:write(tab.."- "..v[1]..": "..v[3].."ms over "..v[2].." samples\n")

            if v[4] then
                writeReport(f, v[4], indent + 2)
            end
        end
    end
end

---Write profiler report to umg_eventbus_report_\<suffix\>.txt
---@param suffix string
function UMGSession:generateProfilerReport(suffix)
    local report = self.eventBus:getProfilerReport()

    -- Ensure the report is not empty
    if next(report) then
        local f = assert(love.filesystem.openFile("umg_eventbus_report_"..suffix..".txt", "w"))
        f:write("Event bus measurement statistics:\n")
        writeReport(f, report, 0)
        f:close()
    end
end

end


return UMGSession

