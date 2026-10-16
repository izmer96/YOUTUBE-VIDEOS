"""Attach Superbet.ro odds, de-vigged implied probabilities, margins and value-vs-estimate to each fixture."""
import json

D = json.load(open('report_data.json'))
S = json.load(open('sb_odds.json'))
ev_map = S['events']
D['superbet_meta'] = dict(fetched_at=S['fetched_at'], source='superbet.ro prematch offer (public offer feed used by the site)',
                          offered=sum(1 for v in ev_map.values() if v['status'] == 'ok'), listed_no_odds=sum(1 for v in ev_map.values() if v['status'] == 'listed_no_odds'), total=len(ev_map), audit=S.get('audit'))
PAIRS = [('home', 'draw', 'away'), ('o25', 'u25'), ('o35', 'u35'), ('btts_yes', 'btts_no')]
EV_KEY = {'o25': 'o25', 'o35': 'o35', 'btts': 'btts_yes', 'home': 'home', 'draw': 'draw', 'away': 'away'}
for fx in D['fixtures']:
    v = ev_map.get(str(fx['id'])) or ev_map.get(fx['id'])
    if not v or v['status'] != 'ok':
        fx['superbet'] = dict(status=(v or {}).get('status', 'not_offered'), eventId=(v or {}).get('eventId'), matchName=(v or {}).get('matchName'))
        continue
    o = v['odds']
    implied, margin = {}, {}
    for grp in PAIRS:
        if all(k in o for k in grp):
            s = sum(1 / o[k] for k in grp)
            for k in grp:
                implied[k] = (1 / o[k]) / s
            margin['1x2' if grp[0] == 'home' else grp[0]] = s - 1
    imp = dict(home=implied.get('home'), draw=implied.get('draw'), away=implied.get('away'),
               o25=implied.get('o25'), o35=implied.get('o35'), btts=implied.get('btts_yes'))
    value = {k: (fx['final'][k] * o[EV_KEY[k]] - 1) if EV_KEY[k] in o else None for k in EV_KEY}
    fair = {k: (1 / fx['final'][k]) for k in EV_KEY}
    best = max(((k, x) for k, x in value.items() if x is not None), key=lambda t: t[1])
    fx['superbet'] = dict(status='ok', eventId=v['eventId'], matchName=v['matchName'], utcDate=v['utcDate'],
                          odds=o, implied=imp, margin=margin, value=value, fair=fair, best=dict(market=best[0], value=best[1]))
json.dump(D, open('report_data.json', 'w'))
ok = [f for f in D['fixtures'] if f['superbet']['status'] == 'ok']
print('fixtures with Superbet odds', len(ok))
pos = sorted(((f['superbet']['best']['value'], f['home'], f['away'], f['superbet']['best']['market'], f['has_market']) for f in ok), reverse=True)
print('largest positive values (final estimate x Superbet price - 1):')
for x in pos[:12]:
    print(f"  {x[0]*100:+.1f}%  {x[1]} v {x[2]}  {x[3]}  {'market-anchored' if x[4] else 'MODEL-ONLY estimate'}")
print('margins 1x2: min %.1f%% median %.1f%% max %.1f%%' % tuple(100 * x for x in (
    min(f['superbet']['margin']['1x2'] for f in ok), sorted(f['superbet']['margin']['1x2'] for f in ok)[len(ok) // 2], max(f['superbet']['margin']['1x2'] for f in ok))))
