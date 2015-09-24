local image = require("resty.image")
local http = require("socket.http")
local ltn12 = require("ltn12")
local os = require("os")

local function exists(path)
	local f, e = io.open(path, "rb")
	if f ~= nil then
		f:close()
		return true
	else
		return false
	end
end

local function check(path)
	local s, e = string.find(path, "[^/]*$")
	if s > 1 then
		local dpath = string.sub(path, 0, s -1)
		if exists(dpath) then
			return true
		end
		local r = os.execute("/bin/mkdir -p " .. "'" .. dpath .. "'")
		if r ~= 0 then
			for i=1,3 do
				if exists(dpath) then
					return true
				end
			end
			return false
		else
			return true
		end
	elseif s == 1 then
		return true
	else
		return false
	end
end


local function zimg(m, q, p)
	local img = image:new(m)
	
	if img == nil or img:compress(q) == 0 then
		return nil
	end

	img:strip()

	local s = img:string()

	-- save must finally run, because img will destroy after it --
	if p ~= nil and check(p) then
		img:save(p)
	end

	return s
end

local path = string.gsub(string.gsub(ngx.var.request_uri, "%.webp$", ""), "-app$", "")
local imgurl = "http://image.xcar.com.cn" .. path

local t = {}
local ok, code, headers = http.request {
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
