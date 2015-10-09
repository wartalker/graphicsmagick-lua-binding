local io = require("io")
local string = require("string")
local image = require("resty/image")

local wh = {
        {'w',170},
        {'w',200},
        {'w',224},
        {'w',365},
        {'w',150},
        {'w',237},
        {'w',420},
        {'w',450},
        {'w',608},
--        {'h',32},
--        {'m',600},
}

local xy = {
        {60,60},
        {80,60},
        {120,90},
        {130,130},
        {200,100},
        {200,150},
        {220,165},
        {240,180},
        {260,195},
        {232,144},
        {300,225},
        {300,300},
        {360,270},
        {400,300},
        {420,315},
        {500,375},
        {600,450},
        {635,480},
        {700,525},
}

local function exists(path)
	local f, _ = io.open(path, "rb")
	if f == nil then
		return false
	end
	f:close()
	return true
end

local function check(path)
	local dp = string.match(path, ".*/")
	if exists(dp) then
		return true
	end
	local cmd = "/bin/mkdir -p " .. "'" .. dp .. "'"
	local r = os.execute(cmd)
	if r == 0 then
		return true
	end
	for i = 1, 3 do
		if exists(dp) then
			return true
		end
	end
	return false
end

-- q: quality w: width h: height st: side type --
local q = 75
local w, h, l
local path, suffix, suffix_
local st
local t = tonumber(ngx.var.type)

if t == nil then
	t = 0
end

if t == 1 then
	_, _, path, suffix, w, h, suffix_ = string.find(ngx.var.uri, '(.*)%.(%a+)%-(%d+)x(%d+)%.(%a+)')
	w, h = tonumber(w), tonumber(h)
elseif t == 2 then
	_, _, path, suffix, w, suffix_ = string.find(ngx.var.uri, '(.*)%.(%a+)%-(%d+)%.(%a+)')
	w = tonumber(w)
	h = w
elseif t == 3 then
	_, _, path, suffix, st, l, suffix_ = string.find(ngx.var.uri, '(.*)%.(%a+)%-([whm])(%d+)%.(%a+)')
	l = tonumber(l)
else
	_, _, path, suffix = string.find(ngx.var.uri, '(.*)%.(%a+)%.webp$')
end

local is_resize = false

if st ~= nil then
	local i
	
	for i=1, #wh do
		if wh[i][1] == st and wh[i][2] == l then
			is_resize = true
			break
		end
	end
else
	local i

	for i=1, #xy do
		if xy[i][1] == w and xy[i][2] == h then
			is_resize = true
			break
		end
	end
end

if is_resize and suffix_ ~= 'webp' and suffix_ ~= suffix then
	ngx.exit(404)
end

local src = ngx.var.srcPath .. path .. '.' .. suffix

if not exists(src) then
	ngx.exit(404)
end

local img = image:new(src, 'file')

if img == nil then
	ngx.exit(404)
end

if img:compress(q) == 0 then
	ngx.exit(404)
end

if is_resize then
	if w ~= nil and w > 0 and h ~= nil and h > 0 then
		img:resize(w, h)
	elseif l ~= nil and l > 0 then
		img:resize(l, 0)
	end
end

local si = img:string()
local dst = ngx.var.destPath .. ngx.var.uri

if check(dst) then
	img:save(dst)
end

ngx.print(si)
