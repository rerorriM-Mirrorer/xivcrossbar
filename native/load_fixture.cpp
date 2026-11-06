#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstdio>

int main() {
    HMODULE dll = LoadLibraryW(L"xb_gamepad.dll");
    if (!dll) { std::printf("LoadLibrary error %lu\n", GetLastError()); return 1; }
    auto lua_open = reinterpret_cast<int (__cdecl*)(void*)>(GetProcAddress(dll, "luaopen_xb_gamepad"));
    if (!lua_open || lua_open(nullptr) != 0) return 4; // no LuaCore in this test process
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
    unsigned status[7]{};
    const auto count = poll(0, edges, 8, status);
    FreeLibrary(dll);
    return count || status[1] ? 3 : 0;
}
