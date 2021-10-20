import niup
import niupext

proc load_medal_images()=
  let
    img_gold =
      [
      0'u8,0,0,4,4,4,4,4,4,4,4,4,4,0,0,0,
      0,0,4,4,4,4,4,4,4,4,4,4,4,4,0,0,
      0,0,4,4,4,4,4,4,4,4,4,4,4,4,0,0,
      0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,
      0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,
      0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,
      0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,
      0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,
      0,3,4,4,2,4,4,4,4,4,2,2,4,4,3,0,
      2,0,2,2,2,2,2,2,2,2,2,2,2,2,0,2,
      0,0,3,3,2,2,2,1,1,2,2,2,1,3,3,0,
      0,1,1,1,3,2,1,1,1,1,2,3,3,3,3,0,
      3,3,1,1,1,3,3,3,1,3,3,1,1,1,1,1,
      3,3,1,1,1,1,1,3,3,1,1,1,1,1,1,1,
      0,0,0,0,3,1,1,0,0,1,1,1,0,0,0,0,
      0,0,0,0,0,3,3,0,0,1,1,3,0,0,0,0
      ]

    img_silver =
      [
      0'u8,0,0,3,3,3,3,3,3,3,3,3,3,0,0,0,
      0,0,4,3,3,3,3,3,3,3,3,3,3,4,0,0,
      0,0,3,3,3,3,3,3,3,3,3,3,3,3,0,0,
      0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,
      0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,
      0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,
      0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,
      0,3,3,3,3,3,3,3,3,3,3,3,3,3,3,0,
      0,3,3,3,3,3,3,3,3,3,3,2,3,3,3,0,
      3,0,2,2,2,2,2,3,3,2,2,2,2,2,0,3,
      0,0,1,1,2,2,1,1,1,2,2,2,1,1,3,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
      2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,
      0,0,0,0,2,1,1,0,0,0,1,1,0,0,0,0,
      0,0,0,0,0,1,1,0,0,1,1,2,0,0,0,0
      ]

    img_bronze =
      [
      0'u8,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,
      0,0,4,1,1,1,1,1,1,1,1,1,1,4,0,0,
      0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,
      0,1,1,1,3,3,1,1,1,1,3,3,1,1,1,0,
      4,0,3,3,3,3,3,3,3,3,3,3,3,2,0,4,
      0,0,3,3,3,3,2,2,2,2,3,2,2,3,4,0,
      0,2,2,2,2,3,2,2,2,2,2,2,2,2,3,0,
      4,3,2,2,2,2,2,2,2,2,2,2,2,2,2,3,
      4,3,2,2,2,2,2,2,4,2,2,2,2,2,2,3,
      0,0,0,0,3,2,2,0,0,2,2,2,0,0,0,0,
      0,0,0,0,0,3,3,0,0,2,2,4,0,0,0,0
      ]

  let image_gold = Image(16, 16, cast[ptr uint8](unsafeAddr(img_gold)))
  SetAttribute(image_gold, "0", "BGCOLOR")
  SetAttribute(image_gold, "1", "128 0 0")
  SetAttribute(image_gold, "2", "128 128 0")
  SetAttribute(image_gold, "3", "255 0 0")
  SetAttribute(image_gold, "4", "255 255 0")
  SetHandle("IMGGOLD", image_gold)

  let image_silver = Image(16, 16, cast[ptr uint8](unsafeAddr(img_silver)))
  SetAttribute(image_silver, "0", "BGCOLOR")
  SetAttribute(image_silver, "1", "0 128 128")
  SetAttribute(image_silver, "2", "128 128 128")
  SetAttribute(image_silver, "3", "192 192 192")
  SetAttribute(image_silver, "4", "255 255 255")
  SetHandle("IMGSILVER", image_silver)

  let image_bronze = Image(16, 16, cast[ptr uint8](unsafeAddr(img_bronze)))
  SetAttribute(image_bronze, "0", "BGCOLOR")
  SetAttribute(image_bronze, "1", "128 0 0")
  SetAttribute(image_bronze, "2", "0 128 0")
  SetAttribute(image_bronze, "3", "128 128 0")
  SetAttribute(image_bronze, "4", "128 128 128")
  SetHandle("IMGBRONZE", image_bronze)

proc mainProc =
  niupext.Open()
  ImageLibOpen()

  var
    dlg:PIhandle
    list1, list2:PIhandle
    frm_medal1, frm_medal2:PIhandle

  list1 = List (nil)
  SetAttributes(list1, "1=Gold, 2=Silver, 3=Bronze, 4=Brass, 5=None, SHOWIMAGE=YES, DRAGDROPLIST=YES, XXX_SPACING=4, VALUE=4")
  load_medal_images()
  SetAttribute(list1, "IMAGE1", "IMGGOLD")
  SetAttribute(list1, "IMAGE2", "IMGSILVER")
  SetAttribute(list1, "IMAGE3", "IMGBRONZE")
  #SetAttribute(list1, "MULTIPLE", "YES")
  SetAttribute(list1, "DRAGSOURCE", "YES")
  #SetAttribute(list1, "DRAGSOURCEMOVE", "YES")
  SetAttribute(list1, "DRAGTYPES", "ITEMLIST")
  
  frm_medal1 = Frame(list1)
  SetAttribute(frm_medal1, "TITLE", "List 1")
  
  list2 = List (nil)
  SetAttributes(list2, "1=Apple, 2=Plum, 3=Pear, 4=Lime, 5=Mango, 6=Coco, SHOWIMAGE=YES, DRAGDROPLIST=YES, XXX_SPACING=4, VALUE=4")
  SetAttribute(list2, "DROPTARGET", "YES")
  SetAttribute(list2, "DROPTYPES", "ITEMLIST")
  frm_medal2 = Frame (list2)
  SetAttribute(frm_medal2, "TITLE", "List 2")
  
  dlg = Dialog(Hbox(frm_medal1, frm_medal2, nil))
  SetAttribute(dlg, "TITLE", "List Example")
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  MainLoop()
  Close()

if isMainModule:
  mainProc()
