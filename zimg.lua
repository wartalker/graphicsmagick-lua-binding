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

q = tonumber(ngx.var.arg_quality)

if ok and code == 200 then
        if string.len(body) > 0 then
                img = image:new(body)
                if img ~= nil then
                        img:strip()
                        cimg = img:compress(q)
                        if cimg ~= nil then
                                ngx.print(cimg)
                                return
                        end
                end
                ngx.log(ngx.ERR, "GraphicsMagick can't read image data")
                ngx.print(body)
        end
else
        ngx.log(ngx.ERR, "Image not found")
        ngx.exit(404)
end
