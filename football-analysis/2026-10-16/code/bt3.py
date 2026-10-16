import json, pickle, numpy as np, datetime
from model import score_matrix, markets
from backtest import score
from odds_util import market_probs
res = pickle.load(open('bt_grid2.pkl', 'rb'))
sm = json.load(open('bt_summary.json'))
S_cfg, T_cfg = tuple(sm['S_cfg']), tuple(sm['T_cfg'])
S = {p['id']: p for p in res[S_cfg][1]}; T = {p['id']: p for p in res[T_cfg][1]}
odds = json.load(open('odds.json'))
def comb(i, rho=-0.05):
    s, t = S[i], T[i]; tot = t['lh'] + t['la']; lh = tot * s['lh'] / (s['lh'] + s['la'])
    return dict(markets(score_matrix(lh, tot - lh, rho)), hg=s['hg'], ag=s['ag'], ut=s['ut'], ts=s['ts'])
ids = [i for i in S if i in T and str(i) in odds]
P = {i: comb(i) for i in ids}
for label, use in (('closing', 'fractionalValue'), ('opening', 'initialFractionalValue')):
    mk = {i: market_probs(odds[str(i)], use) for i in ids}
    ok = [i for i in ids if all(k in mk[i] for k in ('home', 'o25', 'o35', 'btts'))]
    for sub_name, sub in (('all', ok), ('UEFA', [i for i in ok if P[i]['ut'] in (7, 679, 17015)]), ('domestic', [i for i in ok if P[i]['ut'] not in (7, 679, 17015)]),
                          ('early-season(Sep-Nov)', [i for i in ok if P[i]['ts'] < datetime.datetime(2025, 12, 31).timestamp()])):
        line = []
        for a in (0.0, 0.25, 0.5, 1.0):
            B = [dict({k: a * P[i][k] + (1 - a) * mk[i][k] for k in ('home', 'draw', 'away', 'o25', 'o35', 'btts')}, hg=P[i]['hg'], ag=P[i]['ag']) for i in sub]
            s = score(B)
            line.append(f"w={a}: o25 {s['o25']:.4f} o35 {s['o35']:.4f} btts {s['btts']:.4f} rps {s['1x2_rps']:.4f}")
        print(label, sub_name, len(sub)); [print('   ', l) for l in line]
