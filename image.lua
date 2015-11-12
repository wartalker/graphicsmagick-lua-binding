-- GraphicMagic lua binding --

local ffi = require "ffi"

local _M = {}
_M._VERSION = '0.4'
local mt = { __index = _M }

ffi.cdef
[[
typedef void MagickWand;
typedef void DrawingWand;
typedef void PixelWand;
typedef int MagickBooleanType;
typedef int ExceptionType;
typedef int size_t;


typedef enum
{
  UndefinedFilter,
  PointFilter,
  BoxFilter,
  TriangleFilter,
  HermiteFilter,
  HanningFilter,
  HammingFilter,
  BlackmanFilter,
  GaussianFilter,
  QuadraticFilter,
  CubicFilter,
  CatromFilter,
  MitchellFilter,
  LanczosFilter,
  BesselFilter,
  SincFilter
} FilterTypes;


typedef enum
{
  ForgetGravity,
  NorthWestGravity,
  NorthGravity,
  NorthEastGravity,
  WestGravity,
  CenterGravity,
  EastGravity,
  SouthWestGravity,
  SouthGravity,
  SouthEastGravity,
  StaticGravity
} GravityType;


// Init
void InitializeMagick();

// *** Magick Wand ***
MagickWand* NewMagickWand();
MagickWand* DestroyMagickWand( MagickWand * );

// Free resouse
unsigned int MagickRelinquishMemory( void *resource );

//
char * MagickGetImageFormat( MagickWand *wand );

// Read/Write
MagickBooleanType MagickReadImageBlob( MagickWand*, const void*, const size_t );
unsigned char *MagickWriteImageBlob( MagickWand *wand, size_t *length );
unsigned int MagickWriteImage( MagickWand *wand, const char *filename );
unsigned int MagickReadImage( MagickWand *wand, const char *filename );

// Size
unsigned long MagickGetImageWidth( MagickWand *wand );
unsigned long MagickGetImageHeight( MagickWand *wand );

// Resize
unsigned int MagickResizeImage( MagickWand *wand, const unsigned long columns,
                                const unsigned long rows, const FilterTypes filter,
                                const double blur );

// Quality
unsigned int MagickSetCompressionQuality( MagickWand *wand, const unsigned long quality );

// Remove profile
unsigned int MagickStripImage( MagickWand *wand );

// Annote Text
unsigned int MagickAnnotateImage( MagickWand *wand, const DrawingWand *drawing_wand,
                                  const double x, const double y, const double angle,
                                  const char *text );

// *** Drawing Wand ***
DrawingWand *MagickNewDrawingWand();
void MagickDestroyDrawingWand( DrawingWand *drawing_wand );

// Set text encoding
void MagickDrawSetTextEncoding( DrawingWand *drawing_wand, const char *encoding );

// Font
void MagickDrawSetFont( DrawingWand *drawing_wand, const char *font_name );
void MagickDrawSetFontSize( DrawingWand *drawing_wand, const double pointsize );
void MagickDrawSetFillColor( DrawingWand *drawing_wand, const PixelWand *fill_wand );
void MagickDrawSetGravity( DrawingWand *drawing_wand, const GravityType gravity );

// *** Pixel Wand ***
PixelWand* NewPixelWand();
unsigned int DestroyPixelWand( PixelWand *wand );

// Set color
unsigned int PixelSetColor( PixelWand *wand, const char *color );
]]


local libgm = ffi.load('libGraphicsMagickWand')
libgm.InitializeMagick()

function _M.new(self, img, t)
	local mwand = ffi.gc(libgm.NewMagickWand(), function(w)
		libgm.DestroyMagickWand(w)
	end)

	local r = 0
	if t == 'mem' then
		r = libgm.MagickReadImageBlob(mwand, img, #img)
	elseif t == 'file' then
		r = libgm.MagickReadImage(mwand, img)
	end

	return (r ~= 0) and setmetatable({_mwand = mwand}, mt) or nil
end

function _M.width(self)
	return libgm.MagickGetImageWidth(self._mwand)
end

function _M.height(self)
	return libgm.MagickGetImageHeight(self._mwand)
end

function _M.resize(self, w, h)
	if h == nil or h == 0 then
		local iw = self:width()
		local ih = self:height()
		h = w * ih / iw
	end

	if w == nil or w == 0 then
		local iw = self:width()
		local ih = self:height()
		w = h * iw / ih
	end

	local filter = libgm['LanczosFilter']
	return libgm.MagickResizeImage(self._mwand, w, h, filter, 1.0)
end

function _M.compress(self, quality)
	return libgm.MagickSetCompressionQuality(self._mwand, quality)
end

function _M.strip(self)
	local t = ffi.string(libgm.MagickGetImageFormat(self._mwand))
	if t ~= 'JPEG' then
		return libgm.MagickStripImage(self._mwand)
	else
		return 1
	end
end

function _M.string(self)
	local len = ffi.new('size_t[1]', 0)
	local blob = libgm.MagickWriteImageBlob(self._mwand, len)
	if ffi.cast('void *', blob) > nil then
		local s = ffi.string(blob, len[0])
		libgm.MagickRelinquishMemory(blob)
		return s
	else
		return nil
	end
end

function _M.save(self, path)
	return libgm.MagickWriteImage(self._mwand, path)
end

local function new_pixel_wand()
	local pwand = ffi.gc(libgm.NewPixelWand(), function(w)
			libgm.DestroyPixelWand(w)
	end)
	return pwand
end

local function new_draw_wand()
	local dwand = ffi.gc(libgm.MagickNewDrawingWand(), function(w)
		libgm.MagickDestroyDrawingWand(w)
	end)
	return dwand
end

local function set_font(dwand, path, size, color)
	if libgm.MagickDrawSetFont(dwand, path) == 0 then
		return 0
	end

	if libgm.MagickDrawSetFontSize(dwand, size) == 0 then
		return 0
	end

	local pwand = new_pixel_wand()
	if pwand == nil or libgm.PixelSetColor(pwand, color) == 0 then
		return 0
	end

	return libgm.MagickDrawSetFillColor(dwand, pwand)
end

local function set_gravity(dwand, gravity)
	local g = libgm[gravity .. 'Gravity']
	if g == nil then
		return 0
	end
   	return libgm.MagickDrawSetGravity(dwand, g)
end

function _M.annote(self, path, size, color, pos, text)
	local i, _ = string.find(pos, ':')
	local gravity = string.sub(pos, 0, i-1)
	local j, _ = string.find(pos, 'x', i+1)
	local x = tonumber(string.sub(pos, i+1, j-1))
	local y = tonumber(string.sub(pos, j+1))

	if x == nil or y == nil then
		return 0
	end

	local dwand = new_draw_wand()
	if dwand == nil then
		return 0
	end

	libgm.MagickDrawSetTextEncoding(dwand, 'utf-8')

	if set_font(dwand, path, size, color) == 0 then
		return 0
	end

	if set_gravity(dwand, gravity) == 0 then
		return 0
	end

	return libgm.MagickAnnotateImage(self._mwand, dwand, x, y, 0, text)
end

return _M
