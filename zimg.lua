local image = require("resty.image")
local http = require("socket.http")
local ltn12 = require("ltn12")
local os = require("os")
local io = require("io")
local string = require("string")

local function exists(path)
	local f, _ = io.open(path, "rb")
	if f == nil then
		return false
	end
	f:close()
	return true
end

local function check(path)
	local dpath = string.match(path, ".*/")
	if exists(dpath) then
		return true
	end
	local r = os.execute("/bin/mkdir -p " .. "'" .. dpath .. "'")
	if r == 0 then
		return true
	end
	for i = 1, 3 do
		if exists(dpath) then
			return true
		end
	end
	ngx.log(ngx.ERR, "mkdir: " .. dpath)
	return false
end

local function zimg(data, q, path)
	local img = image:new(data, 'mem')

	if img == nil or img:compress(q) == 0 then
		return nil
	end

	img:strip()

	local s = img:string()

	-- save must run finally, because img will be destroyed after it --
	if path ~= nil and check(path) then
		img:save(path)
	end

	return s
end

local host = ""
local path = string.gsub(string.gsub(ngx.var.request_uri, "%.webp$", ""), "-app$", "")
local imgurl = host .. path

local t = {}
local ok, code, _ = http.request {
	url = imgurl,
	proxy = "http://10.15.201.151:80",
	sink = ltn12.sink.table(t)
}

local body = table.concat(t)

if ok and code == 200 then
        if #body > 0 then
		local q = tonumber(ngx.var.arg_quality)
		local p = ngx.var.request_filename
		local s = zimg(body, q, p)
		if s ~= nil then
			ngx.print(s)
		else
			ngx.print(body)
		end
	end
else
        ngx.exit(404)
end
