#pragma once

#include <type_traits>
#include "ownership.hpp"

namespace xb {
// Version 1 ABI. The hook owns all memory passed to the policy DLL.
// Keep the wire layout stable, and use a new export for an incompatible ABI.
struct LogicInput {
    std::uint64_t now;
    std::uint32_t raw, mode, menu, native_menu, targeting, banks, binding, trust_slots;
};
static_assert(std::is_standard_layout_v<Ownership> && std::is_trivially_copyable_v<Ownership>);
static_assert(sizeof(Ownership) == 24 && sizeof(LogicInput) == 40 && sizeof(Sample) == 12);
using ApplyLogic = void (__cdecl*)(Ownership*, const LogicInput*, Sample*);
constexpr char logic_export[] = "xb_logic_v1_apply";
}
