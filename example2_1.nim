# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_1.c

import iup

proc mainProc =
  discard iup.open(nil, nil)
  iup.message("Hello World 1", "Hello World from IUP.")
  iup.close()

if isMainModule:
  mainProc()
