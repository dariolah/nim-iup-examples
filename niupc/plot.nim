#  IupPlot Test
#  Description : Create all built-in plots.
#                It is organised as two side-by-side panels:
#                  - left panel for current plot control
#                  - right panel containg tabbed plots
#       Remark : depend on libs IUP, CD, IUP_PLOT

import niup
import niupext
import strformat
import strutils

const MAXPLOT = 6  # room for examples


var plot: array[00 .. MAXPLOT, PIhandle]
var dial1, dial2,              # dials for zooming
        tgg1, tgg2,            # autoscale on|off toggles
        tgg3, tgg4,            # grid show|hide toggles
        tgg5,                  # legend show|hide toggle
        tabs:PIhandle          # tabbed control

proc delete_cb(ih:PIhandle, index, sample_index:cint, x, y:cdouble):cint =
  echo fmt"DELETE_CB({index}, {sample_index}, {x}, {y})\n"
  return IUP_DEFAULT

proc select_cb(ih:PIhandle, index, sample_index:cint, x, y:cdouble, select:cint):cint =
  echo fmt"SELECT_CB({index}, {sample_index}, {x}, {y}, {select})\n"
  return IUP_DEFAULT

proc postdraw_cb(ih:PIhandle, cnv:ptr cdCanvas):cint =
  var ix, iy:cdouble

  PlotTransform(ih, 0.003f, 0.02f, addr ix, addr iy)
  cdCanvasFont(cnv, nil, CD_BOLD, 10)
  cdCanvasTextAlignment(cnv, CD_SOUTH)
  cdfCanvasText(cnv, ix, iy, "My Inline Legend")
  echo "POSTDRAW_CB()\n"

  return IUP_DEFAULT

proc predraw_cb(ih:PIhandle, cnv:ptr cdCanvas):cint =
  echo "PREDRAW_CB()\n"
  return IUP_DEFAULT

