// Execute actual sender decision/latch functions with native/file I/O mocked.
// This is a narrow AHK-to-JS translation, not Windows/AHK execution.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('movement_signal.ahk','utf8');
function extract(name){const start=source.indexOf(name+'(');return source.slice(start,source.indexOf('\n}\n',start)+2);}
let code=['MovementInit','MovementTick','MovementPoll'].map(extract).join('\n');
code=code.replace(/^\s*global .*$/gm,'').replace(/^\s*;[^\n]*$/gm,'')
 .replace(/SendEvent, ([^\n]+)/g,(_,keys)=>'SendEvent('+JSON.stringify(keys)+')')
 .replace(/WinGetTitle, title, ahk_id %active%/g,'title=\"Myrr\"')
 .replace(/FileAppend, %line%, [^\n]+/g,'FileAppend(line)');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?JSON.stringify(t.slice(1,-1)):t
 .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
 .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'));
code=code.replace(/^(Movement\w+\([^\n]*\)) \{/gm,'function $1 { let ready,context,title,line;');
let active=1,time=100,policy='Send',ready=false,context='menu:1';
const sent=[],logs=[];
const c={PC:{enabled:true},DllCall:()=>time,WinActive:()=>active,
 PersonalContext:()=>context,MovementRelease:()=>{c.TM.signalOwner=0},
 MovementReceiverReady:()=>{c.TM.policy=policy;return ready},
 SendEvent:keys=>sent.push(keys),FileAppend:s=>logs.push(s),A_NowUTC:'20261025'};
vm.createContext(c);vm.runInContext(code,c);
const moving={moveX:.5,moveY:0,HasKey(k){return Object.hasOwn(this,k)}};
const neutral={...moving,moveX:0};
function fresh(){sent.length=0;logs.length=0;active=1;time=100;c.MovementInit();c.MovementTick(active);}
fresh();c.MovementPoll(neutral,active);assert.equal(c.TM.fired,false);
c.MovementPoll(moving,active);assert.equal(sent.length,1);assert.equal(c.TM.sent,1);
assert.equal(c.TM.fired,true,'Send must consume blocked-context first movement');
c.MovementPoll(moving,active);assert.equal(sent.length,1);
c.MovementTick(0);c.MovementTick(1);c.MovementPoll(moving,1);assert.equal(sent.length,1,'desktop trip rearmed latch');
active=2;c.MovementTick(2);c.MovementPoll(moving,2);assert.equal(sent.length,2,'different FFXI client did not rearm');
fresh();policy='Ready';ready=false;context='gameplay';c.MovementPoll(moving,active);assert.equal(c.TM.fired,false);
ready=true;context='menu:1';c.MovementPoll(moving,active);assert.equal(c.TM.fired,false);
context='crossbar';c.MovementPoll(moving,active);assert.equal(sent.length,1);assert.equal(c.TM.fired,true);
assert(logs[0].includes('policy=Ready'));
assert(source.includes('trust\\data\\movement') && source.includes('trustmovement\\data'));
console.log('Actual movement sender: Send/Ready, blocked contexts, neutral, once-only latch, desktop and client changes passed.');
