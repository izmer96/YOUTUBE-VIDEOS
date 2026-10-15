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
    musicBus.gain.setTargetAtTime(prefs.musicOn ? prefs.music * 0.5 : 0, ctx.currentTime, 0.05);
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
      const m = 64 + 12 * Math.floor(step / 5) + PENTATONIC[step % 5];
      tone(mtof(m), { type: 'triangle', dur: 0.18, vol: 0.22 });
      tone(mtof(m + 12), { type: 'sine', dur: 0.08, vol: 0.06, echo: 0 });
    },
    gold(combo) {
      if (!ok()) return;
      const m = 76 + PENTATONIC[Math.min(24, combo) % 5];
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

  // Quiet looping chord arpeggio: Am, F, G, Em with a bass note.
  function startMusic() {
    if (musicTimer) return;
    nextBeat = ctx.currentTime + 0.2;
    musicTimer = setInterval(schedule, 60);
  }
  function schedule() {
    const spb = 0.3;
    while (nextBeat < ctx.currentTime + 0.25) {
      const bar = Math.floor(beat / 8) % 4, step = beat % 8;
      const chord = MUSIC_CHORDS[bar];
      const at = nextBeat - ctx.currentTime;
      if (prefs.musicOn && prefs.music > 0) {
        const pattern = [0, 1, 2, 1, 0, 1, 2, 1];
        const note = chord[pattern[step]] + (step >= 4 ? 12 : 0);
        tone(mtof(note), { type: 'triangle', dur: 0.32, vol: 0.12, at, bus: musicBus, attack: 0.01 });
        if (step === 0) tone(mtof(chord[0] - 24), { type: 'sine', dur: 2.2, vol: 0.25, at, bus: musicBus, attack: 0.05 });
        if (step === 4) tone(mtof(chord[0] - 17), { type: 'sine', dur: 1.0, vol: 0.12, at, bus: musicBus, attack: 0.05 });
      }
      nextBeat += spb; beat++;
    }
  }

  function play(name, ...args) { if (ctx && fx[name]) { try { fx[name](...args); } catch (e) { /* audio is best effort */ } } }
  return { init, play, set, prefs };
})();
