import ss, json
from concurrent.futures import ThreadPoolExecutor
from season import team_season_matches, primary_league
M = json.load(open('matches.json'))
teams = json.load(open('teams.json'))
fx = json.load(open('fixtures.json'))
ids = set()
for tid in teams:
    t = int(tid)
    for m in team_season_matches(M, t, primary_league(M, t)):
        ids.add(m['id'])
print('past events', len(ids), flush=True)
def f(i): return i, ss.get(f'event/{i}/lineups', sleep=0.1)
out = {}
with ThreadPoolExecutor(6) as ex:
    for i, d in ex.map(f, sorted(ids)): out[i] = d
json.dump(out, open('lineups_past.json', 'w'))
up = {}
for e in fx:
    up[e['id']] = ss.get(f'event/{e["id"]}/lineups', refresh=True)
json.dump(up, open('lineups_upcoming.json', 'w'))
print('done', sum('home' in d for d in out.values()), sum('home' in d for d in up.values()))
