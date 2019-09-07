# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://webserver2.tecgraf.puc-rio.br/iup/examples/tutorial/scintilla_notepad/scintilla_notepad.c

import niup
import strformat
import unicode
import os
import strutils

################################# Utilities ##################################

proc toggleMarker(ih:PIhandle, lin:cint, margin:cint) =
  var value = niup.GetIntId(ih, "MARKERGET", lin)

  if margin == 1:
    value = value and 0x000001
  else:
    value = value and 0x000002

  if value > 0:
    niup.SetIntId(ih, "MARKERDELETE", lin, margin - 1)
  else:
    niup.SetIntId(ih, "MARKERADD", lin, margin - 1)

proc setMarkerMask(markNumber:cint):cint =
  let mask = 0x000000
  let mark = 0x00001 shl markNumber
  return cast[cint](mask or mark)

proc copyMarkedLines(multitext:PIHandle) =
  var
    size = niup.GetInt(multitext, "COUNT")
    buffer:string
    text:cstring
    lin:cint = 0

  while lin >= 0:
    niup.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niup.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niup.GetAttributeId(multitext, "LINE", lin);
      buffer = buffer & $text
      size = size - cast[cint](text.len)
      lin = lin + 1

  if buffer.len > 0:
    let clipboard = niup.Clipboard()
    niup.SetAttribute(clipboard, "TEXT", buffer)
    niup.Destroy(clipboard)

proc cutMarkedLines(multitext:PIhandle) =
  var
    size = niup.GetInt(multitext, "COUNT")
    buffer:string
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0 and size > 0:
    niup.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niup.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niup.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niup.TextConvertLinColToPos(multitext, lin, 0, pos)
      niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      buffer = buffer & $text
      size = size - cast[cint](len)
      niup.SetIntId(multitext, "MARKERDELETE", lin, 0)
      lin = lin - 1

  if buffer.len > 0:
    let clipboard = niup.Clipboard()
    niup.SetAttribute(clipboard, "TEXT", buffer)
    niup.Destroy(clipboard)

proc pasteToMarkedLines(multitext:PIhandle) =
  var
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0:
    niup.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niup.GetInt(multitext, "LASTMARKERFOUND");
    if lin >= 0:
      text = niup.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niup.TextConvertLinColToPos(multitext, lin, 0, pos)
      niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      niup.SetIntId(multitext, "MARKERDELETE", lin, 0)
      let clipboard = niup.Clipboard()
      niup.SetAttributeId(multitext, "INSERT", pos, niup.GetAttribute(clipboard, "TEXT"))
      niup.Destroy(clipboard)
      lin = lin - 1

proc invertMarkedLines(multitext:PIhandle) =
  for lin in countup(0, niup.GetInt(multitext, "LINECOUNT")):
    toggleMarker(multitext, cast[cint](lin), 1);

proc removeMarkedLines(multitext:PIhandle) =
  var
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0:
    niup.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niup.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niup.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niup.TextConvertLinColToPos(multitext, lin, 0, pos)
      niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      niup.SetIntId(multitext, "MARKERDELETE", lin, 0)
      lin = lin - 1

proc removeUnmarkedLines(multitext:PIhandle) =
  var
    text:cstring
    len:cint
    start = niup.GetInt(multitext, "LINECOUNT") - 1
    finish:cint
    posStart:cint
    posEnd:cint

  while start >= 0:
    text = niup.GetAttributeId(multitext, "LINE", start)
    len = cast[cint](text.len)
    niup.SetIntId(multitext, "MARKERPREVIOUS", start, setMarkerMask(0))
    finish = niup.GetInt(multitext, "LASTMARKERFOUND")
    niup.TextConvertLinColToPos(multitext, start, len + 1, posEnd)
    if finish >= 0:
      text = niup.GetAttributeId(multitext, "LINE", finish)
      len = cast[cint](text.len)
      niup.TextConvertLinColToPos(multitext, finish, len + 1, posStart)
    else:
      posStart = 0
      posEnd = posEnd + 1
    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", posStart, posEnd - posStart)
    finish = finish - 1
    start = finish

proc changeTabsToSpaces(multitext:PIhandle) =
  let
    text = niup.GetAttribute(multitext, "VALUE")
    count = niup.GetInt(multitext, "COUNT")
    tabSize = niup.GetInt(multitext, "TABSIZE")
  var
    i, j, lin, col, spacesToNextTab:cint

  for i in countdown(count - 1, -1):
    let c = text[i]

    if c != '\t':
      continue

    niup.TextConvertPosToLinCol(multitext, i, lin, col)

    spacesToNextTab = tabSize - (col + 1) mod tabSize + 1

    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", i, 1)

    for j in countup(0, spacesToNextTab - 1):
      niup.SetAttributeId(multitext, "INSERT", cast[cint](i + j), " ")

proc changeSpacesToTabs(multitext:PIhandle) =
  let
    text = niup.GetAttribute(multitext, "VALUE")
    count = niup.GetInt(multitext, "COUNT")
    tabSize = niup.GetInt(multitext, "TABSIZE")
  var
    i, lin, col, nSpaces:cint

  #for (i = count - 1; i >= 0; i--)
  i = count - 1
  while i >= 0:
    let c = text[i]

    niup.TextConvertPosToLinCol(multitext, i, lin, col)

    #int tabStop = (col + 1) % tabSize == tabSize - 1 ? 1 : 0;
    let tabStop = ((col + 1) mod tabSize) == (tabSize - 1)

    if not tabStop or c != ' ':
      i = i - 1 #for loop iteration, i--
      continue

    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", i + 1, 1)
    niup.SetAttributeId(multitext, "INSERT", i + 1, "\t")

    nSpaces = 0

    while (text[i - nSpaces] == ' ') and (nSpaces < tabSize - 1):
      nSpaces = nSpaces + 1

    if nSpaces == 0:
      i = i - 1 #for loop iteration, i--
      continue

    i = i - nSpaces

    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", i + 1, nSpaces)
    i = i - 1 #for loop iteration, i--

