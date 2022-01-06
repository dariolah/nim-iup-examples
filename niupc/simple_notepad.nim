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
    dlg = niupc.GetDialog(ih)
    multitext = niupc.GetDialogChild(dlg, "MULTITEXT")

  niupc.SetAttribute(dlg, "TITLE", "Untitled - Simple Notepad");
  niupc.SetAttribute(multitext, "FILENAME", nil)
  niupc.SetAttribute(multitext, "DIRTY", "NO")
  niupc.SetAttribute(multitext, "VALUE", "")

proc open_file(ih:PIhandle, filename:string) =
  try:
    let str = readFile(filename)
    if str != "":
      let
        dlg = niupc.GetDialog(ih)
        multitext = niupc.GetDialogChild(dlg, "MULTITEXT")
        config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

      niupc.SetfAttribute(dlg, "TITLE", "%s - Simple Notepad", cstring(os.extractFilename(filename)))
      niupc.SetStrAttribute(multitext, "FILENAME", filename)
      niupc.SetAttribute(multitext, "DIRTY", "NO")
      niupc.SetStrAttribute(multitext, "VALUE", cstring(str))

      niupc.ConfigRecentUpdate(config, filename)
  except:
    niupc.Message("Error", cstring(fmt"Fail when reading file: {filename}"))

proc save_file(multitext:PIhandle):int =
  let
    filename = niupc.GetAttribute(multitext, "FILENAME")
    str = niupc.GetAttribute(multitext, "VALUE")
  try:
    if filename != nil:
      writeFile($filename, $str)
    else:
      echo "missing filename!"
    niupc.SetAttribute(multitext, "DIRTY", "NO");
  except:
    niupc.Message("Error", cstring(fmt"Fail when writing to file: {filename}"))

proc saveas_file(multitext:PIhandle, filename:string) =
  let str = niupc.GetAttribute(multitext, "VALUE")
  try:
    writeFile(filename, $str)
    let config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

    niupc.SetfAttribute(niupc.GetDialog(multitext), "TITLE", "%s - Simple Notepad", cstring(os.extractFilename(filename)))
    niupc.SetStrAttribute(multitext, "FILENAME", filename);
    niupc.SetAttribute(multitext, "DIRTY", "NO");

    niupc.ConfigRecentUpdate(config, filename)
  except:
    niupc.Message("Error", cstring(fmt"Fail when writing to file: {filename}"))

proc save_check(ih:PIhandle):bool =
  let
    multitext = niupc.GetDialogChild(ih, "MULTITEXT")
    filename = niupc.GetAttribute(multitext, "FILENAME")

  if niupc.GetInt(multitext, "DIRTY") == 1:
    if filename != nil:
      case niupc.Alarm("Warning", "File not saved! Save it now?", "Yes", "No", "Cancel"):
        of 1:  # save the changes and continue
            discard save_file(multitext)
        of 2:  # ignore the changes and continue
          discard
        else:  # cancel
          return false
    else:
      case niupc.Alarm("Warning", "File not saved and missing filename! Discard it?", "Yes", "No", "Cancel"):
        of 1:  # discard changes
            discard
        else:  # No
          return false

  return true

proc toggle_bar_visibility(item:PIhandle, ih:PIhandle) =
  if niupc.GetInt(item, "VALUE") > 0:
    niupc.SetAttribute(ih, "FLOATING", "YES")
    niupc.SetAttribute(ih, "VISIBLE", "NO")
    niupc.SetAttribute(item, "VALUE", "OFF")
  else:
    niupc.SetAttribute(ih, "FLOATING", "NO")
    niupc.SetAttribute(ih, "VISIBLE", "YES")
    niupc.SetAttribute(item, "VALUE", "ON")

  niupc.Refresh(ih);  # refresh the dialog layout

