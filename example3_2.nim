# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_2.c

import niup

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return niup.IUP_CLOSE

proc mainProc =
  var dlg, multitext, vbox: niup.PIhandle
  var file_menu, item_exit, item_open, item_saveas: niup.PIhandle
  var sub1_menu, menu: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  niup.Text(nil)
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")

  item_open = niup.Item("Open", nil)
  item_saveas = niup.Item("Save As", nil)
  item_exit = niup.Item("Exit", nil)
  SetCallback(item_exit, "ACTION", cast[ICallback](exit_cb))

  file_menu = niup.Menu(item_open,
                       item_saveas,
                       niup.Separator(),
                       item_exit,
                       nil)

  sub1_menu = niup.Submenu("File", file_menu)

  menu = niup.Menu(sub1_menu, nil)

  vbox = niup.Vbox(multitext,
                  nil)

  dlg = niup.Dialog(vbox)
  niup.SetAttributeHandle(dlg, "MENU", menu)
  niup.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niup.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, niup.IUP_CENTER, niup.IUP_CENTER)
  niup.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
