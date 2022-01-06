# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial4.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example4_1.c

import niup/niupc
import niup/niupext
import strformat
import unicode
import os


#********************************** Utilities *****************************************

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

proc show_error(message:string, is_error:int) =
  let dlg = MessageDlg()
  SetStrAttribute(dlg, "PARENTDIALOG", GetGlobal("PARENTDIALOG"))
  if is_error == 0:
    SetAttribute(dlg, "DIALOGTYPE", "WARNING")
    SetStrAttribute(dlg, "TITLE", "Warning")
  else:
    SetAttribute(dlg, "DIALOGTYPE", "ERROR")
    SetStrAttribute(dlg, "TITLE", "Error")
  SetAttribute(dlg, "BUTTONS", "OK")
  SetStrAttribute(dlg, "VALUE", message)
  Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)
  Destroy(dlg)

proc show_file_error(error:imErrorCodes) =
  case error:
  of IM_ERR_OPEN:
    show_error("Error Opening File.",  1)
  of IM_ERR_MEM:
    show_error("Insufficient memory.",  1)
  of IM_ERR_ACCESS:
    show_error("Error Accessing File.",  1)
  of IM_ERR_DATA:
    show_error("Image type not Supported.",  1)
  of IM_ERR_FORMAT:
    show_error("Invalid Format.",  1)
  of IM_ERR_COMPRESS:
    show_error("Invalid or unsupported compression.",  1)
  else:
    show_error("Unknown Error.",  1)

proc read_file(filename:string):ptr imImage =
  var
    error:imErrorCodes
    image = imFileImageLoadBitmap($filename, 0, addr error)
  if error != IM_ERR_NONE:
    show_file_error(error)
  else:
    # we are going to support only RGB images with no alpha
    imImageRemoveAlpha(image)
    if image.color_space != IM_RGB:
      var new_image = imImageCreateBased(image, -1, -1, IM_RGB, cast[imDataType](-1))
      imConvertColorSpace(image, new_image)
      imImageDestroy(image)
      image = new_image
  return image

proc write_file(filename:cstring, image:ptr imImage):bool =
  let
    format = imImageGetAttribString(image, "FileFormat")
    error = imFileImageSave(filename, format, image)
  if error != IM_ERR_NONE:
    show_file_error(error)
    return false
  return true

proc new_file(ih:PIhandle, image:ptr imImage) =
  let
    dlg = GetDialog(ih)
    canvas = GetDialogChild(dlg, "CANVAS")
    old_image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  SetAttribute(dlg, "TITLE", "Untitled - Simple Paint")
  SetAttribute(canvas, "FILENAME", nil)
  SetAttribute(canvas, "DIRTY", "NO")

  SetAttribute(canvas, "IMAGE", cast[cstring](image))

  Update(canvas)

  if old_image != nil:
    imImageDestroy(old_image)

proc check_new_file(dlg:PIhandle) =
  let canvas = GetDialogChild(dlg, "CANVAS")
  var image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  if image != nil:
    let
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
      width = ConfigGetVariableIntDef(config, "NewImage", "Width", 640)
      height = ConfigGetVariableIntDef(config, "NewImage", "Height", 480)

    image = imImageCreate(width, height, IM_RGB, IM_BYTE)

    new_file(dlg, image)

proc open_file(ih:PIhandle, filename:string) =
  let image = read_file(filename)
  if image != nil:
    let
      dlg = GetDialog(ih)
      canvas = GetDialogChild(dlg, "CANVAS")
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
      old_image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

    SetfAttribute(dlg, "TITLE", "%s - Simple Paint", os.extractFilename(filename))
    SetStrAttribute(canvas, "FILENAME", filename)
    SetAttribute(canvas, "DIRTY", "NO")
    SetAttribute(canvas, "IMAGE", cast[cstring](image))

    Update(canvas)

    if old_image != nil:
      imImageDestroy(old_image)

    ConfigRecentUpdate(config, filename)

proc save_file(canvas:PIhandle) =
  let filename = GetAttribute(canvas, "FILENAME")
  let image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
  if write_file(filename, image):
    SetAttribute(canvas, "DIRTY", "NO")

