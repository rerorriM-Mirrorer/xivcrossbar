#Requires AutoHotkey v2.0.19+
#Include %A_ScriptDir%\runtime-functions.ahk
; This harness is copied to an isolated temporary folder by ahk_v2.ps1.
; All policies below execute actual production functions with real v2 objects.
OnError(NativeTestError)
SetKeyDelay(10, -1)
FileEncoding("CP0")
DirCreate(A_ScriptDir . "\data")
profile := "ps5-directinput", device := 1, modifierArgument := "apps", origin := "test"
captureKey := "AppsKey", ready := false, lastStatusTick := -1000, phase := "test", connected := false
isXInput := false, joystickPrefix := "", joys := [], xinputGetState := 0, xinputLibrary := 0, xinputFault := false
xinputGuide := false, povDirection := 0, owner := 0, appsOwned := false
keys := ["F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"]
previous := InputState()
ControllerMessageInit()
PersonalInit(profile, "")
MovementInit()
InputTraceInit()
WrapperClientsInit()
NativeContextObservationTests()
ControllerMessageInit()
PersonalInit(profile, "")
MovementInit()
order := ""
for k in OrderedInputMap(Map(2, true, 1, true, "z", true, "A", true))
    order .= k . ","
Assert(order = "1,2,A,z,", "v1 acquisition/release enumeration order")
Assert(previous[14] = false, "missing sparse button is released")
Assert(previous.l1 = false, "named defaults")
previous.moveX := 0.25
cloned := previous.Clone()
Assert(cloned.HasOwnProp("moveX") and cloned.moveX = 0.25, "Clone keeps named axes")
Assert(cloned[14] = false, "Clone keeps Default")
Assert(A_KeyDelay = 10 and A_KeyDuration = -1, "v1 event delays")
record := WrapperClientRecord("[Client]`nprotocol=owner-file-v1`nid=test-1`nstate=loaded`nkill=true`nclosed=0`n")
Assert(record.id = "test-1" and record.kill = "true", "native regex capture objects")
Assert(!WrapperClientRecord("[Client]`nprotocol=wrong`n"), "malformed client record")
; Actual v2 query: the reported combined-name exception must not recur.
Assert(PersonalPhysicalKey("vkC0sc029") = GetKeyState("sc029", "P"), "touch physical scan query")
Assert(PersonalPhysicalKey("vkBCsc033") = GetKeyState("sc033", "P"), "comma physical scan query")
Assert(PersonalPhysicalKey("vkBEsc034") = GetKeyState("sc034", "P"), "period physical scan query")
Assert(PersonalPhysicalKey("Escape") = GetKeyState("Escape", "P"), "ordinary key query unchanged")
g := {phase:"idle"}
Assert(PersonalTouchStep(g, true, false, false, 100) = "", "touch arm")
Assert(PersonalTouchStep(g, true, true, false, 599) = "", "touch threshold before")
Assert(PersonalTouchStep(g, true, true, false, 600) = "vkC0sc029", "touch hold")
Assert(PersonalTouchStep(g, false, true, false, 601) = "Escape", "touch release")
Assert(PersonalPovDirection(4500, 2) = 2 and PersonalPovDirection(4500, 0) = 1, "diagonal policy")
profile := "xinput-extended"
s := XInputStates(0x1100, 5, 4, .25, -.5, true, false)
Assert(s[5] and s[11] and !s[12] and s.l1 and !s.r1, "XInput independent thresholds/face/shoulder")
Assert(s.moveX = .25 and s.moveY = -.5 and !s.touch, "XInput axes/Guide fallback")
for _, pair in [[1,1],[8,2],[2,3],[4,4],[0x1000,5],[0x4000,6],[0x2000,7],[0x8000,8],[0x20,9],[0x10,10]] {
    povDirection := 0
    bits := XInputStates(pair[1], 0, 0, 0, 0, true, true)
    Assert(bits[pair[2]], "XInput mapping " . pair[2])
}
PC.enabled := false
path := A_ScriptDir . "\data\test.ini"
lease := "bank_protocol=1`nbutton_mode=messages`nbutton_token=one`nbutton_ack=0`nbutton_recover=0`n"
ControllerMessageLease(lease, path)
Assert(CM.seq = 1 and CM.pending[1].kind = "cancel", "initial cancel")
ControllerMessageLease(StrReplace(lease, "button_ack=0", "button_ack=1"), path)
Assert(CM.pending.Length = 0, "native ack pruning")
CM.expanded := true
s := InputState()
ControllerMessagePoll(s)
Assert(CM.phase = "messages", "neutral arming")
s[7] := true, s[11] := true, s[14] := true
ControllerMessagePoll(s)
Assert(CM.pending[2].button = 11 and CM.pending[3].button = 14 and CM.pending[4].button = 7, "trigger/shoulder before slot")
sequence := CM.seq
ControllerMessagePoll(s)
Assert(CM.seq = sequence, "held dedup")
ControllerMessagePoll(InputState())
Assert(CM.pending[5].kind = "up" and CM.pending[5].button = 7, "release order")
serialized := FileRead(CM.path, "CP0")
Assert(InStr(serialized, "token=one`n") = 1 and InStr(serialized, "END`n"), "wire framing")
CM.pending := [], CM.previous := InputState(), CM.phase := "messages"
CM.seen := DllCall("GetTickCount64", "UInt64") - 101
ControllerMessagePoll(InputState())
Assert(CM.phase = "uncertain" and CM.pending[1].kind = "stall", "lease gap quarantine")
CM.seen := DllCall("GetTickCount64", "UInt64")
ControllerMessagePoll(InputState())
Assert(CM.phase = "messages", "neutral recovery")
CM.pending := [], CM.previous := InputState()
s := InputState(), s[11] := true
ControllerMessagePoll(s)
CM.pending[1].tick := DllCall("GetTickCount64", "UInt64") - 351
ControllerMessagePoll(s)
Assert(CM.phase = "backpressure", "350ms backlog boundary")
Assert(!PublishControllerFile(A_ScriptDir . "\missing\x", A_ScriptDir . "\missing\y", "x"), "write failure remains local")
PC.enabled := true
spec := PersonalNativeSpec("ctrl+left")
Assert(spec.key = "Left" and spec.modifier = "LControl", "native whitelist")
Assert(PersonalNativeSpec("f8").key = "F8", "function whitelist")
Assert(!PersonalNativeSpec("win+r"), "invalid native key")
PC.keys := Map(), PC.releases := Map(), PC.blocked := Map(1,"i",2,"l"), PC.suppressed := Map()
raw := InputState(), raw[2] := true
PersonalFilter(raw.Clone(), raw)
Assert(!PC.blocked.Has(1) and PC.blocked.Has(2), "map deletion preserves adjacent entry")
state := {seen:true,emptySince:0,lastClose:0}
Assert(!WrapperClientsDecision(state, 0, 10, true, 1000), "shutdown grace")
Assert(WrapperClientsDecision(state, 0, 10, true, 3000), "shutdown boundary")
FileAppend("PASS native v2 policy and object tests ahk=" . A_AhkVersion . "`n", "*", "UTF-8-RAW")
ExitApp(0)

