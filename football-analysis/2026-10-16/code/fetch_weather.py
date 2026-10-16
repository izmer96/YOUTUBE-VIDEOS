import ss, json, subprocess, datetime, time
fx = json.load(open('fixtures.json'))
out = {}
for f in fx:
    e = ss.get(f'event/{f["id"]}').get('event', {})
    v = e.get('venue') or {}
    c = v.get('venueCoordinates')
    rec = dict(venue=v.get('name'), city=(v.get('city') or {}).get('name'), capacity=v.get('capacity'))
    if c:
        lat, lon = round(c['latitude'], 3), round(c['longitude'], 3)
        r = subprocess.run(['curl', '-s', '--max-time', '30', '-A', 'football-research-script/1.0', f'https://api.met.no/weatherapi/locationforecast/2.0/compact?lat={lat}&lon={lon}'], capture_output=True)
        try:
            ts = json.loads(r.stdout)['properties']['timeseries']
            ko = datetime.datetime.utcfromtimestamp(f['ts'])
            best = min(ts, key=lambda x: abs((datetime.datetime.strptime(x['time'], '%Y-%m-%dT%H:%M:%SZ') - ko).total_seconds()))
            dt = abs((datetime.datetime.strptime(best['time'], '%Y-%m-%dT%H:%M:%SZ') - ko).total_seconds()) / 3600
            inst = best['data']['instant']['details']
            nxt = best['data'].get('next_1_hours') or best['data'].get('next_6_hours') or {}
            rec.update(temp=inst.get('air_temperature'), wind=inst.get('wind_speed'), precip=(nxt.get('details') or {}).get('precipitation_amount'),
                       symbol=(nxt.get('summary') or {}).get('symbol_code'), hours_off=dt, nxt='1h' if best['data'].get('next_1_hours') else '6h')
        except Exception as ex:
            rec['err'] = str(ex)[:100]
        time.sleep(0.3)
    out[f['id']] = rec
json.dump(out, open('weather.json', 'w'), indent=0)
for f in fx:
    w = out[f['id']]
    print(f['home'][:22], '-', f['away'][:22], '|', w.get('city'), w.get('temp'), 'C wind', w.get('wind'), 'm/s precip', w.get('precip'), w.get('nxt'), w.get('symbol'), w.get('err', ''))
