; Run every line
Critical

#SingleInstance force

; Switch windows instantaeously
SetWinDelay -1

; Avoid warning dialogue about over-hits
#MaxHotkeysPerInterval 50000
#HotkeyInterval, 1
#WinActivateForce
SetWorkingDir, %A_ScriptDir%

IniRead, ButtonLayout, config.ini, ButtonMap, ButtonLayout
IniRead, ConfirmButton, config.ini, ButtonMap, ConfirmButton
IniRead, CancelButton, config.ini, ButtonMap, CancelButton
IniRead, MainMenuButton, config.ini, ButtonMap, MainMenuButton
IniRead, ActiveWindowButton, config.ini, ButtonMap, ActiveWindowButton
StringUpper, ButtonLayout, ButtonLayout
StringUpper, ConfirmButton, ConfirmButton
StringUpper, CancelButton, CancelButton
StringUpper, MainMenuButton, MainMenuButton
StringUpper, ActiveWindowButton, ActiveWindowButton

lastKeyPressed := ""
isLeftTriggerDown := false
isRightTriggerDown := false
isEnvironmentDialogOpen := false

; Measured DirectInput button numbers, separate from the existing ButtonMap.
; Oct. 2 DualSense measurements: L1=Joy5, L3=Joy11. Zero disables either.
; Windows shoulder injection has not passed the live test; default it off.
IniRead, L1Joy, controller-extras.ini, Controller, L1Joy, 5
IniRead, L3Joy, controller-extras.ini, Controller, L3Joy, 11
IniRead, ShouldersEnabled, controller-extras.ini, Controller, ShouldersEnabled, 0
if (ShouldersEnabled != 0 and ShouldersEnabled != 1) {
  MsgBox, 16, XIVCrossbar, Invalid controller-extras.ini: ShouldersEnabled must be 0 or 1.
  ExitApp
}
if (!ValidExtraJoy(L1Joy) or !ValidExtraJoy(L3Joy) or (L1Joy and L1Joy = L3Joy)) {
  MsgBox, 16, XIVCrossbar, Invalid controller-extras.ini: use distinct Joy5 or Joy11-Joy32 numbers (0 disables).
  ExitApp
}
r1WasDown := GetKeyState("Joy6")
l1WasDown := L1Joy ? GetKeyState("Joy" . L1Joy) : false
l3WasDown := L3Joy ? GetKeyState("Joy" . L3Joy) : false
l3ArmedWindow := 0
SetTimer, CheckControllerExtras, 10

#Persistent  ; Keep this script running until the user explicitly exits it.
SetTimer, CheckPOVState, 10 ; Poll for POV hat every 10ms

CheckPOVState:
If WinActive("ahk_class FFXiClass") {
  GetKeyState, joyp, JoyPOV

  If (isLeftTriggerDown or isRightTriggerDown or isEnvironmentDialogOpen) {
    If (joyp == 0) {
      If (lastKeyPressed != "dpad_up") {
        SendInput {f1}

        lastKeyPressed:= "dpad_up"
      }
    } else If (joyp == 9000) {
      If (lastKeyPressed != "dpad_right") {
        SendInput {f2}

        lastKeyPressed:= "dpad_right"
      }
    } else If (joyp == 18000) {
      If (lastKeyPressed != "dpad_down") {
        SendInput {f3}

        lastKeyPressed:= "dpad_down"
      }
    } else If (joyp == 27000) {
      If (lastKeyPressed != "dpad_left") {
        SendInput {f4}

        lastKeyPressed:= "dpad_left"
      }
    }
  }

  If (joyp == -1 and lastKeyPressed != "") {
      lastKeyPressed:= ""
  }
}
return

; Helper subroutines. *DON'T* modify these to remap, instead just change which buttons call them
SendConfirmKey:
	If !WinActive("ahk_class FFXiClass") {
		WinActivate, ahk_class FFXiClass
		sleep 250
	}
	SendInput {Enter}
return
SendCancelKey:
	If !WinActive("ahk_class FFXiClass") {
		WinActivate, ahk_class FFXiClass
		sleep 250
	}
	SendInput {Esc}
return
SendMainMenuKey:
	If !WinActive("ahk_class FFXiClass") {
		WinActivate, ahk_class FFXiClass
		sleep 250
	}
	SendInput {NumpadSub}
return
SendActiveWindowKey:
	If !WinActive("ahk_class FFXiClass") {
		WinActivate, ahk_class FFXiClass
		sleep 250
	}
	SendInput {NumpadAdd}
return

