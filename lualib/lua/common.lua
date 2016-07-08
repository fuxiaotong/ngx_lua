module("lua.common", package.seeall)
local json = require "cjson.safe"
local redis = require "resty.redis"
local red = redis:new()


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

--检查输入数据的合法性
function check_args(args, require_key)
    if not args then
      return false
    end

    args = json_decode(args)
    local key, value
    for k,_ in ipairs(require_key) do

        key = require_key[k]
        value = args[key]

        if nil == value then
            return false
        elseif #value == 0 then
            return false
        end
    end

    return true
end


function set_request_redis(args_t)
  red:set_timeout(1000) --timeout 1 sec

  local ok, err = red:connect("127.0.0.1", 6379)
  if err then
    return nil, err
  end

  local count, err = red:get_reused_times()
  if 0 == count then
    ok, err = red:auth("ubuntu")  -- 安全验证
    if not ok then
      return nil, err
    end
  elseif err then
    return nil, err
  end

  if args_t then
    for i,v in pairs(args_t) do
      local ok, err = red:hmset("mydata", i, v)
      if not ok then
        return nil, err
      end
      --ngx.say("key: ",i,", value: ",v, "  set ok")
    end
  end
end


function get_data_redis()
  local json_status = {}
  local res, err = red:hmget("mydata","name","age")

  json_status.name = res[1]
  json_status.age = res[2]
  local record_json = json_encode(json_status)

  -- 连接池大小是100个，并且设置最大的空闲时间是 10 秒
  local ok, err = red:set_keepalive(10000, 100)
  if not ok then
    return nil, err
  end

  return record_json, err

end


function get_from_cache(key)
    local cache_ngx = ngx.shared.my_cache
    local value = cache_ngx:get(key)
    return value
end

function set_to_cache(args_t, exptime)
    if not exptime then
        exptime = 0
    end
    local cache_ngx = ngx.shared.my_cache
    if args_t then
      for key, value in pairs(args_t) do
        local succ, err, forcible = cache_ngx:set(key, value, exptime)
        if err then
          return nil, err
        end
      end
    end
    return succ
end
