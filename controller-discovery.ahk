#Requires AutoHotkey v2.0.19+
#SingleInstance Force

; Read every exposed slot. Window switching is armed by explicit confirmation.
scanXInput := 0
for dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll", "xinput1_2.dll", "xinput1_1.dll"] {
    library := DllCall("LoadLibraryExW", "WStr", dll, "Ptr", 0, "UInt", 0x800, "Ptr")
    if (!library)
        continue
    scanXInput := DllCall("GetProcAddress", "Ptr", library, "AStr", "XInputGetState", "Ptr")
    if (scanXInput)
        break
    DllCall("FreeLibrary", "Ptr", library)
}
if (A_Args.Length && A_Args[1] = "--selftest") {
    ScanDevices()
    ExitApp()
}
scanPrevious := Map()
scanReport := "XIVCrossbar discovery " . A_Now . Chr(13) . Chr(10)
scanDevicesNow := []
scanLastButton := Map()
scanPS := false
scanOrigin := 0
scanOther := 0
scanReturnUntil := 0
scanOriginPID := 0
scanOtherPID := 0
scanWindow := Gui(, "XIVCrossbar controller discovery")
scanWindow.AddText("w760", "Release all buttons, then press one on your controller. Try PS separately. Select the intended row to confirm.")
scanList := scanWindow.AddListView("w760 r8", ["API", "Slot", "Controller", "Type", "Last press"])
scanProfile := scanWindow.AddDropDownList("w280 Choose1", ["ps5", "f710", "fightpadpro", "xinput", "xinputalt"])
scanWindow.AddButton("x+12", "Confirm selected entry").OnEvent("Click", ScanConfirm)
scanWindow.AddButton("xm", "Arm selected PS input").OnEvent("Click", ScanArmPS)
scanWindow.AddButton("x+12", "Disarm PS").OnEvent("Click", (*) => ScanDisarmPS())
scanLog := scanWindow.AddEdit("xm w760 r14 ReadOnly")
scanWindow.AddButton(, "Save report").OnEvent("Click", ScanSave)
scanWindow.OnEvent("Close", (*) => ExitApp())
scanWindow.Show()
ScanTick()
SetTimer(ScanTick, 40)

ScanDevices() {
    global scanXInput
    devices := []
    Loop 16 {
        slot := A_Index
        prefix := String(slot)
        name := GetKeyState(prefix . "JoyName")
        if (name = "")
            continue
        buttons := []
        count := GetKeyState(prefix . "JoyButtons")
        Loop Min(32, IsNumber(count) ? count : 0)
            if (GetKeyState(prefix . "Joy" . A_Index))
                buttons.Push(A_Index)
        kind := RegExMatch(name, "i)dualsense|wireless controller|sony") ? "PlayStation candidate"
            : RegExMatch(name, "i)f710") ? "F710 candidate"
            : RegExMatch(name, "i)fightpad") ? "FightPad candidate" : "Confirm profile manually"
        devices.Push({key:"DI" . slot, api:"DirectInput reader", slot:slot, name:name, kind:kind, buttons:buttons})
    }
    if (scanXInput) {
        Loop 4 {
            slot := A_Index
            state := Buffer(16, 0)
            if (DllCall(scanXInput, "UInt", slot - 1, "Ptr", state, "UInt") != 0)
                continue
            buttons := []
            mask := NumGet(state, 4, "UShort")
            Loop 16
                if (mask & (1 << (A_Index - 1)))
                    buttons.Push(A_Index)
            if (NumGet(state, 6, "UChar") > 4)
                buttons.Push(17)
            if (NumGet(state, 7, "UChar") > 4)
                buttons.Push(18)
            devices.Push({key:"XI" . slot, api:"XInput", slot:slot, name:"XInput controller",
                kind:"Xbox-compatible", buttons:buttons})
        }
    }
    return devices
}

ScanTick() {
    global scanPrevious, scanList, scanDevicesNow, scanLastButton, scanPS
    devices := ScanDevices()
    signature := ""
    for device in devices
        signature .= device.key . ":" . device.name . "|"
    static previousSignature := "<initial>"
    if (signature != previousSignature) {
        scanList.Delete()
        for device in devices
            scanList.Add(, device.api, device.slot, device.name, device.kind, "")
        ScanAppend("Device list changed. Release buttons and identify your controller again.")
        previousSignature := signature
        scanPrevious := Map()
        scanLastButton := Map()
        ScanDisarmPS()
        for device in devices
            ScanAppend(device.api . " slot " . device.slot . " [" . device.name . "] " . device.kind)
    }
    for row, device in devices {
        current := Map()
        for button in device.buttons {
            current[button] := true
            if (scanPrevious.Has(device.key) && !scanPrevious[device.key].Has(button)) {
                scanLastButton[device.key] := button
                scanList.Modify(row, , device.api, device.slot, device.name, device.kind, "Button " . button)
                ScanAppend(device.api . " slot " . device.slot . " [" . device.name . "] button " . button)
                if (IsObject(scanPS) && scanPS.key = device.key && scanPS.button = button)
                    ScanSwitchPS()
            }
        }
        scanPrevious[device.key] := current
    }
    scanDevicesNow := devices
    ScanRememberWindows()
}