proc set_find_replace_visibility(find_dlg:PIhandle, show_replace:bool) =
  let
    replace_txt = niupc.GetDialogChild(find_dlg, "REPLACE_TEXT")
    replace_lbl = niupc.GetDialogChild(find_dlg, "REPLACE_LABEL")
    replace_bt = niupc.GetDialogChild(find_dlg, "REPLACE_BUTTON")

  if show_replace:
    niupc.SetAttribute(replace_txt, "VISIBLE", "Yes")
    niupc.SetAttribute(replace_lbl, "VISIBLE", "Yes")
    niupc.SetAttribute(replace_bt, "VISIBLE", "Yes")
    niupc.SetAttribute(replace_txt, "FLOATING", "No")
    niupc.SetAttribute(replace_lbl, "FLOATING", "No")
    niupc.SetAttribute(replace_bt, "FLOATING", "No")

    niupc.SetAttribute(find_dlg, "TITLE", "Replace")
  else:
    niupc.SetAttribute(replace_txt, "FLOATING", "Yes")
    niupc.SetAttribute(replace_lbl, "FLOATING", "Yes")
    niupc.SetAttribute(replace_bt, "FLOATING", "Yes")
    niupc.SetAttribute(replace_txt, "VISIBLE", "No")
    niupc.SetAttribute(replace_lbl, "VISIBLE", "No")
    niupc.SetAttribute(replace_bt, "VISIBLE", "No")

    niupc.SetAttribute(find_dlg, "TITLE", "Find")

  niupc.SetAttribute(find_dlg, "SIZE", nil);  # force a dialog resize on the IupRefresh
  niupc.Refresh(find_dlg)

################################# Callbacks ##################################

proc dropfiles_cb(ih:PIhandle, filename:cstring):int =
  if save_check(ih):
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_valuechanged_cb(multitext:PIhandle):int =
  niupc.SetAttribute(multitext, "DIRTY", "YES")
  return IUP_DEFAULT

proc file_menu_open_cb(ih:PIhandle):int =
  let
    item_revert = niupc.GetDialogChild(ih, "ITEM_REVERT")
    item_save = niupc.GetDialogChild(ih, "ITEM_SAVE")
    multitext = niupc.GetDialogChild(ih, "MULTITEXT")
    filename = niupc.GetAttribute(multitext, "FILENAME")
    dirty = niupc.GetInt(multitext, "DIRTY")

  if dirty == 1:
    niupc.SetAttribute(item_save, "ACTIVE", "YES")
  else:
    niupc.SetAttribute(item_save, "ACTIVE", "NO")

  if dirty == 1 and filename != "":
    niupc.SetAttribute(item_revert, "ACTIVE", "YES")
  else:
    niupc.SetAttribute(item_revert, "ACTIVE", "NO")
  return IUP_DEFAULT

proc edit_menu_open_cb(ih:PIhandle): int =
  let
    clipboard = niupc.Clipboard()
    item_paste = niupc.GetDialogChild(ih, "ITEM_PASTE")
    item_cut = niupc.GetDialogChild(ih, "ITEM_CUT")
    item_delete = niupc.GetDialogChild(ih, "ITEM_DELETE")
    item_copy = niupc.GetDialogChild(ih, "ITEM_COPY")
    multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  if niupc.GetInt(clipboard, "TEXTAVAILABLE") == 0:
    niupc.SetAttribute(item_paste, "ACTIVE", "NO")
  else:
    niupc.SetAttribute(item_paste, "ACTIVE", "YES")

  if niupc.GetAttribute(multitext, "SELECTEDTEXT") == nil:
    niupc.SetAttribute(item_cut, "ACTIVE", "NO")
    niupc.SetAttribute(item_delete, "ACTIVE", "NO")
    niupc.SetAttribute(item_copy, "ACTIVE", "NO")
  else:
    niupc.SetAttribute(item_cut, "ACTIVE", "YES")
    niupc.SetAttribute(item_delete, "ACTIVE", "YES")
    niupc.SetAttribute(item_copy, "ACTIVE", "YES")

  niupc.Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = niupc.GetAttribute(ih, "RECENTFILENAME")
    open_file(ih, $filename)

  return IUP_DEFAULT

proc multitext_caret_cb (ih:PIhandle, lin:int, col:int): int =
  let lbl_statusbar = niupc.GetDialogChild(ih, "STATUSBAR")
  niupc.SetfAttribute(lbl_statusbar, "TITLE", "Lin %d, Col %d", lin, col)
  return niupc.IUP_DEFAULT

proc item_new_action_cb(item_new:PIhandle):int =
  if save_check(item_new):
    new_file(item_new)

  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle): int =
  if not save_check(item_open):
    return IUP_DEFAULT

  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_open))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    open_file(item_open, $filename);

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let multitext = niupc.GetDialogChild(item_saveas, "MULTITEXT")
  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_saveas))
  niupc.SetStrAttribute(filedlg, "FILE", niupc.GetAttribute(multitext, "FILENAME"))

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc item_save_action_cb(item_save:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_save, "MULTITEXT")
    filename = niupc.GetAttribute(multitext, "FILENAME")
  if filename != "":
    discard item_saveas_action_cb(item_save)
  else:
    # test again because in can be called using the hot key
    let dirty = niupc.GetInt(multitext, "DIRTY")
    if dirty == 1:
      discard save_file(multitext)
  return IUP_DEFAULT

