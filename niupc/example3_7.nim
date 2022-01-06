# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_7.c

import niup/niupc
import strformat
import unicode

proc str_compare(l:string, r:string, casesensitive:bool): int =
  if l.len == 0 or r.len == 0:
    return 0

  var l_index:int = 0
  var r_index:int = 0
  var diff:int
  var l_rune:Rune
  var r_rune:Rune

  while l_index < l.len and r_index < r.len:
    # in case of unicode, multiple bytes are consumed
    # compute the difference of both characters
    fastRuneAt(l, l_index, l_rune, doInc=true)
    fastRuneAt(r, r_index, r_rune, doInc=true)
    # if they differ we have a result
    if casesensitive:
      if not (l_rune == r_rune):
        return 0
    else:
      if not (unicode.toLower(l_rune) == unicode.toLower(r_rune)):
        return 0

  # check also for terminator
  if l_index == l.len and r_index == r.len:
    return l_index

  if r_index <= r.len:
    return l_index  # if second string is at terminator, then it is partially equal

  return 0

proc str_find(str:string, str_to_find:string, casesensitive:int): int =
  var i, count: int

  if str.len == 0 or str_to_find.len == 0:
    return -1

  count = str.len - str_to_find.len
  if count < 0:
    return -1

  inc(count)

  i = 0
  while i < count:
    let case_p:bool = (casesensitive==1)
    let bytes = str_compare(substr(str, i), str_to_find, case_p)
    if  bytes > 0:
      return i

    inc(i)

  return -1

#********************************** Callbacks *****************************************

proc config_recent_cb(ih:PIhandle): int =
  let filename = niupc.GetAttribute(ih, "RECENTFILENAME")
  let str = readFile($filename)
  if str.string != "":
    let multitext = niupc.GetDialogChild(ih, "MULTITEXT")
    niupc.SetStrAttribute(multitext, "VALUE", str)

  return IUP_DEFAULT

proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = niupc.GetDialogChild(ih, "STATUSBAR")
  niupc.SetfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return niupc.IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  let multitext = niupc.GetDialogChild(item_open, "MULTITEXT")
  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_open))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    try:
      let str = readFile($filename) # $ converts cstring to string
      # .string converts TaintedString to string
      if str.string != "":
        let config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))
        niupc.ConfigRecentUpdate(config, filename)
        niupc.SetStrAttribute(multitext, "VALUE", str.string)
    except:
      niupc.Message("Error", fmt"Fail when reading from file: {filename}");

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = niupc.GetDialogChild(item_saveas, "MULTITEXT")
  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_saveas))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    let str = niupc.GetAttribute(multitext, "VALUE")
    try:
      writeFile($filename, $str)
      niupc.ConfigRecentUpdate(config, filename)
    except:
      niupc.Message("Error", fmt"Fail when writing to file: {filename}");

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc goto_ok_action_cb(bt_ok:PIhandle): int =
  let line_count = niupc.GetInt(bt_ok, "TEXT_LINECOUNT")
  let txt = niupc.GetDialogChild(bt_ok, "LINE_TEXT")
  let line = niupc.GetInt(txt, "VALUE")
  if line < 1 or line >= line_count:
    niupc.Message("Error", "Invalid line number.")
    return niupc.IUP_DEFAULT

  niupc.SetAttribute(niupc.GetDialog(bt_ok), "STATUS", "1");
  return niupc.IUP_CLOSE

proc goto_cancel_action_cb(bt_ok:PIhandle): int =
  niupc.SetAttribute(niupc.GetDialog(bt_ok), "STATUS", "0")
  return IUP_CLOSE

