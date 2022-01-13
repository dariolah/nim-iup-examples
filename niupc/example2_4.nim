# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_4.c

import niup/niupc

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  # Exits the main loop
  return IUP_CLOSE

proc mainProc =
  var dlg, button, label, vbox: PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  label =  niupc.Label("Hello world from IUP.");
  button = niupc.Button("OK", nil)
  vbox = niupc.Vbox(label,
                  button,
                  nil)
  dlg = niupc.Dialog(vbox)
  SetAttribute(dlg, "TITLE", "Hello World 4")

  # Registers callbacks
  SetCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  MainLoop()

  Close()

if isMainModule:
  mainProc()
