import niup
import strformat

proc quit_cb(ih: PIhandle): cint {.cdecl.} =
  return IUP_CLOSE

proc resize_cb(ih: PIhandle, w, h: cint): cint {.cdecl.} =
  let
    dialog = Dialog_t(ih)
    image = ImageRGBA_t(GetAttributeHandle(dialog, "SHAPEIMAGE"))
  image.resize = &"{w}x{h}"
  dialog["SHAPEIMAGE"] = nil
  dialog.shapeimage = image
  return IUP_DEFAULT

proc Main() =
  Open()

  let image = ImageRGBA_t(LoadImage("balloon.png"))

  #/* Creating the button */
  let quit_bt = Button("Quit")
  quit_bt.action = quit_cb

  let flabel = FlatLabel("Very Long Text Label")
  # SetAttributes returns PIhandle, if used inline, as nested call,
  #   it will have to ba casted to FlatLabel_t or similar NIUP type
  SetAttributes(flabel, "EXPAND=YES, ALIGNMENT=ACENTER, FONTSIZE=24")

  #/* the container with a label and the button */
  let vbox = Vbox(
               flabel,
               quit_bt)
  vbox.alignment = "ACENTER"
  vbox.margin(200, 200)
  vbox.gap = 5

  let bgbox = BackgroundBox(vbox)
  bgbox.rastersize = "804x644"
  #//  IupSetAttribute(vbox, "BACKCOLOR", "255 255 255");
  bgbox.bgcolor = "255 255 255"
  bgbox.backimage = image

  #/* Creating the dialog */
  let dialog = Dialog(bgbox)
  dialog.defaultesc = quit_bt
  #//  IupSetCallback(dialog, "RESIZE_CB", (Icallback)resize_cb);

  dialog.border = "NO"
  dialog.resize = "NO"
  dialog.minbox = "NO"
  dialog.maxbox = "NO"
  dialog.menubox = "NO"
  dialog.shapeimage = image
  #//  IupSetAttributeHandle(dialog, "OPACITYIMAGE", image);
  #//  IupSetAttribute(dialog, "OPACITY", "128");

  Show(dialog)

  MainLoop()
  
  Destroy(dialog)
  Close()


if isMainModule:
  Main()
