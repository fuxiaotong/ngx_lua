local redis = require "resty.redis"
local commom = require "lua.common"

-- decode json
local data = ngx.req.get_body_data()

local str = data
local t = commom.json_decode(str)
if t then
    for i,v in pairs(t) do
      ngx.say("key: ",i,", value: ",v)
    end
end

-- redis connect and write

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

  for i,v in pairs(t) do

    local ok, err = red:hmset("mydata", i, v)
    if not ok then
      ngx.say("failed to set : ", err)
      return
    end
    ngx.say("key: ",i,", value: ",v, "  set ok")

  end

end


-- read from redis

local json_status = {}
local res, err = red:hmget("mydata","name","age")

json_status.name = res[1]
json_status.age = res[2]
local record_json = commom.json_encode(json_status)
ngx.say("output=======>")
ngx.say(record_json)

-- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
local ok, err = red:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end
