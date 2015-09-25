-- GraphicMagic lua binding --

local ffi = require "ffi"

local _M = {}
_M._VERSION = '0.2'
local mt = { __index = _M }

ffi.cdef
[[
void free(void *);
typedef void MagickWand;
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
	JincFilter,
	SincFilter,
	SincFastFilter,
	KaiserFilter,
	WelshFilter,
	ParzenFilter,
	BohmanFilter,
	BartlettFilter,
	LagrangeFilter,
	LanczosFilter,
	LanczosSharpFilter,
	Lanczos2Filter,
	Lanczos2SharpFilter,
	RobidouxFilter,
	RobidouxSharpFilter,
	CosineFilter,
	SplineFilter,
	LanczosRadiusFilter,
	SentinelFilter
} FilterTypes;


// Init
void InitializeMagick();

// Magick Wand
MagickWand* NewMagickWand();
MagickWand* DestroyMagickWand( MagickWand * );

// Free resouse
unsigned int MagickRelinquishMemory( void *resource );

// Read/Write
MagickBooleanType MagickReadImageBlob( MagickWand*, const void*, const size_t );
unsigned char *MagickWriteImageBlob( MagickWand *wand, size_t *length );
unsigned int MagickWriteImage( MagickWand *wand, const char *filename );

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
]]


local libgm = ffi.load('GraphicsMagickWand')
libgm.InitializeMagick()

function _M.new(self, img)
	local wand = ffi.gc(libgm.NewMagickWand(), function(w)
		libgm.DestroyMagickWand(w)
	end)
	local r = libgm.MagickReadImageBlob(wand, img, #img)
	return (r ~= 0) and setmetatable({_wand = wand}, mt) or nil
end

function _M.width(self)
	return libgm.MagickGetImageWidth(self._wand)
end

function _M.height(self)
	return libgm.MagickGetImageHeight(self._wand)
end

function _M.resize(self, w, h)
	assert(w ~= nil)
	if h == nil then
		local iw, ih = self.width(), self.height()
		if iw > ih then
			h = w*ih/iw
		else
			local t = w
			h = t
			w = t*iw/ih
		end
	end

	local filter = libgm['LanczosFilter']
	return libgm.MagickResizeImage(self._wand, w, h, filter, 1.0)
end

function _M.compress(self, quality)
	assert(0 <= quality and quality <= 100)
	return libgm.MagickSetCompressionQuality(self._wand, quality)
end

function _M.strip(self)
	return libgm.MagickStripImage(self._wand)
end

function _M.string(self)
	local len = ffi.new('size_t[1]', 0)
	local blob = libgm.MagickWriteImageBlob(self._wand, len)
	local s = ffi.string(blob, len[0])
	libgm.MagickRelinquishMemory(blob)
	return s
end

function _M.save(self, path)
	return libgm.MagickWriteImage(self._wand, path)
end

return _M
