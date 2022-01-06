# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial3.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example3_3.c

import niup/niupc
import strformat

var multitext: niupc.PIhandle

proc open_cb(): int =
  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

  Popup(filedlg, IUP_CENTER, IUP_CENTER)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    try:
      let str = readFile($filename) # $ converts cstring to string
      # .string converts TaintedString to string
      if str.string != "":
        niupc.SetStrAttribute(multitext, "VALUE", str.string)
    except:
      niupc.Message("Error", fmt"Fail when reading from file: {filename}");

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc saveas_cb(): int =
  let filedlg = niupc.FileDlg()
  niupc.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
  niupc.SetAttribute(filedlg, "EXTFILTER", "Text Files|*.txt|All Files|*.*|")

  Popup(filedlg, IUP_CENTER, IUP_CENTER)

  if niupc.GetInt(filedlg, "STATUS") != -1:
    let filename = niupc.GetAttribute(filedlg, "VALUE")
    let str = niupc.GetAttribute(multitext, "VALUE")
    try:
      writeFile($filename, $str)
    except:
      niupc.Message("Error", fmt"Fail when writing to file: {filename}");

  niupc.Destroy(filedlg)
  return niupc.IUP_DEFAULT

proc font_cb(): int =
  let fontdlg = niupc.FontDlg()
  let font = niupc.GetAttribute(multitext, "FONT")

  niupc.SetStrAttribute(fontdlg, "VALUE", font)
  Popup(fontdlg, IUP_CENTER, IUP_CENTER)

  if niupc.GetInt(fontdlg, "STATUS") == 1:
    let font = niupc.GetAttribute(fontdlg, "VALUE")

    niupc.SetStrAttribute(multitext, "FONT", font)

  niupc.Destroy(fontdlg)
  return niupc.IUP_DEFAULT

proc about_cb(): int =
  niupc.Message("About", "   Simple Notepad\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return niupc.IUP_DEFAULT

proc exit_cb(ih:PIhandle):cint {.cdecl.}=
  return niupc.IUP_CLOSE

proc mainProc =
  var dlg, vbox: niupc.PIhandle
  var file_menu, item_exit, item_open, item_saveas: niupc.PIhandle
  var format_menu, item_font: niupc.PIhandle
  var help_menu, item_about: niupc.PIhandle
  var sub_menu_file, sub_menu_format, sub_menu_help, menu: niupc.PIhandle

  var argc:cint=0
  var argv:cstringArray=nil
  Open(argc, addr argv)

  multitext =  niupc.Text(nil)
  niupc.SetAttribute(multitext, "MULTILINE", "YES")
  niupc.SetAttribute(multitext, "EXPAND", "YES")

  item_open = niupc.Item("Open...", nil)
  item_saveas = niupc.Item("Save As...", nil)
  item_exit = niupc.Item("Exit", nil)
  item_font= niupc.Item("Font...", nil)
  item_about= niupc.Item("About...", nil)

  SetCallback(item_exit, "ACTION", cast[ICallback](exit_cb))
  SetCallback(item_open, "ACTION", cast[ICallback](open_cb))
  SetCallback(item_saveas, "ACTION", cast[ICallback](saveas_cb))
  SetCallback(item_font, "ACTION", cast[ICallback](font_cb))
  SetCallback(item_about, "ACTION", cast[ICallback](about_cb))

  file_menu = niupc.Menu(item_open,
                       item_saveas,
                       niupc.Separator(),
                       item_exit,
                       nil)
  format_menu = niupc.Menu(item_font,
                         nil)
  help_menu = niupc.Menu(item_about,
                       nil)

  sub_menu_file = niupc.Submenu("File", file_menu)
  sub_menu_format = niupc.Submenu("Format", format_menu)
  sub_menu_help = niupc.Submenu("Help", help_menu)

  menu = niupc.Menu(sub_menu_file,
                  sub_menu_format,
                  sub_menu_help,
                  nil)

  vbox = niupc.Vbox(multitext,
                  nil)

  dlg = niupc.Dialog(vbox)
  niupc.SetAttributeHandle(dlg, "MENU", menu)
  niupc.SetAttribute(dlg, "TITLE", "Simple Notepad")
  niupc.SetAttribute(dlg, "SIZE", "QUARTERxQUARTER");

  ShowXY(dlg, niupc.IUP_CENTER, niupc.IUP_CENTER)
  niupc.SetAttribute(dlg, "USERSIZE", nil);

  MainLoop()

  niupc.Close()

if isMainModule:
  mainProc()
