"""Second-stage backtest: supremacy/total split, Dixon-Coles rho, market blend, calibration."""
import json, pickle, numpy as np
from model import score_matrix, markets
from backtest import run, score
from odds_util import market_probs

res = pickle.load(open('bt_grid.pkl', 'rb'))
extra = {}
for cfg in [(150, 1.0, 6.0), (150, 1.0, 10.0), (150, 0.8, 10.0), (240, 1.0, 10.0), (100, 0.8, 1.5), (100, 0.8, 6.0)]:
    hl, xw, rg = cfg
    preds = run(dict(half_life=hl, xg_w=xw, ridge=rg))
    res[cfg] = (score(preds), preds)
    print(cfg, {k: round(float(v), 5) for k, v in res[cfg][0].items()}, flush=True)
pickle.dump(res, open('bt_grid2.pkl', 'wb'))

def best(key, lower=True):
    return sorted(res, key=lambda c: res[c][0][key])[0]

print('best o25', best('o25'), 'best btts', best('btts'), 'best rps', best('1x2_rps'), 'best ll', best('1x2_ll'))
S_cfg, T_cfg = best('1x2_rps'), best('o25')
S = {p['id']: p for p in res[S_cfg][1]}
T = {p['id']: p for p in res[T_cfg][1]}
odds = json.load(open('odds.json'))
ids = [i for i in S if i in T and str(i) in odds]
mk = {i: market_probs(odds[str(i)]) for i in ids}
ids = [i for i in ids if all(k in mk[i] for k in ('home', 'o25', 'o35', 'btts'))]
print('common n', len(ids))

def combined(i, rho):
    s, t = S[i], T[i]
    tot = t['lh'] + t['la']
    lh = tot * s['lh'] / (s['lh'] + s['la']); la = tot - lh
    return dict(markets(score_matrix(lh, la, rho)), lh=lh, la=la, hg=s['hg'], ag=s['ag'], id=i)

def metrics(P):
    return score(P)

for rho in (-0.12, -0.08, -0.05, -0.02, 0.0):
    P = [combined(i, rho) for i in ids]
    print('combined rho', rho, {k: round(float(v), 5) for k, v in metrics(P).items()})
rho = -0.05
P = {i: combined(i, rho) for i in ids}
Mk = [dict(mk[i], hg=S[i]['hg'], ag=S[i]['ag']) for i in ids]
print('market', {k: round(float(v), 5) for k, v in metrics(Mk).items()})
blend_res = {}
for a in (0.0, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0):
    B = []
    for i in ids:
        q = {k: a * P[i][k] + (1 - a) * mk[i][k] for k in ('home', 'draw', 'away', 'o25', 'o35', 'btts')}
        q.update(hg=S[i]['hg'], ag=S[i]['ag']); B.append(q)
    blend_res[a] = metrics(B)
    print('blend model weight', a, {k: round(float(v), 5) for k, v in blend_res[a].items()})

# calibration of model-only and 40% blend
def calib(pred_list, key, outcome):
    bins = [0, .2, .3, .4, .5, .6, .7, .8, .9, 1.01]
    p = np.array([q[key] for q in pred_list]); y = np.array([outcome(q) for q in pred_list], float)
    rows = []
    for lo, hi in zip(bins[:-1], bins[1:]):
        s = (p >= lo) & (p < hi)
        if s.sum() >= 10:
            rows.append((f'{lo:.1f}-{min(hi,1):.1f}', int(s.sum()), round(float(p[s].mean()), 3), round(float(y[s].mean()), 3)))
    return rows
outc = dict(o25=lambda q: q['hg'] + q['ag'] >= 3, o35=lambda q: q['hg'] + q['ag'] >= 4, btts=lambda q: q['hg'] > 0 and q['ag'] > 0,
            home=lambda q: q['hg'] > q['ag'], away=lambda q: q['hg'] < q['ag'], draw=lambda q: q['hg'] == q['ag'])
Pl = list(P.values())
cal = {}
for k, f in outc.items():
    cal[k] = calib(Pl, k, f)
    print('CALIB model', k, cal[k])
json.dump(dict(S_cfg=S_cfg, T_cfg=T_cfg, rho=rho, n=len(ids), grid={str(c): {k: float(v) for k, v in res[c][0].items()} for c in res},
               market={k: float(v) for k, v in metrics(Mk).items()}, blends={str(a): {k: float(v) for k, v in b.items()} for a, b in blend_res.items()},
               combined={k: float(v) for k, v in metrics(Pl).items()}, calib=cal), open('bt_summary.json', 'w'), indent=1)
