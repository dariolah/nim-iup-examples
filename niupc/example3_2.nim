# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_2.c
import niup/niupc

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return IUP_CLOSE

proc mainProc =
  var dlg, multitext, vbox: PIhandle
  var file_menu, item_exit, item_open, item_saveas: PIhandle
  var sub1_menu, menu: PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  niupc.Text(nil)
  niupc.SetAttribute(multitext, "MULTILINE", "YES")
  niupc.SetAttribute(multitext, "EXPAND", "YES")

  item_open = niupc.Item("Open", nil)
  item_saveas = niupc.Item("Save As", nil)
  item_exit = niupc.Item("Exit", nil)
  SetCallback(item_exit, "ACTION", cast[ICallback](exit_cb))

  file_menu = niupc.Menu(item_open,
                       item_saveas,
                       niupc.Separator(),
                       item_exit,
                       nil)

  sub1_menu = niupc.Submenu("File", file_menu)

  menu = niupc.Menu(sub1_menu, nil)

  vbox = niupc.Vbox(multitext,
                  nil)

  dlg = niupc.Dialog(vbox)
  niupc.SetAttributeHandle(dlg, "MENU", menu)
  niupc.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niupc.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)
  niupc.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  Close()

if isMainModule:
  mainProc()
