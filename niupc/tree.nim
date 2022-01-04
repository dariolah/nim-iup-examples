# IupTree: Example in C
# Creates a tree with some branches and leaves.
# Two callbacks are registered: one deletes marked nodes when the Del key is pressed,
# and the other, called when the right mouse button is pressed, opens a menu with options.

import niup/niupc
import niup/niupext
import strformat

# Callback called when a leaf is added by the menu.
proc addleaf():int =
  let
    tree = GetHandle("tree")
    id = GetInt(tree,"VALUE")
  SetAttributeId(tree,"ADDLEAF", id, "");
  return IUP_DEFAULT

# Callback called when a branch is added by the menu.
proc addbranch():int =
  let
    tree = GetHandle("tree")
    id = GetInt(tree,"VALUE")
  SetAttributeId(tree,"ADDBRANCH", id, "");
  return IUP_DEFAULT

# Callback called when a node is removed by the menu
proc removenode():int =
  let
    tree = GetHandle("tree")
  SetAttribute(tree,"DELNODE","MARKED")
  return IUP_DEFAULT

# from the menu *
proc renamenode():int =
  return IUP_DEFAULT

proc executeleaf_cb(h:PIhandle, id:int):int =
  echo fmt"executeleaf_cb ({id})\n"
  return IUP_DEFAULT

proc rename_cb(h:PIhandle, id:int, name:cstring):int =
  echo fmt"rename_cb ({id}={name})\n"
  if name == "fool":
    return IUP_IGNORE
  return IUP_DEFAULT

proc branchopen_cb(h:PIhandle, id:int):int =
  echo fmt"branchopen_cb ({id})\n"
  return IUP_DEFAULT

proc branchclose_cb(h:PIhandle, id:int):int =
  echo fmt"branchclose_cb (id)\n"
  return IUP_DEFAULT

proc dragdrop_cb(h:PIhandle, drag_id, drop_id, isshift, iscontrol:int):int =
  echo fmt"dragdrop_cb ({drag_id})->({drop_id})\n"
  return IUP_DEFAULT

# Callback called when a key is hit
proc k_any_cb(h:PIhandle, c:int):int =
  if c == K_DEL:
    SetAttribute(h,"DELNODE","MARKED")

  return IUP_DEFAULT

proc selectnode(h:PIhandle):int =
  let tree = GetHandle("tree")
  SetAttribute(tree,"VALUE",GetAttribute(h, "TITLE"))
  return IUP_DEFAULT

# Callback called when the right mouse button is pressed
proc rightclick_cb(h:PIhandle, id:int):int =
  let popup_menu = Menu(
    Item("Add Leaf","addleaf"),
    Item("Add Branch","addbranch"),
    Item("Rename Node","renamenode"),
    Item("Remove Node","removenode"),
    Submenu("Selection", Menu(
      Item("ROOT", "selectnode"),
      Item("LAST", "selectnode"),
      Item("PGUP", "selectnode"),
      Item("PGDN", "selectnode"),
      Item("NEXT", "selectnode"),
      Item("PREVIOUS", "selectnode"),
      Separator(),
      Item("INVERT", "selectnode"),
      Item("BLOCK", "selectnode"),
      Item("CLEARALL", "selectnode"),
      Item("MARKALL", "selectnode"),
      Item("INVERTALL", "selectnode"),
      nil)),
    nil)
    
  discard SetFunction("selectnode", cast[Icallback](selectnode))
  
  discard SetFunction("addleaf", cast[Icallback](addleaf))
  discard SetFunction("addbranch", cast[Icallback](addbranch))
  discard SetFunction("removenode", cast[Icallback](removenode))
  discard SetFunction("renamenode", cast[Icallback](renamenode))

  SetAttribute(h, "VALUE", $id)
  Popup(popup_menu,IUP_MOUSEPOS, IUP_MOUSEPOS)

  Destroy(popup_menu)

  return IUP_DEFAULT

# Initializes IupTree and registers callbacks
proc init_tree() =
  let tree = Tree()

  withPIhandle tree:
    cb "EXECUTELEAF_CB" executeleaf_cb
    cb "RENAME_CB" rename_cb
    cb "BRANCHCLOSE_CB" branchclose_cb
    cb "BRANCHOPEN_CB" branchopen_cb
    cb "DRAGDROP_CB" dragdrop_cb
    cb "RIGHTCLICK_CB" rightclick_cb
    cb "K_ANY" k_any_cb
    "SHOWRENAME" "YES"

  SetHandle("tree",tree)

# Initializes the dialog
proc init_dlg() =
  let
    tree = GetHandle("tree")
    box = Vbox(Hbox(tree, Button("test", nil), nil), nil)
    dlg = Dialog(box)
  SetAttribute(dlg, "TITLE", "IupTree");
  SetAttribute(box, "MARGIN", "20x20");
  SetHandle("dlg",dlg);

# Initializes the IupTree's attributes
proc init_tree_atributes() =
  let tree = GetHandle("tree")

  withPIhandle tree:
    "TITLE" "Figures"
    "ADDBRANCH" "3D"
    "ADDBRANCH" "2D"
    "ADDLEAF" "test"
    "ADDBRANCH1" "parallelogram"
    "ADDLEAF2" "diamond"
    "ADDLEAF2" "square"
    "ADDBRANCH1" "triangle"
    "ADDLEAF2" "scalenus"
    "ADDLEAF2" "isoceles"
    "ADDLEAF2" "equilateral"
    "VALUE" "6"

proc mainProc =
  niupext.Open()
  ControlsOpen()

  init_tree()                          # Initializes IupTree
  init_dlg()                           # Initializes the dialog
  let dlg = GetHandle("dlg")               # Retrieves the dialog handle
  ShowXY(dlg,IUP_CENTER,IUP_CENTER)    # Displays the dialog
  init_tree_atributes()                # Initializes attributes, can be done here or anywhere

  MainLoop()
  Close()

if isMainModule:
  mainProc()
