// Windower's Lua 5.1 ABI is exported by the already-loaded LuaCore.dll.
// Resolve only the calls used here, without loading a second Lua runtime.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstddef>

struct lua_State;
extern "C" unsigned __cdecl xb_begin(unsigned, unsigned, unsigned, unsigned, const char*);
extern "C" void __cdecl xb_off();
extern "C" unsigned __cdecl xb_detach();
extern "C" unsigned __cdecl xb_poll(unsigned, int*, unsigned, unsigned*);

namespace {
using LuaFunction = int (__cdecl*)(lua_State*);
struct Api {
    std::ptrdiff_t (__cdecl* integer)(lua_State*, int);
    const char* (__cdecl* string)(lua_State*, int, size_t*);
    void (__cdecl* push)(lua_State*, std::ptrdiff_t);
    void (__cdecl* table)(lua_State*, int, int);
    void (__cdecl* closure)(lua_State*, LuaFunction, int);
    void (__cdecl* field)(lua_State*, int, const char*);
    void (__cdecl* index)(lua_State*, int, int);
} api;

template<typename T>
bool resolve(HMODULE host, T& function, const char* name) {
    function = reinterpret_cast<T>(GetProcAddress(host, name));
    return function != nullptr;
}

int begin(lua_State* L) {
    const unsigned result = xb_begin(static_cast<unsigned>(api.integer(L, 1)),
        static_cast<unsigned>(api.integer(L, 2)), static_cast<unsigned>(api.integer(L, 3)),
        static_cast<unsigned>(api.integer(L, 4)), api.string(L, 5, nullptr));
    api.push(L, result);
    return 1;
}
int off(lua_State*) { xb_off(); return 0; }
int detach(lua_State* L) { api.push(L, xb_detach()); return 1; }
int tap_tab(lua_State* L) {
    DWORD pid = 0;
    GetWindowThreadProcessId(GetForegroundWindow(), &pid);
    // Never turn an unmodified controller tap into Alt+Tab or a modified key.
    if (pid != GetCurrentProcessId() || (GetAsyncKeyState(VK_MENU) & 0x8000) ||
        (GetAsyncKeyState(VK_CONTROL) & 0x8000) || (GetAsyncKeyState(VK_SHIFT) & 0x8000) ||
        (GetAsyncKeyState(VK_LWIN) & 0x8000) || (GetAsyncKeyState(VK_RWIN) & 0x8000) ||
        (GetAsyncKeyState(VK_TAB) & 0x8000)) {
        api.push(L, 0);
        return 1;
    }
    INPUT keys[2]{};
    keys[0].type = keys[1].type = INPUT_KEYBOARD;
    keys[0].ki.wScan = keys[1].ki.wScan = static_cast<WORD>(MapVirtualKeyW(VK_TAB, MAPVK_VK_TO_VSC));
    keys[0].ki.dwFlags = KEYEVENTF_SCANCODE;
    keys[1].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
    const UINT sent = SendInput(2, keys, sizeof(INPUT));
    if (sent == 1) SendInput(1, &keys[1], sizeof(INPUT));
    api.push(L, sent == 2 ? 1 : 0);
    return 1;
}
int poll(lua_State* L) {
    int edges[256]{};
    unsigned status[8]{};
    const auto count = xb_poll(static_cast<unsigned>(api.integer(L, 1)), edges, 256, status);
    api.table(L, count, 0);
    for (unsigned i = 0; i < count; ++i) {
        api.push(L, edges[i]);
        api.index(L, -2, i + 1);
    }
    api.table(L, 8, 0);
    for (int i = 0; i < 8; ++i) {
        api.push(L, status[i]);
        api.index(L, -2, i + 1);
    }
    return 2;
}
}

extern "C" __declspec(dllexport) int __cdecl luaopen_xb_gamepad_messages(lua_State* L) {
    bool resolved = false;
    const wchar_t* hosts[] = {L"LuaCore.dll", L"lua51.dll", L"lua5.1.dll"};
    for (auto name : hosts) {
        const HMODULE host = GetModuleHandleW(name);
        if (!host || !resolve(host, api.integer, "lua_tointeger") ||
            !resolve(host, api.string, "lua_tolstring") || !resolve(host, api.push, "lua_pushinteger") ||
            !resolve(host, api.table, "lua_createtable") || !resolve(host, api.closure, "lua_pushcclosure") ||
            !resolve(host, api.field, "lua_setfield") || !resolve(host, api.index, "lua_rawseti")) continue;
        resolved = true;
        break;
    }
    if (!resolved) return 0;
    api.table(L, 0, 6);
    api.closure(L, begin, 0); api.field(L, -2, "begin");
    api.push(L, GetCurrentProcessId()); api.field(L, -2, "process_id");
    api.closure(L, off, 0); api.field(L, -2, "off");
    api.closure(L, detach, 0); api.field(L, -2, "detach");
    api.closure(L, tap_tab, 0); api.field(L, -2, "tap_tab");
    api.closure(L, poll, 0); api.field(L, -2, "poll");
    return 1;
}
