# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_6.c

import iup
import iupfix
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
  let lbl_statusbar = iup.getDialogChild(ih, "STATUSBAR")
  iup.setfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return iup.IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  let multitext = iup.getDialogChild(item_open, "MULTITEXT")
  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "OPEN")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  iup.setAttributeHandle(filedlg, "PARENTDIALOG", iup.getDialog(item_open))

  iup.popup(filedlg, IUP_CENTER, IUP_CENTER)

  if iup.getInt(filedlg, "STATUS") != -1:
    let filename = iup.getAttribute(filedlg, "VALUE")
    try:
      let str = readFile($filename) # $ converts cstring to string
      # .string converts TaintedString to string
      if str.string != "":
        #this function is not in Nim IUP module, using local iupfix.nim
        iupfix.setStrAttribute(multitext, "VALUE", str.string)
    except:
      iup.message("Error", fmt"Fail when reading from file: {filename}");

  iup.destroy(filedlg)
  return iup.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = iup.getDialogChild(item_saveas, "MULTITEXT")
  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "SAVE")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  iup.setAttributeHandle(filedlg, "PARENTDIALOG", iup.getDialog(item_saveas))

  iup.popup(filedlg, IUP_CENTER, IUP_CENTER)

  if iup.getInt(filedlg, "STATUS") != -1:
    let filename = iup.getAttribute(filedlg, "VALUE")
    let str = iup.getAttribute(multitext, "VALUE")
    try:
      writeFile($filename, $str)
    except:
      iup.message("Error", fmt"Fail when writing to file: {filename}");

  iup.destroy(filedlg)
  return iup.IUP_DEFAULT

proc goto_ok_action_cb(bt_ok:PIhandle): int =
  let line_count = iup.getInt(bt_ok, "TEXT_LINECOUNT")
  let txt = iup.getDialogChild(bt_ok, "LINE_TEXT")
  let line = iup.getInt(txt, "VALUE")
  if line < 1 or line >= line_count:
    iup.message("Error", "Invalid line number.")
    return iup.IUP_DEFAULT

  iup.setAttribute(iup.getDialog(bt_ok), "STATUS", "1");
  return iup.IUP_CLOSE

proc goto_cancel_action_cb(bt_ok:PIhandle): int =
  iup.setAttribute(iup.getDialog(bt_ok), "STATUS", "0")
  return IUP_CLOSE

