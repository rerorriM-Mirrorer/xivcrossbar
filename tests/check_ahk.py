"""Lexical/integration checks only. Native AHK parsing and delivery need Windows."""
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
sources={p:p.read_text() for p in root.rglob('*.ahk')}
for path,source in sources.items():
    # AHK v1 command-style Files/Read/Parse loops require the brace on a new
    # line. Balanced braces alone missed the native Personal 6 startup error.
    assert not re.search(r'^\s*Loop,\s*(Files|Read|Parse)\b[^\n]*\{\s*$',source,re.M|re.I),path
    stack=[];quoted=False;i=0
    while i<len(source):
        c=source[i]
        if c=='`': i+=2;continue
        if quoted and source[i:i+2]=='""': i+=2;continue
        if c=='"':quoted=not quoted
        elif not quoted:
            if c==';':
                stop=source.find('\n',i)
                i=len(source) if stop<0 else stop
                continue
            if c in '({[':stack.append(c)
            elif c in ')}]':
                assert stack and stack.pop()=={')':'(',']':'[','}':'{'}[c],(path,i)
        i+=1
    assert not quoted and not stack,path
wrapper=sources[root/'ffxi_directinput.ahk']
includes=re.findall(r'^#Include %A_ScriptDir%\\(.+)$',wrapper,re.M)
assert set(includes)=={'personal_controls.ahk','personal_gestures.ahk','controller_clients.ahk','movement_signal.ahk'}
for name in includes:assert (root/name).is_file()
assert wrapper.index('instanceMutex := AcquireWrapperMutex()')<wrapper.index('OnExit, TransportExit')
controls=sources[root/'personal_controls.ahk']
assert 'enabled:selected = "ps5-extended"' in controls
assert not any(x in controls for x in ['JoyR','raw.zoom','nextZoom','zoomArmed'])
assert 'modifier:i = 8 ? "LControl" : ""' in controls
assert 'raw.r1 and !raw.l1' in controls
assert 'Mod(index - 1 + direction + ordered.Length(), ordered.Length())' in controls
assert 'PC.owner != WinActive("ahk_class FFXiClass")' in controls
assert 'ControlSend,,' in controls
functions=[]
for name in ['personal_controls.ahk','personal_gestures.ahk']:
    functions += re.findall(r'^(Personal\w+)\([^\n]*\) \{',sources[root/name],re.M)
assert len(functions)==len(set(functions)), 'duplicate function'
calls=set(re.findall(r'\b(Personal\w+)\(',wrapper+controls+sources[root/'personal_gestures.ahk']))
assert calls<=set(functions),calls-set(functions)
probe=sources[root/'tools/keyprobe/keyboard_probe.ahk']
assert 'OnExit, ProbeExit' in probe and 'ProbeReleaseKeys()' in probe
assert 'WinActive("ahk_class FFXiClass") != probeOwner' in probe
print(f'{len(sources)} AHK files: balanced literals/delimiters, includes, hidden gating, cleanup and function links checked.')
