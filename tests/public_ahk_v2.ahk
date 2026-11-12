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
    states := ReadTransportSlot(FakeJoystick.Bind(9000))
    Check(states.Length = 14 && states[2] && states[5] && !states[6] && states[12] && states[13] && !states[14], "connected DirectInput maps base inputs and both shoulders")
    Check(!ReadTransportSlot(FakeJoystick.Bind("")), "missing POV invalidates the DirectInput sample")
    states := ReadTransportSlot(FakeJoystick.Bind(-1))
    Check(states.Length = 14 && !states[1] && !states[2] && !states[3] && !states[4] && states[5],
        "centered POV preserves face input")
    states := ReadTransportSlot(FakeJoystick.Bind(31500))
    Check(states[1] && !states[2] && !states[3] && states[4], "diagonal POV maps Up and Left")
    for profile in ["ps5-directinput", "f710-directinput", "fightpadpro-directinput"] {
        joys := ControllerDirectInputButtons(profile)
        states := ReadTransportSlot(FakeJoystick.Bind(9000))
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
    Check(!states[11] && states[12] && states[13], "LB and physical RT are read independently")
    NumPut("UChar", 5, packet, 6)
    states := DecodeXInputState(packet, "xinput")
    Check(states[11] && states[12], "both physical triggers register together")
    NumPut("UShort", 0x0200, packet, 4)
    Check(!DecodeXInputState(packet, "xinput")[10] && DecodeXInputState(packet, "xinput-r1-chooser")[10], "alternate RB chooser")
    Check(DecodeXInputState(packet, "xinput")[14] && !DecodeXInputState(packet, "xinput-r1-chooser")[14],
        "alternate RB chooser never emits a second RB edge")
    owner := 0
    ControllerMessageInit()
    BridgeInit()
    DiagInit()
    Check(!DiagMatch(0, 123), "PID-scoped capture does not match outside FFXI")
    DX.active := true, DX.matched := false
    DiagRecord("unfocused synthetic event")
    Check(DX.lines.Length = 0, "unmatched foreground cannot enter a scoped feed")
    DX.active := false
    BridgeLease("bridge_movement=test`nbridge_ps=on`nbridge_gameplay=1`n")
    Check(CB.movement = "test" && CB.ps = "on" && CB.gameplay && PPS.down,
        "bridge modes parse and arm from neutral")
    BridgeLease("bridge_movement=invalid`n")
    Check(CB.movement = "off" && CB.ps = "off" && !CB.gameplay, "old or invalid lease defaults off")
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
        held[13] := true, held[14] := true
        for count in [12, 14] {
            ControllerMessageSelect(true, "shoulder-test-" . count, 0, spool, count)
            ControllerMessagePoll(NeutralButtons(), 0)
            ControllerMessagePoll(held, 0)
            contents := FileRead(spool)
            Check((InStr(contents, "buttons=14") != 0) = (count = 14)
                && (InStr(contents, ",down,13,1") != 0) = (count = 14)
                && (InStr(contents, ",down,14,1") != 0) = (count = 14),
                "only extended leases carry both shoulders and same-sample chord marks")
        }
        held[13] := false, held[14] := false
        for profile in ["ps5-directinput", "f710-directinput", "fightpadpro-directinput", "xinput", "xinput-r1-chooser"] {
            ControllerMessageSelect(false, "", 0, "")
            Check(!ControllerMessagePoll(held, 0) && !CM.pending.Length, "no lease stays silent")
            ControllerMessageSelect(true, profile, 0, spool)
            ControllerMessagePoll(NeutralButtons(), 0)
            ControllerMessagePoll(held, 0)
            Check(CM.seq = 3 && InStr(FileRead(spool), "3,down,5"), "every profile sends messages")
        }
        for mask in [1,2,4,8,3,12] {
            ControllerMessageSelect(true,"handoff-source-" . mask,0,spool,14)
            CM.handoff := true, CM.bank := mask = 1 ? 5 : mask = 2 ? 6 : 3
            ControllerMessagePoll(NeutralButtons(),0)
            held := NeutralButtons(), held[2] := true
            Loop 4
                held[10+A_Index] := (mask & (1 << (A_Index-1))) != 0
            ControllerMessagePoll(held,0)
            ControllerMessagePrepareHandoff()
            Check(HO.pending,"eligible source keeps a modifier handoff")
            ControllerMessageSelect(true,"handoff-target-" . mask,0,spool,14)
            ControllerMessagePoll(held,0)
            contents := FileRead(spool)
            Check(InStr(contents,",resume," . mask . ",") && !InStr(contents,",down,2"),
                "destination adopts modifiers without replaying switching direction")
            Check(CM.phase = "messages" && CM.previous[2] && !HO.pending,"preheld action is seeded until release")
            held[2] := false
            ControllerMessagePoll(held,0)
            held[2] := true
            ControllerMessagePoll(held,0)
            Check(InStr(FileRead(spool),",down,2"),"fresh direction works without releasing modifiers")
        }
    } finally {
        try FileDelete(spool)
        try FileDelete(spool . ".tmp")
    }
    PersonalControlChecks()
    ProfileSlotChecks()
    s := {armed:false,previousL1:false}, extra := NeutralButtons()
    extra[13] := true
    Check(ZoomDecision(s,extra,true)="","L1 alone has no zoom")
    extra[20] := true
    Check(ZoomDecision(s,extra,true)="vkBE","L1 then right up holds period")
    extra[20] := false, extra[22] := true
    Check(ZoomDecision(s,extra,true)="vkBC","right down holds comma")
    Check(ZoomDecision(s,extra,false)="","lost eligibility releases zoom")
    Check(ZoomDecision(s,extra,true)="","held stick cannot rearm on focus return")
    extra[22] := false
    ZoomDecision(s,extra,true)
    extra[22] := true
    Check(ZoomDecision(s,extra,true)="vkBC","centering rearms zoom")
    extra[14] := true
    Check(ZoomDecision(s,extra,true)="","other shoulder suppresses zoom")
    packet := Buffer(16,0)
    NumPut("UShort",0xc0,packet,4)
    NumPut("Short",28000,packet,12)
    NumPut("Short",28000,packet,14)
    extra := DecodeXInputState(packet,"xinput")
    Check(extra.Length=23 && extra[15] && extra[16] && extra[20] && extra[21],"XInput extras and right diagonal")
    ControllerMessageInit()
    ControllerMessageSelect(true,"extra-fixture",0,A_ScriptDir . "\data\extra.buttons",23)
    ControllerMessagePoll(NeutralButtons(),0)
    extra := NeutralButtons(), extra[18] := true, extra[23] := true
    ControllerMessagePoll(extra,0)
    Check(CM.pending.Length=3 && CM.pending[2].button=18 && CM.pending[3].button=23,"extended stream carries extra edges")
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
    return key = "Joy2" or key = "Joy8" or key = "Joy5"
}

