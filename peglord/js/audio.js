/* Every sound is synthesized with the Web Audio API. Silent until the first click. */
'use strict';

const Sound = (() => {
  let ctx = null, master, comp, sfxBus, musicBus, echoIn, noiseBuf;
  const prefs = { sfx: 0.7, music: 0.35, sfxOn: true, musicOn: true };
  let musicTimer = null, nextBeat = 0, beat = 0;

  function init() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -18; comp.knee.value = 12; comp.ratio.value = 4;
    comp.attack.value = 0.004; comp.release.value = 0.2;
    master = ctx.createGain(); master.gain.value = 0.9;
    comp.connect(master).connect(ctx.destination);
    sfxBus = ctx.createGain(); musicBus = ctx.createGain();
    sfxBus.connect(comp); musicBus.connect(comp);
    // Soft echo bus.
    echoIn = ctx.createGain(); echoIn.gain.value = 0.22;
    const delay = ctx.createDelay(1); delay.delayTime.value = 0.23;
    const fb = ctx.createGain(); fb.gain.value = 0.32;
    const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 2600;
    echoIn.connect(delay); delay.connect(lp); lp.connect(fb); fb.connect(delay); lp.connect(comp);
    noiseBuf = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    apply();
    startMusic();
  }

  function apply() {
    if (!ctx) return;
    sfxBus.gain.setTargetAtTime(prefs.sfxOn ? prefs.sfx : 0, ctx.currentTime, 0.02);
    musicBus.gain.setTargetAtTime(prefs.musicOn ? prefs.music * 0.9 : 0, ctx.currentTime, 0.05);
  }
  function set(p) { Object.assign(prefs, p); apply(); }

  const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
  const ok = () => ctx && prefs.sfxOn && prefs.sfx > 0;

  function tone(freq, { type = 'sine', dur = 0.15, vol = 0.3, at = 0, slide = 0, echo = 0.4, attack = 0.004, bus } = {}) {
    const t = ctx.currentTime + at;
    const o = ctx.createOscillator(), g = ctx.createGain();
    o.type = type; o.frequency.setValueAtTime(freq, t);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, freq * slide), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g); g.connect(bus || sfxBus);
    if (echo && !bus) { const e = ctx.createGain(); e.gain.value = echo; g.connect(e); e.connect(echoIn); }
    o.start(t); o.stop(t + dur + 0.05);
  }
  function noise({ dur = 0.2, vol = 0.3, at = 0, type = 'bandpass', freq = 1200, q = 1, to = 0, echo = 0.2 } = {}) {
    const t = ctx.currentTime + at;
    const s = ctx.createBufferSource(); s.buffer = noiseBuf;
    const f = ctx.createBiquadFilter(); f.type = type; f.frequency.setValueAtTime(freq, t); f.Q.value = q;
    if (to) f.frequency.exponentialRampToValueAtTime(to, t + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    s.connect(f); f.connect(g); g.connect(sfxBus);
    if (echo) { const e = ctx.createGain(); e.gain.value = echo; g.connect(e); e.connect(echoIn); }
    s.start(t, Math.random() * 0.5); s.stop(t + dur + 0.05);
  }

  // Sound effects.
  const fx = {
    peg(combo) {
      if (!ok()) return;
      const step = Math.min(24, combo);
      const k = Math.floor(step * 0.6);
      const m = 69 + 12 * Math.floor(k / 5) + PENTATONIC[k % 5];
      tone(mtof(m), { type: 'triangle', dur: 0.18, vol: 0.22 });
      tone(mtof(m + 12), { type: 'sine', dur: 0.08, vol: 0.06, echo: 0 });
    },
    gold(combo) {
      if (!ok()) return;
      const m = 81 + PENTATONIC[Math.min(24, combo) % 5];
      [1, 2.76, 5.4].forEach((r, i) => tone(mtof(m) * r, { type: 'sine', dur: 0.9 - i * 0.2, vol: 0.18 / (i + 1), echo: 0.6 }));
    },
    crate() { if (ok()) { noise({ dur: 0.12, vol: 0.4, freq: 500, q: 2 }); tone(140, { type: 'square', dur: 0.06, vol: 0.08, echo: 0 }); } },
    crateBreak() { if (ok()) { noise({ dur: 0.35, vol: 0.5, freq: 800, to: 200, q: 1 }); tone(90, { type: 'sawtooth', dur: 0.15, vol: 0.12, slide: 0.5 }); } },
    bomb() { if (ok()) { noise({ dur: 0.7, vol: 0.9, type: 'lowpass', freq: 1800, to: 80, q: 0.7, echo: 0.5 }); tone(70, { type: 'sine', dur: 0.5, vol: 0.6, slide: 0.4 }); } },
    glass() { if (ok()) { noise({ dur: 0.4, vol: 0.35, type: 'highpass', freq: 4000, q: 0.5, echo: 0.5 }); for (let i = 0; i < 4; i++) tone(2000 + Math.random() * 3000, { dur: 0.25, vol: 0.05, at: i * 0.03 }); } },
    bumper() { if (ok()) { tone(220, { type: 'square', dur: 0.12, vol: 0.15, slide: 2.5 }); } },
    heart() { if (ok()) { tone(mtof(72), { dur: 0.2, vol: 0.15 }); tone(mtof(79), { dur: 0.3, vol: 0.15, at: 0.08 }); } },
    star() { if (ok()) [0, 4, 7, 12].forEach((s, i) => tone(mtof(84 + s), { type: 'triangle', dur: 0.2, vol: 0.1, at: i * 0.04 })); },
    bolt() { if (ok()) { noise({ dur: 0.25, vol: 0.3, type: 'highpass', freq: 2500, q: 2 }); tone(900, { type: 'sawtooth', dur: 0.2, vol: 0.08, slide: 0.3 }); } },
    portal() { if (ok()) { tone(300, { type: 'sine', dur: 0.35, vol: 0.2, slide: 4, echo: 0.6 }); } },
    wall() { if (ok()) tone(180, { type: 'sine', dur: 0.04, vol: 0.05, echo: 0 }); },
    launch() { if (ok()) { tone(400, { type: 'triangle', dur: 0.15, vol: 0.15, slide: 0.5 }); noise({ dur: 0.1, vol: 0.15, freq: 2000 }); } },
    sink() { if (ok()) { tone(300, { type: 'sine', dur: 0.25, vol: 0.2, slide: 0.4 }); } },
    perk() { if (ok()) [0, 4, 7, 12].forEach((s, i) => tone(mtof(72 + s), { type: 'triangle', dur: 0.25, vol: 0.18, at: i * 0.08, echo: 0.5 })); },
    bad() { if (ok()) { tone(220, { type: 'sawtooth', dur: 0.45, vol: 0.15, slide: 0.45 }); tone(233, { type: 'square', dur: 0.45, vol: 0.06, slide: 0.45 }); } },
    multi(n) { if (ok()) { tone(mtof(72 + n * 2), { type: 'square', dur: 0.12, vol: 0.12 }); tone(mtof(79 + n * 2), { type: 'square', dur: 0.2, vol: 0.12, at: 0.07 }); } },
    joker() { if (ok()) [[0, 0.1], [4, 0.1], [7, 0.1], [12, 0.4]].forEach(([s, d], i) => { tone(mtof(67 + s), { type: 'square', dur: d + 0.05, vol: 0.1, at: i * 0.1 }); tone(mtof(55 + s), { type: 'triangle', dur: d + 0.05, vol: 0.12, at: i * 0.1 }); }); },
    slash() { if (ok()) noise({ dur: 0.18, vol: 0.5, freq: 3000, to: 600, q: 3 }); },
    zap() { if (ok()) { tone(1200, { type: 'sawtooth', dur: 0.25, vol: 0.1, slide: 0.2 }); noise({ dur: 0.2, vol: 0.2, type: 'highpass', freq: 3000 }); } },
    fire() { if (ok()) { noise({ dur: 0.5, vol: 0.5, type: 'lowpass', freq: 600, to: 3000, q: 1, echo: 0.4 }); tone(200, { type: 'sawtooth', dur: 0.4, vol: 0.1, slide: 0.5 }); } },
    crit() { if (ok()) [0, 7, 12, 19].forEach((s, i) => tone(mtof(88 + s), { dur: 0.15, vol: 0.08, at: i * 0.03, echo: 0.6 })); },
    hurt() { if (ok()) { tone(120, { type: 'sine', dur: 0.2, vol: 0.4, slide: 0.5 }); noise({ dur: 0.1, vol: 0.3, type: 'lowpass', freq: 400 }); } },
    clank() { if (ok()) { tone(1400, { type: 'square', dur: 0.08, vol: 0.08 }); tone(2100, { type: 'square', dur: 0.12, vol: 0.05 }); noise({ dur: 0.08, vol: 0.2, freq: 5000, q: 4 }); } },
    heal() { if (ok()) [0, 4, 7].forEach((s, i) => tone(mtof(79 + s), { dur: 0.4, vol: 0.12, at: i * 0.06, echo: 0.6 })); },
    kill() { if (ok()) { tone(mtof(67), { type: 'triangle', dur: 0.15, vol: 0.2 }); tone(mtof(60), { type: 'triangle', dur: 0.4, vol: 0.2, at: 0.12 }); } },
    levelup() { if (ok()) { tone(mtof(72), { type: 'triangle', dur: 0.1, vol: 0.15 }); tone(mtof(79), { type: 'triangle', dur: 0.2, vol: 0.15, at: 0.06 }); } },
    equip() { if (ok()) { noise({ dur: 0.08, vol: 0.2, freq: 2500, q: 3 }); tone(600, { type: 'square', dur: 0.06, vol: 0.06, at: 0.04 }); } },
    ui() { if (ok()) tone(880, { type: 'sine', dur: 0.05, vol: 0.08, echo: 0 }); },
    deny() { if (ok()) tone(160, { type: 'square', dur: 0.1, vol: 0.08 }); },
    win() { if (ok()) [0, 4, 7, 12, 16, 19, 24].forEach((s, i) => tone(mtof(60 + s), { type: 'triangle', dur: 0.4, vol: 0.14, at: i * 0.1, echo: 0.6 })); },
    lose() { if (ok()) [12, 7, 3, 0].forEach((s, i) => tone(mtof(52 + s), { type: 'sawtooth', dur: 0.5, vol: 0.1, at: i * 0.22 })); },
    flip() { if (ok()) noise({ dur: 0.12, vol: 0.25, freq: 1500, to: 600, q: 2 }); },
  };

  // ---------- Music: a tavern jig with lute, whistle, upright bass, pad and bodhran ----------
  let musicOut = null;
  function musicNode() {
    if (musicOut) return musicOut;
    const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 5200;
    lp.connect(musicBus);
    const send = ctx.createGain(); send.gain.value = 0.35; lp.connect(send); send.connect(echoIn);
    musicOut = lp; return lp;
  }
  function env(g, t, a, peak, d) { g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(peak, t + a); g.gain.exponentialRampToValueAtTime(0.0001, t + a + d); }
  function pluck(m, t, vol, dur = 0.7) {
    const f = mtof(m), out = musicNode();
    const o1 = ctx.createOscillator(), o2 = ctx.createOscillator(), lp = ctx.createBiquadFilter(), g = ctx.createGain();
    o1.type = 'sawtooth'; o2.type = 'square'; o1.frequency.value = f; o2.frequency.value = f * 1.003;
    lp.type = 'lowpass'; lp.Q.value = 2; lp.frequency.setValueAtTime(3200, t); lp.frequency.exponentialRampToValueAtTime(420, t + 0.25);
    const g2 = ctx.createGain(); g2.gain.value = 0.35;
    env(g, t, 0.004, vol, dur);
    o1.connect(lp); o2.connect(g2); g2.connect(lp); lp.connect(g); g.connect(out);
    o1.start(t); o2.start(t); o1.stop(t + dur + 0.1); o2.stop(t + dur + 0.1);
  }
  function whistle(m, t, dur, vol) {
    const f = mtof(m), out = musicNode();
    const o = ctx.createOscillator(), o2 = ctx.createOscillator(), g = ctx.createGain(), lfo = ctx.createOscillator(), lg = ctx.createGain();
    o.type = 'sine'; o2.type = 'triangle'; o.frequency.value = f; o2.frequency.value = f * 2;
    lfo.frequency.value = 5.6; lg.gain.setValueAtTime(0, t); lg.gain.linearRampToValueAtTime(f * 0.006, t + Math.min(0.25, dur));
    lfo.connect(lg); lg.connect(o.frequency);
    const h = ctx.createGain(); h.gain.value = 0.08; o2.connect(h); h.connect(g);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.035);
    g.gain.setValueAtTime(vol * 0.85, t + Math.max(0.05, dur - 0.06)); g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.08);
    o.connect(g); g.connect(out);
    [o, o2, lfo].forEach(x => { x.start(t); x.stop(t + dur + 0.15); });
    // breath
    const s = ctx.createBufferSource(); s.buffer = noiseBuf; const bp = ctx.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = f * 2; bp.Q.value = 3;
    const ng = ctx.createGain(); env(ng, t, 0.01, vol * 0.25, 0.08); s.connect(bp); bp.connect(ng); ng.connect(out); s.start(t, Math.random()); s.stop(t + 0.15);
  }
  function bass(m, t, vol) {
    const f = mtof(m), out = musicNode();
    const o = ctx.createOscillator(), o2 = ctx.createOscillator(), lp = ctx.createBiquadFilter(), g = ctx.createGain();
    o.type = 'triangle'; o2.type = 'sine'; o.frequency.value = f; o2.frequency.value = f;
    lp.type = 'lowpass'; lp.frequency.value = 700;
    env(g, t, 0.01, vol, 0.55);
    o.connect(lp); o2.connect(lp); lp.connect(g); g.connect(out);
    o.start(t); o2.start(t); o.stop(t + 0.7); o2.stop(t + 0.7);
  }
  function pad(notes, t, dur, vol) {
    const out = musicNode();
    const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 900; lp.Q.value = 0.5;
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.5); g.gain.setValueAtTime(vol, t + dur - 0.3); g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.4);
    lp.connect(g); g.connect(out);
    notes.forEach(m => [-6, 6].forEach(cents => {
      const o = ctx.createOscillator(); o.type = 'sawtooth'; o.frequency.value = mtof(m); o.detune.value = cents;
      o.connect(lp); o.start(t); o.stop(t + dur + 0.5);
    }));
  }
  function drum(t, kind, vol) {
    const out = musicNode();
    if (kind === 'kick') {
      const o = ctx.createOscillator(), g = ctx.createGain();
      o.frequency.setValueAtTime(120, t); o.frequency.exponentialRampToValueAtTime(48, t + 0.14);
      env(g, t, 0.003, vol, 0.22); o.connect(g); g.connect(out); o.start(t); o.stop(t + 0.3);
    } else {
      const s = ctx.createBufferSource(); s.buffer = noiseBuf; const f = ctx.createBiquadFilter(), g = ctx.createGain();
      if (kind === 'shaker') { f.type = 'highpass'; f.frequency.value = 7000; env(g, t, 0.004, vol, 0.05); }
      else { f.type = 'bandpass'; f.frequency.value = 260; f.Q.value = 1.5; env(g, t, 0.002, vol, 0.12); }
      s.connect(f); f.connect(g); g.connect(out); s.start(t, Math.random() * 0.5); s.stop(t + 0.2);
    }
  }

  let fight = false;
  function setMood(isFight) { fight = !!isFight; }
  function startMusic() {
    if (musicTimer) return;
    nextBeat = ctx.currentTime + 0.3;
    musicTimer = setInterval(schedule, 50);
  }
  function schedule() {
    while (nextBeat < ctx.currentTime + 0.3) {
      const step = beat % 6, barIdx = Math.floor(beat / 6) % MUSIC.bars.length, loop = Math.floor(beat / (6 * MUSIC.bars.length));
      const len = fight ? MUSIC.fightEighth : MUSIC.eighth;
      const t = nextBeat;
      if (prefs.musicOn && prefs.music > 0) {
        const chord = MUSIC.chords[MUSIC.bars[barIdx]];
        // Upright bass: root on 1, fifth on 4.
        if (step === 0) bass(chord[0] - 12, t, 0.32);
        if (step === 3) bass(chord[0] - 5, t, 0.24);
        // Lute: chord tones on the off-beats.
        if (step !== 0 && step !== 3) pluck(chord[[0, 1, 2, 0, 2, 1][step]] + 12, t, step === 1 || step === 4 ? 0.07 : 0.05, 0.35);
        if (step === 0 && loop % 2 === 1) pad(chord, t, len * 6, 0.022);
        // Bodhran and shaker.
        if (step === 0 || step === 3) drum(t, 'kick', step === 0 ? 0.35 : 0.22);
        if (step === 2 || step === 5) drum(t, 'tap', 0.18);
        drum(t, 'shaker', step % 3 === 0 ? 0.05 : 0.025);
        if (fight && step % 3 === 1) drum(t, 'tap', 0.12);
        // Melody: whistle on even loops, lute an octave down on odd loops.
        const note = MUSIC.melody[barIdx][step];
        if (note != null) {
          let hold = 1; while (step + hold < 6 && MUSIC.melody[barIdx][step + hold] === null) hold++;
          if (loop % 2 === 0) whistle(note, t, hold * len * 0.95, 0.075);
          else pluck(note, t, 0.09, 0.3 + hold * len);
        }
      }
      nextBeat += len; beat++;
    }
  }

  function play(name, ...args) { if (ctx && fx[name]) { try { fx[name](...args); } catch (e) { /* audio is best effort */ } } }
  return { init, play, set, prefs, setMood };
})();
