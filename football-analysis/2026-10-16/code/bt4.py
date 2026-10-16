import json, pickle, numpy as np, datetime
from model import score_matrix, markets
from backtest import score
from odds_util import market_probs
res = pickle.load(open('bt_grid2.pkl', 'rb'))
sm = json.load(open('bt_summary.json'))
S = {p['id']: p for p in res[tuple(sm['S_cfg'])][1]}; T = {p['id']: p for p in res[tuple(sm['T_cfg'])][1]}
odds = json.load(open('odds.json'))
ids = [i for i in S if i in T]
TBAR = 2.7
def lam(i, k, j):
    s, t = S[i], T[i]
    tot = t['lh'] + t['la']; r = np.log(s['lh'] / s['la'])
    r2 = k * r; tot2 = np.exp(np.log(TBAR) + j * (np.log(tot) - np.log(TBAR)))
    lh = tot2 * np.exp(r2) / (1 + np.exp(r2)); return lh, tot2 - lh
def preds(k, j, sub):
    out = []
    for i in sub:
        lh, la = lam(i, k, j)
        out.append(dict(markets(score_matrix(lh, la, -0.05)), hg=S[i]['hg'], ag=S[i]['ag'], id=i))
    return out
# split in time: fit stretch on first half of evaluation weeks (early season + Jan-Feb), validate on Mar-May
cut = datetime.datetime(2026, 3, 1).timestamp()
fit_ids = [i for i in ids if S[i]['ts'] < cut]; val_ids = [i for i in ids if S[i]['ts'] >= cut]
print('fit n', len(fit_ids), 'val n', len(val_ids))
best = {}
for k in (1.0, 1.05, 1.1, 1.15, 1.2, 1.3):
    for j in (1.0, 1.25, 1.5, 1.75, 2.0, 2.5):
        s = score(preds(k, j, fit_ids))
        best[(k, j)] = s
kb = min(best, key=lambda c: best[c]['1x2_rps']); jb = min(best, key=lambda c: best[c]['o25'] + best[c]['btts'] + best[c]['o35'])
print('best k (rps) on fit', kb, best[kb]['1x2_rps'], ' best j (totals) on fit', jb, best[jb]['o25'], best[jb]['btts'], best[jb]['o35'])
K, J = kb[0], jb[1]
print('chosen k', K, 'j', J)
for name, sub in (('fit', fit_ids), ('validation', val_ids), ('all', ids)):
    s0 = score(preds(1.0, 1.0, sub)); s1 = score(preds(K, J, sub))
    print(name, 'raw  ', {k: round(float(v), 5) for k, v in s0.items()})
    print(name, 'stretch', {k: round(float(v), 5) for k, v in s1.items()})
# blends with market on all, using stretched model
mk = {i: market_probs(odds[str(i)]) for i in ids if str(i) in odds}
ok = [i for i in ids if i in mk and all(x in mk[i] for x in ('home', 'o25', 'o35', 'btts'))]
P = {p['id']: p for p in preds(K, J, ok)}
for a in (0.0, 0.25, 0.5, 1.0):
    B = [dict({x: a * P[i][x] + (1 - a) * mk[i][x] for x in ('home', 'draw', 'away', 'o25', 'o35', 'btts')}, hg=S[i]['hg'], ag=S[i]['ag']) for i in ok]
    print('blend w', a, {k: round(float(v), 5) for k, v in score(B).items()})
# calibration of stretched model
def calib(pl, key, f):
    bins = [0, .2, .3, .4, .5, .6, .7, .8, .9, 1.01]
    p = np.array([q[key] for q in pl]); y = np.array([f(q) for q in pl], float); rows = []
    for lo, hi in zip(bins[:-1], bins[1:]):
        s = (p >= lo) & (p < hi)
        if s.sum() >= 10: rows.append((f'{lo:.1f}-{min(hi,1):.1f}', int(s.sum()), round(float(p[s].mean()), 3), round(float(y[s].mean()), 3)))
    return rows
PL = preds(K, J, ids)
outc = dict(o25=lambda q: q['hg'] + q['ag'] >= 3, o35=lambda q: q['hg'] + q['ag'] >= 4, btts=lambda q: q['hg'] > 0 and q['ag'] > 0,
            home=lambda q: q['hg'] > q['ag'], draw=lambda q: q['hg'] == q['ag'], away=lambda q: q['hg'] < q['ag'])
cal = {k: calib(PL, k, f) for k, f in outc.items()}
for k, v in cal.items(): print('CAL', k, v)
sm.update(stretch_k=K, stretch_j=J, calib_stretched=cal, stretch_scores={'raw': {k: float(v) for k, v in score(preds(1, 1, ids)).items()}, 'stretched': {k: float(v) for k, v in score(PL).items()}},
          stretch_val={'raw': {k: float(v) for k, v in score(preds(1, 1, val_ids)).items()}, 'stretched': {k: float(v) for k, v in score(preds(K, J, val_ids)).items()}, 'n': len(val_ids)})
json.dump(sm, open('bt_summary.json', 'w'), indent=1)
