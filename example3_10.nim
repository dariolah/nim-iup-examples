# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_10.c

import iup
import iupfix
import strformat
import unicode
import os

################################# Utilities ##################################

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

proc new_file(ih:PIhandle) =
  let
    dlg = iup.getDialog(ih)
    multitext = iup.getDialogChild(dlg, "MULTITEXT")

  iup.setAttribute(dlg, "TITLE", "Untitled - Simple Notepad");
  iup.setAttribute(multitext, "FILENAME", nil)
  iup.setAttribute(multitext, "DIRTY", "NO")
  iup.setAttribute(multitext, "VALUE", "")

proc open_file(ih:PIhandle, filename:string) =
  try:
    let str = readFile(filename)
    if str.string != "":
      let
        dlg = iup.getDialog(ih)
        multitext = iup.getDialogChild(dlg, "MULTITEXT")
        config = cast[PIhandle](iup.getAttribute(multitext, "CONFIG"))

      iup.setfAttribute(dlg, "TITLE", "%s - Simple Notepad", os.extractFilename(filename))
      iupfix.setStrAttribute(multitext, "FILENAME", filename)
      iup.setAttribute(multitext, "DIRTY", "NO")
      iupfix.setStrAttribute(multitext, "VALUE", str)

      iupfix.configRecentUpdate(config, filename)
  except:
    iup.message("Error", fmt"Fail when reading file: {filename}");

proc save_file(multitext:PIhandle):int =
  let
    filename = iup.getAttribute(multitext, "FILENAME")
    str = iup.getAttribute(multitext, "VALUE")
  try:
    if filename != nil:
      writeFile($filename, $str)
    else:
      echo "missing filename!"
    iup.setAttribute(multitext, "DIRTY", "NO");
  except:
    iup.message("Error", fmt"Fail when writing to file: {filename}");

proc saveas_file(multitext:PIhandle, filename:string) =
  let str = iup.getAttribute(multitext, "VALUE")
  try:
    writeFile(filename, $str)
    let config = cast[PIhandle](iup.getAttribute(multitext, "CONFIG"))

    iup.setfAttribute(iup.getDialog(multitext), "TITLE", "%s - Simple Notepad", os.extractFilename(filename));
    iupfix.setStrAttribute(multitext, "FILENAME", filename);
    iup.setAttribute(multitext, "DIRTY", "NO");

    iupfix.configRecentUpdate(config, filename)
  except:
    iup.message("Error", fmt"Fail when writing to file: {filename}");

proc save_check(ih:PIhandle):bool =
  let
    multitext = iup.getDialogChild(ih, "MULTITEXT")
    filename = iup.getAttribute(multitext, "FILENAME")

  if iup.getInt(multitext, "DIRTY") == 1:
    if filename != nil:
      case iup.alarm("Warning", "File not saved! Save it now?", "Yes", "No", "Cancel"):
        of 1:  # save the changes and continue
            discard save_file(multitext)
        of 2:  # ignore the changes and continue
          discard
        else:  # cancel
          return false
    else:
      case iup.alarm("Warning", "File not saved and missing filename! Discard it?", "Yes", "No", "Cancel"):
        of 1:  # discard changes
            discard
        else:  # No
          return false

  return true

proc toggle_bar_visibility(item:PIhandle, ih:PIhandle) =
  if iup.getInt(item, "VALUE") > 0:
    iup.setAttribute(ih, "FLOATING", "YES")
    iup.setAttribute(ih, "VISIBLE", "NO")
    iup.setAttribute(item, "VALUE", "OFF")
  else:
    iup.setAttribute(ih, "FLOATING", "NO")
    iup.setAttribute(ih, "VISIBLE", "YES")
    iup.setAttribute(item, "VALUE", "ON")

  iup.refresh(ih);  # refresh the dialog layout

################################# Callbacks ##################################

proc dropfiles_cb(ih:PIhandle, filename:cstring):int =
  if save_check(ih):
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_valuechanged_cb(multitext:PIhandle):int =
  iup.setAttribute(multitext, "DIRTY", "YES")
  return IUP_DEFAULT

