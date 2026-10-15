/* Turn-based combat: foes, intents, hero commands and damage rules. */
'use strict';

const Battle = (() => {
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const wait = () => sleep(G.skipAnim ? 90 : (ANIM_STEP * 1000) / (G.speed > 1 ? 1.6 : 1));
  const living = arr => arr.filter(u => !u.dead);

  // ---------- Foes ----------
  function makeFoe(type, stage, name) {
    const E = ENEMIES[type];
    return {
      id: uid(), type, name: name || E.name, icon: E.icon,
      maxHp: Math.round(E.hp * (1 + ENEMY_HP_SCALE * (stage - 1))),
      atk: Math.round(E.atk * (1 + ENEMY_ATK_SCALE * (stage - 1))),
      armor: E.armor, moves: E.moves.slice(), moveIdx: RNG.int(E.moves.length), dead: false,
      burn: 0, burnTurns: 0, mark: false, pin: 0, minion: false,
    };
  }

  function setupStage() {
    const S = STAGES[G.stage - 1];
    let foes;
    if (S.boss) {
      const boss = { id: uid(), type: 'boss', name: BOSS.name, icon: BOSS.icon, maxHp: BOSS.hp, atk: BOSS.atk, armor: BOSS.armor,
        moves: BOSS.moves.slice(), moveIdx: 0, dead: false, burn: 0, burnTurns: 0, mark: false, pin: 0, boss: true, phase2: false };
      foes = BOSS.minions.map(m => { const f = makeFoe(m.type, m.stage, m.name); f.minion = true; return f; });
      foes.splice(1, 0, boss);
    } else {
      const theme = RNG.pick(S.themes);
      let types;
      if (theme.length > 3) {
        do { types = [RNG.pick(theme), RNG.pick(theme), RNG.pick(theme)]; } while (types.every(t => t === 'shaman'));
      } else types = RNG.shuffle(theme.slice());
      foes = types.map(t => makeFoe(t, G.stage));
      const seen = {};
      foes.forEach(f => { seen[f.name] = (seen[f.name] || 0) + 1; });
      const count = {};
      foes.forEach(f => { if (seen[f.name] > 1) { count[f.name] = (count[f.name] || 0) + 1; if (count[f.name] > 1) f.name += ' ' + 'ABC'[count[f.name] - 1]; } });
    }
    foes.forEach(f => (f.hp = f.maxHp));
    G.foes = foes;
    G.target = foes.find(f => !f.dead).id;
  }

  function foeAttack(f) {
    let a = f.atk + RENT_HIKE_PER_ROUND * (G.round - 1);
    if (G.mods.curse) a += CURSE_ATK;
    if (hasJoker('glasscannon')) a *= GLASS_CANNON_FOE;
    a -= f.pin;
    if (G.mods.guard) a -= GUARD_POCKET;
    return Math.max(1, Math.round(a));
  }
  function intentOf(f) { return MOVES[f.moves[f.moveIdx % f.moves.length]]; }
  function intentValue(f) {
    const m = intentOf(f), atk = foeAttack(f);
    if (m === MOVES.mend) return Math.round(1.5 * atk + 3);
    return Math.max(1, Math.round(atk * m.mult));
  }
  function intentLabel(f) {
    const m = intentOf(f), v = intentValue(f);
    const tgt = { one: '', lowest: ' (weakest)', all: ' (all)', ally: ' (heal)' }[m.target];
    return `${m.name} ${v}${m.hits ? '×' + m.hits : ''}${tgt}`;
  }

  // ---------- Heroes ----------
  function priestBlessing() {
    const p = G.heroes.find(h => h.cls === 'priest' && !h.dead);
    return p ? heroStats(p).blessing : 0;
  }
  function weakestHero(includeDead) {
    const c = G.heroes.filter(h => includeDead || !h.dead);
    if (!c.length) return null;
    return c.reduce((a, b) => (a.hp / heroStats(a).maxHp <= b.hp / heroStats(b).maxHp ? a : b));
  }
  function heal(h, amt, src) {
    if (!h || h.dead) return 0;
    const st = heroStats(h);
    const before = h.hp;
    h.hp = Math.min(st.maxHp, h.hp + amt);
    let over = amt - (h.hp - before);
    const pr = G.heroes.find(x => x.cls === 'priest' && !x.dead && hasPerk(x, 24));
    if (over > 0 && pr && src === 'mend') { h.shield = Math.max(h.shield, over); }
    const got = h.hp - before;
    if (got > 0) UI.unitFx('hero', h.id, '+' + got, 'heal');
    return got;
  }
  function healWeakest(amt, src) {
    const h = weakestHero(false); if (!h) return;
    const got = heal(h, amt, src);
    UI.log(got ? `${src}: ${h.name} heals ${got}.` : `${src}: everyone is already at full HP.`, 'good');
    UI.refresh();
  }
  function heroIsTaunting(h) { return !h.dead && (h.guarding || (h.cls === 'knight' && hasPerk(h, 24))); }

  function currentTarget() {
    let t = G.foes.find(f => f.id === G.target && !f.dead);
    if (!t) { t = living(G.foes)[0]; if (t) G.target = t.id; }
    return t;
  }

  // Hit a foe with mult × AR. Returns damage dealt.
  function hitFoe(h, foe, mult, opts = {}) {
    if (!foe || foe.dead) return 0;
    const st = heroStats(h);
    const type = opts.type || st.dmgType;
    let ar = st.ar * mult;
    if (type === 'magic' && opts.type === 'magic' && st.dmgType !== 'magic' && h.cls === 'mage') ar *= 1.15;
    const crit = RNG.chance(st.crit / 100);
    const k = crit ? (legend(h, 'nightcap') ? 2.5 : 2) : 1;
    let raw = Math.floor((ar + priestBlessing()) * k) + G.mods.rally + G.mods.whet - G.mods.rust;
    if (st.bounty) { const top = living(G.foes).reduce((a, b) => (a.hp >= b.hp ? a : b)); if (top === foe) raw = Math.floor(raw * (1 + st.bounty / 100)); }
    if (h.cls === 'ranger' && hasPerk(h, 24)) { const top = living(G.foes).reduce((a, b) => (a.hp >= b.hp ? a : b)); if (top === foe) raw = Math.floor(raw * 1.25); }
    if (h.cls === 'rogue' && hasPerk(h, 36) && foe.hp < foe.maxHp * 0.3) raw *= 2;
    if (foe.mark) raw = Math.floor(raw * 1.2);
    let armor = type === 'phys' ? foe.armor : Math.floor(foe.armor / 2);
    if (h.cls === 'ranger') armor = Math.max(0, armor - 2);
    const dmg = Math.max(1, raw - armor);
    foe.hp = Math.max(0, foe.hp - dmg);
    G.stats.dmg += dmg;
    UI.unitFx('foe', foe.id, (crit ? 'CRIT ' : '') + dmg, crit ? 'crit' : 'dmg');
    Sound.play(crit ? 'crit' : (type === 'magic' ? 'zap' : 'slash'));
    if (crit && h.cls === 'mage' && opts.firebolt && hasPerk(h, 16)) { foe.burn = 3; foe.burnTurns = 3; UI.log(`${foe.name} is burning.`, ''); }
    if (crit && h.cls === 'rogue' && hasPerk(h, 8)) { foe.burn = 3; foe.burnTurns = 3; UI.log(`${foe.name} is bleeding.`, ''); }
    if (st.leech) heal(h, st.leech);
    if (legend(h, 'tapmaster')) { const w = weakestHero(false); if (w) heal(w, Math.max(1, Math.floor(dmg * 0.1))); }
    afterFoeDamage(foe, h);
    if (legend(h, 'gavel') && !opts.splash) {
      living(G.foes).forEach(o => { if (o !== foe) { o.hp = Math.max(0, o.hp - 3); G.stats.dmg += 3; UI.unitFx('foe', o.id, '3', 'dmg'); afterFoeDamage(o, h); } });
    }
    return dmg;
  }

  function afterFoeDamage(foe, h) {
    if (foe.boss && !foe.phase2 && foe.hp > 0 && foe.hp <= foe.maxHp / 2) {
      foe.phase2 = true; foe.moves = BOSS.phase2Moves.slice(); foe.moveIdx = 0;
      foe.armor += BOSS.phase2Armor; foe.atk += BOSS.phase2Atk;
      UI.log('The Landlord tears up the lease! Phase two: Foreclosure.', 'bad');
      Sound.play('bad');
    }
    if (foe.hp <= 0 && !foe.dead) {
      foe.dead = true; Sound.play('kill');
      UI.log(`${foe.name} is down.`, 'good');
      G.stats.kills++;
      if (!foe.boss) {
        const ch = (foe.minion ? MINION_DROP : DROP_CHANCE) + partyLuck();
        if (RNG.chance(ch)) { const it = dropItem('foe'); G.stageDrops.push(it); UI.log(`${foe.name} dropped ${it.name}.`, 'loot'); }
      }
      if (h && legend(h, 'lastcall') && G.acting === 'firebolt') { h.cd = 0; UI.log('Last Call: Firebolt is ready again.', 'good'); }
    }
    UI.refresh();
  }

  async function heroAct(h) {
    const st = heroStats(h);
    const cmd = h.cmd;
    UI.unitAnim('hero', h.id, 'lunge');
    if (cmd === 'guard') {
      h.guarding = true;
      Sound.play('clank');
      heal(h, 2 + (setCount(h, 'bouncer') >= 4 ? 4 : 0));
      UI.log(`${h.name} guards.`, '');
      return;
    }
    if (cmd === 'skill' && skillReady(h)) {
      if (h.cd > 0 && h.cls === 'mage') h.used.overcast = true;
      h.cd = st.cd;
      G.acting = 'skill';
      const tgt = currentTarget();
      switch (h.cls) {
        case 'knight':
          Sound.play('slash');
          living(G.foes).forEach(f => hitFoe(h, f, 0.7));
          UI.log(`${h.name} cleaves every foe.`, '');
          break;
        case 'mage': {
          G.acting = 'firebolt';
          Sound.play('fire');
          const d = hitFoe(h, tgt, 2.2, { type: 'magic', firebolt: true });
          if (hasPerk(h, 36)) living(G.foes).forEach(f => { if (f !== tgt) hitFoe(h, f, 1.1, { type: 'magic', splash: true }); });
          UI.log(`${h.name} casts Firebolt for ${d}.`, '');
          break;
        }
        case 'priest': {
          const dead = G.heroes.find(x => x.dead);
          if (dead && hasPerk(h, 36) && !h.used.resurrect) {
            h.used.resurrect = true; dead.dead = false; dead.hp = Math.ceil(heroStats(dead).maxHp * 0.4);
            Sound.play('heal'); UI.log(`${h.name} resurrects ${dead.name}!`, 'good');
            break;
          }
          const w = weakestHero(false);
          if (hasPerk(h, 8) && w) w.hex = 0;
          const got = heal(w, st.mendAmount, 'mend');
          if (setCount(h, 'choir') >= 4 && w) w.defBuff = 3;
          Sound.play('heal');
          UI.log(`${h.name} mends ${w.name} for ${got}.`, 'good');
          break;
        }
        case 'rogue':
          hitFoe(h, tgt, 1.1); if (!tgt.dead) hitFoe(h, tgt, 1.1);
          UI.log(`${h.name} twin-stabs ${tgt.name}.`, '');
          break;
        case 'ranger': {
          const n = hasPerk(h, 36) ? 2 : 1;
          for (let i = 0; i < n; i++) living(G.foes).forEach(f => hitFoe(h, f, 0.6));
          UI.log(`${h.name} looses a volley.`, '');
          break;
        }
      }
      G.acting = null;
      return;
    }
    // Attack.
    G.acting = 'attack';
    const tgt = currentTarget(); if (!tgt) return;
    const d = hitFoe(h, tgt, 1);
    UI.log(`${h.name} hits ${tgt.name} for ${d}.`, '');
    if (h.cls === 'mage' && hasPerk(h, 8)) { const o = living(G.foes).find(f => f !== tgt); if (o) hitFoe(h, o, 0.4, { splash: true }); }
    if (h.cls === 'priest' && hasPerk(h, 16) && !tgt.dead) tgt.mark = true;
    if (h.cls === 'ranger' && hasPerk(h, 8) && !tgt.dead) tgt.pin = 1;
    G.acting = null;
  }

  function skillReady(h) {
    if (h.cd <= 0) return true;
    return h.cls === 'mage' && hasPerk(h, 24) && !h.used.overcast;
  }

  function damageHero(h, atk, magic, foe) {
    if (h.dead) return 0;
    const st = heroStats(h);
    if (h.cls === 'rogue' && hasPerk(h, 24) && h.guarding && !h.dodged) { h.dodged = true; UI.unitFx('hero', h.id, 'Dodge', 'block'); return 0; }
    const D = magic ? st.res : st.def;
    let kg = h.guarding ? 0.5 : 1;
    if (h.guarding && h.gear.offhand && h.gear.offhand.offType === 'shield') kg *= 1 - SHIELD_BLOCK;
    let dmg = Math.max(1, Math.floor(atk * 40 / (40 + D) * kg));
    const unguarded = Math.max(1, Math.floor(atk * 40 / (40 + D)));
    if (h.shield > 0) { const a = Math.min(h.shield, dmg); h.shield -= a; dmg -= a; if (a) UI.unitFx('hero', h.id, 'Shield ' + a, 'block'); }
    h.hp -= dmg;
    if (h.hp <= 0 && h.cls === 'knight' && hasPerk(h, 36) && !h.used.laststand) { h.used.laststand = true; h.hp = 1; UI.log(`${h.name}: Last Stand!`, 'good'); }
    UI.unitFx('hero', h.id, String(dmg), h.guarding ? 'block' : 'dmg');
    UI.unitAnim('hero', h.id, 'hit');
    Sound.play(h.guarding ? 'clank' : 'hurt');
    if (foe && !foe.dead) {
      let back = st.thorns;
      if (h.guarding && ((h.cls === 'knight' && hasPerk(h, 8)) || setCount(h, 'bouncer') >= 4)) back += Math.floor(st.ar * 0.5);
      if (h.guarding && legend(h, 'bastion')) back += unguarded - dmg;
      if (back > 0) { foe.hp = Math.max(0, foe.hp - back); G.stats.dmg += back; UI.unitFx('foe', foe.id, String(back), 'dmg'); afterFoeDamage(foe, h); }
    }
    if (h.hp <= 0) { h.hp = 0; h.dead = true; h.guarding = false; UI.log(`${h.name} falls!`, 'bad'); Sound.play('lose'); }
    return dmg;
  }

  async function foeAct(f) {
    const m = intentOf(f);
    const atk = foeAttack(f);
    UI.unitAnim('foe', f.id, 'lunge');
    if (m === MOVES.mend) {
      const w = living(G.foes).reduce((a, b) => (a.hp / a.maxHp <= b.hp / b.maxHp ? a : b));
      const amt = Math.round(1.5 * atk + 3);
      w.hp = Math.min(w.maxHp, w.hp + amt);
      UI.unitFx('foe', w.id, '+' + amt, 'heal'); Sound.play('heal');
      UI.log(`${f.name} mends ${w.name} for ${amt}.`, 'bad');
    } else {
      if (m.rentHike) { f.atk += 2; UI.log('Rent Hike: The Landlord gains +2 attack.', 'bad'); }
      const alive = living(G.heroes);
      if (!alive.length) return;
      let targets;
      if (m.target === 'all') targets = alive;
      else if (m.target === 'lowest') targets = [alive.reduce((a, b) => (a.hp <= b.hp ? a : b))];
      else { const t = alive.filter(heroIsTaunting); targets = [RNG.pick(t.length ? t : alive)]; }
      const hits = m.hits || 1;
      for (let i = 0; i < hits; i++) {
        targets.forEach(h => {
          if (h.dead) return;
          if (m.miss && RNG.chance(m.miss)) { UI.unitFx('hero', h.id, 'Miss', 'block'); UI.log(`${f.name} swings wildly and misses.`, ''); return; }
          const d = damageHero(h, Math.max(1, Math.round(atk * m.mult)), m.magic, f);
          if (m.drain && !f.dead) { f.hp = Math.min(f.maxHp, f.hp + d); UI.unitFx('foe', f.id, '+' + d, 'heal'); }
          if (m.hex && !h.dead) h.hex = 2;
          UI.log(`${f.name} ${m.name.toLowerCase()}s ${h.name} for ${d}.`, 'bad');
        });
      }
    }
    f.moveIdx++;
    UI.refresh();
  }

  async function resolve() {
    G.phase = 'resolve';
    UI.refresh();
    G.heroes.forEach(h => { h.guarding = false; h.dodged = false; if (!h.dead && h.cmd === 'guard') h.guarding = true; });
    for (const h of G.heroes) {
      if (h.dead || !living(G.foes).length) continue;
      if (h.cmd === 'skill' && !skillReady(h)) h.cmd = 'attack';
      await heroAct(h);
      UI.refresh();
      await wait();
    }
    if (living(G.foes).length) {
      for (const f of G.foes) {
        if (f.dead || !living(G.heroes).length) continue;
        await foeAct(f);
        await wait();
      }
    }
    // End of turn.
    G.foes.forEach(f => {
      if (!f.dead && f.burnTurns > 0) { f.hp = Math.max(0, f.hp - f.burn); f.burnTurns--; UI.unitFx('foe', f.id, String(f.burn), 'dmg'); G.stats.dmg += f.burn; afterFoeDamage(f, null); }
      f.mark = false; f.pin = 0;
    });
    G.heroes.forEach(h => {
      if (!h.dead && h.hex > 0) { h.hp = Math.max(1, h.hp - 2); h.hex--; UI.unitFx('hero', h.id, '2', 'dmg'); }
      h.cd = Math.max(0, h.cd - 1); h.guarding = false; h.defBuff = 0;
      if (h.cmd === 'skill') h.cmd = 'attack';
    });
    UI.refresh();
    await sleep(G.skipAnim ? 50 : 300);
    if (!living(G.foes).length) Game.stageCleared();
    else if (!living(G.heroes).length) Game.defeat();
    else Game.nextRound();
  }

  return { setupStage, resolve, intentLabel, intentOf, intentValue, foeAttack, healWeakest, heal, skillReady, weakestHero, currentTarget, living, MOVES };
})();