proc InitPlots() =
  var
    theI:int
    x, y, theFac:float64

  #************************************************************************
  # PLOT 0 - MakeExamplePlot1
  SetAttribute(plot[0], "TITLE", "AutoScale")
  SetAttribute(plot[0], "FONT", "Helvetica, 10")
  SetAttribute(plot[0], "LEGENDSHOW", "YES")
  SetAttribute(plot[0], "AXS_XLABEL", "gnu (Foo)")
  SetAttribute(plot[0], "AXS_YLABEL", "Space (m^3)")
  SetAttribute(plot[0], "AXS_XCROSSORIGIN", "Yes")
  SetAttribute(plot[0], "AXS_YCROSSORIGIN", "Yes")


  theFac = 1.0/(100*100*100)
  PlotBegin(plot[0], 0)
  for theI in -100 .. 100:
    x = float(theI+50)
    y = theFac * (theI * theI * theI).float
    PlotAdd(plot[0], x, y)

  PlotEnd(plot[0])
  SetAttribute(plot[0], "DS_LINEWIDTH", "3")
  SetAttribute(plot[0], "DS_LEGEND", "Line")

  theFac = 2.0/100
  PlotBegin(plot[0], 0)
  for theI in -100 ..< 0:
    x = theI.float
    y = -theFac * theI.float
    PlotAdd(plot[0], x, y)

  block:
    let index = PlotEnd(plot[0]) # add an empty plot
    var
      px:array[0 .. 210, cdouble]
      py:array[0 .. 210, cdouble]
      count:cint = 0
    for theI in 0 .. 100:
      x = theI.float
      y = -theFac * theI.float
      px[theI] = x
      py[theI] = y
      count += 1
    PlotInsertSamples(plot[0], index, 100, cast[ptr cdouble](addr px), cast[ptr cdouble](addr py), count)

  SetAttribute(plot[0], "DS_LEGEND", "Curve 1")

  PlotBegin(plot[0], 0)
  for theI in -100 .. 101:
    x = 0.01 * float(theI * theI) - 30
    y = 0.01 * theI.float
    PlotAdd(plot[0], x, y)
  PlotEnd(plot[0])
  SetAttribute(plot[0], "DS_LEGEND", "Curve 2")

  #************************************************************************
  # PLOT 1
  SetAttribute(plot[1], "TITLE", "No Autoscale+No CrossOrigin")
  SetAttribute(plot[1], "FONT", "Helvetica, 10")
  SetAttribute(plot[1], "BGCOLOR", "0 192 192")
  SetAttribute(plot[1], "AXS_XLABEL", "Tg (X)")
  SetAttribute(plot[1], "AXS_YLABEL", "Tg (Y)")
  SetAttribute(plot[1], "AXS_XAUTOMIN", "NO")
  SetAttribute(plot[1], "AXS_XAUTOMAX", "NO")
  SetAttribute(plot[1], "AXS_YAUTOMIN", "NO")
  SetAttribute(plot[1], "AXS_YAUTOMAX", "NO")
  SetAttribute(plot[1], "AXS_XMIN", "10")
  SetAttribute(plot[1], "AXS_XMAX", "60")
  SetAttribute(plot[1], "AXS_YMIN", "-0.5")
  SetAttribute(plot[1], "AXS_YMAX", "0.5")
  SetAttribute(plot[1], "AXS_XFONTSTYLE", "ITALIC")
  SetAttribute(plot[1], "AXS_YFONTSTYLE", "BOLD")
  SetAttribute(plot[1], "AXS_XREVERSE", "YES")
  SetAttribute(plot[1], "GRIDCOLOR", "128 255 128")
  SetAttribute(plot[1], "GRIDLINESTYLE", "DOTTED")
  SetAttribute(plot[1], "GRID", "YES")
  SetAttribute(plot[1], "LEGENDSHOW", "YES")
  SetAttribute(plot[1], "AXS_XLABELCENTERED", "Yes")
  SetAttribute(plot[1], "AXS_YLABELCENTERED", "Yes")
  SetAttribute(plot[1], "GRAPHICSMODE", "IMAGERGB")

  theFac = 1.0 / (100.0 * 100.0 * 100.0)
  PlotBegin(plot[1], 0)
  for theI in 0 .. 100:
    x = theI.float
    y = theFac * (theI * theI * theI).float
    PlotAdd(plot[1], x, y)
  PlotEnd(plot[1])

  theFac = 2.0 / 100.0
  PlotBegin(plot[1], 0)
  for theI in 0 .. 100:
    x = theI.float
    y = -theFac * theI.float
    PlotAdd(plot[1], x, y)
  PlotEnd(plot[1])

  #************************************************************************
  # PLOT 2
  SetAttribute(plot[2], "TITLE", "Log Scale")
  SetAttribute(plot[2], "GRID", "YES")
  SetAttribute(plot[2], "AXS_XSCALE", "LOG10")
  SetAttribute(plot[2], "AXS_YSCALE", "LOG2")
  SetAttribute(plot[2], "AXS_XLABEL", "Tg (X)")
  SetAttribute(plot[2], "AXS_YLABEL", "Tg (Y)")
  SetAttribute(plot[2], "AXS_XFONTSTYLE", "BOLD")
  SetAttribute(plot[2], "AXS_YFONTSTYLE", "BOLD")

  theFac = 100.0/(100*100*100)
  PlotBegin(plot[2], 0)
  for theI in 0 .. 100:
    x = 0.0001 + theI.float * 0.001
    y = 0.01 + theFac * (theI * theI * theI).float
    PlotAdd(plot[2], x, y)
  PlotEnd(plot[2])
  SetAttribute(plot[2], "DS_COLOR", "100 100 200")
  SetAttribute(plot[2], "DS_LINESTYLE", "DOTTED")

  #************************************************************************
  # PLOT 3
  SetAttribute(plot[3], "TITLE", "Bar Mode")

  block:
    let
      kLables = ["jan","feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
      kData = [10,20,30,40,50,60,70,80,90,0,10,20]
    PlotBegin(plot[3], 1)
    for theI in 0 ..< kLables.len:
      PlotAddStr(plot[3], kLables[theI].cstring, kData[theI].cdouble)

  PlotEnd(plot[3])
  SetAttribute(plot[3], "DS_COLOR", "100 100 200")
  SetAttribute(plot[3], "DS_MODE", "BAR")

  #************************************************************************
  # PLOT 4
  SetAttribute(plot[4], "TITLE", "Marks Mode")
  SetAttribute(plot[4], "AXS_XAUTOMIN", "NO")
  SetAttribute(plot[4], "AXS_XAUTOMAX", "NO")
  SetAttribute(plot[4], "AXS_YAUTOMIN", "NO")
  SetAttribute(plot[4], "AXS_YAUTOMAX", "NO")
  SetAttribute(plot[4], "AXS_XMIN", "0")
  SetAttribute(plot[4], "AXS_XMAX", "0.011")
  SetAttribute(plot[4], "AXS_YMIN", "0")
  SetAttribute(plot[4], "AXS_YMAX", "0.22")
  SetAttribute(plot[4], "AXS_XTICKFORMAT", "%1.3f")
  SetAttribute(plot[4], "LEGENDSHOW", "YES")
  SetAttribute(plot[4], "LEGENDPOS", "BOTTOMRIGHT")

  theFac = 100.0/(100*100*100)
  PlotBegin(plot[4], 0)
  for theI in 0 .. 10:
    x = 0.0001 + theI.float * 0.001
    y = 0.01 + theFac * (theI * theI).float
    PlotAdd(plot[4], x, y)

  PlotEnd(plot[4])
  SetAttribute(plot[4], "DS_MODE", "MARKLINE")

  PlotBegin(plot[4], 0)
  for theI in 0 .. 10:
    x = 0.0001 + theI.float * 0.001
    y = 0.2 - theFac * (theI * theI).float
    PlotAdd(plot[4], x, y)

  PlotEnd(plot[4])
  SetAttribute(plot[4], "DS_MODE", "MARK")
  SetAttribute(plot[4], "DS_MARKSTYLE", "HOLLOW_CIRCLE")
  
  #************************************************************************
  # PLOT 5
  SetAttribute(plot[5], "TITLE", "Data Selection and Editing")

  theFac = 100.0/(100*100*100)
  PlotBegin(plot[5], 0)
  for theI in -10 .. 10:
    x = 0.001 * theI.float
    y = 0.01 + theFac * (theI * theI * theI).float
    PlotAdd(plot[5], x, y)

  PlotEnd(plot[5])

  SetAttribute(plot[5], "AXS_XCROSSORIGIN", "Yes")
  SetAttribute(plot[5], "AXS_YCROSSORIGIN", "Yes")

  SetAttribute(plot[5], "DS_COLOR", "100 100 200")
  SetCallback(plot[5], "DELETE_CB", cast[Icallback](delete_cb))
  SetCallback(plot[5], "SELECT_CB", cast[Icallback](select_cb))
  SetCallback(plot[5], "POSTDRAW_CB", cast[Icallback](postdraw_cb))
  SetCallback(plot[5], "PREDRAW_CB", cast[Icallback](predraw_cb))

proc tabs_get_index():int =
  let curr_tab = GetHandle(GetAttribute(tabs, "VALUE"))
  let ss = GetAttribute(curr_tab, "TABTITLE");
  #ss += 5; # Skip "Plot "
  return parseInt(($ss)[5 ..< ss.len])

# Some processing required by current tab change: the controls at left
# will be updated according to current plot props
proc tabs_tabchange_cb(self:PIhandle, new_tab:PIhandle):cint =
  let ss = GetAttribute(new_tab, "TABTITLE")
  #ss += 5; # Skip "Plot "
  let ii = parseInt(($ss)[5 ..< ss.len])

  # autoscaling X axis
  if GetInt(plot[ii], "AXS_XAUTOMIN") != 0 and GetInt(plot[ii], "AXS_XAUTOMAX") != 0:
    SetAttribute(tgg2, "VALUE", "ON")
    SetAttribute(dial2, "ACTIVE", "NO")
  else:
    SetAttribute(tgg2, "VALUE", "OFF")
    SetAttribute(dial2, "ACTIVE", "YES")

  # autoscaling Y axis
  if GetInt(plot[ii], "AXS_YAUTOMIN") != 0 and GetInt(plot[ii], "AXS_YAUTOMAX") != 0:
    SetAttribute(tgg1, "VALUE", "ON")
    SetAttribute(dial1, "ACTIVE", "NO")
  else:
    SetAttribute(tgg1, "VALUE", "OFF")
    SetAttribute(dial1, "ACTIVE", "YES")

  # grid
  if GetInt(plot[ii], "GRID") != 0:
    SetAttribute(tgg3, "VALUE", "ON")
    SetAttribute(tgg4, "VALUE", "ON")
  else:
    # X axis
    if ($(GetAttribute(plot[ii], "GRID")))[0] == 'V':
      SetAttribute(tgg3, "VALUE", "ON")
    else:
      SetAttribute(tgg3, "VALUE", "OFF")
    # Y axis
    #tt =
    if ($(GetAttribute(plot[ii], "GRID")))[0] == 'H':
      SetAttribute(tgg4, "VALUE", "ON")
    else:
      SetAttribute(tgg4, "VALUE", "OFF")

  # legend
  if GetInt(plot[ii], "LEGENDSHOW") != 0:
    SetAttribute(tgg5, "VALUE", "ON")
  else:
    SetAttribute(tgg5, "VALUE", "OFF")

  return IUP_DEFAULT

# show/hide V grid
proc tgg3_cb(self:PIhandle, v:cint):cint =
  let ii = tabs_get_index()

  if v != 0:
    if GetInt(tgg4, "VALUE") != 0:
      SetAttribute(plot[ii], "GRID", "YES")
    else:
      SetAttribute(plot[ii], "GRID", "VERTICAL")
  else:
    if GetInt(tgg4, "VALUE") == 0:
      SetAttribute(plot[ii], "GRID", "NO");
    else:
      SetAttribute(plot[ii], "GRID", "HORIZONTAL")

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# show/hide H grid
proc tgg4_cb(self:PIhandle, v:cint):cint =
  let ii = tabs_get_index()

  if v != 0:
    if GetInt(tgg3, "VALUE") != 0:
      SetAttribute(plot[ii], "GRID", "YES")
    else:
      SetAttribute(plot[ii], "GRID", "HORIZONTAL")
  else:
    if GetInt(tgg3, "VALUE") == 0:
      SetAttribute(plot[ii], "GRID", "NO")
    else:
      SetAttribute(plot[ii], "GRID", "VERTICAL")

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# show/hide legend
proc tgg5_cb(self:PIhandle, v:cint):cint =
  let ii = tabs_get_index()

  if v != 0:
    SetAttribute(plot[ii], "LEGENDSHOW", "YES")
  else:
    SetAttribute(plot[ii], "LEGENDSHOW", "NO")

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# autoscale Y
proc tgg1_cb(self:PIhandle, v:cint):cint =
  let ii = tabs_get_index()

  if v != 0:
    SetAttribute(dial1, "ACTIVE", "NO")
    SetAttribute(plot[ii], "AXS_YAUTOMIN", "YES")
    SetAttribute(plot[ii], "AXS_YAUTOMAX", "YES")
  else:
    SetAttribute(dial1, "ACTIVE", "YES")
    SetAttribute(plot[ii], "AXS_YAUTOMIN", "NO")
    SetAttribute(plot[ii], "AXS_YAUTOMAX", "NO")

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# autoscale X
proc tgg2_cb(self:PIhandle, v:cint):cint =
  let ii = tabs_get_index()

  if v != 0:
    SetAttribute(dial2, "ACTIVE", "NO")
    SetAttribute(plot[ii], "AXS_XAUTOMIN", "YES")
    SetAttribute(plot[ii], "AXS_XAUTOMAX", "YES")
  else:
    SetAttribute(dial2, "ACTIVE", "YES")
    SetAttribute(plot[ii], "AXS_XAUTOMIN", "NO")
    SetAttribute(plot[ii], "AXS_XAUTOMAX", "NO")

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# Y zoom
proc dial1_btndown_cb(self:PIhandle, angle:cdouble):cint =
  let ii = tabs_get_index()

  StoreAttribute(plot[ii], "OLD_YMIN", GetAttribute(plot[ii], "AXS_YMIN"))
  StoreAttribute(plot[ii], "OLD_YMAX", GetAttribute(plot[ii], "AXS_YMAX"))

  return IUP_DEFAULT

proc dial1_btnup_cb(self:PIhandle, angle:cdouble):cint =
  let ii = tabs_get_index()

  var
    x1 = GetFloat(plot[ii], "OLD_YMIN")
    x2 = GetFloat(plot[ii], "OLD_YMAX")
    xm:float64

  let ss = GetAttribute(plot[ii], "AXS_YMODE")

  if ss != nil and ss[3]=='2':
    # LOG2:  one circle will zoom 2 times
    xm = 4.0 * abs(angle) / 3.141592
    if angle>0.0:
      x2 = x2 / xm
      x1 = x1 * xm
    else:
      x2 = x2 * xm
      x1 = x1 / xm

  if ss != nil and ss[3]=='1':
    # LOG10:  one circle will zoom 10 times
    xm = 10.0 * abs(angle) / 3.141592;
    if angle>0.0:
      x2 = x2 / xm
      x1 *= xm
    else:
      x2 *= xm
      x1 = x1 / xm
  else:
    # LIN: one circle will zoom 2 times
    xm = (x1 + x2) / 2.0
    x1 = xm - (xm - x1)*(1.0-angle*1.0/3.141592)
    x2 = xm + (x2 - xm)*(1.0-angle*1.0/3.141592)

  if x1<x2:
    SetfAttribute(plot[ii], "AXS_YMIN", "%g", x1);
    SetfAttribute(plot[ii], "AXS_YMAX", "%g", x2);

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

# X zoom
proc dial2_btndown_cb(self:PIhandle, angle:float64):cint =
  let ii = tabs_get_index()

  StoreAttribute(plot[ii], "OLD_XMIN", GetAttribute(plot[ii], "AXS_XMIN"))
  StoreAttribute(plot[ii], "OLD_XMAX", GetAttribute(plot[ii], "AXS_XMAX"))

  return IUP_DEFAULT

proc dial2_btnup_cb(self:PIhandle, angle:cdouble):cint =
  let ii = tabs_get_index()
  var
    xm:float64
    x1 = GetFloat(plot[ii], "OLD_XMIN")
    x2 = GetFloat(plot[ii], "OLD_XMAX")

  xm = (x1 + x2) / 2.0

  x1 = xm - (xm - x1)*(1.0-angle*1.0/3.141592) # one circle will zoom 2 times
  x2 = xm + (x2 - xm)*(1.0-angle*1.0/3.141592)

  SetfAttribute(plot[ii], "AXS_XMIN", "%g", x1)
  SetfAttribute(plot[ii], "AXS_XMAX", "%g", x2)

  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

proc bt1_cb(self:PIhandle):cint =
  let ii = tabs_get_index()
  SetAttribute(plot[ii], "CLEAR", "Yes")
  SetAttribute(plot[ii], "REDRAW", nil)

  return IUP_DEFAULT

proc PlotTest() =
  var
    vboxr:array[0 .. MAXPLOT, PIhandle]       # tabs containing the plots
    dlg, vboxl, hbox, lbl1, lbl2, lbl3, bt1:PIhandle
    boxinfo, boxdial1, boxdial2, f1, f2:PIhandle

  PlotOpen()     # init IupPlot library

  # create plots
  for ii in 0 ..< MAXPLOT:
    plot[ii] = Plot()
    SetAttribute(plot[ii], "MENUITEMPROPERTIES", "Yes")

  # left panel: plot control
  #   Y zooming
  dial1 = Dial("VERTICAL")
  lbl1 = Label("+")
  lbl2 = Label("-")
  boxinfo = Vbox(lbl1, Fill(), lbl2, nil)
  boxdial1 = Hbox(boxinfo, dial1, nil)

  SetAttribute(boxdial1, "ALIGNMENT", "ACENTER")
  SetAttribute(boxinfo, "ALIGNMENT", "ACENTER")
  SetAttribute(boxinfo, "SIZE", "20x52")
  SetAttribute(boxinfo, "GAP", "2")
  SetAttribute(boxinfo, "MARGIN", "4")
  SetAttribute(boxinfo, "EXPAND", "YES")
  SetAttribute(lbl1, "EXPAND", "NO")
  SetAttribute(lbl2, "EXPAND", "NO")

  SetAttribute(dial1, "ACTIVE", "NO")
  SetAttribute(dial1, "SIZE", "20x52")
  SetCallback(dial1, "BUTTON_PRESS_CB", cast[Icallback](dial1_btndown_cb))
  SetCallback(dial1, "MOUSEMOVE_CB", cast[Icallback](dial1_btnup_cb))
  SetCallback(dial1, "BUTTON_RELEASE_CB", cast[Icallback](dial1_btnup_cb))

  tgg1 = Toggle("Y Autoscale", nil)
  SetCallback(tgg1, "ACTION", cast[Icallback](tgg1_cb))
  SetAttribute(tgg1, "VALUE", "ON")

  f1 = Frame( Vbox(boxdial1, tgg1, nil) )
  SetAttribute(f1, "TITLE", "Y Zoom")

  # X zooming
  dial2 = Dial("HORIZONTAL")
  lbl1 = Label("-")
  lbl2 = Label("+")
  boxinfo = Hbox(lbl1, Fill(), lbl2, nil)
  boxdial2 = Vbox(dial2, boxinfo, nil)

  SetAttribute(boxdial2, "ALIGNMENT", "ACENTER")
  SetAttribute(boxinfo, "ALIGNMENT", "ACENTER")
  SetAttribute(boxinfo, "SIZE", "64x16")
  SetAttribute(boxinfo, "GAP", "2")
  SetAttribute(boxinfo, "MARGIN", "4")
  SetAttribute(boxinfo, "EXPAND", "HORIZONTAL")

  SetAttribute(lbl1, "EXPAND", "NO")
  SetAttribute(lbl2, "EXPAND", "NO")

  SetAttribute(dial2, "ACTIVE", "NO")
  SetAttribute(dial2, "SIZE", "64x16")
  SetCallback(dial2, "BUTTON_PRESS_CB", cast[Icallback](dial2_btndown_cb))
  SetCallback(dial2, "MOUSEMOVE_CB", cast[Icallback](dial2_btnup_cb))
  SetCallback(dial2, "BUTTON_RELEASE_CB", cast[Icallback](dial2_btnup_cb))

  tgg2 = Toggle("X Autoscale", nil)
  SetCallback(tgg2, "ACTION", cast[Icallback](tgg2_cb))

  f2 = Frame( Vbox(boxdial2, tgg2, nil) )
  SetAttribute(f2, "TITLE", "X Zoom")

  lbl1 = Label("")
  SetAttribute(lbl1, "SEPARATOR", "HORIZONTAL")

  tgg3 = Toggle("Vertical Grid", nil)
  SetCallback(tgg3, "ACTION", cast[Icallback](tgg3_cb))
  tgg4 = Toggle("Horizontal Grid", nil)
  SetCallback(tgg4, "ACTION", cast[Icallback](tgg4_cb))

  lbl2 = Label("")
  SetAttribute(lbl2, "SEPARATOR", "HORIZONTAL")

  tgg5 = Toggle("Legend", nil)
  SetCallback(tgg5, "ACTION", cast[Icallback](tgg5_cb))

  lbl3 = Label("")
  SetAttribute(lbl3, "SEPARATOR", "HORIZONTAL")

  bt1 = Button("Export PDF", nil)
  SetCallback(bt1, "ACTION", cast[Icallback](bt1_cb))

  vboxl = Vbox(f1, f2, lbl1, tgg3, tgg4, lbl2, tgg5, lbl3, bt1, nil)
  SetAttribute(vboxl, "GAP", "4")
  SetAttribute(vboxl, "EXPAND", "NO")

  # right panel: tabs with plots
  for ii in 0 .. MAXPLOT:
    vboxr[ii] = Vbox(plot[ii], nil) # each plot a tab
    SetfAttribute(vboxr[ii], "TABTITLE", "Plot %d", ii) # name each tab
    SetHandle(GetAttribute(vboxr[ii], "TABTITLE"), vboxr[ii])
  vboxr[MAXPLOT] = nil # mark end of vector

  tabs = Tabsv(cast[ptr PIhandle](addr vboxr))
  SetCallback(tabs, "TABCHANGE_CB", cast[Icallback](tabs_tabchange_cb))

  hbox = Hbox(vboxl, tabs, nil)
  SetAttribute(hbox, "MARGIN", "4x4")
  SetAttribute(hbox, "GAP", "10")
  
  dlg = Dialog(hbox)
  SetAttribute(dlg, "TITLE", "Plot Example")

  InitPlots() # It must be able to be done independent of dlg Mapping

  discard tabs_tabchange_cb(tabs, vboxr[0])

  SetAttribute(dlg, "SIZE", "300x")
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)
  SetAttribute(dlg, "SIZE", nil)

proc mainProc =
  niupext.Open()
  ControlsOpen()

  PlotTest()

  MainLoop()
  Close()

if isMainModule:
  mainProc()
