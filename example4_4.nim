# https://www.tecgraf.puc-rio.br/iup/en/tutorial/tutorial4.html
# https://www.tecgraf.puc-rio.br/iup/examples/tutorial/example4_4.c

import niup
import niupext
import strformat
import unicode
import os
import strscans
import math

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
  discard Popup(dlg, IUP_CENTERPARENT, IUP_CENTERPARENT)
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

  return image

proc write_file(filename:cstring, image:ptr imImage):bool =
  let
    format = imImageGetAttribString(image, "FileFormat")
    error = imFileImageSave(filename, format, image)
  if error != IM_ERR_NONE:
    show_file_error(error)
    return false
  return true

# extracted from the SCROLLBAR attribute documentation
proc scroll_update(ih:PIhandle, view_width:int, view_height:int) =
  # view_width and view_height is the virtual space size
  # here we assume XMIN=0, XMAX=1, YMIN=0, YMAX=1
  var
    elem_width, elem_height:cint
    canvas_width, canvas_height:int
  let
    scrollbar_size = GetInt(nil, "SCROLLBARSIZE")
    border = GetInt(ih, "BORDER")

  discard GetIntInt(ih, "RASTERSIZE", elem_width, elem_height)

  # if view is greater than canvas in one direction,
  # then it has scrollbars,
  # but this affects the opposite direction
  elem_width -= 2 * border  # remove BORDER (always size=1)
  elem_height -= 2 * border
  canvas_width = elem_width
  canvas_height = elem_height
  if view_width > elem_width:  # check for horizontal scrollbar
    canvas_height -= scrollbar_size  # affect vertical size
  if view_height > elem_height:
    canvas_width -= scrollbar_size
  if view_width <= elem_width and view_width > canvas_width:  # check if still has horizontal scrollbar
    canvas_height -= scrollbar_size
  if view_height <= elem_height and view_height > canvas_height:
    canvas_width -= scrollbar_size
  if canvas_width < 0:
    canvas_width = 0
  if canvas_height < 0:
    canvas_height = 0

  SetFloat(ih, "DX", canvas_width.float / view_width.float)
  SetFloat(ih, "DY", canvas_height.float / view_height.float)

proc scroll_calc_center(ih:PIhandle, x,y:var cfloat) =
  x = GetFloat(ih, "POSX") + GetFloat(ih, "DX") / 2.0f
  y = GetFloat(ih, "POSY") + GetFloat(ih, "DY") / 2.0f

proc scroll_center(ih:PIhandle, old_center_x:float, old_center_y:float) =
  # always update the scroll position
  #   keeping it proportional to the old position
  #   relative to the center of the ih.

  let
    dx = GetFloat(ih, "DX")
    dy = GetFloat(ih, "DY")

  var
    posx = old_center_x - dx / 2.0f
    posy = old_center_y - dy / 2.0f

  if posx < 0:
    posx = 0
  if posx > (1 - dx):
    posx = 1 - dx

  if posy < 0:
    posy = 0
  if posy > (1 - dy):
    posy = 1 - dy

  SetFloat(ih, "POSX", posx)
  SetFloat(ih, "POSY", posy)

proc zoom_update(ih:PIhandle, zoom_index:cdouble) =
  let
    zoom_lbl = GetDialogChild(ih, "ZOOMLABEL")
    canvas = GetDialogChild(ih, "CANVAS")
    image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
    zoom_factor = pow(2, zoom_index)

  SetStrf(zoom_lbl, "TITLE", "%.0f%%", floor(zoom_factor * 100))
  if image != nil:
    var old_center_x, old_center_y:cfloat
    let
      view_width = (zoom_factor * image.width.float).int
      view_height = (zoom_factor * image.height.float).int

    scroll_calc_center(canvas, old_center_x, old_center_y)

    scroll_update(canvas, view_width, view_height)

    scroll_center(canvas, old_center_x, old_center_y)

  Update(canvas)

