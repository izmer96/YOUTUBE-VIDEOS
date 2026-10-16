import json, pickle, numpy as np
from model import score_matrix, markets
from backtest import score
from odds_util import market_probs
from coherent import fit_dc
res = pickle.load(open('bt_grid2.pkl', 'rb')); sm = json.load(open('bt_summary.json'))
S = {p['id']: p for p in res[tuple(sm['S_cfg'])][1]}; T = {p['id']: p for p in res[tuple(sm['T_cfg'])][1]}
odds = json.load(open('odds.json'))
ids = [i for i in S if i in T and str(i) in odds]
mk = {i: market_probs(odds[str(i)]) for i in ids}
ids = [i for i in ids if all(k in mk[i] for k in ('home', 'o25', 'o35', 'btts'))]
B, C, rmse = [], [], []
for i in ids:
    s, t = S[i], T[i]; tot = t['lh'] + t['la']; lh = tot * s['lh'] / (s['lh'] + s['la'])
    mod = markets(score_matrix(lh, tot - lh, -0.05))
    tgt = {k: 0.25 * mod[k] + 0.75 * mk[i][k] for k in ('home', 'draw', 'away', 'o25', 'o35', 'btts')}
    B.append(dict(tgt, hg=s['hg'], ag=s['ag']))
    a, b, rho, P, e = fit_dc(tgt, lh, tot - lh)
    C.append(dict(markets(P), hg=s['hg'], ag=s['ag'])); rmse.append(e)
print('n', len(ids))
print('blend      ', {k: round(float(v), 5) for k, v in score(B).items()})
print('coherent DC', {k: round(float(v), 5) for k, v in score(C).items()})
print('fit rmse pts: mean', round(100 * np.mean(rmse), 2), 'p95', round(100 * np.percentile(rmse, 95), 2), 'max', round(100 * max(rmse), 2))
