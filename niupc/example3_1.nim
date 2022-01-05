# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_1.c

import niup

proc mainProc =
  var dlg, multitext, vbox: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  niup.Text(nil);
  vbox = niup.Vbox(multitext,
                  nil)
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")

  dlg = niupc.Dialog(vbox)
  niupc.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niupc.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, niup.IUP_CENTER, niup.IUP_CENTER)
  niupc.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
