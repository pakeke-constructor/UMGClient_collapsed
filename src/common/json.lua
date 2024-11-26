local json = require("libs.nm_json.json")
local json5 = require("libs.json5.json5")

return {
    encode = json.encode,
    decode = json.decode,
    json5_decode = json5.decode
}