proc item_goto_action_cb(item_goto:PIhandle): int =
  let multitext = niupc.GetDialogChild(item_goto, "MULTITEXT")
  var dlg, box, bt_ok, bt_cancel, txt, lbl: PIhandle

  let line_count = niupc.GetInt(multitext, "LINECOUNT")

  lbl = niupc.Label(nil)
  niupc.SetfAttribute(lbl, "TITLE", "Line Number [1-%d]:", line_count)
  txt = niupc.Text(nil)
  niupc.SetAttribute(txt, "MASK", IUP_MASK_UINT)  # unsigned integer numbers only
  niupc.SetAttribute(txt, "NAME", "LINE_TEXT")
  niupc.SetAttribute(txt, "VISIBLECOLUMNS", "20")
  bt_ok = niupc.Button("OK", nil)
  niupc.SetInt(bt_ok, "TEXT_LINECOUNT", line_count)
  niupc.SetAttribute(bt_ok, "PADDING", "10x2")
  SetCallback(bt_ok, "ACTION", cast[ICallback](goto_ok_action_cb))
  bt_cancel = niupc.Button("Cancel", nil)
  SetCallback(bt_cancel, "ACTION", cast[ICallback](goto_cancel_action_cb))
  niupc.SetAttribute(bt_cancel, "PADDING", "10x2")

  box = niupc.Vbox(
    lbl,
    txt,
    niupc.SetAttributes(niupc.Hbox(
      niupc.Fill(),
      bt_ok,
      bt_cancel,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  niupc.SetAttribute(box, "MARGIN", "10x10")
  niupc.SetAttribute(box, "GAP", "5")

  dlg = niupc.Dialog(box)
  niupc.SetAttribute(dlg, "TITLE", "Go To Line")
  niupc.SetAttribute(dlg, "DIALOGFRAME", "Yes")
  niupc.SetAttributeHandle(dlg, "DEFAULTENTER", bt_ok)
  niupc.SetAttributeHandle(dlg, "DEFAULTESC", bt_cancel)
  niupc.SetAttributeHandle(dlg, "PARENTDIALOG", niupc.GetDialog(item_goto))

  Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(dlg, "STATUS") == 1:
    let line = niupc.GetInt(txt, "VALUE")
    var pos:cint
    niupc.TextConvertLinColToPos(multitext, line, 0, pos)
    niupc.SetInt(multitext, "CARETPOS", pos)
    niupc.SetInt(multitext, "SCROLLTOPOS", pos)
    SetFocus(multitext)

  niupc.Destroy(dlg)

  return IUP_DEFAULT

proc find_next_action_cb(bt_next:PIhandle): int =
  let multitext = cast[PIhandle](niupc.GetAttribute(bt_next, "MULTITEXT"))
  let str = niupc.GetAttribute(multitext, "VALUE")
  let find_pos = niupc.GetInt(multitext, "FIND_POS")

  let txt = niupc.GetDialogChild(bt_next, "FIND_TEXT")
  let str_to_find = niupc.GetAttribute(txt, "VALUE")

  let find_case = niupc.GetDialogChild(bt_next, "FIND_CASE")
  let casesensitive = niupc.GetInt(find_case, "VALUE")

  var pos:cint = cast[cint](str_find(substr($str,find_pos), $str_to_find, casesensitive))
  if pos >= 0:
    pos += find_pos
  elif find_pos > 0:
    pos = cast[cint](str_find($str, $str_to_find, casesensitive))  # try again from the start

  if pos >= 0:
    # we need number of unicode characters
    var unicode_pos:cint = cast[cint](unicode.toRunes(substr($str,0,pos)).len - 1)
    var lin, col:cint
    let end_pos = pos + len($str_to_find)
    # we need number of unicode characters
    let unicode_end_pos = unicode_pos + unicode.toRunes($str_to_find).len

    niupc.SetInt(multitext, "FIND_POS", cast[cint](end_pos))

    SetFocus(multitext)
    # When using UTF-8 strings in GTK be aware that all attributes are indexed by characters,
    # NOT by byte index, because some characters in UTF-8 can use more than one byte
    niupc.SetfAttribute(multitext, "SELECTIONPOS", "%d:%d", unicode_pos, unicode_end_pos)
    niupc.TextConvertPosToLinCol(multitext, unicode_pos, lin, col)
    niupc.TextConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    niupc.SetInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    niupc.Message("Warning", "Text not found.")

  return niupc.IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle): int =
  Hide(niupc.GetDialog(bt_close))
  return niupc.IUP_DEFAULT

proc item_find_action_cb(item_find:PIhandle): int =
  var dlg = cast[PIhandle](niupc.GetAttribute(item_find, "FIND_DIALOG"))

  if dlg == nil:
    let multitext = niupc.GetDialogChild(item_find, "MULTITEXT")
    var box, bt_next, bt_close, txt, find_case:PIhandle

    txt = niupc.Text(nil)
    niupc.SetAttribute(txt, "NAME", "FIND_TEXT")
    niupc.SetAttribute(txt, "VISIBLECOLUMNS", "20")
    find_case = niupc.Toggle("Case Sensitive", nil)
    niupc.SetAttribute(find_case, "NAME", "FIND_CASE")
    bt_next = niupc.Button("Find Next", nil)
    niupc.SetAttribute(bt_next, "PADDING", "10x2")
    SetCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
    bt_close = niupc.Button("Close", nil)
    SetCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
    niupc.SetAttribute(bt_close, "PADDING", "10x2")

    box = niupc.Vbox(
      niupc.Label("Find What:"),
      txt,
      find_case,
      niupc.SetAttributes(niupc.Hbox(
        niupc.Fill(),
        bt_next,
        bt_close,
        nil), "NORMALIZESIZE=HORIZONTAL"),
      nil);
    niupc.SetAttribute(box, "MARGIN", "10x10")
    niupc.SetAttribute(box, "GAP", "5")

    dlg = niupc.Dialog(box);
    niupc.SetAttribute(dlg, "TITLE", "Find")
    niupc.SetAttribute(dlg, "DIALOGFRAME", "Yes")
    niupc.SetAttributeHandle(dlg, "DEFAULTENTER", bt_next)
    niupc.SetAttributeHandle(dlg, "DEFAULTESC", bt_close)
    niupc.SetAttributeHandle(dlg, "PARENTDIALOG", niupc.GetDialog(item_find))

    # Save the multiline to acess it from the callbacks
    niupc.SetAttribute(dlg, "MULTITEXT", cast[cstring](multitext))

    # Save the dialog to reuse it
    niupc.SetAttribute(item_find, "FIND_DIALOG", cast[cstring](dlg))

  # centerparent first time, next time reuse the last position
  ShowXY(dlg, IUP_CURRENT, IUP_CURRENT)

  return niupc.IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = niupc.GetDialogChild(item_font, "MULTITEXT")
  let fontdlg = niupc.FontDlg()
  let font = niupc.GetAttribute(multitext, "FONT")
  niupc.SetStrAttribute(fontdlg, "VALUE", font)
  niupc.SetAttributeHandle(fontdlg, "PARENTDIALOG", niupc.GetDialog(item_font))

  Popup(fontdlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(fontdlg, "STATUS") == 1:
    let config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))
    let font = niupc.GetAttribute(fontdlg, "VALUE")
    niupc.SetStrAttribute(multitext, "FONT", font)
    niupc.ConfigSetVariableStr(config, "MainWindow", "Font", font)

  niupc.Destroy(fontdlg)
  return niupc.IUP_DEFAULT

proc item_about_action_cb(): int =
  niupc.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niupc.IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint {.cdecl.} =
  let dlg = niupc.GetDialog(item_exit)
  let config = cast[PIhandle](niupc.GetAttribute(dlg, "CONFIG"))
  niupc.ConfigDialogClosed(config, dlg, "MainWindow")
  ConfigSave(config)
  niupc.Destroy(config)
  return niupc.IUP_CLOSE

proc mainProc =
  var dlg, vbox, multitext, menu: niupc.PIhandle
  var sub_menu_file, file_menu, item_exit, item_open, item_saveas, btn_open, btn_save: niupc.PIhandle
  var sub_menu_edit, edit_menu, item_find, item_goto, btn_find: niupc.PIhandle
  var sub_menu_format, format_menu, item_font: niupc.PIhandle
  var sub_menu_help, help_menu, item_about: niupc.PIhandle
  var lbl_statusbar, toolbar_hb, recent_menu: niupc.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)
  niupc.ImageLibOpen()

  let config:PIhandle = niupc.Config()
  niupc.SetAttribute(config, "APP_NAME", "simple_notepad")
  ConfigLoad(config)

  multitext =  niupc.Text(nil)
  niupc.SetAttribute(multitext, "MULTILINE", "YES")
  niupc.SetAttribute(multitext, "EXPAND", "YES")
  niupc.SetAttribute(multitext, "NAME", "MULTITEXT");

  let font = niupc.ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    niupc.SetStrAttribute(multitext, "FONT", font)

  lbl_statusbar = niupc.Label("Lin 1, Col 1")
  niupc.SetAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  niupc.SetAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  niupc.SetAttribute(lbl_statusbar, "PADDING", "10x5")

  item_open = niupc.Item("&Open...\tCtrl+O", nil)
  btn_open = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  niupc.SetAttribute(btn_open, "FLAT", "Yes")
  niupc.SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  niupc.SetAttribute(btn_open, "CANFOCUS", "No")

  item_saveas = niupc.Item("Save &As...\tCtrl+S", nil)
  btn_save = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  niupc.SetAttribute(btn_save, "FLAT", "Yes")
  niupc.SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  niupc.SetAttribute(btn_save, "CANFOCUS", "No")

  item_exit = niupc.Item("E&xit", nil)

  item_find = niupc.Item("&Find...\tCtrl+F", nil)
  btn_find = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_find, "IMAGE", "IUP_EditFind")
  niupc.SetAttribute(btn_find, "FLAT", "Yes")
  niupc.SetAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  niupc.SetAttribute(btn_find, "CANFOCUS", "No")

  toolbar_hb = niupc.Hbox(
    btn_open,
    btn_save,
    niupc.SetAttributes(niupc.Label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  niupc.SetAttribute(toolbar_hb, "MARGIN", "5x5")
  niupc.SetAttribute(toolbar_hb, "GAP", "2")

  item_goto = niupc.Item("&Go To...\tCtrl+G", nil)
  item_font= niupc.Item("&Font...", nil)
  item_about= niupc.Item("&About...", nil)

  SetCallback(item_open, "ACTION", cast[ICallback](item_open_action_cb))
  SetCallback(btn_open, "ACTION", cast[ICallback](item_open_action_cb))
  SetCallback(item_saveas, "ACTION", cast[ICallback](item_saveas_action_cb))
  SetCallback(btn_save, "ACTION", cast[ICallback](item_saveas_action_cb))
  SetCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))
  SetCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  SetCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  SetCallback(item_goto, "ACTION", cast[ICallback](item_goto_action_cb))
  SetCallback(item_font, "ACTION", cast[ICallback](item_font_action_cb))
  SetCallback(item_about, "ACTION", cast[ICallback](item_about_action_cb))
  SetCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))

  recent_menu = niupc.Menu(nil)

  file_menu = niupc.Menu(item_open,
                       item_saveas,
                       niupc.Separator(),
                       niupc.Submenu("Recent &Files", recent_menu),
                       item_exit,
                       nil)
  edit_menu = niupc.Menu(item_find,
                      item_goto,
                      nil)
  format_menu = niupc.Menu(item_font,
                         nil)
  help_menu = niupc.Menu(item_about,
                       nil)

  sub_menu_file = niupc.Submenu("&File", file_menu)
  sub_menu_edit = niupc.Submenu("&Edit", edit_menu)
  sub_menu_format = niupc.Submenu("F&ormat", format_menu)
  sub_menu_help = niupc.Submenu("&Help", help_menu)

  menu = niupc.Menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = niupc.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niupc.Dialog(vbox)
  niupc.SetAttributeHandle(dlg, "MENU", menu)
  niupc.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niupc.SetAttribute(dlg, "SIZE", "HALFxHALF")
  SetCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))

  niupc.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  # parent for pre-defined dialogs in closed functions (IupMessage)
  niupc.SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  SetCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  SetCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  SetCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  SetCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))

  niupc.ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  niupc.ConfigDialogShow(config, dlg, "MainWindow")

  MainLoop()

  niupc.Close()

if isMainModule:
  mainProc()
