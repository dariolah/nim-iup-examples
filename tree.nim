# IupTree: Example in C
# Creates a tree with some branches and leaves.
# Two callbacks are registered: one deletes marked nodes when the Del key is pressed,
# and the other, called when the right mouse button is pressed, opens a menu with options.

import niup
import niupext
import strformat
import streams

# Callback called when a leaf is added by the menu.
proc addleaf():int =
  let
    strm {.global.} = newStringStream("")
    tree = GetHandle("tree")
    id = GetInt(tree,"VALUE")
  strm.write(fmt"ADDLEAF{id}")
  let attr = strm.readAll()
  SetAttribute(tree,attr.cstring,"");
  return IUP_DEFAULT

# Callback called when a branch is added by the menu.
proc addbranch():int =
  let
    strm {.global.} = newStringStream("")
    tree = GetHandle("tree")
    id = GetInt(tree,"VALUE")
  strm.write(fmt"ADDBRANCH{id}")
  let attr = strm.readAll()
  SetAttribute(tree,attr.cstring,"");
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

  SetCallback(tree, "EXECUTELEAF_CB", cast[Icallback]( executeleaf_cb))
  SetCallback(tree, "RENAME_CB", cast[Icallback]( rename_cb))
  SetCallback(tree, "BRANCHCLOSE_CB", cast[Icallback]( branchclose_cb))
  SetCallback(tree, "BRANCHOPEN_CB", cast[Icallback]( branchopen_cb))
  SetCallback(tree, "DRAGDROP_CB", cast[Icallback]( dragdrop_cb))
  SetCallback(tree, "RIGHTCLICK_CB", cast[Icallback]( rightclick_cb))
  SetCallback(tree, "K_ANY", cast[Icallback]( k_any_cb))

  #SetAttribute(tree, "FONT","COURIER_NORMAL")
  #SetAttribute(tree, "CTRL","YES")
  #SetAttribute(tree, "SHIFT","YES")
  #SetAttribute(tree, "ADDEXPANDED", "NO")
  #SetAttribute(tree, "SHOWDRAGDROP", "YES")
  SetAttribute(tree, "SHOWRENAME", "YES")

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

  SetAttribute(tree, "TITLE","Figures")
  SetAttribute(tree, "ADDBRANCH","3D")
  SetAttribute(tree, "ADDBRANCH","2D")
  SetAttribute(tree, "ADDLEAF","test")
  SetAttribute(tree, "ADDBRANCH1","parallelogram")
  SetAttribute(tree, "ADDLEAF2","diamond")
  SetAttribute(tree, "ADDLEAF2","square")
  SetAttribute(tree, "ADDBRANCH1","triangle")
  SetAttribute(tree, "ADDLEAF2","scalenus")
  SetAttribute(tree, "ADDLEAF2","isoceles")
  SetAttribute(tree, "ADDLEAF2","equilateral")
  SetAttribute(tree, "VALUE","6")

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
