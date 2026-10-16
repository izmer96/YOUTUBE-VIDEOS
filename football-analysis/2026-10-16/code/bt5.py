import json, pickle, numpy as np, datetime
from model import score_matrix, markets
from backtest import score
res = pickle.load(open('bt_grid2.pkl', 'rb')); sm = json.load(open('bt_summary.json'))
S = {p['id']: p for p in res[tuple(sm['S_cfg'])][1]}; T = {p['id']: p for p in res[tuple(sm['T_cfg'])][1]}
U = [i for i in S if i in T and S[i]['ut'] in (7, 679, 17015)]
def preds(k, j, sub):
    out = []
    for i in sub:
        s, t = S[i], T[i]; tot = t['lh'] + t['la']; r = k * np.log(s['lh'] / s['la'])
        tot2 = np.exp(np.log(2.7) + j * (np.log(tot) - np.log(2.7))); lh = tot2 * np.exp(r) / (1 + np.exp(r))
        out.append(dict(markets(score_matrix(lh, tot2 - lh, -0.05)), hg=s['hg'], ag=s['ag']))
    return out
# 2-fold cross-validation by season half: A (Sep-Nov 2025) vs B (2026)
cut = datetime.datetime(2025, 12, 31).timestamp()
A_ = [i for i in U if S[i]['ts'] < cut]; B_ = [i for i in U if S[i]['ts'] >= cut]
print('UEFA n', len(U), 'fold A', len(A_), 'fold B', len(B_))
for k in (1.0, 1.1, 1.2, 1.3):
    for j in (1.0, 1.25):
        sa = score(preds(k, j, A_)); sb = score(preds(k, j, B_))
        print(k, j, 'A rps', round(sa['1x2_rps'], 5), 'o25', round(sa['o25'], 5), '| B rps', round(sb['1x2_rps'], 5), 'o25', round(sb['o25'], 5))
