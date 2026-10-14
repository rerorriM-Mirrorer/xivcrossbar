#Requires AutoHotkey v1.1.33+
#SingleInstance Ignore
; A: manual, optional probe. It is never launched by XIVCrossbar.
; Send one selected signal to the most recently active FFXI window only.
OnExit, ProbeExit
probeOwner := 0
probeKeyOwned := false
probeAppsOwned := false
choices := "F13|F14|F15||F16|F17|F18|F19|F20|F21|F22|F23|F24|Kana|Convert|Nonconvert|Browser Back|Browser Forward|Browser Favorites"
Gui, Add, Text,, Choose a key, then send one pulse to the latest FFXI window.
Gui, Add, DropDownList, vProbeChoice w230, %choices%
Gui, Add, Checkbox, vUseApps, Include Apps modifier
Gui, Add, Button, gProbeSend Default, Send to FFXI
Gui, Add, Text,, Controller device for button discovery (normally 1):
Gui, Add, Edit, vProbeDevice Number w50, 1
Gui, Add, Checkbox, vWatchButtons gProbeWatch, Watch controller button numbers (read only)
Gui, Add, Text, vHardwareStatus w400, Button discovery is off.
Gui, Add, Text, w360, Stop the controller wrapper for isolated testing. International/browser keys may have native effects. No power or media-launch keys are included.
Gui, Show,, XIVCrossbar keyboard probe
return

ProbeWatch:
Gui, Submit, NoHide
if (ProbeDevice < 1 or ProbeDevice > 16 or Mod(ProbeDevice,1)) {
    GuiControl,, WatchButtons, 0
    WatchButtons := false
}
SetTimer, ProbeHardware, % WatchButtons ? 20 : "Off"
if (!WatchButtons) {
    GuiControl,, HardwareStatus, Button discovery is off.
    ToolTip,,,, 2
}
return

ProbeHardware:
prefix := ProbeDevice = 1 ? "" : ProbeDevice
name := GetKeyState(prefix . "JoyName")
count := GetKeyState(prefix . "JoyButtons") + 0
held := ""
Loop, % Min(32,count) {
    if GetKeyState(prefix . "Joy" . A_Index)
        held .= (held = "" ? "" : ", ") . "Joy" . A_Index
}
message := name = "" ? "Controller not detected on device " . ProbeDevice
    : "Buttons=" . count . " | held: " . (held = "" ? "none (released)" : held)
GuiControl,, HardwareStatus, %message%
if WinActive("ahk_class FFXiClass")
    ToolTip, %message%,,, 2
else
    ToolTip,,,, 2
return

ProbeSend:
if (probeOwner)
    return
Gui, Submit, NoHide
probeOwner := WinExist("ahk_class FFXiClass")
if (!probeOwner) {
    MsgBox, 48, Key probe, No FFXI window was found.
    return
}
signals := {"Kana":"vk15sc070", "Convert":"vk1Csc079", "Nonconvert":"vk1Dsc07B"
    , "Browser Back":"Browser_Back", "Browser Forward":"Browser_Forward", "Browser Favorites":"Browser_Favorites"}
probeKey := signals.HasKey(ProbeChoice) ? signals[ProbeChoice] : ProbeChoice
WinActivate, ahk_id %probeOwner%
SetTimer, ProbePulse, -300
return

ProbePulse:
if (WinActive("ahk_class FFXiClass") != probeOwner) {
    probeOwner := 0
    return
}
if (UseApps and !GetKeyState("AppsKey", "P")) {
    probeAppsOwned := true
    SendEvent, {Blind}{AppsKey down}
}
if (!GetKeyState(probeKey, "P")) {
    probeKeyOwned := true
    SendEvent, % "{Blind}{" . probeKey . " down}"
}
ToolTip, % ProbeChoice . " | VK=" . GetKeyVK(probeKey) . " SC=" . GetKeySC(probeKey)
SetTimer, ProbeRelease, -40
SetTimer, ProbeClearTip, -1500
return

ProbeRelease:
ProbeReleaseKeys()
return

ProbeClearTip:
ToolTip
return

GuiClose:
ExitApp

^!F12::ExitApp

ProbeExit:
ProbeReleaseKeys()
ExitApp

ProbeReleaseKeys() {
    global probeOwner, probeKeyOwned, probeAppsOwned, probeKey
    if (!probeOwner)
        return
    for _, entry in [{key:probeKey, owned:probeKeyOwned}, {key:"AppsKey", owned:probeAppsOwned}] {
        key := entry.key, owned := entry.owned
        if (!owned or GetKeyState(key,"P"))
            continue
        if (WinActive("ahk_class FFXiClass") = probeOwner)
            SendEvent, % "{Blind}{" . key . " up}"
        else if WinExist("ahk_id " . probeOwner)
            ControlSend,, % "{" . key . " up}", ahk_id %probeOwner%
    }
    probeKeyOwned := false, probeAppsOwned := false, probeOwner := 0
}
