# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_3.c

import iup

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  iup.message("Hello World Message", "Hello World from IUP.")
  # Exits the main loop
  return iup.IUP_CLOSE

proc mainProc =
  var dlg, button, vbox: iup.PIhandle

  discard iup.open(nil, nil)

  button = iup.button("OK", nil)
  vbox = iup.vbox(button,
                  nil)
  dlg = iup.dialog(vbox)
  iup.setAttribute(dlg, "TITLE", "Hello World 3")

  # Registers callbacks
  discard iup.setCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  iup.showXY(dlg, iup.IUP_CENTER, iup.IUP_CENTER)

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
