# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_3.c

import iup
import iupfix
import strformat

var multitext: iup.PIhandle

proc open_cb(): int =
  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "OPEN")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

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

proc saveas_cb(): int =
  let filedlg = iup.fileDlg()
  iup.setAttribute(filedlg, "DIALOGTYPE", "SAVE")
  iup.setAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

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

proc font_cb(): int =
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

proc about_cb(): int =
  iup.message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return iup.IUP_DEFAULT

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return iup.IUP_CLOSE

proc mainProc =
  var dlg, vbox: iup.PIhandle
  var file_menu, item_exit, item_open, item_saveas: iup.PIhandle
  var format_menu, item_font: iup.PIhandle
  var help_menu, item_about: iup.PIhandle
  var sub_menu_file, sub_menu_format, sub_menu_help, menu: iup.PIhandle

  discard iup.open(nil, nil)

  multitext =  iup.text(nil)
  iup.setAttribute(multitext, "MULTILINE", "YES")
  iup.setAttribute(multitext, "EXPAND", "YES")

  item_open = iup.item("Open...", nil)
  item_saveas = iup.item("Save As...", nil)
  item_exit = iup.item("Exit", nil)
  item_font= iup.item("Font...", nil)
  item_about= iup.item("About...", nil)

  discard iup.setCallback(item_exit, "ACTION", cast[ICallback](exit_cb))
  discard iup.setCallback(item_open, "ACTION", cast[ICallback](open_cb))
  discard iup.setCallback(item_saveas, "ACTION", cast[ICallback](saveas_cb))
  discard iup.setCallback(item_font, "ACTION", cast[ICallback](font_cb))
  discard iup.setCallback(item_about, "ACTION", cast[ICallback](about_cb))

  file_menu = iup.menu(item_open,
                       item_saveas,
                       iup.separator(),
                       item_exit,
                       nil)
  format_menu = iup.menu(item_font,
                         nil)
  help_menu = iup.menu(item_about,
                       nil)

  sub_menu_file = iup.submenu("File", file_menu)
  sub_menu_format = iup.submenu("Format", format_menu)
  sub_menu_help = iup.submenu("Help", help_menu)

  menu = iup.menu(sub_menu_file,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = iup.vbox(multitext,
                  nil)

  dlg = iup.dialog(vbox)
  iup.setAttributeHandle(dlg, "MENU", menu)
  iup.setAttribute(dlg, "TITLE", "Simple Notepad")
  iup.setAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  iup.showXY(dlg, iup.IUP_CENTER, iup.IUP_CENTER)
  iup.setAttribute(dlg, "USERSIZE", nil);

  iup.mainLoop()

  iup.close()

if isMainModule:
  mainProc()
