
# server:

On startup:
    creates new thread
    Loads mods
    loads world into memory


Whilst running:
    Listens for new connections

    if new connection:
        (see diagram I drew)

    Updates(dt) game world

    updates peers with new world state
    












### thread channels:
Since love2d channels are bi-directional, specify the direction and purpose
of channels by name:

The general format is:
<Direction>.<Purpose>

EXAMPLE:
`client_to_server.close`
This channel is from  client --> server, and is for listening to "close" events.

EXAMPLE 2:
`client_to_server.initialize`
This channel is ALSO from  client --> server, and is for sending initialize data.






### List of channels:

`client_to_server.initialize`
`client_to_server.close`

`server_to_client.print`  -- printing
`server_to_client.localport` -- sends port for 127.0.0.1