proc set_file_format(image:ptr imImage, filename:string) =
  let (dir, name, ext) = splitFile(filename)
  var format = "JPEG"

  if ext.toLower() == ".jpg" or ext.toLower() == ".jpg":
    format = "JPEG"
  elif ext.toLower() == ".bmp":
    format = "BMP"
  elif ext.toLower() == ".png":
    format = "PNG"
  elif ext.toLower() == ".tga":
    format = "TGA"
  elif ext.toLower() == ".tif" or ext.toLower() == ".tiff":
    format = "TIFF"
  imImageSetAttribString(image, "FileFormat", format)

proc saveas_file(canvas:PIhandle, filename:string) =
  let image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  set_file_format(image, filename)

  if write_file(filename, image):
    let config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))

    SetfAttribute(GetDialog(canvas), "TITLE", "%s - Simple Paint", os.extractFilename(filename))
    SetStrAttribute(canvas, "FILENAME", filename)
    SetAttribute(canvas, "DIRTY", "NO")

    ConfigRecentUpdate(config, filename)

proc save_check(ih:PIhandle):bool =
  let canvas = GetDialogChild(ih, "CANVAS")
  if GetInt(canvas, "DIRTY") > 0:
    case Alarm("Warning", "File not saved! Save it now?", "Yes", "No", "Cancel"):
    of 1:  # save the changes and continue
      save_file(canvas)
    of 2:  # ignore the changes and continue
      return true
    else:  # 3: cancel
      return false
  return true

proc toggle_bar_visibility(item:PIhandle, ih:PIhandle) =
  if GetInt(item, "VALUE") > 0:
    SetAttribute(ih, "FLOATING", "YES")
    SetAttribute(ih, "VISIBLE", "NO")
    SetAttribute(item, "VALUE", "OFF")
  else:
    SetAttribute(ih, "FLOATING", "NO")
    SetAttribute(ih, "VISIBLE", "YES")
    SetAttribute(item, "VALUE", "ON")

  Refresh(ih)  # refresh the dialog layout

#/********************************** Callbacks *****************************************/

proc dropfiles_cb(ih:PIhandle, filename:cstring):cint =
  if save_check(ih):
    open_file(ih, $filename)

  return IUP_DEFAULT

proc file_menu_open_cb(ih:PIhandle):cint =
  let
    item_revert = GetDialogChild(ih, "ITEM_REVERT")
    item_save = GetDialogChild(ih, "ITEM_SAVE")
    canvas = GetDialogChild(ih, "CANVAS")
    filename = GetAttribute(canvas, "FILENAME")
    dirty = GetInt(canvas, "DIRTY")

  if dirty != 0:
    SetAttribute(item_save, "ACTIVE", "YES")
  else:
    SetAttribute(item_save, "ACTIVE", "NO")

  if dirty != 0 and filename != "":
    SetAttribute(item_revert, "ACTIVE", "YES")
  else:
    SetAttribute(item_revert, "ACTIVE", "NO")
  return IUP_DEFAULT

proc edit_menu_open_cb(ih:PIhandle):cint =
  let
    clipboard = Clipboard()
    item_paste = GetDialogChild(ih, "ITEM_PASTE")

  if GetInt(clipboard, "IMAGEAVAILABLE") == 0:
    SetAttribute(item_paste, "ACTIVE", "NO")
  else:
    SetAttribute(item_paste, "ACTIVE", "YES")

  Destroy(clipboard)
  return IUP_DEFAULT

proc config_recent_cb(ih:PIhandle):cint =
  if save_check(ih):
    let filename = GetAttribute(ih, "RECENTFILENAME")
    open_file(ih, $filename)

  return IUP_DEFAULT

proc item_new_action_cb(item_new:PIhandle):cint =
  if save_check(item_new):
    let
      canvas = GetDialogChild(item_new, "CANVAS")
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
    var
      width = ConfigGetVariableIntDef(config, "NewImage", "Width", 640)
      height = ConfigGetVariableIntDef(config, "NewImage", "Height", 480)

    if GetParam("New Image", nil, nil, "Width: %i[1,]\nHeight: %i[1,]\n", width, height, nil) != 0:
      let image = imImageCreate(width, height, IM_RGB, IM_BYTE)

      ConfigSetVariableInt(config, "NewImage", "Width", width)
      ConfigSetVariableInt(config, "NewImage", "Height", height)

      new_file(item_new, image)

  return IUP_DEFAULT

