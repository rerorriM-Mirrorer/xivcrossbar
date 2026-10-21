// Actual AHK decision function, with native process/file observations simulated.
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
let s=fs.readFileSync('controller_clients.ahk','utf8');
s=s.slice(s.indexOf('WrapperClientsDecision(state,'),s.indexOf('\nWrapperOwnerAlive(',s.indexOf('WrapperClientsDecision(state,')));
s=s.replace(/;[^\n]*/g,'').replace(/:=/g,'=').replace(/\bor\b/g,'||').replace(/\band\b/g,'&&');
s=s.replace(/^WrapperClientsDecision\(/,'function decision(');
const ctx={};vm.createContext(ctx);vm.runInContext(s,ctx);
const state={seen:false,emptySince:0,lastClose:0};
assert.equal(ctx.decision(state,0,0,true,1000),false,'manual pre-login wrapper stopped');
state.seen=true;
assert.equal(ctx.decision(state,1,10,true,1000),false,'another client was stopped');
assert.equal(ctx.decision(state,0,10,true,1100),false);
assert.equal(ctx.decision(state,0,10,true,3099),false);
assert.equal(ctx.decision(state,0,10,true,3100),true);
assert.equal(ctx.decision(state,1,0,false,3200),false,'reload did not reset grace');
assert.equal(ctx.decision(state,0,11,false,3300),false);
assert.equal(ctx.decision(state,0,11,false,10000),false,'false setting ignored');
assert.equal(ctx.decision(state,0,12,true,10100),false,'new departure did not get grace');
assert.equal(ctx.decision(state,0,12,true,12100),true);
console.log('AHK lifecycle policy: manual startup, remaining clients, grace, reload and last-client preference passed.');
// Parse the actual private record reader using its actual expressions.
let parser=fs.readFileSync('controller_clients.ahk','utf8');
parser=parser.slice(parser.indexOf('\nWrapperClientRecord(contents) {')+1).trim();
parser=parser.replace(/RegExMatch\((contents|section1), ("[^"\n]+"), (\w+)\)/g,'RegExMatch($1, $2, "$3")');
parser=parser.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?JSON.stringify(t.slice(1,-1)):t
 .replace(/\bor\b/g,'||').replace(/\band\b/g,'&&'));
parser=parser.replace(/^WrapperClientRecord\(/,'function record(').replace('closed1 + 0','Number(closed1)');
const observed={};
observed.RegExMatch=(value,pattern,name)=>{
 const flags=pattern.match(/^([ims]+)\)/);if(flags)pattern=pattern.slice(flags[0].length);
 pattern=pattern.replace(/\\z/g,'$(?![\\s\\S])');
 const m=new RegExp(pattern,flags?flags[1]:'').exec(value);
 observed[name+'1']=m?m[1]:'';return !!m;
};
vm.createContext(observed);vm.runInContext(parser,observed);
const record='[Client]\nprotocol=owner-file-v1\nid=123456-1234\nstate=loaded\nkill=false\nclosed=0\n';
let row=observed.record(record);assert.equal(row.id,'123456-1234');assert.equal(row.state,'loaded');assert.equal(row.kill,'false');
row=observed.record(record.replace(/\n/g,'\r\n').replace('closed=0','closed=1792542736.25'));
assert.equal(row.closed,1792542736.25);
assert.equal(observed.record(record.replace('protocol=owner-file-v1','protocol=old')),false);
assert.equal(observed.record(record.replace('kill=false','kill=unknown')),false);
assert.equal(observed.record(record.replace('closed=0','closed=broken')),false);
assert.equal(observed.record('[Other]\n'+record.split('\n').slice(1).join('\n')),false);
assert.equal(observed.record('[Client]\nprotocol=owner-file-v1\n[Other]\nid=x\nstate=loaded\nkill=true\nclosed=0\n'),false);
const all=fs.readFileSync('controller_clients.ahk','utf8');assert(!all.includes('IniRead,'));
assert.equal((all.match(/FileRead, contents/g)||[]).length,1);
assert(all.indexOf('WC.retired.HasKey(path)')<all.indexOf('FileRead, contents'));
assert(all.includes('if (!alive)\n                WC.retired[path] := record'));
console.log('Actual lifecycle record parser: complete LF/CRLF snapshots, section isolation, malformed records, one-read scan and retired-session bypass passed.');
// Exercise the actual scan with native files/ownership simulated. No Windows
// latency claim: verify dead-session caching cannot discard a live/new client.
let scan=all.slice(all.indexOf('\nWrapperClientsShouldExit() {')+1,all.indexOf('\n; A: testable lifecycle'));
scan=scan.replace(/^\s*global .*$/gm,'').replace(/;[^\n]*/g,'')
 .replace(/Loop, Files, %pattern%, F\s*\{/g,'for (const A_LoopFileFullPath of paths) {')
 .replace(/FileRead, contents, %path%/g,'contents:=readRecord(path)');
scan=scan.replace(/"(?:[^"]|"")*"|[^"\n]+/g,t=>t.startsWith('"')?JSON.stringify(t.slice(1,-1)):t
 .replace(/ \. /g,' + ').replace(/:=/g,'@ASSIGN@').replace(/(?<![<>!:=+])=(?!=)/g,'===')
 .replace(/@ASSIGN@/g,'=').replace(/\bor\b/g,'||').replace(/\band\b/g,'&&'));
