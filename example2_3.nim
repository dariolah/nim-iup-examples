# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_3.c

import niup

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  niup.Message("Hello World Message", "Hello World from IUP.")
  # Exits the main loop
  return niup.IUP_CLOSE

proc mainProc =
  var dlg, button, vbox: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  discard niup.Open(argc, addr argv)

  button = niup.Button("OK", nil)
  vbox = niup.Vbox(button,
                  nil)
  dlg = niup.Dialog(vbox)
  niup.SetAttribute(dlg, "TITLE", "Hello World 3")

  # Registers callbacks
  discard niup.SetCallback(button, "ACTION", cast[ICallback](btn_exit_cb))

  discard niup.ShowXY(dlg, niup.IUP_CENTER, niup.IUP_CENTER)

  discard niup.MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
