#include "ownership.hpp"
#include "pad_state.hpp"
#include <cstdlib>
#include <iostream>

static void check(bool ok, const char* what) {
    if (!ok) { std::cerr << what << '\n'; std::exit(1); }
}

int main() {
    using namespace xb;
    constexpr unsigned right = 2, face = 16, left_trigger = 1024, right_trigger = 2048;
    Ownership owner;
    check(!owner.apply(up, 1, false, false).suppressed, "preheld Up remains native");
    owner.apply(0, 1, false, false);
    auto edge = owner.apply(up | right | face, 1, false, false);
    check(edge.suppressed == up && edge.down == up, "Up probe preserves other inputs");
    check(filter_hat(4500, edge.suppressed) == 9000, "diagonal retains native Right");
    check(owner.apply(0, 1, false, false).up == up, "Up release");
    edge = owner.apply(up | circle | right, 1, false, false);
    check(edge.suppressed == (up | circle) && edge.down == (up | circle), "Up and Circle probe leaves Right native");
    check(owner.apply(circle, 1, false, false).suppressed == circle, "Circle ownership survives Up release");
    owner.apply(0, 1, false, false);
    check(!owner.apply(up, 0, false, false).suppressed, "fresh disabled Up is native");

    owner.reset();
    owner.apply(0, 2, false, false);
    owner.apply(up, 2, false, false);
    edge = owner.apply(up | left_trigger | face, 2, false, false);
    check(edge.down == (left_trigger | face), "native Up stays native through trigger");
    edge = owner.apply(up | face, 2, false, false);
    check(edge.up == left_trigger && edge.suppressed == face, "trigger release keeps held face captured");
    edge = owner.apply(up, 2, false, false);
    check(edge.up == face && !edge.suppressed, "face release clears ownership");
    check(!owner.apply(up | face | right_trigger, 2, false, true).suppressed, "native menu passes fresh inputs");
    owner.apply(0, 2, true, false);
    check(owner.apply(face, 2, true, false).suppressed == face, "addon menu owns face");
    owner.reset();
    check(!owner.apply(left_trigger | up, 2, false, false).down, "focus or disconnect reset requires neutral");
    owner.apply(0, 2, false, false);
    check(owner.apply(left_trigger | up, 2, false, false).down == (left_trigger | up), "fresh chord after reset");

    owner.reset();
    owner.apply(0, 2, false, false, default_passthrough);
    edge = owner.apply(right_trigger | up | circle | face, 2, false, false, default_passthrough);
    check(edge.suppressed == (right_trigger | face), "default policy reserves Up and Circle for FFXI");
    owner.apply(0, 2, false, false, default_passthrough);
    edge = owner.apply(right_trigger | up, 2, false, false);
    check(edge.suppressed == (right_trigger | up), "explicit override allows R2 plus Up capture");
    edge = owner.apply(up, 2, false, true, default_passthrough);
    check(edge.suppressed == up && edge.up == right_trigger, "menu or policy change keeps captured Up");
    edge = owner.apply(0, 2, false, true, default_passthrough);
    check(!edge.suppressed && edge.buffered_mask() == up, "buffered Up release retains its owner");
    check(!owner.apply(up, 2, false, true, default_passthrough).buffered_mask(), "fresh native Up passes");

    owner.reset();
    owner.apply(0, 2, false, false, 0, 1);
    owner.apply(right_trigger | up | circle, 2, false, false, 0, 10);
    check(owner.apply(up | circle, 2, false, false, 0, 20).suppressed == (up | circle),
        "trigger release begins directional handoff delay");
    check(owner.apply(up | circle, 2, false, false, 0, 139).suppressed == (up | circle),
        "held direction stays captured during delay");
    check(owner.apply(up | circle, 2, false, false, 0, 140).suppressed == circle,
        "only direction returns to native control after delay");

    check(read_xbox(0x1009 | 0x0200, 5, 4) == (up | right | face | left_trigger),
        "Xbox layout ignores unrelated shoulder and preserves trigger threshold");
    check(read_xbox(0x0100, 4, 5) == right_trigger, "LB stays native and RT works independently");
    check(read_xbox(0x0100, 5, 5) == (left_trigger | right_trigger),
        "physical LT and RT register together");
    check(read_xbox(0x0230, 0, 0) == (share | chooser), "standard Xbox uses View and Menu");
    check(read_xbox(0x0010, 0, 0, true) == 0 &&
        read_xbox(0x0220, 0, 0, true) == (share | chooser), "Xbox alternate preserves Menu and captures RB");
    owner.reset();
    owner.apply(0, 2, false, false);
    check(owner.apply(chooser | up, 2, false, false).suppressed == (chooser | up),
        "simultaneous chooser and direction are both captured");
    check(owner.apply(up, 2, false, false).suppressed == up, "chooser direction owns its release");
    owner.apply(0, 2, false, false);
    check(owner.apply(share | face, 2, false, false).suppressed == (share | face),
        "simultaneous binder and face are both captured");
    owner.apply(0, 2, false, false);
    check(owner.apply(share | chooser | face, 2, false, true).suppressed == 0,
        "monitor or chat leaves auxiliary buttons native");
    std::uint8_t buttons[32]{};
    buttons[1] = buttons[6] = buttons[10] = 0x80;
    check(read_joystick(4500, buttons, false) == (up | right | face | left_trigger), "DirectInput layout");
    filter_joystick(buttons, face | left_trigger, false);
    check(!buttons[1] && !buttons[6] && buttons[10], "DirectInput unrelated button stays intact");
    buttons[9] = 0x80;
    check(read_joystick(0xffffffffu, buttons, false) == chooser, "DirectInput Options/Start mapping");
    filter_joystick(buttons, chooser, false);
    check(!buttons[9] && buttons[10], "DirectInput chooser preserves unrelated input");
    buttons[2] = 0x80;
    check(read_joystick(0xffffffffu, buttons, true) == face, "FightPad mapping");
}