proc item_revert_action_cb(item_revert:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_revert, "MULTITEXT")
    filename = niupc.GetAttribute(multitext, "FILENAME")
  open_file(item_revert, $filename)
  return IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint {.cdecl.} =
  let dlg = niupc.GetDialog(item_exit)
  let config = cast[PIhandle](niupc.GetAttribute(dlg, "CONFIG"))

  if not save_check(item_exit):
    return IUP_IGNORE  # to abort the CLOSE_CB callback

  niupc.ConfigDialogClosed(config, dlg, "MainWindow")
  ConfigSave(config)
  niupc.Destroy(config)
  return niupc.IUP_CLOSE

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

proc find_next_action_cb(ih:PIhandle): int =
  let find_dlg = cast[PIhandle](niupc.GetAttribute(ih, "FIND_DIALOG"))
  if find_dlg == nil:
    return IUP_DEFAULT

  let multitext = cast[PIhandle](niupc.GetAttribute(find_dlg, "MULTITEXT"))
  var find_pos = niupc.GetInt(multitext, "FIND_POS")

  let txt = niupc.GetDialogChild(find_dlg, "FIND_TEXT")
  let str_to_find = niupc.GetAttribute(txt, "VALUE")

  let find_case = niupc.GetDialogChild(find_dlg, "FIND_CASE")
  let casesensitive = niupc.GetInt(find_case, "VALUE")

  # test again, because it can be called from the hot key
  if str_to_find == nil or str_to_find == "":
    return IUP_DEFAULT

  if find_pos == -1:
    find_pos = 0

  let str = niupc.GetAttribute(multitext, "VALUE")

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
    niupc.SetfAttribute(multitext, "FIND_SELECTION", "%d:%d", unicode_pos, unicode_end_pos)

    niupc.TextConvertPosToLinCol(multitext, unicode_pos, lin, col)
    niupc.TextConvertLinColToPos(multitext, lin, 0, unicode_pos)  # position at col=0, just scroll lines
    niupc.SetInt(multitext, "SCROLLTOPOS", unicode_pos)
  else:
    niupc.SetInt(multitext, "FIND_POS", -1)
    niupc.Message("Warning", "Text not found.")

  return niupc.IUP_DEFAULT

proc find_replace_action_cb(bt_replace:PIhandle):int =
  let
    find_dlg = cast[PIhandle](niupc.GetAttribute(bt_replace, "FIND_DIALOG"))
    multitext = cast[PIhandle](niupc.GetAttribute(find_dlg, "MULTITEXT"))
    find_pos = niupc.GetInt(multitext, "FIND_POS")
    selectionpos = niupc.GetAttribute(multitext, "SELECTIONPOS")
    find_selection = niupc.GetAttribute(multitext, "FIND_SELECTION")

  if find_pos == -1 or selectionpos == nil or find_selection == nil or selectionpos != find_selection:
    discard find_next_action_cb(bt_replace)
  else:
    let
      replace_txt = niupc.GetDialogChild(find_dlg, "REPLACE_TEXT")
      str_to_replace = niupc.GetAttribute(replace_txt, "VALUE")
    niupc.SetAttribute(multitext, "SELECTEDTEXT", str_to_replace)

    # then find next
    discard find_next_action_cb(bt_replace)

  return IUP_DEFAULT

proc find_close_action_cb(bt_close:PIhandle):int =
  let
    find_dlg = niupc.GetDialog(bt_close)
    multitext = cast[PIhandle](niupc.GetAttribute(find_dlg, "MULTITEXT"))
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

  niupc.ConfigDialogClosed(config, find_dlg, "FindDialog")
  Hide(find_dlg)  # do not destroy, just hide

  return niupc.IUP_DEFAULT

