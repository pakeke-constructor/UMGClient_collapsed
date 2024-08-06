
--[[

Defines all the packets for the Boxer module

]]


local PACKET_VERSION = constants.BOXER_PACKET_VERSION

log.info("Using packet version: ", PACKET_VERSION)



local packetTypes = {}


local PREFIX = constants.BOXER_BUILTIN_PACKET_PREFIX 

local i = 1
local function def(packetName, args)
    args = args or {}
    assert(packetName:sub(1,1) == PREFIX, "needs prefix!")

    table.insert(packetTypes, {
        name = packetName,
        typelist = args,
        id = i
    })
    i = i + 1
end


local ENTITY = "entity"

local U32_ID = "number"
local ENT_ID = "number"
local VERSION = "number"

local COMP_NAME = "string"

local JSON = "string"
local PCKR_DATA = "string"
local ENT_TYPE = "string"
local NAME = "string"

local CLIENT_ID = "string"





def("@gimme_box_version")

def("@box_version", {VERSION})


def("@kick_player") -- unicast, sent to kick a player


def("@gimme_world") --client --> server: requests for the world data

def("@world", {PCKR_DATA}) -- server --> client
-- Spawns a world for the client. (serialized by pckr stable)


def("@ready_to_play") -- client --> server
-- tells the server that the client is ready to play.
-- ie, the client has loaded all appropriate mods and stuff.


def("@client_join", {CLIENT_ID, JSON})
def("@client_leave", {CLIENT_ID})

def("@client_wants_to_disconnect") -- client --> server
-- tells the server that we'd like to disconnect

def("@server_disconnect", {"string"}) -- server --> client
-- tells the client that server kicks them out


--[[
<<Mod events>>

Each (Client, Server) pair has a set of (event_name, event_id) pairs
that they use to communicate across the network.
NOTE:: The event_name -> event_id mapping could be different for
each (Client,Server) pair!!
]]

def("@tick") --Denotes a server tick



def("@define_packet_id", {U32_ID, NAME})
-- Server --> Client:  assigns a new id to a broadcast event
-- Client --> Server:  assigns a new id to a broadcast event  
--   (IT WORKS BOTH WAYS, there are 2 caches.)





-- These two packets are unused as of now!!!
-- In the future, we can add it back.

-- def("@register_ent_type", {U32_ID, ENT_TYPE})
-- -- registers an entity type as an id, for volatile serialization
-- def("@entity_register_cache", {JSON})
-- -- The entity register cache, as json data



def("@spawn_entities", {PCKR_DATA})
-- spawns an entity, passes in pckr_data

def("@ent_add_component", {ENTITY, COMP_NAME, PCKR_DATA}) -- syncs an entity component
def("@ent_remove_component", {ENTITY, COMP_NAME}) -- rems an entity component

def("@ent_delete", {ENTITY})




--[[

Test Packets:

These packets are for testing purposes.
They have no use outside of testing.

]]
local ENT = "entity"
def("@test_entity", {ENT, ENT, ENT}) -- test entities




return packetTypes
