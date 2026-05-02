const fs = require('fs');
const path = require('path');

const md = fs.readFileSync(path.join(__dirname, '../docs/SkillTreeReference.md'), 'utf8');

const lines = md.split('\n');
let currentClass = null;
const classes = {};

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  
  // Find class headers
  let match = line.match(/^## (Tank|DPS|Support|Hybrid|Controller)$/i);
  if (!match) {
    match = line.match(/^### Subclass: (.*?) \(/i);
  }
  
  if (match) {
    currentClass = match[1].toLowerCase().replace(' ', '_');
    classes[currentClass] = [];
    continue;
  }
  
  // Find table rows
  if (currentClass && line.startsWith('|') && !line.includes('Skill Name') && !line.includes('---')) {
    const parts = line.split('|').map(p => p.trim());
    if (parts.length >= 7) {
      let name = parts[1].replace(/\*\*/g, '');
      let type = parts[2].replace(/\*\*/g, '');
      let desc = parts[3].replace(/\*\*/g, '');
      let initial = parts[4].replace(/\*\*/g, '');
      let perLvl = parts[5].replace(/\*\*/g, '');
      let max = parts[6].replace(/\*\*/g, '');
      
      classes[currentClass].push({ name, type, desc, initial, perLvl, max });
    }
  }
}

console.log("Found classes:", Object.keys(classes));
console.log("DPS skills:", classes['dps']);