proc create_find_dialog(multitext:PIhandle):PIhandle =
  var
    box, bt_next, bt_close, txt, find_case, find_dlg:PIhandle
    txt_replace, bt_replace:PIhandle

  txt = niupc.Text(nil)
  niupc.SetAttribute(txt, "NAME", "FIND_TEXT")
  niupc.SetAttribute(txt, "VISIBLECOLUMNS", "20")
  txt_replace = niupc.Text(nil)
  niupc.SetAttribute(txt_replace, "NAME", "REPLACE_TEXT")
  niupc.SetAttribute(txt_replace, "VISIBLECOLUMNS", "20")
  find_case = niupc.Toggle("Case Sensitive", nil)
  niupc.SetAttribute(find_case, "NAME", "FIND_CASE")
  bt_next = niupc.Button("Find Next", nil)
  niupc.SetAttribute(bt_next, "PADDING", "10x2")
  SetCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
  bt_replace = niupc.Button("Replace", nil)
  niupc.SetAttribute(bt_replace, "PADDING", "10x2")
  SetCallback(bt_replace, "ACTION", cast[ICallback](find_replace_action_cb))
  niupc.SetAttribute(bt_replace, "NAME", "REPLACE_BUTTON")
  bt_close = niupc.Button("Close", nil)
  SetCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
  niupc.SetAttribute(bt_close, "PADDING", "10x2")

  box = niupc.Vbox(
    niupc.Label("Find What:"),
    txt,
    niupc.SetAttributes(niupc.Label("Replace with:"), "NAME=REPLACE_LABEL"),
    txt_replace,
    find_case,
    niupc.SetAttributes(niupc.Hbox(
      niupc.Fill(),
      bt_next,
      bt_replace,
      bt_close,
      nil), "NORMALIZESIZE=HORIZONTAL"),
    nil)
  niupc.SetAttribute(box, "MARGIN", "10x10")
  niupc.SetAttribute(box, "GAP", "5")

  find_dlg = niupc.Dialog(box)
  niupc.SetAttribute(find_dlg, "TITLE", "Find")
  niupc.SetAttribute(find_dlg, "DIALOGFRAME", "Yes")
  niupc.SetAttributeHandle(find_dlg, "DEFAULTENTER", bt_next)
  niupc.SetAttributeHandle(find_dlg, "DEFAULTESC", bt_close)
  niupc.SetAttributeHandle(find_dlg, "PARENTDIALOG", niupc.GetDialog(multitext))
  SetCallback(find_dlg, "CLOSE_CB", cast[ICallback](find_close_action_cb))

  # Save the multiline to access it from the callbacks
  niupc.SetAttribute(find_dlg, "MULTITEXT", cast[cstring](multitext))

  # Save the dialog to reuse it
  niupc.SetAttribute(find_dlg, "FIND_DIALOG", cast[cstring](find_dlg))  # from itself
  niupc.SetAttribute(niupc.GetDialog(multitext), "FIND_DIALOG", cast[cstring](find_dlg)) # from the main dialog

  return find_dlg

proc item_find_action_cb(item_find:PIhandle): int =
  var find_dlg = cast[PIhandle](niupc.GetAttribute(item_find, "FIND_DIALOG"))
  let
    multitext = niupc.GetDialogChild(item_find, "MULTITEXT")
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, false)

  niupc.ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = niupc.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = niupc.GetDialogChild(find_dlg, "FIND_TEXT")
    niupc.SetStrAttribute(txt, "VALUE", str)

  return niupc.IUP_DEFAULT

proc item_replace_action_cb(item_replace:PIhandle):int =
  var find_dlg = cast[PIhandle](niupc.GetAttribute(item_replace, "FIND_DIALOG"))
  let
    multitext = niupc.GetDialogChild(item_replace, "MULTITEXT")
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

  if find_dlg == nil:
    find_dlg = create_find_dialog(multitext)

  set_find_replace_visibility(find_dlg, true)

  niupc.ConfigDialogShow(config, find_dlg, "FindDialog")

  let str = niupc.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    let txt = niupc.GetDialogChild(find_dlg, "FIND_TEXT")
    niupc.SetStrAttribute(txt, "VALUE", str)

  return IUP_IGNORE  # replace system processing for the hot key

proc selection_find_next_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  let str = niupc.GetAttribute(multitext, "SELECTEDTEXT")
  if str != nil and str != "":
    var find_dlg = cast[PIhandle](niupc.GetAttribute(ih, "FIND_DIALOG"))

    if find_dlg == nil:
      find_dlg = create_find_dialog(multitext)

    let txt = niupc.GetDialogChild(find_dlg, "FIND_TEXT")
    niupc.SetStrAttribute(txt, "VALUE", str)

    discard find_next_action_cb(ih)

  return IUP_DEFAULT

