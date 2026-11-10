#define WIN32_LEAN_AND_MEAN
#include <windows.h>

extern "C" __declspec(dllexport) unsigned __cdecl xb_logic_v1_action(unsigned action) {
    if (action != 1 && action != 2) return 0;
    DWORD pid = 0;
    GetWindowThreadProcessId(GetForegroundWindow(), &pid);
    // Never turn an unmodified controller tap into Alt+Tab or a modified key.
    if (pid != GetCurrentProcessId() || (GetAsyncKeyState(VK_MENU) & 0x8000) ||
        (GetAsyncKeyState(VK_CONTROL) & 0x8000) || (GetAsyncKeyState(VK_SHIFT) & 0x8000) ||
        (GetAsyncKeyState(VK_LWIN) & 0x8000) || (GetAsyncKeyState(VK_RWIN) & 0x8000) ||
        (GetAsyncKeyState(VK_TAB) & 0x8000)) {
        return 0;
    }
    const bool reverse = action == 2;
    INPUT keys[4]{};
    auto set_key = [&](unsigned index, UINT key, bool release) {
        keys[index].type = INPUT_KEYBOARD;
        keys[index].ki.wScan = static_cast<WORD>(MapVirtualKeyW(key, MAPVK_VK_TO_VSC));
        keys[index].ki.dwFlags = KEYEVENTF_SCANCODE | (release ? KEYEVENTF_KEYUP : 0);
    };
    const unsigned tab = reverse ? 1u : 0u;
    const unsigned count = reverse ? 4u : 2u;
    set_key(tab, VK_TAB, false);
    set_key(tab + 1, VK_TAB, true);
    if (reverse) {
        set_key(0, VK_LSHIFT, false);
        set_key(3, VK_LSHIFT, true);
    }
    const UINT sent = SendInput(count, keys, sizeof(INPUT));
    if (sent == tab + 1) SendInput(1, &keys[tab + 1], sizeof(INPUT));
    if (reverse && sent > 0 && sent < count) SendInput(1, &keys[3], sizeof(INPUT));
    return sent == count ? 1 : 0;
}
