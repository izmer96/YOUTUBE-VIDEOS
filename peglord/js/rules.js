/* Seeded RNG, hero math and gear generation. */
'use strict';

// ---------- Seeded RNG ----------
function hashSeed(str) {
  let h = 1779033703 ^ str.length;
  for (let i = 0; i < str.length; i++) { h = Math.imul(h ^ str.charCodeAt(i), 3432918353); h = (h << 13) | (h >>> 19); }
  h = Math.imul(h ^ (h >>> 16), 2246822507); h = Math.imul(h ^ (h >>> 13), 3266489909);
  return (h ^= h >>> 16) >>> 0;
}
const RNG = {
  s: 1,
  seed(str) { this.s = hashSeed(String(str)) || 1; },
  next() { let t = (this.s = (this.s + 0x6D2B79F5) >>> 0); t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; },
  int(n) { return Math.floor(this.next() * n); },
  range(a, b) { return a + this.next() * (b - a); },
  pick(arr) { return arr[this.int(arr.length)]; },
  chance(p) { return this.next() < p; },
  shuffle(arr) { for (let i = arr.length - 1; i > 0; i--) { const j = this.int(i + 1); [arr[i], arr[j]] = [arr[j], arr[i]]; } return arr; },
  weighted(weights) { const tot = weights.reduce((a, b) => a + b, 0); let r = this.next() * tot; for (let i = 0; i < weights.length; i++) { r -= weights[i]; if (r < 0) return i; } return weights.length - 1; },
};
function randomSeedString() {
  const w = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; let s = '';
  for (let i = 0; i < 6; i++) s += w[Math.floor(Math.random() * w.length)];
  return s;
}

// ---------- Global game state ----------
let G = null;
let nextId = 1;
const uid = () => nextId++;
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const hasJoker = id => G && G.jokers.includes(id);

// ---------- Hero math ----------
function softCap(a) {
  if (a <= SOFT_CAP_1) return a;
  if (a <= SOFT_CAP_2) return SOFT_CAP_1 + (a - SOFT_CAP_1) / 2;
  return SOFT_CAP_1 + (SOFT_CAP_2 - SOFT_CAP_1) / 2 + (a - SOFT_CAP_2) / 4;
}
function scaleCurve(a) { return a <= 20 ? a / 20 : Math.min(2, 1 + (a - 20) / 40); }

function makeHero(cls) {
  const def = HEROES[cls];
  const h = { id: uid(), cls, name: def.name, bought: { vig: 0, str: 0, dex: 0, int: 0, fai: 0, arc: 0 }, level: 1,
    hp: 1, shield: 0, gear: {}, cmd: 'attack', cd: 0, guarding: false, dead: false, hex: 0, defBuff: 0,
    used: { laststand: false, overcast: false, resurrect: false } };
  SLOTS.forEach(s => (h.gear[s] = null));
  def.start.forEach(fam => {
    const it = fam === 'shield' ? genItem(1, 0, 'offhand', { offType: 'shield' }) : genItem(1, 0, 'weapon', { family: fam });
    h.gear[it.slot] = it;
  });
  h.hp = heroStats(h).maxHp;
  return h;
}

function hasPerk(h, lvl) { return h.level >= lvl; }
function legend(h, id) { return SLOTS.some(s => h.gear[s] && h.gear[s].legend === id); }
function setCount(h, set) { return SET_SLOTS.filter(s => h.gear[s] && h.gear[s].set === set).length; }

function totalAttrs(h) {
  const def = HEROES[h.cls];
  const a = {};
  ATTRS.forEach(k => (a[k] = def.attrs[k] + h.bought[k]));
  SLOTS.forEach(s => { const it = h.gear[s]; if (it) it.affixes.forEach(x => { if (x.type === 'attr') a[x.attr] += x.value; }); });
  if (hasJoker('glasscannon')) { const main = mainStat(h); a[main] += 1; }
  if (hasJoker('overclock')) { let best = 'vig'; ATTRS.forEach(k => { if (a[k] > a[best]) best = k; }); a[best] += 2; }
  return a;
}
function mainStat(h) {
  const w = h.gear.weapon; if (!w) return 'str';
  const g = w.grades; let best = null;
  Object.keys(g).forEach(k => { if (!best || GRADES[g[k]] > GRADES[g[best]]) best = k; });
  return best || 'str';
}
function affixSum(h, type) {
  let v = 0;
  SLOTS.forEach(s => { const it = h.gear[s]; if (it) it.affixes.forEach(x => { if (x.type === type) v += x.value; }); });
  return v;
}

