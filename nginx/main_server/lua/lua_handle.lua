local data = ngx.req.get_body_data()
--ngx.say("hello ", data)
local json = require("cjson")

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

ngx.say("---------------decode json---------------------")

local json = require("cjson.safe")
--local str  = [[ {"key:"value"} ]]
--local str = '{"name":"xiaoming","age":23}'
local str = data
local t    = json_decode(str)
if t then
    ngx.say(" json decode start --> ")
    for i,v in pairs(t) do
      ngx.say("key: ",i,", value: ",v)
    end
    ngx.say("<-- json decode stop  ")
end

-- redis connect and write
ngx.say("---------------write to redis---------------------")
local redis = require "resty.redis"
local red = redis:new()

red:set_timeout(1000) --timeout 1 sec

local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
   ngx.say("failed to connect: ", err)
   return
end

-- 请注意这里 auth 的调用过程
local count
count, err = red:get_reused_times()
if 0 == count then
   ok, err = red:auth("ubuntu")  -- 安全验证
   if not ok then
       ngx.say("failed to auth: ", err)
       return
     end
elseif err then
  ngx.say("failed to get reused times: ", err)
  return
end

if t then
  ngx.say(" write to redis --> ")
  for i,v in pairs(t) do

    local ok, err = red:hmset("mydata", i, v)
    if not ok then
      ngx.say("failed to set : ", err)
      return
    end
    ngx.say("key: ",i,", value: ",v, "  set ok")

  end
  ngx.say("<-- write stop  ")
end

ngx.say("all k-v set result: ", ok)


-- read from redis
ngx.say("---------------read from redis (hashset)---------------------")

local json_status = {} 
local keys = {'name', 'age'}
local res, err = red:hmget("mydata","name","age")
for k,v in ipairs(res) do
  json_status[keys[k]] = v
end
local record_json = json_encode(json_status)
--local record_json = json_encode({channel="chan", type="type_s", data={"value"}})
ngx.say(record_json)


-- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
local ok, err = red:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end
