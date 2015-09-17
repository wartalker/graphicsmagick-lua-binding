local image = require("resty.image")
local http = require("resty.http")

local path = string.gsub(string.gsub(ngx.var.request_uri, "%.webp$", ""), "-app$", "")
local imgurl = "http://image.xcar.com.cn" .. path
-- local imgurl = "http://10.15.201.151" .. path
local hc = http:new()
local ok, code, headers, status, body = hc:request {
        url = imgurl,
        proxy = "http://10.15.201.151:80",
        method = "GET"
}

local q = tonumber(ngx.var.arg_quality)

if ok and code == 200 then
        if #body > 0 then
                local img = image:new(body)
                if (img ~= nil) and (img:compress(q) ~= 0) then
                        img:strip()
                        local s = img:string()
                        if s ~= nil then
                                ngx.print(s)
				return
			end
		end
		ngx.log(ngx.ERR, "GraphicsMagick read or compress image failed")
		ngx.print(body)
	end
else
        ngx.log(ngx.ERR, "Image not found: " .. code)
        ngx.exit(404)
end
