#IupFlatTree Example in C
# Creates a tree with some branches and leaves.
# Two callbacks are registered: one deletes marked nodes when the Del key is pressed,
# and the other, called when the right mouse button is pressed, opens a menu with options.
import niup
import niup/niupc
import niup/niupext
import strformat

proc load_image_LogoTecgraf(): PIHandle =
  let imgdata =
    [
      0'u8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 108, 120, 143, 125, 132, 148, 178, 173, 133, 149, 178, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 110, 130, 48, 130, 147, 177, 254, 124, 139, 167, 254, 131, 147, 176, 137, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 115, 128, 153, 134, 142, 159, 191, 194, 47, 52, 61, 110, 114, 128, 154, 222, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 143, 172, 192, 140, 156, 188, 99, 65, 69, 76, 16, 97, 109, 131, 251, 129, 144, 172, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 131, 147, 175, 232, 140, 157, 188, 43, 0, 0, 0, 0, 100, 112, 134, 211, 126, 141, 169, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 78, 88, 26, 48, 52, 57, 60, 135, 150, 178, 254, 108, 121, 145, 83, 105, 118, 142, 76, 106, 119, 143, 201, 118, 133, 159, 122, 117, 129, 152, 25, 168, 176, 190, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      118, 128, 145, 3, 104, 117, 140, 92, 114, 127, 152, 180, 131, 147, 177, 237, 133, 149, 178, 249, 38, 42, 50, 222, 137, 152, 180, 249, 126, 142, 170, 182, 114, 128, 154, 182, 104, 117, 140, 227, 95, 107, 128, 238, 83, 93, 112, 248, 84, 95, 113, 239, 104, 117, 141, 180, 115, 129, 155, 93, 127, 140, 165, 4,
      98, 109, 130, 153, 109, 123, 147, 254, 145, 163, 195, 153, 138, 154, 182, 56, 115, 123, 138, 5, 92, 99, 109, 35, 134, 149, 177, 230, 0, 0, 0, 0, 0, 0, 0, 0, 120, 133, 159, 143, 135, 151, 181, 115, 86, 89, 93, 5, 41, 45, 51, 54, 40, 45, 53, 150, 107, 120, 144, 254, 122, 137, 164, 154,
      51, 57, 66, 147, 83, 93, 112, 255, 108, 121, 145, 159, 113, 126, 151, 62, 123, 136, 159, 8, 87, 93, 103, 35, 125, 141, 169, 230, 0, 0, 0, 0, 0, 0, 0, 0, 129, 143, 169, 143, 140, 156, 184, 115, 134, 147, 172, 8, 124, 138, 165, 60, 124, 139, 167, 155, 131, 147, 177, 255, 131, 147, 176, 153,
      64, 68, 73, 2, 36, 39, 45, 86, 41, 46, 54, 173, 60, 67, 80, 232, 75, 84, 101, 251, 89, 100, 120, 228, 105, 118, 142, 250, 110, 123, 148, 187, 118, 132, 158, 187, 126, 141, 169, 229, 134, 149, 177, 239, 136, 152, 179, 250, 136, 152, 181, 234, 139, 156, 186, 175, 130, 145, 173, 90, 124, 134, 151, 3,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 71, 74, 79, 19, 60, 64, 73, 50, 92, 103, 124, 254, 86, 95, 111, 84, 90, 100, 117, 76, 126, 141, 168, 201, 113, 126, 150, 119, 99, 105, 117, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 93, 105, 125, 231, 135, 151, 181, 46, 0, 0, 0, 0, 137, 154, 184, 212, 123, 137, 164, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 74, 83, 98, 191, 133, 149, 179, 102, 111, 121, 139, 17, 134, 150, 180, 252, 126, 140, 166, 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 48, 57, 132, 121, 136, 164, 197, 121, 135, 161, 115, 130, 146, 175, 221, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 47, 52, 46, 87, 98, 118, 254, 126, 142, 170, 254, 124, 139, 166, 135, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 51, 57, 67, 118, 115, 128, 152, 170, 127, 140, 164, 17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]

  return ImageRGBA(16, 16, cast[ptr uint8](unsafeAddr(imgdata)))

