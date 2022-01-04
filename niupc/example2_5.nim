# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_5.c

import niup

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  # Exits the main loop
  return niup.IUP_CLOSE

proc mainProc =
  var dlg, button, label, vbox: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  label =  niupc.Label("Hello world from IUP.");
  button = niupc.Button("OK", nil)
  vbox = niupc.Vbox(label,
                  button,
                  nil)
  niup.SetAttribute(vbox, "ALIGNMENT", "ACENTER");
  niup.SetAttribute(vbox, "GAP", "10");
  niup.SetAttribute(vbox, "MARGIN", "10x10");

  dlg = niupc.Dialog(vbox)
  niup.SetAttribute(dlg, "TITLE", "Hello World 5")

  # Registers callbacks
  SetCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  ShowXY(dlg, niup.IUP_CENTER, niup.IUP_CENTER)

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
