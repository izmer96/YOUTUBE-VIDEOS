import ss, json, datetime, sys
teams = json.load(open('teams.json'))
cut = datetime.datetime(2025, 1, 1).timestamp()
allev = {}
for tid, name in teams.items():
    evs = []
    for p in range(8):
        d = ss.get(f'team/{tid}/events/last/{p}')
        e = d.get('events', [])
        evs += e
        if not e or min(x['startTimestamp'] for x in e) < cut or not d.get('hasNextPage'):
            break
    allev[tid] = evs
    print(name, len(evs), flush=True)
json.dump(allev, open('team_events.json', 'w'))