const TEST_IMAGE_SIZE=16

proc load_image_TestImage(): PIHandle =
  let image_data_8 =
    [
      5'u8,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,0,0,0,1,1,1,1,2,2,2,2,0,0,0,5,
      5,0,0,0,1,1,1,1,2,2,2,2,0,0,0,5,
      5,0,0,0,1,1,1,1,2,2,2,2,0,0,0,5,
      5,0,0,0,1,1,1,1,2,2,2,2,0,0,0,5,
      5,0,0,0,3,3,3,3,4,4,4,4,0,0,0,5,
      5,0,0,0,3,3,3,3,4,4,4,4,0,0,0,5,
      5,0,0,0,3,3,3,3,4,4,4,4,0,0,0,5,
      5,0,0,0,3,3,3,3,4,4,4,4,0,0,0,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5,
      5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
    ]

  let image = Image(TEST_IMAGE_SIZE, TEST_IMAGE_SIZE, cast[ptr uint8](unsafeAddr(image_data_8)))
  withPIhandle image:
    "0" "BGCOLOR"
    "1" "255 0 0"
    "2" "0 255 0"
    "3" "0 0 255"
    "4" "255 255 255"
    "5" "0 0 0"

  return image

proc addleaf():int =
  let
    tree = GetHandle("flattree")
    id = GetInt(tree, "VALUE")
  SetAttributeId(tree, "ADDLEAF", id, "")
  return IUP_DEFAULT

proc insertleaf(ih:PIhandle):int =
  let
    tree = GetHandle("flattree")
    id = GetInt(tree, "VALUE")
  SetAttributeId(tree, "INSERTLEAF", id, "")
  return IUP_DEFAULT

proc addbranch():int =
  let
    tree = GetHandle("flattree")
    id = GetInt(tree, "VALUE")
  SetAttributeId(tree, "ADDBRANCH", id, "")
  return IUP_DEFAULT

proc insertbranch():int =
  let
    tree = GetHandle("flattree")
    id = GetInt(tree, "VALUE")
  SetAttributeId(tree, "INSERTBRANCH", id, "")
  return IUP_DEFAULT

proc togglestate():int =
  let
    tree = GetHandle("flattree")
    id = GetInt(tree, "VALUE")
    value = GetAttributeId(tree, "STATE", id)
  if value != nil:
    if value == "EXPANDED":
      SetAttributeId(tree, "STATE", id, "COLLAPSED")
    else:
      SetAttributeId(tree, "STATE", id, "EXPANDED")
  return IUP_DEFAULT

proc togglemarkmode():int =
  let
    tree = GetHandle("flattree")
    value = GetAttribute(tree, "MARKMODE")
  if value == "SINGLE":
    SetAttribute(tree, "MARKMODE", "MULTIPLE")
  else:
    SetAttribute(tree, "MARKMODE", "SINGLE")
  let a = GetAttribute(tree, "MARKMODE")
  echo fmt"MARKMODE={a}\n"
  return IUP_DEFAULT

proc text_cb(ih:PIhandle, c:cint, after:cstring):int =
  if c == K_ESC:
    return IUP_CLOSE

  if c == K_CR:
    let tree = GetHandle("flattree")
    SetAttribute(tree, "NAME", after)
    return IUP_CLOSE

  return IUP_DEFAULT

proc tips_cb(ih:PIhandle, x:cint, y:cint):int =
  echo fmt"TIPS_CB({x}, {y})\n"
  return IUP_DEFAULT

proc removenode():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "DELNODE", "SELECTED")
  return IUP_DEFAULT

proc removechild():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "DELNODE", "CHILDREN")
  return IUP_DEFAULT

proc removemarked():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "DELNODE", "MARKED")
  return IUP_DEFAULT

proc removeall():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "DELNODE", "ALL")
  return IUP_DEFAULT

