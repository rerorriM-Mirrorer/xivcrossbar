#Requires AutoHotkey v2.0.19+
#SingleInstance Ignore
; Manual diagnostic only; never launched by XIVCrossbar.
SetKeyDelay(10, -1)
probeOwner := 0, probeKeyOwned := false, probeAppsOwned := false, probeKey := ""
OnExit(ProbeExit)
probeGui := Gui(, "XIVCrossbar keyboard probe")
probeGui.AddText(, "Choose a key, then send one pulse to the latest FFXI window.")
choice := probeGui.AddDropDownList("w230 Choose3", ["F13","F14","F15","F16","F17","F18","F19","F20","F21","F22","F23","F24","Kana","Convert","Nonconvert","Browser Back","Browser Forward","Browser Favorites"])
useApps := probeGui.AddCheckbox(, "Include Apps modifier")
probeGui.AddButton("Default", "Send to FFXI").OnEvent("Click", ProbeSend)
probeGui.AddText(, "Controller device for button discovery (normally 1):")
device := probeGui.AddEdit("Number w50", "1")
watch := probeGui.AddCheckbox(, "Watch controller button numbers (read only)")
watch.OnEvent("Click", ProbeWatch)
hardwareStatus := probeGui.AddText("w400", "Button discovery is off.")
probeGui.AddText("w360", "Stop the controller wrapper for isolated testing. International/browser keys may have native effects. No power or media-launch keys are included.")
probeGui.OnEvent("Close", (*) => ExitApp())
probeGui.Show()

ProbeWatch(*) {
    global
    if (!IsNumber(device.Value) or device.Value < 1 or device.Value > 16 or Mod(device.Value, 1))
        watch.Value := 0
    SetTimer(ProbeHardware, watch.Value ? 20 : 0)
    if (!watch.Value) {
        hardwareStatus.Text := "Button discovery is off."
        ToolTip(, , , 2)
    }
}
ProbeHardware() {
    global
    prefix := device.Value = 1 ? "" : device.Value
    name := GetKeyState(prefix . "JoyName")
    count := GetKeyState(prefix . "JoyButtons")
    count := count = "" ? 0 : count + 0
    held := ""
    Loop Min(32, count)
        if GetKeyState(prefix . "Joy" . A_Index)
            held .= (held = "" ? "" : ", ") . "Joy" . A_Index
    message := name = "" ? "Controller not detected on device " . device.Value
        : "Buttons=" . count . " | held: " . (held = "" ? "none (released)" : held)
    hardwareStatus.Text := message
    if WinActive("ahk_class FFXiClass")
        ToolTip(message, , , 2)
    else
        ToolTip(, , , 2)
}
ProbeSend(*) {
    global
    if (probeOwner)
        return
    probeOwner := WinExist("ahk_class FFXiClass")
    if (!probeOwner) {
        MsgBox("No FFXI window was found.", "Key probe", 48)
        return
    }
    signals := Map("Kana","vk15sc070", "Convert","vk1Csc079", "Nonconvert","vk1Dsc07B",
        "Browser Back","Browser_Back", "Browser Forward","Browser_Forward", "Browser Favorites","Browser_Favorites")
    probeKey := signals.Get(choice.Text, choice.Text)
    WinActivate("ahk_id " . probeOwner)
    SetTimer(ProbePulse, -300)
}
ProbePulse() {
    global
    if (WinActive("ahk_class FFXiClass") != probeOwner) {
        probeOwner := 0
        return
    }
    if (useApps.Value and !GetKeyState("AppsKey", "P")) {
        probeAppsOwned := true
        SendEvent("{Blind}{AppsKey down}")
    }
    if (!GetKeyState(probeKey, "P")) {
        probeKeyOwned := true
        SendEvent("{Blind}{" . probeKey . " down}")
    }
    ToolTip(choice.Text . " | VK=" . GetKeyVK(probeKey) . " SC=" . GetKeySC(probeKey))
    SetTimer(ProbeReleaseKeys, -40)
    SetTimer(() => ToolTip(), -1500)
}
^!F12::ExitApp
ProbeExit(*) {
    ProbeReleaseKeys()
    return 0
}
ProbeReleaseKeys() {
    global
    if (!probeOwner)
        return
    for _, entry in [{key:probeKey, owned:probeKeyOwned}, {key:"AppsKey", owned:probeAppsOwned}] {
        key := entry.key, owned := entry.owned
        if (!owned or GetKeyState(key,"P"))
            continue
        if (WinActive("ahk_class FFXiClass") = probeOwner)
            SendEvent("{Blind}{" . key . " up}")
        else if WinExist("ahk_id " . probeOwner)
            try ControlSend("{" . key . " up}", , "ahk_id " . probeOwner)
    }
    probeKeyOwned := false, probeAppsOwned := false, probeOwner := 0
}
