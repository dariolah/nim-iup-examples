# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_1.c

import niup/niupc

proc mainProc =
  var dlg, multitext, vbox: PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  Text(nil);
  vbox = Vbox(multitext,
                  nil)
  SetAttribute(multitext, "MULTILINE", "YES")
  SetAttribute(multitext, "EXPAND", "YES")

  dlg = niupc.Dialog(vbox)
  niupc.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niupc.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)
  niupc.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  Close()

if isMainModule:
  mainProc()
