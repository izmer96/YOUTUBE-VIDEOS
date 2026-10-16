import ss, json
UTS = [17,8,23,34,35,52,37,38,238,18,54,53,182,44,98,7,679,17015,172,39,20,185,45,36,202,215,40,170,247,171,210,218]
le = json.load(open('league_events.json'))
for ut in UTS:
    s = ss.get(f'unique-tournament/{ut}/seasons')
    if len(s.get('seasons', [])) < 3: continue
    se = s['seasons'][2]
    evs = []
    for p in range(40):
        d = ss.get(f'unique-tournament/{ut}/season/{se["id"]}/events/last/{p}')
        evs += d.get('events', [])
        if not d.get('hasNextPage'): break
    le[f'{ut}_{se["id"]}'] = {'ut': ut, 'season': se['id'], 'name': se['name'], 'events': evs}
    print(ut, se['name'], len(evs), flush=True)
json.dump(le, open('league_events.json', 'w'))
