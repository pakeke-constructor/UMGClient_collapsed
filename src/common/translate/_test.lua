

local path = tools.path(...)


local langs = tools.load_tree(path:gsub("%.", "/") .. "/tables")


local EN = langs.EN
assert(EN, "?")


local required_fields = {}
for k,_ in pairs(EN)do
    table.insert(required_fields, k)
end


for lang_code, tt in pairs(langs)do
    for _, f in ipairs(required_fields) do
        if (not tt[f]) then
            error("Language " .. lang_code .. " did not have the translation: " .. f)
        end
    end
end


