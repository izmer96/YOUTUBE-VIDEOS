/* Run flow: rounds, pockets, levelling, rewards, save and meta progress. */
'use strict';

const SAVE_KEY = 'peglord.save.v1', META_KEY = 'peglord.meta.v1', SETTINGS_KEY = 'peglord.settings.v1';
const store = {
  get(k) { try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : null; } catch (e) { return null; } },
  set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); return true; } catch (e) { return false; } },
  del(k) { try { localStorage.removeItem(k); } catch (e) { /* ignore */ } },
};

function loadSettings() {
  const prefersReduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  return Object.assign({ sfx: 0.7, music: 0.35, sfxOn: true, musicOn: true, reducedMotion: prefersReduced }, store.get(SETTINGS_KEY) || {});
}
function loadMeta() { return Object.assign({ wins: 0, runs: 0, unlocked: [], startJoker: false, bestPoints: 0 }, store.get(META_KEY) || {}); }

const Game = (() => {
  let settings = loadSettings();
  let meta = loadMeta();

  function blankState(seed) {
    return {
      seed, stage: 1, round: 1, phase: 'title', bank: 0, heroes: [], pack: [], jokers: [], pegExtras: {},
      foes: [], target: null, selHero: 0, pending: [], mods: {}, balls: 0, ballNo: 0, hotNext: false,
      speed: 1, skipAnim: false, settings, stageDrops: [], rewards: null, draftHidden: false, acting: null,
      stats: { points: 0, bestCombo: 0, dmg: 0, pegs: 0, gear: 0, kills: 0, stages: 0, rounds: 0 },
    };
  }

  function newRun(seed, party, startJoker) {
    seed = (seed || '').trim().toUpperCase() || randomSeedString();
    RNG.seed(seed);
    nextId = 1;
    G = blankState(seed);
    G.heroes = (party || DEFAULT_PARTY).map(makeHero);
    if (startJoker) { const commons = Object.keys(JOKERS).filter(k => JOKERS[k].rarity === 'common'); G.jokers.push(RNG.pick(commons)); }
    meta.runs++; store.set(META_KEY, meta);
    Battle.setupStage();
    startRound();
    UI.closeAll();
    UI.rebuild();
    UI.log(`Run ${seed} begins in ${STAGES[0].name}.`, '');
  }

  function startRound() {
    G.mods = { guard: 0, curse: 0, rust: 0, rally: 0, whet: 0, chalkUsed: false };
    G.balls = BASE_BALLS + (hasJoker('sparekey') ? 1 : 0) + (hasJoker('happyhour') && G.round === 1 ? 2 : 0);
    if (hasJoker('sparekey')) UI.pulseJoker('sparekey');
    if (hasJoker('happyhour') && G.round === 1) UI.pulseJoker('happyhour');
    G.ballNo = 0;
    G.stats.rounds++;
    if (hasJoker('secondwind')) { G.heroes.forEach(h => Battle.heal(h, 3)); UI.pulseJoker('secondwind'); }
    if (hasJoker('bartab')) { G.bank += 10; UI.pulseJoker('bartab'); }
    G.heroes.forEach(h => { if (!h.dead && h.cmd === 'skill' && !Battle.skillReady(h)) h.cmd = 'attack'; });
    Board.build();
    G.phase = 'aim';
    UI.refresh();
  }

  function applyPocket(type, ball) {
    const P = POCKETS[type];
    UI.log(`Pocket ${P.name}: ${P.text}.`, P.kind === 'perk' ? 'good' : 'bad');
    if (P.kind === 'bad') {
      if (hasJoker('debt')) { G.bank += 6; G.stats.points += 6; UI.pulseJoker('debt'); UI.log('Debt Collector pays 6.', 'good'); }
      if (hasJoker('chalk') && !G.mods.chalkUsed) {
        G.mods.chalkUsed = true; UI.pulseJoker('chalk'); Sound.play('ui');
        UI.log('Chalk Dust cancels it.', 'good'); UI.refresh(); return;
      }
      Sound.play('bad');
    } else {
      Sound.play('perk');
      if (hasJoker('tipjar')) { G.bank += 3; G.stats.points += 3; UI.pulseJoker('tipjar'); }
    }
    switch (type) {
      case 'jackpot': { let v = 6 + 2 * G.stage; if (hasJoker('fever')) { v *= 2; UI.pulseJoker('fever'); } G.bank += v; G.stats.points += v; break; }
      case 'double': G.bank += ball.pts; G.stats.points += ball.pts; break;
      case 'freeball': G.balls++; break;
      case 'patch': Battle.healWeakest(5, 'Patch Up'); break;
      case 'guard': G.mods.guard = 1; break;
      case 'treasure': { const it = dropItem('pocket'); UI.log(`Treasure: ${it.name}.`, 'loot'); break; }
      case 'rally': G.mods.rally += 2; break;
      case 'hotball': G.hotNext = true; break;
      case 'taxman': G.bank = Math.max(0, G.bank - 6); break;
      case 'leaky': G.bank = Math.max(0, G.bank - Math.floor(ball.pts / 2)); break;
      case 'curse': G.mods.curse = 1; break;
      case 'rust': G.mods.rust += 1; break;
      case 'plague': G.heroes.forEach(h => { if (!h.dead) h.hp = Math.max(1, h.hp - 2); }); break;
      case 'jam': G.balls = Math.max(0, G.balls - 1); break;
    }
    UI.refresh();
  }

  function afterBall() {
    if (G.balls > 0) { G.phase = 'aim'; }
    else {
      G.phase = 'alloc';
      G.pending = [];
      UI.log(`Bank ${G.bank} XP. Level up, set commands, then Fight.`, '');
    }
    UI.refresh();
  }

  // ---------- Levelling ----------
  const canManage = () => G && (G.phase === 'alloc' || G.phase === 'draft');
  function buyLevel(h, attr, n = 1) {
    if (!canManage()) return false;
    let bought = 0;
    for (let i = 0; i < n; i++) {
      if (G.bank < LEVEL_COST || h.level >= LEVEL_CAP) break;
      const before = heroStats(h).maxHp;
      G.bank -= LEVEL_COST; h.bought[attr]++; h.level++;
      G.pending.push({ hid: h.id, attr });
      const after = heroStats(h).maxHp;
      if (!h.dead) h.hp += Math.max(0, after - before);
      if (legend(h, 'rentboots') && !h.dead) h.hp = Math.min(after, h.hp + 5);
      bought++;
    }
    if (bought) Sound.play('levelup'); else Sound.play('deny');
    UI.refresh();
    return bought > 0;
  }
  function refundLevel(h, attr) {
    if (!canManage()) return;
    const i = G.pending.map(p => p.hid === h.id && p.attr === attr).lastIndexOf(true);
    if (i < 0) { Sound.play('deny'); return; }
    G.pending.splice(i, 1);
    G.bank += LEVEL_COST; h.bought[attr]--; h.level--;
    h.hp = Math.min(h.hp, heroStats(h).maxHp);
    Sound.play('ui'); UI.refresh();
  }
  function confirmLevels() { G.pending = []; UI.refresh(); }
  function autoLevel() {
    if (!canManage()) return;
    let n = 0;
    while (G.bank >= LEVEL_COST) {
      const cands = G.heroes.filter(h => h.level < LEVEL_CAP);
      if (!cands.length) break;
      const h = cands.reduce((a, b) => (b.level < a.level ? b : a));
      if (!buyLevel(h, HEROES[h.cls].auto(h), 1)) break;
      n++;
    }
    UI.log(n ? `Auto-level bought ${n} level${n > 1 ? 's' : ''}.` : 'Not enough XP for a level.', '');
    UI.refresh();
  }

  // ---------- Gear ----------
  function equip(h, it) {
    if (!canManage()) return;
    const idx = G.pack.indexOf(it); if (idx < 0) return;
    const before = heroStats(h).maxHp;
    G.pack.splice(idx, 1);
    if (h.gear[it.slot]) G.pack.push(h.gear[it.slot]);
    h.gear[it.slot] = it;
    const after = heroStats(h).maxHp;
    if (!h.dead) h.hp = clamp(h.hp + Math.max(0, after - before), 1, after);
    Sound.play('equip'); UI.refresh();
  }
  function unequip(h, slot) {
    if (!canManage() || !h.gear[slot]) return;
    G.pack.push(h.gear[slot]); h.gear[slot] = null;
    h.hp = Math.min(h.hp, heroStats(h).maxHp);
    Sound.play('equip'); UI.refresh();
  }
  function salvage(it) {
    if (!canManage() || it.locked) return;
    const idx = G.pack.indexOf(it); if (idx < 0) return;
    G.pack.splice(idx, 1);
    let xp = RARITIES[it.rarity].salvage;
    if (G.heroes.some(h => legend(h, 'pawnshark'))) xp *= 2;
    G.bank += xp;
    UI.log(`Salvaged ${it.name} for ${xp} XP.`, 'loot');
    Sound.play('crateBreak'); UI.refresh();
  }

  // ---------- Fight ----------
  function fight() {
    if (G.phase !== 'alloc') return;
    confirmLevels();
    Sound.play('ui');
    Battle.resolve();
  }
  function nextRound() { G.round++; startRound(); }

  function stageCleared() {
    G.stats.stages++;
    G.heroes.forEach(h => {
      const mx = heroStats(h).maxHp;
      if (h.dead) { h.dead = false; h.hp = Math.ceil(mx * STAGE_HEAL); }
      else h.hp = Math.min(mx, h.hp + Math.ceil(mx * STAGE_HEAL));
      h.used = { laststand: false, overcast: false, resurrect: false };
      h.cd = 0; h.hex = 0; h.shield = 0;
    });
    if (STAGES[G.stage - 1].boss) { victory(); return; }
    Sound.play('win');
    UI.log(`${STAGES[G.stage - 1].name} cleared! Party heals 30%.`, 'good');
    G.phase = 'draft';
    G.pending = [];
    G.rewards = makeRewards();
    G.draftHidden = false;
    UI.refresh();
    UI.showDraft();
  }

  function rollJoker() {
    const pool = Object.keys(JOKERS).filter(k => !G.jokers.includes(k));
    if (!pool.length) return null;
    return pool[RNG.weighted(pool.map(k => JOKER_RARITY_WEIGHT[JOKERS[k].rarity]))];
  }
  function makeRewards() {
    const free = G.jokers.length < MAX_JOKERS;
    const pool = [{ kind: 'gear' }, { kind: 'gear' }];
    if (free) { pool.push({ kind: 'joker' }, { kind: 'joker' }); }
    const packs = RNG.shuffle(Object.keys(PEG_PACKS).slice());
    pool.push({ kind: 'pack', id: packs[0] }, { kind: 'pack', id: packs[1] }, { kind: 'whetstone' }, { kind: 'bed' });
    if (RNG.chance(TANKARD_CHANCE)) pool.push({ kind: 'tankard' });
    const picks = [pool.shift()];
    if (free) { const j = pool.findIndex(p => p.kind === 'joker'); picks.push(pool.splice(j, 1)[0]); }
    RNG.shuffle(pool);
    while (picks.length < 3 && pool.length) picks.push(pool.shift());
    const used = new Set();
    return picks.map(p => {
      if (p.kind === 'gear') p.item = genItem(G.stage, rollRarity(G.stage));
      if (p.kind === 'joker') { let j; do { j = rollJoker(); } while (j && used.has(j) && G.jokers.length + used.size < Object.keys(JOKERS).length); used.add(j); p.id = j; if (!j) p.kind = 'bed'; }
      return p;
    });
  }

  function pickReward(i, heroIdx) {
    if (G.phase !== 'draft' || !G.rewards) return;
    const r = G.rewards[i];
    const h = G.heroes[heroIdx != null ? heroIdx : G.selHero];
    switch (r.kind) {
      case 'gear': G.pack.push(r.item); G.stats.gear++; UI.log(`Took ${r.item.name}.`, 'loot'); break;
      case 'joker': G.jokers.push(r.id); Sound.play('joker'); UI.log(`Joker gained: ${JOKERS[r.id].name}.`, 'good'); UI.newJoker = r.id; break;
      case 'pack': Object.keys(PEG_PACKS[r.id].add).forEach(k => (G.pegExtras[k] = (G.pegExtras[k] || 0) + PEG_PACKS[r.id].add[k])); UI.log(`Peg pack: ${PEG_PACKS[r.id].name}.`, 'good'); break;
      case 'whetstone': {
        const w = h.gear.weapon;
        if (!w || w.upg >= 10) { Sound.play('deny'); return; }
        w.upg++; UI.log(`${w.name} is now +${w.upg}.`, 'good'); Sound.play('equip'); break;
      }
      case 'tankard': {
        let n = 0; ATTRS.forEach(a => { n += h.bought[a]; h.bought[a] = 0; });
        h.level = 1; G.bank += n * LEVEL_COST; h.hp = Math.min(h.hp, heroStats(h).maxHp);
        UI.log(`Golden Tankard: ${h.name} respecs, ${n * LEVEL_COST} XP returned.`, 'good'); break;
      }
      case 'bed': G.heroes.forEach(x => { if (!x.dead) Battle.heal(x, Math.ceil(heroStats(x).maxHp * WARM_BED_HEAL)); }); UI.log('Warm Bed: party heals 40%.', 'good'); break;
    }
    if (r.kind !== 'joker') Sound.play('perk');
    G.rewards = null;
    G.stage++; G.round = 1; G.pending = [];
    save();
    Battle.setupStage();
    UI.log(`Stage ${G.stage}: ${STAGES[G.stage - 1].name}.`, '');
    UI.closeAll();
    startRound();
    UI.rebuild();
  }

  function defeat() {
    G.phase = 'over';
    store.del(SAVE_KEY);
    meta.bestPoints = Math.max(meta.bestPoints, G.stats.points); store.set(META_KEY, meta);
    Sound.play('lose');
    UI.showEnd(false);
  }
  function victory() {
    G.phase = 'over';
    store.del(SAVE_KEY);
    meta.wins++;
    const newly = [];
    ['rogue', 'ranger'].forEach(k => { if (!meta.unlocked.includes(k)) { meta.unlocked.push(k); newly.push(HEROES[k].name); } });
    if (!meta.startJoker) { meta.startJoker = true; newly.push('a starting joker'); }
    meta.bestPoints = Math.max(meta.bestPoints, G.stats.points);
    store.set(META_KEY, meta);
    const legs = RNG.shuffle(LEGENDARIES.slice()).slice(0, 3).map(l => genItem(G.stage, 4, l.slot, { legend: l.id }));
    Sound.play('win');
    UI.showEnd(true, legs, newly);
  }

  // ---------- Save and resume ----------
  function save() {
    const data = {
      v: 1, seed: G.seed, rng: RNG.s, nextId, stage: G.stage, round: G.round, bank: G.bank,
      heroes: G.heroes, pack: G.pack, jokers: G.jokers, pegExtras: G.pegExtras, stats: G.stats, speed: G.speed, skipAnim: G.skipAnim,
    };
    store.set(SAVE_KEY, data);
  }
  function hasSave() { return !!store.get(SAVE_KEY); }
  function resume() {
    const d = store.get(SAVE_KEY); if (!d) return false;
    try {
      G = blankState(d.seed);
      Object.assign(G, { stage: d.stage, round: d.round, bank: d.bank, heroes: d.heroes, pack: d.pack, jokers: d.jokers, pegExtras: d.pegExtras, stats: d.stats, speed: d.speed || 1, skipAnim: !!d.skipAnim });
      RNG.s = d.rng; nextId = d.nextId;
      Battle.setupStage();
      startRound();
      UI.closeAll(); UI.rebuild();
      UI.log(`Resumed run ${G.seed} at ${STAGES[G.stage - 1].name}.`, '');
      return true;
    } catch (e) { store.del(SAVE_KEY); return false; }
  }

  function setSettings(p) {
    Object.assign(settings, p);
    store.set(SETTINGS_KEY, settings);
    Sound.set({ sfx: settings.sfx, music: settings.music, sfxOn: settings.sfxOn, musicOn: settings.musicOn });
    document.documentElement.classList.toggle('reduced', !!settings.reducedMotion);
    if (G) G.settings = settings;
  }

  function boot() {
    G = blankState('');
    setSettings({});
  }

  return { newRun, startRound, applyPocket, afterBall, buyLevel, refundLevel, confirmLevels, autoLevel, equip, unequip, salvage,
    fight, nextRound, stageCleared, defeat, pickReward, hasSave, resume, setSettings, boot,
    get settings() { return settings; }, get meta() { return meta; }, canManage };
})();
