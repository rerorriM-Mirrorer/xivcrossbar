; Generated from packaging/controller_mappings.json. Edit the source and regenerate.
; Logical order: up, right, down, left, bottom, face_left, face_right, top, binder, chooser, lt, rt, l1, r1.
; The DirectInput POV supplies the first four inputs.
ControllerDirectInputButtons(profile) {
    switch profile {
        case "ps5-directinput":
            return [2, 1, 3, 4, 9, 10, 7, 8, 5, 6]
        case "fightpadpro-directinput":
            return [3, 2, 4, 1, 9, 10, 7, 8, 5, 6]
        case "f710-directinput":
            return [2, 1, 3, 4, 9, 10, 7, 8, 5, 6]
    }
}

ControllerXInputButtons(profile) {
    return [0x0001, 0x0008, 0x0002, 0x0004, 0x1000, 0x4000, 0x2000, 0x8000, 0x0020,
        profile = "xinput-r1-chooser" ? 0x0200 : 0x0010]
}

ControllerXInputShoulders(profile) {
    return [0x0100, profile = "xinput-r1-chooser" ? 0 : 0x0200]
}

ControllerXInputTriggerThreshold() => 4
