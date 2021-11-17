# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_6.c

import niup
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


proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = niup.GetDialogChild(ih, "STATUSBAR")
  niup.SetfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return niup.IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  let multitext = niup.GetDialogChild(item_open, "MULTITEXT")
  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_open))

  Popup(filedlg, IUP_CENTER, IUP_CENTER)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    try:
      let str = readFile($filename) # $ converts cstring to string
      # .string converts TaintedString to string
      if str.string != "":
        niup.SetStrAttribute(multitext, "VALUE", str.string)
    except:
      niup.Message("Error", fmt"Fail when reading from file: {filename}");

  niup.Destroy(filedlg)
  return niup.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = niup.GetDialogChild(item_saveas, "MULTITEXT")
  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_saveas))

  Popup(filedlg, IUP_CENTER, IUP_CENTER)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    let str = niup.GetAttribute(multitext, "VALUE")
    try:
      writeFile($filename, $str)
    except:
      niup.Message("Error", fmt"Fail when writing to file: {filename}");

  niup.Destroy(filedlg)
  return niup.IUP_DEFAULT

proc goto_ok_action_cb(bt_ok:PIhandle): int =
  let line_count = niup.GetInt(bt_ok, "TEXT_LINECOUNT")
  let txt = niup.GetDialogChild(bt_ok, "LINE_TEXT")
  let line = niup.GetInt(txt, "VALUE")
  if line < 1 or line >= line_count:
    niup.Message("Error", "Invalid line number.")
    return niup.IUP_DEFAULT

  niup.SetAttribute(niup.GetDialog(bt_ok), "STATUS", "1");
  return niup.IUP_CLOSE

proc goto_cancel_action_cb(bt_ok:PIhandle): int =
  niup.SetAttribute(niup.GetDialog(bt_ok), "STATUS", "0")
  return IUP_CLOSE

