import json, glob, unicodedata, re, datetime
from difflib import SequenceMatcher
fx = json.load(open('work/fixtures.json'))
evs = {}
for f in sorted(glob.glob('sb/day_*.json')):
    for x in json.load(open(f))['data']:
        if x.get('sportId') == 5:
            evs[x['eventId']] = x
evs = list(evs.values())
STOP = {'fc', 'cf', 'sk', 'ac', 'as', 'sc', 'fk', 'rc', 'cd', 'ud', 'ssc', 'afc', 'tsg', 'sv', 'vfb', 'bk', 'if', 'aif', 'ss', 'club', 'de', 'kv', 'rsc', 'kaa', 'vv', 'gnk', 'hnk', 'nk', 'tc', 'jk', 'sk', 'fk', 'pfc', 'ofk', 'cs', 'kf', 'hsv', '1', 'st', 'osc'}
ALIAS = {'bayern munchen': 'bayern', 'bayern münchen': 'bayern', 'internazionale': 'inter', 'crvena zvezda': 'steaua rosie', 'fc kobenhavn': 'copenhaga', 'kobenhavn': 'copenhaga',
         'real racing club': 'racing santander', 'deportivo de a coruna': 'deportivo la coruna'}
def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    s = re.sub(r"[^a-z0-9 ]", ' ', s)
    return ' '.join(w for w in s.split() if w not in STOP)
def sim(a, b):
    a, b = norm(a), norm(b)
    if not a or not b: return 0
    ta, tb = set(a.split()), set(b.split())
    jac = len(ta & tb) / max(1, len(ta | tb))
    return max(SequenceMatcher(None, a, b).ratio(), jac, 1.0 if (a in b or b in a) and min(len(a), len(b)) >= 4 else 0)
out = []
for f in fx:
    cands = []
    for x in evs:
        t = datetime.datetime.strptime(x['utcDate'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=datetime.timezone.utc).timestamp()
        if abs(t - f['ts']) > 3 * 3600: continue
        parts = x['matchName'].split('·')
        if len(parts) != 2: continue
        s = sim(f['home'], parts[0]) + sim(f['away'], parts[1])
        cands.append((s, x['eventId'], x['matchName'], x['utcDate'], x['tournamentId']))
    cands.sort(reverse=True)
    best = cands[0] if cands else None
    out.append(dict(fid=f['id'], comp=f['comp'], home=f['home'], away=f['away'], ts=f['ts'], best=best, alts=cands[1:3]))
low = [o for o in out if not o['best'] or o['best'][0] < 1.3]
for o in out:
    b = o['best']
    flag = '  <-- CHECK' if (not b or b[0] < 1.3) else ''
    print(f"{o['comp']:9s} {o['home'][:22]:22s} v {o['away'][:22]:22s} -> {b[2] if b else None} ({b[0]:.2f}){flag}" if b else f"{o['home']} v {o['away']} -> NONE")
json.dump(out, open('work/sb_map_auto.json', 'w'))
print('needs check:', len(low))
