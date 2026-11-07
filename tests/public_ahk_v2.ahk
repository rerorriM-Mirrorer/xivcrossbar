; Load production functions below without entering the reader's auto-execute code.
try {
    WrapperClientsInit()
    WC.seen := true
    Check(!WrapperClientsDecision(WC, 1, 10, true, 100), "another loaded client keeps the reader alive")
    Check(!WrapperClientsDecision(WC, 0, 10, true, 200), "last unload starts grace period")
    Check(!WrapperClientsDecision(WC, 0, 10, true, 2199), "grace period has not elapsed")
    Check(WrapperClientsDecision(WC, 0, 10, true, 2200), "last client requests shutdown after grace")
    Check(!WrapperClientsDecision(WC, 1, 10, true, 2201), "reload cancels shutdown")
    DX := {active:false}
    profile := "ps5-directinput"
    isXInput := false
    joystickPrefix := ""
    joys := ControllerDirectInputButtons(profile)
    states := ReadTransportStates(FakeJoystick.Bind(9000))
    Check(states.Length = 12 && states[2] && states[5] && !states[6] && states[12], "connected DirectInput maps all twelve states")
    Check(!ReadTransportStates(FakeJoystick.Bind("")), "missing POV invalidates the DirectInput sample")
    states := ReadTransportStates(FakeJoystick.Bind(-1))
    Check(states.Length = 12 && !states[1] && !states[2] && !states[3] && !states[4] && states[5],
        "centered POV preserves face input")
    states := ReadTransportStates(FakeJoystick.Bind(31500))
    Check(states[1] && !states[2] && !states[3] && states[4], "diagonal POV maps Up and Left")
    for profile in ["ps5-directinput", "f710-directinput", "fightpadpro-directinput"] {
        joys := ControllerDirectInputButtons(profile)
        states := ReadTransportStates(FakeJoystick.Bind(9000))
        Check(states[2] && states[12] && states[profile = "fightpadpro-directinput" ? 6 : 5], "DirectInput profile mapping")
    }
    packet := Buffer(16, 0)
    NumPut("UShort", 0x1231, packet, 4)
    NumPut("UChar", 5, "UChar", 4, packet, 6)
    for profile in ["xinput", "xinput-r1-chooser"] {
        states := DecodeXInputState(packet, profile)
        Check(states[1] && states[5] && states[9] && states[10] && states[11] && !states[12], "XInput state and trigger threshold")
    }
    NumPut("UShort", 0x0100, packet, 4)
    NumPut("UChar", 4, "UChar", 5, packet, 6)
    states := DecodeXInputState(packet, "xinput")
    Check(!states[11] && states[12], "LB stays native and physical RT works independently")
    NumPut("UChar", 5, packet, 6)
    states := DecodeXInputState(packet, "xinput")
    Check(states[11] && states[12], "both physical triggers register together")
    NumPut("UShort", 0x0200, packet, 4)
    Check(!DecodeXInputState(packet, "xinput")[10] && DecodeXInputState(packet, "xinput-r1-chooser")[10], "alternate RB chooser")
    owner := 0
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
        for profile in ["ps5-directinput", "f710-directinput", "fightpadpro-directinput", "xinput", "xinput-r1-chooser"] {
            ControllerMessageSelect(false, "", 0, "")
            Check(!ControllerMessagePoll(held, 0) && !CM.pending.Length, "no lease stays silent")
            ControllerMessageSelect(true, profile, 0, spool)
            ControllerMessagePoll(NeutralButtons(), 0)
            ControllerMessagePoll(held, 0)
            Check(CM.seq = 3 && InStr(FileRead(spool), "3,down,5"), "every profile sends messages")
        }
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

FakeJoystick(pov, key) {
    if (key = "JoyName")
        return "Test controller"
    if (key = "JoyPOV")
        return pov
    return key = "Joy2" or key = "Joy8"
}

Check(condition, description) {
    if (!condition)
        throw Error(description)
}

#Include %A_ScriptDir%\ffxi_directinput.ahk
