# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_4.c

import iup

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  # Exits the main loop
  return iup.IUP_CLOSE

proc mainProc =
  var dlg, button, label, vbox: iup.PIhandle

  discard iup.open(nil, nil)

  label =  iup.label("Hello world from IUP.");
  button = iup.button("OK", nil)
  vbox = iup.vbox(label,
                  button,
                  nil)
  dlg = iup.dialog(vbox)
  iup.setAttribute(dlg, "TITLE", "Hello World 4")

  # Registers callbacks
  discard iup.setCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  iup.showXY(dlg, iup.IUP_CENTER, iup.IUP_CENTER)

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
