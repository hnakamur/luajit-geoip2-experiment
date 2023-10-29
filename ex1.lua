package.path = './deps/geoip2/lib/?.lua;;'
local maxminddb = require 'resty/maxminddb'

local db, err = maxminddb.open('GeoLite2-Country.mmdb')
if err ~= nil then
  print(string.format('maxminddb.open err=%s', err))
  os.exit(1)
end

print('--- lookup ---')
local res, err = db:lookup('1.0.16.0')
if err ~= nil then
  print(string.format('lookup err=%s', err))
else
  for k, v in pairs(res) do
    print(string.format('k=%s, v=%s.', k, v))
    for k2, v2 in pairs(v) do
      print(string.format('  k2=%s, v2=%s.', k2, v2))
    end
  end  
end

print('--- lookup_country_iso_code ---')
local res, err = db:lookup_country_iso_code('1.0.16.0')
if err ~= nil then
  print(string.format('lookup_country_iso_code err=%s', err))
else
  print(res)
end

print('--- lookup_country_iso_code#2 ---')
local res, err = db:lookup_country_iso_code('1.1.1.1')
if err ~= nil then
  print(string.format('lookup_country_iso_code err=%s', err))
else
  print(res)
end

print('--- lookup_country_iso_code#3 ---')
local res, err = db:lookup_country_iso_code('0.0.0.0')
if err ~= nil then
  print(string.format('lookup_country_iso_code#3 err=%s', err))
else
  print(res)
end

db:close()
print('closed')
