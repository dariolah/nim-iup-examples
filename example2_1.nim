# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_1.c

import niup

proc mainProc =
  var argc:cint=0
  var argv:cstringArray=nil
  discard niup.Open(argc, addr argv)
  niup.Message("Hello World 1", "Hello World from IUP.")
  niup.Close()

if isMainModule:
  mainProc()
