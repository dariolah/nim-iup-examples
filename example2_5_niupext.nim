# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_5.c

import niup
import niupext

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  # Exits the main loop
  return niup.IUP_CLOSE

proc mainProc =
  Open()

  let
    label =  Label("Hello world from IUP. (/w macros)")
    button = Button("OK", nil)
    vbox = Vbox(label, button, nil)

  withPIhandle(vbox):
    "ALIGNMENT" "ACENTER"
    "GAP" "10"
    "MARGIN" "10x10"

  let dlg = Dialog(vbox)
  SetAttribute(dlg, "TITLE", "Hello World 5")

  # Registers callbacks
  SetCallback(button, IUP_ACTION, btn_exit_cb)
  # same as
  # SetCallback(button, "ACTION", btn_exit_cb)

  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
