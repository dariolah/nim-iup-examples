# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_10.c

import niup/niupc
import niup/niupext
import strformat
import unicode
import os

################################# Utilities ##################################

proc str_compare(l:string, r:string, casesensitive:bool): int =
  if l.len == 0 or r.len == 0:
    return 0

  var l_index:int = 0
  var r_index:int = 0
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
    dlg = GetDialog(ih)
    multitext = GetDialogChild(dlg, "MULTITEXT")

  SetAttribute(dlg, "TITLE", "Untitled - Simple Notepad")
  withPIhandle multitext:
    "FILENAME" nil
    "DIRTY" "NO"
    "VALUE" ""

proc open_file(ih:PIhandle, filename:string) =
  try:
    let str = readFile(filename)
    if str != "":
      let
        dlg = GetDialog(ih)
        multitext = GetDialogChild(dlg, "MULTITEXT")
        config = GetAttributeAsPIhandle(multitext, "CONFIG")

      SetfAttribute(dlg, "TITLE", "%s - Simple Notepad", cstring(os.extractFilename(filename)))
      withPIhandle multitext:
        "FILENAME" filename
        "DIRTY" "NO"
        "VALUE" cstring(str)

      ConfigRecentUpdate(config, filename)
  except:
    Message("Error", cstring(fmt"Fail when reading file: {filename}"))

proc save_file(multitext:PIhandle):int =
  let
    filename = GetAttribute(multitext, "FILENAME")
    str = GetAttribute(multitext, "VALUE")
  try:
    if filename != nil:
      writeFile($filename, $str)
    else:
      echo "missing filename!"
    SetAttribute(multitext, "DIRTY", "NO")
  except:
    Message("Error", cstring(fmt"Fail when writing to file: {filename}"))

proc saveas_file(multitext:PIhandle, filename:string) =
  let str = GetAttribute(multitext, "VALUE")
  try:
    writeFile(filename, $str)
    let config = GetAttributeAsPIhandle(multitext, "CONFIG")

    SetfAttribute(GetDialog(multitext), "TITLE", "%s - Simple Notepad", cstring(os.extractFilename(filename)))
    withPIhandle multitext:
      "FILENAME" filename
      "DIRTY" "NO"

    ConfigRecentUpdate(config, filename)
  except:
    Message("Error", cstring(fmt"Fail when writing to file: {filename}"))

proc save_check(ih:PIhandle):bool =
  let
    multitext = GetDialogChild(ih, "MULTITEXT")
    filename = GetAttribute(multitext, "FILENAME")

  if GetBool(multitext, "DIRTY"):
    if filename != nil:
      case Alarm("Warning", "File not saved! Save it now?", "Yes", "No", "Cancel"):
        of 1:  # save the changes and continue
            discard save_file(multitext)
        of 2:  # ignore the changes and continue
          discard
        else:  # cancel
          return false
    else:
      case Alarm("Warning", "File not saved and missing filename! Discard it?", "Yes", "No", "Cancel"):
        of 1:  # discard changes
            discard
        else:  # No
          return false

  return true

proc toggle_bar_visibility(item:PIhandle, ih:PIhandle) =
  if GetBool(item, "VALUE"):
    withPIhandle ih:
      "FLOATING" "YES"
      "VISIBLE" "NO"
    SetAttribute(item, "VALUE", "OFF")
  else:
    withPIhandle ih:
      "FLOATING" "NO"
      "VISIBLE" "YES"
    SetAttribute(item, "VALUE", "ON")

  Refresh(ih)  # refresh the dialog layout

