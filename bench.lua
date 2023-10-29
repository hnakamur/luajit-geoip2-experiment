package.path = './deps/geoip2/lib/?.lua;;'
local maxminddb = require 'resty/maxminddb'

function generate_random_ipv4_addresses(n, seed)
  if not seed then
    seed = os.time()
    -- print(string.format('random seed=%d', seed))
  end
  math.randomseed(seed)

  local addrs = {}
  for i = 1, n do
    -- 0.0.0.0 ～ 255.255.255.255
    table.insert(addrs, ipv4addr_ntoa(math.random(0, 4294967295)))
  end
  return addrs
end

function ipv4addr_ntoa(n)
  local d = n % 256
  n = math.floor(n / 256)
  local c = n % 256
  n = math.floor(n / 256)
  local b = n % 256
  local a = math.floor(n / 256)
  return string.format('%d.%d.%d.%d', a, b, c, d)
end

local ffi = require "ffi"
local C = ffi.C

ffi.cdef[[
    typedef int clockid_t;
    typedef int64_t time_t;

    struct timespec {
        time_t   tv_sec;        /* seconds */
        long     tv_nsec;       /* nanoseconds */
    };

    int clock_gettime(clockid_t clockid, struct timespec *tp);
]]

local CLOCK_REALTIME = 0

-- See
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER
-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER
local max_safe_integer = 9007199254740991
local min_safe_integer = -9007199254740991

function check_safe_integer(v)
    if v < min_safe_integer or v > max_safe_integer then
        print(string.format("number %g is not a safe integer", v))
        os.exit(1)
    end
end

function timespecdiffsec(t, u)
    check_safe_integer(tonumber(t.tv_sec))
    check_safe_integer(tonumber(t.tv_nsec))
    check_safe_integer(tonumber(u.tv_sec))
    check_safe_integer(tonumber(u.tv_nsec))

    local sec = tonumber(t.tv_sec) - tonumber(u.tv_sec)
    local nsec = tonumber(t.tv_nsec) - tonumber(u.tv_nsec)
    if nsec < 0 then
        sec = sec - 1
        nsec = nsec + 1000000000
    end
    return sec + nsec / 1000000000
end

local t1 = ffi.new("struct timespec[1]")
local t2 = ffi.new("struct timespec[1]")

local db, err = maxminddb.open('GeoLite2-Country.mmdb')
if err ~= nil then
  print(string.format('maxminddb.open err=%s', err))
  os.exit(1)
end

C.clock_gettime(CLOCK_REALTIME, t1[0])
local addrs = generate_random_ipv4_addresses(1000000)
for i, addr in ipairs(addrs) do
  local res, err = db:lookup_country_iso_code(addr)
  if err ~= nil then
    if err ~= 'not found' then
      print(string.format('lookup_country_iso_code err=%s', err))
      os.exit(1)
    end
  end
end
C.clock_gettime(CLOCK_REALTIME, t2[0])
local elapsed = timespecdiffsec(t2[0], t1[0])
print(string.format("elapsed=%f(s)", elapsed))

db:close()
