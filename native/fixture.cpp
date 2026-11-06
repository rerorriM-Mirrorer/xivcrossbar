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

    check(read_xbox(0x1009 | 0x0200, 5, 4) == (up | right | face | left_trigger),
        "Xbox layout ignores unrelated shoulder and preserves trigger threshold");
    std::uint8_t buttons[32]{};
    buttons[1] = buttons[6] = buttons[9] = 0x80;
    check(read_joystick(4500, buttons, false) == (up | right | face | left_trigger), "DirectInput layout");
    filter_joystick(buttons, face | left_trigger, false);
    check(!buttons[1] && !buttons[6] && buttons[9], "DirectInput unrelated button stays intact");
    buttons[2] = 0x80;
    check(read_joystick(0xffffffffu, buttons, true) == face, "FightPad mapping");
}