; Gamecube Y Button (Playstation Triangle, Xbox Y Button, Nintendo X Button, TOP face button)
Joy4::
;If WinActive("ahk_class FFXiClass") {
  If (isLeftTriggerDown or isRightTriggerDown) {
    SendInput {f8}
  } else {
    If (ButtonLayout == "GAMECUBE" or ButtonLayout == "XBOX") {
      If (ConfirmButton == "Y") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "Y") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "Y") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "Y") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "PLAYSTATION") {
      If (ConfirmButton == "TRIANGLE") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "TRIANGLE") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "TRIANGLE") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "TRIANGLE") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "NINTENDO") {
      If (ConfirmButton == "X") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "X") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "X") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "X") {
        Gosub, SendActiveWindowKey
      }
    }
  }
;}
return

; Gamecube B Button (Playstation Square, Xbox X Button, Nintendo Y Button, LEFT face button)
Joy1::
;If WinActive("ahk_class FFXiClass") {
  If (isLeftTriggerDown or isRightTriggerDown) {
    SendInput {f6}
  } else {
    If (ButtonLayout == "GAMECUBE") {
      If (ConfirmButton == "B") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "B") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "B") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "B") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "XBOX") {
      If (ConfirmButton == "X") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "X") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "X") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "X") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "PLAYSTATION") {
      If (ConfirmButton == "SQUARE") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "SQUARE") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "SQUARE") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "SQUARE") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "NINTENDO") {
      If (ConfirmButton == "Y") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "Y") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "Y") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "Y") {
        Gosub, SendActiveWindowKey
      }
    }
  }
;}
return

; Gamecube A Button (Playstation Cross, Xbox A Button, Nintendo B Button, BOTTOM face button)
Joy2::
;If WinActive("ahk_class FFXiClass") {
  If (isLeftTriggerDown or isRightTriggerDown) {
    SendInput {f5}
  } else {
    If (ButtonLayout == "GAMECUBE" or ButtonLayout == "XBOX") {
      If (ConfirmButton == "A") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "A") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "A") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "A") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "PLAYSTATION") {
      If (ConfirmButton == "CROSS") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "CROSS") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "CROSS") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "CROSS") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "NINTENDO") {
      If (ConfirmButton == "B") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "B") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "B") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "B") {
        Gosub, SendActiveWindowKey
      }
    }
  }
;}
return

; Gamecube X Button (Playstation Circle, Xbox B Button, Nintendo A Button, RIGHT face button)
Joy3::
;If WinActive("ahk_class FFXiClass") {
  If (isLeftTriggerDown or isRightTriggerDown) {
    SendInput {f7}
  } else {
    If (ButtonLayout == "GAMECUBE") {
      If (ConfirmButton == "X") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "X") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "X") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "X") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "XBOX") {
      If (ConfirmButton == "B") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "B") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "B") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "B") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "PLAYSTATION") {
      If (ConfirmButton == "CIRCLE") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "CIRCLE") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "CIRCLE") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "CIRCLE") {
        Gosub, SendActiveWindowKey
      }
    } else If (ButtonLayout == "NINTENDO") {
      If (ConfirmButton == "A") {
        Gosub, SendConfirmKey
      } else If (CancelButton == "A") {
        Gosub, SendCancelKey
      } else If (MainMenuButton == "A") {
        Gosub, SendMainMenuKey
      } else If (ActiveWindowButton == "A") {
        Gosub, SendActiveWindowKey
      }
    }
  }
;}
return

; Left Trigger
Joy7::
If WinActive("ahk_class FFXiClass") {
  SendInput {Ctrl down}
  SendInput {f11 down}
  isLeftTriggerDown := true
  SetTimer, WaitForButtonUp7, 10 ; Poll for button setting every 10ms
}
return

WaitForButtonUp7:
If WinActive("ahk_class FFXiClass") {
  if GetKeyState("Joy7")  ; The button is still, down, so keep waiting.
      return
  ; Otherwise, the button has been released.
  SendInput {f11 up}
  if !isRightTriggerDown {
	SendInput {Ctrl Down}
    SendInput {Ctrl up}
  }
  isLeftTriggerDown := false
  SetTimer, WaitForButtonUp7, Off ; Turn off polling
  ;ReleaseCtrl()
}
return

; Right Trigger
Joy8::
If WinActive("ahk_class FFXiClass") {
  SendInput {Ctrl down}
  SendInput {f12 down}
  isRightTriggerDown := true
  SetTimer, WaitForButtonUp8, 10 ; Poll for button setting every 10ms
}
return

WaitForButtonUp8:
If WinActive("ahk_class FFXiClass") {
  if GetKeyState("Joy8")  ; The button is still, down, so keep waiting.
      return
  ; Otherwise, the button has been released.
  SendInput {f12 up}
  if !isLeftTriggerDown {
	SendInput {Ctrl Down}
    SendInput {Ctrl up}
  }
  isRightTriggerDown := false
  SetTimer, WaitForButtonUp8, Off ; Turn off polling
  ;ReleaseCtrl()

}
return