proc setFont():int =
  var tree = GetHandle("flattree")
  let
    fontdlg = FontDlg()
    id = GetInt(tree, "VALUE")
  var font = GetAttributeId(tree, "TITLEFONT", id)

  SetStrAttribute(fontdlg, "VALUE", font)
  discard Popup(fontdlg, IUP_CENTER, IUP_CENTER)

  if GetInt(fontdlg, "STATUS") == 1:
    font = GetAttribute(fontdlg, "VALUE")
    SetStrAttributeId(tree, "TITLEFONT", id, font)

  return IUP_DEFAULT

proc expandall():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "EXPANDALL", "YES")
  return IUP_DEFAULT

proc contractall():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "EXPANDALL", "NO")
  return IUP_DEFAULT

proc renamenode():int =
  let tree = GetHandle("flattree")
  SetAttribute(tree, "RENAME", "YES")
  return IUP_DEFAULT

proc button_cb(ih:PIhandle, but, pressed, x, y:cint, status:cstring):int =
  let cxy = ConvertXYToPos(ih, x, y)
  echo fmt"FLAT_BUTTON_CB(but={but} ({pressed}), x={x}, y={y} [{status}]) - [id={cxy}]\n"
  return IUP_DEFAULT

proc motion_cb(ih:PIhandle, x, y:cint, status:cstring):int =
  let cxy = ConvertXYToPos(ih, x, y)
  echo fmt"MOTION_CB(x={x}, y={y} [{status}]) - [id={cxy}]\n"
  return IUP_DEFAULT

proc showrename_cb(ih:PIhandle, id:cint):int =
  echo fmt"SHOWRENAME_CB({id})\n"
  if id == 6:
    return IUP_IGNORE
  return IUP_DEFAULT

proc togglevalue_cb(ih:PIhandle, id, status:cint):int =
  echo fmt"TOGGLEVALUE_CB({id}, {status})\n"
  return IUP_DEFAULT

proc selection_cb(ih:PIhandle, id, status:cint):int =
  echo fmt"SELECTION_CB(id={id}, status={status})\n"
  let ud = GetAttributeId(ih, "USERDATA", id)
  echo fmt"    USERDATA={ud}\n"
  return IUP_DEFAULT

proc multiselection_cb(ih:PIhandle, ids:var ptr int, n:cint):int =
  echo "MULTISELECTION_CB("
  echo "TODO"
  #TODO
  #for i in countup(0, n):
  #  echo ids[i] & ", "
  echo fmt"n={n})\n"
  return IUP_DEFAULT

proc multiunselection_cb(ih:PIhandle, ids:var ptr int, n:cint):int =
  echo "MULTIUNSELECTION_CB("
  echo "TODO"
  #TODO
  #for i in countup(0, n):
  #  echo ids[i] & ", "
  echo fmt"n={n})\n"
  return IUP_DEFAULT

proc executeleaf_cb(ih:PIhandle, id:cint):int =
  echo fmt"EXECUTELEAF_CB ({id})\n"
  return IUP_DEFAULT

proc rename_cb(ih:PIhandle, id:cint, title:cstring):int =
  echo fmt"RENAME_CB ({id}={title})\n", id, title
  if title == "fool":
    return IUP_IGNORE
  return IUP_DEFAULT

proc branchopen_cb(ih:PIhandle, id:cint):int =
  echo fmt"BRANCHOPEN_CB ({id})\n"
  return IUP_DEFAULT

proc branchclose_cb(ih:PIhandle, id:cint):int =
  echo fmt"BRANCHCLOSE_CB ({id})\n"
  return IUP_DEFAULT

proc noderemoved_cb(ih:PIhandle, data:pointer):int =
  let p = repr(data)
  echo fmt"NODEREMOVED_CB(userdata={p})\n"
  return IUP_DEFAULT

proc dragdrop_cb(ih:PIhandle, drag_id, drop_id, shift, control:int):int =
  echo fmt"DRAGDROP_CB (drag_id)->(drop_id) shift={shift} ctrl={control}\n"
  return IUP_CONTINUE

proc getfocus_cb(ih:PIhandle):int =
  echo "GETFOCUS_CB()\n"
  return IUP_DEFAULT

proc killfocus_cb(ih:PIhandle):int =
  echo "KILLFOCUS_CB()\n"
  return IUP_DEFAULT

