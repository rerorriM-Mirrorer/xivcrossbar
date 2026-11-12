#Requires AutoHotkey v2.0.19+
; A: shared controller transport; physical readers are selected at startup.
; All profiles share one DirectLink message stream.
#SingleInstance Off
#Include %A_ScriptDir%\controller_messages.ahk
#Include %A_ScriptDir%\controller_bridge.ahk
#Include %A_ScriptDir%\controller_diagnostics.ahk
#Include %A_ScriptDir%\controller_clients.ahk
#Include %A_ScriptDir%\controller_mappings.ahk
#Include %A_ScriptDir%\controller_slots.ahk
allSlotsTest := true ; All slots of the selected profile backend, including normal startup.
slotScan := {armed:Map(), signature:"unobserved", connected:"", active:""}
SetWorkingDir(A_ScriptDir)
instanceMutex := AcquireWrapperMutex()
if (!instanceMutex)
    ExitApp()
DirCreate(A_ScriptDir . "\data")
; Manual test launch owns the same mutex, so it can clear a stale stop marker
; only after the old reader has actually exited.
if (allSlotsTest) {
    try FileDelete(A_ScriptDir . "\data\input-stop.request")
}
; A: one shared process; select transport only at startup, never mid-hold.
profileArgument := A_Args.Length >= 2 ? A_Args[2] : ""
deviceArgument := A_Args.Length >= 3 ? A_Args[3] : ""
; A: use a validated startup handoff if the launcher drops script arguments.
origin := "arguments"
if (profileArgument = "") {
    launchFile := A_ScriptDir . "\data\controller-launch.ini"
    if FileExist(launchFile) {
        profileArgument := IniRead(launchFile, "Controller", "profile", "ps5-directinput")
        deviceArgument := IniRead(launchFile, "Controller", "device", "1")
        origin := "launch-file"
    } else {
        origin := "default"
    }
}
profile := profileArgument != "" ? profileArgument : "ps5-directinput"
device := deviceArgument = "" ? 1 : (IsInteger(deviceArgument) ? Integer(deviceArgument) : 0)
isXInput := (profile = "xinput" or profile = "xinput-r1-chooser")
validProfile := isXInput or profile = "ps5-directinput" or profile = "f710-directinput" or profile = "fightpadpro-directinput"
if (!validProfile or device < 1 or device > (isXInput ? 4 : 16) or Mod(device, 1))
    ExitApp()
joystickPrefix := device = 1 ? "" : String(device)
xinputLibrary := 0
xinputGetState := 0
xinputFault := false
connected := false
phase := "starting"
lastStatusTick := -1000
if (isXInput)
    xinputFault := !InitXInput()
joys := isXInput ? [] : ControllerDirectInputButtons(profile)
owner := 0
ready := false
ControllerMessageInit()
BridgeInit()
DiagInit()
WrapperClientsInit()
WriteTransportStatus(true)
OnExit(TransportExit)
SetTimer(TransportPoll, 10)

TransportPoll() {
    global owner, ready, phase, connected, xinputFault, CB, HO
    Critical("On")
    if WrapperClientsShouldExit()
        ExitApp()
    if FileExist(A_ScriptDir . "\data\input-stop.request") {
        try FileDelete(A_ScriptDir . "\data\input-stop.request")
        catch Error
            return  ; The writer may still hold the request open. Retry next poll.
        ExitApp()
    }
    active := WinActive("ahk_class FFXiClass")
    DiagTick(active)
    DiagStage("start")
    if (!active) {
        HO.pending := false
        BridgeOutside()
        ReleaseTransport()
        ready := false
        phase := "unfocused"
        DiagSample(false,active,phase)
        WriteTransportStatus()
        return
    }
    if (owner and owner != active) {
        ControllerMessagePrepareHandoff()
        BridgeRelease()
        ReleaseTransport()
        ControllerMessageSelect(false, "", 0, "")
        ready := false
    }
    owner := active
    states := ReadTransportStates(GetKeyState, CB.movement != "off" or CB.ps != "off")
    DiagStage("hardware-read")
    connected := IsObject(states)
    if (!connected) {
        CB.psDown := true, CB.neutral := false
        BridgeRelease()
        ReleaseTransport()
        ready := false
        phase := xinputFault ? "xinput-unavailable" : "disconnected"
        DiagSample(false,active,phase)
        WriteTransportStatus()
        return
    }
    neutral := true
    Loop 12 {
        if (states[A_Index])
            neutral := false
    }
    phase := ready ? "ready" : "waiting-neutral"
    DiagSample(states,active,phase)
    WriteTransportStatus()
    if (!ready) {
        if (HO.pending)
            ready := true
        else {
            if (neutral)
                ready := true
            return
        }
    }
    ControllerMessagePoll(states, active)
    DiagStage("lease-routing-write")
    BridgePoll(states, active)
    DiagStage("bridge-decisions")
}

; Explicit local stop; it exits only this script, even outside FFXI.
^!F12::ExitApp()

TransportExit(*) {
    global phase, xinputLibrary
    SetTimer(TransportPoll, 0)
    BridgeRelease()
    ReleaseTransport()
    DiagClose("wrapper exit")
    phase := "stopped"
    WriteTransportStatus(true)
    if (xinputLibrary)
        DllCall("FreeLibrary", "Ptr", xinputLibrary)
    ; Windows closes the mutex handle when the process terminates.
}

ReleaseTransport() {
    global owner
    DiagRecord("transport release owner=" . owner)
    ControllerMessageCancel()
}

