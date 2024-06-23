

local path = tools.path(...)


if constants.TEST then
    require(path .. "._test")
end


local translate = {}




-- TODO: Make it load the last saved language.
local language = "EN"



local current_table



function translate.translate(txt)
    local translated_txt = current_table[txt:lower()]
    if translated_txt then
        return translated_txt
    else
        return txt
    end
end




function translate.set_language(lang_code)
    local pth = "src.common.translate.tables." .. lang_code:upper()
    local tabl = require(pth)
    language = lang_code:upper()
    current_table = tabl
end



translate.set_language(language)


return translate