proc item_copy_action_cb(item_copy:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_copy, "MULTITEXT")
    clipboard = niupc.Clipboard()
  niupc.SetAttribute(clipboard, "TEXT", niupc.GetAttribute(multitext, "SELECTEDTEXT"))
  niupc.Destroy(clipboard)
  return IUP_DEFAULT

proc item_paste_action_cb(item_paste:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_paste, "MULTITEXT")
    clipboard = niupc.Clipboard()
  niupc.SetAttribute(multitext, "INSERT", niupc.GetAttribute(clipboard, "TEXT"))
  niupc.Destroy(clipboard)
  return IUP_DEFAULT

proc item_cut_action_cb(item_cut:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_cut, "MULTITEXT")
    clipboard = niupc.Clipboard()
  niupc.SetAttribute(clipboard, "TEXT", niupc.GetAttribute(multitext, "SELECTEDTEXT"))
  niupc.SetAttribute(multitext, "SELECTEDTEXT", "")
  niupc.Destroy(clipboard)
  return IUP_DEFAULT

proc item_delete_action_cb(item_delete:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_delete, "MULTITEXT")
  niupc.SetAttribute(multitext, "SELECTEDTEXT", "")
  return IUP_DEFAULT

proc item_select_all_action_cb(item_select_all:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_select_all, "MULTITEXT")
  SetFocus(multitext)
  niupc.SetAttribute(multitext, "SELECTION", "ALL")
  return IUP_DEFAULT

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

proc item_toolbar_action_cb(item_toolbar:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_toolbar, "MULTITEXT")
    toolbar = niupc.GetChild(niupc.GetParent(multitext), 0)
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_toolbar, toolbar)

  niupc.ConfigSetVariableStr(config, "MainWindow", "Toolbar", niupc.GetAttribute(item_toolbar, "VALUE"))
  return IUP_DEFAULT

proc item_statusbar_action_cb(item_statusbar:PIhandle):int =
  let
    multitext = niupc.GetDialogChild(item_statusbar, "MULTITEXT")
    statusbar = niupc.GetBrother(multitext)
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))

  toggle_bar_visibility(item_statusbar, statusbar)

  niupc.ConfigSetVariableStr(config, "MainWindow", "Statusbar", niupc.GetAttribute(item_statusbar, "VALUE"))
  return IUP_DEFAULT

proc item_help_action_cb():int =
  Help("http://www.tecgraf.puc-rio.br/iup")
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  niupc.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niupc.IUP_DEFAULT

