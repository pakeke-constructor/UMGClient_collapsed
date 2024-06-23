
# translate

Handles language translations.

This is where we should do most of our text.
(This just ensures that we can futureproof languages and stuff.)


# usage:
```lua

local language = require(".../language")


-- set language
language.set_language(lang_code)
--[[
lang_code can be:

EN - english
... do others too
]]




language.translate("hello") --> translates `hello` into whatever language is set.
-- If there is no translation, english is returned.