Check(condition, description) {
    if (!condition)
        throw Error(description)
}

PersonalControlChecks() {
    for arm in ["client","neutral"] {
        s := {neutral:false,fired:false,neutralSince:0,armMode:arm}
        Check(!MovementArmStep(s,1,1000),"deflected stick cannot arm without center")
        MovementArmStep(s,0,1100)
        Check(!MovementArmStep(s,0,1199),"center must be stable for 100 ms")
        MovementArmStep(s,0,1200)
        Check(MovementArmStep(s,1,1210),"fresh deliberate movement signals")
        s.fired := true, s.neutral := false
        Check(!MovementArmStep(s,1,1220),"held movement cannot repeat")
        MovementArmStep(s,0,1300), MovementArmStep(s,0,1400)
        Check(MovementArmStep(s,1,1410) = (arm = "neutral"),"only neutral mode rearms within the same focus session")
    }
    s := PersonalPSState(), s.other := 123, s.otherPID := 456
    Check(!PersonalPSDecision(s,true,1,true,false,"on",1000),"preheld PS cannot switch")
    PersonalPSDecision(s,false,1,true,false,"on",1010)
    d := PersonalPSDecision(s,true,1,true,false,"on",1020)
    Check(IsObject(d) && d.kind = "away" && d.target = 123,"fresh bare PS selects remembered non-FFXI window")
    s.returnClient := 789, s.returnPID := 987, s.returnUntil := 32000
    Check(!PersonalPSDecision(s,true,0,false,false,"on",1030),"held PS cannot immediately bounce back")
    PersonalPSDecision(s,false,0,false,false,"on",1040)
    d := PersonalPSDecision(s,true,0,false,false,"on",1050)
    Check(IsObject(d) && d.kind = "return" && d.target = 789,"fresh PS outside selects originating FFXI client")
    PersonalPSDecision(s,false,1,true,false,"on",1060)
    Check(!PersonalPSDecision(s,true,1,true,true,"on",1070),"PS chord is blocked")
    PersonalPSDecision(s,false,0,false,false,"on",33000)
    Check(!PersonalPSDecision(s,true,0,false,false,"on",33010),"expired return cannot activate a window")
    PersonalPSDecision(s,false,1,true,false,"off",34000)
    Check(!PersonalPSDecision(s,true,1,true,false,"off",34010),"disabled PS remains inactive")
}
ProfileSlotChecks() {
    fixtures := Map(1, SlotSample())
    scan := {armed:Map(),signature:"",connected:"",active:""}
    reader := (slot) => fixtures.Has(slot) ? fixtures[slot] : false
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(IsObject(states) && !states[5] && scan.connected = "1", "all-slot neutral discovery")
    fixtures[1][5] := true
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(states[5] && scan.active = "1", "slot 1 press")
    fixtures[2] := SlotSample()
    ReadProfileSlots(reader,16,scan,NoSlotLog)
    fixtures[2][5] := true
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(states[5] && scan.active = "1,2", "duplicate source yields one logical held state")
    fixtures[1][5] := false
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(states[5], "one source release cannot release another held source")
    fixtures.Delete(2)
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(!states[5] && !scan.armed.Has(2), "disconnect releases final held source")
    fixtures[16] := SlotSample()
    fixtures[16][11] := true
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(!states[11] && !scan.armed[16], "new held source waits for release")
    fixtures[16][11] := false
    ReadProfileSlots(reader,16,scan,NoSlotLog)
    fixtures[16][11] := true
    states := ReadProfileSlots(reader,16,scan,NoSlotLog)
    Check(states[11] && scan.active = "16", "highest DirectInput address participates")
    states := ReadProfileSlots(reader,4,scan,NoSlotLog)
    Check(!states[11] && scan.connected = "1", "XInput scans only its four addresses")
    fixtures.Clear()
    Check(!ReadProfileSlots(reader,16,scan,NoSlotLog), "all disconnected produces no sample")
}
SlotSample() {
    result := []
    Loop 14
        result.Push(false)
    return result
}
NoSlotLog(connected,active,signature) {
}

#Include %A_ScriptDir%\ffxi_directinput.ahk
