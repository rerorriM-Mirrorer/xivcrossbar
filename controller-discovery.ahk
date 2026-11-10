#Requires AutoHotkey v2.0.19+
#SingleInstance Force

; Diagnostic only. Read all slots exposed by the existing readers.
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
scanWindow := Gui(, "XIVCrossbar controller discovery")
scanWindow.AddText("w760", "Release all buttons, then press one on your controller. Try PS separately. Select the intended row to confirm.")
scanList := scanWindow.AddListView("w760 r8", ["API", "Slot", "Controller", "Type", "Last press"])
scanProfile := scanWindow.AddDropDownList("w280 Choose1", ["ps5", "f710", "fightpadpro", "xinput", "xinputalt"])
scanWindow.AddButton("x+12", "Confirm selected entry").OnEvent("Click", ScanConfirm)
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
    global scanPrevious, scanList, scanDevicesNow
    devices := ScanDevices()
    signature := ""
    for device in devices
        signature .= device.key . ":" . device.name . "|"
    static previousSignature := ""
    if (signature != previousSignature) {
        scanList.Delete()
        for device in devices
            scanList.Add(, device.api, device.slot, device.name, device.kind, "")
        ScanAppend("Device list changed. Release buttons and identify your controller again.")
        previousSignature := signature
        scanPrevious := Map()
    }
    for row, device in devices {
        current := Map()
        for button in device.buttons {
            current[button] := true
            if (scanPrevious.Has(device.key) && !scanPrevious[device.key].Has(button)) {
                scanList.Modify(row, , device.api, device.slot, device.name, device.kind, "Button " . button)
                ScanAppend(device.api . " slot " . device.slot . " [" . device.name . "] button " . button)
            }
        }
        scanPrevious[device.key] := current
    }
    scanDevicesNow := devices
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
