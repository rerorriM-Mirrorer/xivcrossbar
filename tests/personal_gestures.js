// Exercise the actual pure AHK gesture functions through a narrow syntax
// translation. This checks decisions, not the Windows/AHK runtime or SendEvent.
const fs = require('fs');
const vm = require('vm');
const assert = require('assert/strict');
let source = fs.readFileSync('personal_gestures.ahk', 'utf8');
source = source.replace(/;[^\n]*/g, '').replace(/"(?:[^"]|"")*"|[^"\n]+/g, token => {
  if (token.startsWith('"')) return token;
  return token.replace(/:=/g, '@ASSIGN@').replace(/(?<![<>!:=])=(?!=)/g, '===')
    .replace(/@ASSIGN@/g, '=').replace(/\band\b/g, '&&').replace(/\bor\b/g, '||');
});
source = source.replace(/^(Personal\w+\([^\n]+\)) \{/gm, 'function $1 { let event, phase;');
const context = {};
vm.createContext(context);
vm.runInContext(source, context, {filename:'translated-personal_gestures.ahk'});
let cases = 0;
function shoulder(key='F8') {
  const g={phase:'idle', key}; let previous=false;
  return (down,consumed=false) => {
    const value=context.PersonalShoulderStep(g,down,previous,consumed);
    previous=down; return value;
  };
}
function touch() {
  const g={phase:'idle'}; let previous=false;
  return (down,time,consumed=false) => {
    const value=context.PersonalTouchStep(g,down,previous,consumed,time);
    previous=down; return value;
  };
}
function clicks() {
  const g={phase:'idle'}; let l=false,r=false;
  return (nl,nr,consumed=false) => {
    const value=context.PersonalClicksStep(g,nl,nr,l,r,consumed);
    l=nl;r=nr;return value;
  };
}
function check(name, run) {run();cases++;}
check('brief unknown lease pauses without authorizing actions; stale/lost sessions do not pause',()=>{
  assert.equal(context.PersonalLeasePause('unknown',1015,1000,true),true);
  assert.equal(context.PersonalLeasePause('unknown',1100,1000,true),true);
  assert.equal(context.PersonalLeasePause('unknown',1101,1000,true),false);
  assert.equal(context.PersonalLeasePause('unknown',1015,1000,false),false);
  assert.equal(context.PersonalLeasePause('unknown',1015,0,true),false);
  for(const mode of ['stale','text','menu:1','unfocused','gameplay'])
    assert.equal(context.PersonalLeasePause(mode,1015,1000,true),false);
});
check('bare R1 keeps F8 on release',()=>{const s=shoulder();s(true);assert.equal(s(false),'F8');});
check('combinations consume shoulder single',()=>{
  const s=shoulder('switch');s(true);s(true,true);assert.equal(s(false),'');
});
check('context loss cannot switch on release',()=>{
  const s=shoulder('switch');s(true);s(true,true);assert.equal(s(false,true),'');assert.equal(s(false),'');
});
check('holding a shoulder does not repeat',()=>{
  const s=shoulder('switch');s(true);assert.equal(s(true),'');assert.equal(s(true),'');assert.equal(s(false),'switch');
});
check('bare touchpad tap backtick only on release',()=>{
  const t=touch();assert.equal(t(true,100),'');assert.equal(t(false,300),'vkC0sc029');assert.equal(t(false,700),'');
});
check('map peek opens once and closes once',()=>{
  const t=touch();t(true,100);assert.equal(t(true,599),'');assert.equal(t(true,600),'vkC0sc029');
  assert.equal(t(true,900),'');assert.equal(t(false,1000),'Escape');assert.equal(t(false,1100),'');
});
check('peek focus/context loss cancels Escape',()=>{
  const t=touch();t(true,100);t(true,600);t(true,700,true);assert.equal(t(false,800),'');
});
check('L1 touchpad is reserved, emits neither Tab nor F15',()=>{
  const t=touch();assert.equal(t(true,100,true),'');assert.equal(t(true,600,true),'');assert.equal(t(false,700,true),'');
});
check('adding shoulder mid-peek cannot retain Escape',()=>{
  const t=touch();t(true,100);t(true,600);t(true,700,true);assert.equal(t(false,800),'');
});
check('R3 then L3 holds comma, without autorun/heal',()=>{
  const c=clicks();assert.equal(c(false,true),'');assert.equal(c(true,true),'vkBCsc033');
  assert.equal(c(true,true),'vkBCsc033');assert.equal(c(false,true),'');assert.equal(c(false,false),'');
});
check('L3 then R3 holds period',()=>{
  const c=clicks();c(true,false);assert.equal(c(true,true),'vkBEsc034');assert.equal(c(false,false),'');
});
check('bare clicks H/R only on release',()=>{
  const c=clicks();assert.equal(c(true,false),'');assert.equal(c(false,false),'h');
  assert.equal(c(false,true),'');assert.equal(c(false,false),'r');
});
check('same sample clicks do not guess order',()=>{
  const c=clicks();assert.equal(c(true,true),'');assert.equal(c(false,true),'');assert.equal(c(false,false),'');
});
check('focus loss cancels held click',()=>{
  const c=clicks();c(true,false);c(true,false,true);assert.equal(c(false,false),'');
});
check('releasing first before overlap cancels pair',()=>{
  const c=clicks();c(true,false);assert.equal(c(false,true),'');assert.equal(c(false,false),'');
});
check('comma follows second click after first releases',()=>{
  const c=clicks();c(false,true);c(true,true);assert.equal(c(true,false),'vkBCsc033');
  assert.equal(c(false,false),'');
});
check('period follows second click after first releases',()=>{
  const c=clicks();c(true,false);c(true,true);assert.equal(c(false,true),'vkBEsc034');
  assert.equal(c(false,false),'');
});
check('second click release requires both neutral before rearming',()=>{
  const c=clicks();c(false,true);c(true,true);assert.equal(c(false,true),'');
  assert.equal(c(true,true),'');assert.equal(c(false,false),'');
  c(false,true);assert.equal(c(true,true),'vkBCsc033');
});
check('focus loss clears held zoom output',()=>{
  const c=clicks();c(true,false);c(true,true);assert.equal(c(true,true,true),'');
  assert.equal(c(false,false),'');
});
function layer() {
  const g={phase:'idle'};
  return (l1=false,l2=false,r1=false,r2=false)=>context.PersonalLayerStep(g,l1,l2,r1,r2);
}
check('bare L1 reveals only while held and taps never toggle',()=>{
  const p=layer();for(let i=0;i<3;i++){assert.equal(p(true),'keyboard');assert.equal(p(),'');}
});
check('L1 first reveals bank; L2 release reveals keyboard again',()=>{
  const p=layer();p(true);assert.equal(p(true,true),'bank');assert.equal(p(true,true),'bank');
  assert.equal(p(true,false),'keyboard');assert.equal(p(),'');
});
check('L2 first remains ordinary until L2 releases',()=>{
  const p=layer();assert.equal(p(false,true),'ordinary');assert.equal(p(true,true),'ordinary');
  assert.equal(p(true,false),'keyboard');assert.equal(p(),'');
});
check('same sample L1+L2 preserves ordinary crossbar',()=>{assert.equal(layer()(true,true),'ordinary');});
check('releasing L1 first consumes remaining L2 without opening ordinary bar',()=>{
  const p=layer();p(true);p(true,true);assert.equal(p(false,true),'tail');
  assert.equal(p(true,true),'tail');assert.equal(p(true,false),'keyboard');
});
check('R2 takes ordinary priority and shoulder pairs never create modifiers',()=>{
  const p=layer();p(true);p(true,true);assert.equal(p(true,true,false,true),'ordinary');
  assert.equal(p(false,false,true,true),'ordinary');assert.equal(p(false,false,true,false),'');
});
check('POV centered/invalid is neutral',()=>{for(const v of [-1,65535,40000])assert.equal(context.PersonalPovDirection(v,1),0);});
check('POV cardinals and diagonal rolls retain one adjacent direction',()=>{
  for(let i=0;i<4;i++){
    const current=i+1,next=(i+1)%4+1,diag=i*9000+4500;
    assert.equal(context.PersonalPovDirection(i*9000,0),current);
    assert.equal(context.PersonalPovDirection(diag,current),current);
    assert.equal(context.PersonalPovDirection(diag,next),next);
    assert.equal(context.PersonalPovDirection(diag,0),current);
  }
});
// Read actual shortcut declarations rather than maintain an implementation copy.
const controls=fs.readFileSync('personal_controls.ahk','utf8');
const shortcuts=vm.runInNewContext('({'+controls.match(/shortcuts := \{([^}]+)\}/)[1]+'})');
check('L1 keys match the requested physical-button mapping',()=>{
  assert.deepEqual(JSON.parse(JSON.stringify(shortcuts)),{1:'i',2:'m',3:'e',4:'j',5:'Space',6:'q',7:'',8:'s'});
});
check('layer reveal releases Apps first and consumes held buttons; bank masks L2',()=>{
  const body=controls.slice(controls.indexOf('if (layerChanged)'),controls.indexOf('taps := []'));
  assert(body.indexOf('ReleaseTransport(true)')<body.indexOf('PersonalL1Event(layer'));
  assert(body.includes('PersonalL1Block(raw)')&&body.includes('states[11] := false'));
  assert(controls.includes('if (!layerChanged and raw[i] and !PC.previous[i])'));
  assert(!controls.includes('PersonalModifierStep')&&!controls.includes('PersonalKey("LAlt", PC.'));
});
check('PS is one focus toggle per down edge, with no hold threshold',()=>{
  const ps=controls.slice(controls.indexOf('\nPersonalPS('),controls.indexOf('\nPersonalActivate('));
  assert(ps.includes('PC.previous.ps')&&ps.includes('PersonalClientTarget(0)'));
  assert(!ps.includes('500')&&!ps.includes('WinMinimize'));
});
check('L1 bank uses existing slot order and does not emit native Ctrl keys',()=>{
  const sequence=controls.match(/slots := \[([^\]]+)\]/)[1].split(',').map(Number);
  assert.deepEqual(sequence,[4,3,2,1,6,5,7,8]);
  assert(controls.includes('else if (layer = "keyboard" and key != "")'));
  assert(!controls.includes('key:"l1mode"')&&!controls.includes('PersonalL1Event("tap")'));
});
check('only context changes require neutral, not layer changes',()=>{
  assert(!controls.includes('PC.l1.waiting'));
  const lease=controls.slice(controls.indexOf('\nPersonalL1Lease('),controls.indexOf('\nPersonalL1Block('));
  assert(lease.includes('PC.ready := false')&&lease.includes('PC.l1.token != token1'));
});
console.log(`${cases} personal gesture/routing scenarios passed; Windows delivery remains a live check.`);

