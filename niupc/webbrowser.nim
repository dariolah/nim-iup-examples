#
# IupWebBrowser sample
#
import niup/niupc
import niup/niupext
import strformat
import strutils

proc navigate_cb(self:PIhandle, url:cstring):int =
  echo fmt"NAVIGATE_CB: {url}\n"
  if find($url, "download") == -1:
    return IUP_IGNORE
  return IUP_DEFAULT
                   
proc error_cb(self:PIhandle, url:cstring):int =
  echo fmt"ERROR_CB: {url}\n"
  return IUP_DEFAULT

proc completed_cb(self:PIhandle, url:cstring):int =
  echo fmt"COMPLETED_CB: {url}\n"
  return IUP_DEFAULT

proc newwindow_cb(self:PIhandle, url:cstring):int =
  echo fmt"NEWWINDOW_CB: {url}\n"
  SetAttribute(self, "VALUE", url)
  return IUP_DEFAULT

proc back_cb(self:PIhandle):int =
  let web  = cast[PIhandle](GetAttribute(self, "MY_WEB"))
  SetAttribute(web, "BACKFORWARD", "-1")
  #printf("zoom=%s\n", IupGetAttribute(web, "ZOOM"));
  return IUP_DEFAULT

proc forward_cb(self:PIhandle):int =
  let web  = cast[PIhandle](GetAttribute(self, "MY_WEB"))
  SetAttribute(web, "BACKFORWARD", "1")
  #  IupSetAttribute(web, "ZOOM", "200");
  return IUP_DEFAULT

proc stop_cb(self:PIhandle):int =
  let web  = cast[PIhandle](GetAttribute(self, "MY_WEB"))
  SetAttribute(web, "STOP", nil)
  return IUP_DEFAULT

proc reload_cb(self:PIhandle):int =
  let web  = cast[PIhandle](GetAttribute(self, "MY_WEB"))
  SetAttribute(web, "RELOAD", nil)

  #TEST:
  #  printf("STATUS=%s\n", IupGetAttribute(web, "STATUS"));
  return IUP_DEFAULT

proc load_cb(self:PIhandle):int =
  let
    txt  = cast[PIhandle](GetAttribute(self, "MY_TEXT"))
    web  = cast[PIhandle](GetAttribute(self, "MY_WEB"))
  SetAttribute(web, "VALUE", GetAttribute(txt, "VALUE"))

  #TESTS:
  #  IupSetAttribute(txt, "VALUE", IupGetAttribute(web, "VALUE"));
  #  IupSetAttribute(web, "HTML", "<html><body><b>Hello</b>, World!</body></html>");
  #  IupSetAttribute(web, "VALUE", "http://www.microsoft.com");

  return IUP_DEFAULT

proc WebBrowserTest() =
  WebBrowserOpen()

  # Creates an instance of the WebBrowser control
  let
    web = WebBrowser()
    btBack = Button("Back", nil)
    btForward = Button("Forward", nil)
    txt = Text("")
    btLoad = Button("Load", nil)
    btReload = Button("Reload", nil)
    btStop = Button("Stop", nil)

  # Creates a dialog containing the control
  let dlg = Dialog(Vbox(Hbox(btBack,
                                  btForward,
                                  txt,
                                  btLoad,
                                  btReload,
                                  btStop,
                                  nil),
                                  web, nil))
  SetAttribute(dlg, "TITLE", "WebBrowser")
  SetAttribute(dlg, "MY_TEXT", cast[cstring](txt))
  SetAttribute(dlg, "MY_WEB", cast[cstring](web))
  SetAttribute(dlg, "RASTERSIZE", "800x600")
  SetAttribute(dlg, "MARGIN", "10x10")
  SetAttribute(dlg, "GAP", "10")

  #SetAttribute(web, "HTML", "<html><body><b>Hello</b>World!</body></html>")
  #SetAttribute(txt, "VALUE", "My HTML")
  SetAttribute(txt, "VALUE", "https://nim-lang.org")
  #SetAttribute(txt, "VALUE", "file:///D:/tecgraf//html/index.html")
  SetAttribute(web, "VALUE", GetAttribute(txt, "VALUE"))
  SetAttributeHandle(dlg, "DEFAULTENTER", btLoad)

  SetAttribute(txt, "EXPAND", "HORIZONTAL")
  SetCallback(btLoad, "ACTION", cast[Icallback](load_cb))
  SetCallback(btReload, "ACTION", cast[Icallback](reload_cb))
  SetCallback(btBack, "ACTION", cast[Icallback](back_cb))
  SetCallback(btForward, "ACTION", cast[Icallback](forward_cb))
  SetCallback(btStop, "ACTION", cast[Icallback](stop_cb))

  SetCallback(web, "NEWWINDOW_CB", cast[Icallback](newwindow_cb))
  SetCallback(web, "NAVIGATE_CB", cast[Icallback](navigate_cb))
  SetCallback(web, "ERROR_CB", cast[Icallback](error_cb))
  SetCallback(web, "COMPLETED_CB", cast[Icallback](completed_cb))

  #Shows dialog
  discard Show(dlg)

proc mainProc =
  niupext.Open()

  WebBrowserTest();

  MainLoop()
  Close()

if isMainModule:
  mainProc()
