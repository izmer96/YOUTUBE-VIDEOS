import ss, json, sys
UTS = [17,8,23,34,35,52,37,38,172,238,39,20,185,45,36,170,247,171,202,215,266,210,704,222,720,709,198,40,197,152,671,682,212,211,187,41,218,742,1542,
       18,54,53,182,44,98,239,216,22, 7,679,17015]
out = {}
for ut in UTS:
    s = ss.get(f'unique-tournament/{ut}/seasons')
    seasons = s.get('seasons', [])[:2]
    for se in seasons:
        evs = []
        for p in range(40):
            d = ss.get(f'unique-tournament/{ut}/season/{se["id"]}/events/last/{p}', refresh=(se is seasons[0]))
            evs += d.get('events', [])
            if not d.get('hasNextPage'):
                break
        out[f'{ut}_{se["id"]}'] = {'ut': ut, 'season': se['id'], 'name': se['name'], 'events': evs}
        print(ut, se['name'], len(evs), flush=True)
json.dump(out, open('league_events.json', 'w'))