proc set_find_replace_visibility(find_dlg:PIhandle, show_replace:bool) =
  let
    replace_txt = GetDialogChild(find_dlg, "REPLACE_TEXT")
    replace_lbl = GetDialogChild(find_dlg, "REPLACE_LABEL")
    replace_bt = GetDialogChild(find_dlg, "REPLACE_BUTTON")

  if show_replace:
    withPIhandle replace_txt:
      "VISIBLE" "Yes"
      "FLOATING" "No"
    withPIhandle replace_lbl:
      "VISIBLE" "Yes"
      "FLOATING" "No"
    withPIhandle replace_bt:
      "VISIBLE" "Yes"
      "FLOATING" "No"

    SetAttribute(find_dlg, "TITLE", "Replace")
  else:
    withPIhandle replace_txt:
      "VISIBLE" "No"
      "FLOATING" "Yes"
    withPIhandle replace_lbl:
      "VISIBLE" "No"
      "FLOATING" "Yes"
    withPIhandle replace_bt:
      "VISIBLE" "No"
      "FLOATING" "Yes"

    SetAttribute(find_dlg, "TITLE", "Find")

  SetAttribute(find_dlg, "SIZE", nil)  # force a dialog resize on the IupRefresh
  Refresh(find_dlg)

################################# Callbacks ##################################

proc dropfiles_cb(ih:PIhandle, filename:cstring):int =
  if save_check(ih):
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_valuechanged_cb(multitext:PIhandle):int =
  SetAttribute(multitext, "DIRTY", "YES")
  return IUP_DEFAULT

proc file_menu_open_cb(ih:PIhandle):int =
  let
    item_revert = GetDialogChild(ih, "ITEM_REVERT")
    item_save = GetDialogChild(ih, "ITEM_SAVE")
    multitext = GetDialogChild(ih, "MULTITEXT")
    filename = GetAttribute(multitext, "FILENAME")
    dirty = GetBool(multitext, "DIRTY")

  if dirty:
    SetAttribute(item_save, "ACTIVE", "YES")
  else:
    SetAttribute(item_save, "ACTIVE", "NO")

  if dirty and filename != "":
    SetAttribute(item_revert, "ACTIVE", "YES")
  else:
    SetAttribute(item_revert, "ACTIVE", "NO")
  return IUP_DEFAULT

proc edit_menu_open_cb(ih:PIhandle): int =
  let
    clipboard = Clipboard()
    item_paste = GetDialogChild(ih, "ITEM_PASTE")
    item_cut = GetDialogChild(ih, "ITEM_CUT")
    item_delete = GetDialogChild(ih, "ITEM_DELETE")
    item_copy = GetDialogChild(ih, "ITEM_COPY")
    multitext = GetDialogChild(ih, "MULTITEXT")

  if GetInt(clipboard, "TEXTAVAILABLE") == 0:
    SetAttribute(item_paste, "ACTIVE", "NO")
  else:
    SetAttribute(item_paste, "ACTIVE", "YES")

  if GetAttribute(multitext, "SELECTEDTEXT") == nil:
    SetAttribute(item_cut, "ACTIVE", "NO")
    SetAttribute(item_delete, "ACTIVE", "NO")
    SetAttribute(item_copy, "ACTIVE", "NO")
  else:
    SetAttribute(item_cut, "ACTIVE", "YES")
    SetAttribute(item_delete, "ACTIVE", "YES")
    SetAttribute(item_copy, "ACTIVE", "YES")

  Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = GetAttribute(ih, "RECENTFILENAME")
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = GetDialogChild(ih, "STATUSBAR")
  SetfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return IUP_DEFAULT

proc item_new_action_cb(item_new:PIhandle):int =
  if save_check(item_new):
    new_file(item_new)

  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  if not save_check(item_open):
    return IUP_DEFAULT

  let filedlg = FileDlg()
  withPIhandle filedlg:
    "DIALOGTYPE" "OPEN"
    "EXTFILTER" "Text Files|*.txt|All Files|*.*|"
    handle "PARENTDIALOG" GetDialog(item_open)

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if GetInt(filedlg, "STATUS") != -1:
    let filename = GetAttribute(filedlg, "VALUE")
    open_file(item_open, $filename)

  Destroy(filedlg)
  return IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = GetDialogChild(item_saveas, "MULTITEXT")
  let filedlg = FileDlg()
  withPIhandle filedlg:
    "DIALOGTYPE" "SAVE"
    "EXTFILTER" "Text Files|*.txt|All Files|*.*|"
    handle "PARENTDIALOG" GetDialog(item_saveas)
    str "FILE" GetAttribute(multitext, "FILENAME")

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if GetInt(filedlg, "STATUS") != -1:
    let filename = GetAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)

  Destroy(filedlg)
  return IUP_DEFAULT

