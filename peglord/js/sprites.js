/* Hand-drawn vector sprites for heroes and foes. Origin is the feet, +x faces the enemy side. */
'use strict';

const Sprites = (() => {
  const TAU = Math.PI * 2;

  function circle(c, x, y, r, fill) { c.beginPath(); c.arc(x, y, r, 0, TAU); c.fillStyle = fill; c.fill(); }
  function ellipse(c, x, y, rx, ry, fill, rot = 0) { c.beginPath(); c.ellipse(x, y, rx, ry, rot, 0, TAU); c.fillStyle = fill; c.fill(); }
  function rrect(c, x, y, w, h, r, fill) {
    c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r); c.arcTo(x + w, y + h, x, y + h, r);
    c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath(); c.fillStyle = fill; c.fill();
  }
  function poly(c, pts, fill) { c.beginPath(); pts.forEach(([x, y], i) => (i ? c.lineTo(x, y) : c.moveTo(x, y))); c.closePath(); c.fillStyle = fill; c.fill(); }
  function line(c, x1, y1, x2, y2, w, col) { c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.lineWidth = w; c.strokeStyle = col; c.lineCap = 'round'; c.stroke(); }
  const OUT = 'rgba(20,12,6,0.9)';

  // ---------- Weapons, drawn in the hand's frame with the blade along +y ----------
  const weapon = {
    sword(c) { rrect(c, -2.5, -4, 5, 8, 1.5, '#5a3a1e'); rrect(c, -7, 3, 14, 3, 1, '#c9a24a'); poly(c, [[-3, 6], [3, 6], [2.5, 32], [0, 37], [-2.5, 32]], '#dfe6ee'); line(c, 0, 8, 0, 32, 1, '#9aa7b4'); },
    staff(c, glow) {
      line(c, 0, -14, 0, 34, 3.5, '#6b4226');
      const g = 6 + glow * 3;
      c.save(); c.shadowColor = '#c39bff'; c.shadowBlur = 10 + glow * 18; circle(c, 0, 38, g, '#d9c2ff'); c.restore();
      circle(c, 0, 38, g * 0.55, '#ffffff');
    },
    mace(c) { line(c, 0, -4, 0, 24, 3.5, '#6b4226'); circle(c, 0, 28, 7, '#b0b6bf'); [0, 1, 2, 3, 4, 5].forEach(i => { const a = i * TAU / 6; poly(c, [[Math.cos(a) * 6, 28 + Math.sin(a) * 6], [Math.cos(a + 0.3) * 6, 28 + Math.sin(a + 0.3) * 6], [Math.cos(a + 0.15) * 11, 28 + Math.sin(a + 0.15) * 11]], '#8a9099'); }); },
    dagger(c) { rrect(c, -2, -3, 4, 6, 1, '#3b2414'); rrect(c, -5, 2, 10, 2.5, 1, '#c9a24a'); poly(c, [[-2.5, 4], [2.5, 4], [0, 20]], '#e8eef4'); },
    bow(c) { c.beginPath(); c.arc(-10, 0, 22, -1.1, 1.1); c.lineWidth = 3.5; c.strokeStyle = '#7a4a22'; c.stroke(); line(c, -10 + 22 * Math.cos(-1.1), 22 * Math.sin(-1.1), -10 + 22 * Math.cos(1.1), 22 * Math.sin(1.1), 1, '#eee'); },
    tankard(c) { rrect(c, -7, 2, 14, 16, 3, '#c98a2a'); rrect(c, -7, 2, 14, 4, 2, '#fff8e0'); c.beginPath(); c.arc(8, 10, 5, -1.4, 1.4); c.lineWidth = 2.5; c.strokeStyle = '#8a5a1a'; c.stroke(); },
    cane(c) { line(c, 0, -6, 0, 34, 3, '#2a1a10'); circle(c, 0, -7, 4, '#d4a94e'); },
    bottle(c) { rrect(c, -4, 4, 8, 16, 3, '#3d7a3a'); rrect(c, -2, -2, 4, 7, 1, '#2f5f2c'); },
    skull(c) { line(c, 0, -10, 0, 34, 3, '#5a4632'); circle(c, 0, 38, 6, '#ece4cf'); circle(c, -2, 37, 1.4, '#222'); circle(c, 2, 37, 1.4, '#222'); },
    fist() {},
  };
  const offhand = {
    shield(c, raise) { const y = raise ? -6 : 0; poly(c, [[-11, y - 14], [11, y - 14], [11, y + 2], [0, y + 14], [-11, y + 2]], '#8a2a2a'); poly(c, [[-8, y - 11], [8, y - 11], [8, y + 1], [0, y + 10], [-8, y + 1]], '#b8913f'); line(c, 0, y - 10, 0, y + 8, 2, '#8a2a2a'); },
    tower(c, raise) { rrect(c, -14, (raise ? -30 : -24), 22, 40, 3, '#7a4a33'); for (let i = 0; i < 4; i++) line(c, -13, (raise ? -22 : -16) + i * 9, 7, (raise ? -22 : -16) + i * 9, 1.2, '#3b2414'); },
    bomb(c) { circle(c, 0, 4, 9, '#2b2b2b'); circle(c, -3, 1, 2.5, '#666'); line(c, 4, -4, 8, -11, 2, '#c9a24a'); circle(c, 8.5, -12, 2.5, Math.random() > 0.5 ? '#ffcf3f' : '#ff6a2a'); },
  };

  // ---------- Generic humanoid ----------
  // o: skin, body, legs, bulk, head(c), weapon, off, arm (radians, 0 = hanging), lean, glow, guard
  function humanoid(c, o) {
    const b = o.bulk || 1;
    c.save(); c.rotate(o.lean || 0);
    // legs
    const step = o.step || 0;
    rrect(c, -8 * b, -20, 7 * b, 20 + step, 2, o.legs); rrect(c, 1 * b, -20, 7 * b, 20 - step, 2, o.legs);
    rrect(c, -9 * b, -3 + step, 9 * b, 4, 2, '#2a1a10'); rrect(c, 1 * b, -3 - step, 10 * b, 4, 2, '#2a1a10');
    // back arm and off-hand
    c.save(); c.translate(-6 * b, -38); c.rotate(o.guard ? -1.3 : -0.25); line(c, 0, 0, 0, 13, 6 * b, o.sleeve || o.body);
    c.translate(0, 14); if (o.off) (offhand[o.off] || weapon[o.off])(c, o.guard); c.restore();
    // torso
    rrect(c, -12 * b, -44, 24 * b, 27, 7, o.body);
    if (o.belt) rrect(c, -12 * b, -24, 24 * b, 4, 1, o.belt);
    if (o.torso) o.torso(c, b);
    // head
    circle(c, 1, -54, 11, o.skin);
    if (!o.noFace) { circle(c, 5, -55, 1.6, '#1a120c'); circle(c, 9, -55, 1.4, '#1a120c'); if (o.hurt) { line(c, 3, -49, 9, -49, 1.5, '#5a2a1a'); } }
    if (o.head) o.head(c);
    // front arm and weapon
    c.save(); c.translate(6 * b, -38); c.rotate(-(o.arm || 0));
    line(c, 0, 0, 0, 13, 6 * b, o.sleeve || o.body); circle(c, 0, 15, 3.5, o.skin);
    c.translate(0, 15); c.rotate(-0.35);
    if (o.weapon && weapon[o.weapon]) weapon[o.weapon](c, o.glow || 0);
    c.restore();
    c.restore();
  }

  // ---------- Heroes ----------
  const H = {
    knight(c, p) {
      humanoid(c, Object.assign({
        skin: '#f0c8a0', body: '#9aa7b4', legs: '#6c7682', sleeve: '#7d8894', belt: '#5a3a1e', weapon: 'sword', off: 'shield',
        torso(c) { line(c, -8, -36, 8, -36, 2, '#c9d3dd'); rrect(c, -4, -32, 8, 6, 2, '#b8913f'); },
        head(c) {
          rrect(c, -10, -67, 23, 15, 6, '#aab5c2'); rrect(c, 3, -59, 10, 3, 1, '#2a2f35');
          poly(c, [[-4, -67], [0, -79], [4, -67]], '#c0392b'); poly(c, [[0, -76], [-10, -73], [-4, -68]], '#e74c3c');
        },
      }, p));
    },
    mage(c, p) {
      humanoid(c, Object.assign({
        skin: '#e9c49c', body: '#5b3a8c', legs: '#3e2766', sleeve: '#6b47a3', weapon: 'staff', belt: '#c9a24a',
        torso(c) { poly(c, [[-12, -20], [12, -20], [15, -4], [-15, -4]], '#5b3a8c'); },
        head(c) {
          ellipse(c, 1, -64, 17, 4, '#4a2d75');
          poly(c, [[-10, -64], [12, -64], [6, -80], [-6, -93]], '#5b3a8c'); circle(c, -6, -93, 3, '#ffd23f');
          line(c, -4, -46, 8, -46, 4, '#e8e2d0'); poly(c, [[-3, -46], [9, -46], [3, -36]], '#e8e2d0');
        },
      }, p));
    },
    priest(c, p) {
      humanoid(c, Object.assign({
        skin: '#f2c9a5', body: '#8a5a33', legs: '#6b4226', sleeve: '#9b6a3f', belt: '#e8d9a8', weapon: 'mace', off: 'tankard', bulk: 1.15,
        torso(c) { rrect(c, -3, -42, 6, 18, 1, '#e8d9a8'); rrect(c, -7, -36, 14, 4, 1, '#e8d9a8'); },
        head(c) { c.beginPath(); c.arc(1, -54, 11, Math.PI * 1.05, Math.PI * 1.95, true); c.fillStyle = '#7a5130'; c.fill(); circle(c, 11, -51, 2.5, '#e8907a'); },
      }, p));
    },
    rogue(c, p) {
      humanoid(c, Object.assign({
        skin: '#e4b88f', body: '#3d5a2e', legs: '#2c3a22', sleeve: '#4a6b37', belt: '#5a3a1e', weapon: 'dagger',
        head(c) { c.beginPath(); c.arc(1, -54, 13, Math.PI * 0.85, Math.PI * 0.15 + TAU); c.lineTo(-10, -40); c.fillStyle = '#2f4a22'; c.fill(); rrect(c, 1, -52, 12, 5, 2, '#1a2a12'); },
      }, p));
    },
    ranger(c, p) {
      humanoid(c, Object.assign({
        skin: '#e7bd93', body: '#2e6b6b', legs: '#4a3a22', sleeve: '#3a7f7f', belt: '#7a4a22', weapon: 'bow',
        torso(c) { line(c, -10, -44, 10, -22, 3, '#7a4a22'); },
        head(c) { poly(c, [[-11, -58], [13, -60], [8, -70], [-6, -70]], '#2a5555'); poly(c, [[-8, -66], [-20, -74], [-10, -62]], '#c0392b'); },
      }, p));
    },
  };

  // ---------- Foes (they face +x in local space; the scene mirrors them) ----------
  const F = {
    brute(c, p) {
      humanoid(c, Object.assign({
        skin: '#d99a7a', body: '#e8e2d0', legs: '#3b4a6b', sleeve: '#d99a7a', bulk: 1.35, weapon: 'fist', belt: '#2a1a10',
        torso(c) { line(c, -8, -44, -8, -30, 3, '#c9a24a'); },
        head(c) { line(c, -6, -61, 8, -62, 2.5, '#5a2a1a'); rrect(c, -2, -48, 12, 3, 1, '#6b3a2a'); },
      }, p));
    },
    sneak(c, p) {
      humanoid(c, Object.assign({
        skin: '#2b2b33', body: '#1f1f26', legs: '#151519', sleeve: '#26262e', weapon: 'dagger', noFace: true,
        head(c) { c.beginPath(); c.arc(1, -54, 13, Math.PI * 0.8, Math.PI * 0.2 + TAU); c.lineTo(-11, -38); c.fillStyle = '#18181e'; c.fill(); circle(c, 6, -55, 1.8, '#ff4a3a'); circle(c, 10, -55, 1.6, '#ff4a3a'); },
      }, p));
    },
    bomber(c, p) {
      humanoid(c, Object.assign({
        skin: '#e0b090', body: '#7a3a2a', legs: '#4a2a1a', sleeve: '#8a4a3a', bulk: 1.4, weapon: 'fist', off: 'bomb', belt: '#c9a24a',
        head(c) { rrect(c, -10, -66, 22, 7, 3, '#4a4a4a'); rrect(c, 2, -60, 11, 5, 2, '#88c0ff'); },
      }, p));
    },
    shaman(c, p) {
      humanoid(c, Object.assign({
        skin: '#9fbf7a', body: '#6b4a2a', legs: '#4a3a22', sleeve: '#7a5a3a', weapon: 'skull', glow: p.glow || 0, lean: (p.lean || 0) + 0.12,
        head(c) { [-0.6, -0.3, 0, 0.3, 0.6].forEach((a, i) => { c.save(); c.translate(1, -62); c.rotate(a); poly(c, [[-2, 0], [2, 0], [0, -16]], ['#e74c3c', '#f1c40f', '#3498db', '#f1c40f', '#e74c3c'][i]); c.restore(); }); },
      }, p));
    },
    bulwark(c, p) {
      humanoid(c, Object.assign({
        skin: '#d0a888', body: '#6c6c74', legs: '#4a4a52', sleeve: '#5a5a62', bulk: 1.3, weapon: 'fist', off: 'tower', guard: true,
        head(c) { rrect(c, -10, -68, 23, 18, 4, '#7a7a84'); rrect(c, 2, -60, 11, 3, 1, '#222'); },
      }, p));
    },
    drunk(c, p) {
      humanoid(c, Object.assign({
        skin: '#e8b090', body: '#a85a3a', legs: '#4a3a5a', sleeve: '#b86a4a', weapon: 'bottle', belt: '#2a1a10', lean: (p.lean || 0) + Math.sin((p.time || 0) * 2) * 0.12,
        head(c) { circle(c, 12, -52, 3.5, '#e85a4a'); line(c, -8, -64, 10, -66, 3, '#6b4226'); },
      }, p));
    },
    leech(c, p) {
      const flap = Math.sin((p.time || 0) * 10) * 0.5;
      c.save(); c.translate(0, -40 + Math.sin((p.time || 0) * 3) * 4); c.rotate(p.lean || 0);
      [-1, 1].forEach(s => { c.save(); c.scale(s, 1); c.rotate(flap * s); poly(c, [[4, -2], [30, -14], [26, -2], [32, 6], [20, 4], [14, 10], [6, 6]], '#4a2a4a'); c.restore(); });
      ellipse(c, 0, 0, 10, 13, '#5a3a5a'); poly(c, [[-7, -10], [-4, -20], [-1, -10]], '#5a3a5a'); poly(c, [[1, -10], [4, -20], [7, -10]], '#5a3a5a');
      circle(c, -3, -3, 2, '#ffcf3f'); circle(c, 4, -3, 2, '#ffcf3f'); poly(c, [[-2, 5], [0, 9], [2, 5]], '#fff');
      c.restore();
    },
    hound(c, p) {
      const run = Math.sin((p.time || 0) * (p.attacking ? 20 : 4)) * 3;
      c.save(); c.rotate(p.lean || 0);
      rrect(c, -18, -12 + run * 0.2, 5, 12, 2, '#5a3a22'); rrect(c, -10, -12 - run * 0.2, 5, 12, 2, '#4a2e1a');
      rrect(c, 8, -12 - run * 0.2, 5, 12, 2, '#5a3a22'); rrect(c, 14, -12 + run * 0.2, 5, 12, 2, '#4a2e1a');
      ellipse(c, 0, -18, 22, 10, '#6b4226'); line(c, -20, -20, -30, -30 - run, 3, '#6b4226');
      ellipse(c, 22, -28, 10, 8, '#6b4226'); rrect(c, 24, -27, 12, 7, 3, '#5a3a22'); circle(c, 35, -25, 2, '#111');
      poly(c, [[16, -34], [18, -44], [23, -34]], '#4a2e1a'); circle(c, 24, -30, 1.8, '#ffcf3f');
      rrect(c, 12, -22, 6, 3, 1, '#c0392b');
      c.restore();
    },
    landlord(c, p) {
      humanoid(c, Object.assign({
        skin: '#e8c8a8', body: '#2a2a3a', legs: '#1e1e2a', sleeve: '#33334a', weapon: 'cane', belt: '#c9a24a', bulk: 1.2,
        torso(c) { poly(c, [[-4, -44], [4, -44], [0, -26]], '#f2ead3'); poly(c, [[-2, -42], [2, -42], [0, -34]], '#8a1a1a'); circle(c, 6, -30, 1.4, '#d4a94e'); circle(c, 6, -24, 1.4, '#d4a94e'); },
        head(c) {
          rrect(c, -9, -84, 20, 22, 2, '#151520'); rrect(c, -13, -65, 28, 4, 2, '#151520'); rrect(c, -9, -69, 20, 3, 0, '#8a1a1a');
          c.beginPath(); c.arc(8, -55, 4, 0, TAU); c.lineWidth = 1.5; c.strokeStyle = '#d4a94e'; c.stroke();
          line(c, 0, -47, 12, -47, 3, '#d8d8d8'); line(c, 12, -47, 15, -50, 2, '#d8d8d8');
        },
      }, p));
    },
  };

  // Draw a unit to the given context at (x, y), feet at y.
  // pose: { kind: 'hero'|'foe', type, scale, arm, lean, guard, glow, hurt, time, dead, attacking }
  function draw(c, x, y, pose) {
    c.save(); c.translate(x, y);
    const s = pose.scale || 1;
    c.scale(pose.kind === 'foe' ? -s : s, s);
    if (pose.dead) { c.translate(-10, 0); c.rotate(-Math.PI / 2); c.translate(0, 18); }
    const fn = pose.kind === 'hero' ? H[pose.type] : F[pose.type];
    if (fn) fn(c, pose);
    c.restore();
  }
  function shadow(c, x, y, w) { ellipse(c, x, y + 2, w, w * 0.25, 'rgba(0,0,0,0.35)'); }

  function idleArm(type) { return { staff: 1.1, bow: 1.4, skull: 1.0, cane: 0.6, bottle: 0.7 }[type] || 0.45; }
  const weaponOf = {
    hero: { knight: 'sword', mage: 'staff', priest: 'mace', rogue: 'dagger', ranger: 'bow' },
    foe: { brute: 'fist', sneak: 'dagger', bomber: 'fist', shaman: 'skull', bulwark: 'fist', drunk: 'bottle', leech: null, hound: null, landlord: 'cane' },
  };

  return { draw, shadow, idleArm, weaponOf, OUT };
})();
