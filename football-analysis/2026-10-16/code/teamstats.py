"""Per-team current-season match logs, split aggregates, and comparable-opponent analysis."""
import datetime
import numpy as np
from season import team_season_matches, primary_league
from model import LEAGUE_UTS, UEFA_UTS

UEFA_NAMES = {7: 'UCL', 679: 'UEL', 17015: 'UECL'}


def match_row(m, tid, strength):
    home = m['h'] == tid
    gf, ga = (m['hg'], m['ag']) if home else (m['ag'], m['hg'])
    htf, hta = (m['hht'], m['aht']) if home else (m['aht'], m['hht'])
    opp = m['a'] if home else m['h']
    oppn = m['an'] if home else m['hn']
    r = dict(id=m['id'], date=datetime.datetime.utcfromtimestamp(m['ts']).strftime('%Y-%m-%d'), ts=m['ts'],
             comp=m['tname'], ut=m['ut'], ctype='league' if m['ut'] in LEAGUE_UTS else ('uefa' if m['ut'] in UEFA_UTS else 'cup'),
             round=m['rname'] or m['rnd'],
             venue='N' if m['neutral'] else ('H' if home else 'A'), opp=oppn, opp_id=opp, gf=gf, ga=ga, htf=htf, hta=hta,
             res='W' if gf > ga else ('D' if gf == ga else 'L'), et=m['et'],
             red_for=(m['hr'] if home else m['ar']), red_against=(m['ar'] if home else m['hr']),
             opp_str=strength.get(opp))
    for k, short in (('expectedGoals', 'xg'), ('totalShotsOnGoal', 'sh'), ('shotsOnGoal', 'sot'), ('bigChanceCreated', 'bc'), ('ballPossession', 'pos'), ('cornerKicks', 'cor')):
        if 'h_' + k in m:
            r[short + 'f'] = m['h_' + k] if home else m['a_' + k]
            r[short + 'a'] = m['a_' + k] if home else m['h_' + k]
    return r


def agg(rows):
    n = len(rows)
    if n == 0:
        return dict(n=0)
    gf = np.array([r['gf'] for r in rows]); ga = np.array([r['ga'] for r in rows]); tot = gf + ga
    out = dict(n=n, w=int((gf > ga).sum()), d=int((gf == ga).sum()), l=int((gf < ga).sum()),
               gf=int(gf.sum()), ga=int(ga.sum()), gf_pg=gf.mean(), ga_pg=ga.mean(), tot_pg=tot.mean(),
               o25=(tot >= 3).mean(), o35=(tot >= 4).mean(), btts=((gf > 0) & (ga > 0)).mean(),
               cs=(ga == 0).mean(), fts=(gf == 0).mean(), gf2=(gf >= 2).mean(), ga2=(ga >= 2).mean())
    for s in ('xg', 'sh', 'sot', 'bc', 'pos', 'cor'):
        sub = [r for r in rows if s + 'f' in r]
        if sub:
            out[s + 'f_pg'] = np.mean([r[s + 'f'] for r in sub]); out[s + 'a_pg'] = np.mean([r[s + 'a'] for r in sub])
            out[s + '_n'] = len(sub)
    st = [r['opp_str'] for r in rows if r['opp_str'] is not None]
    out['opp_str_avg'] = float(np.mean(st)) if st else None
    return out


def team_profile(M, tid, strength):
    pl = primary_league(M, tid)
    ms = team_season_matches(M, tid, pl)
    rows = [match_row(m, tid, strength) for m in ms]
    prof = dict(tid=tid, primary_ut=pl, rows=rows,
                all=agg(rows), home=agg([r for r in rows if r['venue'] == 'H']), away=agg([r for r in rows if r['venue'] == 'A']),
                last10=agg(rows[-10:]), last5=agg(rows[-5:]),
                league=agg([r for r in rows if r['ctype'] == 'league']),
                league_home=agg([r for r in rows if r['ctype'] == 'league' and r['venue'] == 'H']),
                league_away=agg([r for r in rows if r['ctype'] == 'league' and r['venue'] == 'A']),
                uefa=agg([r for r in rows if r['ctype'] == 'uefa']), cup=agg([r for r in rows if r['ctype'] == 'cup']))
    return prof


def comparables(M, tid, target_id, params, cur_rows, max_n=8):
    """Matches of `tid` vs opponents whose (attack, defence) profile is closest to `target_id`.
    Current season first; previous season (2025-26 / 2025) added only if fewer than 4 current-season comparables."""
    att, de = params['att'], params['def']
    if target_id not in att:
        return [], None
    ta, td = att[target_id], de[target_id]

    def dist(o):
        if o not in att:
            return 9
        return float(np.hypot(att[o] - ta, de[o] - td))

    cur = [dict(r, dist=dist(r['opp_id']), season='current') for r in cur_rows if r['opp_id'] != target_id]
    picked = sorted([r for r in cur if r['dist'] <= 0.30], key=lambda r: r['dist'])
    band = 0.30
    if len(picked) < 4:
        band = 0.45
        picked = sorted([r for r in cur if r['dist'] <= band], key=lambda r: r['dist'])
    if len(picked) < 4:
        cur_ids = {r['id'] for r in cur_rows}
        start = (cur_rows[0]['ts'] if cur_rows else datetime.datetime(2026, 6, 15).timestamp()) - 400 * 86400
        prev = []
        for m in M:
            if m['ts'] < start or m['id'] in cur_ids or (m['h'] != tid and m['a'] != tid):
                continue
            if m['ts'] >= (cur_rows[0]['ts'] if cur_rows else 1e18):
                continue
            r = match_row(m, tid, {})
            if r['opp_id'] == target_id:
                continue
            r['dist'] = dist(r['opp_id']); r['season'] = 'previous'
            if r['dist'] <= 0.30:
                prev.append(r)
        prev.sort(key=lambda r: r['dist'])
        picked = picked + prev[:max(0, 6 - len(picked))]
    return picked[:max_n], band


def h2h(M, a, b, since_ts):
    out = []
    for m in M:
        if m['ts'] >= since_ts and {m['h'], m['a']} == {a, b}:
            out.append(m)
    return out
