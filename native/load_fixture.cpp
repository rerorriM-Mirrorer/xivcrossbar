#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <xinput.h>
#include <atomic>
#include <cstdio>
#include <initializer_list>
#include <thread>
#include "controller_logic.hpp"

int main() {
    HMODULE dll = LoadLibraryW(L"xb_gamepad_messages.dll");
    if (!dll) { std::printf("LoadLibrary error %lu\n", GetLastError()); return 1; }
    auto lua_open = reinterpret_cast<int (__cdecl*)(void*)>(GetProcAddress(dll, "luaopen_xb_gamepad_messages"));
    if (!lua_open || lua_open(nullptr) != 0) return 4; // no LuaCore in this test process
    HMODULE host = LoadLibraryW(L"LuaCore.dll");
    if (!host) return 11;
    auto verify = reinterpret_cast<bool (__cdecl*)(int (__cdecl*)(void*))>(
        GetProcAddress(host, "verify_messages_module"));
    if (!verify || !verify(lua_open)) return 12;
    FreeLibrary(host);
    auto begin = reinterpret_cast<unsigned (__cdecl*)(unsigned, unsigned, unsigned, unsigned, const char*)>(
        GetProcAddress(dll, "xb_begin"));
    auto off = reinterpret_cast<void (__cdecl*)()>(GetProcAddress(dll, "xb_off"));
    auto poll = reinterpret_cast<unsigned (__cdecl*)(unsigned, int*, unsigned, unsigned*)>(
        GetProcAddress(dll, "xb_poll"));
    auto extra=reinterpret_cast<void (__cdecl*)(unsigned,unsigned)>(GetProcAddress(dll,"xb_extra_capture"));
    if (!extra) return 21;
    extra(0,1u<<19);extra(0,0);
    if (!begin || !off || !poll || begin(0, 0, 0, 0, "") != 0 ||
        begin(1, 0, 1, 0, "xb_fixture_missing.dll") != 0) return 2;
    auto detach = reinterpret_cast<unsigned (__cdecl*)()>(GetProcAddress(dll, "xb_detach"));
    if (!detach || detach() != 1) return 5;
    off();
    int edges[8]{};
    unsigned status[8]{};
    const auto count = poll(0, edges, 8, status);
    if (count || status[1]) return 3;
    HMODULE xinput = LoadLibraryExW(L"xinput1_4.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!xinput) return 6;
    auto state = reinterpret_cast<DWORD (WINAPI*)(DWORD, XINPUT_STATE*)>(
        GetProcAddress(xinput, "XInputGetState"));
    if (!state) return 7;
    XINPUT_STATE gamepad{};
    const auto disconnected = state(0, &gamepad) == ERROR_DEVICE_NOT_CONNECTED;
    if (begin(1, 0, 3, 0, "auto") != 1) return 8;
    auto load_logic = reinterpret_cast<unsigned (__cdecl*)(unsigned)>(GetProcAddress(dll, "xb_load_policy"));
    auto revision = reinterpret_cast<unsigned (__cdecl*)()>(GetProcAddress(dll, "xb_policy_revision"));
    auto action = reinterpret_cast<unsigned (__cdecl*)(unsigned)>(GetProcAddress(dll, "xb_policy_action"));
    if (!action || action(99) != 0) return 20;
    if (!load_logic || !revision || revision() != 1) return 14;
    auto initial = GetModuleHandleW(L"xb_controller_logic_1.dll");
    if (!initial || !CopyFileW(L"LuaCore.dll", L"xb_controller_logic_4.dll", FALSE)) return 15;
    const auto incompatible = load_logic(4);
    DeleteFileW(L"xb_controller_logic_4.dll");
    if (incompatible != ERROR_PROC_NOT_FOUND || load_logic(999999) != ERROR_MOD_NOT_FOUND
        || revision() != 1 || GetModuleHandleW(L"xb_controller_logic_1.dll") != initial) return 16;
    auto apply = reinterpret_cast<xb::ApplyLogic>(GetProcAddress(initial, xb::logic_export));
    if (!apply) return 17;
    xb::Ownership ownership;
    xb::Sample filtered;
    xb::LogicInput input{1, 0, 2, 0, 0, 0, 0, 0, 0};
    apply(&ownership, &input, &filtered);
    input.raw = 0x400 | xb::up;
    apply(&ownership, &input, &filtered);
    if (filtered.suppressed != input.raw || filtered.down != input.raw) return 18;
    if (disconnected && state(0, &gamepad) != ERROR_DEVICE_NOT_CONNECTED) return 9;
    // Keep polling while the addon releases and reacquires the entry points.
    std::atomic<bool> running{true};
    std::atomic<unsigned> samples{0};
    std::thread reader([&] {
        XINPUT_STATE sample{};
        while (running) {
            state(0, &sample);
            ++samples;
        }
    });
    while (!samples) std::this_thread::yield();
    bool swapped = true;
    unsigned previous = 1;
    const wchar_t* filenames[] = {L"xb_controller_logic_1.dll", L"xb_controller_logic_2.dll", L"xb_controller_logic_3.dll"};
    for (unsigned next : {2u, 3u, 1u, 3u, 2u, 1u}) {
        if (load_logic(next) != ERROR_SUCCESS || revision() != next
            || GetModuleHandleW(filenames[previous - 1])) {
            swapped = false;
            break;
        }
        auto current = GetModuleHandleW(filenames[next - 1]);
        auto policy = reinterpret_cast<xb::ApplyLogic>(GetProcAddress(current, xb::logic_export));
        if (!policy) { swapped = false; break; }
        ownership.reset();
        input.raw = 0; input.targeting = 1;
        policy(&ownership, &input, &filtered);
        input.raw = xb::l1 | xb::r1;
        policy(&ownership, &input, &filtered);
        if (filtered.suppressed != (next == 3 ? input.raw : 0u)) { swapped = false; break; }
        if (action(99) != 0) { swapped = false; break; }
        previous = next;
        poll(4, edges, 8, status);
    }
    bool detached = true;
    for (unsigned i = 0; i < 8 && detached; ++i) {
        detached = detach() == 1 && begin(1, i % 2, 3, i % 2 ? 2 : 0, "auto") == 1;
        poll(4, edges, 8, status);
    }
    running = false;
    reader.join();
    if (!swapped) return 19;
    if (!detached || detach() != 1 || detach() != 1) return 10;
    // Drop the caller's reference. The pin retains executable code and
    // trampolines until FFXI exits.
    FreeLibrary(dll);
    if (GetModuleHandleW(L"xb_gamepad_messages.dll") != dll) return 13;
    FreeLibrary(xinput);
    return 0;
}
