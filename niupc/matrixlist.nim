import niup
import niupext
import strformat

proc imagevaluechanged_cb(self:PIhandle, item:int, state:int):int =
  echo fmt"imagevaluechanged_cb(item={item}, state={state})\n"
  return IUP_DEFAULT

proc listclick_cb(self:PIhandle, lin:cint, col:int, status:cstring):int =
  var value = GetAttributeId(self, "".cstring, lin)
  if value == nil:
    value = "NULL"
  echo fmt"listclick_cb(lin, col)\n"
  echo fmt"  VALUE{lin}:{col} = {value}\n"
  return IUP_DEFAULT

proc listaction_cb(self:PIhandle, item:int, state:int):int =
  echo fmt"listaction_cb(item={item}, state={state})\n"
  return IUP_DEFAULT

proc mainProc =
  niupext.Open()
  ControlsOpen()

  let mlist = MatrixList()
  SetInt(mlist, "COUNT", 10)
  SetInt(mlist, "VISIBLELINES", 9)
  SetAttribute(mlist, "COLUMNORDER", "LABEL:COLOR:IMAGE")
  #SetAttribute(mlist, "COLUMNORDER", "LABEL:COLOR")
  #SetAttribute(mlist, "COLUMNORDER", "LABEL")
  #SetAttribute(mlist, "ACTIVE", "NO")
  #SetAttribute(mlist, "FOCUSCOLOR", "BGCOLOR")
  SetAttribute(mlist, "SHOWDELETE", "Yes")
  #SetAttribute(mlist, "EXPAND", "Yes")

  SetAttribute(mlist, "EDITABLE", "Yes")
  SetCallback(mlist,"LISTCLICK_CB",cast[Icallback](listclick_cb))
  SetCallback(mlist,"LISTACTION_CB",cast[Icallback](listaction_cb))
  SetCallback(mlist, "IMAGEVALUECHANGED_CB", cast[Icallback](imagevaluechanged_cb))
  
  # Bluish style
  SetAttribute(mlist, "TITLE", "Test")
  SetAttribute(mlist, "BGCOLOR", "220 230 240")
  SetAttribute(mlist, "FRAMECOLOR", "120 140 160")
  SetAttribute(mlist, "ITEMBGCOLOR0", "120 140 160")
  SetAttribute(mlist, "ITEMFGCOLOR0", "255 255 255")
  # ~Bluish style

  SetAttribute(mlist, "1", "AAA")
  SetAttribute(mlist, "2", "BBB")
  SetAttribute(mlist, "3", "CCC")
  SetAttribute(mlist, "4", "DDD")
  SetAttribute(mlist, "5", "EEE")
  SetAttribute(mlist, "6", "FFF")
  SetAttribute(mlist, "7", "GGG")
  SetAttribute(mlist, "8", "HHH")
  SetAttribute(mlist, "9", "III")
  SetAttribute(mlist, "10","JJJ")

  SetAttribute(mlist, "COLOR1", "255 0 0")
  SetAttribute(mlist, "COLOR2", "255 255 0")
  #SetAttribute(mlist, "COLOR3", "0 255 0")
  SetAttribute(mlist, "COLOR4", "0 255 255")
  SetAttribute(mlist, "COLOR5", "0 0 255")
  SetAttribute(mlist, "COLOR6", "255 0 255")
  SetAttribute(mlist, "COLOR7", "255 128 0")
  SetAttribute(mlist, "COLOR8", "255 128 128")
  SetAttribute(mlist, "COLOR9", "0 255 128")
  SetAttribute(mlist, "COLOR10", "128 255 128")

  SetAttribute(mlist, "ITEMACTIVE3", "NO")
  SetAttribute(mlist, "ITEMACTIVE7", "NO")
  SetAttribute(mlist, "ITEMACTIVE8", "NO")

  SetAttribute(mlist, "IMAGEACTIVE9", "No")

  SetAttribute(mlist, "IMAGEVALUE1", "ON")
  SetAttribute(mlist, "IMAGEVALUE2", "ON")
  SetAttribute(mlist, "IMAGEVALUE3", "ON")

  let dlg = Dialog(Vbox(mlist, nil))
  SetAttribute(dlg, "TITLE", "MatrixList")
  SetAttribute(dlg, "MARGIN", "10x10")
  #SetAttribute(dlg, "FONT", "Helvetica, 24")
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  SetAttribute(mlist, "APPENDITEM","KKK")

  MainLoop()
  Close()

if isMainModule:
  mainProc()