ScanAppend(line) {
    global scanReport, scanLog
    scanReport .= line . Chr(13) . Chr(10)
    if (StrLen(scanReport) > 60000)
        scanReport := SubStr(scanReport, -50000)
    scanLog.Value := scanReport
}

ScanConfirm(*) {
    global scanDevicesNow, scanList, scanProfile
    row := scanList.GetNext()
    if (!row || row > scanDevicesNow.Length) {
        MsgBox("Select the controller row first.")
        return
    }
    device := scanDevicesNow[row]
    selected := scanProfile.Text
    if ((device.key ~= "^XI") != (selected ~= "^xinput")) {
        MsgBox("Select an XInput profile for an XInput row, or a DirectInput profile for a DirectInput row.")
        return
    }
    command := "//xb controller profile " . selected . " " . device.slot
    if (MsgBox(device.api . " slot " . device.slot . " [" . device.name . "]"
        . Chr(10) . "Copy selection command? " . command, "Confirm controller", "YesNo") = "Yes") {
        A_Clipboard := command
        ScanAppend("Confirmed " . command)
        ScanAppend("Paste in FFXI, then check //xb nativepad status for live game polls.")
    }
}

ScanSave(*) {
    global scanReport
    path := FileSelect("S16", A_Desktop . "\XIVCrossbar-controller-discovery.txt", "Save controller report", "Text (*.txt)")
    if (path = "")
        return
    file := FileOpen(path, "w", "UTF-8")
    file.Write(scanReport)
    file.Close()
}

ScanDisarmPS() {
    global scanPS, scanReturnUntil
    scanPS := false
    scanReturnUntil := 0
}

ScanArmPS(*) {
    global scanList, scanDevicesNow, scanLastButton, scanPS
    row := scanList.GetNext()
    if (!row || row > scanDevicesNow.Length)
        return MsgBox("Press PS, then select its responding controller row.")
    device := scanDevicesNow[row]
    if (!scanLastButton.Has(device.key))
        return MsgBox("No button event has been observed on this entry. Press PS first.")
    button := scanLastButton[device.key]
    if (MsgBox("Arm " . device.api . " slot " . device.slot . " button " . button
        . " for switching between FFXI and the remembered application?"
        . Chr(10) . "Confirm only if this was the PS button. Disable the addon's PS bridge while testing.",
        "Confirm PS input", "YesNo") != "Yes")
        return
    scanPS := {key:device.key, button:button}
    ScanAppend("PS switching armed on " . device.key . " button " . button . ". Release before testing.")
}

ScanRememberWindows() {
    global scanOrigin, scanOther, scanWindow, scanOriginPID, scanOtherPID
    active := WinActive("A")
    if (!active || active = scanWindow.Hwnd)
        return
    try {
        if (WinGetClass("ahk_id " . active) = "FFXiClass")
            scanOrigin := active, scanOriginPID := WinGetPID("ahk_id " . active)
        else
            scanOther := active, scanOtherPID := WinGetPID("ahk_id " . active)
    }
}

ScanSwitchPS() {
    global scanOrigin, scanOther, scanReturnUntil, scanOriginPID, scanOtherPID
    active := WinActive("A")
    try {
        if (WinGetClass("ahk_id " . active) = "FFXiClass") {
            if (!scanOther || !WinExist("ahk_id " . scanOther)
                || WinGetPID("ahk_id " . scanOther) != scanOtherPID)
                return ScanAppend("PS observed. Focus a non-FFXI application first so it can be remembered.")
            scanOrigin := active, scanOriginPID := WinGetPID("ahk_id " . active)
            scanReturnUntil := A_TickCount + 30000
            WinActivate("ahk_id " . scanOther)
            ScanAppend("PS switched away from FFXI. Press again within 30 seconds to return.")
        } else if (scanOrigin && A_TickCount <= scanReturnUntil && WinExist("ahk_id " . scanOrigin)
            && WinGetPID("ahk_id " . scanOrigin) = scanOriginPID
            && WinGetClass("ahk_id " . scanOrigin) = "FFXiClass") {
            scanReturnUntil := 0
            WinActivate("ahk_id " . scanOrigin)
            ScanAppend("PS returned to the originating FFXI client.")
        }
    } catch Error as error {
        ScanAppend("PS switch failed: " . error.Message)
    }
}
