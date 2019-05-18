#
#FFI declarations missing in current Nim IUP module
#
import iup
import dynlib

{.deadCodeElim: on.}

when defined(windows):
  const dllname = "iup(|30|27|26|25|24).dll"
elif defined(macosx):
  const dllname = "libiup(|3.0|2.7|2.6|2.5|2.4).dylib"
else:
  const dllname = "libiup(|3.0|2.7|2.6|2.5|2.4).so(|.1)"

when defined(windows):
  const imglib_dllname = "iupimglib(|30|27|26|25|24).dll"
elif defined(macosx):
  const imglib_dllname = "libiupimglib(|3.0|2.7|2.6|2.5|2.4).dylib"
else:
  const imglib_dllname = "libiupimglib(|3.0|2.7|2.6|2.5|2.4).so(|.1)"

proc setStrAttribute*(ih:PIhandle, name:cstring, value:cstring)
  {.importc: "IupSetStrAttribute", cdecl, dynlib: dllname.}

proc setInt*(ih:PIhandle, name:cstring, value:cint)
  {.importc: "IupSetInt", cdecl, dynlib: dllname.}

proc imageLibOpen*()
  {.importc: "IupImageLibOpen", cdecl, dynlib: imglib_dllname.}

proc config*():PIhandle
  {.importc: "IupConfig", cdecl, dynlib: dllname.}
proc configLoad*(ih:PIhandle):cint
  {.importc: "IupConfigLoad", cdecl, dynlib: dllname.}
proc configSave*(ih:PIhandle):cint
  {.importc: "IupConfigSave", cdecl, dynlib: dllname.}
proc configRecentUpdate*(ih:PIhandle, filename:cstring)
  {.importc: "IupConfigRecentUpdate", cdecl, dynlib: dllname.}
proc configSetVariableStr*(ih:PIhandle, group:cstring, key:cstring, value:cstring)
  {.importc: "IupConfigSetVariableStr", cdecl, dynlib: dllname.}
proc configGetVariableStr*(ih:PIhandle, group:cstring, key:cstring):cstring
  {.importc: "IupConfigGetVariableStr", cdecl, dynlib: dllname.}
proc configGetVariableIntDef*(ih:PIhandle, group:cstring, key:cstring, def:cint):int
  {.importc: "IupConfigGetVariableIntDef", cdecl, dynlib: dllname.}
proc configRecentInit*(ih:PIhandle, menu:PIhandle, recent_cb:Icallback, max_recent:cint)
  {.importc: "IupConfigRecentInit", cdecl, dynlib:dllname.}
proc configDialogShow*(ih:PIhandle, dialog:PIhandle, name:cstring)
  {.importc: "IupConfigDialogShow", cdecl, dynlib: dllname.}
proc configDialogClosed*(ih:PIhandle, dialog:PIhandle, name:cstring)
  {.importc: "IupConfigDialogClosed", cdecl, dynlib: dllname.}

proc clipboard*():PIhandle
  {.importc: "IupClipboard", cdecl, dynlib: dllname.}


# workaround for dlopen(RTLD_GLOBAL) in Linux
# https://forum.nim-lang.org/t/3996
{. passL:"-rdynamic -Wl,-wrap,dlopen".}
{.emit: """
#include <dlfcn.h>

void *__real_dlopen(const char *filename, int flags);

void *__wrap_dlopen(const char *filename, int flags)
{
  return __real_dlopen(filename, flags | RTLD_GLOBAL);
}
""".}