proc set_new_image(canvas:PIhandle, image:var ptr imImage, filename:string, dirty:bool) =
  let old_image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  let
    size_lbl = GetDialogChild(canvas, "SIZELABEL")
    zoom_val = GetDialogChild(canvas, "ZOOMVAL")

  if filename != "":
    SetStrAttribute(canvas, "FILENAME", filename)
    SetfAttribute(GetDialog(canvas), "TITLE", "%s - Simple Paint", os.extractFilename(filename))
  else:
    SetAttribute(canvas, "FILENAME", nil)
    SetAttribute(GetDialog(canvas), "TITLE", "Untitled - Simple Paint")

  # we are going to support only RGB images with no alpha
  imImageRemoveAlpha(image)
  if image.color_space != IM_RGB:
    let new_image = imImageCreateBased(image, -1, -1, IM_RGB, cast[imDataType](-1))
    discard imConvertColorSpace(image, new_image)
    imImageDestroy(image)

    image = new_image

  # default file format
  let format = imImageGetAttribString(image, "FileFormat")
  if format != "":
    imImageSetAttribString(image, "FileFormat", "JPEG")

  if dirty:
    SetAttribute(canvas, "DIRTY", "Yes")
  else:
    SetAttribute(canvas, "DIRTY", "No")

  SetAttribute(canvas, "IMAGE", cast[cstring](image))

  SetfAttribute(size_lbl, "TITLE", "%d x %d px", image.width, image.height)

  if old_image != nil:
    imImageDestroy(old_image)

  SetDouble(zoom_val, "VALUE", 0)
  zoom_update(canvas, 0)

proc check_new_file(dlg:PIhandle) =
  let canvas = GetDialogChild(dlg, "CANVAS")
  var image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

  if image != nil:
    let
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
      width = ConfigGetVariableIntDef(config, "NewImage", "Width", 640)
      height = ConfigGetVariableIntDef(config, "NewImage", "Height", 480)

    image = imImageCreate(width, height, IM_RGB, IM_BYTE)

    set_new_image(canvas, image, "", false)

proc open_file(ih:PIhandle, filename:string) =
  var image = read_file(filename)
  if image != nil:
    let
      canvas = GetDialogChild(ih, "CANVAS")
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
      old_image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))

    set_new_image(canvas, image, filename, false)

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

proc select_file(parent_dlg:PIhandle, is_open:bool):int =
  let
    config = cast[PIhandle](GetAttribute(parent_dlg, "CONFIG"))
    canvas = GetDialogChild(parent_dlg, "CANVAS")
    filedlg = FileDlg()

  var dir = ConfigGetVariableStr(config, "MainWindow", "LastDirectory")

  if is_open:
    SetAttribute(filedlg, "DIALOGTYPE", "OPEN")
  else:
    SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
    SetStrAttribute(filedlg, "FILE", GetAttribute(canvas, "FILENAME"))

  SetAttribute(filedlg, "EXTFILTER", "Image Files|*.bmp;*.jpg;*.png;*.tif;*.tga|All Files|*.*|")
  SetStrAttribute(filedlg, "DIRECTORY", dir)
  SetAttributeHandle(filedlg, "PARENTDIALOG", parent_dlg)

  discard Popup(filedlg, IUP_CENTERPARENT, IUP_CENTERPARENT)
  if GetInt(filedlg, "STATUS") != -1:
    let filename = GetAttribute(filedlg, "VALUE")
    if is_open:
      open_file(parent_dlg, $filename)
    else:
      saveas_file(canvas, $filename)

    dir = GetAttribute(filedlg, "DIRECTORY")
    ConfigSetVariableStr(config, "MainWindow", "LastDirectory", dir)

  Destroy(filedlg)
  return IUP_DEFAULT

proc view_fit_rect(canvas_width, canvas_height, image_width, image_height:int, view_width, view_height:var ptr int) =
  view_width[] = canvas_width
  view_height[] = ((canvas_width * image_height) / image_width).int

  if view_height[] > canvas_height:
    view_height[] = canvas_height
    view_width[] = ((canvas_height * image_width) / image_height).int

#/********************************** Callbacks *****************************************/