proc changeLeadingSpacesToTabs(multitext:PIhandle) =
  let
    lineCount = niup.GetInt(multitext, "LINECOUNT")
    tabSize = niup.GetInt(multitext, "TABSIZE")
  var
    i, j, pos, tabCount, spaceCount:cint

  for i in countup(0, lineCount - 1):
    let text = niup.GetAttributeId(multitext, "LINE", cast[cint](i))

    var len = strutils.find($text, {' ', '\t'})
    if len == -1:
      continue
    len = len + 1

    var
      tabCount = 0
      spaceCount = 0
    for j in countup(0, len - 1):
      if text[j] == '\t':
        tabCount = tabCount + 1
        spaceCount = 0
      else:
        spaceCount = spaceCount + 1

      if spaceCount == tabSize:
        tabCount = tabCount + 1
        spaceCount = 0

    niup.TextConvertLinColToPos(multitext, cast[cint](i), 0, pos)
    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
    for j in countup(0, spaceCount - 1):
      niup.SetAttributeId(multitext, "INSERT", pos, " ")
    for j in countup(0, tabCount - 1):
      niup.SetAttributeId(multitext, "INSERT", pos, "\t")


proc removeLeadingSpaces(multitext:PIhandle) =
  let lineCount = niup.GetInt(multitext, "LINECOUNT")
  var pos:cint

  for i in countup(0, lineCount - 1):
    let text = niup.GetAttributeId(multitext, "LINE", cast[cint](i))

    var len = strutils.find($text, {' ', '\t'})
    if len == -1:
      continue
    len = len + 1

    niup.TextConvertLinColToPos(multitext, cast[cint](i), 0, pos);
    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)

proc removeTrailingSpaces(multitext:PIhandle) =
  let lineCount = niup.GetInt(multitext, "LINECOUNT")
  var j, pos, count:cint

  for i in countup(0, lineCount - 1):
    let text = niup.GetAttributeId(multitext, "LINE", cast[cint](i))

    var len = len($text)
    if len == 0:
      continue

    if text[len - 1] == '\n':
      len = len - 1

    count = 0
    for j in countdown(len - 1, 0):
      if text[j] != ' ' and text[j] != '\t':
        break
      count = count + 1

    if count == 0:
      continue

    niup.TextConvertLinColToPos(multitext, cast[cint](i), cast[cint](len - count), pos)
    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, count)

proc changeEolToSpace(multitext:PIhandle) =
  while true:
    let text = niup.GetAttribute(multitext, "VALUE")

    let pos:cint = cast[cint](strutils.find($text, '\n'))
    if pos == -1:
      break

    niup.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, 1)
    niup.SetAttributeId(multitext, "INSERT", pos, " ")

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

  niup.SetAttribute(dlg, "TITLE", "Untitled - Scintilla Notepad");
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

      niup.SetfAttribute(dlg, "TITLE", "%s - Scintilla Notepad", os.extractFilename(filename))
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

    niup.SetfAttribute(niup.GetDialog(multitext), "TITLE", "%s - Scintilla Notepad", os.extractFilename(filename));
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

proc marginclick_cb(ih:PIhandle, margin:cint, lin:cint, status:cstring):int =
  if margin < 1 or margin > 2:
    return IUP_IGNORE

  toggleMarker(ih, lin, margin)

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
    find_dlg = cast[PIhandle](niup.GetAttribute(ih, "FIND_DIALOG"))

    item_paste = niup.GetDialogChild(ih, "ITEM_PASTE")
    item_cut = niup.GetDialogChild(ih, "ITEM_CUT")
    item_delete = niup.GetDialogChild(ih, "ITEM_DELETE")
    item_copy = niup.GetDialogChild(ih, "ITEM_COPY")
    item_find_next = niup.GetDialogChild(ih, "ITEM_FINDNEXT")
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

  if find_dlg != nil:
    let txt = niup.GetDialogChild(find_dlg, "FIND_TEXT")
    let str_to_find = niup.GetAttribute(txt, "VALUE")

    if str_to_find.len == 0:
      niup.SetAttribute(item_find_next, "ACTIVE", "NO")
    else:
      niup.SetAttribute(item_find_next, "ACTIVE", "YES")
  else:
    niup.SetAttribute(item_find_next, "ACTIVE", "NO")

  niup.Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = niup.GetAttribute(ih, "TITLE")
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

  let config = cast[PIhandle](niup.GetAttribute(item_open, "CONFIG"))
  var dir = niup.ConfigGetVariableStr(config, "MainWindow", "LastDirectory")

  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_open))
  niup.SetStrAttribute(filedlg, "DIRECTORY", dir)

  discard niup.Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    open_file(item_open, $filename)
    dir = niup.GetAttribute(filedlg, "DIRECTORY")
    niup.ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

  niup.Destroy(filedlg)
  return niup.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let
    multitext = niup.GetDialogChild(item_saveas, "MULTITEXT")
    config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))
    filedlg = niup.FileDlg()
  var dir = niup.ConfigGetVariableStr(config, "MainWindow", "LastDirectory")
  niup.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niup.SetAttributeHandle(filedlg, "PARENTDIALOG", niup.GetDialog(item_saveas))
  niup.SetStrAttribute(filedlg, "FILE", niup.GetAttribute(multitext, "FILENAME"))
  niup.SetStrAttribute(filedlg, "DIRECTORY", dir)

  discard niup.Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(filedlg, "STATUS") != -1:
    let filename = niup.GetAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)
    dir = niup.GetAttribute(filedlg, "DIRECTORY")
    niup.ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

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
  discard niup.ConfigSave(config)
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
  discard niup.SetCallback(bt_ok, "ACTION", cast[ICallback](goto_ok_action_cb))
  bt_cancel = niup.Button("Cancel", nil)
  discard niup.SetCallback(bt_cancel, "ACTION", cast[ICallback](goto_cancel_action_cb))
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

  discard niup.Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(dlg, "STATUS") == 1:
    let line = niup.GetInt(txt, "VALUE")
    var pos:cint
    niup.TextConvertLinColToPos(multitext, line, 0, pos)
    niup.SetInt(multitext, "CARETPOS", pos)
    niup.SetInt(multitext, "SCROLLTOPOS", pos)
    discard niup.SetFocus(multitext)

  niup.Destroy(dlg)

  return IUP_DEFAULT

