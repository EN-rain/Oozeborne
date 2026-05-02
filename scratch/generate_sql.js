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

const customLabels = {
  "Static Build": "+[[0]]% lightning damage on CC'd targets up to +[[1]]%",
  "Thunder Clap": "Slam ground sending shockwave in 6m radius, stunning for [[0]]s",
  "Shockwave": "Chain of 2 shockwaves (8m range) dealing [[0]] damage + [[1]]% slow for 1s",
  "Fortify": "Gain [[0]]% damage reduction, taunt [[1]]m for [[2]]s",
  "Shield Wall": "-[[0]]% damage, taunt [[1]]m for [[2]]s",
  "Blood Rage": "+[[0]]% atk spd, +[[1]]% dmg for [[2]]s",
  "Divine Shield": "Invulnerable [[0]]s, heal [[1]]% max HP",
  "Burst Window": "+[[0]]% attack, +[[1]]% crit for [[2]]s",
  "Shadow Step": "Teleport, +[[0]]% crit next hit for [[1]]s",
  "Trap Network": "Place [[0]] trap: [[1]] dmg + [[2]]s slow",
  "Meteor Storm": "[[0]] dmg over [[1]]s in large area",
  "Iaijutsu": "[[0]]x dmg after [[1]]s charge",
  "Field Aid": "Restore [[0]] HP over [[1]]s, +[[2]]% defense",
  "Divine Blessing": "Holy zone: [[0]] HP/s, +[[1]]% defense, [[2]]s",
  "Symphony of War": "Allies +[[0]]% dmg, +[[1]]% atk spd for [[2]]s",
  "Plague Flask": "Poison cloud: [[0]] dmg over [[1]]s",
  "Grave Swarm": "[[0]] dmg/s for [[1]]s",
  "Adaptive Stance": "+[[0]]% all stats for [[1]]s",
  "Elemental Infusion": "+[[0]]% elemental dmg for [[1]]s",
  "Dark Pact": "Sacrifice [[0]]% HP, deal [[1]] dmg, heal [[2]]%",
  "Seven-Point Strike": "5 strikes, [[0]] dmg each, final crit + stun [[1]]s",
  "Control Field": "6m zone: [[0]]% slow, [[1]]% enemy dmg, [[2]]s",
  "Time Fracture": "[[0]]% slow enemies, +[[1]]% haste exit, [[2]]s",
  "Bastion Ring": "Ring [[0]]s: [[1]]% slow, root first target",
  "Severing Hex": "Cone: [[0]]% enemy dmg, +[[1]]% ability dmg taken for [[2]]s",
  "Tempest Pulse": "[[0]] dmg, knockback [[1]]m, [[2]]s slow",
};

let sql = `-- Migration to populate ALL accurate skill data from SkillTreeReference.md\n`;
sql += `UPDATE class_configs SET skills = '[]'::jsonb;\n\n`;

for (const [cls, data] of Object.entries(classes)) {
  if (data.skills.length === 0) continue;
  
  const skillsJson = JSON.stringify(data.skills.map(sk => ({
    name: sk.name,
    desc: sk.desc,
    type: sk.type,
    paramLabel: customLabels[sk.name] || sk.desc,
    params: sk.params
  }))).replace(/'/g, "''");
  
  sql += `UPDATE class_configs SET skills = '${skillsJson}'::jsonb WHERE class_id = '${cls}';\n`;
}

fs.writeFileSync(path.join(__dirname, '../moon_server/db/migrations/009_all_skills_data.sql'), sql);
console.log("Generated 009_all_skills_data.sql!");