proc canvas_action_cb(canvas:PIhandle):cint =
  var
    x, y, canvas_width, canvas_height:cint
    ri, gi, bi:int
  let
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
    background = ConfigGetVariableStrDef(config, "Canvas", "Background", "255 255 255")
    cd_canvas = cast[ptr cdCanvas](GetAttribute(canvas, "cdCanvas"))

  discard GetIntInt(canvas, "DRAWSIZE", canvas_width, canvas_height)

  discard cdCanvasActivate(cd_canvas)

  # draw the background
  discard scanf($background, "$i $i $i", ri, gi, bi)
  discard cdCanvasBackground(cd_canvas, cdEncodeColor(ri.cuchar, gi.cuchar, bi.cuchar))
  cdCanvasClear(cd_canvas)

  # draw the image at the center of the canvas
  let image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
  if image != nil:
    var
      view_width, view_height:cint
      posy = GetFloat(canvas, "POSY")
      posx = GetFloat(canvas, "POSX")

    let
      zoom_val = GetDialogChild(canvas, "ZOOMVAL")
      zoom_index = GetDouble(zoom_val, "VALUE")
      zoom_factor = pow(2, zoom_index)

    view_width = (zoom_factor * image.width.float).cint
    view_height = (zoom_factor * image.height.float).cint

    if canvas_width < view_width:
      x = cint(floor(-posx*view_width.float))
    else:
      x = cint((canvas_width - image.width) / 2)

    if canvas_height < view_height:
      # posy is top-bottom, CD is bottom-top.
      # invert posy reference (YMAX-DY - POSY)
      let dy = GetFloat(canvas, "DY")
      posy = 1.0f - dy - posy
      y = cint(floor(-posy*view_height.float))
    else:
      y = cint((canvas_height - image.height) / 2)

    # black line around the image
    discard cdCanvasForeground(cd_canvas, CD_BLACK)
    cdCanvasRect(cd_canvas, x - 1, x + view_width, y - 1, y + view_height)

    imcdCanvasPutImage(cd_canvas, image, x, y, view_width, view_height, 0, 0, 0, 0)

  cdCanvasFlush(cd_canvas)
  return IUP_DEFAULT

proc canvas_map_cb(canvas:PIhandle):cint =
  let cd_canvas = cdCreateCanvas(cdContextIupDBuffer(), canvas)
  SetAttribute(canvas, "cdCanvas", cast[cstring](cd_canvas))
  return IUP_DEFAULT

proc canvas_unmap_cb(canvas:PIhandle):cint =
  let cd_canvas = cast[ptr cdCanvas](GetAttribute(canvas, "cdCanvas"))
  cdKillCanvas(cd_canvas)
  return IUP_DEFAULT

proc zoomout_action_cb(ih:PIhandle):int =
  let zoom_val = GetDialogChild(ih, "ZOOMVAL")
  var zoom_index = GetDouble(zoom_val, "VALUE")
  zoom_index = zoom_index - 1
  if zoom_index < -6:
    zoom_index = -6
  SetDouble(zoom_val, "VALUE", round(zoom_index))  # fixed increments when using buttons

  zoom_update(ih, zoom_index)
  return IUP_DEFAULT

proc zoomin_action_cb(ih:PIhandle):int =
  let zoom_val = GetDialogChild(ih, "ZOOMVAL")
  var zoom_index = GetDouble(zoom_val, "VALUE")
  zoom_index = zoom_index + 1
  if zoom_index > 6:
    zoom_index = 6
  SetDouble(zoom_val, "VALUE", round(zoom_index))  # fixed increments when using buttons

  zoom_update(ih, zoom_index)
  return IUP_DEFAULT

proc actualsize_action_cb(ih:PIhandle):int =
  let zoom_val = GetDialogChild(ih, "ZOOMVAL")
  SetDouble(zoom_val, "VALUE", 0)
  zoom_update(ih, 0)
  return IUP_DEFAULT

proc canvas_resize_cb(canvas:PIhandle):int =
  let image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
  if image != nil:
    let
      zoom_val = GetDialogChild(canvas, "ZOOMVAL")
      zoom_index = GetDouble(zoom_val, "VALUE")
      zoom_factor = pow(2, zoom_index)
    var
      old_center_x, old_center_y:cfloat

    let
      view_width = (zoom_factor * image.width.float).cint
      view_height = (zoom_factor * image.height.float).cint

    scroll_calc_center(canvas, old_center_x, old_center_y)

    scroll_update(canvas, view_width, view_height)

    scroll_center(canvas, old_center_x, old_center_y)

  return IUP_DEFAULT

proc canvas_wheel_cb(canvas:PIhandle, delta:cfloat):int =
  if GetInt(nil, "CONTROLKEY") > 0:
    if delta < 0:
      discard zoomout_action_cb(canvas)
    else:
      discard zoomin_action_cb(canvas)
  else:
    var posy = GetFloat(canvas, "POSY")
    posy = posy - delta * GetFloat(canvas, "DY") / 10.0f
    SetFloat(canvas, "POSY", posy)
    Update(canvas)

  return IUP_DEFAULT

