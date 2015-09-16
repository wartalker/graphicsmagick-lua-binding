-- graphic magic lua binding --

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
  MagickWand* DestroyMagickWand(MagickWand*);

  // Read/Write:
  MagickBooleanType MagickReadImageBlob(MagickWand*, const void*, const size_t);
  unsigned char *MagickWriteImageBlob( MagickWand *wand, size_t *length );

  // Quality:
  unsigned int MagickSetCompressionQuality( MagickWand *wand, const unsigned long quality );

  // Remove profile
  unsigned int MagickStripImage( MagickWand *wand );
]]


local libgm = ffi.load('GraphicsMagickWand')
libgm.InitializeMagick();

function _M.new(self, img)
	local wand = ffi.gc(libgm.NewMagickWand(), function(w)
		libgm.DestroyMagickWand(w)
	end)
	local size = #img
	local blob = ffi.new('char['..size..']', img)
	local r = libgm.MagickReadImageBlob(wand, ffi.cast('const void *', blob), size)
	if r ~= 0 then
		return setmetatable({_wand = wand}, mt)
	else
		return nil
	end
end

function _M.compress(self, quality)
	local r = libgm.MagickSetCompressionQuality(self._wand, quality)
	if r ~= 0 then
		local psize = ffi.new('size_t[1]')
		local blob = ffi.gc(libgm.MagickWriteImageBlob(self._wand, psize), ffi.C.free)
		local size = tonumber(psize[0])
		return ffi.string(blob, size)
	else
		return nil
	end
end

function _M.strip(self)
	libgm.MagickStripImage(self._wand)
end

return _M
