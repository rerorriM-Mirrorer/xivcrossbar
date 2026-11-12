#define WIN32_LEAN_AND_MEAN
#define DIRECTINPUT_VERSION 0x0800
#include <windows.h>
#include <dinput.h>
#include <dinputd.h>
#include <xinput.h>
#include <MinHook.h>
#include <mmsystem.h>
#include <array>
#include <cstddef>
#include <cstring>
#include <mutex>
#include <utility>
#include <string>
#include "controller_logic.hpp"
#include "pad_state.hpp"

static_assert(sizeof(void*) == 4, "Windower 4 requires an x86 DLL");
namespace {
using XboxRead = DWORD (WINAPI*)(DWORD, XINPUT_STATE*);
using DirectRead = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, void*);
using DirectBuffered = HRESULT (STDMETHODCALLTYPE*)(IDirectInputDevice8A*, DWORD, DIDEVICEOBJECTDATA*, DWORD*, DWORD);
// Five system XInput DLLs, each with public GetState and optional GetStateEx.
constexpr unsigned max_xbox_hooks = 10;
struct XboxHook {
    XboxRead original{};
    XINPUT_GAMEPAD previous{};
    DWORD source_packet{}, visible_packet{};
    bool initialized{};
};
std::array<XboxHook, max_xbox_hooks> xbox_hooks;
thread_local bool xbox_nested;

DirectRead direct_original;
DirectBuffered buffered_original;
std::mutex guard;
HMODULE policy_module;
xb::ApplyLogic apply_logic;
using PolicyAction = unsigned (__cdecl*)(unsigned);
PolicyAction policy_action;
unsigned policy_revision;
bool waiting_for_neutral, discard_buffered_batch;
xb::Ownership ownership, buffered_ownership;
unsigned buffered_raw;
DIDEVICEOBJECTDATA buffered_hat{};
bool buffered_hat_pending;
std::array<int, 256> events{};
unsigned head, count, generation, mode, device, raw, suppressed, calls, buffered_calls, unsupported;
unsigned backend, last_context, banks, trust_slots;
unsigned extra_plain, extra_l1;
xb::FocusHandoff focus_handoff;
bool inherit_modifiers, personal_set_controls;
bool menu, native_menu, targeting, binding, fightpad, r1_chooser, overflow, buffered_seen, probe_ready;
GUID joystick;
ULONGLONG heartbeat, last_sample;

void reset() {
    ownership.reset();
    buffered_ownership.reset();
    buffered_raw = 0;
    buffered_hat_pending = false;
    probe_ready = false;
    head = count = raw = suppressed = 0;
    ++generation;
}
xb::Sample apply_policy(xb::Ownership& state, unsigned buttons, unsigned policy_mode,
    ULONGLONG now = 0, bool use_targeting = false, unsigned use_banks = 0,
    bool use_binding = false, unsigned use_trust_slots = 0) {
    const xb::LogicInput input{now, buttons, policy_mode, menu, native_menu,
        use_targeting, use_banks | ((extra_plain | ((buttons & xb::l1) && !(buttons & (xb::triggers | xb::r1 | xb::share | xb::chooser)) ? extra_l1 : 0)) & xb::extra_controls) | (inherit_modifiers ? 8u : 0u) | (personal_set_controls ? 16u : 0u), use_binding, use_trust_slots};
    xb::Sample result{};
    apply_logic(&state, &input, &result);
    // Suppress low analog values too while zoom owns an axis; digital edges
    // still require crossing the shared threshold and preserve release ownership.
    if (policy_mode==2 && !menu && !native_menu)
        result.suppressed |= input.banks & xb::right_directions;
    return result;
}

