// Actual AHK message poll/queue/cancel functions under a narrow translation.
// Native FileMove/SendEvent and Windows timing remain live acceptance checks.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('controller_messages.ahk','utf8');
function extract(name){const a=source.indexOf('\n'+name+'(')+1;assert(a>=0);const b=source.indexOf('\n}\n',a);assert(b>a);return source.slice(a,b+2);}
let code=['ControllerMessageInit','ControllerMessageLease','ControllerMessageHeld','ControllerMessageAnyHeld','ControllerMessageAdd','ControllerMessageCancel','ControllerMessagePoll'].map(extract).join('\n');
code=code.replace(/RegExMatch\(lease, ("[^"\n]+"), (\w+)\)/g,'RegExMatch(lease, $1, "$2")');
code=code.replace(/^\s*global .*$/gm,'').replace(/;[^\n]*/g,'');
code=code.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?JSON.stringify(t.slice(1,-1)):t
 .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
 .replace(/@ASSIGN@/g,'=').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||'));
code=code.replace(/Loop, 12 (?=\{)/g,'for(let A_Index=1;A_Index<=12;A_Index++) ')
 .replace(/Loop, 12\s*\n/g,'for(let A_Index=1;A_Index<=12;A_Index++)\n')
 .replace(/for _, event in CM.pending/g,'for (const event of CM.pending)')
 .replace(/for _, i in (\[[^\n]+\]) \{/g,'for (const i of $1) {')
 // AHK arrays use 1-based indexing; this is the only queue index in the code.
 .replace(/CM\.pending\[1\]/g,'CM.pending[0]')
 .replace(/ack1 \+ 0/g,'Number(ack1)')
 .replace(/^(ControllerMessage\w+\([^\n]*\)) \{/gm,'function $1 { let neutral,now,changed,i,requested,token,retained;');
let now=1000;const writes=[];
const ctx={CM:{},RegExMatch:(text,pattern,name)=>{const m=text.match(new RegExp(pattern.replace(/^m\)/,''),'m'));if(m)ctx[name+'1']=m[1];return !!m;},
 RegExReplace:(text,pattern,replacement)=>text.replace(new RegExp(pattern),replacement),
 ReleaseTransport:()=>ctx.ControllerMessageCancel(),DllCall:()=>now,InputTraceRecord:()=>{},IsObject:x=>x&&typeof x==='object',
 ControllerMessageFlush:force=>{writes.push({force,edges:ctx.CM.pending.map(x=>[x.kind,x.button])});return true;}};
vm.createContext(ctx);vm.runInContext('Array.prototype.Push=Array.prototype.push;Array.prototype.Length=function(){return this.length};\n'+code,ctx);
function init(){ctx.ControllerMessageInit();writes.length=0;now=1000;}
function requested(){ctx.CM.requested=true;ctx.CM.token='test';ctx.CM.phase='neutral';ctx.CM.seen=now;}
function poll(states={}){return ctx.ControllerMessagePoll(states);}
function edges(){return Array.from(ctx.CM.pending,x=>[x.kind,x.button]);}
init();assert.equal(poll(),false,'legacy route intercepted');
requested();assert.equal(poll({11:true}),true);assert.equal(ctx.CM.phase,'neutral');assert.equal(ctx.CM.seq,0);
poll();assert.equal(ctx.CM.phase,'messages');
poll({7:true,11:true});assert.deepEqual(edges(),[['down',11],['down',7]],'same-poll slot overtook trigger');
poll({7:true,11:true});assert.equal(ctx.CM.seq,2,'held buttons repeated');
poll();assert.deepEqual(edges().slice(2),[['up',7],['up',11]],'release order changed');
ctx.CM.pending.length=0;ctx.CM.requested=false;ctx.CM.phase='neutral';poll({12:true});assert.equal(poll({12:true}),true);
poll();assert.equal(poll(),false,'keyboard handoff never completed at neutral');
init();requested();poll();poll({12:true});now=1050;poll({12:true,5:true});
assert.deepEqual(edges(),[['down',12],['down',5]],'fresh lease window lost edge');
now=1110;poll({12:true,5:true,7:true});
assert.equal(ctx.CM.phase,'uncertain');assert.equal(edges().at(-1)[0],'cancel');assert(!edges().some(x=>x[0]==='down'&&x[1]===7));
ctx.CM.seen=now;poll({12:true});assert.equal(ctx.CM.phase,'uncertain');poll();assert.equal(ctx.CM.phase,'messages');
init();requested();poll();poll({11:true});now=1351;ctx.CM.seen=now;poll({11:true,7:true});
assert.equal(ctx.CM.phase,'backpressure');assert.deepEqual(edges(),[['down',11],['cancel',0]],'old unacknowledged slot was queued');
ctx.CM.pending.length=0;poll({11:true});assert.equal(ctx.CM.phase,'backpressure');poll();assert.equal(ctx.CM.phase,'messages');
init();requested();poll();ctx.ControllerMessageCancel();assert.equal(ctx.CM.seq,0,'idle L1 reveal sent unnecessary cancel');
init();requested();poll();poll({11:true});now=3600;poll();assert.equal(ctx.CM.phase,'keys');assert.equal(poll(),false,'logout never regained legacy input');
// Use the actual lease parser for mode/client handoffs and writer restart.
function lease(token='one',ack=0,mode='messages'){
 ctx.ControllerMessageLease('button_mode='+mode+'\nbutton_token='+token+'\nbutton_ack='+ack+'\n','data/Test.ini');
}
init();lease();assert(ctx.CM.requested);assert.equal(ctx.CM.seq,1);assert.deepEqual(edges(),[['cancel',0]]);
lease('one',1);assert.equal(ctx.CM.pending.length,0);poll();poll({11:true,7:true});
lease('two',0);assert.equal(ctx.CM.phase,'neutral');assert.equal(ctx.CM.path,'data/Test.buttons');
assert.deepEqual(edges(),[['cancel',0]],'another client inherited queued slot');
init();lease('resumed',12);assert.equal(ctx.CM.seq,13);assert.deepEqual(edges(),[['cancel',0]]);
lease('resumed',13);poll();poll({12:true});lease('',0,'keys');
assert(!ctx.CM.requested);assert.equal(poll({12:true}),true);poll();assert.equal(poll(),false);
init();lease();poll();ctx.ControllerMessageFlush=()=>false;assert.equal(poll({11:true}),true,'failed write fell through to keys');
let retries=0;ctx.ControllerMessageFlush=()=>{retries++;return false;};
now+=351;ctx.CM.seen=now;poll({11:true});assert.equal(ctx.CM.phase,'backpressure');
now+=100;ctx.CM.seen=now;poll({11:true});assert.equal(retries,2,'backpressure stopped retrying its cancel write');
const wrapper=fs.readFileSync('ffxi_directinput.ahk','utf8');
assert(wrapper.indexOf('if (ControllerMessagePoll(states))')<wrapper.indexOf('if (anyDown and !appsOwned)'));
assert(wrapper.includes('ControllerMessageCancel()'));
assert(!/SendEvent|ControlSend/.test(source),'message path injects keyboard signals');
assert(source.includes('CM.seq := requested ? ack1 + 0 : 0'),'writer restart discarded receiver acknowledgment');
assert(source.includes('ControllerMessageFlush(true)'),'writer restart/cancel did not publish');
console.log('Actual AHK message functions: legacy bypass, neutral handoffs, trigger-before-slot order, release order, held dedup, uncertain-read suppression, stale backlog cancellation, logout fallback and no key injection passed.');
