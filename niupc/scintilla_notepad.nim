# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://webserver2.tecgraf.puc-rio.br/iup/examples/tutorial/scintilla_notepad/scintilla_notepad.c

import niup/niupext
import niup/niupc
import strformat
import unicode
import os
import strutils

################################# Utilities ##################################

proc toggleMarker(ih:PIhandle, lin:cint, margin:cint) =
  var value = niupc.GetIntId(ih, "MARKERGET", lin)

  if margin == 1:
    value = value and 0x000001
  else:
    value = value and 0x000002

  if value > 0:
    niupc.SetIntId(ih, "MARKERDELETE", lin, margin - 1)
  else:
    niupc.SetIntId(ih, "MARKERADD", lin, margin - 1)

proc setMarkerMask(markNumber:cint):cint =
  let mask = 0x000000
  let mark = 0x00001 shl markNumber
  return cast[cint](mask or mark)

proc copyMarkedLines(multitext:PIHandle) =
  var
    size = niupc.GetInt(multitext, "COUNT")
    buffer:string
    text:cstring
    lin:cint = 0

  while lin >= 0:
    niupc.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niupc.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niupc.GetAttributeId(multitext, "LINE", lin);
      buffer = buffer & $text
      size = size - cast[cint](text.len)
      lin = lin + 1

  if buffer.len > 0:
    let clipboard = niupc.Clipboard()
    niupc.SetAttribute(clipboard, "TEXT", cstring(buffer))
    niupc.Destroy(clipboard)

proc cutMarkedLines(multitext:PIhandle) =
  var
    size = niupc.GetInt(multitext, "COUNT")
    buffer:string
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0 and size > 0:
    niupc.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niupc.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niupc.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niupc.TextConvertLinColToPos(multitext, lin, 0, pos)
      niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      buffer = buffer & $text
      size = size - cast[cint](len)
      niupc.SetIntId(multitext, "MARKERDELETE", lin, 0)
      lin = lin - 1

  if buffer.len > 0:
    let clipboard = niupc.Clipboard()
    niupc.SetAttribute(clipboard, "TEXT", cstring(buffer))
    niupc.Destroy(clipboard)

proc pasteToMarkedLines(multitext:PIhandle) =
  var
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0:
    niupc.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niupc.GetInt(multitext, "LASTMARKERFOUND");
    if lin >= 0:
      text = niupc.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niupc.TextConvertLinColToPos(multitext, lin, 0, pos)
      niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      niupc.SetIntId(multitext, "MARKERDELETE", lin, 0)
      let clipboard = niupc.Clipboard()
      niupc.SetAttributeId(multitext, "INSERT", pos, niupc.GetAttribute(clipboard, "TEXT"))
      niupc.Destroy(clipboard)
      lin = lin - 1

proc invertMarkedLines(multitext:PIhandle) =
  for lin in countup(0, niupc.GetInt(multitext, "LINECOUNT")):
    toggleMarker(multitext, cast[cint](lin), 1);

proc removeMarkedLines(multitext:PIhandle) =
  var
    text:cstring
    lin:cint = 0
    pos:cint
    len:int

  while lin >= 0:
    niupc.SetIntId(multitext, "MARKERNEXT", lin, setMarkerMask(0))
    lin = niupc.GetInt(multitext, "LASTMARKERFOUND")
    if lin >= 0:
      text = niupc.GetAttributeId(multitext, "LINE", lin)
      len = text.len
      niupc.TextConvertLinColToPos(multitext, lin, 0, pos)
      niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
      niupc.SetIntId(multitext, "MARKERDELETE", lin, 0)
      lin = lin - 1

proc removeUnmarkedLines(multitext:PIhandle) =
  var
    text:cstring
    len:cint
    start = niupc.GetInt(multitext, "LINECOUNT") - 1
    finish:cint
    posStart:cint
    posEnd:cint

  while start >= 0:
    text = niupc.GetAttributeId(multitext, "LINE", start)
    len = cast[cint](text.len)
    niupc.SetIntId(multitext, "MARKERPREVIOUS", start, setMarkerMask(0))
    finish = niupc.GetInt(multitext, "LASTMARKERFOUND")
    niupc.TextConvertLinColToPos(multitext, start, len + 1, posEnd)
    if finish >= 0:
      text = niupc.GetAttributeId(multitext, "LINE", finish)
      len = cast[cint](text.len)
      niupc.TextConvertLinColToPos(multitext, finish, len + 1, posStart)
    else:
      posStart = 0
      posEnd = posEnd + 1
    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", posStart, posEnd - posStart)
    finish = finish - 1
    start = finish

