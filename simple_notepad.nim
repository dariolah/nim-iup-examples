# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_10.c

import niup
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
    dlg = niup.GetDialog(ih)
    multitext = niup.GetDialogChild(dlg, "MULTITEXT")

  niup.SetAttribute(dlg, "TITLE", "Untitled - Simple Notepad");
  niup.SetAttribute(multitext, "FILENAME", nil)
  niup.SetAttribute(multitext, "DIRTY", "NO")
  niup.SetAttribute(multitext, "VALUE", "")

proc open_file(ih:PIhandle, filename:string) =
  try:
    let str = readFile(filename)
    if str.string != "":
      let
        dlg = niup.GetDialog(ih)
        multitext = niup.GetDialogChild(dlg, "MULTITEXT")
        config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

      niup.SetfAttribute(dlg, "TITLE", "%s - Simple Notepad", os.extractFilename(filename))
      niup.SetStrAttribute(multitext, "FILENAME", filename)
      niup.SetAttribute(multitext, "DIRTY", "NO")
      niup.SetStrAttribute(multitext, "VALUE", str)

      niup.ConfigRecentUpdate(config, filename)
  except:
    niup.Message("Error", fmt"Fail when reading file: {filename}");

proc save_file(multitext:PIhandle):int =
  let
    filename = niup.GetAttribute(multitext, "FILENAME")
    str = niup.GetAttribute(multitext, "VALUE")
  try:
    if filename != nil:
      writeFile($filename, $str)
    else:
      echo "missing filename!"
    niup.SetAttribute(multitext, "DIRTY", "NO");
  except:
    niup.Message("Error", fmt"Fail when writing to file: {filename}");

proc saveas_file(multitext:PIhandle, filename:string) =
  let str = niup.GetAttribute(multitext, "VALUE")
  try:
    writeFile(filename, $str)
    let config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

    niup.SetfAttribute(niup.GetDialog(multitext), "TITLE", "%s - Simple Notepad", os.extractFilename(filename));
    niup.SetStrAttribute(multitext, "FILENAME", filename);
    niup.SetAttribute(multitext, "DIRTY", "NO");

    niup.ConfigRecentUpdate(config, filename)
  except:
    niup.Message("Error", fmt"Fail when writing to file: {filename}");

proc save_check(ih:PIhandle):bool =
  let
    multitext = niup.GetDialogChild(ih, "MULTITEXT")
    filename = niup.GetAttribute(multitext, "FILENAME")

  if niup.GetInt(multitext, "DIRTY") == 1:
    if filename != nil:
      case niup.Alarm("Warning", "File not saved! Save it now?", "Yes", "No", "Cancel"):
        of 1:  # save the changes and continue
            discard save_file(multitext)
        of 2:  # ignore the changes and continue
          discard
        else:  # cancel
          return false
    else:
      case niup.Alarm("Warning", "File not saved and missing filename! Discard it?", "Yes", "No", "Cancel"):
        of 1:  # discard changes
            discard
        else:  # No
          return false

  return true

proc toggle_bar_visibility(item:PIhandle, ih:PIhandle) =
  if niup.GetInt(item, "VALUE") > 0:
    niup.SetAttribute(ih, "FLOATING", "YES")
    niup.SetAttribute(ih, "VISIBLE", "NO")
    niup.SetAttribute(item, "VALUE", "OFF")
  else:
    niup.SetAttribute(ih, "FLOATING", "NO")
    niup.SetAttribute(ih, "VISIBLE", "YES")
    niup.SetAttribute(item, "VALUE", "ON")

  niup.Refresh(ih);  # refresh the dialog layout

