"""Data-driven text for counterarguments, comparable-opponent verdicts, tactical profiles and weak-evidence flags."""
import json, numpy as np

def pct(x):
    return f"{x*100:.0f}%"

def comp_summary(comps):
    if not comps:
        return None
    gf = np.array([c['gf'] for c in comps]); ga = np.array([c['ga'] for c in comps])
    return dict(n=len(comps), w=int((gf > ga).sum()), d=int((gf == ga).sum()), l=int((gf < ga).sum()),
                gf=float(gf.mean()), ga=float(ga.mean()), o25=float(((gf + ga) >= 3).mean()), o35=float(((gf + ga) >= 4).mean()),
                btts=float(((gf > 0) & (ga > 0)).mean()), scored=float((gf > 0).mean()))

def comp_verdict(fx, market):
    """Does comparable-opponent evidence support the selection?"""
    h = comp_summary(fx['teams']['home']['comps']); a = comp_summary(fx['teams']['away']['comps'])
    hn, an = fx['teams']['home']['name'], fx['teams']['away']['name']
    parts, score = [], 0
    if market in ('o25', 'o35', 'btts'):
        key = market
        for nm, s in ((hn, h), (an, a)):
            if s:
                rate = s[key]
                parts.append(f"{nm}: {rate*100:.0f}% of {s['n']} comparable games")
                score += (rate - 0.5) * s['n']
    elif market == 'home':
        if h:
            parts.append(f"{hn} v opponents like {an}: {h['w']}-{h['d']}-{h['l']}")
            score += (h['w'] / h['n'] - 0.45) * h['n']
        if a:
            parts.append(f"{an} v opponents like {hn}: {a['w']}-{a['d']}-{a['l']}")
            score += (a['l'] / a['n'] - 0.45) * a['n']
    else:
        if a:
            parts.append(f"{an} v opponents like {hn}: {a['w']}-{a['d']}-{a['l']}")
            score += (a['w'] / a['n'] - 0.45) * a['n']
        if h:
            parts.append(f"{hn} v opponents like {an}: {h['w']}-{h['d']}-{h['l']}")
            score += (h['l'] / h['n'] - 0.45) * h['n']
    if not parts:
        return dict(text='No sufficiently comparable opponents in either sample; uncertainty is higher.', verdict='none')
    verdict = 'supports' if score > 0.5 else ('contradicts' if score < -0.5 else 'mixed')
    return dict(text='; '.join(parts), verdict=verdict)

