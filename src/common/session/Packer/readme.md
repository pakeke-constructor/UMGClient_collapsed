

# Packer:
## Module specialized for entity-serialization


Built on top of `pckr`

-------------------------------------
-------------------------------------
-------------------------------------



# What happens when we serialize a normal entity?
When we serialize an entity, it becomes "tracked".   
From that point onwards, it will be serialized by id.
See `tracking.md`


## What happens when we serialize a non-existant entity?
The entity should be sent over as per normal!
From there, we s
See `tracking.md` for more info, tho.

This should never happen in a normal context, since
entities are buffered before being sent over.  See `tracking.md`   
HOWEVER, this *can* happen when


# What happens when we serialize an entity, and it owns a bunch of other entities?
Serialize the owned entities too.


# How do we ensure that enitites are properly initialized before we send them over? 
See `tracking.md`


# What happens when we serialize a deleted entity?
Throw an error.
Or maybe we should fail silently...?   
^^^ There's a ticket for this anyway, it's fine   
**IMPORTANT NOTE: A Deleted entity is different from a non-existant entity!**