proc set_find_replace_visibility(find_dlg:PIhandle, show_replace:bool) =
  let
    replace_txt = niup.GetDialogChild(find_dlg, "REPLACE_TEXT")
    replace_lbl = niup.GetDialogChild(find_dlg, "REPLACE_LABEL")
    replace_bt = niup.GetDialogChild(find_dlg, "REPLACE_BUTTON")

  if show_replace:
    niup.SetAttribute(replace_txt, "VISIBLE", "Yes")
    niup.SetAttribute(replace_lbl, "VISIBLE", "Yes")
    niup.SetAttribute(replace_bt, "VISIBLE", "Yes")
    niup.SetAttribute(replace_txt, "FLOATING", "No")
    niup.SetAttribute(replace_lbl, "FLOATING", "No")
    niup.SetAttribute(replace_bt, "FLOATING", "No")

    niup.SetAttribute(find_dlg, "TITLE", "Replace")
  else:
    niup.SetAttribute(replace_txt, "FLOATING", "Yes")
    niup.SetAttribute(replace_lbl, "FLOATING", "Yes")
    niup.SetAttribute(replace_bt, "FLOATING", "Yes")
    niup.SetAttribute(replace_txt, "VISIBLE", "No")
    niup.SetAttribute(replace_lbl, "VISIBLE", "No")
    niup.SetAttribute(replace_bt, "VISIBLE", "No")

    niup.SetAttribute(find_dlg, "TITLE", "Find")

  niup.SetAttribute(find_dlg, "SIZE", nil);  # force a dialog resize on the IupRefresh
  niup.Refresh(find_dlg)

################################# Callbacks ##################################

proc dropfiles_cb(ih:PIhandle, filename:cstring):int =
  if save_check(ih):
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_valuechanged_cb(multitext:PIhandle):int =
  niup.SetAttribute(multitext, "DIRTY", "YES")
  return IUP_DEFAULT

proc file_menu_open_cb(ih:PIhandle):int =
  let
    item_revert = niup.GetDialogChild(ih, "ITEM_REVERT")
    item_save = niup.GetDialogChild(ih, "ITEM_SAVE")
    multitext = niup.GetDialogChild(ih, "MULTITEXT")
    filename = niup.GetAttribute(multitext, "FILENAME")
    dirty = niup.GetInt(multitext, "DIRTY")

  if dirty == 1:
    niup.SetAttribute(item_save, "ACTIVE", "YES")
  else:
    niup.SetAttribute(item_save, "ACTIVE", "NO")

  if dirty == 1 and filename != "":
    niup.SetAttribute(item_revert, "ACTIVE", "YES")
  else:
    niup.SetAttribute(item_revert, "ACTIVE", "NO")
  return IUP_DEFAULT

proc edit_menu_open_cb(ih:PIhandle): int =
  let
    clipboard = niup.Clipboard()
    item_paste = niup.GetDialogChild(ih, "ITEM_PASTE")
    item_cut = niup.GetDialogChild(ih, "ITEM_CUT")
    item_delete = niup.GetDialogChild(ih, "ITEM_DELETE")
    item_copy = niup.GetDialogChild(ih, "ITEM_COPY")
    multitext = niup.GetDialogChild(ih, "MULTITEXT")

  if niup.GetInt(clipboard, "TEXTAVAILABLE") == 0:
    niup.SetAttribute(item_paste, "ACTIVE", "NO")
  else:
    niup.SetAttribute(item_paste, "ACTIVE", "YES")

  if niup.GetAttribute(multitext, "SELECTEDTEXT") == nil:
    niup.SetAttribute(item_cut, "ACTIVE", "NO")
    niup.SetAttribute(item_delete, "ACTIVE", "NO")
    niup.SetAttribute(item_copy, "ACTIVE", "NO")
  else:
    niup.SetAttribute(item_cut, "ACTIVE", "YES")
    niup.SetAttribute(item_delete, "ACTIVE", "YES")
    niup.SetAttribute(item_copy, "ACTIVE", "YES")

  niup.Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = niup.GetAttribute(ih, "RECENTFILENAME")
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = niup.GetDialogChild(ih, "STATUSBAR")
  niup.SetfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return niup.IUP_DEFAULT

proc item_new_action_cb(item_new:PIhandle):int =
  if save_check(item_new):
    new_file(item_new)

  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  if not save_check(item_open):
    return IUP_DEFAULT

  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_open))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    open_file(item_open, $filename);

  niup.Destroy(filedlg)
  return niup.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = niup.GetDialogChild(item_saveas, "MULTITEXT")
  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_saveas))
  niup.SetStrAttribute(filedlg, "FILE", niup.GetAttribute(multitext, "FILENAME"))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)

  niup.Destroy(filedlg)
  return niup.IUP_DEFAULT

proc item_save_action_cb(item_save:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_save, "MULTITEXT")
    filename = niup.GetAttribute(multitext, "FILENAME")
  if filename != "":
    discard item_saveas_action_cb(item_save)
  else:
    # test again because in can be called using the hot key
    let dirty = niup.GetInt(multitext, "DIRTY")
    if dirty == 1:
      discard save_file(multitext)
  return IUP_DEFAULT

