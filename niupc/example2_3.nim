# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_3.c

import niup/niupc

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  Message("Hello World Message", "Hello World from IUP.")
  # Exits the main loop
  return IUP_CLOSE

proc mainProc =
  var dlg, button, vbox: PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  button = niupc.Button("OK", nil)
  vbox = niupc.Vbox(button,
                  nil)
  dlg = niupc.Dialog(vbox)
  SetAttribute(dlg, "TITLE", "Hello World 3")

  # Registers callbacks
  SetCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  MainLoop()

  Close()

if isMainModule:
  mainProc()