function weaponAR(h, w, attrs) {
  const eff = {}; ATTRS.forEach(k => (eff[k] = softCap(attrs[k])));
  if (!w) {
    const ar = 3 * (1 + GRADES.D * scaleCurve(eff.str));
    return { ar: Math.max(1, Math.round(ar)), type: 'phys', parts: [{ attr: 'str', grade: 'D', bonus: 0 }], short: [], base: 3 };
  }
  let sum = 0; const parts = [];
  Object.keys(w.grades).forEach(k => {
    const g = GRADES[w.grades[k]] * scaleCurve(eff[k]);
    sum += g; parts.push({ attr: k, grade: w.grades[k], bonus: w.base * g });
  });
  const fav = HEROES[h.cls].favoured.includes(w.family) ? FAVOURED_AFFINITY : 0;
  let ar = w.base * (1 + sum) * (1 + UPGRADE_STEP * w.upg) * (1 + fav);
  const short = [];
  Object.keys(w.req).forEach(k => { if (attrs[k] < w.req[k]) short.push({ attr: k, need: w.req[k], have: attrs[k] }); });
  if (short.length) ar *= 1 - REQ_PENALTY;
  let mult = 1 + affixSum(h, 'atk') / 100;
  if (w.type === 'magic') {
    if (h.cls === 'mage') mult *= 1.15;
    if (h.gear.offhand && h.gear.offhand.offType === 'orb') mult *= 1 + ORB_BONUS;
    if (setCount(h, 'spiller') >= 2) mult *= 1.10;
  }
  ar *= mult;
  return { ar: Math.max(1, Math.round(ar)), type: w.type, parts, short, fav, base: w.base };
}

function armorValue(it, attrs) {
  if (!it || it.def == null) return { def: 0, res: 0 };
  let ok = true;
  if (it.reqAttr === 'str') ok = attrs.str >= it.reqVal;
  else if (it.reqAttr === 'intfai') ok = Math.max(attrs.int, attrs.fai) >= it.reqVal;
  const f = ok ? 1 : 0.5;
  return { def: Math.floor(it.def * f), res: Math.floor(it.res * f), ok };
}

function heroStats(h) {
  const attrs = totalAttrs(h);
  const eff = {}; ATTRS.forEach(k => (eff[k] = softCap(attrs[k])));
  let maxHp = Math.floor(10 + 2.5 * eff.vig) + affixSum(h, 'hp');
  let def = Math.floor(eff.vig / (h.cls === 'knight' ? 4 : 6)), res = Math.floor(eff.vig / 6);
  SLOTS.forEach(s => {
    const it = h.gear[s]; if (!it) return;
    const v = armorValue(it, attrs); def += v.def; res += v.res;
    if (it.hp) maxHp += it.hp;
  });
  if (legend(h, 'pinthelm')) maxHp += 5;
  def += affixSum(h, 'def'); res += affixSum(h, 'res');
  if (h.cls === 'knight' && hasPerk(h, 24)) def += 3;
  if (setCount(h, 'bouncer') >= 2) def += 6;
  def += h.defBuff || 0;
  let crit = CRIT_BASE + attrs.dex + 0.5 * attrs.arc + affixSum(h, 'crit') + (h.cls === 'rogue' ? 10 : 0);
  crit = Math.min(CRIT_CAP, Math.round(crit));
  const wa = weaponAR(h, h.gear.weapon, attrs);
  let heal = 1 + affixSum(h, 'heal') / 100;
  if (h.gear.offhand && h.gear.offhand.offType === 'seal') heal += SEAL_BONUS;
  if (setCount(h, 'choir') >= 2) heal += 0.20;
  let cd = HEROES[h.cls].skill.cd;
  if ((h.cls === 'knight' || h.cls === 'rogue' || h.cls === 'ranger') && hasPerk(h, 16)) cd -= 1;
  if (affixSum(h, 'quick') > 0) cd -= 1;
  if (setCount(h, 'spiller') >= 4) cd -= 1;
  cd = Math.max(1, cd);
  return {
    attrs, eff, maxHp, def, res, crit, ar: wa.ar, dmgType: wa.type, weapon: wa, heal, cd,
    leech: affixSum(h, 'leech'), thorns: affixSum(h, 'thorns'), bounty: affixSum(h, 'bounty'),
    mendAmount: Math.round((6 + 1.5 * eff.fai) * heal),
    blessing: Math.floor(attrs.fai / 5),
  };
}

