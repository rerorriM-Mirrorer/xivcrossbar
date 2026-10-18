// Actual AHK ownership/filter/lease functions under the same narrow translation
// used by the personal-input tests. This is not native Windows/AHK execution.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('personal_controls.ahk','utf8');
function extract(name){const a=source.indexOf('\n'+name+'(')+1;assert(a>0);
  return source.slice(a,source.indexOf('\n}\n',a)+2);}
let code=['PersonalPoll','PersonalNativeDPad','PersonalFilter','PersonalRealKeyLease','PersonalKey','PersonalRelease'].map(extract).join('\n');
code=code.replace(/^\s*global .*$/gm,'').replace(/^\s*;[^\n]*$/gm,'')
  .replace(/SendEvent, % ([^\n]+)/g,'SendEvent($1)')
  .replace(/ControlSend,, % ([^\n]+), ahk_id %owner%/g,'ControlSend($1,owner)');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?t:t
  .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
  .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'));
code=code.replace(/for (\w+), (\w+) in ([^\n{]+|\{[^\n]+\})\s*(\{)?\n/g,
  (_,k,v,e,brace)=>`for (const [${k},${v}] of ahkEnum(${e.trim()})) ${brace||''}\n`)
  .replace(/for (\w+) in ([^\n]+)\n/g,(_,k,e)=>`for (const [${k}] of ahkEnum(${e.trim()}))\n`)
  .replace(/Loop, (\d+)[ \t]*(\{)?\n/g,(_,n,brace)=>`for(let A_Index=1;A_Index<=${n};A_Index++) ${brace||''}\n`)
  .replace(/if (GetKeyState|WinExist|PersonalOtherWindow)\(([^)\n]+)\)/g,'if ($1($2))')
  .replace(/^(Personal\w+\([^\n]+\)) \{/gm,'function $1 { let eligible, enabled, retired, owner, keys;');
function* ahkEnum(o){if(Array.isArray(o)){for(let i=0;i<o.length;i++)yield[i+1,o[i]];return;}
  let index=0;while(true){const keys=Object.keys(o);if(index>=keys.length)return;
    const k=keys[index++];yield[/^\d+$/.test(k)?Number(k):k,o[k]];}}
function object(v={}){return Object.defineProperties(v,{Delete:{value:k=>delete v[k]},
  Count:{value:()=>Object.keys(v).length},HasKey:{value:k=>Object.hasOwn(v,k)}});}
const emitted=[],traces=[],physical=new Set();let active=1;
const ctx={PC:{},CM:{},appsOwned:false,ahkEnum,GetKeyState:k=>physical.has(k),
  WinActive:()=>active,WinExist:()=>active,
  SendEvent:s=>emitted.push(['send',s]),ControlSend:(s,o)=>emitted.push(['control',s,o]),
  InputTraceRecord:s=>traces.push(s),IsObject:o=>o&&typeof o==='object',PersonalL1Event:()=>{},
  RegExMatch:(s,pattern)=>new RegExp(pattern.slice(2),'m').test(s)};
vm.createContext(ctx);vm.runInContext('Array.prototype.Push=Array.prototype.push;Array.prototype.Length=function(){return this.length};\n'+code,ctx);
function fresh(){ctx.PC={enabled:true,owner:1,ready:true,realDpad:true,keys:object(),releases:object(),
  previous:{},blocked:object(),suppressed:object(),layer:{phase:'idle'},touch:{},clicks:{},r1:{}};
  ctx.CM={requested:true,phase:'messages',seen:100};ctx.appsOwned=false;
  active=1;physical.clear();emitted.length=0;traces.length=0;}
function step(raw={},mode='gameplay',now=100){const states={...raw};ctx.PersonalNativeDPad(states,raw,mode,now);
  ctx.PersonalFilter(states,raw);ctx.PC.previous={...raw};return states;}
const map={1:'i',2:'l',3:'k',4:'j'};
for(const [i,k] of Object.entries(map)){
  fresh();assert.equal(step({[i]:true})[i],false,'owned press leaked into Lua message stream');
  assert.deepEqual(emitted,[['send',`{Blind}{${k} down}`]]);
  step({[i]:true});assert.equal(emitted.length,1,'held direction repeated down');
  step();assert.deepEqual(emitted[1],['send',`{Blind}{${k} up}`]);assert.equal(ctx.PC.blocked.Count(),0);
}
for(const mode of ['text','menu:1','crossbar','setup','unknown','updating']){
  fresh();assert.equal(step({1:true},mode)[1],true);assert.equal(emitted.length,0);
}
for(const extra of [{l1:true},{r1:true},{l3:true},{r3:true},{touch:true},{ps:true},{mute:true},
  ...Array.from({length:8},(_,i)=>({[i+5]:true}))]){
  fresh();assert.equal(step({1:true,...extra})[1],true);assert.equal(emitted.length,0);
  fresh();step({1:true});assert.equal(step({1:true,...extra})[1],false);
  assert.deepEqual(emitted.at(-1),['send','{Blind}{i up}']);
  step({1:true});assert.equal(emitted.length,2,'resumed a consumed hold');
  step();step({1:true});assert.equal(emitted.length,3,'fresh press did not rearm');
}
for(const k of ['Control','Alt','Shift','LWin','RWin','AppsKey']){
  fresh();physical.add(k);assert.equal(step({1:true})[1],true);assert.equal(emitted.length,0);
}
for(const k of ['LControl','RControl','LAlt','RAlt','LShift','RShift']){
  fresh();ctx.PC.keys[k]=1;assert.equal(step({1:true})[1],true);assert.equal(emitted.length,0);
}
for(const configure of [()=>ctx.PC.realDpad=false,()=>ctx.PC.ready=false,()=>ctx.appsOwned=true,
  ()=>ctx.CM.phase='neutral',()=>ctx.CM.phase='keys',()=>ctx.CM.phase='uncertain',()=>ctx.CM.phase='backpressure',()=>ctx.CM.seen=-1]){
  fresh();configure();assert.equal(step({1:true})[1],true);assert.equal(emitted.length,0);
}
fresh();physical.add('i');assert.equal(step({1:true})[1],false);step();assert.equal(emitted.length,0,'released physical keyboard ownership');
fresh();step({1:true});physical.add('i');step();assert.equal(emitted.length,1,'injected up while keyboard held');
fresh();step({1:true});ctx.PersonalRelease();assert.deepEqual(emitted.at(-1),['send','{Blind}{i up}']);
assert(!ctx.PC.ready&&ctx.PC.suppressed[1]);step({1:true});assert.equal(emitted.length,2);
fresh();step({1:true});active=2;ctx.PersonalRelease();assert.deepEqual(emitted.at(-1),['control','{i up}',1]);
fresh();ctx.PC.realDpad=false;ctx.PersonalRealKeyLease('dpad_output=ahk\n');
assert(ctx.PC.realDpad&&!ctx.PC.ready);ctx.PC.ready=true;
ctx.PersonalRealKeyLease('dpad_output=ahk\n');assert(ctx.PC.ready,'unchanged permission forced rearm');
step({1:true});ctx.PersonalRealKeyLease('dpad_output=lua\n');assert(!ctx.PC.realDpad&&!ctx.PC.ready);
assert.deepEqual(emitted.at(-1),['send','{Blind}{i up}']);assert.equal(step({1:true})[1],false);
fresh();ctx.PersonalRealKeyLease('l1token=old\n');assert(!ctx.PC.realDpad,'older Lua enabled experiment');
fresh();ctx.CM.requested=false;ctx.PersonalRealKeyLease('dpad_output=ahk\n');assert(!ctx.PC.realDpad);
fresh();ctx.PC.blocked[1]='Up';assert.equal(step({1:true})[1],false);assert.equal(emitted.length,0,'stole R1 ownership');
const pollSource=extract('PersonalPoll'),context=extract('PersonalContext');
assert(pollSource.indexOf('PersonalNativeDPad(states, raw, mode, now)')<pollSource.indexOf('states := PersonalFilter(states, raw)'));
assert(context.indexOf('PersonalRealKeyLease(lease)')<context.indexOf('PersonalL1Lease(lease,'));
assert(!/Sleep,|SetKeyDelay,/.test(extract('PersonalNativeDPad')));
// Exercise the entire actual poll around this helper, especially downstream
// PersonalRelease/filter/arrow output, not just an isolated eligible predicate.
Object.assign(ctx,{previous:{},DllCall:()=>100,PersonalPS:()=>{},PersonalOtherWindow:()=>false,
  PersonalReleaseDue:()=>{},PersonalContext:()=>ctx.mode,PersonalLeasePause:()=>false,
  PersonalTargetTrial:()=>{},PersonalLayerStep:()=>'',PersonalL1Block:()=>{},
  PersonalTouchStep:()=>'',PersonalClicksStep:()=>'',PersonalR1Tap:()=>{},
  PersonalChord:()=>{},ReleaseTransport:()=>{},mode:'gameplay'});
function poll(raw={}){const original=ctx.GetKeyState;
  ctx.GetKeyState=k=>{const named={Joy5:'l1',Joy6:'r1',Joy11:'l3',Joy12:'r3',Joy13:'ps',Joy14:'touch',Joy15:'mute'};
    return named[k]?!!raw[named[k]]:physical.has(k);};
  try{return ctx.PersonalPoll({...raw},1);}finally{ctx.GetKeyState=original;}}
fresh();Object.assign(ctx.PC,{connected:true,prefix:'',layerVisible:''});
assert.equal(poll({1:true})[1],false);poll({1:true});poll();
assert.deepEqual(emitted.filter(e=>e[1].includes('{i ')),[['send','{Blind}{i down}'],['send','{Blind}{i up}']]);
assert(!emitted.some(e=>/\{(Up|Right|Down|Left) down\}/.test(e[1])),'native hold also emitted an R1 arrow');
fresh();Object.assign(ctx.PC,{connected:true,prefix:'',layerVisible:''});
poll({1:true});assert.equal(poll({1:true,12:true})[1],false);poll({1:true});poll();
assert.equal(emitted.filter(e=>e[1].includes('{i down}')).length,1,'trigger transition re-fired direction');
console.log('Actual AHK real IJKL: full-poll integration, direction mapping, once-per-hold, masking, chord/context transitions, neutral routes, modifiers, physical-key ownership, client cleanup and lease compatibility passed.');