proc changeTabsToSpaces(multitext:PIhandle) =
  let
    text = niupc.GetAttribute(multitext, "VALUE")
    count = niupc.GetInt(multitext, "COUNT")
    tabSize = niupc.GetInt(multitext, "TABSIZE")
  var
    i, j, lin, col, spacesToNextTab:cint

  for i in countdown(count - 1, -1):
    let c = text[i]

    if c != '\t':
      continue

    niupc.TextConvertPosToLinCol(multitext, i, lin, col)

    spacesToNextTab = tabSize - (col + 1) mod tabSize + 1

    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", i, 1)

    for j in countup(0, spacesToNextTab - 1):
      niupc.SetAttributeId(multitext, "INSERT", cast[cint](i + j), " ")

proc changeSpacesToTabs(multitext:PIhandle) =
  let
    text = niupc.GetAttribute(multitext, "VALUE")
    count = niupc.GetInt(multitext, "COUNT")
    tabSize = niupc.GetInt(multitext, "TABSIZE")
  var
    i, lin, col, nSpaces:cint

  #for (i = count - 1; i >= 0; i--)
  i = count - 1
  while i >= 0:
    let c = text[i]

    niupc.TextConvertPosToLinCol(multitext, i, lin, col)

    #int tabStop = (col + 1) % tabSize == tabSize - 1 ? 1 : 0;
    let tabStop = ((col + 1) mod tabSize) == (tabSize - 1)

    if not tabStop or c != ' ':
      i = i - 1 #for loop iteration, i--
      continue

    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", i + 1, 1)
    niupc.SetAttributeId(multitext, "INSERT", i + 1, "\t")

    nSpaces = 0

    while (text[i - nSpaces] == ' ') and (nSpaces < tabSize - 1):
      nSpaces = nSpaces + 1

    if nSpaces == 0:
      i = i - 1 #for loop iteration, i--
      continue

    i = i - nSpaces

    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", i + 1, nSpaces)
    i = i - 1 #for loop iteration, i--

proc changeLeadingSpacesToTabs(multitext:PIhandle) =
  let
    lineCount = niupc.GetInt(multitext, "LINECOUNT")
    tabSize = niupc.GetInt(multitext, "TABSIZE")
  var
    i, j, pos, tabCount, spaceCount:cint

  for i in countup(0, lineCount - 1):
    let text = niupc.GetAttributeId(multitext, "LINE", cast[cint](i))

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

    niupc.TextConvertLinColToPos(multitext, cast[cint](i), 0, pos)
    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)
    for j in countup(0, spaceCount - 1):
      niupc.SetAttributeId(multitext, "INSERT", pos, " ")
    for j in countup(0, tabCount - 1):
      niupc.SetAttributeId(multitext, "INSERT", pos, "\t")


proc removeLeadingSpaces(multitext:PIhandle) =
  let lineCount = niupc.GetInt(multitext, "LINECOUNT")
  var pos:cint

  for i in countup(0, lineCount - 1):
    let text = niupc.GetAttributeId(multitext, "LINE", cast[cint](i))

    var len = strutils.find($text, {' ', '\t'})
    if len == -1:
      continue
    len = len + 1

    niupc.TextConvertLinColToPos(multitext, cast[cint](i), 0, pos);
    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, len)

proc removeTrailingSpaces(multitext:PIhandle) =
  let lineCount = niupc.GetInt(multitext, "LINECOUNT")
  var j, pos, count:cint

  for i in countup(0, lineCount - 1):
    let text = niupc.GetAttributeId(multitext, "LINE", cast[cint](i))

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

    niupc.TextConvertLinColToPos(multitext, cast[cint](i), cast[cint](len - count), pos)
    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, count)

proc changeEolToSpace(multitext:PIhandle) =
  while true:
    let text = niupc.GetAttribute(multitext, "VALUE")

    let pos:cint = cast[cint](strutils.find($text, '\n'))
    if pos == -1:
      break

    niupc.SetStrf(multitext, "DELETERANGE", "%d,%d", pos, 1)
    niupc.SetAttributeId(multitext, "INSERT", pos, " ")

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

  niupc.SetAttribute(dlg, "TITLE", "Untitled - Scintilla Notepad");
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

      niupc.SetfAttribute(dlg, "TITLE", "%s - Scintilla Notepad", cstring(os.extractFilename(filename)))
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

    niupc.SetfAttribute(niupc.GetDialog(multitext), "TITLE", "%s - Scintilla Notepad", cstring(os.extractFilename(filename)))
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