function partyXpBonus() {
  let v = 0; G.heroes.forEach(h => (v += affixSum(h, 'xp')));
  return Math.min(XP_GAIN_CAP, v) / 100;
}
function partyLuck() {
  let v = 0, arc = 0;
  G.heroes.forEach(h => { v += affixSum(h, 'luck'); arc = Math.max(arc, totalAttrs(h).arc); });
  return (v + arc) / 100;
}

// ---------- Gear generation ----------
function rollRarity(stage) {
  const row = RARITY_WEIGHTS.find(r => stage <= r.upTo) || RARITY_WEIGHTS[RARITY_WEIGHTS.length - 1];
  return RNG.weighted(row.w);
}
function rollSlot() { return RNG.pick(SLOTS); }

function genAffixes(slot, rarityIdx, count) {
  const out = []; const sizeIdx = Math.min(2, Math.max(0, rarityIdx - 1));
  const pool = Object.keys(AFFIXES).filter(k => {
    const a = AFFIXES[k];
    if (a.epicOnly && rarityIdx < 3) return false;
    return a.slots === 'any' || a.slots.includes(slot);
  });
  for (let i = 0; i < count && pool.length; i++) {
    const k = RNG.pick(pool);
    const a = AFFIXES[k];
    const x = { type: k, value: a.size[sizeIdx] };
    if (k === 'attr') x.attr = RNG.pick(ATTRS);
    else if (k !== 'attr') pool.splice(pool.indexOf(k), 1);
    out.push(x);
  }
  return out;
}

