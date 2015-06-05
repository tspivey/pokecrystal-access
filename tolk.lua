local ffi = require "ffi"
local kernel32 = ffi.load("kernel32")
ffi.cdef[[
void Tolk_Load();
void Tolk_Output(const char *s, bool interrupt);
void Tolk_Silence();
typedef unsigned int UINT;
typedef unsigned int DWORD;
typedef const char * LPCSTR;
typedef wchar_t * LPWSTR;
int MultiByteToWideChar(UINT CodePage,
DWORD    dwFlags,
LPCSTR   lpMultiByteStr, int cbMultiByte,
LPWSTR  lpWideCharStr, int cchWideChar);
]]
local CP_UTF8 = 65001
local tolk = ffi.load("tolk")
tolk.Tolk_Load()
local function to_utf16(s)
local needed = kernel32.MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0)
local buf = ffi.new("wchar_t[?]", needed)
local written = kernel32.MultiByteToWideChar(CP_UTF8, 0, s, -1, buf, needed)
return ffi.string(buf, written*2)
end
local function output(s)
tolk.Tolk_Output(to_utf16(s), false)
end
local function silence()
tolk.Tolk_Silence()
end
return {output=output, silence=silence}