void enqueue(int edge) {
    if (count == events.size()) { overflow = true; return; }
    events[(head + count++) % events.size()] = edge;
}
unsigned observe(unsigned buttons) {
    ++calls;
    raw = buttons;
    const auto now = GetTickCount64();
    if (last_sample && now - last_sample > 500) reset();
    last_sample = now;
    DWORD foreground = 0;
    GetWindowThreadProcessId(GetForegroundWindow(), &foreground);
    const auto focus_mask=focus_handoff.sample(buttons,foreground==GetCurrentProcessId(),mode==3,
        !heartbeat || last_context==4);
    if (!apply_logic || !mode || !heartbeat || foreground != GetCurrentProcessId() || now - heartbeat > 500 ||
        (mode == 2 && buffered_seen) || overflow) {
        if (suppressed || count) reset();
        ownership.reset();
        probe_ready = false;
        buffered_ownership.reset();
        buffered_raw = 0;
        buffered_hat_pending = false;
        suppressed = focus_mask;
        return focus_mask;
    }
    if (waiting_for_neutral) {
        if (buttons & (xb::controls | xb::l1 | xb::r1)) return focus_mask;
        waiting_for_neutral = false;
    }
    if ((mode == 1 || mode == 3) && !probe_ready && (!(buttons & xb::controls)
        || (mode==3 && inherit_modifiers && (buttons & (xb::triggers | xb::l1 | xb::r1))))) {
        probe_ready = true;
        buffered_raw=inherit_modifiers ? buttons : 0;
        apply_policy(buffered_ownership, buffered_raw, 2);
    }
    const auto result = apply_policy(ownership, buttons, mode == 3 ? 2 : mode, mode == 3 ? now : 0,
        mode == 3 && targeting, mode == 3 ? banks : 0, mode == 3 && binding, mode == 3 ? trust_slots : 0);
    suppressed = result.suppressed | focus_mask;
    if (mode == 3) return suppressed;
    // Releases precede presses; simultaneous triggers precede face/D-pad.
    for (int i = 0; i < 12; ++i)
        if (result.up & (1u << i)) enqueue(-(i + 1));
    for (int i : {10, 11, 0, 1, 2, 3, 4, 5, 6, 7})
        if (result.down & (1u << i)) enqueue(i + 1);
    if (overflow) { reset(); return 0; }
    return suppressed;
}

