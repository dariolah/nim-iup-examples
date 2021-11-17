# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_3.c

import niup
import strformat

var multitext: niup.PIhandle

proc open_cb(): int =
  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

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

proc saveas_cb(): int =
  let filedlg = niup.FileDlg()
  niup.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niup.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

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

proc font_cb(): int =
  let fontdlg = niup.FontDlg()
  let font = niup.GetAttribute(multitext, "FONT")

  niup.SetStrAttribute(fontdlg, "VALUE", font)
  Popup(fontdlg, IUP_CENTER, IUP_CENTER)

  if niup.GetInt(fontdlg, "STATUS") == 1:
    let font = niup.GetAttribute(fontdlg, "VALUE")

    niup.SetStrAttribute(multitext, "FONT", font)

  niup.Destroy(fontdlg)
  return niup.IUP_DEFAULT

proc about_cb(): int =
  niup.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niup.IUP_DEFAULT

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return niup.IUP_CLOSE

proc mainProc =
  var dlg, vbox: niup.PIhandle
  var file_menu, item_exit, item_open, item_saveas: niup.PIhandle
  var format_menu, item_font: niup.PIhandle
  var help_menu, item_about: niup.PIhandle
  var sub_menu_file, sub_menu_format, sub_menu_help, menu: niup.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  niup.Text(nil)
  niup.SetAttribute(multitext, "MULTILINE", "YES")
  niup.SetAttribute(multitext, "EXPAND", "YES")

  item_open = niup.Item("Open...", nil)
  item_saveas = niup.Item("Save As...", nil)
  item_exit = niup.Item("Exit", nil)
  item_font= niup.Item("Font...", nil)
  item_about= niup.Item("About...", nil)

  SetCallback(item_exit, "ACTION", cast[ICallback](exit_cb))
  SetCallback(item_open, "ACTION", cast[ICallback](open_cb))
  SetCallback(item_saveas, "ACTION", cast[ICallback](saveas_cb))
  SetCallback(item_font, "ACTION", cast[ICallback](font_cb))
  SetCallback(item_about, "ACTION", cast[ICallback](about_cb))

  file_menu = niup.Menu(item_open,
                       item_saveas,
                       niup.Separator(),
                       item_exit,
                       nil)
  format_menu = niup.Menu(item_font,
                         nil)
  help_menu = niup.Menu(item_about,
                       nil)

  sub_menu_file = niup.Submenu("File", file_menu)
  sub_menu_format = niup.Submenu("Format", format_menu)
  sub_menu_help = niup.Submenu("Help", help_menu)

  menu = niup.Menu(sub_menu_file,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = niup.Vbox(multitext,
                  nil)

  dlg = niup.Dialog(vbox)
  niup.SetAttributeHandle(dlg, "MENU", menu)
  niup.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niup.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, niup.IUP_CENTER, niup.IUP_CENTER)
  niup.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