proc marginclick_cb(ih:PIhandle, margin:cint, lin:cint, status:cstring):int =
  if margin < 1 or margin > 2:
    return IUP_IGNORE

  toggleMarker(ih, lin, margin)

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
    find_dlg = cast[PIhandle](niupc.GetAttribute(ih, "FIND_DIALOG"))

    item_paste = niupc.GetDialogChild(ih, "ITEM_PASTE")
    item_cut = niupc.GetDialogChild(ih, "ITEM_CUT")
    item_delete = niupc.GetDialogChild(ih, "ITEM_DELETE")
    item_copy = niupc.GetDialogChild(ih, "ITEM_COPY")
    item_find_next = niupc.GetDialogChild(ih, "ITEM_FINDNEXT")
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

  if find_dlg != nil:
    let txt = niupc.GetDialogChild(find_dlg, "FIND_TEXT")
    let str_to_find = niupc.GetAttribute(txt, "VALUE")

    if str_to_find.len == 0:
      niupc.SetAttribute(item_find_next, "ACTIVE", "NO")
    else:
      niupc.SetAttribute(item_find_next, "ACTIVE", "YES")
  else:
    niupc.SetAttribute(item_find_next, "ACTIVE", "NO")

  niupc.Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle): int =
  if save_check(ih):
    let filename = niupc.GetAttribute(ih, "TITLE")
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

  let config = cast[PIhandle](niupc.GetAttribute(item_open, "CONFIG"))
  var dir = niupc.ConfigGetVariableStr(config, "MainWindow", "LastDirectory")

  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_open))
  niupc.SetStrAttribute(filedlg, "DIRECTORY", dir)

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    open_file(item_open, $filename)
    dir = niupc.GetAttribute(filedlg, "DIRECTORY")
    niupc.ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc item_saveas_action_cb(item_saveas:PIhandle): int =
  let
    multitext = niupc.GetDialogChild(item_saveas, "MULTITEXT")
    config = cast[PIhandle](niupc.GetAttribute(multitext, "CONFIG"))
    filedlg = niupc.FileDlg()
  var dir = niupc.ConfigGetVariableStr(config, "MainWindow", "LastDirectory")
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")
  niupc.SetAttributeHandle(filedlg, "PARENTDIALOG", niupc.GetDialog(item_saveas))
  niupc.SetStrAttribute(filedlg, "FILE", niupc.GetAttribute(multitext, "FILENAME"))
  niupc.SetStrAttribute(filedlg, "DIRECTORY", dir)

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    saveas_file(multitext, $filename)
    dir = niupc.GetAttribute(filedlg, "DIRECTORY")
    niupc.ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

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

proc item_gotombrace_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niupc.GetInt(multitext, "CARETPOS")
    newpos = niupc.GetIntId(multitext, "BRACEMATCH", pos)

  if newpos != -1:
    niupc.SetStrf(multitext, "BRACEHIGHLIGHT", "%d:%d", pos, newpos)

    niupc.SetInt(multitext, "CARETPOS", newpos)
    niupc.SetInt(multitext, "SCROLLTOPOS", newpos)

  return niupc.IUP_IGNORE

proc item_togglemark_action_cb(ih:PIhandle): int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niupc.GetInt(multitext, "CARETPOS")
    lin, col: cint

  niupc.TextConvertPosToLinCol(multitext, pos, lin, col)

  toggleMarker(multitext, lin, 1)

  return niupc.IUP_IGNORE

proc item_nextmark_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niupc.GetInt(multitext, "CARETPOS")
    lin, col:cint

  niupc.TextConvertPosToLinCol(multitext, pos, lin, col)

  niupc.SetIntId(multitext, "MARKERNEXT", cast[cint](lin + 1), setMarkerMask(0))

  lin = niupc.GetInt(multitext, "LASTMARKERFOUND")

  if lin == -1:
    return niupc.IUP_IGNORE

  niupc.TextConvertLinColToPos(multitext, lin, 0, pos)

  niupc.SetInt(multitext, "CARETPOS", pos)

  return niupc.IUP_DEFAULT

proc item_previousmark_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  var
    pos = niupc.GetInt(multitext, "CARETPOS")
    lin, col:cint

  niupc.TextConvertPosToLinCol(multitext, pos, lin, col)

  niupc.SetIntId(multitext, "MARKERPREVIOUS", cast[cint](lin - 1), setMarkerMask(0))

  lin = niupc.GetInt(multitext, "LASTMARKERFOUND")

  if lin == -1:
    return niupc.IUP_IGNORE

  niupc.TextConvertLinColToPos(multitext, lin, 0, pos)

  niupc.SetInt(multitext, "CARETPOS", pos)

  return niupc.IUP_DEFAULT


proc item_clearmarks_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")
  niupc.SetInt(multitext, "MARKERDELETEALL", 0)
  return niupc.IUP_DEFAULT

proc item_copymarked_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  copyMarkedLines(multitext)

  return niupc.IUP_DEFAULT

proc item_cutmarked_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  cutMarkedLines(multitext)

  return niupc.IUP_DEFAULT

proc item_pastetomarked_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  pasteToMarkedLines(multitext)

  return niupc.IUP_DEFAULT

proc item_removemarked_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  removeMarkedLines(multitext)

  return niupc.IUP_DEFAULT