proc item_save_action_cb(item_save:PIhandle):int =
  let
    multitext = GetDialogChild(item_save, "MULTITEXT")
    filename = GetAttribute(multitext, "FILENAME")
  if filename != "":
    discard item_saveas_action_cb(item_save)
  else:
    # test again because in can be called using the hot key
    let dirty = GetBool(multitext, "DIRTY")
    if dirty:
      discard save_file(multitext)
  return IUP_DEFAULT

proc item_revert_action_cb(item_revert:PIhandle):int =
  let
    multitext = GetDialogChild(item_revert, "MULTITEXT")
    filename = GetAttribute(multitext, "FILENAME")
  open_file(item_revert, $filename)
  return IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint =
  let dlg = GetDialog(item_exit)
  let config = GetAttributeAsPIhandle(dlg, "CONFIG")

  if not save_check(item_exit):
    return IUP_IGNORE  # to abort the CLOSE_CB callback

  ConfigDialogClosed(config, dlg, "MainWindow")
  ConfigSave(config)
  Destroy(config)
  return IUP_CLOSE

proc goto_ok_action_cb(bt_ok:PIhandle): int =
  let line_count = GetInt(bt_ok, "TEXT_LINECOUNT")
  let txt = GetDialogChild(bt_ok, "LINE_TEXT")
  let line = GetInt(txt, "VALUE")
  if line < 1 or line >= line_count:
    Message("Error", "Invalid line number.")
    return IUP_DEFAULT

  SetAttribute(GetDialog(bt_ok), "STATUS", "1");
  return IUP_CLOSE

proc goto_cancel_action_cb(bt_ok:PIhandle): int =
  SetAttribute(GetDialog(bt_ok), "STATUS", "0")
  return IUP_CLOSE