proc item_goto_action_cb(item_goto:PIhandle): int =
  let multitext = iup.getDialogChild(item_goto, "MULTITEXT")
  var dlg, box, bt_ok, bt_cancel, txt, lbl: PIhandle

  let line_count = iup.getInt(multitext, "LINECOUNT")

  lbl = iup.label(nil)
  iup.setfAttribute(lbl, "TITLE", "Line Number [1-%d]:", line_count)
  txt = iup.text(nil)
  iup.setAttribute(txt, "MASK", IUP_MASK_UINT)  # unsigned integer numbers only
  iup.setAttribute(txt, "NAME", "LINE_TEXT")
  iup.setAttribute(txt, "VISIBLECOLUMNS", "20")
  bt_ok = iup.button("OK", nil)
  iupfix.setInt(bt_ok, "TEXT_LINECOUNT", line_count)
  iup.setAttribute(bt_ok, "PADDING", "10x2")
  iup.setCallback(bt_ok, "ACTION", cast[ICallback](goto_ok_action_cb))
  bt_cancel = iup.button("Cancel", nil)
  iup.setCallback(bt_cancel, "ACTION", cast[ICallback](goto_cancel_action_cb))
  iup.setAttribute(bt_cancel, "PADDING", "10x2")

  box = iup.vbox(
    lbl,
    txt,
    iup.setAttributes(iup.hbox(
      iup.fill(),
      bt_ok,
      bt_cancel,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  iup.setAttribute(box, "MARGIN", "10x10")
  iup.setAttribute(box, "GAP", "5")

  dlg = iup.dialog(box)
  iup.setAttribute(dlg, "TITLE", "Go To Line")
  iup.setAttribute(dlg, "DIALOGFRAME", "Yes")
  iup.setAttributeHandle(dlg, "DEFAULTENTER", bt_ok)
  iup.setAttributeHandle(dlg, "DEFAULTESC", bt_cancel)
  iup.setAttributeHandle(dlg, "PARENTDIALOG", iup.getDialog(item_goto))

  iup.popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if iup.getInt(dlg, "STATUS") == 1:
    let line = iup.getInt(txt, "VALUE")
    var pos:cint
    iup.textConvertLinColToPos(multitext, line, 0, pos)
    iupfix.setInt(multitext, "CARETPOS", pos)
    iupfix.setInt(multitext, "SCROLLTOPOS", pos)
    discard iup.setFocus(multitext)

  iup.destroy(dlg)

  return IUP_DEFAULT

proc find_next_action_cb(bt_next:PIhandle): int =
  let multitext = cast[PIhandle](iup.getAttribute(bt_next, "MULTITEXT"))
  let str = iup.getAttribute(multitext, "VALUE")
  let find_pos = iup.getInt(multitext, "FIND_POS")

  let txt = iup.getDialogChild(bt_next, "FIND_TEXT")
  let str_to_find = iup.getAttribute(txt, "VALUE")

  let find_case = iup.getDialogChild(bt_next, "FIND_CASE")
  let casesensitive = iup.getInt(find_case, "VALUE")

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

    iupfix.setInt(multitext, "FIND_POS", cast[cint](end_pos))

    discard iup.setFocus(multitext)
    # When using UTF-8 strings in GTK be aware that all attributes are indexed by characters,
    # NOT by byte index, because some characters in UTF-8 can use more than one byte
    iup.setfAttribute(multitext, "SELECTIONPOS", "%d:%d", unicode_pos, unicode_end_pos)
    iup.textConvertPosToLinCol(multitext, unicode_pos, lin, col)
    iup.textConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    iupfix.setInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    iup.message("Warning", "Text not found.")

  return iup.IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle): int =
  iup.hide(iup.getDialog(bt_close))
  return iup.IUP_DEFAULT

proc item_find_action_cb(item_find:PIhandle): int =
  var dlg = cast[PIhandle](iup.getAttribute(item_find, "FIND_DIALOG"))

  if dlg == nil:
    let multitext = iup.getDialogChild(item_find, "MULTITEXT")
    var box, bt_next, bt_close, txt, find_case:PIhandle

    txt = iup.text(nil)
    iup.setAttribute(txt, "NAME", "FIND_TEXT")
    iup.setAttribute(txt, "VISIBLECOLUMNS", "20")
    find_case = iup.toggle("Case Sensitive", nil)
    iup.setAttribute(find_case, "NAME", "FIND_CASE")
    bt_next = iup.button("Find Next", nil)
    iup.setAttribute(bt_next, "PADDING", "10x2")
    iup.setCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
    bt_close = iup.button("Close", nil)
    iup.setCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
    iup.setAttribute(bt_close, "PADDING", "10x2")

    box = iup.vbox(
      iup.label("Find What:"),
      txt,
      find_case,
      iup.setAttributes(iup.hbox(
        iup.fill(),
        bt_next,
        bt_close,
        nil), "NORMALIZESIZE=HORIZONTAL"),
      nil);
    iup.setAttribute(box, "MARGIN", "10x10")
    iup.setAttribute(box, "GAP", "5")

    dlg = iup.dialog(box);
    iup.setAttribute(dlg, "TITLE", "Find")
    iup.setAttribute(dlg, "DIALOGFRAME", "Yes")
    iup.setAttributeHandle(dlg, "DEFAULTENTER", bt_next)
    iup.setAttributeHandle(dlg, "DEFAULTESC", bt_close)
    iup.setAttributeHandle(dlg, "PARENTDIALOG", iup.getDialog(item_find))

    # Save the multiline to acess it from the callbacks
    iup.setAttribute(dlg, "MULTITEXT", cast[cstring](multitext))

    # Save the dialog to reuse it
    iup.setAttribute(item_find, "FIND_DIALOG", cast[cstring](dlg))

  # centerparent first time, next time reuse the last position
  iup.showXY(dlg, IUP_CURRENT, IUP_CURRENT)

  return iup.IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = iup.getDialogChild(item_font, "MULTITEXT")
  let fontdlg = iup.fontDlg()
  let font = iup.getAttribute(multitext, "FONT")
  #this function is not in Nim IUP module, using local iupfix.nim
  iupfix.setStrAttribute(fontdlg, "VALUE", font)
  iup.popup(fontdlg, IUP_CENTER, IUP_CENTER)

  if iup.getInt(fontdlg, "STATUS") == 1:
    let font = iup.getAttribute(fontdlg, "VALUE")
    #this function is not in Nim IUP module, using local iupfix.nim
    iupfix.setStrAttribute(multitext, "FONT", font)

  iup.destroy(fontdlg)
  return iup.IUP_DEFAULT

proc item_about_action_cb(): int =
  iup.message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return iup.IUP_DEFAULT

proc item_exit_action_cb(ih:PIhandle):cint {.cdecl.}=
  return iup.IUP_CLOSE

proc mainProc =
  var dlg, vbox, multitext, menu: iup.PIhandle
  var sub_menu_file, file_menu, item_exit, item_open, item_saveas, btn_open, btn_save: iup.PIhandle
  var sub_menu_edit, edit_menu, item_find, item_goto, btn_find: iup.PIhandle
  var sub_menu_format, format_menu, item_font: iup.PIhandle
  var sub_menu_help, help_menu, item_about: iup.PIhandle
  var lbl_statusbar, toolbar_hb: iup.PIhandle

  discard iup.open(nil, nil)
  iupfix.imageLibOpen()

  multitext =  iup.text(nil)
  iup.setAttribute(multitext, "MULTILINE", "YES")
  iup.setAttribute(multitext, "EXPAND", "YES")
  iup.setAttribute(multitext, "NAME", "MULTITEXT");

  lbl_statusbar = iup.label("Lin 1, Col 1")
  iup.setAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  iup.setAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  iup.setAttribute(lbl_statusbar, "PADDING", "10x5")

  item_open = iup.item("&Open...\tCtrl+O", nil)
  btn_open = iup.button(nil, nil)
  iup.setAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  iup.setAttribute(btn_open, "FLAT", "Yes")
  iup.setAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  iup.setAttribute(btn_open, "CANFOCUS", "No")

  item_saveas = iup.item("Save &As...\tCtrl+S", nil)
  btn_save = iup.button(nil, nil)
  iup.setAttribute(btn_save, "IMAGE", "IUP_FileSave")
  iup.setAttribute(btn_save, "FLAT", "Yes")
  iup.setAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  iup.setAttribute(btn_save, "CANFOCUS", "No")

  item_exit = iup.item("E&xit", nil)

  item_find = iup.item("&Find...\tCtrl+F", nil)
  btn_find = iup.button(nil, nil)
  iup.setAttribute(btn_find, "IMAGE", "IUP_EditFind")
  iup.setAttribute(btn_find, "FLAT", "Yes")
  iup.setAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  iup.setAttribute(btn_find, "CANFOCUS", "No")

  toolbar_hb = iup.hbox(
    btn_open,
    btn_save,
    iup.setAttributes(iup.label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  iup.setAttribute(toolbar_hb, "MARGIN", "5x5")
  iup.setAttribute(toolbar_hb, "GAP", "2")

  item_goto = iup.item("&Go To...\tCtrl+G", nil)
  item_font= iup.item("&Font...", nil)
  item_about= iup.item("&About...", nil)

  discard iup.setCallback(item_open, "ACTION", cast[ICallback](item_open_action_cb))
  discard iup.setCallback(btn_open, "ACTION", cast[ICallback](item_open_action_cb))
  discard iup.setCallback(item_saveas, "ACTION", cast[ICallback](item_saveas_action_cb))
  discard iup.setCallback(btn_save, "ACTION", cast[ICallback](item_saveas_action_cb))
  discard iup.setCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))
  discard iup.setCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  discard iup.setCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  discard iup.setCallback(item_goto, "ACTION", cast[ICallback](item_goto_action_cb))
  discard iup.setCallback(item_font, "ACTION", cast[ICallback](item_font_action_cb))
  discard iup.setCallback(item_about, "ACTION", cast[ICallback](item_about_action_cb))
  discard iup.setCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))

  file_menu = iup.menu(item_open,
                       item_saveas,
                       iup.separator(),
                       item_exit,
                       nil)
  edit_menu = iup.menu(item_find,
                      item_goto,
                      nil)
  format_menu = iup.menu(item_font,
                         nil)
  help_menu = iup.menu(item_about,
                       nil)

  sub_menu_file = iup.submenu("&File", file_menu)
  sub_menu_edit = iup.submenu("&Edit", edit_menu)
  sub_menu_format = iup.submenu("F&ormat", format_menu)
  sub_menu_help = iup.submenu("&Help", help_menu)

  menu = iup.menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = iup.vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = iup.dialog(vbox)
  iup.setAttributeHandle(dlg, "MENU", menu)
  iup.setAttribute(dlg, "TITLE", "Simple Notepad")
  iup.setAttribute(dlg, "SIZE", "HALFxHALF")

  # parent for pre-defined dialogs in closed functions (IupMessage)
  iup.setAttributeHandle(nil, "PARENTDIALOG", dlg);


  iup.setCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  iup.setCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  iup.setCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  iup.setCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))

  iup.showXY(dlg, iup.IUP_CENTERPARENT, iup.IUP_CENTERPARENT)
  iup.setAttribute(dlg, "USERSIZE", nil);

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
