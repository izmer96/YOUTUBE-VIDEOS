"""Assemble the final, coherent per-fixture estimates plus all evidence into report_data.json."""
import json, datetime, numpy as np
from model import score_matrix, markets, top_scores
from coherent import fit_dc

A = json.load(open('analysis.json'))
R = A['results']
bt = json.load(open('bt_summary.json'))
xc = json.load(open('xcheck.json'))
W = 0.25
KEYS = ('home', 'draw', 'away', 'o25', 'o35', 'btts')
TOP_LEAGUE_GRPS = {'L17', 'L8', 'L23', 'L34', 'L35', 'L52', 'L37', 'L38', 'L238', 'L18', 'L54', 'L53', 'L182', 'L44', 'L98'}
GRP_NAME = {}
for m in json.load(open('matches.json')):
    pass
LEAGUE_NAMES = {}
le = json.load(open('league_events.json'))
for k, v in le.items():
    if v['events']:
        LEAGUE_NAMES[f"L{v['ut']}"] = v['events'][0]['tournament'].get('uniqueTournament', {}).get('name')

def r3(x):
    return None if x is None else round(float(x), 4)

def agg_out(a):
    if not a or not a.get('n'):
        return None
    keys = ['n', 'w', 'd', 'l', 'gf', 'ga', 'gf_pg', 'ga_pg', 'tot_pg', 'o25', 'o35', 'btts', 'cs', 'fts', 'gf2', 'ga2',
            'xgf_pg', 'xga_pg', 'xg_n', 'shf_pg', 'sha_pg', 'sotf_pg', 'sota_pg', 'bcf_pg', 'bca_pg', 'posf_pg', 'corf_pg', 'cora_pg', 'opp_str_avg']
    return {k: (round(a[k], 3) if isinstance(a.get(k), float) else a.get(k)) for k in keys if k in a}

def row_out(x):
    return [x['date'], x['comp'], x['ctype'], x['venue'], x['opp'], x['gf'], x['ga'], x['htf'], x['hta'],
            r3(x.get('xgf')), r3(x.get('xga')), x.get('shf'), x.get('sha'), x.get('sotf'), x.get('sota'), x.get('bcf'), x.get('bca'),
            r3(x.get('opp_str')), int(x['red_for'] or 0), int(x['red_against'] or 0), bool(x['et']), x.get('round')]

def real_coach_change(mg):
    """Treat a change as real only if the current coach is new and the run is not a flip-back to an earlier name."""
    if not mg['changes']:
        return None
    last = mg['changes'][-1]
    olds = {c['old'] for c in mg['changes']}
    if last['new'] in olds:
        return None
    if len({c['new'] for c in mg['changes']} | olds) > 3:
        return None
    return dict(coach=mg['current'], since=last['date'], previous=last['old'], matches=mg['n_current'])

lu_up = json.load(open('lineups_upcoming.json'))
NEWS_NOTE = {16938775: {'home': "No absentee feed was published for this UCL fixture. Manchester City's list for their 17 Oct league game shows no injured regulars (Foden's suspension there is domestic and does not carry into the Champions League)."}}
SB = json.load(open('sb_odds.json'))['events']

def superbet_devig(fid):
    """De-vigged (proportional) Superbet.ro probabilities, or None if the fixture is not offered."""
    v = SB.get(str(fid))
    if not v or v['status'] != 'ok':
        return None
    o = v['odds']
    s3 = 1 / o['home'] + 1 / o['draw'] + 1 / o['away']
    pair = lambda a, b: (1 / o[a]) / (1 / o[a] + 1 / o[b])
    return dict(home=(1 / o['home']) / s3, draw=(1 / o['draw']) / s3, away=(1 / o['away']) / s3,
                o25=pair('o25', 'u25'), o35=pair('o35', 'u35'), btts=pair('btts_yes', 'btts_no'), margin_1x2=s3 - 1)

