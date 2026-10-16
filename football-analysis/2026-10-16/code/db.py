import json, datetime
FRIENDLY = {853, 851, 1295, 889, 36470, 10785, 18553, 38292, 27158, 27111, 25609, 25623, 20360}
NEUTRAL_UT = {213, 341, 339, 357, 465, 346, 799, 340, 345, 338, 31346, 505, 550, 510, 511, 16589, 1924, 773, 1266, 1107, 1262, 698, 26693, 766, 2104, 23674, 28472}
def stat_items(sd):
    out = {}
    for per in sd.get('statistics', []):
        if per['period'] != 'ALL': continue
        for g in per['groups']:
            for it in g['statisticsItems']:
                k = it.get('key')
                if k in ('expectedGoals', 'totalShotsOnGoal', 'shotsOnGoal', 'bigChanceCreated', 'ballPossession', 'cornerKicks') and k not in out:
                    out[k] = (it.get('homeValue', it.get('home')), it.get('awayValue', it.get('away')))
    return out
def build():
    le = json.load(open('league_events.json'))
    te = json.load(open('team_events.json'))
    st = json.load(open('event_stats.json'))
    raw = {}
    for v in le.values():
        for e in v['events']: raw[e['id']] = e
    for evs in te.values():
        for e in evs: raw[e['id']] = e
    M = []
    for e in raw.values():
        ut = e['tournament'].get('uniqueTournament', {}).get('id')
        if ut in FRIENDLY or ut is None: continue
        if e['status']['type'] != 'finished': continue
        hs, as_ = e.get('homeScore', {}), e.get('awayScore', {})
        if e.get('isAwarded'): continue
        h90 = hs.get('normaltime', hs.get('current')); a90 = as_.get('normaltime', as_.get('current'))
        if h90 is None or a90 is None: continue
        rnd = e.get('roundInfo', {})
        neutral = ut in NEUTRAL_UT or (rnd.get('name') or '').lower() == 'final'
        m = dict(id=e['id'], ts=e['startTimestamp'], ut=ut, tname=e['tournament'].get('uniqueTournament', {}).get('name'),
                 cat=e['tournament']['category']['name'], season=e.get('season', {}).get('id'), sname=e.get('season', {}).get('name'),
                 rnd=rnd.get('round'), rname=rnd.get('name'),
                 h=e['homeTeam']['id'], hn=e['homeTeam']['name'], a=e['awayTeam']['id'], an=e['awayTeam']['name'], hcty=(e['homeTeam'].get('country') or {}).get('name'), acty=(e['awayTeam'].get('country') or {}).get('name'),
                 hg=h90, ag=a90, hht=hs.get('period1'), aht=as_.get('period1'),
                 et='overtime' in hs or 'extra1' in hs, hr=e.get('homeRedCards', 0) or 0, ar=e.get('awayRedCards', 0) or 0, neutral=neutral)
        sd = st.get(str(e['id']))
        if sd and 'error' not in sd:
            si = stat_items(sd)
            for k, (hv, av) in si.items():
                try: m['h_' + k] = float(hv); m['a_' + k] = float(av)
                except (TypeError, ValueError): pass
        M.append(m)
    M.sort(key=lambda m: m['ts'])
    return M
if __name__ == '__main__':
    M = build()
    json.dump(M, open('matches.json', 'w'))
    print(len(M), 'matches;', sum('h_expectedGoals' in m for m in M), 'with xG')
    print(datetime.datetime.utcfromtimestamp(M[0]['ts']), datetime.datetime.utcfromtimestamp(M[-1]['ts']))