proc zoom_valuechanged_cb(val:PIhandle):int =
  let zoom_index = GetDouble(val, "VALUE")
  zoom_update(val, zoom_index)
  return IUP_DEFAULT

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
      var image = imImageCreate(width, height, IM_RGB, IM_BYTE)

      ConfigSetVariableInt(config, "NewImage", "Width", width)
      ConfigSetVariableInt(config, "NewImage", "Height", height)

      set_new_image(canvas, image, "", false)

  return IUP_DEFAULT

proc item_open_action_cb(item_open:PIhandle):int =
  if not save_check(item_open):
    return IUP_DEFAULT

  return select_file(GetDialog(item_open), true)

proc item_saveas_action_cb(item_saveas:PIhandle):int =
  return select_file(GetDialog(item_saveas), false)

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

proc item_pagesetup_action_cb(item_pagesetup:PIhandle):cint =
  let
    canvas = GetDialogChild(item_pagesetup, "CANVAS")
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
  var
    margin_width = ConfigGetVariableIntDef(config, "Print", "MarginWidth", 20)
    margin_height = ConfigGetVariableIntDef(config, "Print", "MarginHeight", 20)

  if GetParam("Page Setup", nil, nil, "Margin Width (mm): %i[1,]\nMargin Height (mm): %i[1,]\n", margin_width, margin_height, nil) > 0:
    ConfigSetVariableInt(config, "Print", "MarginWidth", margin_width)
    ConfigSetVariableInt(config, "Print", "MarginHeight", margin_height)

  return IUP_DEFAULT

proc item_print_action_cb(item_print:PIhandle):cint =
  let
    canvas = GetDialogChild(item_print, "CANVAS")
    title = GetAttribute(GetDialog(item_print), "TITLE")
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
    background = ConfigGetVariableStrDef(config, "Canvas", "Background", "255 255 255")
    cd_canvas = cdCreateCanvasf(cdContextPrinter(), "%s -d", title)
  var
    ri, gi, bi:int

  if cd_canvas == nil:
    return IUP_DEFAULT

  # draw the background
  discard scanf($background, "$i $i $i", ri, gi, bi)
  discard cdCanvasBackground(cd_canvas, cdEncodeColor(ri.cuchar, gi.cuchar, bi.cuchar))
  cdCanvasClear(cd_canvas)

  # draw the image at the center of the canvas
  let image = cast[ptr imImage](GetAttribute(canvas, "IMAGE"))
  if image != nil:
    let
      config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
    var
      x, y, canvas_width, canvas_height:cint
      view_width, view_height:ptr int
      canvas_width_mm, canvas_height_mm:cdouble
      margin_width = ConfigGetVariableIntDef(config, "Print", "MarginWidth", 20).int
      margin_height = ConfigGetVariableIntDef(config, "Print", "MarginHeight", 20).int

    cdCanvasGetSize(cd_canvas, addr canvas_width, addr canvas_height, addr canvas_width_mm, addr canvas_height_mm)

    # convert to pixels
    margin_width = ((margin_width * canvas_width.int) / canvas_width_mm.int).int
    margin_height = ((margin_height * canvas_height.int) / canvas_height_mm.int).int

    view_fit_rect(canvas_width - 2 * margin_width, canvas_height - 2 * margin_height,
                  image.width.int, image.height.int,
                  view_width, view_height)

    x = ((canvas_width - view_width[]) / 2).cint
    y = ((canvas_height - view_height[]) / 2).cint

    imcdCanvasPutImage(cd_canvas, image, x, y, view_width[].cint, view_height[].cint, 0, 0, 0, 0)

  cdKillCanvas(cd_canvas)
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
  discard ConfigSave(config)
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

    set_new_image(canvas, image, "", true)  # set dirty

  return IUP_DEFAULT

