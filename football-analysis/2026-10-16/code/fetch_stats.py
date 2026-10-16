import ss, json, datetime, sys
from concurrent.futures import ThreadPoolExecutor
le = json.load(open('league_events.json'))
te = json.load(open('team_events.json'))
BIG = {17, 8, 23, 34, 35, 52, 7, 679, 17015}
ids = set()
cur_cut = datetime.datetime(2026, 2, 1).timestamp()
for k, v in le.items():
    seasons = sorted({kk.split('_')[1] for kk in le if kk.startswith(f"{v['ut']}_")}, key=int)
    is_current = v['season'] == max(int(s) for s in seasons)
    for e in v['events']:
        if e['status']['type'] != 'finished':
            continue
        if is_current or v['ut'] in BIG:
            ids.add(e['id'])
for tid, evs in te.items():
    for e in evs:
        if e['status']['type'] == 'finished' and e['startTimestamp'] >= cur_cut and e['tournament'].get('uniqueTournament', {}).get('id') != 853:
            ids.add(e['id'])
ids = sorted(ids)
print('events to fetch', len(ids), flush=True)
def f(i):
    d = ss.get(f'event/{i}/statistics', sleep=0.1)
    return i, d
out = {}
with ThreadPoolExecutor(6) as ex:
    for n, (i, d) in enumerate(ex.map(f, ids)):
        out[i] = d
        if n % 500 == 0:
            print(n, flush=True)
bad = sum(1 for d in out.values() if 'error' in d)
print('errors', bad)
json.dump(out, open('event_stats.json', 'w'))