proc item_goto_action_cb(item_goto:PIhandle): int =
  let multitext = GetDialogChild(item_goto, "MULTITEXT")
  var dlg, box, bt_ok, bt_cancel, txt, lbl: PIhandle

  let line_count = GetInt(multitext, "LINECOUNT")

  lbl = Label(nil)
  SetfAttribute(lbl, "TITLE", "Line Number [1-%d]:", line_count)

  txt = Text(nil)
  withPIhandle txt:
    "MASK" IUP_MASK_UINT  # unsigned integer numbers only
    "NAME" "LINE_TEXT"
    "VISIBLECOLUMNS" "20"

  bt_ok = Button("OK", nil)
  withPIhandle bt_ok:
    int "TEXT_LINECOUNT" line_count
    "PADDING" "10x2"
    cb "ACTION" goto_ok_action_cb

  bt_cancel = Button("Cancel", nil)
  withPIhandle bt_cancel:
    cb "ACTION" goto_cancel_action_cb
    "PADDING" "10x2"

  box = Vbox(
    lbl,
    txt,
    SetAttributes(Hbox(
      Fill(),
      bt_ok,
      bt_cancel,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  withPIhandle box:
    "MARGIN" "10x10"
    "GAP" "5"

  dlg = Dialog(box)
  withPIhandle dlg:
    "TITLE" "Go To Line"
    "DIALOGFRAME" "Yes"
    handle "DEFAULTENTER" bt_ok
    handle "DEFAULTESC" bt_cancel
    handle "PARENTDIALOG" GetDialog(item_goto)

  Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if GetInt(dlg, "STATUS") == 1:
    let line = GetInt(txt, "VALUE")
    var pos:cint
    TextConvertLinColToPos(multitext, line, 0, pos)
    withPIhandle multitext:
      int "CARETPOS" pos
      int "SCROLLTOPOS" pos
    SetFocus(multitext)

  Destroy(dlg)

  return IUP_DEFAULT

proc find_next_action_cb(ih:PIhandle): int =
  let find_dlg = GetAttributeAsPIhandle(ih, "FIND_DIALOG")
  if find_dlg == nil:
    return IUP_DEFAULT

  let multitext = GetAttributeAsPIhandle(find_dlg, "MULTITEXT")
  var find_pos = GetInt(multitext, "FIND_POS")

  let txt = GetDialogChild(find_dlg, "FIND_TEXT")
  let str_to_find = GetAttribute(txt, "VALUE")

  let find_case = GetDialogChild(find_dlg, "FIND_CASE")
  let casesensitive = GetInt(find_case, "VALUE")

  # test again, because it can be called from the hot key
  if str_to_find == nil or str_to_find == "":
    return IUP_DEFAULT

  if find_pos == -1:
    find_pos = 0

  let str = GetAttribute(multitext, "VALUE")

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

    SetInt(multitext, "FIND_POS", cast[cint](end_pos))

    SetFocus(multitext)
    # When using UTF-8 strings in GTK be aware that all attributes are indexed by characters,
    # NOT by byte index, because some characters in UTF-8 can use more than one byte
    SetfAttribute(multitext, "SELECTIONPOS", "%d:%d", unicode_pos, unicode_end_pos)
    SetfAttribute(multitext, "FIND_SELECTION", "%d:%d", unicode_pos, unicode_end_pos)

    TextConvertPosToLinCol(multitext, unicode_pos, lin, col)
    TextConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    SetInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    SetInt(multitext, "FIND_POS", -1)
    Message("Warning", "Text not found.")

  return IUP_DEFAULT

proc find_replace_action_cb(bt_replace:PIhandle):int =
  let
    find_dlg = GetAttributeAsPIhandle(bt_replace, "FIND_DIALOG")
    multitext = GetAttributeAsPIhandle(find_dlg, "MULTITEXT")
    find_pos = GetInt(multitext, "FIND_POS")
    selectionpos = GetAttribute(multitext, "SELECTIONPOS")
    find_selection = GetAttribute(multitext, "FIND_SELECTION")

  if find_pos == -1 or selectionpos == nil or find_selection == nil or selectionpos != find_selection:
    discard find_next_action_cb(bt_replace)
  else:
    let
      replace_txt = GetDialogChild(find_dlg, "REPLACE_TEXT")
      str_to_replace = GetAttribute(replace_txt, "VALUE")
    SetAttribute(multitext, "SELECTEDTEXT", str_to_replace)

    # then find next
    discard find_next_action_cb(bt_replace)

  return IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle):int =
  let
    find_dlg = GetDialog(bt_close)
    multitext = GetAttributeAsPIhandle(find_dlg, "MULTITEXT")
    config = GetAttributeAsPIhandle(multitext, "CONFIG")

  ConfigDialogClosed(config, find_dlg, "FindDialog")
  Hide(find_dlg)  # do not destroy, just hide

  return IUP_DEFAULT

proc create_find_dialog(multitext:PIhandle):PIhandle =
  var
    box, bt_next, bt_close, txt, find_case, find_dlg:PIhandle
    txt_replace, bt_replace:PIhandle

  txt = Text(nil)
  withPIhandle txt:
    "NAME" "FIND_TEXT"
    "VISIBLECOLUMNS" "20"

  txt_replace = Text(nil)
  withPIhandle txt_replace:
    "NAME" "REPLACE_TEXT"
    "VISIBLECOLUMNS" "20"

  find_case = Toggle("Case Sensitive", nil)
  SetAttribute(find_case, "NAME", "FIND_CASE")

  bt_next = Button("Find Next", nil)
  withPIhandle bt_next:
    "PADDING" "10x2"
    cb "ACTION" find_next_action_cb

  bt_replace = Button("Replace", nil)
  withPIhandle bt_replace:
    "PADDING" "10x2"
    cb "ACTION" find_replace_action_cb
    "NAME" "REPLACE_BUTTON"

  bt_close = Button("Close", nil)
  withPIhandle bt_close:
    cb "ACTION" find_close_action_cb
    "PADDING" "10x2"

  box = Vbox(
    Label("Find What:"),
    txt,
    SetAttributes(Label("Replace with:"), "NAME=REPLACE_LABEL"),
    txt_replace,
    find_case,
    SetAttributes(Hbox(
      Fill(),
      bt_next,
      bt_replace,
      bt_close,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  withPIhandle box:
    "MARGIN" "10x10"
    "GAP" "5"

  find_dlg = Dialog(box)
  withPIhandle find_dlg:
    "TITLE" "Find"
    "DIALOGFRAME" "Yes"
    handle "DEFAULTENTER" bt_next
    handle "DEFAULTESC" bt_close
    handle "PARENTDIALOG" GetDialog(multitext)
    cb "CLOSE_CB" find_close_action_cb

  # Save the multiline to access it from the callbacks
  SetAttribute(find_dlg, "MULTITEXT", multitext)

  # Save the dialog to reuse it
  SetAttribute(find_dlg, "FIND_DIALOG", find_dlg)  # from itself
  SetAttribute(GetDialog(multitext), "FIND_DIALOG", find_dlg) # from the main dialog

  return find_dlg

proc item_find_action_cb(item_find:PIhandle): int =
  var find_dlg = GetAttributeAsPIhandle(item_find, "FIND_DIALOG")
  let
    multitext = GetDialogChild(item_find, "MULTITEXT")
    config = GetAttributeAsPIhandle(multitext, "CONFIG")

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, false)

  ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = GetDialogChild(find_dlg, "FIND_TEXT")
    SetStrAttribute(txt, "VALUE", str)

  return IUP_DEFAULT

proc item_replace_action_cb(item_replace:PIhandle):int =
  var find_dlg = GetAttributeAsPIhandle(item_replace, "FIND_DIALOG")
  let
    multitext = GetDialogChild(item_replace, "MULTITEXT")
    config = GetAttributeAsPIhandle(multitext, "CONFIG")

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, true)

  ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = GetDialogChild(find_dlg, "FIND_TEXT")
    SetStrAttribute(txt, "VALUE", str)

  return IUP_IGNORE  # replace system processing for the hot key

proc selection_find_next_action_cb(ih:PIhandle):int =
  let multitext = GetDialogChild(ih, "MULTITEXT")

  let str = GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    var find_dlg = GetAttributeAsPIhandle(ih, "FIND_DIALOG")

    if find_dlg == nil:
      find_dlg = create_find_dialog(multitext)

    let txt = GetDialogChild(find_dlg, "FIND_TEXT")
    SetStrAttribute(txt, "VALUE", str)

    discard find_next_action_cb(ih)

  return IUP_DEFAULT

proc item_copy_action_cb(item_copy:PIhandle):int =
  let
    multitext = GetDialogChild(item_copy, "MULTITEXT")
    clipboard = Clipboard()
  SetAttribute(clipboard, "TEXT", GetAttribute(multitext, "SELECTEDTEXT"))
  Destroy(clipboard)
  return IUP_DEFAULT

proc item_paste_action_cb(item_paste:PIhandle):int =
  let
    multitext = GetDialogChild(item_paste, "MULTITEXT")
    clipboard = Clipboard()
  SetAttribute(multitext, "INSERT", GetAttribute(clipboard, "TEXT"))
  Destroy(clipboard)
  return IUP_DEFAULT

proc item_cut_action_cb(item_cut:PIhandle):int =
  let
    multitext = GetDialogChild(item_cut, "MULTITEXT")
    clipboard = Clipboard()
  SetAttribute(clipboard, "TEXT", GetAttribute(multitext, "SELECTEDTEXT"))
  SetAttribute(multitext, "SELECTEDTEXT", "")
  Destroy(clipboard)
  return IUP_DEFAULT

proc item_delete_action_cb(item_delete:PIhandle):int =
  let multitext = GetDialogChild(item_delete, "MULTITEXT")
  SetAttribute(multitext, "SELECTEDTEXT", "")
  return IUP_DEFAULT

proc item_select_all_action_cb(item_select_all:PIhandle):int =
  let multitext = GetDialogChild(item_select_all, "MULTITEXT")
  SetFocus(multitext)
  SetAttribute(multitext, "SELECTION", "ALL")
  return IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = GetDialogChild(item_font, "MULTITEXT")
  let fontdlg = FontDlg()
  let font = GetAttribute(multitext, "FONT")
  SetStrAttribute(fontdlg, "VALUE", font)
  SetAttributeHandle(fontdlg, "PARENTDIALOG", GetDialog(item_font))

  Popup(fontdlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if GetInt(fontdlg, "STATUS") == 1:
    let config = GetAttributeAsPIhandle(multitext, "CONFIG")
    let font = GetAttribute(fontdlg, "VALUE")
    SetStrAttribute(multitext, "FONT", font)
    ConfigSetVariableStr(config, "MainWindow", "Font", font)

  Destroy(fontdlg)
  return IUP_DEFAULT

proc item_toolbar_action_cb(item_toolbar:PIhandle):int =
  let
    multitext = GetDialogChild(item_toolbar, "MULTITEXT")
    toolbar = GetChild(GetParent(multitext), 0)
    config = GetAttributeAsPIhandle(multitext, "CONFIG")

  toggle_bar_visibility(item_toolbar, toolbar)

  ConfigSetVariableStr(config, "MainWindow", "Toolbar", GetAttribute(item_toolbar, "VALUE"))
  return IUP_DEFAULT

proc item_statusbar_action_cb(item_statusbar:PIhandle):int =
  let
    multitext = GetDialogChild(item_statusbar, "MULTITEXT")
    statusbar = GetBrother(multitext)
    config = GetAttributeAsPIhandle(multitext, "CONFIG")

  toggle_bar_visibility(item_statusbar, statusbar)

  ConfigSetVariableStr(config, "MainWindow", "Statusbar", GetAttribute(item_statusbar, "VALUE"))
  return IUP_DEFAULT

proc item_help_action_cb():int =
  Help("http://www.tecgraf.puc-rio.br/iup")
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return IUP_DEFAULT

################################# Main ######################################

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, multitext, menu: PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: PIhandle
    sub_menu_edit, edit_menu, item_find, item_find_next, item_goto: PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: PIhandle
    sub_menu_format, format_menu, item_font, item_replace: PIhandle
    sub_menu_help, help_menu, item_help, item_about: PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar: PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: PIhandle

  multitext =  Text(nil)
  withPIhandle(multitext):
    "MULTILINE" "YES"
    "EXPAND" "YES"
    "NAME" "MULTITEXT"
    "DIRTY" "NO"
    callback "CARET_CB" multitext_caret_cb
    cb "VALUECHANGED_CB" multitext_valuechanged_cb
    cb "DROPFILES_CB" dropfiles_cb

  lbl_statusbar = Label("Lin 1, Col 1")
  withPIhandle lbl_statusbar:
    "NAME" "STATUSBAR"
    "EXPAND" "HORIZONTAL"
    "PADDING" "10x5"

  item_new = Item("New\tCtrl+N", nil)
  withPIhandle item_new:
    "IMAGE" "IUP_FileNew"
    cb "ACTION" item_new_action_cb

  btn_new = Button(nil, nil)
  withPIhandle btn_new:
    "IMAGE" "IUP_FileNew"
    "FLAT" "Yes"
    cb "ACTION" item_new_action_cb
    "TIP" "New (Ctrl+N)"
    "CANFOCUS" "No"

  item_open = Item("&Open...\tCtrl+O", nil)
  withPIhandle item_open:
    "IMAGE" "IUP_FileOpen"
    cb "ACTION" item_open_action_cb

  btn_open = Button(nil, nil)
  withPIhandle btn_open:
    "IMAGE" "IUP_FileOpen"
    "FLAT" "Yes"
    cb "ACTION" item_open_action_cb
    "TIP" "Open (Ctrl+O)"
    "CANFOCUS" "No"

  item_save = Item("Save\tCtrl+S", nil)
  withPIhandle item_save:
    "NAME" "ITEM_SAVE"
    "IMAGE" "IUP_FileSave"
    cb "ACTION" item_save_action_cb

  btn_save = Button(nil, nil)
  withPIhandle btn_save:
    "IMAGE" "IUP_FileSave"
    "FLAT" "Yes"
    cb "ACTION" item_save_action_cb
    "TIP" "Save (Ctrl+S)"
    "CANFOCUS" "No"

  item_saveas = Item("Save &As...\tCtrl+S", nil)
  withPIhandle item_saveas:
    "NAME" "ITEM_SAVEAS"
    cb "ACTION" item_saveas_action_cb

  item_revert = Item("Revert", nil)
  withPIhandle item_revert:
    "NAME" "ITEM_REVERT"
    cb "ACTION" item_revert_action_cb

  item_exit = Item("E&xit", nil)
  SetCallback(item_exit, "ACTION", item_exit_action_cb)

  item_find = Item("&Find...\tCtrl+F", nil)
  withPIhandle item_find:
    "IMAGE" "IUP_EditFind"
    cb "ACTION" item_find_action_cb

  btn_find = Button(nil, nil)
  withPIhandle btn_find:
    "IMAGE" "IUP_EditFind"
    "FLAT" "Yes"
    cb "ACTION" item_find_action_cb
    "TIP" "Find (Ctrl+F)"
    "CANFOCUS" "No"

  item_find_next = Item("Find &Next\tF3", nil)
  withPIhandle item_find_next:
    "NAME" "ITEM_FINDNEXT"
    cb "ACTION" find_next_action_cb

  item_replace = Item("&Replace...\tCtrl+H", nil)
  SetCallback(item_replace, "ACTION", item_replace_action_cb)

  item_cut = Item("Cut\tCtrl+X", nil)
  withPIhandle item_cut:
    "NAME" "ITEM_CUT"
    "IMAGE" "IUP_EditCut"
    cb "ACTION" item_cut_action_cb

  item_copy = Item("Copy\tCtrl+C", nil)
  withPIhandle item_copy:
    "NAME" "ITEM_COPY"
    "IMAGE" "IUP_EditCopy"
    cb "ACTION" item_copy_action_cb

  item_paste = Item("Paste\tCtrl+V", nil)
  withPIhandle item_paste:
    "NAME" "ITEM_PASTE"
    "IMAGE" "IUP_EditPaste"
    cb "ACTION" item_paste_action_cb

  item_delete = Item("Delete\tDel", nil)
  withPIhandle item_delete:
    "NAME" "ITEM_DELETE"
    "IMAGE" "IUP_EditErase"
    cb "ACTION" item_delete_action_cb

  item_select_all = Item("Select All\tCtrl+A", nil)
  SetCallback(item_select_all, "ACTION", item_select_all_action_cb)

  btn_cut = Button(nil, nil)
  withPIhandle btn_cut:
    "IMAGE" "IUP_EditCut"
    "FLAT" "Yes"
    cb "ACTION" item_cut_action_cb
    "TIP" "Cut (Ctrl+X)"
    "CANFOCUS" "No"

  btn_copy = Button(nil, nil)
  withPIhandle btn_copy:
    "IMAGE" "IUP_EditCopy"
    "FLAT" "Yes"
    cb "ACTION" item_copy_action_cb
    "TIP" "Copy (Ctrl+C)"
    "CANFOCUS" "No"

  btn_paste = Button(nil, nil)
  withPIhandle btn_paste:
    "IMAGE" "IUP_EditPaste"
    "FLAT" "Yes"
    cb "ACTION" item_paste_action_cb
    "TIP" "Paste (Ctrl+V)"
    "CANFOCUS" "No"

  toolbar_hb = Hbox(
    btn_new,
    btn_open,
    btn_save,
    SetAttributes(Label(nil), "SEPARATOR=VERTICAL"),
    btn_cut,
    btn_copy,
    btn_paste,
    SetAttributes(Label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  withPIhandle toolbar_hb:
    "MARGIN" "5x5"
    "GAP" "2"

  item_toolbar = Item("&Toobar", nil)
  withPIhandle item_toolbar:
    cb "ACTION" item_toolbar_action_cb
    "VALUE" "ON"

  item_statusbar = Item("&Statusbar", nil)
  withPIhandle item_statusbar:
    cb "ACTION" item_statusbar_action_cb
    "VALUE" "ON"

  item_goto = Item("&Go To...\tCtrl+G", nil)
  SetCallback(item_goto, "ACTION", item_goto_action_cb)

  item_font = Item("&Font...", nil)
  SetCallback(item_font, "ACTION", item_font_action_cb)

  item_help= Item("&Help...", nil)
  SetCallback(item_help, "ACTION", item_help_action_cb)

  item_about = Item("&About...", nil)
  SetCallback(item_about, "ACTION", item_about_action_cb)

  recent_menu = Menu(nil)

  file_menu = Menu(
    item_new,
    item_open,
    item_save,
    item_saveas,
    item_revert,
    Separator(),
    Submenu("Recent &Files", recent_menu),
    item_exit,
    nil)
  edit_menu = Menu(
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    Separator(),
    item_find,
    item_find_next,
    item_replace,
    item_goto,
    Separator(),
    item_select_all,
    nil)
  format_menu = Menu(item_font, nil)
  view_menu = Menu(
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = Menu(item_help, item_about, nil)

  SetCallback(file_menu, "OPEN_CB", file_menu_open_cb)
  SetCallback(edit_menu, "OPEN_CB", edit_menu_open_cb)

  sub_menu_file = Submenu("&File", file_menu)
  sub_menu_edit = Submenu("&Edit", edit_menu)
  sub_menu_format = Submenu("F&ormat", format_menu)
  sub_menu_view = Submenu("&View", view_menu)
  sub_menu_help = Submenu("&Help", help_menu)

  menu = Menu(sub_menu_file,
              sub_menu_edit,
              sub_menu_format,
              sub_menu_view,
              sub_menu_help,
              nil)

  vbox = Vbox(toolbar_hb,
              multitext,
              lbl_statusbar,
              nil)

  dlg = Dialog(vbox)
  withPIhandle dlg:
    "SIZE" "HALFxHALF"
    cb "CLOSECB" item_exit_action_cb
    cb "DROPFILES_CB" dropfiles_cb
    "CONFIG" cast[cstring](config)
    handle "MENU" menu
    cb "K_cN" item_new_action_cb
    cb "K_cO" item_open_action_cb
    cb "K_cS" item_saveas_action_cb
    cb "K_cF" item_find_action_cb
    cb "K_cH" item_replace_action_cb # replace system processing
    cb "K_cG" item_goto_action_cb
    cb "K_F3" find_next_action_cb
    cb "K_cF3" selection_find_next_action_cb
    cb "K_cV" item_paste_action_cb
  # Ctrl+C, Ctrl+X, Ctrl+A, Del, already implemented inside IupText

  # parent for pre-defined dialogs in closed functions (IupMessage and IupAlarm)
  SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  # Initialize variables from the configuration file

  ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  let font = ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    SetStrAttribute(multitext, "FONT", font)

  if ConfigGetVariableIntDef(config, "MainWindow", "Toolbar", 1) == 0:
    SetAttribute(item_toolbar, "VALUE", "OFF")
    withPIhandle toolbar_hb:
      "FLOATING" "YES"
      "VISIBLE" "NO"

  if ConfigGetVariableIntDef(config, "MainWindow", "Statusbar", 1) == 0:
    SetAttribute(item_statusbar, "VALUE", "OFF")
    withPIhandle lbl_statusbar:
      "FLOATING" "YES"
      "VISIBLE" "NO"

  return dlg

proc mainProc =
  Open()
  ImageLibOpen()

  let config:PIhandle = Config()
  SetAttribute(config, "APP_NAME", "simple_notepad")
  ConfigLoad(config)

  let dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  ConfigDialogShow(config, dlg, "MainWindow")

  # initialize the current file
  new_file(dlg)

  # open a file from the command line (allow file association in Windows)
  if paramCount() == 1:
    let filename = paramStr(1)
    open_file(dlg, filename)

  MainLoop()

  Close()

if isMainModule:
  mainProc()

# If instead of using IupText we use IupScintilla, then we can add:
#   - more find/replace options
#   - zoom
#   - show white spaces
#   - margins
#   - word wrap
#   - tab size
#   - auto replace tabs by spaces
#   - undo & redo
#   - markers
#   - line numbers
#   and much more.
#   Hot keys for:
#   - match braces
#   - to lower case
#   - to upper case
#
