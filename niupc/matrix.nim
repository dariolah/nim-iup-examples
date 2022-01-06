import niup/niupc
import niup/niupext
import strformat

const TEST_IMAGE_SIZE=20

let image_data_32  =
  [
  000'u8,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255, 
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,000,000,255,255,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,255,255,255,192,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,255,
  000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255,000,000,000,255
  ]

proc mousemove_cb(ih:PIhandle, lin, col:int):int =
  echo fmt"mousemove_cb({lin}, {col})\n"
  return IUP_DEFAULT

proc drop(self, drop:PIhandle, lin, col:int):int =
  echo fmt"drop_cb({lin}, {col})\n"
  if lin == 3 and col == 1:
    SetAttribute(drop, "1", "A - Test of Very Big String for Dropdown!")
    SetAttribute(drop, "2", "B")
    SetAttribute(drop, "3", "C")
    SetAttribute(drop, "4", "XXX")
    SetAttribute(drop, "5", "5")
    SetAttribute(drop, "6", "6")
    SetAttribute(drop, "7", "7")
    SetAttribute(drop, "8", nil)
    SetAttribute(drop, "VALUE", "4")
    return IUP_DEFAULT
  return IUP_IGNORE


proc dropcheck_cb(self:PIhandle, lin, col:int):int =
  if lin == 3 and col == 1:
    return IUP_DEFAULT
  if lin == 4 and col == 4:
    return IUP_CONTINUE
  return IUP_IGNORE

proc togglevalue_cb(self:PIhandle, lin, col, value:int):int =
  echo fmt"togglevalue_cb({lin}, {col})={value}\n"
  return IUP_DEFAULT

proc click(self:PIhandle, lin, col:cint):int =
  echo fmt"click_cb({lin}, {col})\n"
  SetAttribute(self,"MARKED", nil)  # clear all marks
  SetAttributeId2(self,"MARK", lin, 0, "1")
  SetfAttribute(self,"REDRAW", "L%d", lin)
  return IUP_DEFAULT

proc enteritem_cb(ih:PIhandle, lin, col:cint):int =
  SetAttribute(ih,"MARKED", nil)  # clear all marks
  SetAttributeId2(ih,"MARK", lin, 0, "1")
  SetfAttribute(ih,"REDRAW", "L%d", lin)
  return IUP_DEFAULT

