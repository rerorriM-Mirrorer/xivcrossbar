#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <xinput.h>
#include <cstdio>

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
    if (disconnected && state(0, &gamepad) != ERROR_DEVICE_NOT_CONNECTED) return 9;
    if (detach() != 1 || begin(1, 1, 3, 2, "auto") != 1 || detach() != 1) return 10;
    // The bridge is pinned after installing hooks; these handles can close
    // after both entry points have been restored.
    FreeLibrary(xinput);
    FreeLibrary(dll);
    return 0;
}
