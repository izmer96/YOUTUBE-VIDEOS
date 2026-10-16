"""Player importance from current-season lineups, absentee impact on expected goals, coaching changes, rest days."""
import json, datetime
from collections import defaultdict


def player_usage(M, team_rows):
    """team_rows: {tid: [season match rows]} -> {tid: {pid: usage dict}}"""
    lp = json.load(open('lineups_past.json'))
    mid = {m['id']: m for m in M}
    usage = {}
    for tid, rows in team_rows.items():
        u = defaultdict(lambda: dict(name=None, pos=None, apps=0, starts=0, mins=0.0, goals=0, assists=0))
        n_matches = 0; team_goals = 0
        for r in rows:
            d = lp.get(str(r['id']))
            if not d or 'home' not in d:
                continue
            m = mid[r['id']]
            side = 'home' if m['h'] == tid else 'away'
            n_matches += 1; team_goals += r['gf']
            for p in d[side].get('players', []):
                st = p.get('statistics') or {}
                if 'minutesPlayed' in st:
                    mins = st['minutesPlayed']
                elif not p.get('substitute'):
                    mins = 85
                elif len([k for k in st if k != 'statisticsType']) > 0:
                    mins = 20
                else:
                    mins = 0
                if mins <= 0:
                    continue
                pid = p['player']['id']
                x = u[pid]
                x['name'] = p['player']['name']; x['pos'] = p.get('position') or p['player'].get('position')
                x['apps'] += 1; x['starts'] += 0 if p.get('substitute') else 1
                x['mins'] += mins; x['goals'] += st.get('goals', 0) or 0; x['assists'] += st.get('goalAssist', 0) or 0
        for pid, x in u.items():
            x['min_share'] = x['mins'] / (90.0 * n_matches) if n_matches else 0
            x['ga_share'] = (x['goals'] + 0.6 * x['assists']) / max(team_goals, 1)
        usage[tid] = dict(players=dict(u), n=n_matches, goals=team_goals)
    return usage


def absentee_impact(missing, usage_t):
    """Return (own attack multiplier, opponent attack multiplier, annotated list).
    Heuristic, deliberately conservative: only regulars (>=45% of available minutes) move the numbers."""
    att_mult, opp_mult = 1.0, 1.0
    notes = []
    players = usage_t['players'] if usage_t else {}
    for mp in missing:
        pid = mp['player']['id']
        w = 1.0 if mp.get('type') == 'missing' else 0.5
        x = players.get(pid)
        pos = (x or {}).get('pos') or mp['player'].get('position')
        rec = dict(name=mp['player']['name'], pos=pos, status=mp.get('type'), reason=mp.get('description'),
                   min_share=(x or {}).get('min_share', 0.0), starts=(x or {}).get('starts', 0),
                   goals=(x or {}).get('goals', 0), assists=(x or {}).get('assists', 0))
        regular = rec['min_share'] >= 0.45
        rec['regular'] = regular
        if regular:
            ga = (x or {}).get('ga_share', 0.0)
            att_mult *= (1 - w * (0.30 * ga + 0.012))
            if pos == 'G':
                opp_mult *= (1 + w * 0.05)
            elif pos == 'D':
                opp_mult *= (1 + w * 0.025)
            else:
                opp_mult *= (1 + w * 0.012)
        notes.append(rec)
    att_mult = max(att_mult, 0.85); opp_mult = min(opp_mult, 1.12)
    return att_mult, opp_mult, notes


def manager_history(team_rows, tid, M):
    mg = json.load(open('managers.json'))
    mid = {m['id']: m for m in M}
    seq = []
    for r in team_rows:
        d = mg.get(str(r['id'])) or {}
        m = mid[r['id']]
        key = 'homeManager' if m['h'] == tid else 'awayManager'
        if key in d:
            seq.append((r['date'], d[key]['name']))
    changes = []
    for i in range(1, len(seq)):
        if seq[i][1] != seq[i - 1][1]:
            changes.append(dict(date=seq[i][0], new=seq[i][1], old=seq[i - 1][1]))
    current = seq[-1][1] if seq else None
    matches_under_current = 0
    for dte, name in reversed(seq):
        if name != current:
            break
        matches_under_current += 1
    return dict(current=current, changes=changes, n_current=matches_under_current)


def rest_and_congestion(team_events_raw, tid, fixture_ts):
    """Days since previous competitive match (incl. scheduled ones before the fixture) and days to next."""
    evs = sorted(team_events_raw, key=lambda e: e['startTimestamp'])
    prev = [e for e in evs if e['startTimestamp'] < fixture_ts - 3600]
    nxt = [e for e in evs if e['startTimestamp'] > fixture_ts + 3600]
    p = prev[-1] if prev else None
    n = nxt[0] if nxt else None
    return dict(prev_days=round((fixture_ts - p['startTimestamp']) / 86400, 1) if p else None,
                prev_match=(f"{p['homeTeam']['name']} v {p['awayTeam']['name']} ({p['tournament']['name']})" if p else None),
                next_days=round((n['startTimestamp'] - fixture_ts) / 86400, 1) if n else None,
                next_match=(f"{n['homeTeam']['name']} v {n['awayTeam']['name']} ({n['tournament']['name']})" if n else None))