################################# Main ######################################

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, multitext, menu: niupc.PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: niupc.PIhandle
    sub_menu_edit, edit_menu, item_find, item_find_next, item_goto: niupc.PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:niupc.PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: niupc.PIhandle
    sub_menu_format, format_menu, item_font, item_replace: niupc.PIhandle
    sub_menu_help, help_menu, item_help, item_about: niupc.PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar: PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: niupc.PIhandle

  multitext =  niupc.Text(nil)
  niupc.SetAttribute(multitext, "MULTILINE", "YES")
  niupc.SetAttribute(multitext, "EXPAND", "YES")
  niupc.SetAttribute(multitext, "NAME", "MULTITEXT")
  niupc.SetAttribute(multitext, "DIRTY", "NO")
  SetCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))
  SetCallback(multitext, "VALUECHANGED_CB", cast[ICallback](multitext_valuechanged_cb))
  niupext.SetCallback(multitext, "DROPFILES_CB", dropfiles_cb)

  lbl_statusbar = niupc.Label("Lin 1, Col 1")
  niupc.SetAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  niupc.SetAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  niupc.SetAttribute(lbl_statusbar, "PADDING", "10x5")

  item_new = niupc.Item("New\tCtrl+N", nil)
  niupc.SetAttribute(item_new, "IMAGE", "IUP_FileNew")
  SetCallback(item_new, "ACTION", cast[ICallback](item_new_action_cb))
  btn_new = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_new, "IMAGE", "IUP_FileNew")
  niupc.SetAttribute(btn_new, "FLAT", "Yes")
  SetCallback(btn_new, "ACTION", cast[ICallback](item_new_action_cb))
  niupc.SetAttribute(btn_new, "TIP", "New (Ctrl+N)")
  niupc.SetAttribute(btn_new, "CANFOCUS", "No")

  item_open = niupc.Item("&Open...\tCtrl+O", nil)
  niupc.SetAttribute(item_open, "IMAGE", "IUP_FileOpen")
  SetCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  niupc.SetAttribute(btn_open, "FLAT", "Yes")
  SetCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  niupc.SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  niupc.SetAttribute(btn_open, "CANFOCUS", "No")

  item_save = niupc.Item("Save\tCtrl+S", nil);
  niupc.SetAttribute(item_save, "NAME", "ITEM_SAVE")
  niupc.SetAttribute(item_save, "IMAGE", "IUP_FileSave")
  SetCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  niupc.SetAttribute(btn_save, "FLAT", "Yes")
  SetCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  niupc.SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  niupc.SetAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = niupc.Item("Save &As...\tCtrl+S", nil)
  niupc.SetAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  SetCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = niupc.Item("Revert", nil)
  niupc.SetAttribute(item_revert, "NAME", "ITEM_REVERT")
  SetCallback(item_revert, "ACTION", cast[ICallback](item_revert_action_cb))

  item_exit = niupc.Item("E&xit", nil)
  SetCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))

  item_find = niupc.Item("&Find...\tCtrl+F", nil)
  niupc.SetAttribute(item_find, "IMAGE", "IUP_EditFind")
  SetCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  btn_find = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_find, "IMAGE", "IUP_EditFind")
  niupc.SetAttribute(btn_find, "FLAT", "Yes")
  SetCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  niupc.SetAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  niupc.SetAttribute(btn_find, "CANFOCUS", "No")

  item_find_next = niupc.Item("Find &Next\tF3", nil)
  niupc.SetAttribute(item_find_next, "NAME", "ITEM_FINDNEXT")
  SetCallback(item_find_next, "ACTION", cast[Icallback](find_next_action_cb))

  item_replace = niupc.Item("&Replace...\tCtrl+H", nil)
  SetCallback(item_replace, "ACTION", cast[Icallback](item_replace_action_cb))

  item_cut = niupc.Item("Cut\tCtrl+X", nil)
  niupc.SetAttribute(item_cut, "NAME", "ITEM_CUT")
  niupc.SetAttribute(item_cut, "IMAGE", "IUP_EditCut")
  SetCallback(item_cut, "ACTION", cast[ICallback](item_cut_action_cb))

  item_copy = niupc.Item("Copy\tCtrl+C", nil)
  niupc.SetAttribute(item_copy, "NAME", "ITEM_COPY")
  niupc.SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  SetCallback(item_copy, "ACTION", cast[ICallback](item_copy_action_cb))

  item_paste = niupc.Item("Paste\tCtrl+V", nil)
  niupc.SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  niupc.SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  SetCallback(item_paste, "ACTION", cast[ICallback](item_paste_action_cb))

  item_delete = niupc.Item("Delete\tDel", nil)
  niupc.SetAttribute(item_delete, "NAME", "ITEM_DELETE")
  niupc.SetAttribute(item_delete, "IMAGE", "IUP_EditErase")
  SetCallback(item_delete, "ACTION", cast[ICallback](item_delete_action_cb))

  item_select_all = niupc.Item("Select All\tCtrl+A", nil)
  SetCallback(item_select_all, "ACTION", cast[ICallback](item_select_all_action_cb))

  btn_cut = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_cut, "IMAGE", "IUP_EditCut")
  niupc.SetAttribute(btn_cut, "FLAT", "Yes")
  SetCallback(btn_cut, "ACTION", cast[ICallback](item_cut_action_cb))
  niupc.SetAttribute(btn_cut, "TIP", "Cut (Ctrl+X)")
  niupc.SetAttribute(btn_cut, "CANFOCUS", "No")
  btn_copy = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  niupc.SetAttribute(btn_copy, "FLAT", "Yes")
  SetCallback(btn_copy, "ACTION", cast[ICallback](item_copy_action_cb))
  niupc.SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  niupc.SetAttribute(btn_copy, "CANFOCUS", "No")
  btn_paste = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  niupc.SetAttribute(btn_paste, "FLAT", "Yes")
  SetCallback(btn_paste, "ACTION", cast[ICallback](item_paste_action_cb))
  niupc.SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  niupc.SetAttribute(btn_paste, "CANFOCUS", "No")

  toolbar_hb = niupc.Hbox(
    btn_new,
    btn_open,
    btn_save,
    niupc.SetAttributes(niupc.Label(nil), "SEPARATOR=VERTICAL"),
    btn_cut,
    btn_copy,
    btn_paste,
    niupc.SetAttributes(niupc.Label(nil), "SEPARATOR=VERTICAL"),
    btn_find,
    nil)
  niupc.SetAttribute(toolbar_hb, "MARGIN", "5x5")
  niupc.SetAttribute(toolbar_hb, "GAP", "2")

  item_toolbar = niupc.Item("&Toobar", nil)
  SetCallback(item_toolbar, "ACTION", cast[ICallback](item_toolbar_action_cb))
  niupc.SetAttribute(item_toolbar, "VALUE", "ON")
  item_statusbar = niupc.Item("&Statusbar", nil)
  SetCallback(item_statusbar, "ACTION", cast[ICallback](item_statusbar_action_cb))
  niupc.SetAttribute(item_statusbar, "VALUE", "ON")

  item_goto = niupc.Item("&Go To...\tCtrl+G", nil)
  SetCallback(item_goto, "ACTION", cast[Icallback](item_goto_action_cb))

  item_font= niupc.Item("&Font...", nil)
  SetCallback(item_font, "ACTION", cast[Icallback](item_font_action_cb))

  item_help= niupc.Item("&Help...", nil)
  SetCallback(item_help, "ACTION", cast[Icallback](item_help_action_cb))
  item_about = niupc.Item("&About...", nil)
  SetCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

  recent_menu = niupc.Menu(nil)

  file_menu = niupc.Menu(
    item_new,
    item_open,
    item_save,
    item_saveas,
    item_revert,
    niupc.Separator(),
    niupc.Submenu("Recent &Files", recent_menu),
    item_exit,
    nil)
  edit_menu = niupc.Menu(
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    niupc.Separator(),
    item_find,
    item_find_next,
    item_replace,
    item_goto,
    niupc.Separator(),
    item_select_all,
    nil)
  format_menu = niupc.Menu(item_font, nil)
  view_menu = niupc.Menu(
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = niupc.Menu(item_help, item_about, nil)

  SetCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  SetCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

  sub_menu_file = niupc.Submenu("&File", file_menu)
  sub_menu_edit = niupc.Submenu("&Edit", edit_menu)
  sub_menu_format = niupc.Submenu("F&ormat", format_menu)
  sub_menu_view = niupc.Submenu("&View", view_menu)
  sub_menu_help = niupc.Submenu("&Help", help_menu)

  menu = niupc.Menu(sub_menu_file,
                  sub_menu_edit,
                  sub_menu_format,
                  sub_menu_view,
                  sub_menu_help,
                  nil)

  vbox = niupc.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niupc.Dialog(vbox)
  niupc.SetAttributeHandle(dlg, "MENU", menu)
  niupc.SetAttribute(dlg, "SIZE", "HALFxHALF")
  SetCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))
  niupext.SetCallback(dlg, "DROPFILES_CB", dropfiles_cb)

  niupc.SetAttribute(dlg, "CONFIG", cast[cstring](config))

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
  niupc.SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  # Initialize variables from the configuration file

  niupc.ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  let font = niupc.ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    niupc.SetStrAttribute(multitext, "FONT", font)

  if niupc.ConfigGetVariableIntDef(config, "MainWindow", "Toolbar", 1) == 0:
    niupc.SetAttribute(item_toolbar, "VALUE", "OFF")

    niupc.SetAttribute(toolbar_hb, "FLOATING", "YES")
    niupc.SetAttribute(toolbar_hb, "VISIBLE", "NO")


  if niupc.ConfigGetVariableIntDef(config, "MainWindow", "Statusbar", 1) == 0:
    niupc.SetAttribute(item_statusbar, "VALUE", "OFF")

    niupc.SetAttribute(lbl_statusbar, "FLOATING", "YES")
    niupc.SetAttribute(lbl_statusbar, "VISIBLE", "NO")

  niupc.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  return dlg

proc mainProc =
  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)
  niupc.ImageLibOpen()

  let config:PIhandle = niupc.Config()
  niupc.SetAttribute(config, "APP_NAME", "simple_notepad")
  ConfigLoad(config)

  let dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  niupc.ConfigDialogShow(config, dlg, "MainWindow")

  # initialize the current file
  new_file(dlg)

  # open a file from the command line (allow file association in Windows)
  if paramCount() == 1:
    let filename = paramStr(1)
    open_file(dlg, filename)

  MainLoop()

  niupc.Close()

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
