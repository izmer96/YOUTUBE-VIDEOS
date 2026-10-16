import json, os, time, hashlib, subprocess, urllib.parse
CACHE = os.path.join(os.path.dirname(__file__), '..', 'cache')
BASE = 'https://api.sofascore.com/api/v1/'
UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36'
def get(path, refresh=False, sleep=0.25):
    url = path if path.startswith('http') else BASE + path
    fn = os.path.join(CACHE, hashlib.md5(url.encode()).hexdigest() + '.json')
    if os.path.exists(fn) and not refresh:
        with open(fn) as f:
            return json.load(f)
    for attempt in range(4):
        r = subprocess.run(['curl', '-s', '--compressed', '--max-time', '40', '-A', UA, url], capture_output=True)
        try:
            d = json.loads(r.stdout)
            break
        except Exception:
            time.sleep(2 ** attempt)
    else:
        d = {'error': {'code': -1, 'message': r.stdout[:200].decode(errors='ignore')}}
    if not ('error' in d and d['error'].get('code') in (-1, 403, 429)):
        with open(fn, 'w') as f:
            json.dump(d, f)
    time.sleep(sleep)
    return d
