local redis = require "resty.redis"
local common = require "lua.common"

ngx.req.read_body()

--local args = ngx.req.get_body_data()
local args = '{"name":"xiaohong","age":"55"}'
--ngx.log(ngx.INFO, "data string:", data)
if common.check_args(args, {'name','age'}) == false then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local args_t = common.json_decode(args)

local ok, err = common.set_request_redis(args_t)
if err then
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local json_data, err = common.get_data_redis()
if err then
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

ngx.say(json_data)

-- use cache instead of redis

-- local ok, err = common.set_to_cache(args_t, 1000)
-- if err then
--   ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
-- end
--
-- local value = common.get_from_cache("age")
 -- ngx.say(value)
