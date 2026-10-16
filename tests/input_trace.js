// Actual pure trace helpers translated narrowly; no Windows delivery claim.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('ffxi_directinput.ahk','utf8');
function extract(name){
  const start=source.indexOf('\n'+name+'(')+1;
  assert(start>0);let at=source.indexOf('{',start),depth=1,end=at+1;
  while(depth){const c=source[end++];if(c==='{')depth++;if(c==='}')depth--;}
  return source.slice(start,end);
}
let code=['InputTraceMask','InputTraceRecord','InputTraceContextMiss'].map(extract).join('\n');
code=code.replace(/^\s*global .*$/gm,'').replace(/;[^\n]*/g,'');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,token=>{
  if(token.startsWith('"'))return token.replace(/`n/g,'\\n');
  return token.replace(/\.=/g,'+=').replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@')
    .replace(/(?<![<>!:=+])=(?!=)/g,'===').replace(/@ASSIGN@/g,'=')
    .replace(/\band\b/g,'&&').replace(/\bor\b/g,'||');
});
code=code.replace(/Loop, 12\s*\n/g,'for(let A_Index=1;A_Index<=12;A_Index++)\n')
  .replace(/^(InputTrace\w+\([^\n]*\)) \{/gm,'function $1 { let mask;');
const context={IT:{enabled:false,buffer:'',misses:0},IsObject:x=>x!==null&&typeof x==='object',DllCall:()=>42};
vm.createContext(context);vm.runInContext(code,context);
context.InputTraceRecord('off');assert.equal(context.IT.buffer,'');
assert.equal(context.InputTraceMask(new Proxy({},{get(){throw Error('off trace read state');}})),'');
assert.equal(context.InputTraceContextMiss('malformed'),'unknown');assert.equal(context.IT.misses,1);
context.IT.enabled=true;context.InputTraceRecord('edge');assert.equal(context.IT.buffer,'42 edge\n');
const states={1:true,12:true};assert.equal(context.InputTraceMask(states),'100000000001');
assert.equal(context.InputTraceMask(false),'disconnected');
assert.equal(context.InputTraceContextMiss('stale'),'stale');
assert.equal(context.IT.misses,2);assert(context.IT.buffer.includes('context lease miss=stale'));
const helpers=source.slice(source.indexOf('\nInputTraceInit() {'),source.indexOf('\n#Include'));
assert(!/SendEvent|ControlSend|SetKeyDelay|BlockInput/.test(helpers));
assert(source.includes('IT.deadline := now + 30000')&&source.includes('now >= IT.deadline'));
console.log('Actual trace helpers: opt-in-only buffering, exact raw masks, unchanged context results and 30-second/no-injection integration checks passed.');
