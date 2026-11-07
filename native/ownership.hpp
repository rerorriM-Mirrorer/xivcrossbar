#pragma once
#include <cstdint>

namespace xb {
constexpr unsigned up = 1, circle = 0x40, slots = 0xff, triggers = 0xc00;
constexpr unsigned directions = 0xf, direction_resume_ms = 120;
constexpr unsigned share = 0x100, chooser = 0x200;
constexpr unsigned controls = slots | triggers | share | chooser;
constexpr unsigned personal_buttons = 0x7f000;
constexpr unsigned default_passthrough = up | circle;

struct Sample {
    unsigned suppressed;
    unsigned down;
    unsigned up;

    // Buffered releases belong to the same owner as their press.
    unsigned buffered_mask() const { return suppressed | up; }
};

class Ownership {
    unsigned previous_ = 0;
    unsigned owned_ = 0;
    std::uint64_t direction_resume_at_ = 0;
    bool armed_ = false;
public:
    void reset() { previous_ = owned_ = 0; armed_ = false; direction_resume_at_ = 0; }

    // mode 1 is the isolated Up and Circle probe. Mode 2 routes the normal crossbar.
    Sample apply(unsigned raw, unsigned mode, bool menu, bool native_menu, unsigned passthrough = 0,
        std::uint64_t now = 0, unsigned extra = 0, bool translate = false) {
        if (!armed_) {
            armed_ = !(raw & (controls | extra));
            return {};
        }
        const unsigned down = raw & ~previous_;
        const unsigned released = owned_ & ~raw;
        previous_ = raw;
        owned_ &= raw;
        unsigned capture = mode == 1 ? (up | circle) : 0;
        if (mode == 2 && !native_menu) {
            capture = triggers | share | chooser | extra;
            if (menu || translate || ((owned_ | down) & (triggers | share | chooser)))
                capture |= slots & ~passthrough;
        }
        const unsigned acquired = down & capture;
        owned_ |= acquired;
        if (now && mode == 2 && !translate) {
            if (menu || (owned_ & triggers)) direction_resume_at_ = 0;
            else if (released & triggers) direction_resume_at_ = now + direction_resume_ms;
            if (direction_resume_at_ && now >= direction_resume_at_) {
                owned_ &= ~directions;
                direction_resume_at_ = 0;
            }
        }
        return {owned_, acquired, released};
    }
};
}