proc item_gotombrace_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niup.GetInt(multitext, "CARETPOS")
    newpos = niup.GetIntId(multitext, "BRACEMATCH", pos)

  if newpos != -1:
    niup.SetStrf(multitext, "BRACEHIGHLIGHT", "%d:%d", pos, newpos)

    niup.SetInt(multitext, "CARETPOS", newpos)
    niup.SetInt(multitext, "SCROLLTOPOS", newpos)

  return niup.IUP_IGNORE

proc item_togglemark_action_cb(ih:PIhandle): int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niup.GetInt(multitext, "CARETPOS")
    lin, col: cint

  niup.TextConvertPosToLinCol(multitext, pos, lin, col)

  toggleMarker(multitext, lin, 1)

  return niup.IUP_IGNORE

proc item_nextmark_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niup.GetInt(multitext, "CARETPOS")
    lin, col:cint

  niup.TextConvertPosToLinCol(multitext, pos, lin, col)

  niup.SetIntId(multitext, "MARKERNEXT", cast[cint](lin + 1), setMarkerMask(0))

  lin = niup.GetInt(multitext, "LASTMARKERFOUND")

  if lin == -1:
    return niup.IUP_IGNORE

  niup.TextConvertLinColToPos(multitext, lin, 0, pos)

  niup.SetInt(multitext, "CARETPOS", pos)

  return niup.IUP_DEFAULT

proc item_previousmark_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niup.GetInt(multitext, "CARETPOS")
    lin, col:cint

  niup.TextConvertPosToLinCol(multitext, pos, lin, col)

  niup.SetIntId(multitext, "MARKERPREVIOUS", cast[cint](lin - 1), setMarkerMask(0))

  lin = niup.GetInt(multitext, "LASTMARKERFOUND")

  if lin == -1:
    return niup.IUP_IGNORE

  niup.TextConvertLinColToPos(multitext, lin, 0, pos)

  niup.SetInt(multitext, "CARETPOS", pos)

  return niup.IUP_DEFAULT


proc item_clearmarks_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")
  niup.SetInt(multitext, "MARKERDELETEALL", 0)
  return niup.IUP_DEFAULT

proc item_copymarked_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  copyMarkedLines(multitext)

  return niup.IUP_DEFAULT

proc item_cutmarked_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  cutMarkedLines(multitext)

  return niup.IUP_DEFAULT

proc item_pastetomarked_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  pasteToMarkedLines(multitext)

  return niup.IUP_DEFAULT

proc item_removemarked_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  removeMarkedLines(multitext)

  return niup.IUP_DEFAULT

proc item_removeunmarked_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  removeUnmarkedLines(multitext);

  return niup.IUP_DEFAULT

proc item_invertmarks_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  invertMarkedLines(multitext)

  return niup.IUP_DEFAULT