Assert(value, label) {
    if (!value)
        throw Error("FAIL " . label)
}

NativeTestError(error, mode) {
    FileAppend(error.Message . " at " . error.File . ":" . error.Line . "`n" . error.Stack . "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}

; Execute production context I/O, lease side effects and Ready movement reuse.
; Hidden test windows provide client titles without impersonating FFXiClass.
NativeContextObservationTests() {
    global PC, CM, TM
    previousHidden := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    first := Gui(, "Cioara context test"), second := Gui(, "Myrr context test")
    folder := A_ScriptDir . "\data\personal-controls"
    DirCreate(folder)
    path := folder . "\context-test.ini"
    try {
        NativeWriteContext(path, "Cioara", "gameplay", "session-one")
        observation := {}
        Assert(PersonalContext(first.Hwnd, observation) = "gameplay", "fresh context")
        reads := PC.contextFileReads, scans := PC.contextScans, count := PC.contextObservations
        Assert(CM.token = "session-one", "fresh session side effect")
        NativeWriteContext(path, "Cioara", "chat", "session-two")
        Assert(PersonalContext(first.Hwnd, observation) = "gameplay", "same-poll mode snapshot")
        Assert(CM.token = "session-one", "same-poll session snapshot")
        Assert(PC.contextFileReads = reads and PC.contextScans = scans and PC.contextObservations = count, "same-poll no repeated I/O")
        Assert(PC.contextReuses = 1, "reuse counter")
        observation := {}
        Assert(PersonalContext(first.Hwnd, observation) = "chat" and CM.token = "session-two", "next poll adopts mode/session")
        reads := PC.contextFileReads
        PC.enabled := true
        TM.nextLease := DllCall("GetTickCount64", "UInt64") + 10000
        TM.policy := "Ready", TM.ready := false
        states := InputState(), states.moveX := 1, states.moveY := 0
        MovementPoll(states, first.Hwnd, observation)
        Assert(TM.reason = "personal-chat" and !TM.fired, "Ready movement consumes shared blocked mode")
        Assert(PC.contextFileReads = reads and PC.contextReuses = 2, "movement adds no context read")
        NativeWriteContext(path, "Myrr", "trust", "other-session")
        Assert(PersonalContext(second.Hwnd, observation) = "trust" and CM.token = "other-session", "different HWND cannot reuse mode/session")
        FileDelete(path)
        scans := PC.contextScans
        observation := {}
        Assert(PersonalContext(first.Hwnd, observation) = "unknown", "missing context")
        Assert(PC.contextScans = scans + 2, "immediate two-pass retry retained")
        NativeWriteContext(path, "Cioara", "gameplay", "session-three")
        reads := PC.contextFileReads
        Assert(PersonalContext(first.Hwnd, observation) = "unknown" and PC.contextFileReads = reads, "uncertainty shared within poll")
        Assert(PersonalContext(first.Hwnd, {}) = "gameplay", "next-poll recovery")
        NativeWriteContext(path, "Cioara", "gameplay", "session-four", 0)
        Assert(PersonalContext(first.Hwnd, {}) = "unknown", "stale context rejection")
        FileDelete(path)
        FileAppend("name=Cioara`nmode=gameplay`nEND`n", path, "CP0")
        Assert(PersonalContext(first.Hwnd, {}) = "unknown", "malformed context rejection")
        reads := PC.contextFileReads
        Assert(PersonalContext(0, {}) = "unfocused" and PC.contextFileReads = reads, "unfocused no I/O")
        ; Standalone callers retain a fresh read on every call.
        NativeWriteContext(path, "Cioara", "gameplay", "standalone-one")
        Assert(PersonalContext(first.Hwnd) = "gameplay", "standalone context")
        NativeWriteContext(path, "Cioara", "chat", "standalone-two")
        Assert(PersonalContext(first.Hwnd) = "chat", "standalone is never cached")
        FileAppend("PASS native per-poll context: mode/session isolation, Ready reuse, retry, stale/malformed/focus boundaries`n", "*", "UTF-8-RAW")
    } finally {
        first.Destroy(), second.Destroy()
        DetectHiddenWindows(previousHidden)
        if FileExist(path)
            FileDelete(path)
    }
}

NativeWriteContext(path, name, mode, token, stamp := -1) {
    if (stamp = -1)
        stamp := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    if FileExist(path)
        FileDelete(path)
    FileAppend("name=" . name . "`ntimestamp=" . stamp . "`nmode=" . mode
        . "`nbutton_mode=messages`nbutton_token=" . token . "`nbutton_ack=0`nEND`n", path, "CP0")
}