proc select_file(parent_dlg:PIhandle, is_open:cint):cint =
  let
    config = cast[PIhandle](GetAttribute(parent_dlg, "CONFIG"))
    canvas = GetDialogChild(parent_dlg, "CANVAS")
    filedlg = FileDlg()
  var
    dir = ConfigGetVariableStr(config, "MainWindow", "LastDirectory")

  if is_open != 0:
    SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  else:
    SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
    SetStrAttribute(filedlg, "FILE", GetAttribute(canvas, "FILENAME"))

  SetAttribute(filedlg, "EXTFILTER", "Image Files|*.bmp;*.jpg;*.png;*.tif;*.tga|All Files|*.*|")
  SetStrAttribute(filedlg, "DIRECTORY", dir)
  SetAttributeHandle(filedlg, "PARENTDIALOG", parent_dlg)

  Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)
  if GetInt(filedlg, "STATUS") != -1:
    let filename = GetAttribute(filedlg, "VALUE")
    if is_open != 0:
      open_file(parent_dlg, $filename)
    else:
      saveas_file(canvas, $filename)

    dir = GetAttribute(filedlg, "DIRECTORY")
    ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

  Destroy(filedlg)
  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle):cint =
  if not save_check(item_open):
    return IUP_DEFAULT

  return select_file(GetDialog(item_open), 1)

proc item_saveas_action_cb(item_saveas:PIhandle):cint =
  return select_file(GetDialog(item_saveas), 0)

proc item_save_action_cb(item_save:PIhandle):cint =
  let
    canvas = GetDialogChild(item_save, "CANVAS")
    filename = GetAttribute(canvas, "FILENAME")

  if filename == nil:
    discard item_saveas_action_cb(item_save)
  else:
    # test again because in can be called using the hot key
    let dirty = GetInt(canvas, "DIRTY")
    if dirty == 1:
      save_file(canvas)

  return IUP_DEFAULT

proc item_revert_action_cb(item_revert:PIhandle):cint =
  let
    canvas = GetDialogChild(item_revert, "CANVAS")
    filename = GetAttribute(canvas, "FILENAME")
  open_file(item_revert, $filename)
  return IUP_DEFAULT

proc item_exit_action_cb(item_exit:PIhandle):cint =
  let
    dlg = GetDialog(item_exit)
    config = cast[PIhandle](GetAttribute(dlg, "CONFIG"))
    canvas = GetDialogChild(dlg, "CANVAS")
    image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  if not save_check(item_exit):
    return IUP_IGNORE  # to abort the CLOSE_CB callback

  if image != nil:
    imImageDestroy(image)

  ConfigDialogClosed(config, dlg, "MainWindow")
  ConfigSave(config)
  Destroy(config)
  return IUP_CLOSE

proc item_copy_action_cb(item_copy:PIhandle):cint =
  let
    canvas = GetDialogChild(item_copy, "CANVAS")
    image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
    clipboard = Clipboard()
  SetAttribute(clipboard, "NATIVEIMAGE", cast[cstring](GetImageNativeHandle(image)))
  Destroy(clipboard)
  return IUP_DEFAULT

proc item_paste_action_cb(item_paste:PIhandle):cint =
  if save_check(item_paste):
    let
      canvas = GetDialogChild(item_paste, "CANVAS")
      old_image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
      clipboard = Clipboard()

    var image = GetNativeHandleImage(GetAttribute(clipboard, "NATIVEIMAGE"))

    Destroy(clipboard)

    if image == nil:
      show_error("Invalid Clipboard Data", 1)
      return IUP_DEFAULT

    # we are going to support only RGB images with no alpha
    imImageRemoveAlpha(image)
    if image.color_space != IM_RGB:
      var new_image = imImageCreateBased(image, -1, -1, IM_RGB, cast[imDataType](-1))
      imConvertColorSpace(image, new_image)
      imImageDestroy(image)
      image = new_image

    imImageSetAttribString(image, "FileFormat", "JPEG")

    SetAttribute(canvas, "DIRTY", "Yes")
    SetAttribute(canvas, "IMAGE", cast[cstring](image))
    SetAttribute(canvas, "FILENAME", nil)
    SetAttribute(GetDialog(canvas), "TITLE", "Untitled - Simple Paint")

    Update(canvas)

    if old_image != nil:
      imImageDestroy(old_image)

  return IUP_DEFAULT

