"""Time-decayed, ridge-regularised Poisson team-strength model with Dixon-Coles correction.

log E[home goals] = mu + (hfa + hfa_comp[c]) * (1 - neutral) + att[home] - def[away]
log E[away goals] = mu + att[away] - def[home]

Targets can blend actual goals with xG where xG exists (quasi-Poisson likelihood).
Weights decay exponentially with match age; domestic cups and super cups are down-weighted.
"""
import numpy as np
from scipy.optimize import minimize

LEAGUE_UTS = {17, 8, 23, 34, 35, 52, 37, 38, 172, 238, 39, 20, 185, 45, 36, 170, 247, 171, 202, 215, 266, 210, 704,
              222, 720, 709, 198, 40, 197, 152, 671, 682, 212, 211, 187, 41, 218, 742, 1542, 18, 54, 53, 182, 44, 98,
              239, 216, 22}
UEFA_UTS = {7, 679, 17015}


def comp_weight(m):
    if m['ut'] in LEAGUE_UTS or m['ut'] in UEFA_UTS:
        return 1.0
    if m['neutral']:
        return 0.5
    return 0.7  # domestic cups (rotation, mismatched opponents)


class Model:
    def __init__(self, half_life=240.0, xg_w=0.5, ridge=2.0, ridge_h=20.0, ridge_league=0.5, max_age=800):
        self.half_life, self.xg_w, self.ridge, self.ridge_h, self.max_age = half_life, xg_w, ridge, ridge_h, max_age
        self.ridge_league = ridge_league
        self.params = None

    def _prep(self, M, t_now):
        lo = t_now - self.max_age * 86400
        S = [m for m in M if lo <= m['ts'] < t_now]
        teams = sorted({m['h'] for m in S} | {m['a'] for m in S})
        comps = sorted({m['ut'] for m in S})
        ti = {t: i for i, t in enumerate(teams)}
        ci = {c: i for i, c in enumerate(comps)}
        n = len(S)
        H = np.array([ti[m['h']] for m in S]); A = np.array([ti[m['a']] for m in S])
        C = np.array([ci[m['ut']] for m in S])
        nz = np.array([0.0 if m['neutral'] else 1.0 for m in S])
        age = np.array([(t_now - m['ts']) / 86400 for m in S])
        w = np.exp(-np.log(2) * age / self.half_life) * np.array([comp_weight(m) for m in S])
        yh = np.array([m['hg'] for m in S], float); ya = np.array([m['ag'] for m in S], float)
        if self.xg_w > 0:
            for k, m in enumerate(S):
                if 'h_expectedGoals' in m and 'a_expectedGoals' in m:
                    yh[k] = self.xg_w * m['h_expectedGoals'] + (1 - self.xg_w) * m['hg']
                    ya[k] = self.xg_w * m['a_expectedGoals'] + (1 - self.xg_w) * m['ag']
        # group each team by the most recent domestic league it played in (as of t_now), else by country
        grp = {}
        for m in S:  # S is chronological, so later league matches overwrite earlier ones
            if m['ut'] in LEAGUE_UTS:
                grp[m['h']] = f"L{m['ut']}"; grp[m['a']] = f"L{m['ut']}"
        for m in S:
            for t, c in ((m['h'], m.get('hcty')), (m['a'], m.get('acty'))):
                if t not in grp:
                    grp[t] = f"C{c}-other"
        groups = sorted(set(grp.values()))
        gi = {g: i for i, g in enumerate(groups)}
        G = np.array([gi[grp[t]] for t in teams])
        return dict(S=S, teams=teams, comps=comps, ti=ti, ci=ci, H=H, A=A, C=C, nz=nz, w=w, yh=yh, ya=ya,
                    groups=groups, G=G, grp=grp)

    def fit(self, M, t_now, warm=None):
        d = self._prep(M, t_now)
        nt, nc, ng = len(d['teams']), len(d['comps']), len(d['groups'])
        H, A, C, nz, w, yh, ya, G = d['H'], d['A'], d['C'], d['nz'], d['w'], d['yh'], d['ya'], d['G']
        o = np.cumsum([0, 1, 1, nc, ng, ng, nt, nt])
        # x = [mu, hfa, hfa_comp(nc), Latt(ng), Ldef(ng), att_dev(nt), def_dev(nt)]
        def unpack(x):
            return [x[o[k]:o[k + 1]] for k in range(7)]

        rl = self.ridge_league

        def f(x):
            mu, hfa, hc, La, Ld, ad, dd = unpack(x)
            mu, hfa = mu[0], hfa[0]
            att = La[G] + ad; de = Ld[G] + dd
            eh = mu + (hfa + hc[C]) * nz + att[H] - de[A]
            ea = mu + att[A] - de[H]
            lh, la = np.exp(eh), np.exp(ea)
            nll = np.sum(w * (lh - yh * eh)) + np.sum(w * (la - ya * ea))
            nll += self.ridge * (ad @ ad + dd @ dd) + self.ridge_h * (hc @ hc) + rl * (La @ La + Ld @ Ld)
            gh, ga = w * (lh - yh), w * (la - ya)
            g = np.zeros_like(x)
            g[0] = gh.sum() + ga.sum()
            g[1] = (gh * nz).sum()
            g[o[2]:o[3]] = np.bincount(C, gh * nz, nc) + 2 * self.ridge_h * hc
            gatt = np.bincount(H, gh, nt) + np.bincount(A, ga, nt)
            gdef = -np.bincount(A, gh, nt) - np.bincount(H, ga, nt)
            g[o[3]:o[4]] = np.bincount(G, gatt, ng) + 2 * rl * La
            g[o[4]:o[5]] = np.bincount(G, gdef, ng) + 2 * rl * Ld
            g[o[5]:o[6]] = gatt + 2 * self.ridge * ad
            g[o[6]:o[7]] = gdef + 2 * self.ridge * dd
            return nll, g

        x0 = np.zeros(o[-1]); x0[0] = np.log(1.3); x0[1] = 0.2
        r = minimize(f, x0, jac=True, method='L-BFGS-B', options={'maxiter': 5000})
        mu, hfa, hc, La, Ld, ad, dd = unpack(r.x)
        att = La[G] + ad; de = Ld[G] + dd
        # effective weighted sample size per team (for reliability reporting)
        nw = np.bincount(H, w, nt) + np.bincount(A, w, nt)
        self.params = dict(mu=mu[0], hfa=hfa[0], hc={c: hc[i] for c, i in d['ci'].items()},
                           att={t: att[i] for t, i in d['ti'].items()}, def_={t: de[i] for t, i in d['ti'].items()},
                           neff={t: nw[i] for t, i in d['ti'].items()}, grp=d['grp'],
                           Latt={g: La[i] for i, g in enumerate(d['groups'])},
                           Ldef={g: Ld[i] for i, g in enumerate(d['groups'])}, converged=r.success)
        self.params['def'] = self.params['def_']
        self.t_now = t_now
        return self.params

    def rates(self, h, a, ut, neutral=False):
        p = self.params
        att, de = p['att'], p['def']
        ah, dh = att.get(h, 0.0), de.get(h, 0.0)
        aa, da = att.get(a, 0.0), de.get(a, 0.0)
        hf = 0.0 if neutral else p['hfa'] + p['hc'].get(ut, 0.0)
        lh = np.exp(p['mu'] + hf + ah - da)
        la = np.exp(p['mu'] + aa - dh)
        return lh, la


def score_matrix(lh, la, rho=-0.06, maxg=12):
    from scipy.stats import poisson
    ph = poisson.pmf(np.arange(maxg + 1), lh)
    pa = poisson.pmf(np.arange(maxg + 1), la)
    P = np.outer(ph, pa)
    # Dixon-Coles low-score dependence correction
    P[0, 0] *= max(1 - lh * la * rho, 0)
    P[0, 1] *= max(1 + lh * rho, 0)
    P[1, 0] *= max(1 + la * rho, 0)
    P[1, 1] *= max(1 - rho, 0)
    return P / P.sum()


def markets(P):
    n = P.shape[0]
    i, j = np.indices(P.shape)
    tot = i + j
    return dict(o25=P[tot >= 3].sum(), o35=P[tot >= 4].sum(), btts=P[(i >= 1) & (j >= 1)].sum(),
                home=P[i > j].sum(), draw=P[i == j].sum(), away=P[i < j].sum())


def top_scores(P, k=3):
    flat = [(P[i, j], f'{i}-{j}') for i in range(P.shape[0]) for j in range(P.shape[1])]
    flat.sort(reverse=True)
    return flat[:k]