proc item_eoltospace_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeEolToSpace(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_removespaceeol_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  removeLeadingSpaces(multitext)
  changeEolToSpace(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_trimtrailing_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_trimleading_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeLeadingSpaces(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_trimtraillead_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  removeLeadingSpaces(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_tabtospace_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeTabsToSpaces(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_allspacetotab_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeTabsToSpaces(multitext)

  changeSpacesToTabs(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

proc item_leadingspacetotab_action_cb(ih:PIhandle):int =
  let multitext = niup.GetDialogChild(ih, "MULTITEXT")

  niup.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeLeadingSpacesToTabs(multitext)

  niup.SetAttribute(multitext, "UNDOACTION", "END")

  return niup.IUP_DEFAULT

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

    discard niup.SetFocus(multitext)
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
  discard niup.Hide(find_dlg)  # do not destroy, just hide

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
  discard niup.SetCallback(bt_next, "ACTION", cast[ICallback](find_next_action_cb))
  bt_replace = niup.Button("Replace", nil)
  niup.SetAttribute(bt_replace, "PADDING", "10x2")
  discard niup.SetCallback(bt_replace, "ACTION", cast[ICallback](find_replace_action_cb))
  niup.SetAttribute(bt_replace, "NAME", "REPLACE_BUTTON")
  bt_close = niup.Button("Close", nil)
  discard niup.SetCallback(bt_close, "ACTION", cast[ICallback](find_close_action_cb))
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
  discard niup.SetCallback(find_dlg, "CLOSE_CB", cast[ICallback](find_close_action_cb))

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
  discard niup.SetFocus(multitext)
  var count = niup.GetInt(multitext, "COUNT")
  count = count - 1
  niup.SetStrf(multitext, "SELECTIONPOS", "%d:%d", 0, count);

  return IUP_DEFAULT

proc item_undo_action_cb(item_select_all:PIhandle):int =
  let multitext = niup.GetDialogChild(item_select_all, "MULTITEXT")
  niup.SetAttribute(multitext, "UNDO", "YES")
  return niup.IUP_DEFAULT

proc item_redo_action_cb(item_select_all:PIhandle):int =
  let multitext = niup.GetDialogChild(item_select_all, "MULTITEXT")
  niup.SetAttribute(multitext, "REDO", "YES")
  return niup.IUP_DEFAULT

proc item_uppercase_action_cb(item:PIhandle):int =
  var
    start, tEnd: cint
  let multitext = niup.GetDialogChild(item, "MULTITEXT")
  discard niup.GetIntInt(multitext, "SELECTIONPOS", start, tEnd)
  var text = niup.GetAttribute(multitext, "SELECTEDTEXT");
  var text2 = unicode.toUpper($text)
  niup.SetAttribute(multitext, "SELECTEDTEXT", text2)
  niup.SetStrf(multitext, "SELECTIONPOS", "%d:%d", start, tEnd);

  return niup.IUP_DEFAULT

proc item_lowercase_action_cb(item:PIhandle):int =
  var
    start, tEnd:cint
  let multitext = niup.GetDialogChild(item, "MULTITEXT")
  discard niup.GetIntInt(multitext, "SELECTIONPOS", start, tEnd)
  var text = niup.GetAttribute(multitext, "SELECTEDTEXT")
  var text2 = unicode.toLower($text)
  niup.SetAttribute(multitext, "SELECTEDTEXT", text2)
  niup.SetStrf(multitext, "SELECTIONPOS", "%d:%d", start, tEnd)

  return niup.IUP_DEFAULT

proc item_case_action_cb(item:PIhandle):int =
  let shift = niup.GetGlobal("SHIFTKEY")

  if shift == "ON":
    discard item_uppercase_action_cb(item)
  else:
    discard item_lowercase_action_cb(item)

  return niup.IUP_DEFAULT

proc item_font_action_cb(item_font:PIhandle): int =
  let multitext = niup.GetDialogChild(item_font, "MULTITEXT")
  let fontdlg = niup.FontDlg()
  let font = niup.GetAttribute(multitext, "FONT")
  niup.SetStrAttribute(fontdlg, "VALUE", font)
  niup.SetAttributeHandle(fontdlg, "PARENTDIALOG", niup.GetDialog(item_font))

  discard niup.Popup(fontdlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niup.GetInt(fontdlg, "STATUS") == 1:
    let config = cast[PIhandle](niup.GetAttribute(multitext, "CONFIG"))
    let font = niup.GetAttribute(fontdlg, "VALUE")
    niup.SetStrAttribute(multitext, "FONT", font)
    niup.ConfigSetVariableStr(config, "MainWindow", "Font", font)

  niup.Destroy(fontdlg)
  return niup.IUP_DEFAULT

proc item_tab_action_cb(item_font:PIhandle):int =
  let multitext = niup.GetDialogChild(item_font, "MULTITEXT")

  var
    replaceBySpace:cint = 0
    tabSize = niup.GetInt(multitext, "TABSIZE")

  if niup.GetInt(multitext, "USETABS") == 0:
    replaceBySpace = 1

  if niup.GetParam("Tab Settings", nil, nil,
                   "Size: %i\nReplace by Whitespace: %b\n",
                   addr tabSize, addr replaceBySpace) == 0:
    return niup.IUP_IGNORE

  niup.SetInt(multitext, "TABSIZE", tabSize)

  var useTabs:cint = 1
  if replaceBySpace == 1:
    useTabs = 0
  niup.SetInt(multitext, "USETABS", useTabs)

  return niup.IUP_DEFAULT

proc item_zoomin_action_cb(item_toolbar:PIhandle):int =
  let multitext = niup.GetDialogChild(item_toolbar, "MULTITEXT")

  niup.SetAttribute(multitext, "ZOOMIN", "10")

  return niup.IUP_DEFAULT

proc item_zoomout_action_cb(item_toolbar:PIhandle):int =
  let multitext = niup.GetDialogChild(item_toolbar, "MULTITEXT")

  niup.SetAttribute(multitext, "ZOOMOUT", "10")

  return niup.IUP_DEFAULT

proc item_restorezoom_action_cb(item_toolbar:PIhandle):int =
  let multitext = niup.GetDialogChild(item_toolbar, "MULTITEXT")

  niup.SetAttribute(multitext, "ZOOM", "0")

  return niup.IUP_DEFAULT

proc item_wordwrap_action_cb(item_wordwrap:PIhandle):int =
  let multitext = niup.GetDialogChild(item_wordwrap, "MULTITEXT")

  if niup.GetInt(item_wordwrap, "VALUE") > 0:
    niup.SetAttribute(multitext, "WORDWRAP", "WORD")
  else:
    niup.SetAttribute(multitext, "WORDWRAP", "NONE")

  return niup.IUP_DEFAULT

proc item_showwhite_action_cb(item_showwhite:PIhandle):int =
  let multitext = niup.GetDialogChild(item_showwhite, "MULTITEXT")

  if niup.GetInt(item_showwhite, "VALUE") > 0:
    niup.SetAttribute(multitext, "WHITESPACEVIEW", "VISIBLEALWAYS")
  else:
    niup.SetAttribute(multitext, "WHITESPACEVIEW", "INVISIBLE")

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

proc item_linenumber_action_cb(item_linenumber:PIhandle):int =
  let multitext = niup.GetDialogChild(item_linenumber, "MULTITEXT")

  if niup.GetInt(item_linenumber, "VALUE") > 0:
    niup.SetInt(multitext, "MARGINWIDTH0", 0)
    niup.SetAttribute(item_linenumber, "VALUE", "OFF")
  else:
    niup.SetInt(multitext, "MARGINWIDTH0", 50)
    niup.SetAttribute(item_linenumber, "VALUE", "ON")

  return niup.IUP_DEFAULT

proc item_bookmark_action_cb(item_bookmark:PIhandle):int =
  let multitext = niup.GetDialogChild(item_bookmark, "MULTITEXT")

  if niup.GetInt(item_bookmark, "VALUE") > 0:
    niup.SetInt(multitext, "MARGINWIDTH1", 0)
    niup.SetAttribute(item_bookmark, "VALUE", "OFF")
  else:
    niup.SetInt(multitext, "MARGINWIDTH1", 20)
    niup.SetAttribute(item_bookmark, "VALUE", "ON")

  return niup.IUP_DEFAULT

proc item_help_action_cb():int =
  discard niup.Help("http://www.tecgraf.puc-rio.br/iup")
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  niup.Message("About", "   Scintilla Notepad\n\nAuthors:\n   Camilo Freire\n   Antonio Scuri")
  return niup.IUP_DEFAULT

################################# Main ######################################

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, multitext, menu: niup.PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: niup.PIhandle
    sub_menu_edit, edit_menu, item_find, item_find_next, item_goto, item_gotombrace: niup.PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:niup.PIhandle
    item_togglemark, item_nextmark, item_previousmark, item_clearmarks:niup.PIhandle
    item_cutmarked, item_copymarked, item_pastetomarked, item_removemarked:niup.PIhandle
    item_removeunmarked, item_invertmarks, item_tabtospace, item_allspacetotab, item_leadingspacetotab:niup.PIhandle
    item_trimleading, item_trimtrailing, item_trimtraillead, item_eoltospace, item_removespaceeol:niup.PIhandle
    item_undo, item_redo:niup.PIhandle
    case_menu, item_uppercase, item_lowercase:niup.PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: niup.PIhandle
    sub_menu_format, format_menu, item_font, item_tab, item_replace: niup.PIhandle
    sub_menu_help, help_menu, item_help, item_about: niup.PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar, item_linenumber, item_bookmark: PIhandle
    zoom_menu, item_zoomin, item_zoomout, item_restorezoom: niup.PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: niup.PIhandle
    item_wordwrap, item_showwhite: niup.PIhandle

  multitext =  niup.Scintilla()
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")
  niup.SetAttribute(multitext, "NAME", "MULTITEXT")
  niup.SetAttribute(multitext, "DIRTY", "NO")

  #enable UTF-8 for GTK and Windows
  niup.SetGlobal("UTF8MODE", "YES")
  discard niup.SetCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))
  discard niup.SetCallback(multitext, "VALUECHANGED_CB", cast[ICallback](multitext_valuechanged_cb))
  discard niup.SetCallback(multitext, "DROPFILES_CB", cast[ICallback](dropfiles_cb))
  discard niup.SetCallback(multitext, "MARGINCLICK_CB", cast[ICallback](marginclick_cb))

  niup.SetAttribute(multitext, "STYLEFGCOLOR34", "255 0 0");
  # line numbers
  niup.SetInt(multitext, "MARGINWIDTH0", 30)
  niup.SetAttribute(multitext, "MARGINSENSITIVE0", "YES")
  # bookmarks
  niup.SetInt(multitext, "MARGINWIDTH1", 15)
  niup.SetAttribute(multitext, "MARGINTYPE1", "SYMBOL")
  niup.SetAttribute(multitext, "MARGINSENSITIVE1", "YES")
  niup.SetAttribute(multitext, "MARGINMASKFOLDERS1", "NO")

  lbl_statusbar = niup.Label("Lin 1, Col 1")
  niup.SetAttribute(lbl_statusbar, "NAME", "STATUSBAR")
  niup.SetAttribute(lbl_statusbar, "EXPAND", "HORIZONTAL")
  niup.SetAttribute(lbl_statusbar, "PADDING", "10x5")

  item_new = niup.Item("New\tCtrl+N", nil)
  niup.SetAttribute(item_new, "IMAGE", "IUP_FileNew")
  discard niup.SetCallback(item_new, "ACTION", cast[ICallback](item_new_action_cb))
  btn_new = niup.Button(nil, nil)
  niup.SetAttribute(btn_new, "IMAGE", "IUP_FileNew")
  niup.SetAttribute(btn_new, "FLAT", "Yes")
  discard niup.SetCallback(btn_new, "ACTION", cast[ICallback](item_new_action_cb))
  niup.SetAttribute(btn_new, "TIP", "New (Ctrl+N)")
  niup.SetAttribute(btn_new, "CANFOCUS", "No")

  item_open = niup.Item("&Open...\tCtrl+O", nil)
  niup.SetAttribute(item_open, "IMAGE", "IUP_FileOpen")
  discard niup.SetCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = niup.Button(nil, nil)
  niup.SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  niup.SetAttribute(btn_open, "FLAT", "Yes")
  discard niup.SetCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  niup.SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  niup.SetAttribute(btn_open, "CANFOCUS", "No")

  item_save = niup.Item("Save\tCtrl+S", nil);
  niup.SetAttribute(item_save, "NAME", "ITEM_SAVE")
  niup.SetAttribute(item_save, "IMAGE", "IUP_FileSave")
  discard niup.SetCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = niup.Button(nil, nil)
  niup.SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  niup.SetAttribute(btn_save, "FLAT", "Yes")
  discard niup.SetCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  niup.SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  niup.SetAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = niup.Item("Save &As...\tCtrl+S", nil)
  niup.SetAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  discard niup.SetCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = niup.Item("Revert", nil)
  niup.SetAttribute(item_revert, "NAME", "ITEM_REVERT")
  discard niup.SetCallback(item_revert, "ACTION", cast[ICallback](item_revert_action_cb))

  item_exit = niup.Item("E&xit", nil)
  discard niup.SetCallback(item_exit, "ACTION", cast[ICallback](item_exit_action_cb))

  item_find = niup.Item("&Find...\tCtrl+F", nil)
  niup.SetAttribute(item_find, "IMAGE", "IUP_EditFind")
  discard niup.SetCallback(item_find, "ACTION", cast[ICallback](item_find_action_cb))
  btn_find = niup.Button(nil, nil)
  niup.SetAttribute(btn_find, "IMAGE", "IUP_EditFind")
  niup.SetAttribute(btn_find, "FLAT", "Yes")
  discard niup.SetCallback(btn_find, "ACTION", cast[ICallback](item_find_action_cb))
  niup.SetAttribute(btn_find, "TIP", "Find (Ctrl+F)")
  niup.SetAttribute(btn_find, "CANFOCUS", "No")

  item_find_next = niup.Item("Find &Next\tF3", nil)
  niup.SetAttribute(item_find_next, "NAME", "ITEM_FINDNEXT")
  discard niup.SetCallback(item_find_next, "ACTION", cast[Icallback](find_next_action_cb))

  item_replace = niup.Item("&Replace...\tCtrl+H", nil)
  discard niup.SetCallback(item_replace, "ACTION", cast[Icallback](item_replace_action_cb))

  item_cut = niup.Item("Cut\tCtrl+X", nil)
  niup.SetAttribute(item_cut, "NAME", "ITEM_CUT")
  niup.SetAttribute(item_cut, "IMAGE", "IUP_EditCut")
  discard niup.SetCallback(item_cut, "ACTION", cast[ICallback](item_cut_action_cb))
  btn_cut = niup.Button(nil, nil)
  niup.SetAttribute(btn_cut, "IMAGE", "IUP_EditCut")
  niup.SetAttribute(btn_cut, "FLAT", "Yes")
  discard niup.SetCallback(btn_cut, "ACTION", cast[Icallback](item_cut_action_cb))
  niup.SetAttribute(btn_cut, "TIP", "Cut (Ctrl+X)")
  niup.SetAttribute(btn_cut, "CANFOCUS", "No")

  item_copy = niup.Item("Copy\tCtrl+C", nil)
  niup.SetAttribute(item_copy, "NAME", "ITEM_COPY")
  niup.SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  discard niup.SetCallback(item_copy, "ACTION", cast[ICallback](item_copy_action_cb))
  btn_copy = niup.Button(nil, nil)
  niup.SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  niup.SetAttribute(btn_copy, "FLAT", "Yes")
  discard niup.SetCallback(btn_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  niup.SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  niup.SetAttribute(btn_copy, "CANFOCUS", "No")

  item_paste = niup.Item("Paste\tCtrl+V", nil)
  niup.SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  niup.SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  discard niup.SetCallback(item_paste, "ACTION", cast[ICallback](item_paste_action_cb))
  btn_paste = niup.Button(nil, nil)
  niup.SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  niup.SetAttribute(btn_paste, "FLAT", "Yes")
  discard niup.SetCallback(btn_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  niup.SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  niup.SetAttribute(btn_paste, "CANFOCUS", "No")

  item_delete = niup.Item("Delete\tDel", nil)
  niup.SetAttribute(item_delete, "NAME", "ITEM_DELETE")
  niup.SetAttribute(item_delete, "IMAGE", "IUP_EditErase")
  discard niup.SetCallback(item_delete, "ACTION", cast[ICallback](item_delete_action_cb))

  item_select_all = niup.Item("Select All\tCtrl+A", nil)
  discard niup.SetCallback(item_select_all, "ACTION", cast[ICallback](item_select_all_action_cb))

  item_undo = niup.Item("Undo\tCtrl+Z", nil)
  discard niup.SetCallback(item_undo, "ACTION", cast[Icallback](item_undo_action_cb))

  item_redo = niup.Item("Redo\tCtrl+Y", nil)
  discard niup.SetCallback(item_redo, "ACTION", cast[Icallback](item_redo_action_cb))

  item_uppercase = niup.Item("UPPERCASE\tCtrl+Shift+U", nil)
  discard niup.SetCallback(item_uppercase, "ACTION", cast[Icallback](item_uppercase_action_cb))

  item_lowercase = niup.Item("lowercase\tCtrl+U", nil)
  discard niup.SetCallback(item_lowercase, "ACTION", cast[Icallback](item_lowercase_action_cb))

  item_goto = niup.Item("&Go To...\tCtrl+G", nil)
  discard niup.SetCallback(item_goto, "ACTION", cast[Icallback](item_goto_action_cb))

  item_gotombrace = niup.Item("Go To Matching Brace\tCtrl+B", nil)
  discard niup.SetCallback(item_gotombrace, "ACTION", cast[Icallback](item_gotombrace_action_cb))

  item_togglemark = niup.Item("Toggle Bookmark\tCtrl+F2", nil)
  discard niup.SetCallback(item_togglemark, "ACTION", cast[Icallback](item_togglemark_action_cb))

  item_nextmark = niup.Item("Next Bookmark\tF2", nil)
  discard niup.SetCallback(item_nextmark, "ACTION", cast[Icallback](item_nextmark_action_cb))

  item_previousmark = niup.Item("Previous Bookmark\tShift+F2", nil)
  discard niup.SetCallback(item_previousmark, "ACTION", cast[Icallback](item_previousmark_action_cb))

  item_clearmarks = niup.Item("Clear All Bookmarks", nil)
  discard niup.SetCallback(item_clearmarks, "ACTION", cast[Icallback](item_clearmarks_action_cb))

  item_copymarked = niup.Item("Copy Bookmarked Lines", nil)
  discard niup.SetCallback(item_copymarked, "ACTION", cast[Icallback](item_copymarked_action_cb))

  item_cutmarked = niup.Item("Cut Bookmarked Lines", nil)
  discard niup.SetCallback(item_cutmarked, "ACTION", cast[Icallback](item_cutmarked_action_cb))

  item_pastetomarked = niup.Item("Paste to (Replace) Bookmarked Lines", nil)
  discard niup.SetCallback(item_pastetomarked, "ACTION", cast[Icallback](item_pastetomarked_action_cb))

  item_removemarked = niup.Item("Remove Bookmarked Lines", nil)
  discard niup.SetCallback(item_removemarked, "ACTION", cast[Icallback](item_removemarked_action_cb))

  item_removeunmarked = niup.Item("Remove unmarked Lines", nil)
  discard niup.SetCallback(item_removeunmarked, "ACTION", cast[Icallback](item_removeunmarked_action_cb))

  item_invertmarks = niup.Item("Inverse Bookmark", nil)
  discard niup.SetCallback(item_invertmarks, "ACTION", cast[Icallback](item_invertmarks_action_cb))

  item_trimtrailing = niup.Item("Trim Trailing Space", nil)
  discard niup.SetCallback(item_trimtrailing, "ACTION", cast[Icallback](item_trimtrailing_action_cb))

  item_trimtraillead = niup.Item("Trim Trailing and Leading Space", nil)
  discard niup.SetCallback(item_trimtraillead, "ACTION", cast[Icallback](item_trimtraillead_action_cb))

  item_eoltospace = niup.Item("EOL to Space", nil)
  discard niup.SetCallback(item_eoltospace, "ACTION", cast[Icallback](item_eoltospace_action_cb))

  item_removespaceeol = niup.Item("Remove Unnecessary Blanks and EOL", nil)
  discard niup.SetCallback(item_removespaceeol, "ACTION", cast[Icallback](item_removespaceeol_action_cb))

  item_trimleading = niup.Item("Trim Leading Space", nil)
  discard niup.SetCallback(item_trimleading, "ACTION", cast[Icallback](item_trimleading_action_cb))

  item_tabtospace = niup.Item("TAB to Space", nil)
  discard niup.SetCallback(item_tabtospace, "ACTION", cast[Icallback](item_tabtospace_action_cb))

  item_allspacetotab = niup.Item("Space to TAB (All)", nil)
  discard niup.SetCallback(item_allspacetotab, "ACTION", cast[Icallback](item_allspacetotab_action_cb))

  item_leadingspacetotab = niup.Item("Space to TAB (Leading)", nil)
  discard niup.SetCallback(item_leadingspacetotab, "ACTION", cast[Icallback](item_leadingspacetotab_action_cb))

  item_zoomin = niup.Item("Zoom In\tCtrl_Num +", nil)
  discard niup.SetCallback(item_zoomin, "ACTION", cast[Icallback](item_zoomin_action_cb))

  item_zoomout = niup.Item("Zoom Out\tCtrl_Num -", nil)
  discard niup.SetCallback(item_zoomout, "ACTION", cast[Icallback](item_zoomout_action_cb))

  item_restorezoom = niup.Item("Restore Default Zoom\tCtrl_Num /", nil)
  discard niup.SetCallback(item_restorezoom, "ACTION", cast[Icallback](item_restorezoom_action_cb))

  item_wordwrap = niup.Item("Word Wrap", nil)
  discard niup.SetCallback(item_wordwrap, "ACTION", cast[Icallback](item_wordwrap_action_cb))
  niup.SetAttribute(item_wordwrap, "AUTOTOGGLE", "YES")

  item_showwhite = niup.Item("Show White Spaces", nil)
  discard niup.SetCallback(item_showwhite, "ACTION", cast[Icallback](item_showwhite_action_cb))
  niup.SetAttribute(item_showwhite, "AUTOTOGGLE", "YES")

  item_toolbar = niup.Item("&Toobar", nil)
  discard niup.SetCallback(item_toolbar, "ACTION", cast[ICallback](item_toolbar_action_cb))
  niup.SetAttribute(item_toolbar, "VALUE", "ON")

  item_statusbar = niup.Item("&Statusbar", nil)
  discard niup.SetCallback(item_statusbar, "ACTION", cast[ICallback](item_statusbar_action_cb))
  niup.SetAttribute(item_statusbar, "VALUE", "ON")

  item_linenumber = niup.Item("Display Line Numbers", nil)
  discard niup.SetCallback(item_linenumber, "ACTION", cast[Icallback](item_linenumber_action_cb))
  niup.SetAttribute(item_linenumber, "VALUE", "ON")

  item_bookmark = niup.Item("Display Bookmarks", nil)
  discard niup.SetCallback(item_bookmark, "ACTION", cast[Icallback](item_bookmark_action_cb))
  niup.SetAttribute(item_bookmark, "VALUE", "ON")

  item_font= niup.Item("&Font...", nil)
  discard niup.SetCallback(item_font, "ACTION", cast[Icallback](item_font_action_cb))

  item_tab = niup.Item("Tab...", nil)
  discard niup.SetCallback(item_tab, "ACTION", cast[Icallback](item_tab_action_cb))

  item_help= niup.Item("&Help...", nil)
  discard niup.SetCallback(item_help, "ACTION", cast[Icallback](item_help_action_cb))

  item_about = niup.Item("&About...", nil)
  discard niup.SetCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

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

  case_menu = niup.Menu(
      item_uppercase,
      item_lowercase,
      nil)

  edit_menu = niup.Menu(
    item_undo,
    item_redo,
    niup.Separator(),
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    niup.Separator(),
    item_find,
    item_find_next,
    item_replace,
    item_goto,
    item_gotombrace,
    niup.Separator(),
    niup.Submenu("Bookmarks", niup.Menu(item_togglemark,
      item_nextmark,
      item_previousmark,
      item_clearmarks,
      item_cutmarked,
      item_copymarked,
      item_pastetomarked,
      item_removemarked,
      item_removeunmarked,
      item_invertmarks,
      nil)),
    niup.Submenu("Blank Operations", niup.Menu(
      item_trimtrailing,
      item_trimleading,
      item_trimtraillead,
      item_eoltospace,
      item_removespaceeol,
      niup.Separator(),
      item_tabtospace,
      item_allspacetotab,
      item_leadingspacetotab,
      nil)),
    niup.Submenu("Convert Case to", case_menu),
    niup.Separator(),
    item_select_all,
    nil)

  format_menu = niup.Menu(item_font, item_tab, nil)

  zoom_menu = niup.Menu(
    item_zoomin,
    item_zoomout,
    item_restorezoom,
    nil)

  view_menu = niup.Menu(
    niup.Submenu("Zoom", zoom_menu),
    item_wordwrap,
    item_showwhite,
    niup.Separator(),
    item_toolbar,
    item_statusbar,
    item_linenumber,
    item_bookmark,
    nil)
  help_menu = niup.Menu(item_help, item_about, nil)

  discard niup.SetCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  discard niup.SetCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

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

  vbox = niup.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niup.Dialog(vbox)
  niup.SetAttributeHandle(dlg, "MENU", menu)
  niup.SetAttribute(dlg, "SIZE", "HALFxHALF")
  discard niup.SetCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))
  discard niup.SetCallback(dlg, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  niup.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  discard niup.SetCallback(dlg, "K_cN", cast[ICallback](item_new_action_cb))
  discard niup.SetCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  discard niup.SetCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  discard niup.SetCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  discard niup.SetCallback(dlg, "K_cH", cast[ICallback](item_replace_action_cb)) # replace system processing
  discard niup.SetCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))
  discard niup.SetCallback(dlg, "K_cB", cast[Icallback](item_gotombrace_action_cb))
  discard niup.SetCallback(dlg, "K_cF2", cast[Icallback](item_togglemark_action_cb))
  discard niup.SetCallback(dlg, "K_F2", cast[Icallback](item_nextmark_action_cb))
  discard niup.SetCallback(dlg, "K_sF2", cast[Icallback](item_previousmark_action_cb))
  discard niup.SetCallback(dlg, "K_F3", cast[ICallback](find_next_action_cb))
  discard niup.SetCallback(dlg, "K_cF3", cast[ICallback](selection_find_next_action_cb))
  discard niup.SetCallback(dlg, "K_cV", cast[ICallback](item_paste_action_cb))
  discard niup.SetCallback(dlg, "K_c+", cast[Icallback](item_zoomin_action_cb))
  discard niup.SetCallback(dlg, "K_c-", cast[Icallback](item_zoomout_action_cb))
  discard niup.SetCallback(dlg, "K_c/", cast[Icallback](item_restorezoom_action_cb))
  discard niup.SetCallback(dlg, "K_cU", cast[Icallback](item_case_action_cb))
  # Ctrl+C, Ctrl+X, Ctrl+A, Del, already implemented inside IupText

  # parent for pre-defined dialogs in closed functions (IupMessage and IupAlarm)
  niup.SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  # Initialize variables from the configuration file

  niup.ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  let font = niup.ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    niup.SetStrAttribute(multitext, "FONT", font)

  niup.SetAttribute(multitext, "WORDWRAPVISUALFLAGS", "MARGIN")
  # line numbers
  niup.SetAttributeId(multitext, "MARKERFGCOLOR", 0, "0 0 255")
  niup.SetAttributeId(multitext, "MARKERBGCOLOR", 0, "0 0 255")
  niup.SetAttributeId(multitext, "MARKERALPHA", 0, "80")
  niup.SetAttributeId(multitext, "MARKERSYMBOL", 0, "CIRCLE")
  # bookmarks
  niup.SetIntId(multitext, "MARGINMASK", 1, 0x000005)
  niup.SetAttributeId(multitext, "MARKERFGCOLOR", 1, "255 0 0")
  niup.SetAttributeId(multitext, "MARKERBGCOLOR", 1, "255 0 0")
  niup.SetAttributeId(multitext, "MARKERALPHA", 1, "80")
  niup.SetAttributeId(multitext, "MARKERSYMBOL", 1, "CIRCLE")

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
  discard niup.Open(argc, addr argv)
  niup.ImageLibOpen()

  niup.ScintillaOpen()

  let config:PIhandle = niup.Config()
  niup.SetAttribute(config, "APP_NAME", "scintilla_notepad")
  discard niup.ConfigLoad(config)

  let dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  niup.ConfigDialogShow(config, dlg, "MainWindow")

  # initialize the current file
  new_file(dlg)

  # open a file from the command line (allow file association in Windows)
  if paramCount() == 1:
    let filename = paramStr(1)
    open_file(dlg, filename)

  discard niup.MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