proc item_toolbar_action_cb(item_toolbar:PIhandle):cint =
  let
    canvas = GetDialogChild(item_toolbar, "CANVAS")
    toolbar = GetChild(GetParent(canvas), 0)
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))

  toggle_bar_visibility(item_toolbar, toolbar)

  ConfigSetVariableStr(config, "MainWindow", "Toolbar", GetAttribute(item_toolbar, "VALUE"))
  return IUP_DEFAULT

proc item_statusbar_action_cb(item_statusbar:PIhandle):cint =
  let
    canvas = GetDialogChild(item_statusbar, "CANVAS")
    statusbar = GetBrother(canvas)
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))

  toggle_bar_visibility(item_statusbar, statusbar)

  ConfigSetVariableStr(config, "MainWindow", "Statusbar", GetAttribute(item_statusbar, "VALUE"))
  return IUP_DEFAULT

proc item_help_action_cb():cint =
  Help("http://www.tecgraf.puc-rio.br/")
  return IUP_DEFAULT

proc item_about_action_cb():cint =
  Message("About", "   Simple Paint\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return IUP_DEFAULT

#********************************** Main *****************************************

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, canvas, menu:PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert:PIhandle
    sub_menu_edit, edit_menu, item_copy, item_paste:PIhandle
    btn_copy, btn_paste, btn_new, btn_open, btn_save:PIhandle
    sub_menu_help, help_menu, item_help, item_about:PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar:PIhandle
    statusbar, toolbar, recent_menu:PIhandle

  canvas = Canvas(nil)
  SetAttribute(canvas, "NAME", "CANVAS")
  SetAttribute(canvas, "DIRTY", "NO")
  # TODO: SetCallback(canvas, "ACTION", cast[Icallback](canvas_action_cb)
  SetCallback(canvas, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  statusbar = Label("(0, 0) = [0   0   0]")
  SetAttribute(statusbar, "NAME", "STATUSBAR")
  SetAttribute(statusbar, "EXPAND", "HORIZONTAL")
  SetAttribute(statusbar, "PADDING", "10x5")

  item_new = Item("&New\tCtrl+N", nil)
  SetAttribute(item_new, "IMAGE", "IUP_FileNew")
  SetCallback(item_new, "ACTION", cast[Icallback](item_new_action_cb))
  btn_new = Button(nil, nil)
  SetAttribute(btn_new, "IMAGE", "IUP_FileNew")
  SetAttribute(btn_new, "FLAT", "Yes")
  SetCallback(btn_new, "ACTION", cast[Icallback](item_new_action_cb))
  SetAttribute(btn_new, "TIP", "New (Ctrl+N)")
  SetAttribute(btn_new, "CANFOCUS", "No")

  item_open = Item("&Open...\tCtrl+O", nil)
  SetAttribute(item_open, "IMAGE", "IUP_FileOpen")
  SetCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = Button(nil, nil)
  SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  SetAttribute(btn_open, "FLAT", "Yes")
  SetCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  SetAttribute(btn_open, "CANFOCUS", "No")

  item_save = Item("&Save\tCtrl+S", nil)
  SetAttribute(item_save, "NAME", "ITEM_SAVE")
  SetAttribute(item_save, "IMAGE", "IUP_FileSave")
  SetCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = Button(nil, nil)
  SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  SetAttribute(btn_save, "FLAT", "Yes")
  SetCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  SetAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = Item("Save &As...", nil)
  SetAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  SetCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = Item("&Revert", nil)
  SetAttribute(item_revert, "NAME", "ITEM_REVERT")
  SetCallback(item_revert, "ACTION", cast[Icallback](item_revert_action_cb))

  item_exit = Item("E&xit", nil)
  SetCallback(item_exit, "ACTION", cast[Icallback](item_exit_action_cb))

  item_copy = Item("&Copy\tCtrl+C", nil)
  SetAttribute(item_copy, "NAME", "ITEM_COPY")
  SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  SetCallback(item_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  btn_copy = Button(nil, nil)
  SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  SetAttribute(btn_copy, "FLAT", "Yes")
  SetCallback(btn_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  SetAttribute(btn_copy, "CANFOCUS", "No")

  item_paste = Item("&Paste\tCtrl+V", nil)
  SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  SetCallback(item_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  btn_paste = Button(nil, nil)
  SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  SetAttribute(btn_paste, "FLAT", "Yes")
  SetCallback(btn_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  SetAttribute(btn_paste, "CANFOCUS", "No")

  item_toolbar = Item("&Toobar", nil)
  SetCallback(item_toolbar, "ACTION", cast[Icallback](item_toolbar_action_cb))
  SetAttribute(item_toolbar, "VALUE", "ON")

  item_statusbar = Item("&Statusbar", nil)
  SetCallback(item_statusbar, "ACTION", cast[Icallback](item_statusbar_action_cb))
  SetAttribute(item_statusbar, "VALUE", "ON")

  item_help = Item("&Help...", nil)
  SetCallback(item_help, "ACTION", cast[Icallback](item_help_action_cb))

  item_about = Item("&About...", nil)
  SetCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

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
    item_copy,
    item_paste,
    nil)
  view_menu = Menu(
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = Menu(
    item_help,
    item_about,
    nil)

  SetCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  SetCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

  sub_menu_file = Submenu("&File", file_menu)
  sub_menu_edit = Submenu("&Edit", edit_menu)
  sub_menu_view = Submenu("&View", view_menu)
  sub_menu_help = Submenu("&Help", help_menu)

  menu = Menu(
    sub_menu_file,
    sub_menu_edit,
    sub_menu_view,
    sub_menu_help,
    nil)

  toolbar = Hbox(
    btn_new,
    btn_open,
    btn_save,
    SetAttributes(Label(nil), "SEPARATOR=VERTICAL"),
    btn_copy,
    btn_paste,
    nil)
  SetAttribute(toolbar, "MARGIN", "5x5")
  SetAttribute(toolbar, "GAP", "2")

  vbox = Vbox(
    toolbar,
    canvas,
    statusbar,
    nil)

  dlg = Dialog(vbox)
  SetAttributeHandle(dlg, "MENU", menu)
  SetAttribute(dlg, "SIZE", "HALFxHALF")
  SetCallback(dlg, "CLOSE_CB", cast[Icallback](item_exit_action_cb))
  SetCallback(dlg, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  SetCallback(dlg, "K_cN", cast[Icallback](item_new_action_cb))
  SetCallback(dlg, "K_cO", cast[Icallback](item_open_action_cb))
  SetCallback(dlg, "K_cS", cast[Icallback](item_save_action_cb))
  SetCallback(dlg, "K_cV", cast[Icallback](item_paste_action_cb))
  SetCallback(dlg, "K_cC", cast[Icallback](item_copy_action_cb))

  # parent for pre-defined dialogs in closed functions (Message and IupAlarm)
  SetAttributeHandle(nil, "PARENTDIALOG", dlg)

  # Initialize variables from the configuration file

  ConfigRecentInit(config, recent_menu, cast[Icallback](config_recent_cb), 10)

  if ConfigGetVariableIntDef(config, "MainWindow", "Toolbar", 1) == 0:
    SetAttribute(item_toolbar, "VALUE", "OFF")
    SetAttribute(toolbar, "FLOATING", "YES")
    SetAttribute(toolbar, "VISIBLE", "NO")

  if ConfigGetVariableIntDef(config, "MainWindow", "Statusbar", 1) == 0:
    SetAttribute(item_statusbar, "VALUE", "OFF")

    SetAttribute(statusbar, "FLOATING", "YES")
    SetAttribute(statusbar, "VISIBLE", "NO")

  SetAttribute(dlg, "CONFIG", cast[cstring](config))

  return dlg

proc mainProc =
  var dlg, config: PIhandle

  niupext.Open()
  niupc.ImageLibOpen()

  niupext.InitConfig(config, "simple_paint")

  dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  niupc.ConfigDialogShow(config, dlg, "MainWindow")

  # open a file from the command line (allow file association in Windows)
  if paramCount() > 1 and paramStr(1) != "":
    let filename = paramStr(1)
    open_file(dlg, filename)

  # initialize the current file, if not already loaded
  check_new_file(dlg);

  MainLoop()

  niupc.Close()

if isMainModule:
  mainProc()
