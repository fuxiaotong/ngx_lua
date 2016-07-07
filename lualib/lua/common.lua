module("lua.common", package.seeall)
local json = require "cjson.safe"

function json_decode( str )
    local json_value = nil
    pcall(function (str) json_value = json.decode(str) end, str)
    return json_value
end

function json_encode( str )
    local json_value = nil
    pcall(function (str) json_value = json.encode(str) end, str)
    return json_value
end
