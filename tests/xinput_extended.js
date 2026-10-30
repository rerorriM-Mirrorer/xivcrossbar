// Exercise production XInput decoding and the actual personal full-poll path.
// Native DLL loading/Guide interception still require Windows acceptance.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const {ctx,fresh,poll,emitted,messages}=require('./personal_realkeys');
const wrapper=require('./ahk_source').read('ffxi_directinput.ahk','utf8');
const gestures=require('./ahk_source').read('personal_gestures.ahk','utf8');
function extract(source,name){const a=source.indexOf('\n'+name+'(')+1;assert(a>0);
 return source.slice(a,source.indexOf('\n}\n',a)+2);}
let code=extract(wrapper,'XInputStates')+'\n'+extract(gestures,'PersonalPovDirection');
code=code.replace(/^\s*global .*$/gm,'').replace(/^\s*;[^\n]*$/gm,'')
 .replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?t:t
   .replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
   .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'))
 .replace(/for (\w+), (\w+) in ([^\n]+)\n/g,(_,k,v,e)=>`for(const [${k},${v}] of ahkEnum(${e.trim()}))\n`)
 .replace(/Loop, (\d+)[ \t]*\n/g,(_,n)=>`for(let A_Index=1;A_Index<=${n};A_Index++)\n`)
 .replace(/^(XInput\w+\([^\n]+\)) \{/gm,'function $1 { let flags,states,angles,hat,pov;')
 .replace(/^(Personal\w+\([^\n]+\)) \{/gm,'function $1 {');
vm.runInContext('Object.defineProperty(Object.prototype,"HasKey",{value:function(k){return Object.hasOwn(this,k)}});\n'+code,ctx);
ctx.profile='xinput-extended';ctx.povDirection=0;
function decode(mask=0,lt=0,rt=0,extended=true,guide=true){
 return ctx.XInputStates(mask,lt,rt,.25,-.5,extended,guide);
}
for(const [bit,index] of [[1,1],[8,2],[2,3],[4,4],[0x1000,5],[0x4000,6],
 [0x2000,7],[0x8000,8],[0x20,9],[0x10,10]]){
 ctx.povDirection=0;const s=decode(bit);assert.equal(s[index],true);
 assert.equal(Object.keys(s).filter(k=>/^\d+$/.test(k)&&s[k]).length,1);
}
for(const [bit,name] of [[0x100,'l1'],[0x200,'r1'],[0x40,'l3'],[0x80,'r3'],[0x400,'touch']]){
 const s=decode(bit);assert.equal(s[name],true);assert.equal(s.ps,false);assert.equal(s.mute,false);
}
assert.equal(decode(0x400,0,0,true,false).touch,false,'standard GetState reserved bit became Guide');
assert.equal(decode(0,4,4)[11],false);assert.equal(decode(0,5,5)[11],true);
assert.equal(decode(0,5,0)[12],false);assert.equal(decode(0,0,5)[12],true);
assert.equal(decode().moveX,.25);assert.equal(decode().moveY,-.5);
decode(8);let s=decode(9);assert(s[2]&&!s[1],'diagonal lost previous right cardinal');
decode(1);s=decode(9);assert(s[1]&&!s[2]);
for(const mask of [0,3,12,15])assert(![1,2,3,4].some(i=>decode(mask)[i]));
ctx.profile='xinput';s=decode(9,0,0,false);assert(s[1]&&s[2]&&!s.l1,'ordinary profile changed');
ctx.profile='xinput-r1-chooser';assert(decode(0x200,0,0,false)[10]);
ctx.profile='xinput-extended';assert(!decode(0x200)[10],'RB stole Start chooser role');
// Same named samples reach the real extended poll; JoyN must never be queried.
fresh();Object.assign(ctx.PC,{connected:true,prefix:'',xinput:true,banks:true,ready:false});
ctx.PersonalNativePoll=()=>{};poll(decode());assert(ctx.PC.ready);
const savedGetKeyState=ctx.GetKeyState;ctx.GetKeyState=key=>{
 if(key.includes('Joy'))throw Error('Xbox sampled DirectInput JoyN');return false;};
try{s=ctx.PersonalPoll({...decode(0x100,6,0)},1);}finally{ctx.GetKeyState=savedGetKeyState;}
assert(s[13]&&s[11]&&!s[14]&&!s[12],JSON.stringify({s,pc:ctx.PC}));assert.equal(emitted.length,0);
s=poll(decode(0x200,0,6));assert(s[14]&&s[12]&&!s[13]);
// Guide enters the shared touch gesture, never PS focus-toggle handling.
let guideValue,psValue;
ctx.PersonalTouchStep=(_,pressed)=>{guideValue=pressed;return '';};
ctx.PersonalPS=pressed=>{psValue=pressed;};
poll(decode(0x400));assert(guideValue&&psValue===false);
assert(!messages.some(m=>m[0]==='key'&&m[1]==='r'));
const reader=extract(wrapper,'ReadTransportStates');
assert(reader.includes('return XInputStates(buttons, NumGet(state, 6, "UChar")'));
assert(reader.includes('profile = "xinput-extended", xinputGuide'));
const init=extract(wrapper,'InitXInput');
assert(init.includes('"Ptr", 100, "Ptr"')&&init.includes('extendedAddress ? extendedAddress : address'));
console.log('Actual Xbox decoder + full poll: face/menu bits, independent triggers, shoulders/clicks/Guide, unavailable Guide fallback, shared diagonals, neutral arming and no JoyN reads passed.');