proc item_revert_action_cb(item_revert:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_revert, "MULTITEXT")
    filename = niup.GetAttribute(multitext, "FILENAME")
  open_file(item_revert, $filename)
  return IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint {.cdecl.} =
  let dlg = niup.GetDialog(item_exit)
  let config = cast[PIhandle](niup.GetAttribute(dlg, "CONFIG"))

  if not save_check(item_exit):
    return IUP_IGNORE  # to abort the CLOSE_CB callback

  niup.ConfigDialogClosed(config, dlg, "MainWindow")
  ConfigSave(config)
  niup.Destroy(config)
  return niup.IUP_CLOSE

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

proc find_next_action_cb(ih:PIhandle): int =
  let find_dlg = cast[PIhandle](niup.GetAttribute(ih, "FIND_DIALOG"))
  if find_dlg == nil:
    return IUP_DEFAULT

  let multitext = cast[PIhandle](niup.GetAttribute(find_dlg, "MULTITEXT"))
  var find_pos = niup.GetInt(multitext, "FIND_POS")

  let txt = niup.GetDialogChild(find_dlg, "FIND_TEXT")
  let str_to_find = niup.GetAttribute(txt, "VALUE")

  let find_case = niup.GetDialogChild(find_dlg, "FIND_CASE")
  let casesensitive = niup.GetInt(find_case, "VALUE")

  # test again, because it can be called from the hot key
  if str_to_find == nil or str_to_find == "":
    return IUP_DEFAULT

  if find_pos == -1:
    find_pos = 0

  let str = niup.GetAttribute(multitext, "VALUE")

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
    niup.SetfAttribute(multitext, "FIND_SELECTION", "%d:%d", unicode_pos, unicode_end_pos)

    niup.TextConvertPosToLinCol(multitext, unicode_pos, lin, col)
    niup.TextConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    niup.SetInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    niup.SetInt(multitext, "FIND_POS", -1)
    niup.Message("Warning", "Text not found.")

  return niup.IUP_DEFAULT

proc find_replace_action_cb(bt_replace:PIhandle):int =
  let
    find_dlg = cast[PIhandle](niup.GetAttribute(bt_replace, "FIND_DIALOG"))
    multitext = cast[PIhandle](niup.GetAttribute(find_dlg, "MULTITEXT"))
    find_pos = niup.GetInt(multitext, "FIND_POS")
    selectionpos = niup.GetAttribute(multitext, "SELECTIONPOS")
    find_selection = niup.GetAttribute(multitext, "FIND_SELECTION")

  if find_pos == -1 or selectionpos == nil or find_selection == nil or selectionpos != find_selection:
    discard find_next_action_cb(bt_replace)
  else:
    let
      replace_txt = niup.GetDialogChild(find_dlg, "REPLACE_TEXT")
      str_to_replace = niup.GetAttribute(replace_txt, "VALUE")
    niup.SetAttribute(multitext, "SELECTEDTEXT", str_to_replace)

    # then find next
    discard find_next_action_cb(bt_replace)

  return IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle):int =
  let
    find_dlg = niup.GetDialog(bt_close)
    multitext = cast[PIhandle](niup.GetAttribute(find_dlg, "MULTITEXT"))
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

  niup.ConfigDialogClosed(config, find_dlg, "FindDialog")
  Hide(find_dlg)  # do not destroy, just hide

  return niup.IUP_DEFAULT

