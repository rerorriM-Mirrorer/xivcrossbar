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
  return (down,time,consumed=false) => {
    const value=context.PersonalShoulderStep(g,down,previous,consumed,time,250);
    previous=down; return value;
  };
}
function touch() {
  const g={phase:'idle'}; let previous=false;
  return (down,time,l1=false,consumed=false) => {
    const value=context.PersonalTouchStep(g,down,previous,l1,consumed,time);
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
check('single R1 F8 immediately on completed tap',()=>{
  const s=shoulder(); assert.equal(s(true,100),'');assert.equal(s(false,150),'F8');
  assert.equal(s(false,399),'');assert.equal(s(false,401),'');assert.equal(s(false,450),'');
});
check('double R1 targets first, then requests Escape and switching',()=>{
  const s=shoulder();assert.equal(s(true,100),'');assert.equal(s(false,150),'F8');assert.equal(s(true,220),'');
  assert.equal(s(false,270),'switch');assert.equal(s(false,1000),'');
});
check('L1 singles preserve F10',()=>{
  const s=shoulder('F10');s(true,100);assert.equal(s(false,150),'F10');assert.equal(s(false,401),'');
});
check('long first hold still targets on release',()=>{
  const s=shoulder();s(true,100);assert.equal(s(true,3000),'');assert.equal(s(false,3010),'F8');
  assert.equal(s(false,3261),'');
});
check('combo consumes shoulder tap',()=>{
  const s=shoulder();s(true,100);s(true,150,true);assert.equal(s(false,200),'');assert.equal(s(false,500),'');
});
check('second combo cancels switching after first tap targeted',()=>{
  const s=shoulder();s(true,100);assert.equal(s(false,150),'F8');s(true,200);s(true,220,true);
  assert.equal(s(false,250),'');assert.equal(s(false,600),'');
});
check('context loss cancels the pending double window',()=>{
  const s=shoulder();s(true,100);assert.equal(s(false,150),'F8');s(false,200,true);assert.equal(s(false,1000),'');
});
check('slow separate taps both target',()=>{
  const s=shoulder();s(true,100);assert.equal(s(false,150),'F8');assert.equal(s(true,500),'');
  assert.equal(s(false,550),'F8');assert.equal(s(false,801),'');
});
check('long second hold cancels double switch',()=>{
  const s=shoulder();s(true,100);s(false,150);s(true,200);s(true,451);
  assert.equal(s(false,500),'');assert.equal(s(false,1000),'');
});
check('bare touchpad tap backtick only on release',()=>{
  const t=touch();assert.equal(t(true,100),'');assert.equal(t(false,300),'vkC0sc029');assert.equal(t(false,700),'');
});
check('map peek opens once and closes once',()=>{
  const t=touch();t(true,100);assert.equal(t(true,599),'');assert.equal(t(true,600),'vkC0sc029');
  assert.equal(t(true,900),'');assert.equal(t(false,1000),'Escape');assert.equal(t(false,1100),'');
});
check('peek focus/context loss cancels Escape',()=>{
  const t=touch();t(true,100);t(true,600);t(true,700,false,true);
  assert.equal(t(false,800),'');
});
check('L1 touchpad sends Tab on down, not release',()=>{
  const t=touch();assert.equal(t(true,100,true),'Tab');assert.equal(t(false,300,true),'');
});
check('simultaneous L1 and touchpad release retains Tab',()=>{
  const t=touch();assert.equal(t(true,100,true),'Tab');assert.equal(t(false,300,false),'');
});
check('L1 touchpad hold follows immediate Tab with F15',()=>{
  const t=touch();assert.equal(t(true,100,true),'Tab');assert.equal(t(true,600,true),'F15');
  assert.equal(t(true,800,true),'');assert.equal(t(false,900,false),'');
});
check('changing shoulder mid-touch does not change meaning',()=>{
  const t=touch();t(true,100);t(true,200,true);assert.equal(t(true,600,true),'');assert.equal(t(false,700),'');
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
function alt() {
  const g={altLatched:false};
  return (r1=true, l1=false, up=false, right=false, down=false, left=false, other=false)=>
    context.PersonalAltStep(g,r1,right,left);
}
check('vertical R1 arrows remain bare',()=>{const a=alt();assert.equal(a(true,false,true),false);
  assert.equal(a(true,false,false,false,true),false);});
check('right latches Alt through direction release',()=>{const a=alt();
  assert.equal(a(true,false,false,true),true);assert.equal(a(),true);});
check('left also latches Alt',()=>{const a=alt();assert.equal(a(true,false,false,false,false,true),true);});
check('up retains horizontal Alt latch until R1 release',()=>{const a=alt();a(true,false,false,true);
  assert.equal(a(true,false,true),true);assert.equal(a(),true);});
check('other R1 shortcut retains the logical Alt latch',()=>{const a=alt();a(true,false,false,true);
  assert.equal(a(true,false,false,false,false,false,true),true);});
check('R1 release clears Alt',()=>{const a=alt();a(true,false,false,true);assert.equal(a(false),false);});
check('L1 can suspend output without clearing the R1 latch',()=>{const a=alt();a(true,false,false,true);assert.equal(a(true,true),true);});
check('horizontal latches in a simultaneous diagonal',()=>{const a=alt();assert.equal(a(true,false,true,true),true);});
check('direct pulse suspends Alt and restores it after key-up',()=>{
  assert.equal(context.PersonalAltOutput(true,true,false,false,true),false);
  assert.equal(context.PersonalAltOutput(true,true,false,true,false),false);
  assert.equal(context.PersonalAltOutput(true,true,false,false,false),true);
});
check('context or L1 priority suspends Alt output',()=>{
  assert.equal(context.PersonalAltOutput(true,false,false,false,false),false);
  assert.equal(context.PersonalAltOutput(true,true,true,false,false),false);
});
check('switch waits for Escape pulse completion',()=>{
  const p={owner:100,due:140};assert.equal(context.PersonalSwitchStep(p,100,true,true,139),'wait');
  assert.equal(context.PersonalSwitchStep(p,100,true,true,140),'switch');
});
check('focus change cancels pending switch',()=>{
  assert.equal(context.PersonalSwitchStep({owner:100,due:140},200,true,true,150),'cancel');
});
check('new input cancels pending switch',()=>{
  assert.equal(context.PersonalSwitchStep({owner:100,due:140},100,true,false,150),'cancel');
});
check('menu or trigger context cancels pending switch',()=>{
  assert.equal(context.PersonalSwitchStep({owner:100,due:140},100,false,true,150),'cancel');
});
console.log(`${cases} gesture decision scenarios passed; Windows delivery remains a live check.`);
