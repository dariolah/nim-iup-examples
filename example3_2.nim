# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_2.c

import iup

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return iup.IUP_CLOSE

proc mainProc =
  var dlg, multitext, vbox: iup.PIhandle
  var file_menu, item_exit, item_open, item_saveas: iup.PIhandle
  var sub1_menu, menu: iup.PIhandle

  discard iup.open(nil, nil)

  multitext =  iup.text(nil)
  iup.setAttribute(multitext, "MULTILINE", "YES")
  iup.setAttribute(multitext, "EXPAND", "YES")

  item_open = iup.item("Open", nil)
  item_saveas = iup.item("Save As", nil)
  item_exit = iup.item("Exit", nil)
  discard iup.setCallback(item_exit, "ACTION", cast[ICallback](exit_cb))

  file_menu = iup.menu(item_open,
                       item_saveas,
                       iup.separator(),
                       item_exit,
                       nil)

  sub1_menu = iup.submenu("File", file_menu)

  menu = iup.menu(sub1_menu, nil)

  vbox = iup.vbox(multitext,
                  nil)

  dlg = iup.dialog(vbox)
  iup.setAttributeHandle(dlg, "MENU", menu)
  iup.setAttribute(dlg, "TITLE", "Simple Notepad")
  iup.setAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  iup.showXY(dlg, iup.IUP_CENTER, iup.IUP_CENTER)
  iup.setAttribute(dlg, "USERSIZE", nil);

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
