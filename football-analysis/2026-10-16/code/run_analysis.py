"""Produce per-fixture probabilities, evidence and diagnostics for all uploaded fixtures."""
import json, datetime, numpy as np, sys
from model import Model, score_matrix, markets, top_scores, LEAGUE_UTS, UEFA_UTS
from teamstats import team_profile, comparables, agg, h2h
from teamnews import player_usage, absentee_impact, manager_history, rest_and_congestion
from odds_util import market_probs
import ss

cfg = json.load(open('bt_summary.json'))
S_cfg, T_cfg, RHO = tuple(cfg['S_cfg']), tuple(cfg['T_cfg']), cfg['rho']
W_MODEL = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
T_NOW = datetime.datetime(2026, 10, 16, 9, 0).timestamp()

M = json.load(open('matches.json'))
fx = json.load(open('fixtures.json'))
teams = {int(k): v for k, v in json.load(open('teams.json')).items()}
team_last = {int(k): v for k, v in json.load(open('team_events.json')).items()}
team_next = {int(k): v for k, v in json.load(open('team_next.json')).items()}
lu_up = json.load(open('lineups_upcoming.json'))
weather = json.load(open('weather.json'))
names = {}
for m in M:
    names[m['h']] = m['hn']; names[m['a']] = m['an']

def fit(c):
    hl, xw, rg = c
    mdl = Model(half_life=hl, xg_w=xw, ridge=rg); mdl.fit(M, T_NOW); return mdl

mS, mT = fit(S_cfg), fit(T_cfg)
mG = fit((S_cfg[0], 0.0, T_cfg[2]))  # alternative: goals-only model (no xG)
P = mS.params
strength = {t: P['att'][t] + P['def'][t] for t in P['att']}

def lam(h, a, ut, neutral=False, ms=mS, mt=mT):
    sh, sa = ms.rates(h, a, ut, neutral)
    th, ta = mt.rates(h, a, ut, neutral)
    tot = th + ta
    return tot * sh / (sh + sa), tot * sa / (sh + sa)

# league tiers: quintiles of strength among each league's current teams
league_teams = {}
for t, g in P['grp'].items():
    if g.startswith('L'):
        league_teams.setdefault(int(g[1:]), []).append(t)
cur_league_members = {}
for m in M:
    if m['ut'] in LEAGUE_UTS and m['ts'] > datetime.datetime(2026, 1, 1).timestamp():
        cur_league_members.setdefault(m['ut'], set()).update([m['h'], m['a']])

def tier_cuts(ut):
    ts_ = [strength[t] for t in cur_league_members.get(ut, []) if t in strength and P['grp'].get(t) == f'L{ut}']
    if len(ts_) < 5:
        return None
    return np.quantile(ts_, [0.2, 0.4, 0.6, 0.8, 0.9])

def tier(s, cuts):
    if cuts is None or s is None:
        return '?'
    if s >= cuts[4]: return 'Elite'
    if s >= cuts[3]: return 'Strong'
    if s >= cuts[1]: return 'Mid'
    if s >= cuts[0]: return 'Below-avg'
    return 'Weak'

# profiles
profiles = {}
for t in teams:
    pr = team_profile(M, t, strength)
    profiles[t] = pr
usage = player_usage(M, {t: profiles[t]['rows'] for t in teams})

# league baselines (current season)
def league_baseline(ut):
    rows = [m for m in M if m['ut'] == ut and m['ts'] > datetime.datetime(2026, 1, 1).timestamp()
            and (m['ut'] not in UEFA_UTS or True)]
    if ut in UEFA_UTS:
        rows = [m for m in M if m['ut'] == ut and '26/27' in (m['sname'] or '') and 'ualif' not in (m['rname'] or '') and 'layoff' not in (m['rname'] or '')]
    if not rows:
        return None
    hg = np.array([m['hg'] for m in rows]); ag = np.array([m['ag'] for m in rows])
    return dict(n=len(rows), gpg=float((hg + ag).mean()), o25=float((hg + ag >= 3).mean()), o35=float((hg + ag >= 4).mean()),
                btts=float(((hg > 0) & (ag > 0)).mean()), home=float((hg > ag).mean()), draw=float((hg == ag).mean()), away=float((hg < ag).mean()))

COMP_UT = {'PL': 17, 'LaLiga': 8, 'SerieA': 23, 'Ligue1': 34, 'Bundesliga': 35, 'SuperLig': 52, 'UCL': 7, 'UEL': 679, 'UECL': 17015}
baselines = {c: league_baseline(u) for c, u in COMP_UT.items()}

def neutral_rates(t):
    """Opponent-adjusted expected goals for/against vs an average team of t's own league, neutral venue."""
    g = P['grp'].get(t)
    mem = [x for x, gg in P['grp'].items() if gg == g]
    ma = np.mean([P['att'][x] for x in mem]); md = np.mean([P['def'][x] for x in mem])
    return float(np.exp(P['mu'] + P['att'][t] - md)), float(np.exp(P['mu'] + ma - P['def'][t]))