proc item_removeunmarked_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  removeUnmarkedLines(multitext);

  return niupc.IUP_DEFAULT

proc item_invertmarks_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  invertMarkedLines(multitext)

  return niupc.IUP_DEFAULT

proc item_eoltospace_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeEolToSpace(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_removespaceeol_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  removeLeadingSpaces(multitext)
  changeEolToSpace(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_trimtrailing_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_trimleading_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeLeadingSpaces(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_trimtraillead_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  removeTrailingSpaces(multitext)

  removeLeadingSpaces(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_tabtospace_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeTabsToSpaces(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_allspacetotab_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeTabsToSpaces(multitext)

  changeSpacesToTabs(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

proc item_leadingspacetotab_action_cb(ih:PIhandle):int =
  let multitext = niupc.GetDialogChild(ih, "MULTITEXT")

  niupc.SetAttribute(multitext, "UNDOACTION", "BEGIN")

  changeLeadingSpacesToTabs(multitext)

  niupc.SetAttribute(multitext, "UNDOACTION", "END")

  return niupc.IUP_DEFAULT

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
  var count = niupc.GetInt(multitext, "COUNT")
  count = count - 1
  niupc.SetStrf(multitext, "SELECTIONPOS", "%d:%d", 0, count);

  return IUP_DEFAULT

proc item_undo_action_cb(item_select_all:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_select_all, "MULTITEXT")
  niupc.SetAttribute(multitext, "UNDO", "YES")
  return niupc.IUP_DEFAULT

proc item_redo_action_cb(item_select_all:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_select_all, "MULTITEXT")
  niupc.SetAttribute(multitext, "REDO", "YES")
  return niupc.IUP_DEFAULT

proc item_uppercase_action_cb(item:PIhandle):int =
  var
    start, tEnd: cint
  let multitext = niupc.GetDialogChild(item, "MULTITEXT")
  GetIntInt(multitext, "SELECTIONPOS", start, tEnd)
  var text = niupc.GetAttribute(multitext, "SELECTEDTEXT");
  var text2 = unicode.toUpper($text)
  niupc.SetAttribute(multitext, "SELECTEDTEXT", cstring(text2))
  niupc.SetStrf(multitext, "SELECTIONPOS", "%d:%d", start, tEnd);

  return niupc.IUP_DEFAULT

proc item_lowercase_action_cb(item:PIhandle):int =
  var
    start, tEnd:cint
  let multitext = niupc.GetDialogChild(item, "MULTITEXT")
  GetIntInt(multitext, "SELECTIONPOS", start, tEnd)
  var text = niupc.GetAttribute(multitext, "SELECTEDTEXT")
  var text2 = unicode.toLower($text)
  niupc.SetAttribute(multitext, "SELECTEDTEXT", cstring(text2))
  niupc.SetStrf(multitext, "SELECTIONPOS", "%d:%d", start, tEnd)

  return niupc.IUP_DEFAULT

proc item_case_action_cb(item:PIhandle):int =
  let shift = niupc.GetGlobal("SHIFTKEY")

  if shift == "ON":
    discard item_uppercase_action_cb(item)
  else:
    discard item_lowercase_action_cb(item)

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

proc item_tab_action_cb(item_font:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_font, "MULTITEXT")

  var
    replaceBySpace:cint = 0
    tabSize = niupc.GetInt(multitext, "TABSIZE")

  if niupc.GetInt(multitext, "USETABS") == 0:
    replaceBySpace = 1

  if niupc.GetParam("Tab Settings", nil, nil,
                   "Size: %i\nReplace by Whitespace: %b\n",
                   addr tabSize, addr replaceBySpace) == 0:
    return niupc.IUP_IGNORE

  niupc.SetInt(multitext, "TABSIZE", tabSize)

  var useTabs:cint = 1
  if replaceBySpace == 1:
    useTabs = 0
  niupc.SetInt(multitext, "USETABS", useTabs)

  return niupc.IUP_DEFAULT

proc item_zoomin_action_cb(item_toolbar:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_toolbar, "MULTITEXT")

  niupc.SetAttribute(multitext, "ZOOMIN", "10")

  return niupc.IUP_DEFAULT

proc item_zoomout_action_cb(item_toolbar:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_toolbar, "MULTITEXT")

  niupc.SetAttribute(multitext, "ZOOMOUT", "10")

  return niupc.IUP_DEFAULT

proc item_restorezoom_action_cb(item_toolbar:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_toolbar, "MULTITEXT")

  niupc.SetAttribute(multitext, "ZOOM", "0")

  return niupc.IUP_DEFAULT

proc item_wordwrap_action_cb(item_wordwrap:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_wordwrap, "MULTITEXT")

  if niupc.GetInt(item_wordwrap, "VALUE") > 0:
    niupc.SetAttribute(multitext, "WORDWRAP", "WORD")
  else:
    niupc.SetAttribute(multitext, "WORDWRAP", "NONE")

  return niupc.IUP_DEFAULT

proc item_showwhite_action_cb(item_showwhite:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_showwhite, "MULTITEXT")

  if niupc.GetInt(item_showwhite, "VALUE") > 0:
    niupc.SetAttribute(multitext, "WHITESPACEVIEW", "VISIBLEALWAYS")
  else:
    niupc.SetAttribute(multitext, "WHITESPACEVIEW", "INVISIBLE")

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

proc item_linenumber_action_cb(item_linenumber:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_linenumber, "MULTITEXT")

  if niupc.GetInt(item_linenumber, "VALUE") > 0:
    niupc.SetInt(multitext, "MARGINWIDTH0", 0)
    niupc.SetAttribute(item_linenumber, "VALUE", "OFF")
  else:
    niupc.SetInt(multitext, "MARGINWIDTH0", 50)
    niupc.SetAttribute(item_linenumber, "VALUE", "ON")

  return niupc.IUP_DEFAULT

proc item_bookmark_action_cb(item_bookmark:PIhandle):int =
  let multitext = niupc.GetDialogChild(item_bookmark, "MULTITEXT")

  if niupc.GetInt(item_bookmark, "VALUE") > 0:
    niupc.SetInt(multitext, "MARGINWIDTH1", 0)
    niupc.SetAttribute(item_bookmark, "VALUE", "OFF")
  else:
    niupc.SetInt(multitext, "MARGINWIDTH1", 20)
    niupc.SetAttribute(item_bookmark, "VALUE", "ON")

  return niupc.IUP_DEFAULT

proc item_help_action_cb():int =
  Help("http://www.tecgraf.puc-rio.br/iup")
  return IUP_DEFAULT

proc item_about_action_cb(): int =
  niupc.Message("About", "   Scintilla Notepad\n\nAuthors:\n   Camilo Freire\n   Antonio Scuri")
  return niupc.IUP_DEFAULT

################################# Main ######################################

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, multitext, menu: niupc.PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert: niupc.PIhandle
    sub_menu_edit, edit_menu, item_find, item_find_next, item_goto, item_gotombrace: niupc.PIhandle
    item_copy, item_paste, item_cut, item_delete, item_select_all:niupc.PIhandle
    item_togglemark, item_nextmark, item_previousmark, item_clearmarks:niupc.PIhandle
    item_cutmarked, item_copymarked, item_pastetomarked, item_removemarked:niupc.PIhandle
    item_removeunmarked, item_invertmarks, item_tabtospace, item_allspacetotab, item_leadingspacetotab:niupc.PIhandle
    item_trimleading, item_trimtrailing, item_trimtraillead, item_eoltospace, item_removespaceeol:niupc.PIhandle
    item_undo, item_redo:niupc.PIhandle
    case_menu, item_uppercase, item_lowercase:niupc.PIhandle
    btn_cut, btn_copy, btn_paste, btn_find, btn_new, btn_open, btn_save: niupc.PIhandle
    sub_menu_format, format_menu, item_font, item_tab, item_replace: niupc.PIhandle
    sub_menu_help, help_menu, item_help, item_about: niupc.PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar, item_linenumber, item_bookmark: PIhandle
    zoom_menu, item_zoomin, item_zoomout, item_restorezoom: niupc.PIhandle
    lbl_statusbar, toolbar_hb, recent_menu: niupc.PIhandle
    item_wordwrap, item_showwhite: niupc.PIhandle

  multitext =  niupc.Scintilla()
  niupc.SetAttribute(multitext, "MULTILINE", "YES")
  niupc.SetAttribute(multitext, "EXPAND", "YES")
  niupc.SetAttribute(multitext, "NAME", "MULTITEXT")
  niupc.SetAttribute(multitext, "DIRTY", "NO")

  #enable UTF-8 for GTK and Windows
  niupc.SetGlobal("UTF8MODE", "YES")
  SetCallback(multitext, "CARET_CB", cast[ICallback](multitext_caret_cb))
  SetCallback(multitext, "VALUECHANGED_CB", cast[ICallback](multitext_valuechanged_cb))
#SetCallback(multitext, "DROPFILES_CB", cast[ICallback](dropfiles_cb))
  niupext.SetCallback(multitext, "DROPFILES_CB", cast[ICallback](dropfiles_cb))
  SetCallback(multitext, "MARGINCLICK_CB", cast[ICallback](marginclick_cb))

  niupc.SetAttribute(multitext, "STYLEFGCOLOR34", "255 0 0");
  # line numbers
  niupc.SetInt(multitext, "MARGINWIDTH0", 30)
  niupc.SetAttribute(multitext, "MARGINSENSITIVE0", "YES")
  # bookmarks
  niupc.SetInt(multitext, "MARGINWIDTH1", 15)
  niupc.SetAttribute(multitext, "MARGINTYPE1", "SYMBOL")
  niupc.SetAttribute(multitext, "MARGINSENSITIVE1", "YES")
  niupc.SetAttribute(multitext, "MARGINMASKFOLDERS1", "NO")

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
  btn_cut = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_cut, "IMAGE", "IUP_EditCut")
  niupc.SetAttribute(btn_cut, "FLAT", "Yes")
  SetCallback(btn_cut, "ACTION", cast[Icallback](item_cut_action_cb))
  niupc.SetAttribute(btn_cut, "TIP", "Cut (Ctrl+X)")
  niupc.SetAttribute(btn_cut, "CANFOCUS", "No")

  item_copy = niupc.Item("Copy\tCtrl+C", nil)
  niupc.SetAttribute(item_copy, "NAME", "ITEM_COPY")
  niupc.SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  SetCallback(item_copy, "ACTION", cast[ICallback](item_copy_action_cb))
  btn_copy = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  niupc.SetAttribute(btn_copy, "FLAT", "Yes")
  SetCallback(btn_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  niupc.SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  niupc.SetAttribute(btn_copy, "CANFOCUS", "No")

  item_paste = niupc.Item("Paste\tCtrl+V", nil)
  niupc.SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  niupc.SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  SetCallback(item_paste, "ACTION", cast[ICallback](item_paste_action_cb))
  btn_paste = niupc.Button(nil, nil)
  niupc.SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  niupc.SetAttribute(btn_paste, "FLAT", "Yes")
  SetCallback(btn_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  niupc.SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  niupc.SetAttribute(btn_paste, "CANFOCUS", "No")

  item_delete = niupc.Item("Delete\tDel", nil)
  niupc.SetAttribute(item_delete, "NAME", "ITEM_DELETE")
  niupc.SetAttribute(item_delete, "IMAGE", "IUP_EditErase")
  SetCallback(item_delete, "ACTION", cast[ICallback](item_delete_action_cb))

  item_select_all = niupc.Item("Select All\tCtrl+A", nil)
  SetCallback(item_select_all, "ACTION", cast[ICallback](item_select_all_action_cb))

  item_undo = niupc.Item("Undo\tCtrl+Z", nil)
  SetCallback(item_undo, "ACTION", cast[Icallback](item_undo_action_cb))

  item_redo = niupc.Item("Redo\tCtrl+Y", nil)
  SetCallback(item_redo, "ACTION", cast[Icallback](item_redo_action_cb))

  item_uppercase = niupc.Item("UPPERCASE\tCtrl+Shift+U", nil)
  SetCallback(item_uppercase, "ACTION", cast[Icallback](item_uppercase_action_cb))

  item_lowercase = niupc.Item("lowercase\tCtrl+U", nil)
  SetCallback(item_lowercase, "ACTION", cast[Icallback](item_lowercase_action_cb))

  item_goto = niupc.Item("&Go To...\tCtrl+G", nil)
  SetCallback(item_goto, "ACTION", cast[Icallback](item_goto_action_cb))

  item_gotombrace = niupc.Item("Go To Matching Brace\tCtrl+B", nil)
  SetCallback(item_gotombrace, "ACTION", cast[Icallback](item_gotombrace_action_cb))

  item_togglemark = niupc.Item("Toggle Bookmark\tCtrl+F2", nil)
  SetCallback(item_togglemark, "ACTION", cast[Icallback](item_togglemark_action_cb))

  item_nextmark = niupc.Item("Next Bookmark\tF2", nil)
  SetCallback(item_nextmark, "ACTION", cast[Icallback](item_nextmark_action_cb))

  item_previousmark = niupc.Item("Previous Bookmark\tShift+F2", nil)
  SetCallback(item_previousmark, "ACTION", cast[Icallback](item_previousmark_action_cb))

  item_clearmarks = niupc.Item("Clear All Bookmarks", nil)
  SetCallback(item_clearmarks, "ACTION", cast[Icallback](item_clearmarks_action_cb))

  item_copymarked = niupc.Item("Copy Bookmarked Lines", nil)
  SetCallback(item_copymarked, "ACTION", cast[Icallback](item_copymarked_action_cb))

  item_cutmarked = niupc.Item("Cut Bookmarked Lines", nil)
  SetCallback(item_cutmarked, "ACTION", cast[Icallback](item_cutmarked_action_cb))

  item_pastetomarked = niupc.Item("Paste to (Replace) Bookmarked Lines", nil)
  SetCallback(item_pastetomarked, "ACTION", cast[Icallback](item_pastetomarked_action_cb))

  item_removemarked = niupc.Item("Remove Bookmarked Lines", nil)
  SetCallback(item_removemarked, "ACTION", cast[Icallback](item_removemarked_action_cb))

  item_removeunmarked = niupc.Item("Remove unmarked Lines", nil)
  SetCallback(item_removeunmarked, "ACTION", cast[Icallback](item_removeunmarked_action_cb))

  item_invertmarks = niupc.Item("Inverse Bookmark", nil)
  SetCallback(item_invertmarks, "ACTION", cast[Icallback](item_invertmarks_action_cb))

  item_trimtrailing = niupc.Item("Trim Trailing Space", nil)
  SetCallback(item_trimtrailing, "ACTION", cast[Icallback](item_trimtrailing_action_cb))

  item_trimtraillead = niupc.Item("Trim Trailing and Leading Space", nil)
  SetCallback(item_trimtraillead, "ACTION", cast[Icallback](item_trimtraillead_action_cb))

  item_eoltospace = niupc.Item("EOL to Space", nil)
  SetCallback(item_eoltospace, "ACTION", cast[Icallback](item_eoltospace_action_cb))

  item_removespaceeol = niupc.Item("Remove Unnecessary Blanks and EOL", nil)
  SetCallback(item_removespaceeol, "ACTION", cast[Icallback](item_removespaceeol_action_cb))

  item_trimleading = niupc.Item("Trim Leading Space", nil)
  SetCallback(item_trimleading, "ACTION", cast[Icallback](item_trimleading_action_cb))

  item_tabtospace = niupc.Item("TAB to Space", nil)
  SetCallback(item_tabtospace, "ACTION", cast[Icallback](item_tabtospace_action_cb))

  item_allspacetotab = niupc.Item("Space to TAB (All)", nil)
  SetCallback(item_allspacetotab, "ACTION", cast[Icallback](item_allspacetotab_action_cb))

  item_leadingspacetotab = niupc.Item("Space to TAB (Leading)", nil)
  SetCallback(item_leadingspacetotab, "ACTION", cast[Icallback](item_leadingspacetotab_action_cb))

  item_zoomin = niupc.Item("Zoom In\tCtrl_Num +", nil)
  SetCallback(item_zoomin, "ACTION", cast[Icallback](item_zoomin_action_cb))

  item_zoomout = niupc.Item("Zoom Out\tCtrl_Num -", nil)
  SetCallback(item_zoomout, "ACTION", cast[Icallback](item_zoomout_action_cb))

  item_restorezoom = niupc.Item("Restore Default Zoom\tCtrl_Num /", nil)
  SetCallback(item_restorezoom, "ACTION", cast[Icallback](item_restorezoom_action_cb))

  item_wordwrap = niupc.Item("Word Wrap", nil)
  SetCallback(item_wordwrap, "ACTION", cast[Icallback](item_wordwrap_action_cb))
  niupc.SetAttribute(item_wordwrap, "AUTOTOGGLE", "YES")

  item_showwhite = niupc.Item("Show White Spaces", nil)
  SetCallback(item_showwhite, "ACTION", cast[Icallback](item_showwhite_action_cb))
  niupc.SetAttribute(item_showwhite, "AUTOTOGGLE", "YES")

  item_toolbar = niupc.Item("&Toobar", nil)
  SetCallback(item_toolbar, "ACTION", cast[ICallback](item_toolbar_action_cb))
  niupc.SetAttribute(item_toolbar, "VALUE", "ON")

  item_statusbar = niupc.Item("&Statusbar", nil)
  SetCallback(item_statusbar, "ACTION", cast[ICallback](item_statusbar_action_cb))
  niupc.SetAttribute(item_statusbar, "VALUE", "ON")

  item_linenumber = niupc.Item("Display Line Numbers", nil)
  SetCallback(item_linenumber, "ACTION", cast[Icallback](item_linenumber_action_cb))
  niupc.SetAttribute(item_linenumber, "VALUE", "ON")

  item_bookmark = niupc.Item("Display Bookmarks", nil)
  SetCallback(item_bookmark, "ACTION", cast[Icallback](item_bookmark_action_cb))
  niupc.SetAttribute(item_bookmark, "VALUE", "ON")

  item_font= niupc.Item("&Font...", nil)
  SetCallback(item_font, "ACTION", cast[Icallback](item_font_action_cb))

  item_tab = niupc.Item("Tab...", nil)
  SetCallback(item_tab, "ACTION", cast[Icallback](item_tab_action_cb))

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

  case_menu = niupc.Menu(
      item_uppercase,
      item_lowercase,
      nil)

  edit_menu = niupc.Menu(
    item_undo,
    item_redo,
    niupc.Separator(),
    item_cut,
    item_copy,
    item_paste,
    item_delete,
    niupc.Separator(),
    item_find,
    item_find_next,
    item_replace,
    item_goto,
    item_gotombrace,
    niupc.Separator(),
    niupc.Submenu("Bookmarks", niupc.Menu(item_togglemark,
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
    niupc.Submenu("Blank Operations", niupc.Menu(
      item_trimtrailing,
      item_trimleading,
      item_trimtraillead,
      item_eoltospace,
      item_removespaceeol,
      niupc.Separator(),
      item_tabtospace,
      item_allspacetotab,
      item_leadingspacetotab,
      nil)),
    niupc.Submenu("Convert Case to", case_menu),
    niupc.Separator(),
    item_select_all,
    nil)

  format_menu = niupc.Menu(item_font, item_tab, nil)

  zoom_menu = niupc.Menu(
    item_zoomin,
    item_zoomout,
    item_restorezoom,
    nil)

  view_menu = niupc.Menu(
    niupc.Submenu("Zoom", zoom_menu),
    item_wordwrap,
    item_showwhite,
    niupc.Separator(),
    item_toolbar,
    item_statusbar,
    item_linenumber,
    item_bookmark,
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

  vbox = niupc.Vbox(toolbar_hb,
                  multitext,
                  lbl_statusbar,
                  nil)

  dlg = niupc.Dialog(vbox)
  niupc.SetAttributeHandle(dlg, "MENU", menu)
  niupc.SetAttribute(dlg, "SIZE", "HALFxHALF")
  SetCallback(dlg, "CLOSECB", cast[ICallback](item_exit_action_cb))
  niupc.SetCallback(dlg, "DROPFILES_CB", cast[ICallback](dropfiles_cb))

  niupc.SetAttribute(dlg, "CONFIG", cast[cstring](config))

  SetCallback(dlg, "K_cN", cast[ICallback](item_new_action_cb))
  SetCallback(dlg, "K_cO", cast[ICallback](item_open_action_cb))
  SetCallback(dlg, "K_cS", cast[ICallback](item_saveas_action_cb))
  SetCallback(dlg, "K_cF", cast[ICallback](item_find_action_cb))
  SetCallback(dlg, "K_cH", cast[ICallback](item_replace_action_cb)) # replace system processing
  SetCallback(dlg, "K_cG", cast[ICallback](item_goto_action_cb))
  SetCallback(dlg, "K_cB", cast[Icallback](item_gotombrace_action_cb))
  SetCallback(dlg, "K_cF2", cast[Icallback](item_togglemark_action_cb))
  SetCallback(dlg, "K_F2", cast[Icallback](item_nextmark_action_cb))
  SetCallback(dlg, "K_sF2", cast[Icallback](item_previousmark_action_cb))
  SetCallback(dlg, "K_F3", cast[ICallback](find_next_action_cb))
  SetCallback(dlg, "K_cF3", cast[ICallback](selection_find_next_action_cb))
  SetCallback(dlg, "K_cV", cast[ICallback](item_paste_action_cb))
  SetCallback(dlg, "K_c+", cast[Icallback](item_zoomin_action_cb))
  SetCallback(dlg, "K_c-", cast[Icallback](item_zoomout_action_cb))
  SetCallback(dlg, "K_c/", cast[Icallback](item_restorezoom_action_cb))
  SetCallback(dlg, "K_cU", cast[Icallback](item_case_action_cb))
  # Ctrl+C, Ctrl+X, Ctrl+A, Del, already implemented inside IupText

  # parent for pre-defined dialogs in closed functions (IupMessage and IupAlarm)
  niupc.SetAttributeHandle(nil, "PARENTDIALOG", dlg);

  # Initialize variables from the configuration file

  niupc.ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  let font = niupc.ConfigGetVariableStr(config, "MainWindow", "Font")
  if font != "":
    niupc.SetStrAttribute(multitext, "FONT", font)

  niupc.SetAttribute(multitext, "WORDWRAPVISUALFLAGS", "MARGIN")
  # line numbers
  niupc.SetAttributeId(multitext, "MARKERFGCOLOR", 0, "0 0 255")
  niupc.SetAttributeId(multitext, "MARKERBGCOLOR", 0, "0 0 255")
  niupc.SetAttributeId(multitext, "MARKERALPHA", 0, "80")
  niupc.SetAttributeId(multitext, "MARKERSYMBOL", 0, "CIRCLE")
  # bookmarks
  niupc.SetIntId(multitext, "MARGINMASK", 1, 0x000005)
  niupc.SetAttributeId(multitext, "MARKERFGCOLOR", 1, "255 0 0")
  niupc.SetAttributeId(multitext, "MARKERBGCOLOR", 1, "255 0 0")
  niupc.SetAttributeId(multitext, "MARKERALPHA", 1, "80")
  niupc.SetAttributeId(multitext, "MARKERSYMBOL", 1, "CIRCLE")

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

  niupc.ScintillaOpen()

  let config:PIhandle = niupc.Config()
  niupc.SetAttribute(config, "APP_NAME", "scintilla_notepad")
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
