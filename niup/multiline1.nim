#/* IupMultiline: Simple Example in C
#   Shows a multiline that ignores the treatment of the DEL key, canceling its effect.
import niup

proc mlaction(self: PIhandle, c: cint, after: cstring): cint {.cdecl.} =
  if c == K_lowerg:
    return IUP_IGNORE
  else:
    return IUP_DEFAULT

proc Main() =
  Open()

  let ml = MultiLine()
  ml.action = mlaction
  ml.expand = "YES"
  ml.value = "I ignore the \"g\" key!"
  ml.border = "YES"

  let dlg = Dialog(ml)
  dlg.title = "IupMultiline"
  dlg.size = "QUARTERxQUARTER"

  Show(dlg)
  MainLoop()
  Close()

if isMainModule:
  Main()
