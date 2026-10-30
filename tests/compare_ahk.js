// Same existing scenarios against exact v1 source and current native v2 source.
// Both are narrow source-to-JS execution, not Windows/physical delivery tests.
const {spawnSync}=require('child_process'),assert=require('assert/strict');
const baseline=process.argv[2]||'ed86e5f36c435273b62332278ed08fcb82c2f27f';
const suites=['personal_gestures','personal_input','controller_messages','controller_clients',
 'personal_realkeys','companion_native','xinput_extended','input_trace'];
for(const suite of suites){
 const results=[baseline,''].map(ref=>spawnSync(process.execPath,['tests/'+suite+'.js'],{
  encoding:'utf8',env:{...process.env,XIV_AHK_BASELINE:ref}}));
 for(let i=0;i<2;i++)assert.equal(results[i].status,0,suite+' '+(i?'v2':'v1')+'\n'+results[i].stdout+results[i].stderr);
 assert.equal(results[0].stdout,results[1].stdout,suite+' observable test outputs differ');
 console.log('Equivalent translated scenarios/output: '+suite);
}
console.log('8 v1/v2 translated suites passed; no native timing/delivery equivalence claimed.');
