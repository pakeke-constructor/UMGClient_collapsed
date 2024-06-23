
# Boxer

Data structure that handles packet creation, validation, and deser/ser

----

All packets are strongly typed, and have a fixed length.
If we want to send dynamic packets, we need to ser/deser a pckr string.

---


## Defining packets:
We have a bunch of default packets defined in `packet_types`.
These are used internally by the UMG-Engine.

HOWEVER: Modders will often want to define/send their own packets.

What's great, is that Boxer treats mod-defined packets THE EXACT SAME
as builtin packets.
This allows mod-defined-packets to be super efficient.

(Builtin packets are prefixed with `@` to ensure there's no overlap.)


---

# Internal workings:
Internally, `Boxer` uses luaJIT's `string.buffer` to serialize packets.
All packets are packed together in a flat array, and serialized in one go.

Each packet is given an id, and a name.

Example packet buffer:
```lua
{ 
--[[
-- packet_id     arguments....
]]  12,       "player_1",   "{id:304949}",
    7,        4309434
    4,  -- <<< some packets have 0 arguments!
    33, true, true, "{}" 34945, 4454, 
    -- and some packets have MANY arguments.
}
```


# Supported types:
As per `string.buffer` internal mechanisms:
Boxer supports the following types at base level:
```
 number, string, entity, boolean
```
The only confusing one is `entity`:

On `client --> server`, entities are ALWAYS serialized by id. (number)

On `server --> client`, 
entities are either serialized by id (number)
OR they are serialized by volatile Packer. (string)