template<unsigned Hook>
DWORD WINAPI xbox_read(DWORD index, XINPUT_STATE* state) {
    auto& hook = xbox_hooks[Hook];
    // One system XInput export can call another. Observe the outermost read.
    if (xbox_nested) return hook.original(index, state);
    xbox_nested = true;
    const DWORD result = hook.original(index, state);
    xbox_nested = false;
    std::lock_guard lock(guard);
    if (backend != 1 || index != device) return result;
    if (result != ERROR_SUCCESS || !state) {
        hook.initialized = false;
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    auto& pad = state->Gamepad;
    const unsigned mask = observe(xb::read_xbox(pad.wButtons, pad.bLeftTrigger, pad.bRightTrigger, r1_chooser)
        | xb::read_right(pad.sThumbRX/32768.0, -pad.sThumbRY/32768.0));
    if (mask & (1u<<14)) pad.wButtons &= ~0x40;
    if (mask & (1u<<15)) pad.wButtons &= ~0x80;
    if (mask & ((1u<<19)|(1u<<21))) pad.sThumbRY=0;
    if (mask & ((1u<<20)|(1u<<22))) pad.sThumbRX=0;
    for (unsigned i = 0; i < 10; ++i)
        if (mask & (1u << i)) pad.wButtons &= static_cast<WORD>(~xb::xbox_button(i, r1_chooser));
    if (mask & xb::l1) pad.wButtons &= static_cast<WORD>(~xb::xbox_button(12, r1_chooser));
    if (mask & xb::r1) pad.wButtons &= static_cast<WORD>(~xb::xbox_button(13, r1_chooser));
    if (mask & 0x400) pad.bLeftTrigger = 0;
    if (mask & 0x800) pad.bRightTrigger = 0;
    if (!mode && !hook.initialized) return result;
    // A context change or D-pad handoff can change the filtered state without
    // changing the hardware packet number. Notify consumers of that change.
    if (!hook.initialized) hook.visible_packet = state->dwPacketNumber;
    else if (hook.source_packet != state->dwPacketNumber ||
        memcmp(&hook.previous, &pad, sizeof pad) != 0) ++hook.visible_packet;
    hook.source_packet = state->dwPacketNumber;
    hook.previous = pad;
    hook.initialized = true;
    state->dwPacketNumber = hook.visible_packet;
    return result;
}

template<std::size_t... I>
constexpr auto xbox_entries(std::index_sequence<I...>) {
    return std::array<XboxRead, sizeof...(I)>{xbox_read<I>...};
}
constexpr auto xbox_detours = xbox_entries(std::make_index_sequence<max_xbox_hooks>{});
constexpr const char* xbox_modules[] = {
    "xinput1_4.dll", "xinput1_3.dll", "xinput9_1_0.dll", "xinput1_2.dll", "xinput1_1.dll"
};

bool is_selected(IDirectInputDevice8A* object) {
    DIDEVICEINSTANCEA info{};
    info.dwSize = sizeof(info);
    return SUCCEEDED(object->GetDeviceInfo(&info)) && IsEqualGUID(info.guidInstance, joystick);
}
double axis_value(IDirectInputDevice8A* object,DWORD offset,LONG value,LONG* center=nullptr) {
    DIPROPRANGE range{};range.diph.dwSize=sizeof range;range.diph.dwHeaderSize=sizeof range.diph;
    range.diph.dwObj=offset;range.diph.dwHow=DIPH_BYOFFSET;
    if (FAILED(object->GetProperty(DIPROP_RANGE,&range.diph)) || range.lMax<=range.lMin) return 0;
    const double middle=(double(range.lMin)+range.lMax)/2;
    if (center) *center=static_cast<LONG>(middle);
    return (value-middle)/((double(range.lMax)-range.lMin)/2);
}
unsigned read_direct(IDirectInputDevice8A* object,const DIJOYSTATE& state) {
    auto result=xb::read_joystick(state.rgdwPOV[0],state.rgbButtons,fightpad);
    if (!fightpad) result|=xb::read_right(axis_value(object,DIJOFS_Z,state.lZ),axis_value(object,DIJOFS_RZ,state.lRz));
    return result;
}
HRESULT STDMETHODCALLTYPE direct_read(IDirectInputDevice8A* object, DWORD size, void* state) {
    const HRESULT result = direct_original(object, size, state);
    std::lock_guard lock(guard);
    if (backend != 2 || !mode || !is_selected(object)) return result;
    if (size != sizeof(DIJOYSTATE) && size != sizeof(DIJOYSTATE2)) {
        ++unsupported;
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    if (FAILED(result) || !state) {
        if (last_sample) { reset(); last_sample = 0; }
        return result;
    }
    // DIJOYSTATE and DIJOYSTATE2 share offsets through the first 32 buttons.
    auto* bytes = static_cast<unsigned char*>(state);
    DWORD pov;
    static_assert(offsetof(DIJOYSTATE, rgdwPOV) == offsetof(DIJOYSTATE2, rgdwPOV));
    static_assert(offsetof(DIJOYSTATE, rgbButtons) == offsetof(DIJOYSTATE2, rgbButtons));
    auto* hat = bytes + offsetof(DIJOYSTATE, rgdwPOV);
    auto* buttons = bytes + offsetof(DIJOYSTATE, rgbButtons);
    memcpy(&pov, hat, sizeof pov);
    const unsigned mask = observe(read_direct(object,*static_cast<DIJOYSTATE*>(state)));
    pov = xb::filter_hat(pov, mask);
    memcpy(hat, &pov, sizeof pov);
    xb::filter_joystick(buttons, mask, fightpad);
    xb::filter_extra_buttons(buttons,mask,fightpad);
    auto* joystick_state=static_cast<DIJOYSTATE*>(state);
    if (mask & ((1u<<19)|(1u<<21))) { LONG center=joystick_state->lRz;axis_value(object,DIJOFS_RZ,center,&center);joystick_state->lRz=center; }
    if (mask & ((1u<<20)|(1u<<22))) { LONG center=joystick_state->lZ;axis_value(object,DIJOFS_Z,center,&center);joystick_state->lZ=center; }
    return result;
}

HRESULT STDMETHODCALLTYPE direct_buffered(IDirectInputDevice8A* object, DWORD size,
    DIDEVICEOBJECTDATA* data, DWORD* entries, DWORD flags) {
    const DWORD capacity = entries ? *entries : 0;
    const HRESULT result = buffered_original(object, size, data, entries, flags);
    std::lock_guard lock(guard);
    if (backend == 2 && mode && apply_logic && is_selected(object)) {
        ++buffered_calls;
        if (!buffered_seen) {
            buffered_seen = true;
            if (mode == 2) reset();
        }
        const bool rearming = waiting_for_neutral || discard_buffered_batch;
        if ((heartbeat || mode==3) && SUCCEEDED(result)) {
            DIJOYSTATE2 current{};
            auto hr = direct_original(object, sizeof current, &current);
            if (FAILED(hr)) hr = direct_original(object, sizeof(DIJOYSTATE), &current);
            if (SUCCEEDED(hr)) observe(read_direct(object,*reinterpret_cast<DIJOYSTATE*>(&current)));
        }
        if (discard_buffered_batch && !waiting_for_neutral && SUCCEEDED(result)
            && entries && data && !(flags & DIGDD_PEEK) && *entries <= capacity
            && result != DI_BUFFEROVERFLOW && *entries < capacity)
            discard_buffered_batch = false;
        // Neutralize matching records, retaining timestamps,
        // sequence numbers, queue lengths and DIGDD_PEEK semantics.
        constexpr DWORD legacy_size = offsetof(DIDEVICEOBJECTDATA, uAppData);
        DWORD foreground = 0;
        GetWindowThreadProcessId(GetForegroundWindow(), &foreground);
        const bool quarantine_only=mode==3 && focus_handoff.blocked() && foreground==GetCurrentProcessId()
            && (!probe_ready || !heartbeat || GetTickCount64()-heartbeat>500);
        if (!quarantine_only && (rearming || (mode != 1 && mode != 3) || !probe_ready || !heartbeat || GetTickCount64() - heartbeat > 500 ||
            foreground != GetCurrentProcessId() || FAILED(result) || !data || !entries ||
            *entries > capacity || (size != legacy_size && size != sizeof(DIDEVICEOBJECTDATA))))
            return result;
        if (FAILED(result) || !data || !entries || *entries>capacity
            || (size!=legacy_size && size!=sizeof(DIDEVICEOBJECTDATA))) return result;
        last_sample = GetTickCount64();
        ++calls;
        auto* bytes = reinterpret_cast<unsigned char*>(data);
        auto stream = buffered_ownership;
        unsigned state = buffered_raw;
        auto hat = buffered_hat;
        bool hat_pending = buffered_hat_pending;
        const auto now = GetTickCount64();
        for (DWORD i = 0; i < *entries; ++i) {
            auto* record = bytes + i * size;
            DWORD offset, value;
            memcpy(&offset, record, sizeof offset);
            memcpy(&value, record + sizeof offset, sizeof value);
            DIDEVICEOBJECTINSTANCEA info{};
            info.dwSize = sizeof(info);
            if (FAILED(object->GetObjectInfo(&info, offset, DIPH_BYOFFSET))) continue;
            const auto instance = DIDFT_GETINSTANCE(info.dwType);
            const auto type = DIDFT_GETTYPE(info.dwType);
            if ((type & DIDFT_POV) && instance == 0) {
                const std::uint8_t neutral[32]{};
                state = (state & ~0xfu) | xb::read_joystick(value, neutral, fightpad);
                const auto mask = mode == 1 ? xb::up : focus_handoff.blocked() | (quarantine_only ? 0u : apply_policy(stream, state, 2, now, targeting, banks, binding, trust_slots).suppressed);
                if (mode == 3) memcpy(&hat, record, size);
                const auto filtered = xb::filter_hat(value, mask);
                hat_pending = mode == 3 && filtered != value;
                value = filtered;
            } else if (type & DIDFT_BUTTON) {
                const auto* map = fightpad ? xb::fightpad : xb::dualsense;
                unsigned bit = 0;
                for (unsigned j = 0; j < sizeof(xb::logical_buttons) / sizeof(*xb::logical_buttons); ++j)
                    if (instance == map[j]) bit = 1u << xb::logical_buttons[j];
                if (!fightpad && instance>=10 && instance<=14) bit=1u<<(14+instance-10);
                if (!bit) continue;
                state = (state & ~bit) | ((value & 0x80u) ? bit : 0);
                const auto mask = mode == 1 ? xb::circle : focus_handoff.blocked() | (quarantine_only ? 0u : apply_policy(stream, state, 2, now, targeting, banks, binding, trust_slots).buffered_mask());
                if (mask & bit) value &= ~0x80u;
            } else if (!fightpad && (type & DIDFT_AXIS) && (IsEqualGUID(info.guidType,GUID_ZAxis) || IsEqualGUID(info.guidType,GUID_RzAxis))) {
                const bool vertical=IsEqualGUID(info.guidType,GUID_RzAxis);
                LONG center=static_cast<LONG>(value);
                const double normalized=axis_value(object,offset,static_cast<LONG>(value),&center);
                const unsigned axis_mask=vertical ? ((1u<<19)|(1u<<21)) : ((1u<<20)|(1u<<22));
                const auto direction=vertical ? xb::read_right(0,normalized) : xb::read_right(normalized,0);
                state=(state & ~axis_mask)|direction;
                const auto mask=focus_handoff.blocked() | (quarantine_only ? 0u : apply_policy(stream,state,2,now,targeting,banks,binding,trust_slots).buffered_mask());
                if (mask & axis_mask) value=static_cast<DWORD>(center);
            } else continue;
            memcpy(record + sizeof offset, &value, sizeof value);
        }
        if (mode == 3 && hat_pending && *entries < capacity && result == DI_OK) {
            const auto mask = focus_handoff.blocked() | (quarantine_only ? 0u : apply_policy(stream, state, 2, now, targeting, banks, binding, trust_slots).suppressed);
            if (!(mask & state & xb::directions)) {
                hat.dwTimeStamp = GetTickCount();
                memcpy(bytes + (*entries)++ * size, &hat, size);
                hat_pending = false;
            }
        }
        if (!(flags & DIGDD_PEEK)) {
            buffered_hat = hat;
            buffered_hat_pending = hat_pending;
            buffered_ownership = stream;
            buffered_raw = state;
        }
    }
    return result;
}

// Attachment runs on the Lua thread. Callbacks never read these diagnostics.
const char* attach_operation;
long attach_code;
bool attach_failed(const char* operation, long code) {
    attach_operation = operation;
    attach_code = code;
    return false;
}

struct Enumeration { GUID instance; unsigned count; };
BOOL CALLBACK choose_device(const DIDEVICEINSTANCEA* info, void* context) {
    auto& pick = *static_cast<Enumeration*>(context);
    if (!pick.count++) pick.instance = info->guidInstance;
    return pick.count == 1 ? DIENUM_CONTINUE : DIENUM_STOP;
}

bool sole_reader_device(unsigned index) {
    JOYINFOEX sample{};
    sample.dwSize = sizeof sample;
    sample.dwFlags = JOY_RETURNBUTTONS;
    if (joyGetPosEx(index, &sample) != JOYERR_NOERROR) return false;
    // Confirm the reader's numbered device is the only responsive WinMM slot.
    // An attached DirectInput singleton alone does not establish that.
    for (unsigned slot = 0; slot < 16; ++slot) {
        if (slot != index && joyGetPosEx(slot, &sample) == JOYERR_NOERROR) return false;
    }
    return true;
}

void* targets[max_xbox_hooks];
unsigned target_count;
bool hooks_enabled;

bool set_hooks(bool enabled) {
    for (unsigned i = 0; i < target_count; ++i) {
        const auto result = enabled ? MH_QueueEnableHook(targets[i]) : MH_QueueDisableHook(targets[i]);
        if (result != MH_OK) {
            return enabled ? attach_failed("Queue native hooks", result) : false;
        }
    }
    const auto applied = MH_ApplyQueued();
    if (applied != MH_OK) return enabled ? attach_failed("Enable native hooks", applied) : false;
    hooks_enabled = enabled;
    return true;
}
bool install(unsigned kind, unsigned index, const char* module) {
    const auto mh = MH_Initialize();
    if (mh != MH_OK && mh != MH_ERROR_ALREADY_INITIALIZED)
        return attach_failed("Initialize MinHook", mh);
    if (kind == 1) {
        for (auto name : xbox_modules) {
            if (strcmp(module, "auto") != 0 && _stricmp(module, name) != 0) continue;
            const auto loaded = GetModuleHandleA(name);
            if (!loaded) continue;
            const LPCSTR entries[] = {"XInputGetState", MAKEINTRESOURCEA(100)};
            for (auto entry : entries) {
                auto* target = reinterpret_cast<void*>(GetProcAddress(loaded, entry));
                if (!target) continue;
                bool duplicate = false;
                for (unsigned i = 0; i < target_count; ++i)
                    if (targets[i] == target) duplicate = true;
                if (duplicate) continue;
                const auto i = target_count;
                const auto created = MH_CreateHook(target, reinterpret_cast<void*>(xbox_detours[i]),
                    reinterpret_cast<void**>(&xbox_hooks[i].original));
                if (created == MH_ERROR_UNSUPPORTED_FUNCTION) continue;
                if (created != MH_OK) {
                    while (target_count) MH_RemoveHook(targets[--target_count]);
                    return attach_failed("Install XInput hook", created);
                }
                targets[target_count++] = target;
            }
        }
        if (!target_count) return attach_failed("Find a hookable XInput entry point", ERROR_PROC_NOT_FOUND);
    } else {
        const auto loaded = GetModuleHandleA("dinput8.dll");
        if (!loaded) return attach_failed("Find dinput8.dll in FFXI", GetLastError());
        using Create = HRESULT (WINAPI*)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
        const auto factory = reinterpret_cast<Create>(GetProcAddress(loaded, "DirectInput8Create"));
        if (!factory) return attach_failed("Find DirectInput8Create", GetLastError());
        IDirectInput8A* direct = nullptr;
        const auto created = factory(GetModuleHandle(nullptr), DIRECTINPUT_VERSION,
            IID_IDirectInput8A, reinterpret_cast<void**>(&direct), nullptr);
        if (FAILED(created)) return attach_failed("Initialize DirectInput", created);

        IDirectInputJoyConfig8* config = nullptr;
        DIJOYCONFIG selected{};
        selected.dwSize = sizeof selected;
        const char* failed_operation = "Open DirectInput joystick configuration";
        auto result = direct->QueryInterface(IID_IDirectInputJoyConfig8, reinterpret_cast<void**>(&config));
        IDirectInputDevice8A* probe = nullptr;
        if (SUCCEEDED(result)) {
            failed_operation = "Look up the selected DirectInput joystick ID";
            result = config->GetConfig(index, &selected, DIJC_GUIDINSTANCE);
            config->Release();
            if (result == DI_OK) {
                failed_operation = "Open the selected DirectInput device";
                result = direct->CreateDevice(selected.guidInstance, &probe, nullptr);
            }
        }

        if (!probe && sole_reader_device(index)) {
            Enumeration pick{};
            const auto enumerated = direct->EnumDevices(DI8DEVCLASS_GAMECTRL, choose_device, &pick, DIEDFL_ATTACHEDONLY);
            if (FAILED(enumerated)) {
                failed_operation = "Enumerate attached DirectInput devices";
                result = enumerated;
            } else if (pick.count == 1) {
                failed_operation = "Open the sole attached DirectInput device";
                result = direct->CreateDevice(pick.instance, &probe, nullptr);
                if (probe) {
                    selected.guidInstance = pick.instance;
                    attach_operation = "Matched the sole attached controller";
                }
            }
        }
        direct->Release();
        if (!probe) return attach_failed(failed_operation, result);

        joystick = selected.guidInstance;
        auto** methods = *reinterpret_cast<void***>(probe);
        targets[0] = methods[9];  // IDirectInputDevice8::GetDeviceState
        targets[1] = methods[10]; // IDirectInputDevice8::GetDeviceData
        probe->Release();
        const auto state_hook = MH_CreateHook(targets[0], reinterpret_cast<void*>(direct_read),
            reinterpret_cast<void**>(&direct_original));
        if (state_hook != MH_OK) return attach_failed("Install DirectInput state hook", state_hook);
        const auto data_hook = MH_CreateHook(targets[1], reinterpret_cast<void*>(direct_buffered),
            reinterpret_cast<void**>(&buffered_original));
        if (data_hook != MH_OK) {
            MH_RemoveHook(targets[0]);
            return attach_failed("Install DirectInput buffered hook", data_hook);
        }
        target_count = 2;
    }
    // Keep the DLL resident after Lua reload. Dormant detours pass through.
    HMODULE pinned = nullptr;
    if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
        reinterpret_cast<LPCSTR>(&install), &pinned)) {
        const auto error = GetLastError();
        while (target_count) MH_RemoveHook(targets[--target_count]);
        return attach_failed("Keep the native DLL resident", error);
    }
    return true;
}
}