ReleaseCtrl() {
    ;sleep 20
	Loop, 2 {
		SendInput {Ctrl Down}
		sleep 20
		SendInput {Ctrl Up}
	}
	return
}

#t::
loop, 50 {
 SendInput {Ctrl Down}
 SendInput {Ctrl Up}
 }
return


; Opens/closes gamepad binding dialog
Joy9::
If WinActive("ahk_class FFXiClass") {
  SendInput {Ctrl down}
  SendInput {f9 down}
  SetTimer, WaitForButtonUp9, 10 ; Poll for button setting every 10ms
}
return

WaitForButtonUp9:
If WinActive("ahk_class FFXiClass") {
  if GetKeyState("Joy9")  ; The button is still, down, so keep waiting.
      return
  ; Otherwise, the button has been released.
  SendInput {f9 up}
  SendInput {Ctrl up}
  SetTimer, WaitForButtonUp9, Off ; Turn off polling
}
return

; Shows the environment list
Joy10::
If WinActive("ahk_class FFXiClass") {
  SendInput {Ctrl down}
  SendInput {f10 down}
  isEnvironmentDialogOpen := true
  SetTimer, WaitForButtonUp10, 10 ; Poll for button setting every 10ms
}
return

WaitForButtonUp10:
If WinActive("ahk_class FFXiClass") {
  if GetKeyState("Joy10")  ; The button is still, down, so keep waiting.
      return
  ; Otherwise, the button has been released.
  SendInput {f10 up}
  SendInput {Ctrl up}
  isEnvironmentDialogOpen := false
  SetTimer, WaitForButtonUp10, Off ; Turn off polling
}
return

; Rising-edge shoulder taps; L3 switches only on its falling edge.
; Polling avoids hold-repeat and does not block the existing trigger timers.
CheckControllerExtras:
activeFFXI := WinActive("ahk_class FFXiClass")
r1Down := GetKeyState("Joy6")
l1Down := L1Joy ? GetKeyState("Joy" . L1Joy) : false
l3Down := L3Joy ? GetKeyState("Joy" . L3Joy) : false
if (GetKeyState("JoyName") = "") {
  l3ArmedWindow := 0
  r1WasDown := r1Down
  l1WasDown := l1Down
  l3WasDown := l3Down
  return
}
if (activeFFXI and ShouldersEnabled) {
  if (r1Down and !r1WasDown) {
    SendInput {Tab}
  }
  if (l1Down and !l1WasDown) {
    SendInput +{Tab}
  }
}
if (l3Down and !l3WasDown) {
  l3ArmedWindow := activeFFXI
}
; A manual focus change during the hold cancels the pending switch.
if (l3ArmedWindow and activeFFXI != l3ArmedWindow) {
  l3ArmedWindow := 0
}
if (!l3Down and l3WasDown) {
  ; Do not carry a held trigger/menu/modifier into another client.
  if (l3ArmedWindow and !isLeftTriggerDown and !isRightTriggerDown
      and !isEnvironmentDialogOpen and !GetKeyState("Joy9")
      and !GetKeyState("Ctrl") and !GetKeyState("Shift") and !GetKeyState("Alt")) {
    Gosub, ActivateNextFFXI
  }
  l3ArmedWindow := 0
}
r1WasDown := r1Down
l1WasDown := l1Down
l3WasDown := l3Down
return

ActivateNextFFXI:
; HWND ordering stays stable as focus changes; Z-order would just toggle two.
WinGet, ffxiWindows, List, ahk_class FFXiClass
windowOrder := ""
Loop, %ffxiWindows% {
  windowId := ffxiWindows%A_Index%
  windowOrder .= (windowId + 0) . "`n"
}
Sort, windowOrder, N
firstWindow := 0
nextWindow := 0
foundCurrent := false
Loop, Parse, windowOrder, `n, `r
{
  if (A_LoopField = "")
    continue
  windowId := A_LoopField + 0
  if (!firstWindow)
    firstWindow := windowId
  if (foundCurrent) {
    nextWindow := windowId
    break
  }
  if (windowId = l3ArmedWindow)
    foundCurrent := true
}
if (!nextWindow and foundCurrent)
  nextWindow := firstWindow
if (nextWindow and nextWindow != l3ArmedWindow)
  WinActivate, ahk_id %nextWindow%
return

ValidExtraJoy(button) {
  return RegExMatch(button, "^\d+$") and (button = 0 or button = 5 or (button >= 11 and button <= 32))
}
