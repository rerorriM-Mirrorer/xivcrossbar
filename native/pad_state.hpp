#pragma once
#include <cstdint>

namespace xb {
constexpr unsigned xbox[] = {1, 8, 2, 4, 0x1000, 0x4000, 0x2000, 0x8000};
constexpr unsigned dualsense[] = {1, 0, 2, 3, 6, 7};
constexpr unsigned fightpad[] = {2, 1, 3, 0, 6, 7};
constexpr unsigned logical_buttons[] = {4, 5, 6, 7, 10, 11};

inline unsigned read_xbox(unsigned buttons, unsigned left, unsigned right) {
    unsigned raw = (left > 4 ? 0x400 : 0) | (right > 4 ? 0x800 : 0);
    for (unsigned i = 0; i < 8; ++i)
        if (buttons & xbox[i]) raw |= 1u << i;
    return raw;
}
inline unsigned read_joystick(unsigned pov, const std::uint8_t* buttons, bool fight) {
    unsigned raw = 0;
    if (pov < 36000 && pov % 4500 == 0) {
        raw = 1u << (pov / 9000);
        if (pov % 9000) raw |= 1u << ((pov / 9000 + 1) % 4);
    }
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < 6; ++i)
        if (buttons[map[i]] & 0x80) raw |= 1u << logical_buttons[i];
    return raw;
}
inline unsigned filter_hat(unsigned pov, unsigned suppressed) {
    if (pov >= 36000 || pov % 4500 != 0) return pov;
    const unsigned first = pov / 9000;
    const unsigned second = (first + 1) % 4;
    if (!(suppressed & (1u << first)))
        return (pov % 9000 && (suppressed & (1u << second))) ? first * 9000 : pov;
    if (pov % 9000 && !(suppressed & (1u << second))) return second * 9000;
    return 0xffffffffu;
}
inline void filter_joystick(std::uint8_t* buttons, unsigned suppressed, bool fight) {
    const auto* map = fight ? fightpad : dualsense;
    for (unsigned i = 0; i < 6; ++i)
        if (suppressed & (1u << logical_buttons[i])) buttons[map[i]] &= 0x7f;
}
}
