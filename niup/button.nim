#*****************************************************************************
#*                             Button example                             *
#*   Description : Creates four buttons. The first uses images, the second   *
#*                 turns the first on and off, the third exits the           *
#*                 application and the last does nothing                     *
#*****************************************************************************/
 
import niup
import strformat

##/* Defines released button's image */
let pixmap_release =
  [
    1'u8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2,
    1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  ]

##/* Defines pressed button's image */
let pixmap_press =
  [
    1'u8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2,
    1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,4,4,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  ]

##/* Defines inactive button's image */
let pixmap_inactive =
  [
    1'u8,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2,
    1,1,3,3,3,3,3,4,4,4,4,3,3,3,2,2,
    1,1,3,3,3,3,3,3,4,4,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,1,3,3,3,3,3,3,3,3,3,3,3,3,2,2,
    1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
  ]

##/******************************************************************************
# * Function:                                                                  *
# * On off button callback                                                     *
# *                                                                            *
# * Description:                                                               *
# * Callback called when the on/off button is activated. Turns the button with *
# * image on and off                                                           *
# *                                                                            *
# * Parameters received:                                                       *
# * self - element identifier                                                  *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_on_off_cb(self: PIhandle): cint {.cdecl.} =
  ##/* IUP handles */
  let btn_image = Button_t(GetHandle( "btn_image" ))

  ##/* If the button with with image is active...*/
  if btn_image.active:
    ##/* Deactivates the button with image */
    btn_image.active = false
    ##/* else it is inactive */
  else:
    ##/* Activates the button with image */
    btn_image.active = true

  ##/* Executed function successfully */
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Button with image button callback                                          *
# *                                                                            *
# * Description:                                                               *
# * Callback called when the exit button is pressed or released. Shows a       *
# * message saying if the button was pressed or released                       *
# *                                                                            *
# * Parameters received:                                                       *
# * self - identifies the canvas that activated the function’s execution.      *
# * b    - identifies the activated mouse button:                              *
# *                                                                            *
# * IUP_BUTTON1 left mouse button (button 1)                                   *
# * IUP_BUTTON2 middle mouse button (button 2)                                 *
# * IUP_BUTTON3 right mouse button (button 3)                                  *
# *                                                                            *
# * e     - indicates the state of the button:                                 *
# *                                                                            *
# * 0 mouse button was released                                                *
# * 1 mouse button was pressed                                                 *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_image_button_cb(ih: PIhandle, button, pressed, x, y: cint, status: cstring): cint {.cdecl.} =
  ##/* If the left button changed its state... */
  if char(button) == IUP_BUTTON1:
    echo &"{char(button)} {IUP_BUTTON1} {pressed} x={x} y={y}"
    let text = Text_t(GetHandle( "text" ))
    
    ##/* If the button was pressed... */
    if pressed == 1:
      ##/* Sets text's value */
      text.value = "Red button pressed"
      ##/* else the button was released */
    else:
      ##/* Sets text's value */
      text.value = "Red button released"
  
  ##/* Executed function successfully */
  return IUP_DEFAULT

proc btn_big_button_cb(self: PIhandle, button, press, x, y: cint, status:cstring): cint {.cdecl.} =
  echo &"BUTTON_CB(button={button}, press={press})"
  echo x, y, status
  return IUP_DEFAULT

##/******************************************************************************
# * Function:                                                                  *
# * Exit button callback                                                       *
# *                                                                            *
# * Description:                                                               *
# * Callback called when exit button is activated. Exits the program           *
# *                                                                            *
# * Parameters received:                                                       *
# * self - element identifier                                                  *
# *                                                                            *
# * Value returned:                                                            *
# * IUP_DEFAULT                                                                *
# ******************************************************************************/
proc btn_exit_cb(self: PIhandle): cint {.cdecl.} =
  ##/* Exits the program */
  return IUP_CLOSE

##/******************************************************************************
# * Main function                                                              *
# ******************************************************************************/
proc mainProc() =
  ##/* Initializes IUP */
  Open(utf8Mode = true)

  ##/* Creates a text */
  let text = Text()
  text.size(100, 10)
  
  #/* Turns on read-only mode */
  text.readonly(true)
  
  #/* Associates text with handle "text" */
  SetHandle("text", text)
  
  #/* Defines released button's image size */
  let img_release = Image(16, 16, pixmap_release)

  #/* Defines released button's image colors */
  img_release["1"] = "215 215 215"
  img_release["2"] = "40 40 40"
  img_release["3"] = "30 50 210"
  img_release["4"] = "240 0 0"
  
  #/* Defines pressed button's image size */
  let img_press = Image( 16, 16, pixmap_press)
  
  #/* Defines pressed button's image colors */
  img_press["1"] = "40 40 40"
  img_press["2"] = "215 215 215"
  img_press["3"] = "0 20 180"
  img_press["4"] = "210 0 0"
  
  #/* Defines inactive button's image size */
  let img_inactive = Image( 16, 16, pixmap_inactive)
  
  #/* Defines inactive button's image colors */
  img_inactive["1"] = "215 215 215"
  img_inactive["2"] = "40 40 40"
  img_inactive["3"] = "100 100 100"
  img_inactive["4"] = "200 200 200"
  
  #/* Creates a button */
  let btn_image = Button("Button with image")
  
  #/* Sets released, pressed and inactive button images */
  btn_image.image = img_release
  btn_image.impress = img_press
  btn_image.iminactive = img_inactive
  
  #/* Associates btn_image with handle "btn_image" */
  SetHandle( "btn_image", btn_image )

  #/* Creates a button */
  let btn_big = Button( "Big useless button")
  
  #/* Sets big button size */
  btn_big.size = "EIGHTHxEIGHTH"
  # WORKS also btn_big.size(100, 100)
  
  #/* Creates a button entitled Exit associated with action exit_act */
  let btn_exit = Button( "Exit")
  
  #/* Creates a button entitled on/off associated with action onoff_act */
  let btn_on_off = Button( "on/off")

  #/* Creates dialog with the four buttons and the text*/
  let dlg = Dialog(
              Vbox(
                Hbox(btn_image, btn_on_off, btn_exit),
                text,
                btn_big))
  
  #/* Sets dialogs title to Button turns resize, maximize, minimize and    */
  #/* menubox off                                                             */
  dlg.expand = "YES"
  dlg.title = "Button"
  dlg.resize = false
  dlg.menubox = false
  dlg.maxbox = false
  dlg.minbox = false

  #/* Registers callbacks */
  btn_exit.action = btn_exit_cb
  btn_on_off.action = btn_on_off_cb
  btn_image.button_cb = btn_image_button_cb
  btn_big.button_cb = btn_big_button_cb
  
  #/* Shows dialog on the center of the screen */
  ShowXY( dlg, IUP_CENTER, IUP_CENTER )
    
  #/* Initializes IUP main loop */
  MainLoop()

  #/* Finishes IUP */
  Close()

if isMainModule:
  mainProc()