; A: read hardware only. Output, focus cleanup and rearming remain shared.
ReadTransportStates(readKey := GetKeyState, observeBridge := false) {
    global allSlotsTest, isXInput, slotScan
    return ReadProfileSlots(ReadTransportSlot.Bind(readKey, observeBridge), isXInput ? 4 : 16, slotScan)
}

ReadTransportSlot(readKey := GetKeyState, observeBridge := false, slot := 0) {
    global isXInput, profile, device, joystickPrefix, joys, xinputGetState
    if (!isXInput) {
        prefix := slot ? (slot = 1 ? "" : String(slot)) : joystickPrefix
        if (readKey(prefix . "JoyName") = "")
            return false
        pov := readKey(prefix . "JoyPOV")
        ; A controller can disappear between the name and POV reads.
        if (!IsNumber(pov))
            return false
        ; Match the native hook: diagonals carry both adjacent directions.
        states := []
        Loop 4 {
            angle := (A_Index - 1) * 9000
            delta := Mod(pov - angle + 36000, 36000)
            states.Push(pov >= 0 && (delta = 0 || delta = 4500 || delta = 31500))
        }
        for _, joy in joys
            states.Push(readKey(prefix . "Joy" . joy) ? true : false)
        if (observeBridge) {
            x := readKey(prefix . "JoyX"), y := readKey(prefix . "JoyY")
            if (IsNumber(x) and IsNumber(y))
                states.moveX := (x - 50) / 50, states.moveY := (y - 50) / 50
            states.ps := profile = "ps5-directinput" and readKey(prefix . "Joy13") ? true : false
        }
        return states
    }
    if (!xinputGetState)
        return false
    state := Buffer(16, 0)
    if (DllCall(xinputGetState, "UInt", (slot ? slot : device) - 1, "Ptr", state, "UInt") != 0)
        return false
    return DecodeXInputState(state, profile)
}

DecodeXInputState(state, profile) {
    buttons := NumGet(state, 4, "UShort")
    states := []
    for i, flag in ControllerXInputButtons(profile)
        states.Push((buttons & flag) != 0)
    threshold := ControllerXInputTriggerThreshold()
    states.Push(NumGet(state, 6, "UChar") > threshold, NumGet(state, 7, "UChar") > threshold)
    for _, flag in ControllerXInputShoulders(profile)
        states.Push((buttons & flag) != 0)
    states.moveX := NumGet(state, 8, "Short") / 32768
    states.moveY := NumGet(state, 10, "Short") / 32768
    return states
}

InitXInput() {
    global xinputLibrary, xinputGetState
    for _, dll in ["xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll", "xinput1_2.dll", "xinput1_1.dll"] {
        library := DllCall("LoadLibraryExW", "WStr", dll, "Ptr", 0, "UInt", 0x800, "Ptr")
        if (!library)
            continue
        address := DllCall("GetProcAddress", "Ptr", library, "AStr", "XInputGetState", "Ptr")
        if (address) {
            xinputLibrary := library
            xinputGetState := address
            return true
        }
        DllCall("FreeLibrary", "Ptr", library)
    }
    return false
}

WriteTransportStatus(force := false) {
    global profile, device, phase, connected, ready, lastStatusTick, origin, CM, CB, allSlotsTest, slotScan
    if (!force and A_TickCount - lastStatusTick < 1000)
        return
    lastStatusTick := A_TickCount
    timestamp := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    pid := phase = "stopped" ? 0 : DllCall("GetCurrentProcessId", "UInt")
    route := CM.requested ? CM.phase : "waiting-lease"
    contents := "[Controller]`norigin=" . origin . "`nprofile=" . profile . "`ndevice=" . device . "`nmodifier=messages"
        . "`npid=" . pid . "`nstate=" . phase . "`nconnected=" . connected . "`nready=" . ready . "`nroute=" . route . "`ntimestamp=" . timestamp . "`nahk=" . A_AhkVersion . "`nexecutable=" . A_AhkPath . "`n"
    ; Replace the status as one file so Lua never treats a partial write as live.
    temporary := A_ScriptDir . "\data\controller-status.tmp"
    destination := A_ScriptDir . "\data\controller-status.ini"
    contents .= "bridge_movement=" . CB.lastMovement . "`nbridge_ps=" . CB.lastPS . "`n"
    contents .= "scan_mode=all-profile-slots`nscan_connected=" . slotScan.connected . "`nscan_active=" . slotScan.active . "`n"
    contents .= "reader_build=profile-slots2`nreader_script=" . A_ScriptName . "`n"
    contents .= WrapperClientsStatus()
    WriteControllerFile(temporary, destination, contents)
}
AcquireWrapperMutex() {
    ; Normalize case; hash keeps the name below Windows' MAX_PATH limit.
    path := A_ScriptDir
    path := StrLower(path)
    hash := 2166136261
    Loop Parse path
        hash := ((hash ^ Ord(A_LoopField)) * 16777619) & 0xFFFFFFFF
    handle := DllCall("CreateMutexW", "Ptr", 0, "Int", 0, "WStr", "Local\XIVCrossbar_" . hash, "Ptr")
    mutexError := A_LastError
    if (!handle or mutexError = 183) {
        if (handle)
            DllCall("CloseHandle", "Ptr", handle)
        return 0
    }
    return handle
}

; Lease/status/feed readers must only see complete snapshots.
WriteControllerFile(temporary, destination, contents) {
    try {
        if FileExist(temporary)
            FileDelete(temporary)
        FileAppend(contents, temporary, "UTF-8-RAW")
        FileMove(temporary, destination, 1)
        return true
    } catch Error {
        ; FileMove can throw a generic Error with a failed-file count.
        return false
    }
}
