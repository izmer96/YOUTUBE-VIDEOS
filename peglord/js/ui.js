/* DOM: panels, console, overlays, tooltips, keyboard and the main loop. */
'use strict';

const UI = (() => {
  const $ = id => document.getElementById(id);
  const esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const logLines = [];
  let overlayKind = null, sheetSel = null, sheetFilter = 'all';

  // Re-render a container while keeping keyboard focus on the same control.
  function render(el, html) {
    const a = document.activeElement;
    const key = a && el.contains(a) ? a.getAttribute('data-k') : null;
    el.innerHTML = html;
    if (key) { const n = el.querySelector(`[data-k="${CSS.escape(key)}"]`); if (n) n.focus(); }
  }

  // ---------- Log ----------
  function log(text, cls) {
    logLines.push({ text, cls });
    while (logLines.length > 6) logLines.shift();
    const el = $('log'); if (!el) return;
    el.innerHTML = logLines.map(l => `<li class="${l.cls || ''}">${esc(l.text)}</li>`).join('');
  }

  // ---------- HUD under the board ----------
  function hud() {
    if (!G || G.phase === 'title') return;
    const total = G.balls + (G.phase === 'ball' || G.phase === 'sink' ? 1 : 0);
    let dots = '';
    for (let i = 0; i < Math.max(total, G.ballNo + G.balls); i++) dots += `<i class="${i < G.ballNo - (G.phase === 'ball' || G.phase === 'sink' ? 1 : 0) ? 'used' : ''}"></i>`;
    $('balls').innerHTML = dots + `<span class="sr">${G.balls} balls left</span>`;
    $('balls').setAttribute('aria-label', `${G.balls} balls left`);
    const b = Board.B.ball;
    $('combo').textContent = b ? `Combo ${b.combo} · ×${Board.multFor(b.combo)}` : (G.hotNext ? 'Hot ball ready' : '');
    $('bank').textContent = `${G.bank} XP`;
    $('split').textContent = `Peg payout ×${PAYOUT(G.stage)} · Pockets: ${Board.splitText()}`;
    const hints = {
      aim: `Aim with the mouse, a drag or ←/→. Click, release or Space drops. ${G.balls} ball${G.balls === 1 ? '' : 's'} left.`,
      ball: 'Ball in play…',
      sink: 'Pocket revealed!',
      alloc: '99 XP buys a level. Pick commands, tap a foe to target, then Fight.',
      resolve: 'Fighting…',
      draft: 'Stage cleared. Level up and equip, then choose a reward.',
      over: 'Run over.',
    };
    $('hint').textContent = hints[G.phase] || '';
  }

  // ---------- Jokers ----------
  function jokers() {
    let html = '';
    for (let i = 0; i < MAX_JOKERS; i++) {
      const id = G.jokers[i];
      if (id) {
        const J = JOKERS[id];
        html += `<div class="joker ${J.rarity}${UI.newJoker === id ? ' pop' : ''}" id="jk-${id}" tabindex="0" data-tip="${esc(J.name)} (${J.rarity})\n${esc(J.text)}"><span class="ji" aria-hidden="true">${J.icon}</span><span class="jn">${esc(J.name)}</span><span class="jr">${J.rarity}</span></div>`;
      } else html += `<div class="joker empty" aria-label="Empty joker slot">Joker</div>`;
    }
    UI.newJoker = null;
    render($('jokers'), html);
    $('jokercount').textContent = `${G.jokers.length}/${MAX_JOKERS}`;
  }
  function pulseJoker(id) {
    const el = $('jk-' + id); if (!el) return;
    el.classList.remove('pulse'); void el.offsetWidth; el.classList.add('pulse');
  }

  // ---------- Units ----------
  function hpBar(cur, max, shield) {
    const w = Math.max(0, Math.min(100, (cur / max) * 100));
    const s = shield ? Math.min(100, (shield / max) * 100) : 0;
    return `<div class="hpbar"><div class="trail" style="width:${w}%"></div><div class="fill" style="width:${w}%"></div>${s ? `<div class="shield" style="width:${s}%"></div>` : ''}</div>`;
  }
  function updateBar(el, cur, max, shield) {
    const bar = el.querySelector('.hpbar'); if (!bar) return;
    const w = Math.max(0, Math.min(100, (cur / max) * 100)) + '%';
    bar.querySelector('.fill').style.width = w;
    bar.querySelector('.trail').style.width = w;
    let sh = bar.querySelector('.shield');
    if (shield) { if (!sh) { sh = document.createElement('div'); sh.className = 'shield'; bar.appendChild(sh); } sh.style.width = Math.min(100, (shield / max) * 100) + '%'; }
    else if (sh) sh.remove();
  }

  function buildUnits() {
    $('foes').innerHTML = G.foes.map(f => `<button class="unit foe${f.boss ? ' boss' : ''}" id="foe-${f.id}" data-foe="${f.id}" data-k="foe-${f.id}">
      <div class="urow"><canvas class="mini" width="64" height="64" data-portrait="foe:${f.boss ? 'landlord' : f.type}" aria-hidden="true"></canvas><span class="uname">${esc(f.name)}</span></div>
      ${hpBar(f.hp, f.maxHp)}<div class="hptext"></div><div class="fchips"></div></button>`).join('');
    $('party').innerHTML = G.heroes.map((h, i) => `<button class="unit hero" id="hero-${h.id}" data-hero="${i}" data-k="hero-${i}">
      <div class="urow"><canvas class="mini" width="64" height="64" data-portrait="hero:${h.cls}" aria-hidden="true"></canvas><span class="uname">${esc(h.name)}</span></div>
      <div class="usub lvl"></div>${hpBar(h.hp, 1)}<div class="hptext"></div><div class="cmdtag"></div></button>`).join('');
    drawPortraits(document);
  }

  // Head-and-shoulders portraits from the scene sprites.
  function drawPortraits(root, t = 0) {
    root.querySelectorAll('canvas[data-portrait]').forEach(cv => {
      const [kind, type] = cv.dataset.portrait.split(':');
      const c = cv.getContext('2d'), w = cv.width, h = cv.height;
      const full = cv.classList.contains('portrait');
      c.setTransform(1, 0, 0, 1, 0, 0); c.clearRect(0, 0, w, h);
      if (!full) {
        const g = c.createRadialGradient(w / 2, h / 2, 2, w / 2, h / 2, w / 1.3);
        g.addColorStop(0, '#4a3a28'); g.addColorStop(1, '#1b1410'); c.fillStyle = g; c.fillRect(0, 0, w, h);
      }
      const sc = full ? h / 120 : h / 52;
      c.save();
      if (full) { c.translate(w / 2, h - 10 + Math.sin(t * 2.2) * 2); c.scale(sc, sc); }
      else { c.translate(w / 2 - 4 * sc, h + 34 * sc); c.scale(sc, sc); }
      Sprites.draw(c, 0, 0, { kind, type, scale: 1, arm: Sprites.idleArm(Sprites.weaponOf[kind][type]) + Math.sin(t * 2) * 0.05, glow: 0.4, time: t });
      c.restore();
    });
  }

  function units() {
    const alive = Battle.living(G.foes);
    G.foes.forEach(f => {
      const el = $('foe-' + f.id); if (!el) return;
      el.classList.toggle('dead', f.dead);
      el.classList.toggle('target', !f.dead && f.id === G.target);
      updateBar(el, f.hp, f.maxHp);
      el.querySelector('.hptext').textContent = `${f.hp}/${f.maxHp} HP${f.burnTurns ? ` · burning ${f.burn}` : ''}${f.mark ? ' · marked' : ''}`;
      const m = Battle.intentOf(f);
      el.querySelector('.fchips').innerHTML = f.dead ? '' :
        `<span class="intent" data-tip="${esc(m.name)}: ${esc(m.text)}.\nFoe attack now: ${Battle.foeAttack(f)}${m.magic ? ' (magic, vs Resist)' : ' (physical, vs Defense)'}">${esc(Battle.intentLabel(f))}</span> ${f.armor ? `<span class="armorchip" data-tip="Armor ${f.armor}: subtracted from each physical hit, half for magic and holy.">⛨${f.armor}</span>` : ''}`;
      el.setAttribute('aria-label', `${f.name}, ${f.hp} of ${f.maxHp} HP${f.dead ? ', down' : `, intends ${Battle.intentLabel(f)}`}${f.id === G.target ? ', targeted' : ''}`);
      el.disabled = f.dead;
    });
    void alive;
    G.heroes.forEach((h, i) => {
      const el = $('hero-' + h.id); if (!el) return;
      const st = heroStats(h);
      el.classList.toggle('dead', h.dead);
      el.classList.toggle('selected', i === G.selHero);
      el.querySelector('.lvl').textContent = `Lv ${h.level} · ${HEROES[h.cls].title}`;
      updateBar(el, h.hp, st.maxHp, h.shield);
      el.querySelector('.hptext').textContent = `${h.hp}/${st.maxHp} HP${h.shield ? ` +${h.shield}` : ''}${h.hex ? ' · hexed' : ''}`;
      const cmdName = h.dead ? 'Fallen' : h.cmd === 'skill' ? HEROES[h.cls].skill.name : h.cmd === 'guard' ? 'Guard' : 'Attack';
      el.querySelector('.cmdtag').textContent = h.guarding ? 'Guarding' : cmdName;
      el.setAttribute('aria-label', `${h.name}, level ${h.level}, ${h.hp} of ${st.maxHp} HP, ${cmdName}`);
      el.setAttribute('aria-pressed', i === G.selHero ? 'true' : 'false');
    });
  }

  function unitFx(kind, id, text, cls) {
    Scene.text(kind, id, text, cls);
    const el = $(`${kind}-${id}`); if (!el) return;
    const s = document.createElement('span');
    s.className = 'fx ' + cls; s.textContent = text;
    s.style.left = (35 + Math.random() * 30) + '%';
    el.appendChild(s);
    setTimeout(() => s.remove(), 950);
  }
  function unitAnim(kind, id, cls) {
    if (cls === 'lunge') Scene.attack(kind, id); else if (cls === 'hit') Scene.hurt(kind, id);
    if (G.settings.reducedMotion) return;
    const el = $(`${kind}-${id}`); if (!el) return;
    el.classList.remove(cls); void el.offsetWidth; el.classList.add(cls);
    setTimeout(() => el.classList.remove(cls), 400);
  }

  // ---------- XP bar ----------
  function xpbar() {
    const lv = Math.floor(G.bank / LEVEL_COST);
    const t = Battle.currentTarget();
    render($('xpbar'), `<div class="xptop"><span><b>${G.bank}</b> XP banked</span><span>${LEVEL_COST} XP per level · ${lv} ready</span><span>Target: ${t ? esc(t.name) : '—'}</span></div>
      <div class="xpfill" role="progressbar" aria-label="Progress to next level" aria-valuemin="0" aria-valuemax="${LEVEL_COST}" aria-valuenow="${G.bank % LEVEL_COST}"><i style="width:${(G.bank % LEVEL_COST) / LEVEL_COST * 100}%"></i></div>`);
  }

  // ---------- Hero console ----------
  function planLine(h, st) {
    const t = Battle.currentTarget();
    const bless = Battle.living(G.heroes).some(x => x.cls === 'priest') ? (G.heroes.find(x => x.cls === 'priest' && !x.dead) ? heroStats(G.heroes.find(x => x.cls === 'priest' && !x.dead)).blessing : 0) : 0;
    const mods = G.mods.rally + G.mods.whet - G.mods.rust;
    const per = (mult, type) => {
      let ar = st.ar * mult; if (type === 'magic' && st.dmgType !== 'magic' && h.cls === 'mage') ar *= 1.15;
      let armor = t ? (type === 'phys' ? t.armor : Math.floor(t.armor / 2)) : 0;
      if (h.cls === 'ranger') armor = Math.max(0, armor - 2);
      return Math.max(1, Math.floor(ar + bless) + mods - armor);
    };
    if (h.dead) return 'Fallen: cannot act until healed or the stage ends.';
    if (h.cmd === 'guard') return `Guard: half damage${h.gear.offhand && h.gear.offhand.offType === 'shield' ? ' (shield blocks 25% more)' : ''}, recover 2 HP, draw attacks.`;
    if (h.cmd === 'skill') {
      switch (h.cls) {
        case 'knight': return `Cleave: ${per(0.7, st.dmgType)} ${st.dmgType} to every foe, ${st.crit}% crit.`;
        case 'mage': return `Firebolt: ${per(2.2, 'magic')} magic damage to ${t ? esc(t.name) : 'target'}, ${st.crit}% crit.`;
        case 'priest': return `Mend: heals the weakest ally ${st.mendAmount}.`;
        case 'rogue': return `Twin Stab: 2 × ${per(1.1, st.dmgType)} to ${t ? esc(t.name) : 'target'}, ${st.crit}% crit.`;
        case 'ranger': return `Volley: ${per(0.6, st.dmgType)} to every foe, ${st.crit}% crit.`;
      }
    }
    return `Attack: ${per(1, st.dmgType)} ${st.dmgType} damage to ${t ? esc(t.name) : 'target'}, ${st.crit}% crit.`;
  }

  function consoleView() {
    const h = G.heroes[G.selHero]; if (!h) return;
    const D = HEROES[h.cls], st = heroStats(h);
    const ready = Battle.skillReady(h);
    const cdText = h.cd > 0 ? (ready ? 'Overcast' : `${h.cd} turn${h.cd > 1 ? 's' : ''}`) : 'ready';
    const cmdBtn = (c, label, n, dis, tip) => `<button data-act="cmd" data-cmd="${c}" data-k="c-${c}" aria-pressed="${h.cmd === c}" ${dis ? 'disabled' : ''} data-tip="${esc(tip)}">${n}. ${label}</button>`;
    const lv = Math.floor(G.bank / LEVEL_COST);
    const warn = st.weapon.short.length ? `<div class="warn">Weapon below requirements: −40% AR</div>` : '';
    render($('console'), `
      <div class="chead"><h3>${esc(h.name)}</h3><span>Level ${h.level} · ${D.title}</span></div>
      <div class="derived">
        <div data-tip="Max HP = floor(10 + 2.5 × Vigor) + gear">HP <b>${h.hp}/${st.maxHp}</b></div>
        <div data-tip="${esc(arTip(h, st))}">AR <b>${st.ar}</b> ${st.dmgType}</div>
        <div data-tip="3% + 1% × Dex + 0.5% × Arcane + gear, cap 75%">Crit <b>${st.crit}%</b></div>
        <div data-tip="Physical damage taken × 40 / (40 + Defense)">Def <b>${st.def}</b></div>
        <div data-tip="Magic damage taken × 40 / (40 + Resist)">Res <b>${st.res}</b></div>
      </div>${warn}
      <div class="cmds" role="group" aria-label="Command for ${esc(h.name)}">
        ${cmdBtn('attack', 'Attack', 1, h.dead, 'One hit on the target for full AR.')}
        ${cmdBtn('skill', `${D.skill.name} (${cdText})`, 2, h.dead || !ready, `${D.skill.name}: ${D.skill.text}. Usable every ${st.cd > 1 ? st.cd + ' turns' : 'turn'}.`)}
        ${cmdBtn('guard', 'Guard', 3, h.dead, 'Half damage, recover 2 HP, draw foe attacks.')}
      </div>
      <div class="plan">${planLine(h, st)}</div>
      <div class="crow">
        <button class="btn levelbtn${lv && Game.canManage() ? ' glow' : ''}" data-act="level" data-k="level">Level up (L)${lv ? ` <span class="badge">${lv}</span>` : ''}</button>
        <button class="btn" data-act="sheet" data-k="sheet">Equipment (C)</button>
      </div>`);
  }

  // ---------- Level-up screen: modelled on a site-of-grace levelling menu ----------
  let levelPreview = null;
  const ATTR_GLYPH = { vig: '♥', str: '⚒', dex: '➶', int: '✦', fai: '✚', arc: '☾' };
  function statsWith(h, change) {
    const saved = Object.assign({}, h.bought), savedLv = h.level;
    Object.keys(change).forEach(k => { h.bought[k] += change[k]; h.level += change[k]; });
    const st = heroStats(h);
    h.bought = saved; h.level = savedLv;
    return st;
  }
  function pendingOf(h) { const c = {}; G.pending.forEach(p => { if (p.hid === h.id) c[p.attr] = (c[p.attr] || 0) + 1; }); return c; }
  function cmp(a, b, fmt = v => v, invert) {
    if (a === b) return `<span class="sv">${fmt(b)}</span>`;
    const up = invert ? b < a : b > a;
    return `<span class="sv was">${fmt(a)}</span><span class="arrow">→</span><span class="sv ${up ? 'up' : 'down'}">${fmt(b)}</span>`;
  }
  function statRows(h) {
    const pend = pendingOf(h);
    const neg = {}; Object.keys(pend).forEach(k => (neg[k] = -pend[k]));
    const before = statsWith(h, neg);
    const now = heroStats(h);
    const after = levelPreview ? statsWith(h, { [levelPreview]: 1 }) : now;
    const from = levelPreview ? now : before;
    const rows = [
      ['Max HP', from.maxHp, after.maxHp], ['Attack rating', from.ar, after.ar], ['Crit chance', from.crit, after.crit, v => v + '%'],
      ['Defense', from.def, after.def], ['Resist', from.res, after.res], ['Heal power', Math.round(from.heal * 100), Math.round(after.heal * 100), v => v + '%'],
      ['Mend heals', from.mendAmount, after.mendAmount], ['Skill cooldown', from.cd, after.cd, v => v + (v === 1 ? ' turn' : ' turns'), true],
    ];
    if (h.cls === 'priest') rows.push(['Blessing', from.blessing, after.blessing, v => '+' + v]);
    return `<div class="lvl-sub">${levelPreview ? `If ${esc(ATTR_NAMES[levelPreview])} +1` : G.pending.some(p => p.hid === h.id) ? 'Before → after pending levels' : 'Current'}</div>
      <dl class="statlist">${rows.map(r => `<dt>${r[0]}</dt><dd>${cmp(r[1], r[2], r[3], r[4])}</dd>`).join('')}
      <dt>Damage type</dt><dd><span class="sv">${now.dmgType}</span></dd></dl>`;
  }
  function levelView() {
    const h = G.heroes[G.selHero], D = HEROES[h.cls], st = heroStats(h);
    const manage = Game.canManage();
    const pend = pendingOf(h);
    const pendN = Object.values(pend).reduce((a, b) => a + b, 0);
    const allPend = G.pending.length;
    const canBuy = manage && G.bank >= LEVEL_COST && h.level < LEVEL_CAP;
    const tabs = G.heroes.map((x, i) => `<button class="herotab" data-act="selhero" data-h="${i}" data-k="lt-${i}" aria-pressed="${i === G.selHero}"><canvas class="mini" width="64" height="64" data-portrait="hero:${x.cls}" aria-hidden="true"></canvas><span>${esc(x.name)}<br><small>Lv ${x.level}</small></span></button>`).join('');
    const gearAttr = {}; ATTRS.forEach(a => (gearAttr[a] = st.attrs[a] - D.attrs[a] - h.bought[a]));
    const attrRows = ATTRS.map(a => {
      const v = st.attrs[a], p = pend[a] || 0;
      const w = Math.min(60, v) / 60 * 100;
      const tip = `${ATTR_HELP[a]}\nBase ${D.attrs[a]} + bought ${h.bought[a]} + gear/jokers ${gearAttr[a]} = ${v}\nEffective ${Math.round(st.eff[a] * 10) / 10}${v > SOFT_CAP_1 ? ' (soft capped)' : ''}`;
      return `<div class="lrow${levelPreview === a ? ' hot' : ''}" data-preview="${a}">
        <span class="glyph" aria-hidden="true">${ATTR_GLYPH[a]}</span>
        <span class="lname" tabindex="0" data-tip="${esc(tip)}" data-k="ln-${a}">${ATTR_NAMES[a]}</span>
        <span class="lval">${p ? `<span class="was">${v - p}</span><span class="arrow">→</span><span class="up">${v}</span>` : v}</span>
        <span class="abar" aria-hidden="true"><i style="width:${w}%"></i><span class="cap1" style="left:${SOFT_CAP_1 / 60 * 100}%"></span><span class="cap2" style="left:${SOFT_CAP_2 / 60 * 100}%"></span></span>
        <button class="lbtn" data-act="minus" data-attr="${a}" data-k="lm-${a}" ${p && manage ? '' : 'disabled'} aria-label="Refund a level of ${ATTR_NAMES[a]}">−</button>
        <button class="lbtn plus" data-act="plus" data-attr="${a}" data-k="lp-${a}" ${canBuy ? '' : 'disabled'} aria-label="Buy a level of ${ATTR_NAMES[a]} for ${LEVEL_COST} XP (Shift for 5)">+</button>
      </div>`;
    }).join('');
    const milestones = Object.keys(D.perks).map(l => `<li class="${h.level >= l ? 'on' : ''}" style="--pos:${l / LEVEL_CAP * 100}%"><b>${l}</b><span>${esc(D.perks[l])}</span></li>`).join('');
    const body = `<div class="lvl-head"><div class="tabs" role="group" aria-label="Hero">${tabs}</div>
        <div class="tabs" role="group" aria-label="Screen"><button class="btn small" aria-pressed="true">Level up</button><button class="btn small" data-act="sheet">Equipment</button></div></div>
      <div class="lvl">
        <div class="lvl-left">
          <canvas class="portrait" width="220" height="240" data-portrait="hero:${h.cls}" aria-hidden="true"></canvas>
          <h3>${esc(h.name)}</h3><div class="lvl-sub">${D.title} · ${esc(D.passive)}</div>
          <dl class="statlist big">
            <dt>Level</dt><dd>${cmp(h.level - pendN, h.level)}</dd>
            <dt>XP held</dt><dd>${cmp(G.bank + allPend * LEVEL_COST, G.bank, v => v, true)}</dd>
            <dt>XP needed</dt><dd><span class="sv">${LEVEL_COST}</span></dd>
          </dl>
          ${manage ? '' : '<p class="usub">Levelling opens after the last ball of a round and at the stage rest.</p>'}
          <div class="crow"><button class="btn primary" data-act="confirm" ${allPend ? '' : 'disabled'}>Confirm${allPend ? ` (${allPend})` : ''}</button><button class="btn" data-act="autolevel" ${manage && G.bank >= LEVEL_COST ? '' : 'disabled'}>Auto-level</button></div>
        </div>
        <div class="lvl-mid"><h4>Attributes</h4><div class="lrows">${attrRows}</div>
          <p class="usub">Hover an attribute to preview +1. Shift-click + buys five. Bars dim past ${SOFT_CAP_1} and ${SOFT_CAP_2}, where points count half and a quarter.</p>
          <h4>Class milestones</h4><div class="track"><div class="trackfill" style="width:${h.level / LEVEL_CAP * 100}%"></div><ol class="miles">${milestones}</ol></div>
          <ul class="perks mileperks">${Object.keys(D.perks).map(l => `<li class="${h.level >= l ? '' : 'locked'}"><b>Lv ${l}</b> ${esc(D.perks[l])}</li>`).join('')}</ul>
        </div>
        <div class="lvl-right"><h4>Base stats</h4><div id="lvlstats">${statRows(h)}</div>
          <h4>Weapon</h4><p class="usub">${esc(arTip(h, st)).replace(/\n/g, '<br>')}</p></div>
      </div>
      <div class="mrow"><button class="btn" data-act="close">Close (Esc)</button></div>`;
    const o = $('overlay'), modal = o.querySelector('.modal');
    if (modal && overlayKind === 'level') render(modal, body);
    else { open('level', body); $('overlay').querySelector('.modal').classList.add('wide'); }
    drawPortraits($('overlay'), performance.now() / 1000);
  }
  function previewAttr(a) {
    if (overlayKind !== 'level' || levelPreview === a) return;
    levelPreview = a;
    const h = G.heroes[G.selHero];
    const el = $('lvlstats'); if (el) el.innerHTML = statRows(h);
    document.querySelectorAll('.lrow').forEach(r => r.classList.toggle('hot', r.dataset.preview === a));
  }

  function arTip(h, st) {
    const w = h.gear.weapon;
    if (!w) return `Bare hands: ${st.ar} AR`;
    const lines = [`${w.name}: base ${w.base}${w.upg ? `, +${w.upg} (+${w.upg * 8}%)` : ''}${st.weapon.fav ? ', favoured +10%' : ''}`];
    st.weapon.parts.forEach(p => lines.push(`${ATTR_NAMES[p.attr]} ${p.grade}: you have ${st.attrs[p.attr]} → +${p.bonus.toFixed(1)} AR`));
    if (st.weapon.short.length) lines.push('Below requirement: −40%');
    lines.push(`= ${st.ar} AR`);
    return lines.join('\n');
  }

  // ---------- Top-level refresh ----------
  function refresh() {
    if (!G || G.phase === 'title') return;
    const S = STAGES[G.stage - 1];
    $('stageinfo').textContent = `Stage ${G.stage}/11 · ${S.name} · Round ${G.round} · Seed ${G.seed}`;
    $('stagename').textContent = `${G.stage}. ${S.name}`;
    $('roundno').textContent = `Round ${G.round}`;
    hud(); jokers(); units(); xpbar(); consoleView();
    const fight = $('btnFight');
    if (G.phase === 'draft') { fight.textContent = 'Choose reward'; fight.disabled = false; }
    else { fight.textContent = 'Fight'; fight.disabled = G.phase !== 'alloc'; }
    $('btnAuto').disabled = !(Game.canManage() && G.bank >= LEVEL_COST);
    $('btnSpeed').textContent = `${G.speed}×`;
    $('btnSkip').setAttribute('aria-pressed', String(!!G.skipAnim));
    $('btnSfx').setAttribute('aria-pressed', String(Game.settings.sfxOn));
    $('btnMusic').setAttribute('aria-pressed', String(Game.settings.musicOn));
    if (overlayKind === 'sheet') sheetView();
    if (overlayKind === 'level') levelView();
    const fightMode = !['aim', 'ball', 'sink', 'title'].includes(G.phase);
    document.body.classList.toggle('mode-fight', fightMode);
    document.body.classList.toggle('mode-board', !fightMode);
    Sound.setMood(fightMode);
  }
  function rebuild() { buildUnits(); refresh(); }

  // ---------- Tooltips ----------
  const tip = () => $('tip');
  function showTip(text, x, y) {
    const t = tip(); t.textContent = text; t.hidden = false;
    const r = t.getBoundingClientRect();
    t.style.left = Math.max(4, Math.min(window.innerWidth - r.width - 4, x + 12)) + 'px';
    t.style.top = Math.max(4, Math.min(window.innerHeight - r.height - 4, y + 14)) + 'px';
  }
  function hideTip() { tip().hidden = true; }
  function initTips() {
    document.addEventListener('mouseover', e => { const n = e.target.closest('[data-tip]'); if (n) showTip(n.getAttribute('data-tip'), e.clientX, e.clientY); });
    document.addEventListener('mouseout', e => { const n = e.target.closest('[data-tip]'); if (n && !n.contains(e.relatedTarget)) hideTip(); });
    document.addEventListener('focusin', e => { const n = e.target.closest('[data-tip]'); if (n) { const r = n.getBoundingClientRect(); showTip(n.getAttribute('data-tip'), r.left, r.bottom); } });
    document.addEventListener('focusout', hideTip);
    let lp = null;
    document.addEventListener('touchstart', e => {
      const n = e.target.closest('[data-tip]'); if (!n) return;
      const tch = e.touches[0];
      lp = setTimeout(() => { showTip(n.getAttribute('data-tip'), tch.clientX, tch.clientY - 60); setTimeout(hideTip, 2200); }, 450);
    }, { passive: true });
    ['touchend', 'touchmove', 'touchcancel'].forEach(ev => document.addEventListener(ev, () => clearTimeout(lp), { passive: true }));
  }
  function pegTip(p) {
    const el = $('hint');
    if (!p || !el) { hud(); return; }
    const d = PEGS[p.type];
    el.textContent = `${d.name} peg: ${d.rule}${p.lit ? ' (already lit)' : ''}`;
  }

  // ---------- Peg guide ----------
  function pegGuide() {
    const ul = $('pegguide');
    ul.innerHTML = Object.keys(PEGS).map(k => `<li><canvas width="56" height="56" data-peg="${k}" aria-hidden="true"></canvas><span><b>${PEGS[k].name}</b> (${PEGS[k].pts}${k === 'crate' || k === 'chest' ? '/hit' : ''}): ${esc(PEGS[k].rule)}</span></li>`).join('');
    ul.querySelectorAll('canvas').forEach(cv => {
      const c = cv.getContext('2d'); c.scale(2, 2);
      c.fillStyle = '#1f5a3a'; c.fillRect(0, 0, 28, 28);
      Board.drawPeg(c, { type: cv.dataset.peg, r: cv.dataset.peg === 'bumper' ? 10 : 8, lit: false, glow: 0, hits: 0 }, 14, 14, 1);
    });
  }

  // ---------- Overlays ----------
  function open(kind, html) {
    overlayKind = kind;
    const o = $('overlay'); o.innerHTML = `<div class="modal" role="dialog" aria-modal="true" aria-label="${kind}">${html}</div>`; o.hidden = false;
    const f = o.querySelector('[data-autofocus]') || o.querySelector('button:not([disabled]), input');
    if (f) f.focus();
  }
  function closeAll() { overlayKind = null; levelPreview = null; $('overlay').hidden = true; $('overlay').innerHTML = ''; document.body.classList.remove('drafting'); }

  function settingsHtml() {
    const s = Game.settings;
    return `<h3>Settings</h3>
      <div class="mrow"><label>Music <input type="range" min="0" max="1" step="0.05" value="${s.music}" data-set="music" aria-label="Music volume"></label>
      <label>Effects <input type="range" min="0" max="1" step="0.05" value="${s.sfx}" data-set="sfx" aria-label="Effects volume"></label></div>
      <div class="mrow"><label><input type="checkbox" data-set="mute" ${!s.sfxOn && !s.musicOn ? 'checked' : ''}> Mute all</label>
      <label><input type="checkbox" data-set="reducedMotion" ${s.reducedMotion ? 'checked' : ''}> Reduced motion</label></div>`;
  }

  function showTitle(inRun) {
    const meta = Game.meta, can = Game.hasSave();
    const pool = DEFAULT_PARTY.concat(meta.unlocked);
    const party = pool.length > 3 ? `<h3>Party</h3><div class="mrow">${[0, 1, 2].map(i => `<label>Slot ${i + 1} <select data-party="${i}">${pool.map(k => `<option value="${k}" ${DEFAULT_PARTY[i] === k ? 'selected' : ''}>${HEROES[k].name}</option>`).join('')}</select></label>`).join('')}</div>` : '';
    open('title', `<div class="title-hero"><h2>Peglord</h2><p>Drop balls through the pegs, bank XP, level three heroes and evict The Landlord.</p></div>
      <div class="mrow">
        ${inRun ? '<button class="btn primary" data-act="close" data-autofocus>Resume</button>' : ''}
        <button class="btn ${inRun ? '' : 'primary'}" data-act="new" ${inRun ? '' : 'data-autofocus'}>New run</button>
        <button class="btn" data-act="continue" ${can ? '' : 'disabled'}>Continue</button>
        <label>Seed <input type="text" id="seedIn" maxlength="12" placeholder="random" aria-label="Run seed (blank for random)"></label>
      </div>
      ${party}
      ${meta.startJoker ? '<div class="mrow"><label><input type="checkbox" id="startJoker" checked> Start with a random common joker</label></div>' : ''}
      ${settingsHtml()}
      <p class="usub">Runs ${meta.runs} · Wins ${meta.wins} · Best ${meta.bestPoints} XP${meta.unlocked.length ? '' : ' · Clear The Landlord to unlock the Rogue, the Ranger and a starting joker.'}</p>`);
  }

  function showHelp() {
    const rows = Object.keys(POCKETS).map(k => { const p = POCKETS[k]; return `<tr><td>${p.icon} ${p.name}</td><td class="${p.kind === 'perk' ? 'perk' : 'badk'}">${p.kind === 'perk' ? 'Perk' : 'Bad'}</td><td>${esc(p.text)}</td></tr>`; }).join('');
    open('help', `<h2>How to play</h2>
      <p>Each round: drop your balls, bank XP, spend 99 XP per level, pick commands, then Fight. Foe intents are always shown.</p>
      <h3>Hidden pockets</h3>
      <p>All six pockets look the same. A fresh set is rolled at every launch and revealed only when the ball lands. Stages 1–3 roll 4 perks and 2 bad; from stage 4 it is 3 and 3. Jam never rolls on the last ball.</p>
      <table class="ptable"><thead><tr><th>Pocket</th><th>Kind</th><th>Effect</th></tr></thead><tbody>${rows}</tbody></table>
      <h3>Controls</h3>
      <p>Mouse: hover to aim, click to drop. Touch: drag to aim, release to drop. Keys: ←/→ aim, Space or Enter drops, 1/2/3 pick Attack/Skill/Guard, C opens the character sheet, Esc closes panels. Shift-click + buys 5 levels.</p>
      <h3>Scoring</h3>
      <p>A peg pays on its first hit (crates and chests pay every hit). Points = peg value × stage payout (×3 at the start, +1 every three stages) × multiplier, where multiplier = 1 + combo ÷ 8, rounded down. Every point is XP.</p>
      <div class="mrow"><button class="btn primary" data-act="close" data-autofocus>Close</button></div>`);
  }

  function rewardCard(r, i) {
    let body = '', kind = '', cls = '';
    const heroPick = `<div class="crow">${G.heroes.map((h, hi) => `<button class="btn small" data-act="reward" data-i="${i}" data-h="${hi}">${esc(h.name)}${r.kind === 'whetstone' && h.gear.weapon ? ` (+${h.gear.weapon.upg})` : ''}</button>`).join('')}</div>`;
    switch (r.kind) {
      case 'gear': kind = SLOT_NAMES[r.item.slot]; cls = `bord-${r.item.rarity}`; body = `<h3 class="rar-${r.item.rarity}">${esc(r.item.name)}</h3><div class="usub">${RARITIES[r.item.rarity].name} · item level ${r.item.L}</div><ul>${itemSummary(r.item).map(l => `<li>${esc(l)}</li>`).join('')}</ul>`; break;
      case 'joker': { const J = JOKERS[r.id]; kind = `Joker · ${J.rarity}`; cls = J.rarity === 'epic' ? 'bord-3' : J.rarity === 'rare' ? 'bord-2' : 'bord-0'; body = `<h3>${J.icon} ${esc(J.name)}</h3><p>${esc(J.text)}</p>`; break; }
      case 'pack': kind = 'Peg pack'; body = `<h3>${esc(PEG_PACKS[r.id].name)}</h3><p>${esc(PEG_PACKS[r.id].text)} on every board from now on.</p>`; break;
      case 'whetstone': kind = 'Upgrade'; body = `<h3>🪨 Whetstone</h3><p>+1 upgrade (+8% AR) to one hero's weapon, up to +10. Choose who:</p>${heroPick}`; break;
      case 'tankard': kind = 'Rare'; cls = 'bord-2'; body = `<h3>🏆 Golden Tankard</h3><p>Reset one hero's bought attributes and return the XP. Choose who:</p>${heroPick}`; break;
      case 'bed': kind = 'Rest'; body = `<h3>🛏️ Warm Bed</h3><p>Every living hero heals 40% of max HP.</p>`; break;
    }
    const takeBtn = (r.kind === 'whetstone' || r.kind === 'tankard') ? '' : `<button class="btn primary" data-act="reward" data-i="${i}">Take</button>`;
    return `<div class="reward ${cls}"><div class="kind">${esc(kind)}</div>${body}${takeBtn}</div>`;
  }
  function showDraft() {
    if (!G.rewards) return;
    G.draftHidden = false;
    document.body.classList.add('drafting');
    open('draft', `<h2>${esc(STAGES[G.stage - 1].name)} cleared</h2>
      <p>Party healed 30%.${G.stageDrops.length ? ` Foes dropped: ${G.stageDrops.map(i => esc(i.name)).join(', ')}.` : ''} Pick one reward.</p>
      <div class="rewards">${G.rewards.map(rewardCard).join('')}</div>
      <div class="mrow"><button class="btn" data-act="hidedraft">Level up and equip first</button></div>`);
    G.stageDrops = [];
  }

  // ---------- Character sheet ----------
  function compare(h, it) {
    const before = heroStats(h);
    const old = h.gear[it.slot]; h.gear[it.slot] = it;
    const after = heroStats(h); h.gear[it.slot] = old;
    const d = (k, label) => { const v = after[k] - before[k]; return v ? `<span class="${v > 0 ? 'delta-up' : 'delta-down'}">${label} ${v > 0 ? '+' : ''}${v}</span>` : ''; };
    return [d('ar', 'AR'), d('def', 'Def'), d('res', 'Res'), d('maxHp', 'HP'), d('crit', 'Crit')].filter(Boolean).join(' ') || '<span class="usub">No change</span>';
  }
  function itemDetail(h, it, equipped) {
    const lines = itemSummary(it).map(l => `<li>${esc(l)}</li>`);
    let scaling = '';
    if (it.slot === 'weapon') {
      const attrs = totalAttrs(h);
      scaling = '<ul>' + Object.keys(it.grades).map(k => {
        const g = GRADES[it.grades[k]] * scaleCurve(softCap(attrs[k]));
        return `<li>${ATTR_NAMES[k]} ${it.grades[k]}: ${esc(h.name)} has ${attrs[k]} → +${(it.base * g).toFixed(1)} AR</li>`;
      }).join('') + Object.keys(it.req).filter(k => attrs[k] < it.req[k]).map(k => `<li class="shortfall">Needs ${ATTR_NAMES[k]} ${it.req[k]}, has ${attrs[k]}: −40% AR</li>`).join('') + '</ul>';
    }
    const manage = Game.canManage();
    return `<div class="detail"><b class="rar-${it.rarity}">${esc(it.name)}</b> <span class="usub">${RARITIES[it.rarity].name} ${SLOT_NAMES[it.slot]} · iLvl ${it.L}</span>
      <ul>${lines.join('')}</ul>${scaling}
      ${equipped ? '' : `<div>For ${esc(h.name)}: ${compare(h, it)}</div>`}
      <div class="crow" style="margin-top:6px">
        ${equipped ? `<button class="btn small" data-act="unequip" data-slot="${it.slot}" ${manage ? '' : 'disabled'}>Unequip</button>` :
        `<button class="btn small primary" data-act="equip" data-item="${it.id}" ${manage ? '' : 'disabled'}>Equip</button>
         <button class="btn small" data-act="salvage" data-item="${it.id}" ${manage && !it.locked ? '' : 'disabled'}>Salvage (${RARITIES[it.rarity].salvage * (G.heroes.some(x => legend(x, 'pawnshark')) ? 2 : 1)} XP)</button>
         <button class="btn small" data-act="lock" data-item="${it.id}" aria-pressed="${it.locked}">${it.locked ? 'Unlock' : 'Lock'}</button>`}
      </div>${manage ? '' : '<p class="usub">Equipping opens after the last ball of a round and at the stage rest.</p>'}</div>`;
  }
  function sheetView() {
    const h = G.heroes[G.selHero];
    const tabs = G.heroes.map((x, i) => `<button class="btn small" data-act="selhero" data-h="${i}" data-k="tab-${i}" aria-pressed="${i === G.selHero}">${HEROES[x.cls].icon} ${esc(x.name)}</button>`).join('');
    const slotBtn = s => { const it = h.gear[s]; return `<button class="slot ${it ? 'bord-' + it.rarity : ''}" data-act="slot" data-slot="${s}" data-k="slot-${s}" aria-label="${SLOT_NAMES[s]}: ${it ? esc(it.name) : 'empty'}" ${it ? `data-tip="${esc(itemSummary(it).join('\n'))}"` : ''}><span class="si" aria-hidden="true">${SLOT_ICONS[s]}</span><span class="${it ? 'rar-' + it.rarity : 'usub'}">${it ? esc(it.name) : SLOT_NAMES[s]}</span></button>`; };
    const doll = ['helm', 'amulet', 'weapon', 'chest', null, 'offhand', 'gloves', 'legs', 'ring', null, 'boots', null];
    const dollHtml = doll.map(s => s ? slotBtn(s) : (s === null && doll.indexOf(s) === 4 ? '' : '<div></div>')).join('');
    const filters = ['all'].concat(SLOTS).map(f => `<button class="chip" data-act="filter" data-f="${f}" data-k="f-${f}" aria-pressed="${sheetFilter === f}">${f === 'all' ? 'All' : SLOT_NAMES[f]}</button>`).join('');
    const items = G.pack.filter(it => sheetFilter === 'all' || it.slot === sheetFilter)
      .sort((a, b) => SLOTS.indexOf(a.slot) - SLOTS.indexOf(b.slot) || b.rarity - a.rarity);
    const list = items.map(it => `<button class="item bord-${it.rarity}" data-act="pick" data-item="${it.id}" data-k="it-${it.id}" aria-pressed="${sheetSel === it.id}">
      <span><span class="iname rar-${it.rarity}">${it.locked ? '🔒 ' : ''}${esc(it.name)}</span><br><span class="isub">${SLOT_NAMES[it.slot]} · ${RARITIES[it.rarity].name} · iLvl ${it.L}</span></span><span class="isub">${compare(h, it)}</span></button>`).join('') || '<p class="usub">The pack is empty. Gear drops from chests, Treasure pockets, foes and rewards.</p>';
    let det = '';
    const selIt = G.pack.find(i => i.id === sheetSel);
    if (selIt) det = itemDetail(h, selIt, false);
    else if (sheetSel && typeof sheetSel === 'string' && h.gear[sheetSel]) det = itemDetail(h, h.gear[sheetSel], true);
    const st = heroStats(h);
    const sets = Object.keys(SETS).map(k => ({ k, n: setCount(h, k) })).filter(x => x.n).map(x => `${SETS[x.k].name} ${x.n}/5`).join(', ');
    const body = `<div class="lvl-head"><div class="tabs" role="group" aria-label="Hero">${tabs}</div>
      <div class="tabs" role="group" aria-label="Screen"><button class="btn small" data-act="level">Level up</button><button class="btn small" aria-pressed="true">Equipment</button></div></div>
      <div class="sheet">
        <div><div class="doll">${slotBtn('helm')}<div class="figure" aria-hidden="true">${HEROES[h.cls].icon}</div>${slotBtn('amulet')}
          ${slotBtn('weapon')}${slotBtn('chest')}${slotBtn('offhand')}
          ${slotBtn('gloves')}${slotBtn('legs')}${slotBtn('ring')}
          <div></div>${slotBtn('boots')}<div></div></div>
          <p class="usub">HP ${h.hp}/${st.maxHp} · AR ${st.ar} ${st.dmgType} · Crit ${st.crit}% · Def ${st.def} · Res ${st.res}${sets ? '<br>Sets: ' + esc(sets) : ''}</p>
          ${det}</div>
        <div class="pack"><div class="filters" role="group" aria-label="Filter pack">${filters}</div>${list}</div>
      </div>
      <div class="mrow"><button class="btn primary" data-act="close">Close</button></div>`;
    void dollHtml;
    const o = $('overlay');
    const modal = o.querySelector('.modal');
    if (modal && overlayKind === 'sheet') render(modal, `<h2>Character sheet</h2>${body}`);
    else open('sheet', `<h2>Character sheet</h2>${body}`);
  }

  function showEnd(win, legs, unlocked) {
    const s = G.stats;
    const ivs = (legs || []).map(it => `<li class="rar-4">${esc(it.name)}: ${esc(LEGENDARIES.find(l => l.id === it.legend).text)}</li>`).join('');
    open('end', `<h2>${win ? 'Paid in full!' : 'Evicted'}</h2>
      <p>${win ? 'The Landlord falls. The pub is yours.' : `Your party fell in ${esc(STAGES[G.stage - 1].name)}.`}</p>
      <div class="stats">
        <div><b>${s.points}</b>XP scored</div><div><b>${s.bestCombo}</b>Best combo</div><div><b>${s.dmg}</b>Damage dealt</div>
        <div><b>${s.pegs}</b>Pegs broken</div><div><b>${s.gear}</b>Gear found</div><div><b>${s.stages}</b>Stages cleared</div>
        <div><b>${s.kills}</b>Foes downed</div><div><b>${G.jokers.length}</b>Jokers: ${G.jokers.map(j => JOKERS[j].icon).join(' ') || '—'}</div>
      </div>
      ${ivs ? `<h3>The Landlord dropped</h3><ul>${ivs}</ul>` : ''}
      ${unlocked && unlocked.length ? `<p class="perk">Unlocked: ${unlocked.map(esc).join(', ')}.</p>` : ''}
      <p>Seed <b>${esc(G.seed)}</b>. Share it so a friend can race the same boards and rewards.</p>
      <div class="mrow"><button class="btn primary" data-act="new" data-autofocus>New run</button><button class="btn" data-act="sameseed">Same seed</button></div>`);
  }

  // ---------- Events ----------
  function onClick(e) {
    const t = e.target.closest('button, [data-act]');
    if (!t) return;
    Sound.init();
    const act = t.getAttribute('data-act');
    const h = G.heroes[G.selHero];
    if (t.dataset.foe) { if (G.phase !== 'resolve') { G.target = +t.dataset.foe; Sound.play('ui'); refresh(); } return; }
    if (t.dataset.hero != null && t.dataset.hero !== undefined && !act) { G.selHero = +t.dataset.hero; Sound.play('ui'); refresh(); return; }
    switch (act) {
      case 'plus': Game.buyLevel(h, t.dataset.attr, e.shiftKey ? 5 : 1); break;
      case 'minus': Game.refundLevel(h, t.dataset.attr); break;
      case 'confirm': Game.confirmLevels(); Sound.play('ui'); break;
      case 'cmd': setCmd(t.dataset.cmd); break;
      case 'sheet': sheetSel = null; overlayKind = overlayKind === 'level' ? 'sheet' : overlayKind; sheetView(); break;
      case 'level': overlayKind = overlayKind === 'sheet' ? 'level' : overlayKind; levelPreview = null; levelView(); break;
      case 'autolevel': Game.autoLevel(); break;
      case 'close': if (overlayKind === 'draft') { hideDraft(); } else closeAll(); refresh(); break;
      case 'new': {
        const seed = ($('seedIn') && $('seedIn').value) || '';
        const party = [...document.querySelectorAll('[data-party]')].map(s => s.value);
        const uniq = party.length === 3 && new Set(party).size === 3 ? party : null;
        const sj = $('startJoker') ? $('startJoker').checked : false;
        Game.newRun(seed, uniq, sj); break;
      }
      case 'sameseed': Game.newRun(G.seed, G.heroes.map(x => x.cls)); break;
      case 'continue': Game.resume(); break;
      case 'reward': Game.pickReward(+t.dataset.i, t.dataset.h != null ? +t.dataset.h : null); break;
      case 'hidedraft': hideDraft(); break;
      case 'selhero': G.selHero = +t.dataset.h; sheetSel = null; refresh(); break;
      case 'slot': sheetSel = t.dataset.slot; sheetView(); break;
      case 'pick': sheetSel = +t.dataset.item; sheetView(); break;
      case 'filter': sheetFilter = t.dataset.f; sheetView(); break;
      case 'equip': { const it = G.pack.find(i => i.id === +t.dataset.item); if (it) { Game.equip(h, it); sheetSel = null; sheetView(); } break; }
      case 'unequip': Game.unequip(h, t.dataset.slot); sheetSel = null; sheetView(); break;
      case 'salvage': { const it = G.pack.find(i => i.id === +t.dataset.item); if (it) { Game.salvage(it); sheetSel = null; sheetView(); } break; }
      case 'lock': { const it = G.pack.find(i => i.id === +t.dataset.item); if (it) { it.locked = !it.locked; Sound.play('ui'); sheetView(); } break; }
    }
  }
  function hideDraft() { G.draftHidden = true; closeAll(); document.body.classList.add('drafting'); refresh(); }
  function setCmd(c) {
    const h = G.heroes[G.selHero];
    if (!h || h.dead || !(G.phase === 'alloc' || G.phase === 'aim' || G.phase === 'draft')) return;
    if (c === 'skill' && !Battle.skillReady(h)) { Sound.play('deny'); return; }
    h.cmd = c; Sound.play('ui'); refresh();
  }

  function onInput(e) {
    const k = e.target.getAttribute('data-set'); if (!k) return;
    if (k === 'music' || k === 'sfx') Game.setSettings({ [k]: +e.target.value, [k === 'music' ? 'musicOn' : 'sfxOn']: true });
    if (k === 'mute') Game.setSettings({ sfxOn: !e.target.checked, musicOn: !e.target.checked });
    if (k === 'reducedMotion') Game.setSettings({ reducedMotion: e.target.checked });
    Sound.init(); refresh();
  }

  function onKey(e) {
    const tag = (e.target.tagName || '').toLowerCase();
    const typing = tag === 'input' || tag === 'select' || tag === 'textarea';
    if (e.key === 'Escape' && overlayKind) {
      if (overlayKind === 'draft') hideDraft();
      else if (overlayKind === 'title' && G.phase !== 'title') closeAll();
      else if (overlayKind === 'help' || overlayKind === 'sheet' || overlayKind === 'level') { closeAll(); refresh(); }
      return;
    }
    if (overlayKind || typing || !G || G.phase === 'title') return;
    if (G.phase === 'sink' && (e.key === ' ' || e.key === 'Enter')) { Board.skipReveal(); e.preventDefault(); return; }
    if (G.phase === 'aim') {
      if (e.key === 'ArrowLeft') { Board.nudgeAim(0.03); e.preventDefault(); return; }
      if (e.key === 'ArrowRight') { Board.nudgeAim(-0.03); e.preventDefault(); return; }
      if ((e.key === ' ' || e.key === 'Enter') && (tag === 'body' || tag === 'canvas' || tag === 'main')) { Board.fire(); e.preventDefault(); return; }
    }
    if (e.key === '1') setCmd('attack');
    if (e.key === '2') setCmd('skill');
    if (e.key === '3') setCmd('guard');
    if (e.key === 'c' || e.key === 'C') { sheetSel = null; sheetView(); }
    if (e.key === 'l' || e.key === 'L') { levelPreview = null; levelView(); }
  }

  function initTopbar() {
    $('btnSpeed').addEventListener('click', () => { G.speed = G.speed === 1 ? 2 : G.speed === 2 ? 4 : 1; refresh(); });
    $('btnSkip').addEventListener('click', () => { G.skipAnim = !G.skipAnim; refresh(); });
    $('btnSfx').addEventListener('click', () => { Sound.init(); Game.setSettings({ sfxOn: !Game.settings.sfxOn }); refresh(); });
    $('btnMusic').addEventListener('click', () => { Sound.init(); Game.setSettings({ musicOn: !Game.settings.musicOn }); refresh(); });
    $('btnHelp').addEventListener('click', showHelp);
    $('btnMenu').addEventListener('click', () => showTitle(G.phase !== 'title' && G.phase !== 'over'));
    $('btnAuto').addEventListener('click', () => Game.autoLevel());
    $('btnFight').addEventListener('click', () => { if (G.phase === 'draft') showDraft(); else Game.fight(); });
  }

  // ---------- Main loop ----------
  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (G && G.phase !== 'title') try {
      Board.update(dt); Board.draw(); Scene.update(dt); Scene.draw();
      if (G.phase === 'ball') hud();
      if (overlayKind === 'level') { const pc = document.querySelector('#overlay canvas.portrait'); if (pc) drawPortraits(pc.parentElement, now / 1000); }
    } catch (e) { console.error(e); }
    requestAnimationFrame(frame);
  }

  function boot() {
    Game.boot();
    Board.init($('board'));
    Scene.init($('scene'));
    document.addEventListener('mouseover', e => { const r = e.target.closest && e.target.closest('.lrow'); if (r) previewAttr(r.dataset.preview); });
    document.addEventListener('focusin', e => { const r = e.target.closest && e.target.closest('.lrow'); if (r) previewAttr(r.dataset.preview); });
    pegGuide();
    initTips(); initTopbar();
    document.addEventListener('click', onClick);
    document.addEventListener('input', onInput);
    document.addEventListener('change', onInput);
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', () => Sound.init(), { once: true });
    showTitle(false);
    requestAnimationFrame(frame);
  }

  return { log, hud, refresh, rebuild, pulseJoker, unitFx, unitAnim, pegTip, showDraft, showEnd, showTitle, closeAll, boot, newJoker: null };
})();

window.addEventListener('DOMContentLoaded', UI.boot);