proc create_matrix():PIhandle =
  let mat = Matrix(nil)
  
  #  IupSetAttribute(mat, "NUMLIN", "3");
  SetAttribute(mat, "NUMLIN", "4")
  SetAttribute(mat, "NUMCOL", "8")
  #  IupSetAttribute(mat, "NUMCOL", "15");
  #  IupSetAttribute(mat, "NUMLIN", "3");
  #  IupSetAttribute(mat, "NUMCOL", "2");
  #  IupSetAttribute(mat, "NUMLIN", "8");
  #  IupSetAttribute(mat, "NUMCOL", "5");
  #  IupSetAttribute(mat, "ACTIVE", "NO");
  #  IupSetAttribute(mat, "EDITHIDEONFOCUS", "NO");
  #  IupSetAttribute(mat, "EDITALIGN", "Yes");
  #  IupSetAttribute(mat, "EDITFITVALUE", "Yes");
  #  IupSetAttribute(mat, "READONLY", "Yes");
  
  #IupSetAttribute(mat, "0:0", "Inflation");
  #IupSetAttribute(mat, "1:0", "Medicine\nPharma");
  #IupSetAttribute(mat, "2:0", "Food");
  #IupSetAttribute(mat, "3:0", "Energy");
  #IupSetAttribute(mat, "0:1", "January 2000");
  #IupSetAttribute(mat, "0:2", "February 2000");
  SetAttribute(mat, "1:1", "5.6\n3.33")
  SetAttribute(mat, "2:1", "2.2")
  SetAttribute(mat, "3:2", "Very Very Very Very Very Large Text")
  SetAttribute(mat, "1:2", "4.5")
  if GetInt(nil, "UTF8MODE") != 0:
    SetAttribute(mat, "2:2", "UTF-8 😁")
  else:
    SetAttribute(mat, "2:2", "NO UTF-8 :(")

  SetAttribute(mat, "3:1", "3.4");
  SetAttribute(mat, "3:3", "Font Test");
  #  IupSetAttribute(mat, "HEIGHT2", "30");
  #  IupSetAttribute(mat, "WIDTH2", "190");
  #  IupSetAttributeId(mat, "WIDTH", 2, "190");
  SetAttribute(mat,"SORTSIGN2","DOWN")
  #  IupSetAttribute(mat, "WIDTHDEF", "34");
  #  IupSetAttribute(mat,"MULTILINE", "YES");
  SetAttribute(mat,"RESIZEMATRIX", "YES")
  #  IupSetAttribute(mat,"HIDDENTEXTMARKS", "YES");
  #  IupSetAttribute(mat,"USETITLESIZE", "YES");
  #IupSetAttribute(mat,"SCROLLBAR", "NO");
  #  IupSetAttribute(mat, "SCROLLBAR", "HORIZONTAL");
  #IupSetAttribute(mat, "BGCOLOR1:2", "255 92 255");
  #IupSetAttribute(mat, "BGCOLOR2:*", "92 92 255");
  #IupSetAttribute(mat, "BGCOLOR*:3", "255 92 92");
  #IupSetAttribute(mat, "FGCOLOR1:2", "255 0 0");
  #IupSetAttribute(mat, "FGCOLOR2:*", "0 128 0");
  #IupSetAttribute(mat, "FGCOLOR*:3", "0 0 255");
  SetAttribute(mat, "FONT3:3", "Helvetica, 24")
  #IupSetAttribute(mat, "FONT2:*", "Courier, 14");
  #IupSetAttribute(mat, "FONT*:3", "Times, Bold 14");
  #  IupSetAttribute(mat, "ALIGNMENT1", "ALEFT");
  #  IupSetAttribute(mat, "ALIGNMENT3", "ARIGHT");
  #  IupSetAttribute(mat, "ALIGN2:1", ":ARIGHT");
  #  IupSetAttribute(mat, "LINEALIGNMENT1", "ATOP");
  #  IupSetAttribute(mat, "ACTIVE", "NO");
  #  IupSetAttribute(mat, "EXPAND", "NO");
  #  IupSetAttribute(mat, "ALIGNMENT", "ALEFT");

  #  IupSetAttribute(mat, "MASK1:3", IUP_MASK_FLOAT);
  #  IupSetAttribute(mat, "MASK1:3", "[a-zA-Z][0-9a-zA-Z_]*");
  #  IupSetAttribute(mat, "MASKFLOAT1:3", "0.0:10.0");
  SetAttribute(mat, "MASK*:3", "[a-zA-Z][0-9a-zA-Z_]*")

  SetAttribute(mat, "TYPE4:1", "COLOR")
  SetAttribute(mat, "4:1", "255 0 128")

  SetAttribute(mat, "TYPE4:2", "FILL")
  SetAttribute(mat, "4:2", "60")
  SetAttribute(mat, "SHOWFILLVALUE", "Yes")

  let p_image_data_32 = cast[ptr uint8](unsafeAddr(image_data_32))
  let image = ImageRGBA(TEST_IMAGE_SIZE, TEST_IMAGE_SIZE, p_image_data_32)
  SetAttribute(mat, "TYPE4:3", "IMAGE")
  SetAttributeHandle(mat, "4:3", image)

  #  IupSetAttribute(mat, "TOGGLEVALUE4:4", "ON");
  #  IupSetAttribute(mat, "VALUE4:4", "1");
  SetAttribute(mat, "TOGGLECENTERED", "Yes")

  SetAttribute(mat,"MARKMODE","CELL");
  #//  IupSetAttribute(mat,"MARKMODE","LIN");
  #//  IupSetAttribute(mat,"MARKMULTIPLE","NO");
  SetAttribute(mat,"MARKMULTIPLE","YES")
  #  IupSetAttribute(mat,"MARKAREA","NOT_CONTINUOUS");
  #  IupSetAttribute(mat,"MARK2:2","YES");
  #  IupSetAttribute(mat,"MARK2:3","YES");
  #  IupSetAttribute(mat,"MARK3:3","YES");

  SetAttribute(mat,"FRAMEVERTCOLOR1:2","BGCOLOR")
  SetAttribute(mat,"FRAMEHORIZCOLOR1:2","0 0 255")
  SetAttribute(mat,"FRAMEHORIZCOLOR1:3","0 255 0")
  SetAttribute(mat,"FRAMEVERTCOLOR2:2","255 255 0")
  SetAttribute(mat,"FRAMEVERTCOLOR*:4","0 255 0")
  SetAttribute(mat,"FRAMEVERTCOLOR*:5","BGCOLOR")

  #  IupSetAttribute(mat,"MARKMODE","LINCOL");

  #IupSetAttribute(mat, "NUMCOL_VISIBLE_LAST", "YES");
  #IupSetAttribute(mat, "NUMLIN_VISIBLE_LAST", "YES");
  #  IupSetAttribute(mat, "WIDTHDEF", "15");
  SetAttribute(mat, "20:8", "The End")
  #IupSetAttribute(mat, "10:0", "Middle Line");
  #IupSetAttribute(mat, "15:0", "Middle Line");
  #IupSetAttribute(mat, "0:4", "Middle Column");
  #IupSetAttribute(mat, "20:0", "Line Title Test");
  #IupSetAttribute(mat, "0:8", "Column Title Test");
  SetAttribute(mat, "NUMCOL_VISIBLE", "3")
  SetAttribute(mat, "NUMLIN_VISIBLE", "5")
  #  IupSetAttribute(mat,"EDITNEXT","COLCR");
  #  IupSetAttribute(mat, "NUMCOL_NOSCROLL", "1");

  #  IupSetAttribute(mat, "LIMITEXPAND", "Yes");
  #  IupSetAttribute(mat, "XAUTOHIDE", "NO");
  #  IupSetAttribute(mat, "YAUTOHIDE", "NO");

  #  IupSetAttribute(mat,"RASTERSIZE","x300");
  #  IupSetAttribute(mat,"FITTOSIZE","LINES");

  #  IupSetAttribute(mat,"TYPECOLORINACTIVE","No");
  #  IupSetAttribute(mat, "ACTIVE", "No");

  #  IupSetAttribute(mat, "FRAMEBORDER", "Yes");
  #  IupSetAttribute(mat, "FLATSCROLLBAR", "Yes");
  #  IupSetAttribute(mat, "SHOWFLOATING", "Yes");

  # test for custom matrix attributes
  #{
  #  char* v;
  #  IupSetAttribute(mat, "MTX_LINE_ACTIVE_FLAG3:4", "Test1");
  #  IupSetAttributeId2(mat, "MTX_LINE_ACTIVE_FLAG", 5, 7, "Test2");
  #  printf("Test1=%s\n", IupGetAttribute(mat, "MTX_LINE_ACTIVE_FLAG3:4"));
  #  printf("Test2=%s\n", IupGetAttributeId2(mat, "MTX_LINE_ACTIVE_FLAG", 5, 7));
  #}

  SetCallback(mat, "DROPCHECK_CB", cast[Icallback](dropcheck_cb))
  SetCallback(mat,"DROP_CB", cast[Icallback](drop))
  #  IupSetCallback(mat,"MENUDROP_CB",(Icallback)drop);
  #  IupSetCallback(mat, "MOUSEMOVE_CB", (Icallback)mousemove_cb);
  #  IupSetCallback(mat,"CLICK_CB",(Icallback)click);
  #  IupSetCallback(mat,"ENTERITEM_CB",(Icallback)enteritem_cb);
  SetCallback(mat,"TOGGLEVALUE_CB", cast[Icallback](togglevalue_cb))

  result = mat

proc MatrixTest() =
  let mat = create_matrix()
  let box = Vbox(mat, nil)
  SetAttribute(box, "MARGIN", "10x10")
  #  IupSetAttribute(box, "FONT", "Arial, 7");

  let dlg = Dialog(box)
  SetAttribute(dlg, "TITLE", "IupMatrix Simple Test")
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  #        IupSetAttribute(mat, "ADDLIN", "1");
  #        IupSetAttribute(mat,"4:0","Teste");
  #        IupSetAttribute(mat, "REDRAW", "ALL");

proc mainProc =
  niupext.Open()
  ControlsOpen()
  ImageLibOpen()

  when defined(Linux):
    SetGlobal("UTF8MODE", "YES")

  MatrixTest()

  MainLoop()
  Close()

if isMainModule:
  mainProc()
