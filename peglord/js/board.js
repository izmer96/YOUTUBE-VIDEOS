/* The pin board: layout, physics, scoring, hidden pockets and drawing. */
'use strict';

const Board = (() => {
  const P = PHYS;
  let cv, cx, felt, dpr = 1;
  const B = {
    pegs: [], ball: null, parts: [], floats: [], rings: [], arcs: [], trail: [],
    pockets: null, glint: -1, reveal: null, shake: 0, aim: Math.PI / 2, t: 0, bigText: null,
    hoverPeg: null,
  };
  const SLOT_W = P.W / P.pocketCount;
  const reduced = () => G && G.settings.reducedMotion;

  // ---------- Layout ----------
  function build() {
    B.pegs = []; B.parts = []; B.floats = []; B.rings = []; B.arcs = []; B.ball = null; B.reveal = null;
    const spots = [];
    for (let r = 0; r < P.rows; r++) {
      const odd = r % 2 === 1, n = odd ? P.cols - 1 : P.cols;
      const x0 = (P.W - (P.cols - 1) * P.dx) / 2 + (odd ? P.dx / 2 : 0);
      for (let c = 0; c < n; c++) {
        spots.push({ x: x0 + c * P.dx + RNG.range(-P.jitterX, P.jitterX), y: P.top + r * P.dy + RNG.range(-P.jitterY, P.jitterY) });
      }
    }
    RNG.shuffle(spots);
    const extra = Object.values(G.pegExtras).reduce((a, b) => a + b, 0);
    const keep = Math.min(P.keepMax, P.keep + P.keepPerExtra * extra);
    const kept = spots.slice(0, Math.round(spots.length * keep));
    const mix = [];
    Object.keys(BASE_PEG_MIX).forEach(k => { for (let i = 0; i < BASE_PEG_MIX[k]; i++) mix.push(k); });
    for (let i = 0; i < RANDOM_SPECIAL_COUNT; i++) mix.push(RNG.pick(RANDOM_SPECIALS));
    Object.keys(G.pegExtras).forEach(k => { for (let i = 0; i < G.pegExtras[k]; i++) mix.push(k); });
    // Portals must come in pairs.
    const portals = mix.filter(t => t === 'portal').length;
    if (portals % 2) mix.splice(mix.indexOf('portal'), 1);
    let lastPortal = null;
    kept.forEach((s, i) => {
      const type = i < mix.length ? mix[i] : 'brass';
      const p = { id: uid(), type, x: s.x, y: s.y, bx: s.x, r: P.pegR, lit: false, hits: 0, dead: false, phase: RNG.range(0, 6.28), cool: 0, glow: 0 };
      if (type === 'rover') p.bx = clamp(s.x, P.roverAmp + 16, P.W - P.roverAmp - 16);
      if (type === 'bumper') p.r = 10;
      if (type === 'portal') { if (lastPortal) { p.twin = lastPortal; lastPortal.twin = p; lastPortal = null; } else lastPortal = p; }
      B.pegs.push(p);
    });
    // Five static posts on the pocket dividers.
    for (let i = 1; i < P.pocketCount; i++) B.pegs.push({ id: uid(), type: 'post', x: i * SLOT_W, y: P.pocketTop, bx: i * SLOT_W, r: 5, lit: true, dead: false });
  }

  // ---------- Pockets ----------
  function rollPockets(isLastBall) {
    const split = POCKET_SPLIT.find(s => G.stage <= s.upTo);
    const perks = Object.keys(POCKETS).filter(k => POCKETS[k].kind === 'perk');
    const bads = Object.keys(POCKETS).filter(k => POCKETS[k].kind === 'bad' && !(isLastBall && k === 'jam'));
    const roll = RNG.shuffle(perks.slice()).slice(0, split.perks).concat(RNG.shuffle(bads.slice()).slice(0, P.pocketCount - split.perks));
    RNG.shuffle(roll);
    B.pockets = roll;
    B.glint = -1;
    if (hasJoker('peephole')) {
      const idx = roll.map((k, i) => POCKETS[k].kind === 'perk' ? i : -1).filter(i => i >= 0);
      B.glint = RNG.pick(idx); UI.pulseJoker('peephole');
    }
  }
  function splitText() {
    const split = POCKET_SPLIT.find(s => G.stage <= s.upTo);
    return `${split.perks} good, ${P.pocketCount - split.perks} bad`;
  }

  // ---------- Launch ----------
  function fire() {
    if (G.phase !== 'aim' || G.balls <= 0) return;
    Sound.init();
    const isLast = G.balls === 1;
    rollPockets(isLast);
    G.balls--; G.ballNo++;
    const b = {
      x: P.launcherX, y: P.launcherY, vx: Math.cos(B.aim) * P.launchSpeed, vy: Math.sin(B.aim) * P.launchSpeed,
      life: 0, slow: 0, combo: 0, pts: 0, hits: 0, firstHit: true, ghost: false, isLast,
      first: G.ballNo === 1,
    };
    if (G.hotNext) { b.combo = 8; G.hotNext = false; }
    if (isLast && G.heroes.some(h => legend(h, 'lastorder'))) b.combo = Math.max(b.combo, 8);
    B.ball = b; B.trail = [];
    B.pegs.forEach(p => { if (REARM[p.type]) p.lit = false; });
    G.phase = 'ball';
    Sound.play('launch');
    UI.hud();
  }

  // ---------- Scoring ----------
  function multFor(combo) { return 1 + Math.floor(combo / (hasJoker('comboking') ? 6 : 8)); }

  function score(p, base) {
    const b = B.ball; if (!b) return;
    const before = multFor(b.combo);
    b.combo++; b.hits++;
    const mult = multFor(b.combo);
    let pts = base * PAYOUT(G.stage) * mult;
    if (b.firstHit && hasJoker('penny')) { pts *= 3; UI.pulseJoker('penny'); }
    b.firstHit = false;
    if (hasJoker('echo') && b.hits % 4 === 0) { pts *= 2; UI.pulseJoker('echo'); }
    if (hasJoker('luckyseven') && b.hits % 7 === 0) { pts += 7; UI.pulseJoker('luckyseven'); }
    if (b.first && G.heroes.some(h => legend(h, 'horseshoe'))) pts *= 2;
    if (b.isLast && hasJoker('lastorders')) { pts *= 2; UI.pulseJoker('lastorders'); }
    pts = Math.round(pts * (1 + partyXpBonus()));
    b.pts += pts; G.bank += pts; G.stats.points += pts;
    G.stats.bestCombo = Math.max(G.stats.bestCombo, b.combo);
    B.floats.push({ x: p.x, y: p.y - 10, text: '+' + pts, t: 0, color: '#fff3c4', size: 13 });
    if (mult > before) {
      B.bigText = { text: `×${mult}!`, t: 0 };
      Sound.play('multi', mult);
    }
    UI.hud();
  }

  function pegValue(p) {
    let v = PEGS[p.type].pts;
    if (p.type === 'gold') {
      if (hasJoker('goldtooth')) { v += 2; UI.pulseJoker('goldtooth'); }
      G.heroes.forEach(h => { if (legend(h, 'pinthelm')) v += 1; });
    }
    if (p.type === 'brass' && hasJoker('pintglass')) { v += 1; UI.pulseJoker('pintglass'); }
    if (p.type === 'bomb' && hasJoker('bombsquad')) { v += 4; UI.pulseJoker('bombsquad'); }
    return v;
  }

  function burst(x, y, color, n) {
    if (reduced()) n = Math.min(n, 4);
    for (let i = 0; i < n; i++) {
      const a = Math.random() * 6.28, s = 40 + Math.random() * 160;
      B.parts.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 40, t: 0, life: 0.4 + Math.random() * 0.4, color });
    }
  }

  function hitPeg(p, direct) {
    if (p.dead || p.type === 'post') return;
    const def = PEGS[p.type];
    const b = B.ball;
    p.glow = 1;
    if (p.type === 'crate' || p.type === 'chest') {
      p.hits++; p.lit = true;
      score(p, pegValue(p));
      const need = p.type === 'crate' ? (hasJoker('crowbar') ? 2 : def.hits) : def.hits;
      if (p.type === 'crate' && hasJoker('crowbar') && p.hits === need) UI.pulseJoker('crowbar');
      if (p.hits >= need) {
        p.dead = true; G.stats.pegs++;
        Sound.play('crateBreak'); burst(p.x, p.y, def.color, 14); B.shake = Math.max(B.shake, 3);
        if (p.type === 'crate') crateLoot(p); else { const it = dropItem('chest'); UI.log(`Chest broke: ${it.name}.`, 'loot'); floatText(p, it.name, RARITIES[it.rarity].color); }
      } else Sound.play('crate');
      return;
    }
    if (p.lit) { if (direct) Sound.play('peg', b ? b.combo : 0); return; }
    p.lit = true;
    score(p, pegValue(p));
    if (!REARM[p.type]) G.stats.pegs++;
    switch (p.type) {
      case 'gold': Sound.play('gold', b ? b.combo : 0); break;
      case 'glass': p.dead = true; Sound.play('glass'); burst(p.x, p.y, def.color, 10); break;
      case 'bomb': explode(p); break;
      case 'heart': Sound.play('heart'); Battle.healWeakest(3, 'Heart peg'); break;
      case 'star': if (b) b.combo += 3; Sound.play('star'); burst(p.x, p.y, def.color, 8); break;
      case 'bolt': bolt(p); break;
      case 'bumper': Sound.play('bumper'); break;
      case 'portal': Sound.play('portal'); break;
      default: Sound.play('peg', b ? b.combo : 0);
    }
  }

  function floatText(p, text, color) { B.floats.push({ x: p.x, y: p.y - 24, text, t: -0.2, color, size: 12 }); }

  function crateLoot(p) {
    const loot = RNG.pick(CRATE_LOOT);
    switch (loot) {
      case 'bomb': floatText(p, 'Bomb!', '#ff8a65'); explode(p, true); break;
      case 'ball': G.balls++; floatText(p, '+1 ball', '#ffffff'); UI.log('Crate: free ball.', 'good'); break;
      case 'potion': floatText(p, 'Potion', '#4dd0c1'); Battle.healWeakest(6, 'Potion'); break;
      case 'whetstone': G.mods.whet += 2; floatText(p, 'Whetstone +2', '#cfd8dc'); UI.log('Crate: whetstone, +2 damage this round.', 'good'); break;
      case 'coins': G.bank += 6; G.stats.points += 6; floatText(p, '+6 coins', '#ffd23f'); break;
    }
    UI.hud();
  }

  function explode(p, fromCrate) {
    p.dead = true;
    const rad = hasJoker('bombsquad') ? P.bombSquadRadius : P.bombRadius;
    Sound.play('bomb'); burst(p.x, p.y, '#ff9a3c', 22);
    B.rings.push({ x: p.x, y: p.y, r: 4, max: rad, t: 0 });
    if (!reduced()) B.shake = Math.max(B.shake, 9);
    const b = B.ball;
    if (b) {
      const dx = b.x - p.x, dy = b.y - p.y, d = Math.hypot(dx, dy);
      if (d < rad * 1.2 && d > 0.1) { b.vx += (dx / d) * 260; b.vy += (dy / d) * 260 - 60; }
    }
    B.pegs.forEach(q => {
      if (q === p || q.dead || q.type === 'post') return;
      if (Math.hypot(q.x - p.x, q.y - p.y) <= rad) hitPeg(q, false);
    });
    void fromCrate;
  }

  function bolt(p) {
    Sound.play('bolt');
    const near = B.pegs.filter(q => !q.dead && !q.lit && q !== p && q.type !== 'post' && Math.hypot(q.x - p.x, q.y - p.y) <= P.boltRange)
      .sort((a, c) => Math.hypot(a.x - p.x, a.y - p.y) - Math.hypot(c.x - p.x, c.y - p.y)).slice(0, 3);
    near.forEach(q => { B.arcs.push({ x1: p.x, y1: p.y, x2: q.x, y2: q.y, t: 0, seed: Math.random() }); hitPeg(q, false); });
  }

  // ---------- Physics ----------
  function step(dt) {
    const b = B.ball; if (!b) return;
    b.life += dt;
    b.vy += P.gravity * dt;
    if (hasJoker('horseshoe')) {
      let best = null, bd = 140;
      B.pegs.forEach(p => { if (p.type === 'gold' && !p.lit && !p.dead) { const d = Math.hypot(p.x - b.x, p.y - b.y); if (d < bd) { bd = d; best = p; } } });
      if (best) { b.vx += ((best.x - b.x) / bd) * 320 * dt; b.vy += ((best.y - b.y) / bd) * 200 * dt; }
    }
    if (b.life > P.maxBallLife && !b.ghost) { b.ghost = true; b.vy = Math.max(b.vy, 300); UI.log('Ball pushed down.', ''); }
    if (b.ghost) b.vy = Math.max(b.vy, 300);
    b.x += b.vx * dt; b.y += b.vy * dt;
    const r = P.ballR;
    if (b.x < r) { b.x = r; b.vx = Math.abs(b.vx) * P.wallBounce; Sound.play('wall'); }
    if (b.x > P.W - r) { b.x = P.W - r; b.vx = -Math.abs(b.vx) * P.wallBounce; Sound.play('wall'); }
    if (b.y < r) { b.y = r; b.vy = Math.abs(b.vy) * P.ceilBounce; }
    if (!b.ghost) {
      for (const p of B.pegs) {
        if (p.dead) continue;
        const dx = b.x - p.x, dy = b.y - p.y, rr = r + p.r, d2 = dx * dx + dy * dy;
        if (d2 >= rr * rr) continue;
        const d = Math.sqrt(d2) || 0.01, nx = dx / d, ny = dy / d;
        if (p.type === 'portal' && p.twin && !p.twin.dead && p.cool <= 0) {
          p.cool = p.twin.cool = P.portalCooldown;
          hitPeg(p, true);
          b.x = p.twin.x + nx * (rr + 2); b.y = p.twin.y + ny * (rr + 2);
          B.rings.push({ x: p.twin.x, y: p.twin.y, r: 2, max: 26, t: 0, color: '#b388ff' });
          break;
        }
        b.x = p.x + nx * rr; b.y = p.y + ny * rr;
        const vn = b.vx * nx + b.vy * ny;
        if (vn < 0) {
          const e = p.type === 'bumper' ? P.bumperBounce : P.pegBounce;
          b.vx -= (1 + e) * vn * nx; b.vy -= (1 + e) * vn * ny;
          if (p.type === 'bumper') { b.vx += nx * P.bumperKick; b.vy += ny * P.bumperKick; }
          b.vx += RNG.range(-P.nudge, P.nudge);
          if (p.type !== 'post') hitPeg(p, true);
        }
      }
    }
    // Pocket dividers.
    if (b.y > P.pocketTop) {
      for (let i = 1; i < P.pocketCount; i++) {
        const x = i * SLOT_W;
        if (Math.abs(b.x - x) < r + 2) { b.x = x + Math.sign(b.x - x || 1) * (r + 2); b.vx = -b.vx * P.wallBounce; }
      }
    }
    const sp = Math.hypot(b.vx, b.vy);
    if (sp > P.speedCap) { b.vx *= P.speedCap / sp; b.vy *= P.speedCap / sp; }
    if (sp < P.stallSpeed) { b.slow += dt; if (b.slow > P.stallTime) { b.vx += RNG.range(-1, 1) * 140; b.vy -= 40; b.slow = 0; } } else b.slow = 0;
    if (b.y > P.H - 10) sink(clamp(Math.floor(b.x / SLOT_W), 0, P.pocketCount - 1));
  }

  // ---------- Sink and reveal ----------
  function sink(slot) {
    const b = B.ball; B.ball = null;
    G.phase = 'sink';
    Sound.play('sink');
    B.reveal = { slot, type: B.pockets[slot], t: 0, applied: false, ball: b };
  }

  function updateReveal(dt) {
    const R = B.reveal; if (!R) return;
    R.t += dt;
    if (R.t > 0.15 && !R.flipped) { R.flipped = true; Sound.play('flip'); }
    if (R.t > 0.45 && !R.applied) { R.applied = true; Game.applyPocket(R.type, R.ball); }
    if (R.t > REVEAL_HOLD || (R.skip && R.t > 0.6)) {
      B.reveal = null;
      B.pegs.forEach(p => { if (p.lit && !REARM[p.type] && p.type !== 'post' && p.type !== 'crate' && p.type !== 'chest') p.dead = true; });
      B.pegs = B.pegs.filter(p => !p.dead);
      B.pockets = null; B.glint = -1;
      Game.afterBall();
    }
  }

  // ---------- Aim ----------
  function skipReveal() { if (B.reveal) B.reveal.skip = true; }

  function setAimFrom(px, py) {
    let a = Math.atan2(py - P.launcherY, px - P.launcherX);
    if (a < 0) a = px < P.launcherX ? Math.PI - P.aimClamp : P.aimClamp;
    B.aim = clamp(a, P.aimClamp, Math.PI - P.aimClamp);
  }
  function nudgeAim(d) { B.aim = clamp(B.aim + d, P.aimClamp, Math.PI - P.aimClamp); }

  function previewPath() {
    const pts = [];
    let x = P.launcherX, y = P.launcherY, vx = Math.cos(B.aim) * P.launchSpeed, vy = Math.sin(B.aim) * P.launchSpeed;
    const dt = 1 / 120;
    for (let i = 0; i < 240; i++) {
      vy += P.gravity * dt; x += vx * dt; y += vy * dt;
      if (x < P.ballR) { x = P.ballR; vx = -vx * P.wallBounce; }
      if (x > P.W - P.ballR) { x = P.W - P.ballR; vx = -vx * P.wallBounce; }
      if (i % 3 === 0) pts.push([x, y]);
      if (B.pegs.some(p => !p.dead && Math.hypot(p.x - x, p.y - y) < p.r + P.ballR)) break;
      if (y > P.H) break;
    }
    return pts;
  }

  // ---------- Update ----------
  function update(dt) {
    B.t += dt;
    B.pegs.forEach(p => {
      if (p.type === 'rover') p.x = p.bx + Math.sin(B.t * 1.6 + p.phase) * P.roverAmp;
      if (p.cool > 0) p.cool -= dt;
      if (p.glow > 0) p.glow = Math.max(0, p.glow - dt * 2);
    });
    if (G.phase === 'ball' && B.ball) {
      const steps = Math.round((dt * G.speed) / P.dt);
      for (let i = 0; i < steps && B.ball; i++) step(P.dt);
      if (B.ball) {
        B.trail.push({ x: B.ball.x, y: B.ball.y, gold: multFor(B.ball.combo) >= 2 });
        if (B.trail.length > 18) B.trail.shift();
      }
    }
    if (G.phase === 'sink') updateReveal(dt);
    B.parts.forEach(q => { q.t += dt; q.x += q.vx * dt; q.y += q.vy * dt; q.vy += 400 * dt; });
    B.parts = B.parts.filter(q => q.t < q.life);
    B.floats.forEach(f => (f.t += dt));
    B.floats = B.floats.filter(f => f.t < 1);
    B.rings.forEach(r => (r.t += dt));
    B.rings = B.rings.filter(r => r.t < 0.4);
    B.arcs.forEach(a => (a.t += dt));
    B.arcs = B.arcs.filter(a => a.t < 0.3);
    if (B.bigText) { B.bigText.t += dt; if (B.bigText.t > 0.9) B.bigText = null; }
    B.shake = Math.max(0, B.shake - dt * 30);
  }

  // ---------- Drawing ----------
  function makeFelt() {
    felt = document.createElement('canvas');
    felt.width = P.W * dpr; felt.height = P.H * dpr;
    const f = felt.getContext('2d'); f.scale(dpr, dpr);
    f.fillStyle = '#1f5a3a'; f.fillRect(0, 0, P.W, P.H);
    const img = f.getImageData(0, 0, P.W * dpr, P.H * dpr), d = img.data;
    for (let i = 0; i < d.length; i += 4) {
      const n = (Math.random() - 0.5) * 22 + Math.sin(i * 0.013) * 3;
      d[i] += n; d[i + 1] += n; d[i + 2] += n;
    }
    f.putImageData(img, 0, 0);
    const vg = f.createRadialGradient(P.W / 2, P.H / 2, P.W * 0.2, P.W / 2, P.H / 2, P.H * 0.75);
    vg.addColorStop(0, 'rgba(0,0,0,0)'); vg.addColorStop(1, 'rgba(0,0,0,0.55)');
    f.fillStyle = vg; f.fillRect(0, 0, P.W, P.H);
    f.strokeStyle = 'rgba(255,230,160,0.07)'; f.lineWidth = 1.5;
    for (let i = 1; i <= 4; i++) { f.beginPath(); f.arc(P.launcherX, P.launcherY, 30 * i, 0.1, Math.PI - 0.1); f.stroke(); }
    // Pocket area.
    f.fillStyle = 'rgba(0,0,0,0.35)'; f.fillRect(0, P.pocketTop, P.W, P.H - P.pocketTop);
  }

  function shapePath(c, shape, x, y, r) {
    c.beginPath();
    switch (shape) {
      case 'diamond': c.moveTo(x, y - r * 1.2); c.lineTo(x + r, y); c.lineTo(x, y + r * 1.2); c.lineTo(x - r, y); c.closePath(); break;
      case 'square': c.rect(x - r, y - r, r * 2, r * 2); break;
      case 'chest': c.rect(x - r * 1.2, y - r * 0.8, r * 2.4, r * 1.7); break;
      case 'hex': for (let i = 0; i < 6; i++) { const a = i * Math.PI / 3; c.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r); } c.closePath(); break;
      case 'star': for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * 0.5 : r * 1.25; c.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); } c.closePath(); break;
      case 'heart': c.moveTo(x, y + r); c.bezierCurveTo(x - r * 1.6, y - r * 0.2, x - r * 0.6, y - r * 1.4, x, y - r * 0.4); c.bezierCurveTo(x + r * 0.6, y - r * 1.4, x + r * 1.6, y - r * 0.2, x, y + r); break;
      case 'bolt': c.moveTo(x + r * 0.3, y - r * 1.2); c.lineTo(x - r * 0.8, y + r * 0.15); c.lineTo(x, y + r * 0.15); c.lineTo(x - r * 0.3, y + r * 1.2); c.lineTo(x + r * 0.8, y - r * 0.15); c.lineTo(x, y - r * 0.15); c.closePath(); break;
      case 'pill': c.ellipse(x, y, r * 1.4, r * 0.75, 0, 0, Math.PI * 2); break;
      case 'bomb': for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4 + Math.PI / 8; c.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r); } c.closePath(); break;
      default: c.arc(x, y, r, 0, Math.PI * 2);
    }
  }

  function drawPeg(c, p, x, y, scale) {
    const d = PEGS[p.type];
    if (p.type === 'post') { c.fillStyle = '#b8913f'; c.beginPath(); c.arc(x, y, p.r, 0, 6.28); c.fill(); return; }
    const r = p.r * scale;
    if (p.lit || p.glow > 0) { c.shadowColor = d.color; c.shadowBlur = 14 * (p.glow + (p.lit ? 0.6 : 0)); }
    shapePath(c, d.shape, x, y, r);
    const g = c.createRadialGradient(x - r * 0.35, y - r * 0.4, 1, x, y, r * 1.3);
    const col = p.lit && !REARM[p.type] && p.type !== 'crate' && p.type !== 'chest' ? lighten(d.color) : d.color;
    g.addColorStop(0, '#fffbe8'); g.addColorStop(0.35, col); g.addColorStop(1, shade(col));
    c.fillStyle = g; c.fill();
    c.shadowBlur = 0;
    c.lineWidth = 1.2; c.strokeStyle = 'rgba(0,0,0,0.55)'; c.stroke();
    // Inner marks for extra silhouette detail.
    c.strokeStyle = 'rgba(0,0,0,0.6)'; c.lineWidth = 1.4;
    if (d.shape === 'ring') { c.beginPath(); c.arc(x, y, r * 0.55, 0, 6.28); c.stroke(); }
    if (d.shape === 'donut') { c.fillStyle = '#1a0c33'; c.beginPath(); c.arc(x, y, r * 0.5, 0, 6.28); c.fill(); }
    if (d.shape === 'square') { c.beginPath(); c.moveTo(x - r, y - r); c.lineTo(x + r, y + r); c.moveTo(x + r, y - r); c.lineTo(x - r, y + r); c.stroke(); }
    if (d.shape === 'chest') { c.beginPath(); c.moveTo(x - r * 1.2, y - r * 0.1); c.lineTo(x + r * 1.2, y - r * 0.1); c.stroke(); }
    if (d.shape === 'bomb') { c.strokeStyle = '#ffcc80'; c.beginPath(); c.moveTo(x + r * 0.5, y - r * 0.8); c.lineTo(x + r * 1.1, y - r * 1.4); c.stroke(); }
    if ((p.type === 'crate' || p.type === 'chest') && p.hits) {
      c.fillStyle = '#fff'; c.font = 'bold 9px sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
      const need = p.type === 'crate' ? (hasJoker('crowbar') ? 2 : 3) : 2;
      c.fillText(String(need - p.hits), x, y + 1);
    }
  }
  function shade(hex) { const n = parseInt(hex.slice(1), 16); const f = v => Math.max(0, Math.floor(v * 0.45)); return `rgb(${f(n >> 16)},${f((n >> 8) & 255)},${f(n & 255)})`; }
  function lighten(hex) { const n = parseInt(hex.slice(1), 16); const f = v => Math.min(255, Math.floor(v + (255 - v) * 0.5)); return `rgb(${f(n >> 16)},${f((n >> 8) & 255)},${f(n & 255)})`; }

  function draw() {
    if (!cx) return;
    const c = cx;
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.save();
    if (B.shake > 0 && !reduced()) c.translate((Math.random() - 0.5) * B.shake, (Math.random() - 0.5) * B.shake);
    c.drawImage(felt, 0, 0, P.W, P.H);
    // Launcher.
    c.fillStyle = '#5a3a1e'; c.beginPath(); c.arc(P.launcherX, P.launcherY - 8, 18, 0, Math.PI); c.fill();
    c.fillStyle = '#c9a24a'; c.beginPath(); c.arc(P.launcherX, P.launcherY - 8, 12, 0, Math.PI); c.fill();
    // Aim preview.
    if (G.phase === 'aim') {
      c.fillStyle = 'rgba(255,240,200,0.75)';
      previewPath().forEach(([x, y], i) => { c.globalAlpha = 1 - i / 90; c.beginPath(); c.arc(x, y, 2, 0, 6.28); c.fill(); });
      c.globalAlpha = 1;
      c.save(); c.translate(P.launcherX, P.launcherY); c.rotate(B.aim);
      c.fillStyle = '#d8b25a'; c.fillRect(0, -4, 26, 8); c.restore();
      c.fillStyle = '#eee'; c.beginPath(); c.arc(P.launcherX, P.launcherY, P.ballR, 0, 6.28); c.fill();
    }
    // Rings and arcs.
    B.rings.forEach(r => {
      const k = r.t / 0.4; c.strokeStyle = r.color || `rgba(255,170,80,${1 - k})`; c.globalAlpha = 1 - k; c.lineWidth = 4 * (1 - k) + 1;
      c.beginPath(); c.arc(r.x, r.y, r.r + (r.max - r.r) * k, 0, 6.28); c.stroke(); c.globalAlpha = 1;
    });
    // Pegs.
    B.pegs.forEach(p => { if (!p.dead) drawPeg(c, p, p.x, p.y, 1); });
    // Portal links.
    c.setLineDash([2, 5]); c.strokeStyle = 'rgba(179,136,255,0.25)'; c.lineWidth = 1;
    B.pegs.forEach(p => { if (p.type === 'portal' && p.twin && p.id < p.twin.id && !p.dead) { c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.twin.x, p.twin.y); c.stroke(); } });
    c.setLineDash([]);
    B.arcs.forEach(a => {
      c.strokeStyle = `rgba(200,170,255,${1 - a.t / 0.3})`; c.lineWidth = 2; c.beginPath(); c.moveTo(a.x1, a.y1);
      for (let i = 1; i < 6; i++) { const k = i / 6; c.lineTo(a.x1 + (a.x2 - a.x1) * k + (Math.random() - 0.5) * 12, a.y1 + (a.y2 - a.y1) * k + (Math.random() - 0.5) * 12); }
      c.lineTo(a.x2, a.y2); c.stroke();
    });
    // Pockets.
    drawPockets(c);
    // Trail and ball.
    const b = B.ball;
    if (b) {
      const gold = multFor(b.combo) >= 2;
      B.trail.forEach((t, i) => {
        const k = i / B.trail.length;
        c.fillStyle = t.gold ? `rgba(255,210,63,${k * 0.6})` : `rgba(255,255,255,${k * 0.25})`;
        c.beginPath(); c.arc(t.x, t.y, P.ballR * k, 0, 6.28); c.fill();
      });
      c.save(); c.translate(b.x, b.y);
      if (!reduced()) {
        const sp = Math.hypot(b.vx, b.vy), st = Math.min(0.3, sp / 2400);
        c.rotate(Math.atan2(b.vy, b.vx)); c.scale(1 + st, 1 - st);
      }
      if (gold) { c.shadowColor = '#ffd23f'; c.shadowBlur = 18; }
      const g = c.createRadialGradient(-2, -2, 1, 0, 0, P.ballR);
      g.addColorStop(0, '#ffffff'); g.addColorStop(1, gold ? '#e6b422' : '#b0b6bf');
      c.fillStyle = g; c.beginPath(); c.arc(0, 0, P.ballR, 0, 6.28); c.fill();
      c.restore(); c.shadowBlur = 0;
    }
    // Particles and floats.
    B.parts.forEach(q => { c.globalAlpha = 1 - q.t / q.life; c.fillStyle = q.color; c.fillRect(q.x - 2, q.y - 2, 4, 4); });
    c.globalAlpha = 1;
    c.textAlign = 'center'; c.textBaseline = 'middle';
    B.floats.forEach(f => {
      if (f.t < 0) return;
      c.globalAlpha = 1 - f.t; c.fillStyle = f.color; c.font = `bold ${f.size}px system-ui, sans-serif`;
      c.strokeStyle = 'rgba(0,0,0,0.7)'; c.lineWidth = 3; c.strokeText(f.text, f.x, f.y - f.t * 26); c.fillText(f.text, f.x, f.y - f.t * 26);
    });
    c.globalAlpha = 1;
    if (B.bigText) {
      const k = B.bigText.t, s = reduced() ? 1 : 1 + Math.max(0, 0.4 - k) * 1.5;
      c.save(); c.translate(P.W / 2, 300); c.scale(s, s); c.globalAlpha = Math.min(1, 2 * (0.9 - k) + 0.2);
      c.font = 'bold 54px Georgia, serif'; c.fillStyle = '#ffd23f'; c.strokeStyle = '#5a3a1e'; c.lineWidth = 6;
      c.strokeText(B.bigText.text, 0, 0); c.fillText(B.bigText.text, 0, 0); c.restore(); c.globalAlpha = 1;
    }
    c.restore();
  }

  function drawPockets(c) {
    for (let i = 0; i < P.pocketCount; i++) {
      const x = i * SLOT_W, y = P.pocketTop + 6, w = SLOT_W, h = P.H - y;
      const R = B.reveal && B.reveal.slot === i ? B.reveal : null;
      c.fillStyle = '#0d1a12'; c.fillRect(x + 4, y, w - 8, h);
      let lamp = '#8a6a2a';
      if (R && R.t > 0.15) {
        const info = POCKETS[R.type];
        lamp = info.kind === 'perk' ? '#5ef08a' : '#ff5a4a';
        c.fillStyle = info.kind === 'perk' ? 'rgba(94,240,138,0.25)' : 'rgba(255,90,74,0.25)';
        c.fillRect(x + 4, y, w - 8, h);
      }
      if (B.glint === i && G.phase === 'ball') { lamp = `rgba(255,255,255,${0.5 + 0.5 * Math.sin(B.t * 10)})`; }
      c.fillStyle = lamp; c.beginPath(); c.arc(x + w / 2, y + 10, 4, 0, 6.28); c.fill();
      // Revealed plate flips up.
      if (R && R.t > 0.15) {
        const info = POCKETS[R.type];
        const k = Math.min(1, (R.t - 0.15) / 0.25), pw = 196, ph = 70;
        const px = clamp(x + w / 2 - pw / 2, 4, P.W - pw - 4), py = P.pocketTop - ph - 14;
        c.save(); c.translate(px + pw / 2, py + ph); c.scale(1, k); c.translate(-(px + pw / 2), -(py + ph));
        c.fillStyle = '#2b2b2b'; c.strokeStyle = '#c9a24a'; c.lineWidth = 2;
        roundRect(c, px, py, pw, ph, 6); c.fill(); c.stroke();
        c.fillStyle = info.kind === 'perk' ? '#7dffa6' : '#ff8a7a'; c.font = 'bold 19px Georgia, serif'; c.textAlign = 'center';
        c.fillText(`${info.icon} ${info.name}`, px + pw / 2, py + 22);
        c.fillStyle = '#f2ead3'; c.font = '13px system-ui, sans-serif';
        wrapText(c, info.text, px + pw / 2, py + 44, pw - 14, 15);
        // Countdown bar so players know the plate will close.
        c.fillStyle = 'rgba(201,162,74,0.7)'; c.fillRect(px + 6, py + ph - 5, (pw - 12) * Math.max(0, 1 - R.t / REVEAL_HOLD), 2);
        c.restore();
      }
    }
  }
  function roundRect(c, x, y, w, h, r) { c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); }
  function wrapText(c, text, x, y, maxW, lh) {
    const words = text.split(' '); let line = '';
    words.forEach(w => { const t = line ? line + ' ' + w : w; if (c.measureText(t).width > maxW && line) { c.fillText(line, x, y); line = w; y += lh; } else line = t; });
    c.fillText(line, x, y);
  }

  // ---------- Input ----------
  function toBoard(e) {
    const rect = cv.getBoundingClientRect();
    return { x: (e.clientX - rect.left) * (P.W / rect.width), y: (e.clientY - rect.top) * (P.H / rect.height) };
  }
  function pegAt(x, y) { return B.pegs.find(p => !p.dead && p.type !== 'post' && Math.hypot(p.x - x, p.y - y) < p.r + 6); }

  function initInput() {
    let dragging = false;
    cv.addEventListener('pointermove', e => {
      const q = toBoard(e);
      if (G.phase === 'aim' && (e.pointerType === 'mouse' || dragging)) setAimFrom(q.x, q.y);
      const p = pegAt(q.x, q.y);
      if (p !== B.hoverPeg) { B.hoverPeg = p; UI.pegTip(p); }
    });
    cv.addEventListener('pointerdown', e => {
      Sound.init();
      if (G.phase !== 'aim') return;
      if (e.pointerType !== 'mouse') { dragging = true; cv.setPointerCapture(e.pointerId); const q = toBoard(e); setAimFrom(q.x, q.y); e.preventDefault(); }
    });
    cv.addEventListener('pointerup', e => {
      if (G.phase === 'sink') { skipReveal(); dragging = false; return; }
      if (G.phase !== 'aim') { dragging = false; return; }
      if (e.pointerType === 'mouse') { const q = toBoard(e); setAimFrom(q.x, q.y); fire(); }
      else if (dragging) { dragging = false; fire(); }
    });
    cv.addEventListener('pointercancel', () => (dragging = false));
    cv.addEventListener('pointerleave', () => { B.hoverPeg = null; UI.pegTip(null); });
  }

  function init(canvas) {
    cv = canvas; cx = cv.getContext('2d');
    dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.width = P.W * dpr; cv.height = P.H * dpr;
    makeFelt();
    initInput();
  }

  return { init, build, fire, skipReveal, update, draw, nudgeAim, splitText, B, shapePath, drawPeg, multFor };
})();
