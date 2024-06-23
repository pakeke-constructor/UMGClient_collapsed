

## Entity serialization tracking
This file seeks to explain the weird, complex behaviour behind entity serialization that is seen in `Packer`.

# The `entitySerialized` table
In short, the `entitySerialized` table is used to determine whether we serialize entities by id, or whether we serialize entities by value.




-------

































# ====================
#   OLD PLANNING
# ====================

### IDEA: Pre-injection into cy
What if we manually inject entities in cyWorld before serialization? Like, without buffering. 
Question: "Doesn’t this break buffering tho??”

Yes... but what we could do, is give cyWorld an API to check whether it’s midway through a flush or not. If the ECS is halfway through a flush, then it’s obviously safe to add entities to groups willy-nilly.   Packer module (or whatever) can then check if we are in a flush; if we are in a flush, then its safe to do a quick cheeky initialization of entities.  If not, then don’t initialize the entity; just send over bad data. (Then, the Naive solution can handle the rest of it)

^^^ FUTURE OLI HERE: This is a bad idea, it's overengineered

