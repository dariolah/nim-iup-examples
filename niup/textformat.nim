import niup
import strformat

proc text2multiline(ih: PIhandle, attribute: string) =
  let
    mltline = GetDialogChild(ih, "mltline")
    text = GetDialogChild(ih, "text")

  SetAttribute(mltline, attribute, GetAttribute(text, "VALUE"))

proc multiline2text(ih: PIhandle, attribute: string) =
  let
    mltline = GetDialogChild(ih, "mltline")
    text = GetDialogChild(ih, "text")
  SetAttribute(text, "VALUE", GetAttribute(mltline, attribute))

proc btn_append_cb(ih: PIhandle): cint {.cdecl.} =
  text2multiline(ih, "APPEND")
  return IUP_DEFAULT

proc btn_insert_cb(ih: PIhandle): cint {.cdecl.} =
  text2multiline(ih, "INSERT")
  return IUP_DEFAULT

proc btn_clip_cb(ih: PIhandle): cint {.cdecl.} =
  text2multiline(ih, "CLIPBOARD")
  return IUP_DEFAULT

proc btn_key_cb(ih: PIhandle): cint {.cdecl.} =
  let
    mltline = GetDialogChild(ih, "mltline")
    #text = GetDialogChild(ih, "text")
  SetFocus(mltline)
  Flush()
  return IUP_DEFAULT

proc btn_caret_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "CARET")
  else:
    multiline2text(ih, "CARET")
  return IUP_DEFAULT

proc btn_readonly_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "READONLY")
  else:
    multiline2text(ih, "READONLY")
  return IUP_DEFAULT

proc btn_selection_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "SELECTION")
  else:
    multiline2text(ih, "SELECTION")
  return IUP_DEFAULT

proc btn_selectedtext_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "SELECTEDTEXT")
  else:
    multiline2text(ih, "SELECTEDTEXT")
  return IUP_DEFAULT

proc btn_overwrite_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "OVERWRITE")
  else:
    multiline2text(ih, "OVERWRITE")
  return IUP_DEFAULT

proc btn_active_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "ACTIVE")
  else:
    multiline2text(ih, "ACTIVE")
  return IUP_DEFAULT

proc btn_remformat_cb(ih: PIhandle): cint {.cdecl.} =
  text2multiline(ih, "REMOVEFORMATTING")
  return IUP_DEFAULT

proc btn_nc_cb(ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "NC")
  else:
    multiline2text(ih, "NC")
  return IUP_DEFAULT

proc btn_value_cb (ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "VALUE")
  else:
    multiline2text(ih, "VALUE")
  return IUP_DEFAULT

proc btn_tabsize_cb (ih: PIhandle): cint {.cdecl.} =
  let opt = GetHandle("text2multi")
  if GetInt(opt, "VALUE") != 0:
    text2multiline(ih, "TABSIZE")
  else:
    multiline2text(ih, "TABSIZE")
  return IUP_DEFAULT

proc k_f2(ih: PIhandle, c: cint): cint {.cdecl.} =
  echo "K_F2\n"
  return IUP_DEFAULT

proc file_open() =
  var
    buffer: array[1000, char]
    filename = cstring(addr buffer)
  GetFile(filename)  #// test key after dlg in multiline
  echo filename

proc file_open(ih: PIhandle, c: cint): cint {.cdecl.} =
  file_open()
  return IUP_DEFAULT

proc iupKeyCodeToName(code: cint): cstring {.importc: "iupKeyCodeToName", dynlib: "libiup.so", cdecl.}

proc k_any(ih: PIhandle, c: cint): cint {.cdecl.} =
  if iup_isprint(c):
    echo &"K_ANY({c} = {iupKeyCodeToName(c)} \'{char(c)}\')\n"
  else:
    echo &"K_ANY({c} = {iupKeyCodeToName(c)})\n"

  echo &"  CARET({GetAttribute(ih, \"CARET\")})\n"
  if c == K_cupperA:
    return IUP_IGNORE   #// Sound a beep in Windows
  if c == K_cupperO:
    file_open()
    return IUP_IGNORE   #// Sound a beep in Windows
  return IUP_CONTINUE

proc action(ih: PIhandle, c: cint, after: cstring): cint {.cdecl.} =
  if iup_isprint(c):
    echo &"ACTION({c} = {iupKeyCodeToName(c)} \'{char(c)}\', {after})\n"
  else:
    echo &"ACTION({c} = {iupKeyCodeToName(c)}, {after})\n"

  if char(c) == 'i':
    return IUP_IGNORE   #// OK
  if c == K_cupperD:
    return IUP_IGNORE   #// Sound a beep in Windows
  if char(c) == 'h':
    return ord('j')
  return IUP_DEFAULT

