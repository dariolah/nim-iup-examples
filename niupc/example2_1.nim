# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial2.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example2_1.c

import niup/niupc

proc mainProc =
  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)
  Message("Hello World 1", "Hello World from IUP.")
  Close()

if isMainModule:
  mainProc()
