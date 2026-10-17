// Actual AHK filter/prefire decisions under a narrow translation. An enumerator
// that advances over the current sorted keys reproduces AHK's deletion hazard.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('personal_controls.ahk','utf8');
function extract(name){const start=source.indexOf('\n'+name+'(')+1;assert(start>0);
  const end=source.indexOf('\n}\n',start)+2;assert(end>start);return source.slice(start,end);}
let code=['PersonalFilter','PersonalTargetTrial'].map(extract).join('\n');
code=code.replace(/^\s*global .*$/gm,'').replace(/;[^\n]*/g,'');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?t:t
  .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=])=(?!=)/g,'===')
  .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'));
code=code.replace(/for (\w+), (\w+) in ([^\n{]+)(\{)?/g,
  (_,k,v,e,brace)=>`for (const [${k},${v}] of ahkEnum(${e.trim()})) ${brace||''}`)
  .replace(/Loop, (\d+)\s*\n/g,(_,n)=>`for(let A_Index=1;A_Index<=${n};A_Index++)\n`)
  .replace(/if GetKeyState\(([^)\n]+)\)/g,'if (GetKeyState($1))')
  .replace(/^(Personal\w+\([^\n]+\)) \{/gm,'function $1 { let retired, source;');
function* ahkEnum(o){let index=0;while(true){
  if(Array.isArray(o)){if(index>=o.length)return;yield [++index,o[index-1]];}
  else{const keys=Object.keys(o).map(Number).sort((a,b)=>a-b);if(index>=keys.length)return;
    const key=keys[index++];yield [key,o[key]];}
}}
function object(values){return Object.defineProperties(values,{
  Delete:{value:k=>delete values[k]},Count:{value:()=>Object.keys(values).length}});}
const emitted=[],physical=new Set();
const context={ahkEnum,PC:{},appsOwned:false,GetKeyState:k=>physical.has(k),
  PersonalKey:(key,down)=>emitted.push([key,down]),InputTraceRecord:()=>{}};
vm.createContext(context);vm.runInContext('Array.prototype.Push=Array.prototype.push;\n'+code,context);
function fresh(){context.PC={blocked:object({}),suppressed:object({}),keys:object({}),
  l1:{available:true},previous:{},clicks:{phase:'idle'},targetR2:false,targetR3:false};
  context.appsOwned=false;emitted.length=0;physical.clear();}
fresh();context.PC.blocked=object({1:'i',2:'m',6:'q',8:'s'});
context.PC.suppressed=object({1:true,6:true});
let states={1:false,2:true,6:false,8:true},raw={2:true,8:true};
context.PersonalFilter(states,raw);
assert.equal(states[2],false,'held Right leaked after released Up deletion');
assert.equal(states[8],false,'held Triangle leaked after released Square deletion');
assert.deepEqual(Object.keys(context.PC.blocked),['2','8']);
context.PersonalFilter(states,{});assert.equal(context.PC.blocked.Count(),0);
function trial(button,extra={},mode='gameplay'){
  const raw={l1:false,r1:false,l3:false,r3:false,touch:false,ps:false,mute:false,...extra};
  if(button==='R2')raw[12]=true;else raw.r3=true;
  context.PersonalTargetTrial(raw,mode);return emitted;
}
fresh();context.PC.targetR2=true;
assert.deepEqual(trial('R2'),[['F8',true],['F8',false]]);
context.PC.previous[12]=true;emitted.length=0;assert.deepEqual(trial('R2'),[]);
fresh();context.PC.targetR3=true;
assert.deepEqual(trial('R3'),[['F8',true],['F8',false]]);
for(const extra of [{1:true},{5:true},{11:true},{l1:true},{r1:true},{l3:true},{touch:true},{ps:true},{mute:true}]){
  fresh();context.PC.targetR2=true;assert.deepEqual(trial('R2',extra),[]);
}
for(const mode of ['text','setup','menu:1','crossbar','unknown','updating']){
  fresh();context.PC.targetR2=true;assert.deepEqual(trial('R2',{},mode),[]);
}
for(const key of ['Control','Alt','Shift','LWin','RWin','AppsKey','F8']){
  fresh();context.PC.targetR2=true;physical.add(key);assert.deepEqual(trial('R2'),[]);
}
fresh();assert.deepEqual(trial('R2'),[]);assert.deepEqual(trial('R3'),[]);
fresh();context.PC.targetR2=true;context.PC.l1.available=false;assert.deepEqual(trial('R2'),[]);
fresh();context.PC.targetR2=true;context.appsOwned=true;assert.deepEqual(trial('R2'),[]);
fresh();context.PC.targetR3=true;context.PC.clicks.phase='l3';assert.deepEqual(trial('R3'),[]);
fresh();context.PC.targetR3=true;context.PC.previous.r3=true;assert.deepEqual(trial('R3'),[]);
assert(source.indexOf('PersonalTargetTrial(raw, mode)')<source.indexOf('layer := PersonalLayerStep'));
assert(!/Sleep,|SetKeyDelay,|SendEvent|AppsKey.*down/.test(extract('PersonalTargetTrial')));
const pause=source.slice(source.indexOf('if (PersonalLeasePause('),source.indexOf('contextAllowed :='));
assert(pause.includes('states[A_Index] and previous[A_Index]')&&pause.includes('return PersonalFilter(states, raw)'));
assert(!pause.includes('PersonalRelease()')&&!pause.includes('PC.previous := raw'));
console.log('Actual AHK filter: adjacent-entry deletion regression fixed. F8 R2/R3 ordering, fresh edges, defaults-off and context/combo/physical-key guards pass; gap quarantine has no new downs.');
