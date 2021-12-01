# IupText Example in NIM
# Creates a IupText that shows asterisks instead of characters (password-like).

import niup

var
  pwd: Text_t
  password: string = ""

proc k_any(self: PIhandle, c: cint): cint {.cdecl.} =
  case c
  of K_CR, K_SP, K_ESC, K_INS, K_DEL, K_TAB, K_HOME, K_UP, K_PGUP, K_LEFT, K_MIDDLE, K_RIGHT, K_END, K_DOWN, K_PGDN:
    return IUP_IGNORE
  of K_BS:
    if len(password) == 0:
      return IUP_IGNORE
    password = password[0 .. ^2]
    pwd.value = password
  else:
    return IUP_DEFAULT

proc action(self: PIhandle, c: cint, after: cstring): cint {.cdecl.} =
  if c != 0:
    let ch = char(c)
    password.add(char(c))
    pwd.value = password
  return K_asterisk

proc mainProc() =
  Open(utf8Mode = true)

  let text = Text()
  text.size = "200x"
  text.action = action
  text.k_any = k_any

  pwd = Text()
  pwd.size("200x")
  pwd.readonly = true

  let lb = Label("unsused, WTF")  # without extra control crashes

  let dlg = Dialog(Vbox(text, pwd))
  dlg.title = "IupText"

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  MainLoop()
  Close()

if isMainModule:
  mainProc()
