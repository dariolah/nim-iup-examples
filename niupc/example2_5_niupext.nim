# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_5.c
import niup/niupc
import niup/niupext

proc btn_exit_cb(ih:PIhandle):cint {.cdecl.}=
  # Exits the main loop
  return IUP_CLOSE

proc mainProc =
  Open()

  let
    label =  niupc.Label("Hello world from IUP. (/w macros)")
    button = niupc.Button("OK", nil)
    vbox = niupc.Vbox(label, button, nil)

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

  Close()

if isMainModule:
  mainProc()
