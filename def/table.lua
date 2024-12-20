---@meta

---pick a random value from a table (or nil if it's empty)
---@generic T
---@param t T[]
---@param r {random:fun(self:any,min:integer,max:integer):integer}?
---@return T
function table.random(t, r)
end

--copy a table
--	deep_or_into is either:
--		a boolean value, used as deep flag directly
--		or a table to copy into, which implies a deep copy
--	if deep specified:
--		calls copy method of member directly if it exists
--		and recurses into all "normal" table children
--	if into specified, copies into that table
--		but doesn't clear anything out
--		(useful for deep overlays and avoiding garbage)
---@generic T: table
---@param t T
---@param deep_or_into? boolean|table
---@return T
function table.deepCopy(t, deep_or_into)
end

---@generic T: table
---@param t T
---@param into table?
---@return T
function table.shallowCopy(t, into)
end

---This clears all keys and values from a table, but preserves the allocated array/hash sizes. This is useful when a table, which is linked from multiple places, needs to be cleared and/or when recycling a table for use by the same context. This avoids managing backlinks, saves an allocation and the overhead of incremental array/hash part growth. The function needs to be required before use.
---```lua
---    require("table.clear").
---```
---Please note this function is meant for very specific situations. In most cases it's better to replace the (usually single) link with a new table and let the GC do its work.
---
---
---[View documents](command:extension.lua.doc?["en-us/51/manual.html/pdf-table.clear"])
---
---@param tab table
function table.clear(tab)
end

--shuffle the order of a table
---@generic T
---@param t T[]
---@param r {random:fun(self:any,min:integer,max:integer):integer}?
---@return T[]
function table.shuffle(t, r)
end