const char* xb_attach_operation() { return attach_operation; }
long xb_attach_code() { return attach_code; }

extern "C" {
__declspec(dllexport) unsigned __cdecl xb_policy_action(unsigned action) {
    std::lock_guard lock(guard);
    return policy_action ? policy_action(action) : 0;
}

__declspec(dllexport) unsigned __cdecl xb_policy_revision() {
    std::lock_guard lock(guard);
    return policy_revision;
}

__declspec(dllexport) unsigned __cdecl xb_load_policy(unsigned revision) {
    if (revision < 1 || revision > 999999) return ERROR_INVALID_PARAMETER;
    if (xb_policy_revision() == revision) return ERROR_SUCCESS;

    HMODULE host{};
    wchar_t filename[32768]{};
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        reinterpret_cast<LPCWSTR>(&xb_load_policy), &host)) return GetLastError();
    const auto length = GetModuleFileNameW(host, filename, static_cast<DWORD>(std::size(filename)));
    if (!length) return GetLastError();
    if (length == std::size(filename)) return ERROR_INSUFFICIENT_BUFFER;
    std::wstring path(filename, length);
    const auto separator = path.find_last_of(L"\\/");
    if (separator == std::wstring::npos) return ERROR_BAD_PATHNAME;
    path.resize(separator + 1);
    path += L"xb_controller_logic_" + std::to_wstring(revision) + L".dll";
    HMODULE next = LoadLibraryExW(path.c_str(), nullptr,
        LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!next) return GetLastError();

    const auto apply = reinterpret_cast<xb::ApplyLogic>(GetProcAddress(next, xb::logic_export));
    if (!apply) {
        const auto error = GetLastError();
        FreeLibrary(next);
        return error;
    }

    HMODULE previous;
    {
        // Detours invoke policy only under guard. The old image is safe to
        // release once this exchange completes.
        std::lock_guard lock(guard);
        previous = policy_module;
        policy_module = next;
        apply_logic = apply;
        policy_action = reinterpret_cast<PolicyAction>(GetProcAddress(next, "xb_logic_v1_action"));
        policy_revision = revision;
        reset();
        waiting_for_neutral = discard_buffered_batch = true;
    }
    if (previous) FreeLibrary(previous);
    return ERROR_SUCCESS;
}

