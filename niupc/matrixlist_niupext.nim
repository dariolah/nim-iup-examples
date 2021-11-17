import niup
import niup/niupext
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
  niup.Open()
  ControlsOpen()

  let mlist = MatrixList()
  withPIhandle mlist:
    int "COUNT" 10
    int "VISIBLELINES" 9
    "COLUMNORDER" "LABEL:COLOR:IMAGE"
    "SHOWDELETE" "Yes"
    "EDITABLE" "Yes"
    cb "LISTCLICK_CB" listclick_cb
    cb "LISTACTION_CB" listaction_cb
    cb "IMAGEVALUECHANGED_CB" imagevaluechanged_cb
  
    # Bluish style
    "TITLE" "Test"
    "BGCOLOR" "220 230 240"
    "FRAMECOLOR" "120 140 160"
    "ITEMBGCOLOR0" "120 140 160"
    "ITEMFGCOLOR0" "255 255 255"
    # ~Bluish style

    "1" "AAA"
    "2" "BBB"
    "3" "CCC"
    "4" "DDD"
    "5" "EEE"
    "6" "FFF"
    "7" "GGG"
    "8" "HHH"
    "9" "III"
    "10""JJJ"

    "COLOR1" "255 0 0"
    "COLOR2" "255 255 0"
    "COLOR4" "0 255 255"
    "COLOR5" "0 0 255"
    "COLOR6" "255 0 255"
    "COLOR7" "255 128 0"
    "COLOR8" "255 128 128"
    "COLOR9" "0 255 128"
    "COLOR10" "128 255 128"

    "ITEMACTIVE3" "NO"
    "ITEMACTIVE7" "NO"
    "ITEMACTIVE8" "NO"

    "IMAGEACTIVE9" "No"

    "IMAGEVALUE1" "ON"
    "IMAGEVALUE2" "ON"
    "IMAGEVALUE3" "ON"

  let dlg = Dialog(Vbox(mlist, nil))
  withPIhandle dlg:
    "TITLE" "MatrixList"
    "MARGIN" "10x10"
    #"FONT" "Helvetica, 24"
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  SetAttribute(mlist, "APPENDITEM","KKK")

  MainLoop()
  Close()

if isMainModule:
  mainProc()
