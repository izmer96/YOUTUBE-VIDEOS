import ss, json, datetime
from concurrent.futures import ThreadPoolExecutor
M = json.load(open('matches.json'))
fx = json.load(open('fixtures.json'))
BIG = {17, 8, 23, 34, 35, 52, 7, 679, 17015}
ts = lambda *a: datetime.datetime(*a).timestamp()
W = [(ts(2025, 9, 12), ts(2025, 11, 30)), (ts(2026, 1, 15), ts(2026, 5, 31))]
ids = [m['id'] for m in M if m['ut'] in BIG and any(a <= m['ts'] < b for a, b in W)]
ids += [f['id'] for f in fx]
print(len(ids), flush=True)
def f(i): return i, ss.get(f'event/{i}/odds/1/all', sleep=0.1)
out = {}
with ThreadPoolExecutor(6) as ex:
    for i, d in ex.map(f, ids): out[i] = d
print('with markets', sum('markets' in d for d in out.values()))
json.dump(out, open('odds.json', 'w'))
