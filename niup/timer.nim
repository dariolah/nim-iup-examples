#/* IupTimer Example in C */

import niup

var timer1, timer2: Timer_t

proc `==`(t1: PIhandle, t2: Timer_t): bool =
  return t1 == cast[PIhandle](t2)

proc timer_cb(n: PIhandle): cint {.cdecl.} =
  if n == timer1:
    echo "timer 1 called\n"

  if n == timer2:
    echo "timer 2 called\n"
    return IUP_CLOSE
  return IUP_DEFAULT

proc MainProc() =
  Open()

  let text = Label("Timer example")

  #/* Creating main dialog */
  let dialog = Dialog(Vbox(text))
  dialog.title = "timer example"
  dialog.size(200, 200)
  ShowXY(dialog, IUP_CENTER, IUP_CENTER)

  timer1 = Timer()
  timer2 = Timer()

  timer1.time(1000)
  timer1.run(true)
  timer1.action_cb = timer_cb

  timer2.time(4000)
  timer2.run(true)
  timer2.action_cb = timer_cb

  MainLoop()

  #/* Timers are NOT automatically destroyed, must be manually done */
  Destroy(timer1)
  Destroy(timer2)
  Close()

if isMainModule:
  MainProc()
