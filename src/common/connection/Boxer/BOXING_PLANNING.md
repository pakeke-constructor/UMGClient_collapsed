
# Boxing planning:

QUESTION: Should we have `PacketRegistry`...?
A: No, that'd be stupid, there would be too much coupling between modules.


QUESTION: Should dynamic packets be built on top of regular packets?

PROS: 
    - Boxing would be simpler and smaller
    - Would increase separation of concerns (less tech debt)
CONS: 
    - We'd need *another* place to keep track of strings <--> ids, as opposed to a singular source of truth. (Since dynamic packets AND regular packets both need str <--> id mapping synced across the network)
    - Less efficient, since it's no longer handled at base topology
    - Would need more weird coupling between modules




## DynamicBuses (previously broadcast_bus)
With packets being defined at runtime, `Boxer` is going to have to take
the job of ClientDynamicBus and ServerDynamicBus.
To account for this, we should add nice methods to `Boxer`:
```lua
Boxer:definePacket(name, id)
```

We probably also want a callback for when a packet isn't defined!
(`Boxer` calls the callback, `connObj` sends a packet)


-----

## To think about:
where should we define our callback listeners?
    Previously, we defined them inside of `ServerDynamicBus/ClientDynamicBus`.
    IDEA:
    Keep `DynamicBus` modules around. They are useful, and cool.
    Perhaps they should be part of `Boxing`...?
    This would mean that they need to be shared.



### Bus objects:
Now that client/server fuckyness is being handled by `Boxer`,
we should seriously consider `Bus` objects being shared across client/serv.

We should keep `Bus` objects within




### The golden question:
Where do we do the initial setup, ie. `connObj:on` calls...?

I feel like the best place to do these would be in the `:setup` method
(or `:init` method...?) of the objects that are most closely-related to 
whatevers happening.




# FINAL IDEA:
Don't have `dynamic` packets; Just have `regular` packets.

If modders need dynamic packets, they can serialize a string, and 
call `deserializeVolatile` on the string data.



## Sync mod changes:
`sync.autoSyncComponent` should send packets with data: `{"string"}`
where the string is pckr volatile data.

We could ALSO then do `sync.autoSyncComponent` with a MULTI option;
ie. 
we sync `x, y` components as ONE SINGULAR PACKET.


QUESTION:
What about `sync.proxyEventToClient`...??!?
We will just need to deserialize the pckr data manually on client.
No big deal; this was being done anyway.

For `sync.auto`




# Default packets:
How do we register default packets...?
We need `Boxer` to be aware of it;
and we also need `PacketMapper` to be updated

The main question is:
How do we register this stuff?

### IDEA-1:
`packetTypes`: Have a list of packets, with names/args

`Boxer`:
In ctor, calls a private method that loops over all packetTypes
and registers them.
`PacketMapper`:
In ctor, calls a private method that loops over all packetTypes
and assigns an id to them.
