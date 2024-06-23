


# Refactor plan:

A bunch of shoddy notes and planning per the refactor.

----------




# Solution for when entities are sent over early:
With UMG, we can send over *any* data that we want, whenever we want.
But... this can cause some issues when we serialize un-initialized entities.

Pre-reading: It’s a common pattern in UMG-base-mods to mutate entities upon being added to groups via `onAdded`.
Often, mutation is done on the serverside; and the mutated data is sent to clientside when the entity is properly spawned.

We have 2 problems:
### PROBLEM-1: Owned-entities
Say we have an entity, that creates (and owns) another entity. Lets call them `ownerEnt` and `subEnt`. `ownerEnt` gets added into all-group during a flush, and therefore gets serialized first. But `subEnt` is owned by `ownerEnt`, so it gets serialized too. The issue, is that `subEnt`’s data is going to be serialized BEFORE it’s properly initialized, (remember; it hasn’t been added to groups yet).
This is terrible. Client will receive bad data.

## PROBLEM-1 Solution:
How about instead of serializing entities in `allGroup:onAdded`,
we buffer entities that are going to be serialized, and send them in one go?
That way, we can send them over at the end of a tick,
guaranteeing that their components are ready.
 ^^^ This buffering should NOT be handled by `EntitySync`


### PROBLEM-2: Premature serialization
This is when the server just sends an entity over *before* it's been initialized properly.
This is kinda the modder's fault, but oh well.
We will still fix it.

## Problem-2 solution:
Re-send `ent` over after it's been added to allgroup.
The clientside receiver will receive a duplicate entity... but clientside will be smart, and will update components of the previously received `ent`. (which could have out-of-date data)
This is robust (enough), but it isn’t ideal, since it’s sending over data twice. ALSO, any objects that the entity owns will be spawned twice.

(Note that this will require a `serializeEntityByValue(ent)` function!
Or else when we do the 2nd call to `serialize`, it will serialize the entity by id.)









----


## About the old `seen` table:
Speaking in the context of `server/../entity_add_remove`, 
commit: `79517d5`

I'm pretty sure a bunch of stuff in the old `seen` table is useless

I'm pretty sure the `BEING_SERIALIZED_ENUM` is completely useless.
The `BEING_SERIALIZED_ENUM` was used as a hacky way to check if an entity existed; Since we were throwing an error if a non-existant entity was serialized.

but with the current setup; non-existant entities are serialized anyway!   
So firstly: we don't need to error when serializing non-existant ents;   
And secondly: we don't even need `BEING_SERIALIZED_ENUM`!