proc item_goto_action_cb(item_goto:PIhandle): int =
  let multitext = niup.GetDialogChild(item_goto, "MULTITEXT")
  var dlg, box, bt_ok, bt_cancel, txt, lbl: PIhandle

  let line_count = niup.GetInt(multitext, "LINECOUNT")

  lbl = niup.Label(nil)
  niup.SetfAttribute(lbl, "TITLE", "Line Number [1-%d]:", line_count)
  txt = niup.Text(nil)
  niup.SetAttribute(txt, "MASK", IUP_MASK_UINT)  # unsigned integer numbers only
  niup.SetAttribute(txt, "NAME", "LINE_TEXT")
  niup.SetAttribute(txt, "VISIBLECOLUMNS", "20")
  bt_ok = niup.Button("OK", nil)
  niup.SetInt(bt_ok, "TEXT_LINECOUNT", line_count)
  niup.SetAttribute(bt_ok, "PADDING", "10x2")
  SetCallback(bt_ok, "ACTION", cast[ICallback](goto_ok_action_cb))
  bt_cancel = niup.Button("Cancel", nil)
  SetCallback(bt_cancel, "ACTION", cast[ICallback](goto_cancel_action_cb))
  niup.SetAttribute(bt_cancel, "PADDING", "10x2")

  box = niup.Vbox(
    lbl,
    txt,
    niup.SetAttributes(niup.Hbox(
      niup.Fill(),
      bt_ok,
      bt_cancel,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  niup.SetAttribute(box, "MARGIN", "10x10")
  niup.SetAttribute(box, "GAP", "5")

  dlg = niup.Dialog(box)
  niup.SetAttribute(dlg, "TITLE", "Go To Line")
  niup.SetAttribute(dlg, "DIALOGFRAME", "Yes")
  niup.SetAttributeHandle(dlg, "DEFAULTENTER", bt_ok)
  niup.SetAttributeHandle(dlg, "DEFAULTESC", bt_cancel)
  niup.SetAttributeHandle(dlg, "PARENTDIALOG", niup.GetDialog(item_goto))

  Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(dlg, "STATUS") == 1:
    let line = niup.GetInt(txt, "VALUE")
    var pos:cint
    niup.TextConvertLinColToPos(multitext, line, 0, pos)
    niup.SetInt(multitext, "CARETPOS", pos)
    niup.SetInt(multitext, "SCROLLTOPOS", pos)
    SetFocus(multitext)

  niup.Destroy(dlg)

  return IUP_DEFAULT

proc find_next_action_cb(bt_next:PIhandle): int =
  let multitext = cast[PIhandle](niup.GetAttribute(bt_next, "MULTITEXT"))
  let str = niup.GetAttribute(multitext, "VALUE")
  let find_pos = niup.GetInt(multitext, "FIND_POS")

  let txt = niup.GetDialogChild(bt_next, "FIND_TEXT")
  let str_to_find = niup.GetAttribute(txt, "VALUE")

  let find_case = niup.GetDialogChild(bt_next, "FIND_CASE")
  let casesensitive = niup.GetInt(find_case, "VALUE")

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

    niup.SetInt(multitext, "FIND_POS", cast[cint](end_pos))

    SetFocus(multitext)
    # When using UTF-8 strings in GTK be aware that all attributes are indexed by characters,
    # NOT by byte index, because some characters in UTF-8 can use more than one byte
    niup.SetfAttribute(multitext, "SELECTIONPOS", "%d:%d", unicode_pos, unicode_end_pos)
    niup.TextConvertPosToLinCol(multitext, unicode_pos, lin, col)
    niup.TextConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    niup.SetInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    niup.Message("Warning", "Text not found.")

  return niup.IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle): int =
  Hide(niup.GetDialog(bt_close))
  return niup.IUP_DEFAULT

proc item_find_action_cb(item_find:PIhandle): int =
  var dlg = cast[PIhandle](niup.GetAttribute(item_find, "FIND_DIALOG"))

  if dlg == nil:
    let multitext = niup.GetDialogChild(item_find, "MULTITEXT")
    var box, bt_next, bt_close, txt, find_case:PIhandle

    txt = niup.Text(nil)
    niup.SetAttribute(txt, "NAME", "FIND_TEXT")
    niup.SetAttribute(txt, "VISIBLECOLUMNS", "20")
    find_case = niup.Toggle("Case Sensitive", nil)
    niup.SetAttribute(find_case, "NAME", "FIND_CASE")
    bt_next = niup.Button("Find Next", nil)
    niup.SetAttribute(bt_next, "PADDING", "10x2")
    SetCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
    bt_close = niup.Button("Close", nil)
    SetCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
    niup.SetAttribute(bt_close, "PADDING", "10x2")

    box = niup.Vbox(
      niup.Label("Find What:"),
      txt,
      find_case,
      niup.SetAttributes(niup.Hbox(
        niup.Fill(),
        bt_next,
        bt_close,
        nil), "NORMALIZESIZE=HORIZONTAL"),
      nil);
    niup.SetAttribute(box, "MARGIN", "10x10")
    niup.SetAttribute(box, "GAP", "5")

    dlg = niup.Dialog(box);
    niup.SetAttribute(dlg, "TITLE", "Find")
    niup.SetAttribute(dlg, "DIALOGFRAME", "Yes")
    niup.SetAttributeHandle(dlg, "DEFAULTENTER", bt_next)
    niup.SetAttributeHandle(dlg, "DEFAULTESC", bt_close)
    niup.SetAttributeHandle(dlg, "PARENTDIALOG", niup.GetDialog(item_find))

    # Save the multiline to acess it from the callbacks
    niup.SetAttribute(dlg, "MULTITEXT", cast[cstring](multitext))

    # Save the dialog to reuse it
    niup.SetAttribute(item_find, "FIND_DIALOG", cast[cstring](dlg))

  # centerparent first time, next time reuse the last position
  ShowXY(dlg, IUP_CURRENT, IUP_CURRENT)

  return niup.IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = niup.GetDialogChild(item_font, "MULTITEXT")
  let fontdlg = niup.FontDlg()
  let font = niup.GetAttribute(multitext, "FONT")
  niup.SetStrAttribute(fontdlg, "VALUE", font)
  Popup(fontdlg, IUP_CENTER, IUP_CENTER)

  if niup.GetInt(fontdlg, "STATUS") == 1:
    let font = niup.GetAttribute(fontdlg, "VALUE")
    niup.SetStrAttribute(multitext, "FONT", font)

  niup.Destroy(fontdlg)
  return niup.IUP_DEFAULT

proc item_about_action_cb(): int =
  niup.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niup.IUP_DEFAULT

proc item_exit_action_cb(ih:PIhandle):cint {.cdecl.}=
  return niup.IUP_CLOSE

proc mainProc =
  var dlg, vbox, multitext, menu: niup.PIhandle
  var sub_menu_file, file_menu, item_exit, item_open, item_saveas, btn_open, btn_save: niup.PIhandle
  var sub_menu_edit, edit_menu, item_find, item_goto, btn_find: niup.PIhandle
  var sub_menu_format, format_menu, item_font: niup.PIhandle
  var sub_menu_help, help_menu, item_about: niup.PIhandle
  var lbl_statusbar, toolbar_hb: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)
  niup.ImageLibOpen()

  multitext =  niup.Text(nil)
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")
  niup.SetAttribute(multitext, "NAME", "MULTITEXT");

  lbl_statusbar = niup.Label("Lin 1, Col 1")
  niup.SetAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  niup.SetAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  niup.SetAttribute(lbl_statusbar, "PADDING", "10x5")

  item_open = niup.Item("&Open...\tCtrl+O", nil)
  btn_open = niup.Button(nil, nil)
  niup.SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  niup.SetAttribute(btn_open, "FLAT", "Yes")
  niup.SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  niup.SetAttribute(btn_open, "CANFOCUS", "No")

  item_saveas = niup.Item("Save &As...\tCtrl+S", nil)
  btn_save = niup.Button(nil, nil)
  niup.SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  niup.SetAttribute(btn_save, "FLAT", "Yes")
  niup.SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  niup.SetAttribute(btn_save, "CANFOCUS", "No")

  item_exit = niup.Item("E&xit", nil)

  item_find = niup.Item("&Find...\tCtrl+F", nil)
  btn_find = niup.Button(nil, nil)
  niup.SetAttribute(btn_find, "IMAGE", "IUP_EditFind")
  niup.SetAttribute(btn_find, "FLAT", "Yes")
  niup.SetAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  niup.SetAttribute(btn_find, "CANFOCUS", "No")

  toolbar_hb = niup.Hbox(
    btn_open,
    btn_save,
    niup.SetAttributes(niup.Label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  niup.SetAttribute(toolbar_hb, "MARGIN", "5x5")
  niup.SetAttribute(toolbar_hb, "GAP", "2")

  item_goto = niup.Item("&Go To...\tCtrl+G", nil)
  item_font= niup.Item("&Font...", nil)
  item_about= niup.Item("&About...", nil)

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

  file_menu = niup.Menu(item_open,
                       item_saveas,
                       niup.Separator(),
                       item_exit,
                       nil)
  edit_menu = niup.Menu(item_find,
                      item_goto,
                      nil)
  format_menu = niup.Menu(item_font,
                         nil)
  help_menu = niup.Menu(item_about,
                       nil)

  sub_menu_file = niup.Submenu("&File", file_menu)
  sub_menu_edit = niup.Submenu("&Edit", edit_menu)
  sub_menu_format = niup.Submenu("F&ormat", format_menu)
  sub_menu_help = niup.Submenu("&Help", help_menu)

  menu = niup.Menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = niup.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niup.Dialog(vbox)
  niup.SetAttributeHandle(dlg, "MENU", menu)
  niup.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niup.SetAttribute(dlg, "SIZE", "HALFxHALF")

  # parent for pre-defined dialogs in closed functions (IupMessage)
  niup.SetAttributeHandle(nil, "PARENTDIALOG", dlg);


  SetCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  SetCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  SetCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  SetCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))

  ShowXY(dlg, niup.IUP_CENTERPARENT, niup.IUP_CENTERPARENT)
  niup.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