def counter(fx, market):
    """Rank candidate counterarguments by strength and return the top two sentences."""
    T = fx['teams']; h, a = T['home'], T['away']
    hs, as_ = h['splits'], a['splits']
    fin, mod, mkt = fx['final'], fx['model'], fx.get('market') or {}
    cands = []
    def add(strength, text):
        cands.append((strength, text))
    if mkt and market in mkt:
        gap = mod[market] - mkt[market]
        if gap < -0.05:
            add(abs(gap) * 10, f"My model alone gives only {pct(mod[market])}; the higher final figure leans on the market ({pct(mkt[market])}).")
        elif gap > 0.05:
            add(abs(gap) * 8, f"The market ({pct(mkt[market])}) is less confident than the model ({pct(mod[market])}).")
    if not fx['has_market']:
        add(0.4, 'No bookmaker price has been published yet, so this is a model-only estimate.')
    for side, t, venue in (('home', h, 'home'), ('away', a, 'away')):
        nxt = t['rest'].get('next_days'); nm = t['rest'].get('next_match') or ''
        if nxt is not None and nxt <= 3.5 and any(x in nm for x in ('Champions League', 'Europa', 'Conference')):
            fav = (market == 'home' and side == 'home') or (market == 'away' and side == 'away') or market in ('o25', 'o35', 'btts')
            if fav:
                add(0.6, f"{t['name']} play again {nxt:.0f} days later ({nm.split(' (')[0]}), so rotation is possible.")
        reg = [x for x in t['absent'] if x['regular'] and x['status'] == 'missing']
        if reg and ((market == 'home' and side == 'home') or (market == 'away' and side == 'away') or market in ('o25', 'o35', 'btts')):
            names = ', '.join(f"{x['name']} ({x['min_share']*100:.0f}% of minutes)" for x in reg[:3])
            add(0.5 + 0.2 * len(reg), f"{t['name']} are without {names}.")
        cc = t.get('coach_change')
        if cc and cc['matches'] <= 2:
            add(0.5, f"{t['name']} have a new coach ({cc['coach']}, {cc['matches']} match(es) in charge), which makes past data less reliable.")
    if market in ('o25', 'o35'):
        hh = hs.get('home') or {}; aa = as_.get('away') or {}
        key = market
        for t, sp, lbl in ((h, hh, 'home'), (a, aa, 'away')):
            if sp and sp.get('n', 0) >= 3 and sp[key] <= 0.4:
                add(1.0 - sp[key], f"{t['name']}'s {lbl} games went over {'2.5' if key == 'o25' else '3.5'} in only {round(sp[key]*sp['n'])} of {sp['n']}.")
        blank = max(1 - fx['p_h_scores'], 1 - fx['p_a_scores'])
        who = h['name'] if 1 - fx['p_h_scores'] > 1 - fx['p_a_scores'] else a['name']
        if blank > 0.3:
            add(blank * 1.5, f"{who} fail to score {pct(blank)} of the time in the final distribution, and then the other side must score {'three' if market == 'o25' else 'four'} alone.")
        w = fx.get('weather') or {}
        if (w.get('precip') or 0) >= (2 if w.get('nxt') == '1h' else 8) or (w.get('wind') or 0) >= 8:
            add(0.3, f"The forecast at kickoff is poor ({w.get('precip')} mm rain over {w.get('nxt')}, wind {w.get('wind')} m/s); the evidence that this suppresses goals is weak.")
    if market == 'btts':
        hh = hs.get('home') or {}; aa = as_.get('away') or {}
        for t, sp, lbl in ((h, hh, 'home'), (a, aa, 'away')):
            if sp and sp.get('n', 0) >= 3 and sp['cs'] >= 0.5:
                add(sp['cs'] * 1.6, f"{t['name']} kept clean sheets in {round(sp['cs']*sp['n'])} of {sp['n']} {lbl} games.")
            if sp and sp.get('n', 0) >= 3 and sp['fts'] >= 0.3:
                add(sp['fts'] * 1.6, f"{t['name']} failed to score in {round(sp['fts']*sp['n'])} of {sp['n']} {lbl} games.")
        low = min(fx['p_h_scores'], fx['p_a_scores'])
        who = h['name'] if fx['p_h_scores'] < fx['p_a_scores'] else a['name']
        add((1 - low) * 1.2, f"Even in the final distribution {who} fail to score {pct(1-low)} of the time.")
    if market in ('home', 'away'):
        fav, dog = (h, a) if market == 'home' else (a, h)
        add(fin['draw'] * 2.5, f"The draw still carries {pct(fin['draw'])}.")
        dsp = (as_ if market == 'home' else hs).get('away' if market == 'home' else 'home') or {}
        if dsp and dsp.get('n', 0) >= 3 and (dsp['w'] + dsp['d']) / dsp['n'] >= 0.6:
            add(0.7, f"{dog['name']} are {dsp['w']}-{dsp['d']}-{dsp['l']} in {'away' if market == 'home' else 'home'} games this season.")
        cs = comp_summary(dog['comps'])
        if cs and cs['w'] + cs['d'] >= 1:
            add(0.4 + 0.2 * (cs['w'] + cs['d']), f"{dog['name']} took points in {cs['w'] + cs['d']} of {cs['n']} games against opponents comparable to {fav['name']}.")
        fsp = (hs if market == 'home' else as_).get('home' if market == 'home' else 'away') or {}
        if fsp and fsp.get('n', 0) >= 3 and fsp['w'] / fsp['n'] < 0.5:
            add(0.8, f"{fav['name']} won only {fsp['w']} of {fsp['n']} {'home' if market == 'home' else 'away'} games.")
    cands.sort(key=lambda x: -x[0])
    seen, outl = set(), []
    for s, t in cands:
        if t not in seen:
            outl.append(t); seen.add(t)
        if len(outl) == 2:
            break
    return ' '.join(outl) if outl else 'No strong data-driven counterargument found; the main risk is ordinary match variance.'