__declspec(dllexport) unsigned __cdecl xb_begin(unsigned kind, unsigned index, unsigned experiment,
    unsigned fight, const char* module) {
    attach_operation = nullptr;
    attach_code = 0;
    if ((kind != 1 && kind != 2) || (experiment < 1 || experiment > 3) ||
        index >= (kind == 1 ? 4u : 16u) || !module) {
        attach_failed("Validate native hook arguments", ERROR_INVALID_PARAMETER);
        return 0;
    }
    // Called only on Windower's Lua thread. Install without holding the
    // callback mutex so suspended input threads cannot deadlock installation.
    static unsigned installed_kind, installed_device;
    static const char* installed_resolution;
    static std::array<char, 32> installed_module{};
    if (!installed_kind) {
        if (!install(kind, index, module)) return 0;
        installed_resolution = attach_operation;
        installed_kind = kind;
        installed_device = index;
        strncpy_s(installed_module.data(), installed_module.size(), module, _TRUNCATE);
    } else if (installed_kind != kind || (kind == 2 && installed_device != index) ||
        strcmp(installed_module.data(), module) != 0) return 2;
    if (!xb_policy_revision()) {
        const auto error = xb_load_policy(1);
        if (error != ERROR_SUCCESS) {
            attach_failed("Load controller logic revision 1", error);
            return 0;
        }
    }
    if (!hooks_enabled && !set_hooks(true)) return 0;
    attach_operation = installed_resolution;
    std::lock_guard lock(guard);
    reset();
    backend = kind; device = index; fightpad = fight == 1; r1_chooser = fight == 2;
    for (auto& hook : xbox_hooks) hook.initialized = false;
    overflow = false;
    mode = experiment;
    heartbeat = 0; // Wait for the addon to publish the first input context.
    last_context = 0;
    return 1;
}
__declspec(dllexport) void __cdecl xb_off() {
    std::lock_guard lock(guard);
    mode = 0;
    extra_plain=extra_l1=0;
    focus_handoff.reset();
    reset();
}
__declspec(dllexport) unsigned __cdecl xb_detach() {
    xb_off();
    // Restore target entry points without freeing trampolines. A callback
    // already in flight may still need its original-function trampoline.
    return !target_count || set_hooks(false);
}
__declspec(dllexport) void __cdecl xb_extra_capture(unsigned plain,unsigned l1) {
    std::lock_guard lock(guard);
    extra_plain=plain & xb::extra_controls;extra_l1=l1 & xb::extra_controls;
}
__declspec(dllexport) unsigned __cdecl xb_poll(unsigned context, int* output, unsigned capacity, unsigned* status) {
    std::lock_guard lock(guard);
    const auto now = GetTickCount64();
    if ((heartbeat && now - heartbeat > 500) || (last_sample && now - last_sample > 500)) {
        reset();
        last_sample = 0;
        if (heartbeat && now - heartbeat > 500) heartbeat = 0;
    }
    inherit_modifiers = (context & 0x2000000) != 0;
    personal_set_controls = (context & 0x4000000) != 0;
    targeting = (context & 0x100) && !r1_chooser;
    banks = (context >> 9) & 7;
    binding = (context & 0x1000) != 0;
    trust_slots = (context >> 16) & xb::slots;
    context &= 0xff;
    if (context == 0) { if (heartbeat) reset(); heartbeat = 0; }
    else {
        // A lost reader lease gives ownership back to the game. Rearm
        // from neutral while observing, before allowing capture again.
        if (context == 4 && last_context != 4) reset();
        heartbeat = now;
    }
    last_context = context;
    menu = context == 2;
    native_menu = context == 3 || context == 4;
    status[0] = generation; status[1] = calls; status[2] = raw; status[3] = suppressed;
    status[4] = buffered_calls; status[5] = unsupported; status[6] = overflow; status[7] = probe_ready;
    unsigned delivered = 0;
    while (count && delivered < capacity) {
        output[delivered++] = events[head];
        head = (head + 1) % events.size();
        --count;
    }
    return delivered;
}
}
