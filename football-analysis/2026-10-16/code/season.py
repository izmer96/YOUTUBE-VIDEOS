import json, datetime
CAL_LEAGUES = {20, 40, 41, 198, 197, 682, 704}
UEFA = {7, 679, 17015}
def team_season_matches(M, tid, primary_ut):
    """Current-season competitive matches for a team (90-min scores), oldest first."""
    if primary_ut in CAL_LEAGUES:
        start = datetime.datetime(2026, 1, 1).timestamp()
    else:
        start = datetime.datetime(2026, 6, 15).timestamp()
    out = []
    for m in M:
        if m['ts'] < start or (m['h'] != tid and m['a'] != tid):
            continue
        if m['ut'] in UEFA and '26/27' not in (m['sname'] or ''):
            continue
        out.append(m)
    return out
def primary_league(M, tid):
    from model import LEAGUE_UTS
    lu = None
    for m in M:
        if (m['h'] == tid or m['a'] == tid) and m['ut'] in LEAGUE_UTS:
            lu = m['ut']
    return lu
