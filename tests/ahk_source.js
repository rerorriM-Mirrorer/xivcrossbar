// Test-only normalization of native v2 constructs into the vocabulary consumed
// by the existing narrow AHK-to-JS harnesses. Never used by runtime scripts.
const fs = require('fs');
function read(path) {
  let s = fs.readFileSync(path, 'utf8');
  if (!path.endsWith('.ahk')) return s;
  s = s.replace(/try ControlSend\(([^\n]+), , "ahk_id " \. owner\)/g, 'ControlSend,, % $1, ahk_id %owner%')
    .replace('raw := states.Clone()', 'raw := []\n    for i, value in states\n        raw[i] := value')
    .replace(/raw\.%name%/g, 'raw[name]')
    .replace(/Loop Files pattern, "F"/g, 'Loop, Files, %pattern%, F')
    .replace(/readFailed := false, contents := ""\n\s*try contents := FileRead\(path, "CP0"\)\n\s*catch\n\s*readFailed := true/g, 'FileRead, contents, %path%\n            readFailed := ErrorLevel')
    .replace(/RegExMatch\(([^\n]+?), &(\w+)\)/g, 'RegExMatch($1, $2)')
    .replace(/\b(mode|value|ack|reason|capture|section|protocol|id|state|kill|closed|stamp|name|ready|policy|token|base|payload|edge|part|fn)\[([1-9])\]/g, '$1$2')
    .replace(/\bLoop (\d+)/g, 'Loop, $1')
    .replace(/\.Has\(/g, '.HasKey(').replace(/\.HasOwnProp\(/g, '.HasKey(')
    .replace(/\.Length\b(?!\()/g, '.Length()').replace(/\.Count\b(?!\()/g, '.Count()')
    .replace(/InputState\(\)/g, '[]')
    .replace(/\.Get\(([^,\n]+), (?:""|false)\)/g, '[$1]')
    .replace(/DateDiff\((\w+), "19700101000000", "Seconds"\)/g, '$1')
    .replace(/(\w+) := \1/g, '$1 := $1');
  // Existing translators model dictionaries as JS objects and numeric-key
  // objects, so translate only Map constructors, leaving all policy code intact.
  s = s.replace(/Map\(([^()]*)\)/g, (_, args) => {
    if (!args.trim()) return '{}';
    const parts = args.match(/"[^"\n]*"|[^,]+/g).map(x=>x.trim());
    let entries=[];
    for(let i=0;i<parts.length;i+=2) entries.push(parts[i]+':'+parts[i+1]);
    return '{'+entries.join(', ')+'}';
  });
  // v2 Delete requires a guard; JS delete already tolerates absent keys.
  s=s.replace(/^\s*if PC\.(suppressed|releases)\.HasKey\([^\n]+\)\n/gm,'\n')
     .replace(/^\s*if PC\.native\.active\.HasKey\([^\n]+\)\n/gm,'\n');
  return s;
}
module.exports = {read};
