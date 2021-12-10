##/*Multiline Advanced Example in C
#Shows a dialog with a multiline, a text, a list and some buttons. You can test the multiline attributes by clicking on the buttons. Each button is related to an attribute. Select if you want to set or get an attribute using the dropdown list. The value in the text will be used as value when a button is pressed. */

##/* MultiLine example */

import niup
import strformat

##/******************************************************************************
# * Function:                                                                  *
# * Set Attribute                                                              *
# *                                                                            *
# * Description:                                                               *
# * Sets an attribute with the value in the text                               *
# *                                                                            *
# * Parameters received:                                                       *
# * attribute - attribute to be set                                            *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc set_attribute(attribute: string) =
  let
    mltline = MultiLine_t(GetHandle("mltline"))
    text = Text_t(GetHandle("text"))
  mltline[attribute] = text["VALUE"]

  let string_message = &"Attribute {attribute} set with value {text[\"VALUE\"]}"
  Message("Set attribute", string_message)

##/******************************************************************************
# * Function:                                                                  *
# * Get attribute                                                              *
# *                                                                            *
# * Description:                                                               *
# * Get an attribute of the multiline and shows it in the text                 *
# *                                                                            *
# * Parameters received:                                                       *
# * attribute - attribute to be get                                            *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc get_attribute(attribute: string) =
  let
    mltline = MultiLine_t(GetHandle("mltline"))
    text = Text_t(GetHandle("text"))
  text["VALUE"] = mltline[attribute]

  let string_message = &"Attribute {attribute} get with value {text[\"VALUE\"]}"
  Message("Get attribute", string_message)

##/******************************************************************************
# * Functions:                                                                 *
# * Append button callback                                                     *
# *                                                                            *
# * Description:                                                               *
# * Appends text to the multiline. Value: text to be appended                  *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_append_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("APPEND")
  else:
    get_attribute("APPEND")
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Insert button callback                                                     *
# *                                                                            *
# * Description:                                                               *
# * Inserts text in the multiline. Value: text to be inserted                  *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_insert_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("INSERT")
  else:
    get_attribute("INSERT")
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Border button callback                                                     *
# *                                                                            *
# * Description:                                                               *
# * Border of the multiline. Value: "YES" or "NO"                              *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_border_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("BORDER")
  else:
    get_attribute("BORDER")
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Caret button callback                                                      *
# *                                                                            *
# * Description:                                                               *
# * Position of the caret. Value: lin,col                                      *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_caret_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("CARET")
  else:
    get_attribute("CARET")
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Read-only button callback                                                  *
# *                                                                            *
# * Description:                                                               *
# * Readonly attribute. Value: "YES" or "NO"                                   *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_readonly_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("READONLY")
  else:
    get_attribute("READONLY")
  return IUP_DEFAULT

#/******************************************************************************
# * Function:                                                                  *
# * Selection button callback                                                  *
# *                                                                            *
# * Description:                                                               *
# * Changes the selection attribute. Value: lin1,col1:lin2,col2                *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_selection_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("SELECTION")
  else:
    get_attribute("SELECTION")
  return IUP_DEFAULT

#/******************************************************************************
# * Function:                                                                  *
# * Selected text button callback                                              *
# *                                                                            *
# * Description:                                                               *
# * Changes the selected text attribute. Value: lin1,col1:lin2,col2            *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_selectedtext_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("SELECTEDTEXT")
  else:
    get_attribute("SELECTEDTEXT")
  return IUP_DEFAULT

#/******************************************************************************
# * Function:                                                                  *
# * Number of characters button callback                                       *
# *                                                                            *
# * Description:                                                               *
# * Limit number of characters in the multiline                                *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_nc_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("NC")
  else:
    get_attribute("NC")
  return IUP_DEFAULT

#/******************************************************************************
# * Function:                                                                  *
# * Vaue button callback                                                       *
# *                                                                            *
# * Description:                                                               *
# * Text in the multiline.
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_value_cb(ih: PIhandle): cint {.cdecl.} =
  let list = List_t(GetHandle("list"))

  if GetInt(list, "VALUE") == 1:
    set_attribute("VALUE")
  else:
    get_attribute("VALUE")
  return IUP_DEFAULT

#/* Main program */
proc Main() =
  #/* Initializes IUP */
  Open()

  #/* Program begin */

  #/* Creates a multiline, a text and a list*/
  let
    mltline = MultiLine()
    text = Text()
    list = List()

  #/* Turns on multiline expand ans text horizontal expand */
  mltline.expand = "YES"
  text.expand = "YES"

  #/* Associates handles to multiline, text and list */
  SetHandle("mltline", mltline)
  SetHandle("text", text)
  SetHandle("list", list)

  #/* Sets list items and dropdown */
  SetAttributes(list, "1 = SET, 2 = GET, DROPDOWN = YES, VALUE=2")

  #/* Creates buttons */
  let
    btn_append = Button("Append")
    btn_insert = Button("Insert")
    btn_border = Button("Border")
    btn_caret = Button("Caret")
    btn_readonly = Button("Read only")
    btn_selection = Button("Selection")
    btn_selectedtext = Button("Selected Text")
    btn_nc = Button("Number of characters")
    btn_value = Button("Value")

  #/* Registers callbacks */
  btn_append.action = btn_append_cb
  btn_insert.action = btn_insert_cb
  btn_border.action = btn_border_cb
  btn_caret.action = btn_caret_cb
  btn_readonly.action = btn_readonly_cb
  btn_selection.action = btn_selection_cb
  btn_selectedtext.action = btn_selectedtext_cb
  btn_nc.action = btn_nc_cb
  btn_value.action = btn_value_cb

  #/* Creates dialog */
  let dlg = Dialog(Vbox(mltline,
                     Hbox(text, list),
                     Hbox(btn_append, btn_insert, btn_border, btn_caret, btn_readonly, btn_selection),
                     Hbox(btn_selectedtext, btn_nc, btn_value),
                     ))

  #/* Sets title and size of the dialog */
  SetAttributes(dlg, "TITLE=\"MultiLine Example\", SIZE=HALFxQUARTER")

  #/* Shows dialog in the center of the screen */
  ShowXY(dlg, IUP_CENTER, IUP_CENTER)

  #/* Initializes IUP main loop */
  MainLoop()

  #/* Finishes IUP */
  Close()

if isMainModule:
  Main()