proc caret_cb(ih: PIhandle, lin, col, pos: cint): cint {.cdecl.} =
  echo &"CARET_CB({lin}, {col} - {pos})\n"
  echo &"  CARET({GetAttribute(ih, \"CARET\")} - {GetAttribute(ih, \"CARETPOS\")})\n"
  return IUP_DEFAULT

proc getfocus_cb(ih: PIhandle): cint {.cdecl.} =
  echo "GETFOCUS_CB()\n"
  return IUP_DEFAULT

proc help_cb(ih: PIhandle): cint {.cdecl.} =
  echo "HELP_CB()\n"
  return IUP_DEFAULT

proc killfocus_cb(ih: PIhandle): cint {.cdecl.} =
  echo "KILLFOCUS_CB()\n"
  return IUP_DEFAULT

proc leavewindow_cb(ih: PIhandle): cint {.cdecl.} =
  echo "LEAVEWINDOW_CB()\n"
  return IUP_DEFAULT

proc enterwindow_cb(ih: PIhandle): cint {.cdecl.} =
  echo "ENTERWINDOW_CB()\n"
  return IUP_DEFAULT

proc btn_def_esc_cb(ih: PIhandle): cint {.cdecl.} =
  echo "DEFAULTESC\n"
  return IUP_DEFAULT

proc btn_def_enter_cb(ih: PIhandle): cint {.cdecl.} =
  echo "DEFAULTENTER\n"
  return IUP_DEFAULT

proc dropfiles_cb(ih: PIhandle, filename: cstring, num, x, y: cint): cint {.cdecl.} =
  echo &"DROPFILES_CB({filename}, {num}, x={x}, y={y})\n"
  return IUP_DEFAULT

proc button_cb(ih: PIhandle, but, pressed, x, y: cint, status: cstring): cint {.cdecl.} =
  var lin, col: cint
  echo &"BUTTON_CB(but={char(but)} ({pressed}), x={x}, y={y} [{status}])\n"
  let pos = ConvertXYToPos(ih, x, y)
  TextConvertPosToLinCol(ih, pos, lin, col)
  echo &"         (lin={lin}, col={col}, pos={pos})\n"
  return IUP_DEFAULT

proc motion_cb(ih: PIhandle, x, y: cint, status: cstring): cint {.cdecl.} =
  var lin, col: cint
  echo &"MOTION_CB(x={x}, y={y} [{status}])\n"
  let pos = ConvertXYToPos(ih, x, y)
  TextConvertPosToLinCol(ih, pos, lin, col)
  echo &"         (lin={lin}, col={col}, pos={pos})\n"
  return IUP_DEFAULT

