import json, datetime, numpy as np, importlib
import commentary, autotext
D = json.load(open('report_data.json'))
M = json.load(open('matches.json'))
UT = {'PL': 17, 'LaLiga': 8, 'SerieA': 23, 'Ligue1': 34, 'Bundesliga': 35, 'SuperLig': 52, 'UCL': 7, 'UEL': 679, 'UECL': 17015}
xg_base = {}
for c, u in UT.items():
    xs = [m['h_expectedGoals'] + m['a_expectedGoals'] for m in M if m['ut'] == u and 'h_expectedGoals' in m and m['ts'] > datetime.datetime(2026, 6, 15).timestamp()]
    xg_base[c] = float(np.mean(xs)) if xs else None
print({k: round(v, 2) if v else None for k, v in xg_base.items()})
for fx in D['fixtures']:
    fx['auto'] = {}
    for k in ('o25', 'o35', 'btts', 'home', 'away'):
        man = commentary.get(fx['home'], fx['away'], k)
        fx['auto'][k] = dict(counter=autotext.counter(fx, k), comp=autotext.comp_verdict(fx, k),
                             manual_counter=(man or {}).get('counter'), manual_assessment=(man or {}).get('assessment'))
    fx['tactical'] = autotext.tactical(fx, xg_base.get(fx['comp']))
    best, flags = autotext.weak_flags(fx)
    fx['weak'] = dict(best=best, flags=flags)
D['xg_base'] = xg_base
json.dump(D, open('report_data.json', 'w'))
# preview a few
for fx in D['fixtures'][:3]:
    print(fx['home'], fx['away']); print(' tactical:', fx['tactical']); print(' counter o25:', fx['auto']['o25']['counter']); print(' comp o25:', fx['auto']['o25']['comp']); print(' flags:', fx['weak']['flags'])
weak = [fx for fx in D['fixtures'] if fx['weak']['best'] < 0.55 or len(fx['weak']['flags']) >= 2]
print('weak/conflicting fixtures:', len(weak))
