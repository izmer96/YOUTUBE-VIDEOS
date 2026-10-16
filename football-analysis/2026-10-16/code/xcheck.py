import json, subprocess, datetime, unicodedata, re
M = json.load(open('matches.json'))
ESPN = {17: 'eng.1', 8: 'esp.1', 23: 'ita.1', 34: 'fra.1', 35: 'ger.1', 52: 'tur.1', 7: 'uefa.champions'}
def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z]', '', s)
cur = [m for m in M if m['ut'] in ESPN and m['ts'] > datetime.datetime(2026, 7, 1).timestamp() and (m['ut'] != 7 or 'ualif' not in (m['rname'] or ''))]
dates = sorted({(m['ut'], datetime.datetime.utcfromtimestamp(m['ts']).strftime('%Y%m%d')) for m in cur})
espn = {}
for ut, d in dates:
    r = subprocess.run(['curl', '-s', '--compressed', '--max-time', '30', f'https://site.api.espn.com/apis/site/v2/sports/soccer/{ESPN[ut]}/scoreboard?dates={d}'], capture_output=True)
    try:
        js = json.loads(r.stdout)
    except Exception:
        continue
    for ev in js.get('events', []):
        c = ev['competitions'][0]['competitors']
        h = [x for x in c if x['homeAway'] == 'home'][0]; a = [x for x in c if x['homeAway'] == 'away'][0]
        espn[(ut, d, norm(h['team']['displayName'])[:5], norm(a['team']['displayName'])[:5])] = (int(h['score']), int(a['score']))
match = mism = miss = 0; mis_list = []
for m in cur:
    d = datetime.datetime.utcfromtimestamp(m['ts']).strftime('%Y%m%d')
    k = None
    for kk in espn:
        if kk[0] == m['ut'] and kk[1] == d and (kk[2] == norm(m['hn'])[:5] or kk[3] == norm(m['an'])[:5]):
            k = kk; break
    if k is None:
        miss += 1; continue
    if espn[k] == (m['hg'], m['ag']) or m['et']:
        match += 1
    else:
        mism += 1; mis_list.append((m['hn'], m['an'], m['hg'], m['ag'], espn[k]))
print(json.dumps(dict(checked=len(cur), matched=match, mismatched=mism, not_found=miss, mism=mis_list[:20])))
json.dump(dict(checked=len(cur), matched=match, mismatched=mism, not_found=miss, mism=mis_list), open('xcheck.json', 'w'))
