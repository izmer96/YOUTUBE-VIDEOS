import json
A = json.load(open('analysis.json'))
R = A['results']
TOP_LEAGUE_GRPS = {'L17', 'L8', 'L23', 'L34', 'L35', 'L52', 'L37', 'L38', 'L238', 'L18', 'L54', 'L53', 'L182', 'L44', 'L98'}
MK = {'o25': 'Over 2.5', 'o35': 'Over 3.5', 'btts': 'BTTS Yes', 'home': 'Home Win', 'away': 'Away Win'}
def reliability(r, k):
    issues = []
    mk = r['market']; mod = r['model']
    if k in mk:
        gap = abs(mod[k] - mk[k])
        if gap > 0.10: issues.append(('major', f'model and market differ by {gap*100:.0f} pts'))
        elif gap > 0.05: issues.append(('minor', f'model and market differ by {gap*100:.0f} pts'))
    else:
        issues.append(('minor', 'no market price yet (model-only)'))
    for side in ('home', 'away'):
        t = r[side]; p = t['prof']['all']
        cov = p.get('xg_n', 0) / max(p['n'], 1)
        if cov < 0.5: issues.append(('minor', f"{t['name']}: xG for only {p.get('xg_n',0)}/{p['n']} matches"))
        if p['n'] < 6: issues.append(('minor', f"{t['name']}: only {p['n']} matches this season"))
        if t['grp'] not in TOP_LEAGUE_GRPS and p.get('xg_n', 0) < 6: issues.append(('minor', f"{t['name']}: thin cross-league evidence"))
        reg_out = [x for x in t['absent'] if x['regular'] and x['status'] == 'missing']
        if len(reg_out) >= 3: issues.append(('minor', f"{t['name']}: {len(reg_out)} regular starters out"))
        mg = t['mgr']
        if mg['changes'] and mg['n_current'] <= 2 and mg['changes'][-1]['new'] not in [c['old'] for c in mg['changes']]:
            issues.append(('minor', f"{t['name']}: new coach ({mg['current']}, {mg['n_current']} match(es))"))
    maj = sum(1 for s, _ in issues if s == 'major'); mnr = sum(1 for s, _ in issues if s == 'minor')
    level = 'High' if maj == 0 and mnr == 0 else ('Medium' if maj == 0 and mnr <= 2 else 'Low')
    return level, [m for _, m in issues]
rows = []
for i, r in enumerate(R):
    f = r['fixture']
    for k in MK:
        lvl, iss = reliability(r, k)
        rows.append(dict(idx=i, fixture=f"{f['home']} vs {f['away']}", comp=f['comp'], market=k, label=MK[k], p=r['final'][k],
                         model=r['model'][k], mkt=r['market'].get(k), rel=lvl, issues=iss))
json.dump(rows, open('ranked_rows.json', 'w'))
rows.sort(key=lambda x: -x['p'])
seen = {}
for n, x in enumerate(rows[:45]):
    corr = seen.get(x['idx']); seen.setdefault(x['idx'], n + 1)
    print(f"{n+1:2d} {x['fixture'][:45]:45s} {x['comp']:9s} {x['label']:9s} {x['p']*100:5.1f}  model {x['model']*100:5.1f} mkt {'' if x['mkt'] is None else round(x['mkt']*100,1)!s:5s} {x['rel']:6s} {'corr#'+str(corr) if corr else ''} {'; '.join(x['issues'])[:90]}")
