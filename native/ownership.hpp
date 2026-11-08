#pragma once
#include <cstdint>

namespace xb {
constexpr unsigned up = 1, circle = 0x40, slots = 0xff, triggers = 0xc00;
constexpr unsigned directions = 0xf, direction_resume_ms = 120;
constexpr unsigned share = 0x100, chooser = 0x200;
constexpr unsigned l1 = 0x1000, r1 = 0x2000;
constexpr unsigned controls = slots | triggers | share | chooser;
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
    unsigned shoulder_directions_ = 0;
    std::uint64_t direction_resume_at_ = 0;
    bool armed_ = false;
public:
    void reset() { previous_ = owned_ = shoulder_directions_ = 0; armed_ = false; direction_resume_at_ = 0; }

    // mode 1 is the isolated Up and Circle probe. Mode 2 routes the normal crossbar.
    Sample apply(unsigned raw, unsigned mode, bool menu, bool native_menu, unsigned passthrough = 0,
        std::uint64_t now = 0, bool targeting = false, unsigned banks = 0, bool binding = false) {
        if (!armed_) {
            armed_ = !(raw & controls);
            previous_ = raw;
            return {};
        }
        const unsigned down = raw & ~previous_;
        const unsigned released = owned_ & ~raw;
        previous_ = raw;
        owned_ &= raw;
        shoulder_directions_ &= raw;
        unsigned capture = mode == 1 ? (up | circle) : 0;
        if (mode == 2 && !native_menu) {
            const unsigned shoulders = raw & (l1 | r1);
            const unsigned bank = shoulders == (l1 | r1) ? 4 : shoulders == r1 ? 2 : shoulders == l1 ? 1 : 0;
            const bool bank_owns = !menu && (banks & bank) && !(raw & (triggers | share | chooser));

            capture = triggers | share | chooser;
            if (binding && menu) capture |= l1 | r1;
            if (bank_owns) {
                capture |= shoulders | slots;
                shoulder_directions_ |= down & directions;
            }
            if (targeting && !menu && !(raw & (l1 | triggers | share | chooser)))
                capture |= r1;
            if (menu || ((owned_ | down) & (triggers | share | chooser)))
                capture |= slots & ~passthrough;
        }
        const unsigned acquired = down & capture;
        owned_ |= acquired;
        if (now && mode == 2) {
            if (menu || (owned_ & (triggers | l1 | r1))) direction_resume_at_ = 0;
            else if (released & triggers) direction_resume_at_ = now + direction_resume_ms;
            if (direction_resume_at_ && now >= direction_resume_at_) {
                owned_ &= ~(directions & ~shoulder_directions_);
                direction_resume_at_ = 0;
            }
        }
        return {owned_, acquired, released};
    }
};
}
