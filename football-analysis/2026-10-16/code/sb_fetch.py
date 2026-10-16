import json, subprocess, time, datetime
m = json.load(open('work/sb_map_auto.json'))
MISSING = {'Trabzonspor|Heart of Midlothian', 'Getafe|FC Lugano', 'FK Kauno Žalgiris|SK Brann', 'FC Iberia 1999|Mjällby AIF',
           'FC Thun|HNK Hajduk Split', 'Lincoln Red Imps|FC Twente', 'FK Borac Banja Luka|Kuopion Palloseura', 'AGF|KF Egnatia'}
fetched_at = datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')
out = {}
for o in m:
    key = f"{o['home']}|{o['away']}"
    if key in MISSING or not o['best']:
        out[o['fid']] = dict(status='not_offered'); continue
    eid = o['best'][1]
    r = subprocess.run(['curl', '-s', '--compressed', '--max-time', '40', '-A', 'Mozilla/5.0',
                        f'https://production-superbet-offer-ro.freetls.fastly.net/v2/ro-RO/events/{eid}'], capture_output=True)
    d = json.loads(r.stdout)
    open(f'sb/events/{eid}.json', 'w').write(r.stdout.decode())
    e = d['data'][0]
    odds = {}
    for x in e['odds']:
        if x.get('status') != 'active':
            continue
        mid, nm, sbv = x.get('marketId'), x.get('name'), x.get('specialBetValue')
        if mid == 547 and nm in ('1', 'X', '2'):
            odds[{'1': 'home', 'X': 'draw', '2': 'away'}[nm]] = x['price']
        elif mid == 200734 and sbv in ('2.5', '3.5') and nm in (f'Peste {sbv}', f'Sub {sbv}'):
            odds[('o' if nm.startswith('Peste') else 'u') + sbv.replace('.', '')] = x['price']
        elif mid == 539 and nm in ('Da', 'Nu'):
            odds['btts_yes' if nm == 'Da' else 'btts_no'] = x['price']
    out[o['fid']] = dict(status='ok', eventId=eid, matchName=e['matchName'], utcDate=e['utcDate'], tournamentId=e['tournamentId'],
                         betradarId=e.get('betradarId'), odds=odds,
                         url=f"https://superbet.ro/pariuri-sportive/fotbal/{eid}")
    time.sleep(0.2)
json.dump(dict(fetched_at=fetched_at, events=out), open('work/sb_odds.json', 'w'), indent=1)
ok = [v for v in out.values() if v['status'] == 'ok']
full = [v for v in ok if len(v['odds']) == 9]
print('fetched', fetched_at, 'ok', len(ok), 'all 9 prices', len(full))
for fid, v in out.items():
    if v['status'] == 'ok' and len(v['odds']) < 9:
        print('  partial', v['matchName'], sorted(v['odds']))