proc item_background_action_cb(item_background:PIhandle):cint =
  let
    canvas = GetDialogChild(item_background, "CANVAS")
    config = cast[PIhandle](GetAttribute(canvas, "CONFIG"))
    colordlg = ColorDlg()

  var background = ConfigGetVariableStrDef(config, "Canvas", "Background", "255 255 255")

  SetStrAttribute(colordlg, "VALUE", background)
  SetAttributeHandle(colordlg, "PARENTDIALOG", GetDialog(item_background))

  discard Popup(colordlg, IUP_CENTERPARENT, IUP_CENTERPARENT)

  if GetInt(colordlg, "STATUS") == 1:
    background = GetAttribute(colordlg, "VALUE")
    ConfigSetVariableStr(config, "Canvas", "Background", background)

    Update(canvas)

  Destroy(colordlg)
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
  discard Help("http://www.tecgraf.puc-rio.br/")
  return IUP_DEFAULT

proc item_about_action_cb():cint =
  Message("About", "   Simple Paint\n\nAuthors:\n   Gustavo Lyrio\n   Antonio Scuri")
  return IUP_DEFAULT

#********************************** Main *****************************************

proc create_main_dialog(config:PIhandle):PIhandle =
  var
    dlg, vbox, canvas, menu:PIhandle
    sub_menu_file, file_menu, item_exit, item_new, item_open, item_save, item_saveas, item_revert:PIhandle
    sub_menu_edit, edit_menu, item_copy, item_paste, item_print, item_pagesetup:PIhandle
    btn_copy, btn_paste, btn_new, btn_open, btn_save:PIhandle
    sub_menu_help, help_menu, item_help, item_about:PIhandle
    sub_menu_view, view_menu, item_toolbar, item_statusbar:PIhandle
    item_zoomin, item_zoomout, item_actualsize:PIhandle
    statusbar, toolbar, recent_menu, item_background:PIhandle

  canvas = Canvas(nil)
  SetAttribute(canvas, "NAME", "CANVAS")
  SetAttribute(canvas, "SCROLLBAR", "YES")
  SetAttribute(canvas, "DIRTY", "NO")
  SetAttribute(canvas, "BUFFER", "DOUBLE")
  discard SetCallback(canvas, "ACTION", cast[Icallback](canvas_action_cb))
  discard SetCallback(canvas, "ACTION", cast[Icallback](canvas_action_cb))
  discard SetCallback(canvas, "MAP_CB", cast[Icallback](canvas_map_cb))
  discard SetCallback(canvas, "UNMAP_CB", cast[Icallback](canvas_unmap_cb))

  discard SetCallback(canvas, "WHEEL_CB", cast[Icallback](canvas_wheel_cb))
  discard SetCallback(canvas, "RESIZE_CB", cast[Icallback](canvas_resize_cb))

  statusbar = Hbox(
    SetAttributes(Label("(0, 0) = 0   0   0"), "EXPAND=HORIZONTAL, PADDING=10x5"),
    SetAttributes(Label(nil), "SEPARATOR=VERTICAL"),
    SetAttributes(Label("0 x 0"), "SIZE=70x, PADDING=10x5, NAME=SIZELABEL, ALIGNMENT=ACENTER"),
    SetAttributes(Label(nil), "SEPARATOR=VERTICAL"),
    SetAttributes(Label("100%"), "SIZE=30x, PADDING=10x5, NAME=ZOOMLABEL, ALIGNMENT=ARIGHT"),
    SetCallbacks(SetAttributes(Button(nil, nil), "IMAGE=IUP_ZoomOut, FLAT=Yes, TIP=\"Zoom Out (Ctrl+-)\""), "ACTION", cast[Icallback](zoomout_action_cb), nil),
    SetCallbacks(SetAttributes(Val(nil), "VALUE=0, MIN=-6, MAX=6, RASTERSIZE=150x25, NAME=ZOOMVAL"), "VALUECHANGED_CB", cast[Icallback](zoom_valuechanged_cb), nil),
    SetCallbacks(SetAttributes(Button(nil, nil), "IMAGE=IUP_ZoomIn, FLAT=Yes, TIP=\"Zoom In (Ctrl++)\""), "ACTION", cast[Icallback](zoomin_action_cb), nil),
    SetCallbacks(SetAttributes(Button(nil, nil), "IMAGE=IUP_ZoomActualSize, FLAT=Yes, TIP=\"Actual Size (Ctrl+0)\""), "ACTION", cast[Icallback](actualsize_action_cb), nil),
    nil)
  SetAttribute(statusbar, "NAME", "STATUSBAR")

  SetAttribute(statusbar, "ALIGNMENT", "ACENTER")

  item_new = Item("&New\tCtrl+N", nil)
  SetAttribute(item_new, "IMAGE", "IUP_FileNew")
  discard SetCallback(item_new, "ACTION", cast[Icallback](item_new_action_cb))
  btn_new = Button(nil, nil)
  SetAttribute(btn_new, "IMAGE", "IUP_FileNew")
  SetAttribute(btn_new, "FLAT", "Yes")
  discard SetCallback(btn_new, "ACTION", cast[Icallback](item_new_action_cb))
  SetAttribute(btn_new, "TIP", "New (Ctrl+N)")
  SetAttribute(btn_new, "CANFOCUS", "No")

  item_open = Item("&Open...\tCtrl+O", nil)
  SetAttribute(item_open, "IMAGE", "IUP_FileOpen")
  discard SetCallback(item_open, "ACTION", cast[Icallback](item_open_action_cb))
  btn_open = Button(nil, nil)
  SetAttribute(btn_open, "IMAGE", "IUP_FileOpen")
  SetAttribute(btn_open, "FLAT", "Yes")
  discard SetCallback(btn_open, "ACTION", cast[Icallback](item_open_action_cb))
  SetAttribute(btn_open, "TIP", "Open (Ctrl+O)")
  SetAttribute(btn_open, "CANFOCUS", "No")

  item_save = Item("&Save\tCtrl+S", nil)
  SetAttribute(item_save, "NAME", "ITEM_SAVE")
  SetAttribute(item_save, "IMAGE", "IUP_FileSave")
  discard SetCallback(item_save, "ACTION", cast[Icallback](item_save_action_cb))
  btn_save = Button(nil, nil)
  SetAttribute(btn_save, "IMAGE", "IUP_FileSave")
  SetAttribute(btn_save, "FLAT", "Yes")
  discard SetCallback(btn_save, "ACTION", cast[Icallback](item_save_action_cb))
  SetAttribute(btn_save, "TIP", "Save (Ctrl+S)")
  SetAttribute(btn_save, "CANFOCUS", "No")

  item_saveas = Item("Save &As...", nil)
  SetAttribute(item_saveas, "NAME", "ITEM_SAVEAS")
  discard SetCallback(item_saveas, "ACTION", cast[Icallback](item_saveas_action_cb))

  item_revert = Item("&Revert", nil)
  SetAttribute(item_revert, "NAME", "ITEM_REVERT")
  discard SetCallback(item_revert, "ACTION", cast[Icallback](item_revert_action_cb))

  item_pagesetup = Item("Page Set&up...", nil)
  discard SetCallback(item_pagesetup, "ACTION", cast[Icallback](item_pagesetup_action_cb))

  item_print = Item("&Print...\tCtrl+P", nil)
  discard SetCallback(item_print, "ACTION", cast[Icallback](item_print_action_cb))

  item_exit = Item("E&xit", nil)
  discard SetCallback(item_exit, "ACTION", cast[Icallback](item_exit_action_cb))

  item_copy = Item("&Copy\tCtrl+C", nil)
  SetAttribute(item_copy, "NAME", "ITEM_COPY")
  SetAttribute(item_copy, "IMAGE", "IUP_EditCopy")
  discard SetCallback(item_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  btn_copy = Button(nil, nil)
  SetAttribute(btn_copy, "IMAGE", "IUP_EditCopy")
  SetAttribute(btn_copy, "FLAT", "Yes")
  discard SetCallback(btn_copy, "ACTION", cast[Icallback](item_copy_action_cb))
  SetAttribute(btn_copy, "TIP", "Copy (Ctrl+C)")
  SetAttribute(btn_copy, "CANFOCUS", "No")

  item_paste = Item("&Paste\tCtrl+V", nil)
  SetAttribute(item_paste, "NAME", "ITEM_PASTE")
  SetAttribute(item_paste, "IMAGE", "IUP_EditPaste")
  discard SetCallback(item_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  btn_paste = Button(nil, nil)
  SetAttribute(btn_paste, "IMAGE", "IUP_EditPaste")
  SetAttribute(btn_paste, "FLAT", "Yes")
  discard SetCallback(btn_paste, "ACTION", cast[Icallback](item_paste_action_cb))
  SetAttribute(btn_paste, "TIP", "Paste (Ctrl+V)")
  SetAttribute(btn_paste, "CANFOCUS", "No")

  item_zoomin = Item("Zoom &In\tCtrl++", nil)
  SetAttribute(item_zoomin, "IMAGE", "_ZoomIn")
  discard SetCallback(item_zoomin, "ACTION", cast[Icallback](zoomin_action_cb))

  item_zoomout = Item("Zoom &Out\tCtrl+-", nil)
  SetAttribute(item_zoomout, "IMAGE", "_ZoomOut")
  discard SetCallback(item_zoomout, "ACTION", cast[Icallback](zoomout_action_cb))

  item_actualsize = Item("&Actual Size\tCtrl+0", nil)
  SetAttribute(item_actualsize, "IMAGE", "_ZoomActualSize")
  discard SetCallback(item_actualsize, "ACTION", cast[Icallback](actualsize_action_cb))

  item_background = Item("&Background...", nil);
  discard SetCallback(item_background, "ACTION", cast[Icallback](item_background_action_cb))

  item_toolbar = Item("&Toobar", nil)
  discard SetCallback(item_toolbar, "ACTION", cast[Icallback](item_toolbar_action_cb))
  SetAttribute(item_toolbar, "VALUE", "ON")

  item_statusbar = Item("&Statusbar", nil)
  discard SetCallback(item_statusbar, "ACTION", cast[Icallback](item_statusbar_action_cb))
  SetAttribute(item_statusbar, "VALUE", "ON")

  item_help = Item("&Help...", nil)
  discard SetCallback(item_help, "ACTION", cast[Icallback](item_help_action_cb))

  item_about = Item("&About...", nil)
  discard SetCallback(item_about, "ACTION", cast[Icallback](item_about_action_cb))

  recent_menu = Menu(nil)

  file_menu = Menu(
    item_new,
    item_open,
    item_save,
    item_saveas,
    item_revert,
    Separator(),
    item_pagesetup,
    item_print,
    Separator(),
    Submenu("Recent &Files", recent_menu),
    Separator(),
    item_exit,
    nil)
  edit_menu = Menu(
    item_copy,
    item_paste,
    nil)
  view_menu = Menu(
    item_zoomin,
    item_zoomout,
    item_actualsize,
    Separator(),
    item_background,
    Separator(),
    item_toolbar,
    item_statusbar,
    nil)
  help_menu = Menu(
    item_help,
    item_about,
    nil)

  discard SetCallback(file_menu, "OPEN_CB", cast[Icallback](file_menu_open_cb))
  discard SetCallback(edit_menu, "OPEN_CB", cast[Icallback](edit_menu_open_cb))

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
  discard SetCallback(dlg, "CLOSE_CB", cast[Icallback](item_exit_action_cb))
  discard SetCallback(dlg, "DROPFILES_CB", cast[Icallback](dropfiles_cb))

  discard SetCallback(dlg, "K_cN", cast[Icallback](item_new_action_cb))
  discard SetCallback(dlg, "K_cO", cast[Icallback](item_open_action_cb))
  discard SetCallback(dlg, "K_cS", cast[Icallback](item_save_action_cb))
  discard SetCallback(dlg, "K_cV", cast[Icallback](item_paste_action_cb))
  discard SetCallback(dlg, "K_cC", cast[Icallback](item_copy_action_cb))
  discard SetCallback(dlg, "K_cP", cast[Icallback](item_print_action_cb))
  discard SetCallback(dlg, "K_cMinus", cast[Icallback](zoomout_action_cb))
  discard SetCallback(dlg, "K_cPlus", cast[Icallback](zoomin_action_cb))
  discard SetCallback(dlg, "K_cEqual", cast[Icallback](zoomin_action_cb))
  discard SetCallback(dlg, "K_c0", cast[Icallback](actualsize_action_cb))

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
  ImageLibOpen()

  niupext.InitConfig(config, "simple_paint")

  dlg = create_main_dialog(config)

  # show the dialog at the last position, with the last size
  niup.ConfigDialogShow(config, dlg, "MainWindow")

  # open a file from the command line (allow file association in Windows)
  if paramCount() > 1 and paramStr(1) != "":
    let filename = paramStr(1)
    open_file(dlg, filename)

  # initialize the current file, if not already loaded
  check_new_file(dlg);

  discard niup.MainLoop()

  niup.Close()

if isMainModule:
  mainProc()
