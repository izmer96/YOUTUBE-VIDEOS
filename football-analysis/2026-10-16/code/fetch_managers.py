import ss, json, os, time
from concurrent.futures import ThreadPoolExecutor
while not os.path.exists('lineups_upcoming.json'):
    time.sleep(10)
lp = json.load(open('lineups_past.json'))
fx = json.load(open('fixtures.json'))
ids = sorted(int(i) for i in lp) + [f['id'] for f in fx]
def f(i): return i, ss.get(f'event/{i}/managers', sleep=0.1)
out = {}
with ThreadPoolExecutor(6) as ex:
    for i, d in ex.map(f, ids): out[i] = d
json.dump(out, open('managers.json', 'w'))
print('done', len(out))
