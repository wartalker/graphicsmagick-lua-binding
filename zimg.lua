local image = require("resty.image")
local http = require("resty.http")

local function zimg(m, q)
	local img = image:new(m)

	if img == nil then
		return nil
	end

	if img:compress(q) == 0 then
		return nil
	end
	
	img:strip()
	return img:string()
end


local path = string.gsub(string.gsub(ngx.var.request_uri, "%.webp$", ""), "-app$", "")
local url = "http://image.xcar.com.cn" .. path

local hc = http:new()
local ok, code, headers, status, body = hc:request {
        url = url,
        proxy = "http://10.15.201.151:80"
}

if ok and code == 200 then
        if #body > 0 then
		local q = tonumber(ngx.var.arg_quality)
		local s = zimg(body, q)
		if s ~= nil then
			ngx.print(s)
		else
			ngx.print(body)
		end
	end
else
        ngx.exit(404)
end
