; Load production functions below without entering the reader's auto-execute code.
try {
    Check(Beta1PovCardinal(4500, 2) = 2, "retain adjacent cardinal")
    Check(Beta1PovCardinal(4500, 3) = 1, "diagonal fallback")
    Check(Beta1PovCardinal(-1, 2) = 0, "neutral POV")
    DX := {active:false}
    profile := "ps5-directinput"
    isXInput := false
    joystickPrefix := ""
    joys := [0, 0, 0, 0, 2, 1, 3, 4, 9, 10, 7, 8]
    povDirection := 0
    states := ReadTransportStates(FakeJoystick)
    Check(states.Length = 12 && states[2] && states[5] && !states[6] && states[12], "connected DirectInput maps all twelve states")
    owner := 0
    keys := []
    previous := NeutralButtons()
    appsOwned := false
    ControllerMessageInit()
    spool := A_Temp . "\xb-public-native-" . DllCall("GetCurrentProcessId", "UInt") . ".buttons"
    try {
        ControllerMessageSelect(true, "native-test", 0, spool)
        ; Force a replacement failure with a missing destination directory.
        CM.path := spool . "\\missing.buttons"
        Check(!ControllerMessageFlush(true) && CM.error && CM.pending.Length = 1, "failed flush retains pending events")
        CM.path := spool
        Check(ControllerMessageFlush(true) && !CM.error && InStr(FileRead(spool), "1,cancel,0"), "retry publishes pending event")
        held := NeutralButtons()
        held[5] := true
        Check(ControllerMessagePoll(held, 0) && CM.seq = 1, "wait for neutral without keyboard fallback")
        Check(ControllerMessagePoll(NeutralButtons(), 0), "arm DirectLink")
        held[11] := true
        Check(ControllerMessagePoll(held, 0), "capture trigger and face")
        Check(InStr(FileRead(spool), "2,down,11" . Chr(10) . "3,down,5"), "trigger precedes face")
        ControllerMessageSelect(true, "native-test", 3, spool)
        Check(CM.pending.Length = 0, "retire acknowledged events")
        Check(ControllerMessagePoll(NeutralButtons(), 0), "capture releases")
        Check(InStr(FileRead(spool), "4,up,5" . Chr(10) . "5,up,11"), "publish both releases")
        ControllerMessageCancel()
        Check(InStr(FileRead(spool), "6,cancel,0"), "publish cancellation")
        for profile in ["f710-directinput", "fightpadpro-directinput", "xinput", "xinput-r1-chooser"]
            Check(!ControllerMessagePoll(held, 0), "legacy profile stays off DirectLink")
    } finally {
        try FileDelete(spool)
        try FileDelete(spool . ".tmp")
    }
    FileAppend("Public native DirectLink checks passed.", "*")
    ExitApp(0)
} catch Error as failure {
    FileAppend(failure.Message . " (line " . failure.Line . ")", "**")
    ExitApp(1)
}

FakeJoystick(key) {
    if (key = "JoyName")
        return "Test controller"
    if (key = "JoyPOV")
        return 9000
    return key = "Joy2" or key = "Joy8"
}

Check(condition, description) {
    if (!condition)
        throw Error(description)
}

#Include %A_ScriptDir%\ffxi_directinput.ahk
