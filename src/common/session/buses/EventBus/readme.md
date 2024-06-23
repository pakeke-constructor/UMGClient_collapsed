
# simple event bus

### usage:

```lua

local event = require("path.to.event.event")( )


event:on("greet", function (name) -- Says hello
    print("Hello " .. name)
end)



event:call("greet", "Oli")


```

output:
`Hello Oli`


