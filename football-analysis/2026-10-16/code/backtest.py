import json, datetime, sys, itertools, numpy as np, pickle
from model import Model, score_matrix, markets
M = json.load(open('matches.json'))
BIG = {17, 8, 23, 34, 35, 52, 7, 679, 17015}
ts = lambda *a: datetime.datetime(*a).timestamp()
W = [(ts(2025, 9, 12), ts(2025, 11, 30)), (ts(2026, 1, 15), ts(2026, 5, 31))]
weeks = []
for a, b in W:
    t = a
    while t < b:
        weeks.append(t); t += 7 * 86400
def run(cfg, rho=-0.06):
    preds = []
    for t in weeks:
        m = Model(**cfg); m.fit(M, t)
        for x in M:
            if t <= x['ts'] < t + 7 * 86400 and x['ut'] in BIG:
                if x['h'] not in m.params['att'] or x['a'] not in m.params['att']: continue
                lh, la = m.rates(x['h'], x['a'], x['ut'], x['neutral'])
                P = score_matrix(lh, la, rho)
                preds.append(dict(id=x['id'], ut=x['ut'], ts=x['ts'], lh=lh, la=la, hg=x['hg'], ag=x['ag'], **markets(P)))
    return preds
def score(preds):
    hg = np.array([p['hg'] for p in preds]); ag = np.array([p['ag'] for p in preds])
    out = {}
    for k, y in [('o25', hg + ag >= 3), ('o35', hg + ag >= 4), ('btts', (hg > 0) & (ag > 0))]:
        p = np.clip(np.array([q[k] for q in preds]), 1e-6, 1 - 1e-6)
        out[k] = np.mean((p - y) ** 2)
    P = np.array([[q['home'], q['draw'], q['away']] for q in preds])
    Y = np.stack([hg > ag, hg == ag, hg < ag], 1).astype(float)
    out['1x2_ll'] = -np.mean(np.log(np.clip((P * Y).sum(1), 1e-9, 1)))
    out['1x2_rps'] = np.mean(((np.cumsum(P, 1) - np.cumsum(Y, 1))[:, :2] ** 2).sum(1) / 2)
    out['n'] = len(preds)
    return out
if __name__ == '__main__':
    res = {}
    grid = list(itertools.product([150, 240, 365], [0.0, 0.5, 0.8], [1.5, 3.0, 6.0]))
    for hl, xw, rg in grid:
        cfg = dict(half_life=hl, xg_w=xw, ridge=rg)
        preds = run(cfg)
        s = score(preds)
        res[(hl, xw, rg)] = (s, preds)
        print(hl, xw, rg, {k: round(v, 5) for k, v in s.items()}, flush=True)
    pickle.dump(res, open('bt_grid.pkl', 'wb'))