out = []
for f in fx:
    h, a, ut = f['hid'], f['aid'], COMP_UT[f['comp']]
    neutral = False
    lh0, la0 = lam(h, a, ut, neutral)
    # team news
    lu = lu_up.get(str(f['id'])) or {}
    miss_h = (lu.get('home') or {}).get('missingPlayers', [])
    miss_a = (lu.get('away') or {}).get('missingPlayers', [])
    att_h, opp_h, notes_h = absentee_impact(miss_h, usage.get(h))
    att_a, opp_a, notes_a = absentee_impact(miss_a, usage.get(a))
    lh = lh0 * att_h * opp_a
    la = la0 * att_a * opp_h
    Pm = score_matrix(lh, la, RHO)
    mod = markets(Pm)
    # alternatives
    gh, ga = lam(h, a, ut, neutral, ms=mG, mt=mG)
    alt_goals = markets(score_matrix(gh * att_h * opp_a, ga * att_a * opp_h, RHO))
    od = ss.get(f'event/{f["id"]}/odds/1/all', refresh=True, sleep=0.1)
    mk = market_probs(od) if 'markets' in od else {}
    final = {}
    for k in ('o25', 'o35', 'btts', 'home', 'draw', 'away'):
        final[k] = W_MODEL * mod[k] + (1 - W_MODEL) * mk[k] if k in mk else mod[k]
    s3 = final['home'] + final['draw'] + final['away']
    for k in ('home', 'draw', 'away'):
        final[k] /= s3
    ph, pa = profiles[h], profiles[a]
    cuts_h = tier_cuts(ph['primary_ut']); cuts_a = tier_cuts(pa['primary_ut'])
    comp_h, band_h = comparables(M, h, a, P, ph['rows'])
    comp_a, band_a = comparables(M, a, h, P, pa['rows'])
    for r in comp_h + comp_a:
        r['opp_str'] = strength.get(r['opp_id'])
    rec = dict(fixture=f, comp=f['comp'], lam_base=(lh0, la0), lam=(lh, la), model=mod, alt_goals_only=alt_goals, market=mk, final=final,
               top_scores=top_scores(Pm, 5),
               home=dict(id=h, name=names.get(h, f['home']), att=P['att'].get(h), dfn=P['def'].get(h), str=strength.get(h), neff=P['neff'].get(h),
                         grp=P['grp'].get(h), tier_own=tier(strength.get(h), cuts_h), tier_in_opp_league=tier(strength.get(h), cuts_a),
                         nr=neutral_rates(h), prof={k: v for k, v in ph.items() if k != 'rows'}, rows=ph['rows'],
                         absent=notes_h, att_mult=att_h, opp_mult=opp_h, mgr=manager_history(ph['rows'], h, M),
                         rest=rest_and_congestion(team_last[h] + team_next[h], h, f['ts']), comps=comp_h, comp_band=band_h,
                         sos=ph['all'].get('opp_str_avg')),
               away=dict(id=a, name=names.get(a, f['away']), att=P['att'].get(a), dfn=P['def'].get(a), str=strength.get(a), neff=P['neff'].get(a),
                         grp=P['grp'].get(a), tier_own=tier(strength.get(a), cuts_a), tier_in_opp_league=tier(strength.get(a), cuts_h),
                         nr=neutral_rates(a), prof={k: v for k, v in pa.items() if k != 'rows'}, rows=pa['rows'],
                         absent=notes_a, att_mult=att_a, opp_mult=opp_a, mgr=manager_history(pa['rows'], a, M),
                         rest=rest_and_congestion(team_last[a] + team_next[a], a, f['ts']), comps=comp_a, comp_band=band_a,
                         sos=pa['all'].get('opp_str_avg')),
               h2h=[dict(date=datetime.datetime.utcfromtimestamp(m['ts']).strftime('%Y-%m-%d'), hn=m['hn'], an=m['an'], hg=m['hg'], ag=m['ag'], comp=m['tname'])
                    for m in h2h(M, h, a, T_NOW - 800 * 86400)],
               weather=weather.get(str(f['id'])), baseline=baselines.get(f['comp']), lineup_confirmed=lu.get('confirmed'))
    out.append(rec)
    print(f"{f['home'][:22]:22s} v {f['away'][:22]:22s} λ {lh:.2f}-{la:.2f} | O2.5 {final['o25']:.2f} O3.5 {final['o35']:.2f} BTTS {final['btts']:.2f} | "
          f"1 {final['home']:.2f} X {final['draw']:.2f} 2 {final['away']:.2f} | mkt O2.5 {mk.get('o25', float('nan')):.2f} 1 {mk.get('home', float('nan')):.2f}", flush=True)

class Enc(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, (np.floating,)): return float(o)
        if isinstance(o, (np.integer,)): return int(o)
        if isinstance(o, np.ndarray): return o.tolist()
        return super().default(o)
json.dump(dict(results=out, cfg=dict(S=S_cfg, T=T_cfg, rho=RHO, w_model=W_MODEL), baselines=baselines,
               params=dict(mu=P['mu'], hfa=P['hfa'], hc_uefa={k: P['hc'].get(k) for k in (7, 679, 17015)})),
          open('analysis.json', 'w'), cls=Enc)