out = []
for i, r in enumerate(R):
    f = r['fixture']
    mod, mk = r['model'], r['market']
    market_source = 'sofascore' if all(k in mk for k in KEYS) else None
    if market_source is None:
        sbp = superbet_devig(f['id'])
        if sbp:
            mk, market_source = sbp, 'superbet'
    has_mkt = market_source is not None
    if has_mkt:
        tgt = {k: W * mod[k] + (1 - W) * mk[k] for k in KEYS}
        lh, la, rho, P, err = fit_dc(tgt, r['lam'][0], r['lam'][1])
    else:
        lh, la = r['lam']; rho = -0.05; P = score_matrix(lh, la, rho); err = 0.0
    fin = markets(P)
    p_h_scores = float(1 - P[0, :].sum()); p_a_scores = float(1 - P[:, 0].sum())
    ts = [[s, round(float(p), 4)] for p, s in top_scores(P, 5)]
    ko = datetime.datetime.utcfromtimestamp(f['ts'])
    teams = {}
    for side in ('home', 'away'):
        t = r[side]
        cc = real_coach_change(t['mgr'])
        teams[side] = dict(
            id=t['id'], name=t['name'], league=LEAGUE_NAMES.get(t['grp'], t['grp']), grp=t['grp'],
            att=r3(t['att']), dfn=r3(t['dfn']), strength=r3(t['str']), neff=r3(t['neff']),
            tier_own=t['tier_own'], tier_vs=t['tier_in_opp_league'], nr=[r3(x) for x in t['nr']], sos=r3(t['sos']),
            splits={k: agg_out(t['prof'].get(k)) for k in ('all', 'home', 'away', 'last10', 'last5', 'league', 'league_home', 'league_away', 'uefa', 'cup')},
            rows=[row_out(x) for x in t['rows']],
            comps=[dict(date=c['date'], venue=c['venue'], opp=c['opp'], gf=c['gf'], ga=c['ga'], xgf=r3(c.get('xgf')), xga=r3(c.get('xga')),
                        dist=r3(c['dist']), season=c['season'], comp=c['comp'], opp_str=r3(c.get('opp_str'))) for c in t['comps']],
            comp_band=t['comp_band'],
            absent=[dict(name=x['name'], pos=x['pos'], status=x['status'], reason=x['reason'], min_share=r3(x['min_share']),
                         starts=x['starts'], goals=x['goals'], assists=x['assists'], regular=x['regular']) for x in t['absent']],
            att_mult=r3(t['att_mult']), opp_mult=r3(t['opp_mult']),
            coach=t['mgr']['current'], coach_change=cc, coach_raw_changes=len(t['mgr']['changes']),
            rest=t['rest'])
    out.append(dict(
        idx=i, id=f['id'], comp=f['comp'], round=f['round'], kickoff=ko.strftime('%a %d %b %H:%M UTC'), ts=f['ts'],
        home=f['home'], away=f['away'],
        final={k: r3(fin[k]) for k in KEYS}, model={k: r3(mod[k]) for k in KEYS},
        market={k: r3(mk[k]) for k in KEYS if k in mk}, market_margin=r3(mk.get('margin_1x2')),
        goals_only={k: r3(r['alt_goals_only'][k]) for k in KEYS},
        lam_final=[r3(lh), r3(la)], rho=r3(rho), fit_err=r3(err), lam_model=[r3(x) for x in r['lam']], lam_model_base=[r3(x) for x in r['lam_base']],
        p_h_scores=r3(p_h_scores), p_a_scores=r3(p_a_scores), top_scores=ts,
        teams=teams, h2h=r['h2h'], weather=r['weather'], baseline=r['baseline'], lineup_confirmed=r['lineup_confirmed'],
        has_market=has_mkt, market_source=market_source, news_available=('home' in (lu_up.get(str(f['id'])) or {})), news_note=NEWS_NOTE.get(f['id'], {})))