scan=scan.replace(/^WrapperClientsShouldExit\(\) \{/,'function scan() { var scanStarted,loaded,latestClose,latestKill,pattern,path,readStarted,contents,readFailed,record,ownerStarted,alive,id,state,kill,closed,known;');
const dict=()=>({HasKey(k){return Object.hasOwn(this,k);}});
let reads=0,owners=0,lastLoaded;
const native={A_TickCount:1000,A_ScriptDir:'addon',WC:{seen:false,tokens:dict(),retired:dict(),lastPoll:0,emptySince:0,lastClose:0},
 paths:['one','old'],files:{one:record,old:record.replace('id=123456-1234','id=old').replace('state=loaded','state=closing').replace('closed=0','closed=10')},
 alive:{one:true,old:false},ErrorLevel:0,
 DllCall:()=>native.A_TickCount,InputTimingOperation:()=>{},IsObject:x=>x!==null&&typeof x==='object',
 WrapperClientRecord:observed.record,WrapperClientsClock:()=>20,
 WrapperOwnerAlive:p=>{owners++;return !!native.alive[p.replace(/\.owner$/,'')];},
 readRecord:p=>{reads++;native.ErrorLevel=0;return native.files[p];},
 WrapperClientsDecision:(state,loaded,closed,kill,now)=>{lastLoaded=loaded;return ctx.decision(state,loaded,closed,kill,now);}};
vm.createContext(native);vm.runInContext(scan,native);
assert.equal(native.scan(),false);assert.equal(reads,2);assert.equal(owners,2);assert.equal(lastLoaded,1);
native.A_TickCount+=250;native.scan();assert.equal(reads,3);assert.equal(owners,3,'retired session reopened');
native.paths.push('new');native.files.new=record.replace('id=123456-1234','id=new');native.alive.new=true;
native.A_TickCount+=250;native.scan();assert.equal(lastLoaded,2,'new session masked by retired cache');
native.alive.one=false;native.files.one=record.replace('state=loaded','state=closing').replace('kill=false','kill=true').replace('closed=0','closed=20');
native.A_TickCount+=250;native.scan();assert.equal(lastLoaded,1,'remaining client ignored');
native.alive.new=false;native.files.new=native.files.one.replace('id=123456-1234','id=new');native.A_TickCount+=250;
assert.equal(native.scan(),false);native.A_TickCount+=1999;assert.equal(native.scan(),false);
native.A_TickCount+=250;assert.equal(native.scan(),true,'last-client preference/grace lost');
console.log('Actual lifecycle scan: one-read active refresh, retired-cache bypass, new/reloaded clients, remaining clients and last-close grace passed.');
