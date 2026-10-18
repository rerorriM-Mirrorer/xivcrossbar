// Actual AHK bank lease/key service/full poll under narrow source translation.
// File replacement and Windows key delivery still require native acceptance.
const vm=require('vm'),assert=require('assert/strict');
const {ctx,fresh,poll,extract,emitted,messages,physical,object}=require('./personal_realkeys');
let code=['PersonalBankLease','PersonalNativeSpec','PersonalNativeSync','PersonalNativeReset',
  'PersonalNativePoll','PersonalBanksPoll'].map(extract).join('\n');
code=code.replace(/RegExMatch\(([^,\n]+), ("[^"\n]+"), (\w+)\)/g,'RegExMatch($1, $2, "$3")')
 .replace(/^\s*global .*$/gm,'').replace(/^\s*;[^\n]*$/gm,'');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?JSON.stringify(t.slice(1,-1)):t
 .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
 .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'));
code=code.replace(/for (\w+), (\w+) in ([^\n{]+|\{[^\n]+\})\s*(\{)?\n/g,
 (_,k,v,e,brace)=>`for(const [${k},${v}] of ahkEnum(${e.trim()})) ${brace||''}\n`)
 .replace(/for (\w+) in ([^\n]+)\n/g,(_,k,e)=>`for(const [${k}] of ahkEnum(${e.trim()}))\n`)
 .replace(/Loop, (\d+)[ \t]*(\{)?\n/g,(_,n,brace)=>`for(let A_Index=1;A_Index<=${n};A_Index++) ${brace||''}\n`)
 .replace(/if GetKeyState\(([^)\n]+)\)/g,'if (GetKeyState($1))')
 .replace(/PC\.native\.requests\[1\]/g,'PC.native.requests[0]')
 .replace(/edge1 \+ 0/g,'Number(edge1)').replace(/base1 \+ 0/g,'Number(base1)')
 .replace(/^(Personal\w+\([^\n]*\)) \{/gm,'function $1 { let enabled,requests,expected,key,keys,modifiers,desired,retired,edge,spec,owner,busy,touchEvent,clickEvent;');
Object.assign(ctx,{RegExMatch:(text,pattern,name)=>{
  const match=text.match(new RegExp(pattern.replace(/^m\)/,''),'m'));
  if(name)for(let i=1;i<=9;i++)ctx[name+i]=match?.[i]??'';
  return !!match;
},StrSplit:(s,d)=>s.split(d),StrLen:s=>s.length,
 ControllerMessageCancel:()=>{ctx.CM.phase='neutral';ctx.CM.previous={};},
});
// AHK missing dictionary values are empty strings; native key/modifier lookups
// in these two constant tables need that behavior under JavaScript.
code=code.replace(/keys\[part2\]/g,'(keys[part2] || "")').replace(/modifiers\[part1\]/g,'(modifiers[part1] || "")');
vm.runInContext('Array.prototype.RemoveAt=function(i){this.splice(i-1,1)};\n'+code,ctx);
function native(){return {token:'',ack:0,requests:[],active:object(),keys:object()};}
// AHK {} dictionaries support these methods; normalize newly-created tables
// at the native boundary while keeping the actual algorithm unchanged.
for(const name of ['PersonalNativeSync','PersonalNativeReset','PersonalBankLease','PersonalNativePoll']){
 const normalize=v=>Object.hasOwn(v,'Count')?v:object(v);
 const original=ctx[name];ctx[name]=(...args)=>{ctx.PC.native.active=normalize(ctx.PC.native.active);ctx.PC.native.keys=normalize(ctx.PC.native.keys);
  try{return original(...args);}finally{ctx.PC.native.active=normalize(ctx.PC.native.active);ctx.PC.native.keys=normalize(ctx.PC.native.keys);}};
}
// desired is local inside Sync, so use the same non-enumerable dictionary methods
// for all translated object literals in this VM (the production source is untouched).
vm.runInContext('Object.defineProperties(Object.prototype,{HasKey:{value:function(k){return Object.hasOwn(this,k)}},Delete:{value:function(k){delete this[k]}}});',ctx);
function init(){fresh();Object.assign(ctx.PC,{connected:true,prefix:'',layerVisible:'',banks:false,native:native()});ctx.CM.expanded=false;}
function lease(payload='',token='test-native-1',base=0,enabled=true){
 ctx.PersonalBankLease(`bank_protocol=${enabled?1:0}\nbank_native_token=${token}\nbank_native_base=${base}\nbank_native=${payload}\n`);
}
function ready(){ctx.PC.ready=true;ctx.CM.phase='messages';ctx.CM.pending={Length:()=>0};ctx.CM.seen=100;}
init();lease();assert(ctx.PC.banks&&ctx.CM.expanded&&!ctx.PC.ready);ready();
const keyMap={'ctrl+i':['i','LControl'],'ctrl+left':['Left','LControl'],'alt+right':['Right','LAlt'],
 up:['Up',''],enter:['Enter',''],escape:['Escape',''],r:['r',''],tab:['Tab',''],f8:['F8','']};
for(const [value,[key,modifier]] of Object.entries(keyMap)){
 const spec=ctx.PersonalNativeSpec(value);assert.equal(spec.key,key);assert.equal(spec.modifier,modifier);
}
for(const bad of ['{Enter}','ctrl+alt+i','win+r','f13','numpadadd down','i;reload','ctrl+'])assert(!ctx.PersonalNativeSpec(bad));
// Down and up can share the first snapshot: retain a 40ms native pulse.
init();lease('1,d,ctrl+i|2,u,ctrl+i');ready();ctx.PersonalNativePoll(100);
assert.deepEqual(emitted,[['send','{Blind}{LControl down}'],['send','{Blind}{i down}']]);
ctx.PersonalNativePoll(120);assert.equal(ctx.PC.native.ack,1);
ctx.PersonalNativePoll(140);assert.equal(ctx.PC.native.ack,2);
assert.deepEqual(emitted.slice(-2),[['send','{Blind}{i up}'],['send','{Blind}{LControl up}']]);
assert.deepEqual(messages,[['keyack',1],['keyack',2]]);
lease('1,d,ctrl+i|2,u,ctrl+i');ctx.PersonalNativePoll(150);assert.equal(emitted.length,4,'replayed acknowledged pulse');
// One held modifier survives another native owner's release.
init();lease('1,d,ctrl+left|2,d,ctrl+right|3,u,ctrl+left|4,u,ctrl+right');ready();
ctx.PersonalNativePoll(100);ctx.PersonalNativePoll(110);ctx.PersonalNativePoll(140);
assert(ctx.PC.keys.HasKey('LControl')&&ctx.PC.keys.HasKey('Right')&&!ctx.PC.keys.HasKey('Left'));
ctx.PersonalNativePoll(150);assert(!ctx.PC.keys.Count());
// A new generation releases before adopting any new keys. Never replay old IDs.
init();lease('1,d,up');ready();ctx.PersonalNativePoll(100);
lease('2,d,r|3,u,r','test-native-2',1);assert(!ctx.PC.keys.Count());ctx.PersonalNativePoll(110);
assert.equal(emitted.at(-1)[1],'{Blind}{r down}');
// Validate the entire snapshot before touching any key.
for(const invalid of ['1,d,up|3,u,up','1,d,up|2,d,{Enter}','1,d,up|2,x,up']){
 init();lease(invalid);ready();ctx.PersonalNativePoll(100);assert.equal(emitted.length,0);
}
// Foreign physical keys/modifiers are never stolen or released.
for(const held of ['Control','Alt','Shift','LWin','AppsKey','i']){
 init();lease('1,d,ctrl+i|2,u,ctrl+i');ready();physical.add(held);
 ctx.PersonalNativePoll(100);ctx.PersonalNativePoll(140);assert.equal(emitted.length,0);
}
init();lease('1,d,up');ready();ctx.PersonalNativePoll(100);ctx.CM.seen=-1;
ctx.PersonalNativePoll(150);assert.equal(emitted.at(-1)[1],'{Blind}{Up up}');
init();lease('1,d,up');ready();ctx.CM.pending={Length:()=>1};ctx.PersonalNativePoll(100);
assert.equal(emitted.length,0,'output overtook an unacknowledged cancellation/input');
// Full actual PersonalPoll bypasses hardcoded L1/R1 and supplies raw shoulders.
init();lease();ready();const result=poll({l1:true,8:true});
assert(result[13]&&result[8]&&!result[14]);assert.equal(emitted.length,0);assert.deepEqual(messages,[]);
init();lease();ready();const r1=poll({r1:true,6:true});assert(r1[14]&&r1[6]);
assert.equal(emitted.length,0);assert.deepEqual(messages,[],'legacy R1 helper also ran');
ctx.PersonalRelease();assert(!ctx.PC.ready&&ctx.PC.native.token==='');
lease('', 'test-native-1',0,false);assert(!ctx.PC.banks&&!ctx.CM.expanded);
console.log('Actual AHK companion service: negotiated full poll, native whitelist, atomic validation, quick taps, output ack dedup, modifier union, generation cancellation, stale/backlog guards and keyboard ownership passed.');