proc file_menu_open_cb(ih:PIhandle):int =
  let
    item_revert = iup.getDialogChild(ih, "ITEM_REVERT")
    item_save = iup.getDialogChild(ih, "ITEM_SAVE")
    multitext = iup.getDialogChild(ih, "MULTITEXT")
    filename = iup.getAttribute(multitext, "FILENAME")
    dirty = iup.getInt(multitext, "DIRTY")

  if dirty == 1:
    iup.setAttribute(item_save, "ACTIVE", "YES")
  else:
    iup.setAttribute(item_save, "ACTIVE", "NO")

  if dirty == 1 and filename != "":
    iup.setAttribute(item_revert, "ACTIVE", "YES")
  else:
    iup.setAttribute(item_revert, "ACTIVE", "NO")
  return IUP_DEFAULT

proc edit_menu_open_cb(ih:PIhandle): int =
  let
    clipboard = iupfix.clipboard()
    item_paste = iup.getDialogChild(ih, "ITEM_PASTE")
    item_cut = iup.getDialogChild(ih, "ITEM_CUT")
    item_delete = iup.getDialogChild(ih, "ITEM_DELETE")
    item_copy = iup.getDialogChild(ih, "ITEM_COPY")
    multitext = iup.getDialogChild(ih, "MULTITEXT")

  if iup.getInt(clipboard, "TEXTAVAILABLE") == 0:
    iup.setAttribute(item_paste, "ACTIVE", "NO")
  else:
    iup.setAttribute(item_paste, "ACTIVE", "YES")

  if iup.getAttribute(multitext, "SELECTEDTEXT") == nil:
    iup.setAttribute(item_cut, "ACTIVE", "NO")
    iup.setAttribute(item_delete, "ACTIVE", "NO")
    iup.setAttribute(item_copy, "ACTIVE", "NO")
  else:
    iup.setAttribute(item_cut, "ACTIVE", "YES")
    iup.setAttribute(item_delete, "ACTIVE", "YES")
    iup.setAttribute(item_copy, "ACTIVE", "YES")

  iup.destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = iup.getAttribute(ih, "RECENTFILENAME")
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = iup.getDialogChild(ih, "STATUSBAR")
  iup.setfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return iup.IUP_DEFAULT

proc item_new_action_cb(item_new:PIhandle):int =
  if save_check(item_new):
    new_file(item_new)

  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  if not save_check(item_open):
    return IUP_DEFAULT

  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "OPEN")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  iup.setAttributeHandle(filedlg, "PARENTDIALOG", iup.getDialog(item_open))

  iup.popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if iup.getInt(filedlg, "STATUS") != -1:
    let filename = iup.getAttribute(filedlg, "VALUE")
    open_file(item_open, $filename);

  iup.destroy(filedlg)
  return iup.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = iup.getDialogChild(item_saveas, "MULTITEXT")
  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "SAVE")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  iup.setAttributeHandle(filedlg, "PARENTDIALOG", iup.getDialog(item_saveas))
  iupfix.setStrAttribute(filedlg, "FILE", iup.getAttribute(multitext, "FILENAME"))

  iup.popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if iup.getInt(filedlg, "STATUS") != -1:
    let filename = iup.getAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)

  iup.destroy(filedlg)
  return iup.IUP_DEFAULT

proc item_save_action_cb(item_save:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_save, "MULTITEXT")
    filename = iup.getAttribute(multitext, "FILENAME")
  if filename != "":
    discard item_saveas_action_cb(item_save)
  else:
    discard save_file(multitext)
  return IUP_DEFAULT

proc item_revert_action_cb(item_revert:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_revert, "MULTITEXT")
    filename = iup.getAttribute(multitext, "FILENAME")
  open_file(item_revert, $filename)
  return IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint {.cdecl.} =
  let dlg = iup.getDialog(item_exit)
  let config = cast[PIhandle](iup.getAttribute(dlg, "CONFIG"))

  if not save_check(item_exit):
    return IUP_IGNORE  # to abort the CLOSE_CB callback

  iupfix.configDialogClosed(config, dlg, "MainWindow")
  discard iupfix.configSave(config)
  iup.destroy(config)
  return iup.IUP_CLOSE

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

proc item_copy_action_cb(item_copy:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_copy, "MULTITEXT")
    clipboard = iupfix.clipboard()
  iup.setAttribute(clipboard, "TEXT", iup.getAttribute(multitext, "SELECTEDTEXT"))
  iup.destroy(clipboard)
  return IUP_DEFAULT