proc leavewindow_cb(ih:PIhandle):int =
  echo "LEAVEWINDOW_CB()\n"
  return IUP_DEFAULT

proc enterwindow_cb(ih:PIhandle):int =
  echo "ENTERWINDOW_CB()\n"
  return IUP_DEFAULT

proc iupKeyCodeToName(code:int): cstring {.cdecl, importc: "iupKeyCodeToName", dynlib: niup.libiupimSONAME.}

proc k_any_cb(ih:PIhandle, c:int):int =
  if c == K_DEL:
    SetAttribute(ih, "DELNODE", "MARKED")

  let
    parTitle = GetAttribute(GetParent(GetParent(ih)), "TITLE")
    kcn = iupKeyCodeToName(c)

  if iup_isprint(c):
    echo fmt"K_ANY({parTitle}, {ord(c)} = {kcn} \'{c}\')\n"
  else:
    echo fmt"K_ANY({parTitle}, {ord(c)} = {kcn})\n"

  return IUP_CONTINUE

proc help_cb(ih:PIhandle):int =
  echo "HELP_CB()\n"
  return IUP_DEFAULT

proc selectnode(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  SetAttribute(tree, "VALUE", GetAttribute(ih, "TITLE"))
  return IUP_DEFAULT

proc markednode(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  let id = GetInt(tree, "VALUE")
  SetAttributeId(tree, "MARKED", id, GetAttribute(ih, "TITLE"))
  return IUP_DEFAULT

proc markstart(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  let id = GetInt(tree, "VALUE")
  SetInt(tree, "MARKSTART", id)
  return IUP_DEFAULT

proc marknode(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  SetAttribute(tree, "MARK", GetAttribute(ih, "TITLE"))
  return IUP_DEFAULT

proc nodeinfo(ih:PIhandle):int =
  var
    kind:cstring
    branch = 0
  let
    dial = GetAttributeHandle(ih, "DIAL")
    tree = GetAttributeHandle(dial, "FLATTREE")
    id = GetInt(tree, "VALUE")
  echo "\nTree Info:\n"
  echo "  TOTALCOUNT=", GetAttribute(tree, "COUNT"), "\n"
  if id == -1:
    return IUP_DEFAULT
  echo "Node Info:\n"
  echo "  ID={id}\n".fmt
  echo "  TITLE=", GetAttribute(tree, "TITLE"), "\n"
  echo "  DEPTH=", GetAttribute(tree, "DEPTH"), "\n"
  kind = GetAttribute(tree, "KIND")
  echo "  KIND=", kind, "\n"
  if kind == "BRANCH":
    branch = 1
  if branch == 1:
    echo "  STATE=", GetAttribute(tree, "STATE"), "\n"
  echo "  IMAGE=", GetAttributeId(tree, "IMAGE", id), "\n"
  if branch == 1:
    echo "  IMAGEBRANCHEXPANDED=", GetAttribute(tree, "IMAGEBRANCHEXPANDED"), "\n"
  echo "  MARKED=", GetAttribute(tree, "MARKED"), "\n"
  echo "  COLOR=", GetAttributeId(tree, "COLOR", id), "\n"
  echo "  PARENT=", GetAttributeId(tree, "PARENT", id), "\n"
  echo "  CHILDCOUNT=", GetAttribute(tree, "CHILDCOUNT"), "\n"
  echo "  USERDATA=", GetAttributeId(tree, "USERDATA", id), "\n"
  return IUP_DEFAULT

proc rightclick_cb(ih:PIhandle, id:int):int =
  var popup_menu = Menu(
    Item("Node Info", "nodeinfo"),
    Item("Rename Node", "renamenode"),
    Separator(),
    Item("Add Leaf", "addleaf"),
    Item("Add Branch", "addbranch"),
    Item("Insert Leaf", "insertleaf"),
    Item("Insert Branch", "insertbranch"),
    Item("Remove Node", "removenode"),
    Item("Remove Children", "removechild"),
    Item("Remove Marked", "removemarked"),
    Item("Remove All", "removeall"),
    Item("Set Font", "setfont"),
    Separator(),
    Item("Toggle State", "togglestate"),
    Item("Expand All", "expandall"),
    Item("Contract All", "contractall"),
    Submenu("Focus (VALUE)", Menu(
      Item("ROOT", "selectnode"),
      Item("LAST", "selectnode"),
      Item("PGUP", "selectnode"),
      Item("PGDN", "selectnode"),
      Item("NEXT", "selectnode"),
      Item("PREVIOUS", "selectnode"),
      Item("CLEAR", "selectnode"),
      nil)),
    Item("Toggle Mark Mode", "togglemarkmode"),
    Submenu("Marked", Menu(
      Item("Yes", "markednode"),
      Item("No", "markednode"),
      nil)),
    Submenu("Mark (multiple)", Menu(
      Item("INVERT", "marknode"),
      Item("BLOCK", "marknode"),
      Item("CLEARALL", "marknode"),
      Item("MARKALL", "marknode"),
      Item("INVERTALL", "marknode"),
      Separator(),
      Item("MARKSTART", "markstart"),
      nil)),
    nil)

  SetFunction("nodeinfo", cast[ICallback](nodeinfo))
  SetFunction("selectnode", cast[ICallback](selectnode))
  SetFunction("marknode", cast[ICallback](marknode))
  SetFunction("markednode", cast[ICallback](markednode))
  SetFunction("markstart", cast[ICallback](markstart))
  SetFunction("togglemarkmode", cast[ICallback](togglemarkmode))
  SetFunction("addleaf", cast[ICallback](addleaf))
  SetFunction("addbranch", cast[ICallback](addbranch))
  SetFunction("insertleaf", cast[ICallback](insertleaf))
  SetFunction("insertbranch", cast[ICallback](insertbranch))
  SetFunction("removenode", cast[ICallback](removenode))
  SetFunction("removechild", cast[ICallback](removechild))
  SetFunction("removemarked", cast[ICallback](removemarked))
  SetFunction("renamenode", cast[ICallback](renamenode))
  SetFunction("togglestate", cast[ICallback](togglestate))
  SetFunction("removeall", cast[ICallback](removeall))
  SetFunction("setfont", cast[ICallback](setFont))
  SetFunction("expandall", cast[ICallback](expandall))
  SetFunction("contractall", cast[ICallback](contractall))

  SetAttributeHandle(popup_menu, "DIAL", GetDialog(ih))

  Popup(popup_menu, IUP_MOUSEPOS, IUP_MOUSEPOS)

  Destroy(popup_menu)

  return IUP_DEFAULT

proc active(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  if GetInt(tree, "ACTIVE") == 1:
    SetAttribute(tree, "ACTIVE", "NO")
  else:
    SetAttribute(tree, "ACTIVE", "YES")
  return IUP_DEFAULT

proc next(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  SetAttribute(tree, "VALUE", "NEXT")
  return IUP_DEFAULT

proc prev(ih:PIhandle):int =
  var tree = GetHandle("flattree")
  SetAttribute(tree, "VALUE", "PREVIOUS")
  return IUP_DEFAULT

proc show_tree_2(ih:PIhandle):int =
  let dlg = GetHandle("dlg_2")
  ShowXY(dlg, IUP_CENTER, IUP_CENTER) # Displays the dlg
  return IUP_DEFAULT

proc init_tree_nodes() =
  var
    tree = GetHandle("flattree")
    u8 = ""

  if GetInt(nil, "UTF8MODE") != 0:
    u8 = "Other (UTF-8 😁)"
  else:
    u8 = "Other (no UTF8)"

  # create from top to bottom
  withPIhandle tree:
    "ADDBRANCH-1" "Figures"
    "ADDLEAF0" "Other"     # new id=1
    "ADDBRANCH1" "triangle"  # new id=2
    "ADDLEAF2" "equilateral"
    "ADDLEAF3" "isoceles"
    "ADDLEAF4" "scalenus"
    "STATE2" "expanded"
    "INSERTBRANCH2" "parallelogram"  # same depth as id=2 new id=6
    "ADDLEAF6" "square very long string at tree node"
    "ADDLEAF7" "diamond"
    "INSERTLEAF6" "2D"  #new id=9
    "INSERTBRANCH9" "3D"
    "INSERTBRANCH10" u8
    "ADDLEAF11" "Depth 1"
    "ADDBRANCH12" "Folder"
    "ADDLEAF13" "Depth 2"
    "TOGGLEVALUE2" "ON"
    "TOGGLEVALUE6" "ON"
    "TOGGLEVISIBLE7" "No"
    "RASTERSIZE" nil   # remove the minimum size limitation
    "COLOR8" "92 92 255"
    "IMAGE7" "IMGEMPTY"
    "BACKCOLOR5" "0 255 0"
    "COLOR4" "255 0 0"
    "COLOR5" "255 0 0"
    "ITEMTIP6" "Node Tip"
    "TITLEFONTSTYLE3" "Bold"
    "USERDATA0" "0"
    "USERDATA1" "1"
    "USERDATA2" "2"
    "USERDATA3" "3"
    "USERDATA4" "4"
    "USERDATA5" "5"
    "USERDATA6" "6"
    "USERDATA7" "7"
    "USERDATA8" "8"
    "USERDATA9" "9"
    handle "IMAGE1" load_image_LogoTecgraf()
    handle "IMAGE2" load_image_TestImage()

proc init_tree_2_nodes() =
  var tree2 = GetHandle("flattree_2")

  # create from top to bottom
  withPIhandle tree2:
    "ADDBRANCH-1" "NFL"
    "ADDBRANCH0" "AFC"  # new id=2
    "ADDBRANCH1" "EAST"  # ...
    "ADDLEAF2" "Patriots"
    "ADDLEAF3" "Bills"
    "ADDLEAF4" "Jets"
    "ADDLEAF5" "Dolphins"  # same depth as id=2 new id=6
    "INSERTBRANCH2" "North"  # same depth as id=2 new id=6
    "ADDLEAF7" "Ravens"
    "ADDLEAF8" "Steelers"
    "ADDLEAF9" "Browns"
    "ADDLEAF10" "Bengals"  # same depth as id=2 new id=6
    "INSERTBRANCH7" "South"  # same depth as id=2 new id=6
    "ADDLEAF12" "Colts"
    "ADDLEAF13" "Texans"
    "ADDLEAF14" "Titans"
    "ADDLEAF15" "Jaguars"  # same depth as id=2 new id=6
    "INSERTBRANCH12" "West"  # same depth as id=2 new id=6
    "ADDLEAF17" "Chiefs"
    "ADDLEAF18" "Raiders"
    "ADDLEAF19" "Chargers"
    "ADDLEAF20" "Broncos"  # same depth as id=2 new id=6
    "TOGGLEVALUE2" "ON"
    "TOGGLEVALUE6" "ON"
    "RASTERSIZE" nil   # remove the minimum size limitation
    "COLOR8" "92 92 255"
    handle "IMAGE8" load_image_LogoTecgraf()
    handle "IMAGE7" load_image_TestImage()
    "ITEMBGCOLOR5" "0 255 0"
    "ITEMFGCOLOR4" "255 0 0"
    "ITEMFGCOLOR5" "255 0 0"
    "ITEMFONTSTYLE3" "Bold"
    "USERDATA0" "0"
    "USERDATA1" "1"
    "USERDATA2" "2"
    "USERDATA3" "3"
    "USERDATA4" "4"
    "USERDATA5" "5"
    "USERDATA6" "6"
    "USERDATA7" "7"
    "USERDATA8" "8"
    "USERDATA9" "9"


# Initializes IupFlatTree and registers callbacks
proc init_tree_2():PIhandle =
  var tree2 = FlatTree()

  withPIhandle tree2:
    cb "EXECUTELEAF_CB" executeleaf_cb
    cb "RENAME_CB" rename_cb
    cb "BRANCHCLOSE_CB" branchclose_cb
    cb "BRANCHOPEN_CB" branchopen_cb
    cb "DRAGDROP_CB" dragdrop_cb
    cb "RIGHTCLICK_CB" rightclick_cb
    cb "SHOWRENAME_CB" showrename_cb
    cb "SELECTION_CB" selection_cb
    cb "NODEREMOVED_CB" noderemoved_cb
    cb "TOGGLEVALUE_CB" togglevalue_cb
    cb "HELP_CB" help_cb
    "DRAGDROPTREE" "Yes"
    "DRAGSOURCE" "YES"
    "DRAGSOURCEMOVE" "YES"
    "DRAGTYPES" "NODETREE"
    "MARKMODE"     "MULTIPLE"
    "SHOWRENAME" "YES"
    "MARKWHENTOGGLE" "YES"
    "SHOWTOGGLE" "3STATE"
    "ADDEXPANDED" "YES"
    "TIP" "Tree Tip"
    "VISIBLECOLUMNS" "10"
    "VISIBLELINES" "10"

  SetHandle("flattree_2", tree2)

  return tree2

# Initializes IupFlatTree and registers callbacks
proc init_tree():PIhandle =
  var tree = FlatTree()

  withPIhandle tree:
    cb "EXECUTELEAF_CB" executeleaf_cb
    cb "RENAME_CB" rename_cb
    cb "BRANCHCLOSE_CB" branchclose_cb
    cb "BRANCHOPEN_CB" branchopen_cb
    cb "DRAGDROP_CB" dragdrop_cb
    cb "RIGHTCLICK_CB" rightclick_cb
    cb "SHOWRENAME_CB" showrename_cb
    cb "SELECTION_CB" selection_cb
    cb "NODEREMOVED_CB" noderemoved_cb
    cb "TOGGLEVALUE_CB" togglevalue_cb
    cb "HELP_CB" help_cb
    "MARKMODE"     "MULTIPLE"
    "SHOWRENAME" "YES"
    "TIP" "Tree Tip"
    "VISIBLECOLUMNS" "40"
    "VISIBLELINES" "60"

  SetHandle("flattree", tree)

  return tree

# Initializes the dlg */
proc init_dlg() =
  var
    butactv = Button("Active", nil)
    butnext = Button("Next", nil)
    butprev = Button("Prev", nil)
    butmenu = Button("Menu", nil)
    buttree = Button("Tree", nil)
    tree = init_tree()
    vb = Vbox(butactv,
              butnext,
              butprev,
              butmenu,
              buttree,
              nil)
    box = Hbox(tree, vb, nil)
    dlg = Dialog(box)

  SetAttribute(dlg, "TITLE", "IupFlatTree")
  SetAttribute(dlg, "SIZE", "400x400")
  SetAttribute(box, "MARGIN", "10x10")
  SetAttribute(box, "GAP", "10")
  SetCallback(butactv, "ACTION", active)
  SetCallback(butnext, "ACTION", next)
  SetCallback(butprev, "ACTION", prev)
  SetCallback(buttree, "ACTION", show_tree_2)
  SetCallback(butmenu, "ACTION", cast[Icallback](rightclick_cb))

  SetAttributeHandle(dlg, "FLATTREE", tree)

  SetHandle("dlg", dlg)

# Initializes the dlg
proc init_dlg_2() =
  var
    tree = init_tree_2()
    box = Hbox(tree, nil)
    dlg = Dialog(box)

  SetAttribute(dlg, "TITLE", "IupFlatTree")
  SetAttribute(dlg, "SIZE", "400x400")
  SetAttribute(box, "MARGIN", "10x10")
  SetAttribute(box, "GAP", "10")

  SetAttributeHandle(dlg, "FLATTREE", tree)

  SetHandle("dlg_2", dlg)

proc FlatTreeTest() =
  init_dlg()                             # Initializes the dlg
  init_dlg_2()                             # Initializes the dlg
  var dlg = GetHandle("dlg")              # Retrieves the dlg handle
  init_tree_nodes()                  # Initializes attributes, can be done here or anywhere
  init_tree_2_nodes()                  # Initializes attributes, can be done here or anywhere
  ShowXY(dlg, IUP_CENTER, IUP_CENTER) # Displays the dlg
  SetAttribute(dlg, "USERSIZE", nil)

proc mainProc =
  niupext.Open()

  when defined(Linux):
    SetGlobal("UTF8MODE", "YES")

  FlatTreeTest()

  MainLoop()
  Close()

if isMainModule:
  mainProc()
