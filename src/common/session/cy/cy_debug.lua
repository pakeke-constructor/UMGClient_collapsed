
--[[


TODO:
Do this up nicely.


]]


local function dump_ids()
    print("===== entity.id_to_ent ======")
    print(inspect(entityManager.id_to_ent))
    print("=============================")
end

local function dump_groups()
    print("===== ent groups ============")
    print("===== FORMAT:  [group_hash]  [group_size]")
    for k,v in pairs(groupManager.group_hash) do
        print(k, v.size)
    end
    print("=============================")
end

local function print_short_ent(e)
    print(e:type(), e.id)
end

local function dump_buffers()
    print("=============== rembuffer ===================")
    print(inspect(rembuffer))
end

local function dump_ents()
    print("============ entities ============")
    print("NUM ENTS:", groupManager.all.size)
    for i,e in ipairs(groupManager.all.view) do
        print_short_ent(e)
    end
    print("==================================")
end


function cy.dump(what)
    if not what then
        -- dump everything
        dump_ids()
        dump_groups()
        dump_buffers()
        dump_ents()
    elseif what == "ids" then
        dump_ids()
    elseif what == "groups" then
        dump_groups()
    elseif what == "buffers" then
        dump_buffers()
    elseif what == "ents" then
        dump_ents()
    else
        error("cy.dump(what) must take either nil, or one of the following: `ids` `groups` `buffers` or `ents`")
    end
end