proc item_paste_action_cb(item_paste:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_paste, "MULTITEXT")
    clipboard = iupfix.clipboard()
  iup.setAttribute(multitext, "INSERT", iup.getAttribute(clipboard, "TEXT"))
  iup.destroy(clipboard)
  return IUP_DEFAULT

proc item_cut_action_cb(item_cut:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_cut, "MULTITEXT")
    clipboard = iupfix.clipboard()
  iup.setAttribute(clipboard, "TEXT", iup.getAttribute(multitext, "SELECTEDTEXT"))
  iup.setAttribute(multitext, "SELECTEDTEXT", "")
  iup.destroy(clipboard)
  return IUP_DEFAULT

proc item_delete_action_cb(item_delete:PIhandle):int =
  let multitext = iup.getDialogChild(item_delete, "MULTITEXT")
  iup.setAttribute(multitext, "SELECTEDTEXT", "")
  return IUP_DEFAULT

proc item_select_all_action_cb(item_select_all:PIhandle):int =
  let multitext = iup.getDialogChild(item_select_all, "MULTITEXT")
  discard iup.setFocus(multitext)
  iup.setAttribute(multitext, "SELECTION", "ALL")
  return IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = iup.getDialogChild(item_font, "MULTITEXT")
  let fontdlg = iup.fontDlg()
  let font = iup.getAttribute(multitext, "FONT")
  #this function is not in Nim IUP module, using local iupfix.nim
  iupfix.setStrAttribute(fontdlg, "VALUE", font)
  iup.setAttributeHandle(fontdlg, "PARENTDIALOG", iup.getDialog(item_font))

  iup.popup(fontdlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if iup.getInt(fontdlg, "STATUS") == 1:
    let config = cast[PIhandle](iup.getAttribute(multitext, "CONFIG"))
    let font = iup.getAttribute(fontdlg, "VALUE")
    #this function is not in Nim IUP module, using local iupfix.nim
    iupfix.setStrAttribute(multitext, "FONT", font)
    iupfix.configSetVariableStr(config, "MainWindow", "Font", font)

  iup.destroy(fontdlg)
  return iup.IUP_DEFAULT

proc item_toolbar_action_cb(item_toolbar:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_toolbar, "MULTITEXT")
    toolbar = iup.getChild(iup.getParent(multitext), 0)
    config = cast[PIhandle](iup.getAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_toolbar, toolbar)

  iupfix.configSetVariableStr(config, "MainWindow", "Toolbar", iup.getAttribute(item_toolbar, "VALUE"))
  return IUP_DEFAULT

proc item_statusbar_action_cb(item_statusbar:PIhandle):int =
  let
    multitext = iup.getDialogChild(item_statusbar, "MULTITEXT")
    statusbar = iup.getBrother(multitext)
    config = cast[PIhandle](iup.getAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_statusbar, statusbar)

  iupfix.configSetVariableStr(config, "MainWindow", "Statusbar", iup.getAttribute(item_statusbar, "VALUE"))
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  iup.message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return iup.IUP_DEFAULT

proc mainProc =
  var
    dlg, vbox, multitext, menu: iup.PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: iup.PIhandle
    sub_menu_edit, edit_menu, item_find, item_goto: iup.PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:iup.PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: iup.PIhandle
    sub_menu_format, format_menu, item_font: iup.PIhandle
    sub_menu_help, help_menu, item_about: iup.PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar: PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: iup.PIhandle

  discard iup.open(nil, nil)
  iupfix.imageLibOpen()

  let config:PIhandle = iupfix.config()
  iup.setAttribute(config, "APP_NAME", "simple_notepad")
  discard iupfix.configLoad(config)

  multitext =  iup.text(nil)
  iup.setAttribute(multitext, "MULTILINE", "YES")
  iup.setAttribute(multitext, "EXPAND", "YES")
  iup.setAttribute(multitext, "NAME", "MULTITEXT")
  iup.setAttribute(multitext, "DIRTY", "NO")
  iup.setCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))
  iup.setCallback(multitext, "VALUECHANGED_CB", cast[ICallback](multitext_valuechanged_cb))
  iup.setCallback(multitext, "DROPFILES_CB", cast[ICallback](dropfiles_cb))

  let font = iupfix.configGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    iupfix.setStrAttribute(multitext, "FONT", font)

  lbl_statusbar = iup.label("Lin 1, Col 1")
  iup.setAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  iup.setAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  iup.setAttribute(lbl_statusbar, "PADDING", "10x5")

  item_new = iup.item("New\tCtrl+N", nil)
  iup.setAttribute(item_new, "IMAGE", "IUP_FileNew")
  iup.setCallback(item_new, "ACTION", cast[ICallback](item_new_action_cb))
  btn_new = iup.button(nil, nil)
  iup.setAttribute(btn_new, "IMAGE", "IUP_FileNew")
  iup.setAttribute(btn_new, "FLAT", "Yes")
  iup.setCallback(btn_new, "ACTION", cast[ICallback](item_new_action_cb))
  iup.setAttribute(btn_new, "TIP", "New (Ctrl+N)")
  iup.setAttribute(btn_new, "CANFOCUS", "No")

  item_open = iup.item("&Open...\tCtrl+O", nil)
  iup.setAttribute(item_open, "IMAGE", "IUP_FileOpen")
  iup.setCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = iup.button(nil, nil)
  iup.setAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  iup.setAttribute(btn_open, "FLAT", "Yes")
  iup.setCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  iup.setAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  iup.setAttribute(btn_open, "CANFOCUS", "No")

  item_save = iup.item("Save\tCtrl+S", nil);
  iup.setAttribute(item_save, "NAME", "ITEM_SAVE")
  iup.setAttribute(item_save, "IMAGE", "IUP_FileSave")
  iup.setCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = iup.button(nil, nil)
  iup.setAttribute(btn_save, "IMAGE", "IUP_FileSave")
  iup.setAttribute(btn_save, "FLAT", "Yes")
  iup.setCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  iup.setAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  iup.setAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = iup.item("Save &As...\tCtrl+S", nil)
  iup.setAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  iup.setCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = iup.item("Revert", nil)
  iup.setAttribute(item_revert, "NAME", "ITEM_REVERT")
  iup.setCallback(item_revert, "ACTION", cast[ICallback](item_revert_action_cb))

  item_exit = iup.item("E&xit", nil)
  iup.setCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))

  item_find = iup.item("&Find...\tCtrl+F", nil)
  iup.setAttribute(item_find, "IMAGE", "IUP_EditFind")
  iup.setCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  btn_find = iup.button(nil, nil)
  iup.setAttribute(btn_find, "IMAGE", "IUP_EditFind")
  iup.setAttribute(btn_find, "FLAT", "Yes")
  iup.setCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  iup.setAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  iup.setAttribute(btn_find, "CANFOCUS", "No")

  item_cut = iup.item("Cut\tCtrl+X", nil)
  iup.setAttribute(item_cut, "NAME", "ITEM_CUT")
  iup.setAttribute(item_cut, "IMAGE", "IUP_EditCut")
  iup.setCallback(item_cut, "ACTION", cast[ICallback](item_cut_action_cb))

  item_copy = iup.item("Copy\tCtrl+C", nil)
  iup.setAttribute(item_copy, "NAME", "ITEM_COPY")
  iup.setAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  iup.setCallback(item_copy, "ACTION", cast[ICallback](item_copy_action_cb))

  item_paste = iup.item("Paste\tCtrl+V", nil)
  iup.setAttribute(item_paste, "NAME", "ITEM_PASTE")
  iup.setAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  iup.setCallback(item_paste, "ACTION", cast[ICallback](item_paste_action_cb))

  item_delete = iup.item("Delete\tDel", nil)
  iup.setAttribute(item_delete, "NAME", "ITEM_DELETE")
  iup.setAttribute(item_delete, "IMAGE", "IUP_EditErase")
  iup.setCallback(item_delete, "ACTION", cast[ICallback](item_delete_action_cb))

  item_select_all = iup.item("Select All\tCtrl+A", nil)
  iup.setCallback(item_select_all, "ACTION", cast[ICallback](item_select_all_action_cb))

  btn_cut = iup.button(nil, nil)
  iup.setAttribute(btn_cut, "IMAGE", "IUP_EditCut")
  iup.setAttribute(btn_cut, "FLAT", "Yes")
  iup.setCallback(btn_cut, "ACTION", cast[ICallback](item_cut_action_cb))
  iup.setAttribute(btn_cut, "TIP", "Cut (Ctrl+X)")
  iup.setAttribute(btn_cut, "CANFOCUS", "No")
  btn_copy = iup.button(nil, nil)
  iup.setAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  iup.setAttribute(btn_copy, "FLAT", "Yes")
  iup.setCallback(btn_copy, "ACTION", cast[ICallback](item_copy_action_cb))
  iup.setAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  iup.setAttribute(btn_copy, "CANFOCUS", "No")
  btn_paste = iup.button(nil, nil)
  iup.setAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  iup.setAttribute(btn_paste, "FLAT", "Yes")
  iup.setCallback(btn_paste, "ACTION", cast[ICallback](item_paste_action_cb))
  iup.setAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  iup.setAttribute(btn_paste, "CANFOCUS", "No")

  toolbar_hb = iup.hbox(
    btn_new,
    btn_open,
    btn_save,
    iup.setAttributes(iup.label(nil), "SEPARATOR=VERTICAL"),
    btn_cut,
    btn_copy,
    btn_paste,
    iup.setAttributes(iup.label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  iup.setAttribute(toolbar_hb, "MARGIN", "5x5")
  iup.setAttribute(toolbar_hb, "GAP", "2")

  item_toolbar = iup.item("&Toobar", nil)
  iup.setCallback(item_toolbar, "ACTION", cast[ICallback](item_toolbar_action_cb))
  iup.setAttribute(item_toolbar, "VALUE", "ON")
  item_statusbar =iup.item("&Statusbar", nil)
  iup.setCallback(item_statusbar, "ACTION", cast[ICallback](item_statusbar_action_cb))
  iup.setAttribute(item_statusbar, "VALUE", "ON")

  if iupfix.configGetVariableIntDef(config, "MainWindow", "Toolbar", 1) == 0:
    iup.setAttribute(item_toolbar, "VALUE", "OFF")

    iup.setAttribute(toolbar_hb, "FLOATING", "YES")
    iup.setAttribute(toolbar_hb, "VISIBLE", "NO")


  if iupfix.configGetVariableIntDef(config, "MainWindow", "Statusbar", 1) == 0:
    iup.setAttribute(item_statusbar, "VALUE", "OFF")

    iup.setAttribute(lbl_statusbar, "FLOATING", "YES")
    iup.setAttribute(lbl_statusbar, "VISIBLE", "NO")

  item_goto = iup.item("&Go To...\tCtrl+G", nil)
  iup.setCallback(item_goto, "ACTION", cast[Icallback](item_goto_action_cb))

  item_font= iup.item("&Font...", nil)
  iup.setCallback(item_font, "ACTION", cast[Icallback](item_font_action_cb))

  item_about= iup.item("&About...", nil)
  iup.setCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

  recent_menu = iup.menu(nil)

  file_menu = iup.menu(
    item_new,
    item_open,
    item_save,
    item_saveas,
    item_revert,
    iup.separator(),
    iup.submenu("Recent &Files", recent_menu),
    item_exit,
    nil)
  edit_menu = iup.menu(
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    iup.separator(),
    item_find,
    item_goto,
    iup.separator(),
    item_select_all,
    nil)
  format_menu = iup.menu(item_font, nil)
  view_menu = iup.menu(
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = iup.menu(item_about, nil)

  iup.setCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  iup.setCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

  sub_menu_file = iup.submenu("&File", file_menu)
  sub_menu_edit = iup.submenu("&Edit", edit_menu)
  sub_menu_format = iup.submenu("F&ormat", format_menu)
  sub_menu_view = iup.submenu("&View", view_menu)
  sub_menu_help = iup.submenu("&Help", help_menu)

  menu = iup.menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_view,
                  sub_menu_help,
                  nil)

  vbox = iup.vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = iup.dialog(vbox)
  iup.setAttributeHandle(dlg, "MENU", menu)
  iup.setAttribute(dlg, "SIZE", "HALFxHALF")
  iup.setCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))
  iup.setCallback(dlg, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  iup.setAttribute(dlg, "CONFIG", cast[cstring](config))

  # parent for pre-defined dialogs in closed functions (IupMessage)
  iup.setAttributeHandle(nil, "PARENTDIALOG", dlg);

  iup.setCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  iup.setCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  iup.setCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  iup.setCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))

  iupfix.configRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  iupfix.configDialogShow(config, dlg, "MainWindow")

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