proc create_find_dialog(multitext:PIhandle):PIhandle =
  var
    box, bt_next, bt_close, txt, find_case, find_dlg:PIhandle
    txt_replace, bt_replace:PIhandle

  txt = niup.Text(nil)
  niup.SetAttribute(txt, "NAME", "FIND_TEXT")
  niup.SetAttribute(txt, "VISIBLECOLUMNS", "20")
  txt_replace = niup.Text(nil)
  niup.SetAttribute(txt_replace, "NAME", "REPLACE_TEXT")
  niup.SetAttribute(txt_replace, "VISIBLECOLUMNS", "20")
  find_case = niup.Toggle("Case Sensitive", nil)
  niup.SetAttribute(find_case, "NAME", "FIND_CASE")
  bt_next = niup.Button("Find Next", nil)
  niup.SetAttribute(bt_next, "PADDING", "10x2")
  SetCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
  bt_replace = niup.Button("Replace", nil)
  niup.SetAttribute(bt_replace, "PADDING", "10x2")
  SetCallback(bt_replace, "ACTION", cast[ICallback](find_replace_action_cb))
  niup.SetAttribute(bt_replace, "NAME", "REPLACE_BUTTON")
  bt_close = niup.Button("Close", nil)
  SetCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
  niup.SetAttribute(bt_close, "PADDING", "10x2")

  box = niup.Vbox(
    niup.Label("Find What:"),
    txt,
    niup.SetAttributes(niup.Label("Replace with:"), "NAME=REPLACE_LABEL"),
    txt_replace,
    find_case,
    niup.SetAttributes(niup.Hbox(
      niup.Fill(),
      bt_next,
      bt_replace,
      bt_close,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  niup.SetAttribute(box, "MARGIN", "10x10")
  niup.SetAttribute(box, "GAP", "5")

  find_dlg = niup.Dialog(box)
  niup.SetAttribute(find_dlg, "TITLE", "Find")
  niup.SetAttribute(find_dlg, "DIALOGFRAME", "Yes")
  niup.SetAttributeHandle(find_dlg, "DEFAULTENTER", bt_next)
  niup.SetAttributeHandle(find_dlg, "DEFAULTESC", bt_close)
  niup.SetAttributeHandle(find_dlg, "PARENTDIALOG", niup.GetDialog(multitext))
  SetCallback(find_dlg, "CLOSE_CB", cast[ICallback](find_close_action_cb))

  # Save the multiline to access it from the callbacks
  niup.SetAttribute(find_dlg, "MULTITEXT", cast[cstring](multitext))

  # Save the dialog to reuse it
  niup.SetAttribute(find_dlg, "FIND_DIALOG", cast[cstring](find_dlg))  # from itself
  niup.SetAttribute(niup.GetDialog(multitext), "FIND_DIALOG", cast[cstring](find_dlg)) # from the main dialog

  return find_dlg

proc item_find_action_cb(item_find:PIhandle): int =
  var find_dlg = cast[PIhandle](niup.GetAttribute(item_find, "FIND_DIALOG"))
  let
    multitext = niup.GetDialogChild(item_find, "MULTITEXT")
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, false)

  niup.ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = niup.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = niup.GetDialogChild(find_dlg, "FIND_TEXT")
    niup.SetStrAttribute(txt, "VALUE", str)

  return niup.IUP_DEFAULT

proc item_replace_action_cb(item_replace:PIhandle):int =
  var find_dlg = cast[PIhandle](niup.GetAttribute(item_replace, "FIND_DIALOG"))
  let
    multitext = niup.GetDialogChild(item_replace, "MULTITEXT")
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, true)

  niup.ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = niup.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = niup.GetDialogChild(find_dlg, "FIND_TEXT")
    niup.SetStrAttribute(txt, "VALUE", str)

  return IUP_IGNORE  # replace system processing for the hot key

proc selection_find_next_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  let str = niup.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    var find_dlg = cast[PIhandle](niup.GetAttribute(ih, "FIND_DIALOG"))

    if find_dlg == nil:
      find_dlg = create_find_dialog(multitext)

    let txt = niup.GetDialogChild(find_dlg, "FIND_TEXT")
    niup.SetStrAttribute(txt, "VALUE", str)

    discard find_next_action_cb(ih)

  return IUP_DEFAULT

proc item_copy_action_cb(item_copy:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_copy, "MULTITEXT")
    clipboard = niup.Clipboard()
  niup.SetAttribute(clipboard, "TEXT", niup.GetAttribute(multitext, "SELECTEDTEXT"))
  niup.Destroy(clipboard)
  return IUP_DEFAULT

proc item_paste_action_cb(item_paste:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_paste, "MULTITEXT")
    clipboard = niup.Clipboard()
  niup.SetAttribute(multitext, "INSERT", niup.GetAttribute(clipboard, "TEXT"))
  niup.Destroy(clipboard)
  return IUP_DEFAULT

proc item_cut_action_cb(item_cut:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_cut, "MULTITEXT")
    clipboard = niup.Clipboard()
  niup.SetAttribute(clipboard, "TEXT", niup.GetAttribute(multitext, "SELECTEDTEXT"))
  niup.SetAttribute(multitext, "SELECTEDTEXT", "")
  niup.Destroy(clipboard)
  return IUP_DEFAULT

proc item_delete_action_cb(item_delete:PIhandle):int =
  let multitext = niup.GetDialogChild(item_delete, "MULTITEXT")
  niup.SetAttribute(multitext, "SELECTEDTEXT", "")
  return IUP_DEFAULT

proc item_select_all_action_cb(item_select_all:PIhandle):int =
  let multitext = niup.GetDialogChild(item_select_all, "MULTITEXT")
  SetFocus(multitext)
  niup.SetAttribute(multitext, "SELECTION", "ALL")
  return IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = niup.GetDialogChild(item_font, "MULTITEXT")
  let fontdlg = niup.FontDlg()
  let font = niup.GetAttribute(multitext, "FONT")
  niup.SetStrAttribute(fontdlg, "VALUE", font)
  niup.SetAttributeHandle(fontdlg, "PARENTDIALOG", niup.GetDialog(item_font))

  Popup(fontdlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(fontdlg, "STATUS") == 1:
    let config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))
    let font = niup.GetAttribute(fontdlg, "VALUE")
    niup.SetStrAttribute(multitext, "FONT", font)
    niup.ConfigSetVariableStr(config, "MainWindow", "Font", font)

  niup.Destroy(fontdlg)
  return niup.IUP_DEFAULT

