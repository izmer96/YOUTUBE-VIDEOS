/* The fight scene: a side-view pub floor with animated heroes and foes. */
'use strict';

const Scene = (() => {
  const W = 720, H = 300, FLOOR = 250;
  let cv, cx, bg, dpr = 1;
  const anims = {};   // key -> { atk, hurt, flash, cast, die }
  const texts = [], fx = [], shots = [];
  let time = 0, hoverFoe = null;
  const reduced = () => G && G.settings.reducedMotion;
  const key = (kind, id) => kind + id;
  const A = (kind, id) => (anims[key(kind, id)] = anims[key(kind, id)] || { atk: 0, hurt: 0, flash: 0, cast: 0 });

  // ---------- Layout ----------
  function heroPos(i, n) { const xs = n === 3 ? [215, 140, 65] : [200, 120, 50]; return { x: xs[i] || 60, y: FLOOR - (i % 2) * 14 + 6 }; }
  function foePos(i, n, boss) { const xs = [505, 590, 670]; return { x: xs[i] || 600, y: FLOOR - (i % 2) * 14 + 6 + (boss ? 6 : 0) }; }
  function posOf(kind, id) {
    if (kind === 'hero') { const i = G.heroes.findIndex(h => h.id === id); return i < 0 ? null : heroPos(i, G.heroes.length); }
    const i = G.foes.findIndex(f => f.id === id); return i < 0 ? null : foePos(i, G.foes.length, G.foes[i].boss);
  }
  function foeSpriteType(f) { return f.boss ? 'landlord' : f.type; }
  function foeScale(f) { return f.boss ? 1.45 : f.type === 'brute' || f.type === 'bulwark' ? 1.05 : 0.95; }

  // ---------- Events from battle ----------
  function attack(kind, id) { const a = A(kind, id); a.atk = 1; }
  function cast(kind, id) { const a = A(kind, id); a.cast = 1; }
  function hurt(kind, id) { const a = A(kind, id); a.hurt = 1; a.flash = 1; }
  function text(kind, id, t, cls) {
    const p = posOf(kind, id); if (!p) return;
    const col = { dmg: '#ffffff', crit: '#ffd23f', heal: '#5ef0d0', block: '#8ec5ff' }[cls] || '#fff';
    texts.push({ x: p.x + (Math.random() - 0.5) * 24, y: p.y - 92, t: 0, text: t, col, big: cls === 'crit' });
  }
  function effect(kind, id, type) {
    const p = posOf(kind, id); if (!p) return;
    fx.push({ x: p.x, y: p.y - 40, type, t: 0, seed: Math.random() });
  }
  function projectile(fromKind, fromId, toKind, toId, type) {
    const a = posOf(fromKind, fromId), b = posOf(toKind, toId); if (!a || !b) return;
    shots.push({ x1: a.x + 20, y1: a.y - 50, x2: b.x, y2: b.y - 45, t: 0, type });
  }

  // ---------- Background ----------
  function makeBg() {
    bg = document.createElement('canvas'); bg.width = W * dpr; bg.height = H * dpr;
    const c = bg.getContext('2d'); c.scale(dpr, dpr);
    // Brick wall
    const wall = c.createLinearGradient(0, 0, 0, FLOOR - 30);
    wall.addColorStop(0, '#2a1610'); wall.addColorStop(1, '#4a2a1c');
    c.fillStyle = wall; c.fillRect(0, 0, W, FLOOR - 30);
    c.strokeStyle = 'rgba(0,0,0,0.25)'; c.lineWidth = 1;
    for (let y = 8; y < FLOOR - 30; y += 16) {
      c.beginPath(); c.moveTo(0, y); c.lineTo(W, y); c.stroke();
      for (let x = (y / 16) % 2 ? 0 : 20; x < W; x += 40) { c.beginPath(); c.moveTo(x, y); c.lineTo(x, y + 16); c.stroke(); }
    }
    // Wainscot panel
    c.fillStyle = '#3a2210'; c.fillRect(0, FLOOR - 92, W, 62);
    c.fillStyle = '#5a3a1e'; c.fillRect(0, FLOOR - 94, W, 5);
    for (let x = 10; x < W; x += 60) { c.strokeStyle = 'rgba(0,0,0,0.35)'; c.strokeRect(x, FLOOR - 84, 48, 46); }
    // Bar shelf with bottles
    c.fillStyle = '#5a3a1e'; c.fillRect(300, 70, 140, 6);
    ['#3d7a3a', '#8a2a2a', '#c98a2a', '#3a4a8a', '#3d7a3a', '#6b3a6b'].forEach((col, i) => { c.fillStyle = col; c.fillRect(310 + i * 21, 46, 10, 24); c.fillRect(313 + i * 21, 38, 4, 9); });
    // Dartboard and a framed notice
    c.fillStyle = '#1a1a1a'; c.beginPath(); c.arc(110, 80, 26, 0, 6.28); c.fill();
    ['#c0392b', '#f2ead3', '#2e7d32', '#f2ead3', '#c0392b'].forEach((col, i) => { c.fillStyle = col; c.beginPath(); c.arc(110, 80, 22 - i * 4.5, 0, 6.28); c.fill(); });
    c.fillStyle = '#c9a24a'; c.fillRect(560, 44, 84, 60); c.fillStyle = '#efe4c4'; c.fillRect(566, 50, 72, 48);
    c.fillStyle = '#5a3a1e'; c.font = 'bold 10px Georgia, serif'; c.textAlign = 'center'; c.fillText('RENT DUE', 602, 68); c.font = '9px Georgia, serif'; c.fillText('— The Mgmt.', 602, 84);
    // Lamps
    [220, 500].forEach(x => {
      const g = c.createRadialGradient(x, 30, 2, x, 30, 160); g.addColorStop(0, 'rgba(255,200,110,0.35)'); g.addColorStop(1, 'rgba(255,200,110,0)');
      c.fillStyle = g; c.fillRect(0, 0, W, FLOOR);
      c.strokeStyle = '#222'; c.beginPath(); c.moveTo(x, 0); c.lineTo(x, 22); c.stroke();
      c.fillStyle = '#c9a24a'; c.beginPath(); c.moveTo(x - 12, 32); c.lineTo(x + 12, 32); c.lineTo(x + 6, 22); c.lineTo(x - 6, 22); c.fill();
      c.fillStyle = '#ffe8a8'; c.beginPath(); c.arc(x, 34, 4, 0, 6.28); c.fill();
    });
    // Floorboards
    const fl = c.createLinearGradient(0, FLOOR - 30, 0, H);
    fl.addColorStop(0, '#5a361c'); fl.addColorStop(1, '#2a180c');
    c.fillStyle = fl; c.fillRect(0, FLOOR - 30, W, H - FLOOR + 30);
    c.strokeStyle = 'rgba(0,0,0,0.3)';
    for (let i = 0; i < 6; i++) { const y = FLOOR - 30 + i * i * 2.4 + i * 6; c.beginPath(); c.moveTo(0, y); c.lineTo(W, y); c.stroke(); }
    for (let x = -400; x < W + 400; x += 70) { c.beginPath(); c.moveTo(W / 2 + (x - W / 2) * 0.55, FLOOR - 30); c.lineTo(x, H); c.stroke(); }
    const vg = c.createRadialGradient(W / 2, H / 2, 120, W / 2, H / 2, W * 0.7); vg.addColorStop(0, 'rgba(0,0,0,0)'); vg.addColorStop(1, 'rgba(0,0,0,0.55)');
    c.fillStyle = vg; c.fillRect(0, 0, W, H);
  }

  // ---------- Update and draw ----------
  function update(dt) {
    time += dt;
    Object.values(anims).forEach(a => {
      a.atk = Math.max(0, a.atk - dt * 2.4); a.hurt = Math.max(0, a.hurt - dt * 3); a.flash = Math.max(0, a.flash - dt * 6); a.cast = Math.max(0, a.cast - dt * 1.8);
    });
    texts.forEach(t => (t.t += dt)); fx.forEach(f => (f.t += dt)); shots.forEach(s => (s.t += dt * 3));
    for (let i = texts.length - 1; i >= 0; i--) if (texts[i].t > 1.1) texts.splice(i, 1);
    for (let i = fx.length - 1; i >= 0; i--) if (fx[i].t > 0.5) fx.splice(i, 1);
    for (let i = shots.length - 1; i >= 0; i--) if (shots[i].t >= 1) { const s = shots[i]; fx.push({ x: s.x2, y: s.y2, type: s.type === 'fire' ? 'boom' : 'holy', t: 0, seed: Math.random() }); shots.splice(i, 1); }
  }

  // Lunge curve: forward fast, hold, then back.
  function lunge(t) { const p = 1 - t; return p < 0.25 ? p / 0.25 : p < 0.55 ? 1 : 1 - (p - 0.55) / 0.45; }

  function drawUnit(c, u, kind, p, sel, target) {
    const a = A(kind, u.id);
    const dir = kind === 'hero' ? 1 : -1;
    const rm = reduced();
    const bob = rm || u.dead ? 0 : Math.sin(time * 2.4 + u.id) * 1.6;
    const lun = rm ? 0 : lunge(a.atk) * (a.atk > 0 ? 70 : 0);
    const knock = rm ? 0 : Math.sin(a.hurt * Math.PI) * 10;
    const shake = rm ? 0 : (a.hurt > 0.5 ? (Math.random() - 0.5) * 4 : 0);
    const x = p.x + dir * lun - dir * knock + shake, y = p.y;
    const type = kind === 'hero' ? u.cls : foeSpriteType(u);
    const scale = kind === 'hero' ? 1 : foeScale(u);
    // selection ring / target marker
    if (sel) { c.strokeStyle = 'rgba(255,210,63,0.9)'; c.lineWidth = 2; c.beginPath(); c.ellipse(p.x, y + 2, 24, 6, 0, 0, 6.28); c.stroke(); }
    Sprites.shadow(c, x, y, 18 * scale);
    // Arm angle: idle, wind-up then swing during attack, raised while casting.
    const wpn = Sprites.weaponOf[kind][type];
    let arm = Sprites.idleArm(wpn) + Math.sin(time * 2 + u.id) * 0.05;
    if (a.atk > 0) { const t = 1 - a.atk; arm = t < 0.3 ? 0.4 + (t / 0.3) * 2.4 : 2.8 - Math.min(1, (t - 0.3) / 0.2) * 2.3; }
    if (a.cast > 0) arm = 1.6 + Math.sin(time * 20) * 0.1;
    const guard = kind === 'hero' ? (u.guarding || (u.cmd === 'guard' && G.phase !== 'resolve')) : type === 'bulwark';
    const pose = {
      kind, type, scale, arm, guard, time: time + u.id,
      lean: (a.hurt > 0 ? -0.25 * a.hurt : 0) + (a.atk > 0 ? 0.15 : 0),
      glow: a.cast > 0 ? 1 : 0.3 + 0.2 * Math.sin(time * 3), hurt: a.hurt > 0, dead: u.dead, attacking: a.atk > 0,
      step: a.atk > 0 ? Math.sin(time * 30) * 2 : 0,
    };
    c.save();
    if (u.dead) c.globalAlpha = 0.45;
    // Render to an offscreen buffer so a hit can flash the silhouette white.
    const buf = drawUnit.buf || (drawUnit.buf = document.createElement('canvas'));
    const bw = 220, bh = 220;
    if (buf.width !== bw * dpr) { buf.width = bw * dpr; buf.height = bh * dpr; }
    const b = buf.getContext('2d'); b.setTransform(1, 0, 0, 1, 0, 0); b.clearRect(0, 0, buf.width, buf.height); b.setTransform(dpr, 0, 0, dpr, 0, 0); b.globalCompositeOperation = 'source-over';
    Sprites.draw(b, bw / 2, bh - 20 + bob, pose);
    if (a.flash > 0) { b.globalCompositeOperation = 'source-atop'; b.fillStyle = `rgba(255,255,255,${a.flash})`; b.fillRect(0, 0, bw, bh); b.globalCompositeOperation = 'source-over'; }
    if (kind === 'foe' && hoverFoe === u.id && !u.dead) { b.globalCompositeOperation = 'source-atop'; b.fillStyle = 'rgba(255,120,100,0.18)'; b.fillRect(0, 0, bw, bh); b.globalCompositeOperation = 'source-over'; }
    c.drawImage(buf, x - bw / 2, y - bh + 20, bw, bh);
    c.restore();
    if (guard && !u.dead && kind === 'hero') { c.strokeStyle = 'rgba(142,197,255,0.6)'; c.lineWidth = 2; c.beginPath(); c.arc(x, y - 40, 42, -1.2, 1.2); c.stroke(); }
    // HP bar and name
    const max = kind === 'hero' ? heroStats(u).maxHp : u.maxHp;
    const top = y - 76 * scale - 18;
    const bw2 = 56;
    c.fillStyle = 'rgba(0,0,0,0.7)'; c.fillRect(p.x - bw2 / 2 - 1, top - 1, bw2 + 2, 7);
    c.fillStyle = kind === 'hero' ? '#4fc36a' : '#e0503c'; c.fillRect(p.x - bw2 / 2, top, bw2 * Math.max(0, u.hp / max), 5);
    if (kind === 'hero' && u.shield) { c.fillStyle = '#8ec5ff'; c.fillRect(p.x - bw2 / 2, top, bw2 * Math.min(1, u.shield / max), 2); }
    c.font = '600 11px system-ui, sans-serif'; c.textAlign = 'center'; c.fillStyle = '#f2ead3';
    c.fillText(`${u.name}${kind === 'hero' ? ' · ' + u.level : ''}`, p.x, top - 5);
    if (kind === 'foe' && !u.dead) {
      const label = Battle.intentLabel(u);
      c.font = '600 10px system-ui, sans-serif';
      const w = c.measureText(label).width + 10;
      c.fillStyle = 'rgba(70,18,18,0.92)'; c.fillRect(p.x - w / 2, top - 30, w, 15);
      c.fillStyle = '#ffc7bd'; c.fillText(label, p.x, top - 19);
      if (target) {
        const by = top - 40 + (rm ? 0 : Math.sin(time * 6) * 3);
        c.fillStyle = '#ff8a7a'; c.beginPath(); c.moveTo(p.x - 7, by - 8); c.lineTo(p.x + 7, by - 8); c.lineTo(p.x, by); c.fill();
      }
    }
  }

  function drawFx(c) {
    fx.forEach(f => {
      const k = f.t / 0.5;
      c.save(); c.globalAlpha = 1 - k;
      if (f.type === 'slash') {
        c.strokeStyle = '#ffffff'; c.lineWidth = 5 * (1 - k) + 1; c.beginPath(); c.arc(f.x, f.y, 26 + k * 10, -2.2 + f.seed, -0.6 + f.seed + k); c.stroke();
      } else if (f.type === 'zap' || f.type === 'holy') {
        c.strokeStyle = f.type === 'zap' ? '#c8a8ff' : '#fff2a8'; c.lineWidth = 2;
        for (let i = 0; i < 6; i++) { const a = i / 6 * 6.28 + f.seed; c.beginPath(); c.moveTo(f.x + Math.cos(a) * 8, f.y + Math.sin(a) * 8); c.lineTo(f.x + Math.cos(a) * (20 + k * 24), f.y + Math.sin(a) * (20 + k * 24)); c.stroke(); }
      } else if (f.type === 'boom') {
        const g = c.createRadialGradient(f.x, f.y, 0, f.x, f.y, 50 * (0.4 + k)); g.addColorStop(0, '#fff3c4'); g.addColorStop(0.4, '#ff9a3c'); g.addColorStop(1, 'rgba(200,40,20,0)');
        c.fillStyle = g; c.beginPath(); c.arc(f.x, f.y, 50 * (0.4 + k), 0, 6.28); c.fill();
      } else if (f.type === 'heal') {
        c.fillStyle = '#5ef0d0';
        for (let i = 0; i < 7; i++) { const x = f.x + Math.sin(i * 2.1 + f.seed * 9) * 22, y = f.y + 30 - k * 60 - i * 5; c.fillRect(x - 1.5, y - 5, 3, 10); c.fillRect(x - 5, y - 1.5, 10, 3); }
      } else if (f.type === 'block') {
        c.strokeStyle = '#8ec5ff'; c.lineWidth = 3; c.beginPath(); c.arc(f.x, f.y, 30 + k * 8, 0, 6.28); c.stroke();
      }
      c.restore();
    });
    shots.forEach(s => {
      const x = s.x1 + (s.x2 - s.x1) * s.t, y = s.y1 + (s.y2 - s.y1) * s.t - Math.sin(s.t * Math.PI) * 30;
      c.save(); c.shadowColor = s.type === 'fire' ? '#ff6a2a' : '#fff2a8'; c.shadowBlur = 18;
      c.fillStyle = s.type === 'fire' ? '#ffb347' : '#fff8d0'; c.beginPath(); c.arc(x, y, 9, 0, 6.28); c.fill();
      c.fillStyle = 'rgba(255,120,40,0.5)'; c.beginPath(); c.arc(x - (s.x2 - s.x1) * 0.04, y, 6, 0, 6.28); c.fill();
      c.restore();
    });
  }

  function draw() {
    if (!cx || !G || !G.heroes.length) return;
    const c = cx;
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.drawImage(bg, 0, 0, W, H);
    const foeTarget = Battle.currentTarget();
    // Draw back row first so the front row overlaps.
    const units = [];
    G.heroes.forEach((h, i) => units.push({ u: h, kind: 'hero', p: heroPos(i, G.heroes.length), sel: i === G.selHero }));
    G.foes.forEach((f, i) => units.push({ u: f, kind: 'foe', p: foePos(i, G.foes.length, f.boss), target: foeTarget && foeTarget.id === f.id }));
    units.sort((a, b) => a.p.y - b.p.y).forEach(o => drawUnit(c, o.u, o.kind, o.p, o.sel, o.target));
    drawFx(c);
    texts.forEach(t => {
      c.globalAlpha = Math.max(0, 1 - t.t / 1.1);
      c.font = `800 ${t.big ? 24 : 17}px system-ui, sans-serif`; c.textAlign = 'center';
      c.lineWidth = 4; c.strokeStyle = 'rgba(0,0,0,0.8)'; c.strokeText(t.text, t.x, t.y - t.t * 30);
      c.fillStyle = t.col; c.fillText(t.text, t.x, t.y - t.t * 30);
    });
    c.globalAlpha = 1;
  }

  // ---------- Input ----------
  function foeAt(e) {
    const r = cv.getBoundingClientRect();
    const x = (e.clientX - r.left) * W / r.width, y = (e.clientY - r.top) * H / r.height;
    let best = null, bd = 60;
    G.foes.forEach((f, i) => { if (f.dead) return; const p = foePos(i, G.foes.length, f.boss); const d = Math.hypot(p.x - x, p.y - 45 - y); if (d < bd) { bd = d; best = f; } });
    return best;
  }
  function init(canvas) {
    cv = canvas; cx = cv.getContext('2d');
    dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.width = W * dpr; cv.height = H * dpr;
    makeBg();
    cv.addEventListener('pointermove', e => { const f = foeAt(e); hoverFoe = f ? f.id : null; cv.style.cursor = f ? 'pointer' : 'default'; });
    cv.addEventListener('pointerleave', () => (hoverFoe = null));
    cv.addEventListener('click', e => { const f = foeAt(e); if (f && G.phase !== 'resolve') { G.target = f.id; Sound.play('ui'); UI.refresh(); } });
  }

  return { init, update, draw, attack, cast, hurt, text, effect, projectile };
})();