function genItem(L, rarityIdx, slot, opts = {}) {
  slot = slot || rollSlot();
  const r = RARITIES[rarityIdx];
  const it = { id: uid(), slot, rarity: rarityIdx, L, upg: 0, affixes: [], locked: false };
  let lines = r.lines + ((slot === 'amulet' || slot === 'ring') ? 1 : 0);
  let leg = null;
  if (rarityIdx === 4) {
    const pool = LEGENDARIES.filter(x => x.slot === slot);
    leg = opts.legend ? LEGENDARIES.find(x => x.id === opts.legend) : (pool.length ? RNG.pick(pool) : RNG.pick(LEGENDARIES));
    slot = it.slot = leg.slot;
    it.legend = leg.id;
    lines = r.lines + ((slot === 'amulet' || slot === 'ring') ? 1 : 0);
  }
  const reqBump = Math.floor((L - 1) / 2);
  if (slot === 'weapon') {
    const fam = (leg && leg.family) || opts.family || RNG.pick(Object.keys(WEAPONS));
    const W = WEAPONS[fam];
    it.family = fam; it.type = W.type;
    it.grades = Object.assign({}, (leg && leg.grades) || W.grades);
    it.req = {}; Object.keys(W.req).forEach(k => (it.req[k] = W.req[k] + reqBump));
    it.base = Math.round((4 + 1.5 * L) * r.mult * 10) / 10;
    it.name = leg ? leg.name : `${r.prefix} ${RNG.pick(WEAPON_WORDS)} ${W.name}`;
  } else if (slot === 'offhand') {
    const ot = (leg && leg.family) || opts.offType || RNG.pick(Object.keys(OFFHANDS));
    it.offType = ot;
    if (ot === 'shield') {
      const v = ARMOR_WEIGHT.shield * (0.5 + 0.1 * L) * r.mult;
      it.def = Math.max(1, Math.round(v)); it.res = Math.max(0, Math.round(v * 0.5));
      it.reqAttr = 'str'; it.reqVal = 8 + reqBump;
    }
    it.name = leg ? leg.name : `${r.prefix} ${RNG.pick(WEAPON_WORDS)} ${OFFHANDS[ot].name}`;
  } else if (SET_SLOTS.includes(slot)) {
    let cls = (leg && leg.cls) || opts.cls || RNG.pick(Object.keys(ARMOR_CLASS));
    if (!leg && rarityIdx >= 2 && rarityIdx < 4 && G && G.stage >= SET_FROM_STAGE && RNG.chance(SET_CHANCE)) {
      it.set = RNG.pick(Object.keys(SETS)); cls = SETS[it.set].cls;
    }
    const C = ARMOR_CLASS[cls];
    it.cls = cls;
    const v = ARMOR_WEIGHT[slot] * (0.5 + 0.1 * L) * r.mult;
    it.def = Math.max(0, Math.round(v * C.def)); it.res = Math.max(0, Math.round(v * C.res));
    if (slot !== 'gloves' && slot !== 'boots') it.hp = 2 * ARMOR_WEIGHT[slot] * (rarityIdx + 1);
    if (C.req) { it.reqAttr = C.req; it.reqVal = 8 + reqBump; }
    it.name = leg ? leg.name : (it.set ? `${SETS[it.set].name.split(' ')[0]} ${C.words[slot]}` : `${r.prefix} ${C.name} ${C.words[slot]}`);
  } else {
    const nm = slot === 'amulet' ? ['Locket', 'Pendant', 'Token', 'Charm'] : ['Band', 'Signet', 'Loop', 'Coil'];
    it.name = leg ? leg.name : `${r.prefix} ${RNG.pick(WEAPON_WORDS)} ${RNG.pick(nm)}`;
  }
  it.name = it.name.trim();
  it.affixes = genAffixes(slot, rarityIdx, lines);
  return it;
}

function dropItem(source, rarityOverride) {
  const it = genItem(G.stage, rarityOverride != null ? rarityOverride : rollRarity(G.stage));
  G.pack.push(it); G.stats.gear++;
  return it;
}

function itemSummary(it) {
  const lines = [];
  if (it.slot === 'weapon') {
    const W = WEAPONS[it.family];
    lines.push(`${W.name}, ${it.type} damage, base ${it.base}${it.upg ? `, +${it.upg}` : ''}`);
    lines.push('Scaling: ' + Object.keys(it.grades).map(k => `${ATTR_NAMES[k].slice(0, 3)} ${it.grades[k]}`).join(', '));
    lines.push('Needs: ' + Object.keys(it.req).map(k => `${ATTR_NAMES[k].slice(0, 3)} ${it.req[k]}`).join(', '));
  }
  if (it.offType) lines.push(OFFHANDS[it.offType].text);
  if (it.def != null) lines.push(`${it.cls ? ARMOR_CLASS[it.cls].name + ' · ' : ''}Defense ${it.def}, Resist ${it.res}${it.hp ? `, +${it.hp} HP` : ''}`);
  if (it.reqAttr) lines.push(`Needs ${it.reqAttr === 'str' ? 'Str' : 'Int or Fai'} ${it.reqVal} (half value below)`);
  it.affixes.forEach(x => lines.push(AFFIXES[x.type].fmt(x.value, x.attr)));
  if (it.set) lines.push(`${SETS[it.set].name}: 2 pc ${SETS[it.set].two}; 4 pc ${SETS[it.set].four}`);
  if (it.legend) lines.push('★ ' + LEGENDARIES.find(l => l.id === it.legend).text);
  return lines;
}