proc TextTest() =
  #//  IupSetGlobal("UTF8AUTOCONVERT", "NO")

  var text = Text()
  text.expand("HORIZONTAL")
  #//  text."VALUE", "Single Line Text")
  text.cuebanner = "Enter Attribute Value Here"
  text.name = "text"
  text.tip = "Attribute Value"

  var opt = Toggle("Set/Get")
  opt.value = "ON"
  SetHandle("text2multi", opt)

  var mltline = MultiLine()
  mltline.name = "mltline"

  #//  SetAttribute(mltline, "WORDWRAP", "YES")
  #//  SetAttribute(mltline, "BORDER", "NO")
  #//  SetAttribute(mltline, "AUTOHIDE", "YES")
  #//  SetAttribute(mltline, "BGCOLOR", "255 0 128")
  #//  SetAttribute(mltline, "FGCOLOR", "0 128 192")
  #//  SetAttribute(mltline, "PADDING", "15x15")
  mltline.value = "First Line\nSecond Line Big Big Big\nThird Line\nmore\nmore\n莽茫玫谩贸茅" # UTF-8
  #mltline.value = "First Line\nSecond Line Big Big Big\nThird Line\nmore\nmore\n玢踽箝") # Windows-1252
  mltline.tip = "First Line\nSecond Line\nThird Line"
  #//  SetAttribute(mltline, "FONT", "Helvetica, 14")
  #//  SetAttribute(mltline, "MASK", IUP_MASK_FLOAT)
  #//  SetAttribute(mltline, "FILTER", "UPPERCASE")
  #//  SetAttribute(mltline, "ALIGNMENT", "ACENTER")
  #//  SetAttribute(mltline, "CANFOCUS", "NO")

  # Turns on multiline expand and text horizontal expand */
  mltline.size(80, 40)
  mltline.expand = "YES"

  #//  SetAttribute(mltline, "FONT", "Courier, 16")
  #//  SetAttribute(mltline, "FONT", "Arial, 12")
  #//    SetAttribute(mltline, "FORMATTING", "YES")

  # formatting before Map */
  mltline.formatting = true

  var formattag = niup.User()
  formattag.alignment = "CENTER"
  formattag.spaceafter = "10"
  formattag.fontsize = "24"
  formattag.selection = "3,1:3,50"
  mltline.addformattag_handle = formattag

  formattag = User()
  formattag.bgcolor(255, 128, 64)
  formattag.underline = "SINGLE"
  formattag.weight = "BOLD"
  formattag.selection = "3,7:3,11"
  mltline.addformattag_handle = formattag

  # Creates buttons */
  #//  btn_append = IupButton ("APPEND 玢踽箝", NULL)   // Windows-1252
  #//  btn_append = IupButton ("APPEND 莽茫玫谩贸茅", NULL)  // UTF-8
  var
    btn_append = Button("&APPEND")
    btn_insert = Button("INSERT")
    btn_caret = Button("CARET")
    btn_readonly = Button("READONLY")
    btn_selection = Button("SELECTION")
    btn_selectedtext = Button("SELECTEDTEXT")
    btn_nc = Button("NC")
    btn_value = Button("VALUE")
    btn_tabsize = Button("TABSIZE")
    btn_clip = Button("CLIPBOARD")
    btn_key = Button("KEY")
    btn_def_enter = Button("Default Enter")
    btn_def_esc = Button("Default Esc")
    btn_active = Button("ACTIVE")
    btn_remformat = Button("REMOVEFORMATTING")
    btn_overwrite = Button("OVERWRITE")

  btn_append.tip = "First Line\nSecond Line\nThird Line"

  let lbl = Label("&Multiline:")
  lbl.padding = "2x2"

  # Creates dlg */
  let dlg = Dialog(Vbox(lbl,
                mltline,
                Hbox(text, opt),
                Hbox(btn_append, btn_insert, btn_caret, btn_readonly, btn_selection),
                Hbox(btn_selectedtext, btn_nc, btn_value, btn_tabsize, btn_clip, btn_key),
                Hbox(btn_def_enter, btn_def_esc, btn_active, btn_remformat, btn_overwrite)))
  dlg.k_cupperO = file_open
  dlg.title = "IupText Test"
  dlg.margin(10, 10)
  dlg.gap = 5
  dlg.defaultenter = btn_def_enter
  dlg.defaultesc = btn_def_esc
  dlg.shrink = true

  Map(dlg)

  # formatting after Map */
  formattag = User()
  formattag.italic = true
  formattag.strikeout = true
  formattag.selection = "2,1:2,12"
  mltline.addformattag_handle = formattag

  # CALLBACKS
  mltline.dropfiles_cb = dropfiles_cb
  mltline.button_cb = button_cb
  #//  mltline.motion_cb = motion_cb
  mltline.help_cb = help_cb
  mltline.getfocus_cb = getfocus_cb
  mltline.killfocus_cb = killfocus_cb
  mltline.enterwindow_cb = enterwindow_cb
  mltline.leavewindow_cb = leavewindow_cb
  #//mltline.action = action
  mltline.k_any = k_any
  mltline.k_f2 = k_f2
  mltline.caret_cb = caret_cb

  btn_append.action = btn_append_cb
  btn_insert.action = btn_insert_cb
  btn_caret.action = btn_caret_cb
  btn_readonly.action = btn_readonly_cb
  btn_selection.action = btn_selection_cb
  btn_selectedtext.action = btn_selectedtext_cb
  btn_nc.action = btn_nc_cb
  btn_value.action = btn_value_cb
  btn_tabsize.action = btn_tabsize_cb
  btn_clip.action = btn_clip_cb
  btn_key.action = btn_key_cb
  btn_def_enter.action = btn_def_enter_cb
  btn_def_esc.action = btn_def_esc_cb
  btn_active.action = btn_active_cb
  btn_remformat.action = btn_remformat_cb
  btn_overwrite.action = btn_overwrite_cb

  # Shows dlg in the center of the screen */
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)
  SetFocus(mltline)


proc MainProc() =
  Open(utf8Mode = true)
  TextTest()
  MainLoop()
  Close()

if isMainModule:
  MainProc()