def tactical(fx, xg_base):
    """Data-derived style profile; no claims beyond the recorded match statistics."""
    T = fx['teams']; out = []
    for side in ('home', 'away'):
        t = T[side]; a = t['splits']['all'] or {}
        bits = []
        if a.get('posf_pg') is not None:
            bits.append(f"{a['posf_pg']:.0f}% average possession")
        if a.get('shf_pg') is not None:
            bits.append(f"{a['shf_pg']:.1f} shots for / {a['sha_pg']:.1f} against")
        if a.get('xgf_pg') is not None:
            bits.append(f"match xG tempo {a['xgf_pg'] + a['xga_pg']:.2f} per game")
        if a.get('bcf_pg') is not None and a.get('bca_pg') is not None:
            bits.append(f"big chances {a['bcf_pg']:.1f} created / {a['bca_pg']:.1f} conceded")
        if bits:
            out.append(f"{t['name']}: " + ', '.join(bits) + '.')
    tempo = [T[s]['splits']['all'].get('xgf_pg', 0) + T[s]['splits']['all'].get('xga_pg', 0) for s in ('home', 'away') if T[s]['splits']['all'] and T[s]['splits']['all'].get('xgf_pg') is not None]
    if len(tempo) == 2 and xg_base:
        avg = np.mean(tempo)
        rel = 'above' if avg > xg_base * 1.08 else ('below' if avg < xg_base * 0.92 else 'close to')
        out.append(f"Combined, these teams' matches average {avg:.2f} total xG, {rel} the competition norm of {xg_base:.2f}.")
    lh, la = fx['lam_final']
    shape = 'one-sided' if max(lh, la) > 2 * min(lh, la) and max(lh, la) > 1.9 else ('open, high-scoring' if lh + la > 3.2 else ('controlled, lower-scoring' if lh + la < 2.4 else 'competitive'))
    out.append(f"Projected shape: {shape} (expected goals {lh:.2f} v {la:.2f}).")
    return ' '.join(out)

def weak_flags(fx):
    T = fx['teams']; fin, mod, mkt = fx['final'], fx['model'], fx.get('market') or {}
    flags = []
    best = max(fin[k] for k in ('o25', 'o35', 'btts', 'home', 'away'))
    if fin['o25'] < 0.45:
        flags.append(('Low scoring expectations', f"Over 2.5 only {pct(fin['o25'])}; expected goals {fx['lam_final'][0]:.2f} v {fx['lam_final'][1]:.2f}."))
    if fin['draw'] >= 0.27 and max(fin['home'], fin['away']) < 0.47:
        flags.append(('Balanced teams, high draw probability', f"Home {pct(fin['home'])}, draw {pct(fin['draw'])}, away {pct(fin['away'])}."))
    gaps = [(k, mod[k] - mkt[k]) for k in ('home', 'away', 'o25', 'btts') if k in mkt and abs(mod[k] - mkt[k]) > 0.10]
    if gaps:
        lab = {'home': 'home win', 'away': 'away win', 'o25': 'over 2.5', 'btts': 'BTTS'}
        flags.append(('Model and market disagree', '; '.join(f"{lab[k]}: model {pct(mod[k])} v market {pct(mkt[k])}" for k, g in gaps) + '.'))
    for side in ('home', 'away'):
        t = T[side]; a = t['splits']['all']
        reg = [x for x in t['absent'] if x['regular'] and x['status'] == 'missing']
        if t['att_mult'] <= 0.93 or len(reg) >= 3:
            flags.append(('Injuries and team news', f"{t['name']}: {len(reg)} regular(s) out ({', '.join(x['name'] for x in reg[:4])}); attack adjusted ×{t['att_mult']:.2f}."))
        if t.get('coach_change') and t['coach_change']['matches'] <= 2:
            flags.append(('Tactical uncertainty (new coach)', f"{t['name']}: {t['coach_change']['coach']} replaced {t['coach_change']['previous']} on {t['coach_change']['since']} ({t['coach_change']['matches']} match(es))."))
        if a['n'] < 7:
            flags.append(('Small sample', f"{t['name']}: {a['n']} matches this season."))
        if (a.get('xg_n') or 0) < 0.5 * a['n']:
            flags.append(('Unavailable reliable statistics', f"{t['name']}: xG for {a.get('xg_n') or 0} of {a['n']} matches."))
    hh = T['home']['splits'].get('home') or {}; aa = T['away']['splits'].get('away') or {}
    if fin['btts'] >= 0.58 and hh.get('n', 0) >= 4 and aa.get('n', 0) >= 4 and hh['btts'] <= 0.35 and aa['btts'] <= 0.35:
        flags.append(('Inconsistent home/away evidence', f"BTTS {pct(fin['btts'])} overall, but BTTS in only {pct(hh['btts'])} of {T['home']['name']} home games and {pct(aa['btts'])} of {T['away']['name']} away games."))
    if fx['comp'] in ('UCL', 'UEL', 'UECL'):
        for side in ('home', 'away'):
            t = T[side]
            if not t['comps']:
                flags.append(('Opponent-quality differences', f"{t['name']}: no comparable opponents in the sample, so the cross-league rating is untested."))
    if not fx['has_market']:
        flags.append(('No market cross-check', 'Bookmaker prices were not yet published; model-only.'))
    return best, flags
