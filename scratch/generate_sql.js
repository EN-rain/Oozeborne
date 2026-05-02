const fs = require('fs');
const path = require('path');

const md = fs.readFileSync(path.join(__dirname, '../docs/SkillTreeReference.md'), 'utf8');

const lines = md.split('\n');
let currentClass = null;
const classes = {};

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  
  let match = line.match(/^## (Tank|DPS|Support|Hybrid|Controller)$/i);
  if (!match) match = line.match(/^### Subclass: (.*?) \(/i);
  
  if (match) {
    currentClass = match[1].toLowerCase().replace(' ', '_');
    if (!classes[currentClass]) classes[currentClass] = { skills: [] };
    continue;
  }

  // Find Base Stats / Subclass Stats
  if (currentClass && line.includes('Stats:**')) {
    classes[currentClass].raw_stats = line;
  }
  
  // Find table rows
  if (currentClass && line.startsWith('|') && !line.includes('Skill Name') && !line.includes('---')) {
    const parts = line.split('|').map(p => p.trim());
    if (parts.length >= 7) {
      let name = parts[1].replace(/\*\*/g, '');
      let type = parts[2].replace(/\*\*/g, '');
      let desc = parts[3].replace(/\*\*/g, '');
      
      const parseVals = (str) => {
        return str.replace(/\*\*/g, '').split('/').map(s => {
          const num = parseFloat(s.replace(/[^0-9.-]/g, ''));
          return isNaN(num) ? 0 : num;
        });
      };
      
      let initVals = parseVals(parts[4]);
      let perLvlVals = parseVals(parts[5]);
      let maxVals = parseVals(parts[6]);
      
      // Ensure equal lengths
      const len = Math.max(initVals.length, perLvlVals.length, maxVals.length);
      const params = [];
      for (let j = 0; j < len; j++) {
        params.push({
          init: initVals[j] || 0,
          per_lvl: perLvlVals[j] || 0,
          max: maxVals[j] || 0
        });
      }
      
      classes[currentClass].skills.push({ name, type, desc, params });
    }
  }
}

let sql = `-- Migration to populate ALL accurate skill data from SkillTreeReference.md\n`;
sql += `UPDATE class_configs SET skills = '[]'::jsonb;\n\n`;

for (const [cls, data] of Object.entries(classes)) {
  if (data.skills.length === 0) continue;
  
  const skillsJson = JSON.stringify(data.skills.map(sk => ({
    name: sk.name,
    desc: sk.desc,
    type: sk.type,
    params: sk.params
  }))).replace(/'/g, "''");
  
  sql += `UPDATE class_configs SET skills = '${skillsJson}'::jsonb WHERE class_id = '${cls}';\n`;
}

fs.writeFileSync(path.join(__dirname, '../moon_server/db/migrations/010_all_skills_data.sql'), sql);
console.log("Generated 010_all_skills_data.sql!");