proc item_toolbar_action_cb(item_toolbar:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_toolbar, "MULTITEXT")
    toolbar = niup.GetChild(niup.GetParent(multitext), 0)
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_toolbar, toolbar)

  niup.ConfigSetVariableStr(config, "MainWindow", "Toolbar", niup.GetAttribute(item_toolbar, "VALUE"))
  return IUP_DEFAULT

proc item_statusbar_action_cb(item_statusbar:PIhandle):int =
  let
    multitext = niup.GetDialogChild(item_statusbar, "MULTITEXT")
    statusbar = niup.GetBrother(multitext)
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_statusbar, statusbar)

  niup.ConfigSetVariableStr(config, "MainWindow", "Statusbar", niup.GetAttribute(item_statusbar, "VALUE"))
  return IUP_DEFAULT

proc item_help_action_cb():int =
  Help("http://www.tecgraf.puc-rio.br/iup")
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  niup.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niup.IUP_DEFAULT

################################# Main ######################################

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, multitext, menu: niup.PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: niup.PIhandle
    sub_menu_edit, edit_menu, item_find, item_find_next, item_goto: niup.PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:niup.PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: niup.PIhandle
    sub_menu_format, format_menu, item_font, item_replace: niup.PIhandle
    sub_menu_help, help_menu, item_help, item_about: niup.PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar: PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: niup.PIhandle

  multitext =  niup.Text(nil)
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")
  niup.SetAttribute(multitext, "NAME", "MULTITEXT")
  niup.SetAttribute(multitext, "DIRTY", "NO")
  SetCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))
  SetCallback(multitext, "VALUECHANGED_CB", cast[ICallback](multitext_valuechanged_cb))
  SetCallback(multitext, "DROPFILES_CB", cast[ICallback](dropfiles_cb))

  lbl_statusbar = niup.Label("Lin 1, Col 1")
  niup.SetAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  niup.SetAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  niup.SetAttribute(lbl_statusbar, "PADDING", "10x5")

  item_new = niup.Item("New\tCtrl+N", nil)
  niup.SetAttribute(item_new, "IMAGE", "IUP_FileNew")
  SetCallback(item_new, "ACTION", cast[ICallback](item_new_action_cb))
  btn_new = niup.Button(nil, nil)
  niup.SetAttribute(btn_new, "IMAGE", "IUP_FileNew")
  niup.SetAttribute(btn_new, "FLAT", "Yes")
  SetCallback(btn_new, "ACTION", cast[ICallback](item_new_action_cb))
  niup.SetAttribute(btn_new, "TIP", "New (Ctrl+N)")
  niup.SetAttribute(btn_new, "CANFOCUS", "No")

  item_open = niup.Item("&Open...\tCtrl+O", nil)
  niup.SetAttribute(item_open, "IMAGE", "IUP_FileOpen")
  SetCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = niup.Button(nil, nil)
  niup.SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  niup.SetAttribute(btn_open, "FLAT", "Yes")
  SetCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  niup.SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  niup.SetAttribute(btn_open, "CANFOCUS", "No")

  item_save = niup.Item("Save\tCtrl+S", nil);
  niup.SetAttribute(item_save, "NAME", "ITEM_SAVE")
  niup.SetAttribute(item_save, "IMAGE", "IUP_FileSave")
  SetCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = niup.Button(nil, nil)
  niup.SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  niup.SetAttribute(btn_save, "FLAT", "Yes")
  SetCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  niup.SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  niup.SetAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = niup.Item("Save &As...\tCtrl+S", nil)
  niup.SetAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  SetCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = niup.Item("Revert", nil)
  niup.SetAttribute(item_revert, "NAME", "ITEM_REVERT")
  SetCallback(item_revert, "ACTION", cast[ICallback](item_revert_action_cb))

  item_exit = niup.Item("E&xit", nil)
  SetCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))

  item_find = niup.Item("&Find...\tCtrl+F", nil)
  niup.SetAttribute(item_find, "IMAGE", "IUP_EditFind")
  SetCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  btn_find = niup.Button(nil, nil)
  niup.SetAttribute(btn_find, "IMAGE", "IUP_EditFind")
  niup.SetAttribute(btn_find, "FLAT", "Yes")
  SetCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  niup.SetAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  niup.SetAttribute(btn_find, "CANFOCUS", "No")

  item_find_next = niup.Item("Find &Next\tF3", nil)
  niup.SetAttribute(item_find_next, "NAME", "ITEM_FINDNEXT")
  SetCallback(item_find_next, "ACTION", cast[Icallback](find_next_action_cb))

  item_replace = niup.Item("&Replace...\tCtrl+H", nil)
  SetCallback(item_replace, "ACTION", cast[Icallback](item_replace_action_cb))

  item_cut = niup.Item("Cut\tCtrl+X", nil)
  niup.SetAttribute(item_cut, "NAME", "ITEM_CUT")
  niup.SetAttribute(item_cut, "IMAGE", "IUP_EditCut")
  SetCallback(item_cut, "ACTION", cast[ICallback](item_cut_action_cb))

  item_copy = niup.Item("Copy\tCtrl+C", nil)
  niup.SetAttribute(item_copy, "NAME", "ITEM_COPY")
  niup.SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  SetCallback(item_copy, "ACTION", cast[ICallback](item_copy_action_cb))

  item_paste = niup.Item("Paste\tCtrl+V", nil)
  niup.SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  niup.SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  SetCallback(item_paste, "ACTION", cast[ICallback](item_paste_action_cb))

  item_delete = niup.Item("Delete\tDel", nil)
  niup.SetAttribute(item_delete, "NAME", "ITEM_DELETE")
  niup.SetAttribute(item_delete, "IMAGE", "IUP_EditErase")
  SetCallback(item_delete, "ACTION", cast[ICallback](item_delete_action_cb))

  item_select_all = niup.Item("Select All\tCtrl+A", nil)
  SetCallback(item_select_all, "ACTION", cast[ICallback](item_select_all_action_cb))

  btn_cut = niup.Button(nil, nil)
  niup.SetAttribute(btn_cut, "IMAGE", "IUP_EditCut")
  niup.SetAttribute(btn_cut, "FLAT", "Yes")
  SetCallback(btn_cut, "ACTION", cast[ICallback](item_cut_action_cb))
  niup.SetAttribute(btn_cut, "TIP", "Cut (Ctrl+X)")
  niup.SetAttribute(btn_cut, "CANFOCUS", "No")
  btn_copy = niup.Button(nil, nil)
  niup.SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  niup.SetAttribute(btn_copy, "FLAT", "Yes")
  SetCallback(btn_copy, "ACTION", cast[ICallback](item_copy_action_cb))
  niup.SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  niup.SetAttribute(btn_copy, "CANFOCUS", "No")
  btn_paste = niup.Button(nil, nil)
  niup.SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  niup.SetAttribute(btn_paste, "FLAT", "Yes")
  SetCallback(btn_paste, "ACTION", cast[ICallback](item_paste_action_cb))
  niup.SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  niup.SetAttribute(btn_paste, "CANFOCUS", "No")

  toolbar_hb = niup.Hbox(
    btn_new,
    btn_open,
    btn_save,
    niup.SetAttributes(niup.Label(nil), "SEPARATOR=VERTICAL"),
    btn_cut,
    btn_copy,
    btn_paste,
    niup.SetAttributes(niup.Label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  niup.SetAttribute(toolbar_hb, "MARGIN", "5x5")
  niup.SetAttribute(toolbar_hb, "GAP", "2")

  item_toolbar = niup.Item("&Toobar", nil)
  SetCallback(item_toolbar, "ACTION", cast[ICallback](item_toolbar_action_cb))
  niup.SetAttribute(item_toolbar, "VALUE", "ON")
  item_statusbar = niup.Item("&Statusbar", nil)
  SetCallback(item_statusbar, "ACTION", cast[ICallback](item_statusbar_action_cb))
  niup.SetAttribute(item_statusbar, "VALUE", "ON")

  item_goto = niup.Item("&Go To...\tCtrl+G", nil)
  SetCallback(item_goto, "ACTION", cast[Icallback](item_goto_action_cb))

  item_font= niup.Item("&Font...", nil)
  SetCallback(item_font, "ACTION", cast[Icallback](item_font_action_cb))

  item_help= niup.Item("&Help...", nil)
  SetCallback(item_help, "ACTION", cast[Icallback](item_help_action_cb))
  item_about = niup.Item("&About...", nil)
  SetCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

  recent_menu = niup.Menu(nil)

  file_menu = niup.Menu(
    item_new,
    item_open,
    item_save,
    item_saveas,
    item_revert,
    niup.Separator(),
    niup.Submenu("Recent &Files", recent_menu),
    item_exit,
    nil)
  edit_menu = niup.Menu(
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    niup.Separator(),
    item_find,
    item_find_next,
    item_replace,
    item_goto,
    niup.Separator(),
    item_select_all,
    nil)
  format_menu = niup.Menu(item_font, nil)
  view_menu = niup.Menu(
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = niup.Menu(item_help, item_about, nil)

  SetCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  SetCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

  sub_menu_file = niup.Submenu("&File", file_menu)
  sub_menu_edit = niup.Submenu("&Edit", edit_menu)
  sub_menu_format = niup.Submenu("F&ormat", format_menu)
  sub_menu_view = niup.Submenu("&View", view_menu)
  sub_menu_help = niup.Submenu("&Help", help_menu)

  menu = niup.Menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_view,
                  sub_menu_help,
                  nil)

  vbox = niup.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niup.Dialog(vbox)
  niup.SetAttributeHandle(dlg, "MENU", menu)
  niup.SetAttribute(dlg, "SIZE", "HALFxHALF")
  SetCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))
  SetCallback(dlg, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  niup.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  SetCallback(dlg, "K_cN", cast[ICallback](item_new_action_cb))
  SetCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  SetCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  SetCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  SetCallback(dlg, "K_cH", cast[ICallback](item_replace_action_cb)) # replace system processing
  SetCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))
  SetCallback(dlg, "K_F3", cast[ICallback](find_next_action_cb))
  SetCallback(dlg, "K_cF3", cast[ICallback](selection_find_next_action_cb))
  SetCallback(dlg, "K_cV", cast[ICallback](item_paste_action_cb))
  # Ctrl+C, Ctrl+X, Ctrl+A, Del, already implemented inside IupText

  # parent for pre-defined dialogs in closed functions (IupMessage and IupAlarm)
  niup.SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  # Initialize variables from the configuration file

  niup.ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  let font = niup.ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    niup.SetStrAttribute(multitext, "FONT", font)

  if niup.ConfigGetVariableIntDef(config, "MainWindow", "Toolbar", 1) == 0:
    niup.SetAttribute(item_toolbar, "VALUE", "OFF")

    niup.SetAttribute(toolbar_hb, "FLOATING", "YES")
    niup.SetAttribute(toolbar_hb, "VISIBLE", "NO")


  if niup.ConfigGetVariableIntDef(config, "MainWindow", "Statusbar", 1) == 0:
    niup.SetAttribute(item_statusbar, "VALUE", "OFF")

    niup.SetAttribute(lbl_statusbar, "FLOATING", "YES")
    niup.SetAttribute(lbl_statusbar, "VISIBLE", "NO")

  niup.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  return dlg

proc mainProc =
  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)
  niup.ImageLibOpen()

  let config:PIhandle = niup.Config()
  niup.SetAttribute(config, "APP_NAME", "simple_notepad")
  ConfigLoad(config)

  let dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  niup.ConfigDialogShow(config, dlg, "MainWindow")

  # initialize the current file
  new_file(dlg)

  # open a file from the command line (allow file association in Windows)
  if paramCount() == 1:
    let filename = paramStr(1)
    open_file(dlg, filename)

  MainLoop()

  niup.Close()

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
