
# typecheck

a simple typechecking library for lua




# USAGE:
```lua


local tc = require("typecheck")

local tc_shockwave = tc.assert(tc.num, tc.num, tc.string, tc.table)




local function shockwave(x, y, type, entity)
    tc_shockwave(x, y, type, entity)
   ...
end



shockwave(1, 2, 3, {})
-- ERROR: shockwave: argument #3 expected type `string`, got `number`.

```




# Advanced usage:
We can also typecheck and return a boolean, instead of error'ing.
```lua


-- Returns `true` on type error!
local tc_circle = tc.safe(tc.num, tc.int, tc.int)



local function circle(rad, x, y)
    
    if tc_circle(rad, x, y) then
        return "Failed circle creation!"
    end

    return new_circle({rad, x, y})   
end



```
