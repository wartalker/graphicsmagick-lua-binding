-- GraphicMagic lua binding --

local ffi = require "ffi"

local _M = {}
_M._VERSION = '0.1'
local mt = { __index = _M }

ffi.cdef
[[
  void free(void *);
  typedef void MagickWand;
  typedef int MagickBooleanType;
  typedef int ExceptionType;
  typedef int size_t;

  void InitializeMagick();

  // Magick Wand:
  MagickWand* NewMagickWand();
  MagickWand* DestroyMagickWand( MagickWand * );

  // Free resouse
  unsigned int MagickRelinquishMemory( void *resource );

  // Read/Write:
  MagickBooleanType MagickReadImageBlob( MagickWand*, const void*, const size_t );
  unsigned char *MagickWriteImageBlob( MagickWand *wand, size_t *length );

  // Quality:
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

function _M.compress(self, quality)
	return libgm.MagickSetCompressionQuality(self._wand, quality)
end

function _M.string(self)
	local len = ffi.new('size_t[1]', 0)
	local blob = libgm.MagickWriteImageBlob(self._wand, len)
	local s = ffi.string(blob, len[0])
	libgm.MagickRelinquishMemory(blob)
	return s
end

function _M.strip(self)
	return libgm.MagickStripImage(self._wand)
end

return _M