# reliability per (fixture, market)
MK = {'o25': 'Over 2.5', 'o35': 'Over 3.5', 'btts': 'BTTS Yes', 'home': 'Home Win', 'away': 'Away Win'}
def reliability(fx, k):
    issues = []
    if fx['has_market']:
        lbl = 'market' if fx['market_source'] == 'sofascore' else 'Superbet'
        gap = abs(fx['model'][k] - fx['market'][k])
        if gap > 0.10: issues.append(('major', f"model {fx['model'][k]*100:.0f}% vs {lbl} {fx['market'][k]*100:.0f}% ({gap*100:.0f}-pt gap)"))
        elif gap > 0.05: issues.append(('minor', f"model {fx['model'][k]*100:.0f}% vs {lbl} {fx['market'][k]*100:.0f}%"))
        if fx['market_source'] == 'superbet':
            issues.append(('minor', 'market anchor is a single bookmaker (Superbet.ro), priced six days before kickoff'))
    else:
        issues.append(('minor', 'no bookmaker price published yet: model-only estimate'))
    if not fx['news_available']:
        issues.append(('minor', 'no injury/suspension feed published for this fixture'))
    for side in ('home', 'away'):
        t = fx['teams'][side]; a = t['splits']['all']
        cov = (a.get('xg_n') or 0) / max(a['n'], 1)
        if cov < 0.5: issues.append(('minor', f"{t['name']}: xG available for {a.get('xg_n') or 0} of {a['n']} matches"))
        if a['n'] < 6: issues.append(('minor', f"{t['name']}: only {a['n']} matches played"))
        if t['grp'] not in TOP_LEAGUE_GRPS and (a.get('xg_n') or 0) < 6: issues.append(('minor', f"{t['name']}: thin cross-league evidence"))
        reg_out = [x for x in t['absent'] if x['regular'] and x['status'] == 'missing']
        if len(reg_out) >= 3: issues.append(('minor', f"{t['name']}: {len(reg_out)} regular starters ruled out"))
        if t['coach_change'] and t['coach_change']['matches'] <= 2:
            issues.append(('minor', f"{t['name']}: new coach {t['coach_change']['coach']} ({t['coach_change']['matches']} match(es) in charge)"))
    maj = sum(1 for s, _ in issues if s == 'major'); mnr = sum(1 for s, _ in issues if s == 'minor')
    level = 'High' if maj == 0 and mnr == 0 else ('Medium' if maj == 0 and mnr <= 2 else 'Low')
    return level, [m for _, m in issues]

rows = []
for fx in out:
    fx['rel'] = {}
    for k in MK:
        lvl, iss = reliability(fx, k)
        fx['rel'][k] = dict(level=lvl, issues=iss)
        rows.append(dict(idx=fx['idx'], market=k, p=fx['final'][k]))
rows.sort(key=lambda x: -x['p'])
master = []
seen = {}
for x in rows[:40]:
    corr = seen.get(x['idx'])
    seen.setdefault(x['idx'], len(master) + 1)
    master.append(dict(x, corr_with=corr))
rank = {k: sorted(range(len(out)), key=lambda i: -out[i]['final'][k]) for k in MK}

audit = dict(
    fixtures_identified=len(out), fixtures_analyzed=len(out),
    unique_teams=len({fx['teams'][s]['id'] for fx in out for s in ('home', 'away')}),
    unique_current_matches=len({row[0] + row[4] + str(fx['teams'][s]['id']) for fx in out for s in ('home', 'away') for row in fx['teams'][s]['rows']}),
    team_match_records=sum(len(fx['teams'][s]['rows']) for fx in out for s in ('home', 'away')),
    with_market=sum(fx['has_market'] for fx in out),
    xcheck=xc, backtest=bt)
A2 = json.load(open('analysis.json'))
audit['unique_current_matches'] = len({row['id'] for rr in A2['results'] for sd in ('home', 'away') for row in rr[sd]['rows']})
audit['base_rate'] = {'o25': 0.2479, 'o35': 0.2128, 'btts': 0.2481, '1x2_rps': 0.2293}
audit['news_missing'] = [f"{fx['home']} v {fx['away']}" for fx in out if not fx['news_available']]
json.dump(dict(fixtures=out, master=master, rank=rank, audit=audit, generated='2026-10-16 ~12:00 UTC'), open('report_data.json', 'w'))
for n, x in enumerate(master):
    fx = out[x['idx']]
    print(f"{n+1:2d} {fx['home'][:24]:24s} v {fx['away'][:22]:22s} {MK[x['market']]:9s} {x['p']*100:5.1f} rel {fx['rel'][x['market']]['level']:6s} corr {x['corr_with']}")
