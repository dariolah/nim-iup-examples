# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_1.c

import iup

proc mainProc =
  var dlg, multitext, vbox: iup.PIhandle

  discard iup.open(nil, nil)

  multitext =  iup.text(nil);
  vbox = iup.vbox(multitext,
                  nil)
  iup.setAttribute(multitext, "MULTILINE", "YES")
  iup.setAttribute(multitext, "EXPAND", "YES")

  dlg = iup.dialog(vbox)
  iup.setAttribute(dlg, "TITLE", "Simple Notepad")
  iup.setAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  iup.showXY(dlg, iup.IUP_CENTER, iup.IUP_CENTER)
  iup.setAttribute(dlg, "USERSIZE", nil);

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
