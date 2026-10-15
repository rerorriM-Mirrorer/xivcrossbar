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
check('bare L1 switches immediately on release',()=>{
  const s=shoulder('switch');assert.equal(s(true),'');assert.equal(s(false),'switch');assert.equal(s(false),'');
});
check('two completed L1 taps switch twice; no double mode or delay',()=>{
  const s=shoulder('switch');s(true);assert.equal(s(false),'switch');s(true);assert.equal(s(false),'switch');
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
function pair() {
  const g={ctrl:false,alt:false};
  return (l1=false,l2=false,r1=false,r2=false,allowed=true)=>context.PersonalModifierStep(g,l1,l2,r1,r2,allowed);
}
check('Ctrl starts on L1+L2 without an arrow',()=>{const p=pair();assert.equal(p(true,true),'ctrl');});
check('Alt starts on R1+R2 without an arrow',()=>{const p=pair();assert.equal(p(false,false,true,true),'alt');});
check('single buttons never start modifiers',()=>{
  for(let i=0;i<4;i++){const a=[false,false,false,false];a[i]=true;assert.equal(pair()(...a),'');}
});
check('Ctrl survives either first release until both released',()=>{
  for(const a of [[true,false],[false,true]]) {const p=pair();p(true,true);assert.equal(p(...a),'ctrl');assert.equal(p(),'');}
});
check('Alt survives either first release until both released',()=>{
  for(const a of [[true,false],[false,true]]) {const p=pair();p(false,false,true,true);assert.equal(p(false,false,...a),'alt');assert.equal(p(),'');}
});
check('pairs can overlap and release independently',()=>{
  const p=pair();assert.equal(p(true,true,true,true),'both');assert.equal(p(false,false,true,false),'alt');assert.equal(p(),'');
});
check('focus/menu loss clears both modifiers immediately',()=>{
  const p=pair();p(true,true,true,true);assert.equal(p(true,true,true,true,false),'');assert.equal(p(),'');
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
check('navigation releases Apps before modifier down and masks transport buttons',()=>{
  const begin=controls.indexOf('if (navigation != "")');const end=controls.indexOf('if (PC.navigationActive)',begin+30);
  const body=controls.slice(begin,end);
  assert(body.indexOf('ReleaseTransport(true)')<body.indexOf('PersonalKey("LControl"'));
  assert(body.includes('Loop, 12')&&body.includes('return PersonalFilter(states, raw)'));
});
check('PS is one focus toggle per down edge, with no hold threshold',()=>{
  const ps=controls.slice(controls.indexOf('\nPersonalPS('),controls.indexOf('\nPersonalActivate('));
  assert(ps.includes('PC.previous.ps')&&ps.includes('PersonalClientTarget(0)'));
  assert(!ps.includes('500')&&!ps.includes('WinMinimize'));
});
console.log(`${cases} personal gesture/routing scenarios passed; Windows delivery remains a live check.`);
