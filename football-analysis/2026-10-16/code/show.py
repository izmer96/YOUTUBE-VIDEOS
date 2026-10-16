import json, sys
A = json.load(open('analysis.json')); R = A['results']
def f2(v): return round(v, 2) if isinstance(v, float) else v
def show(q, rows=True):
    for r in R:
        f = r['fixture']
        if q.lower() not in (f['home'] + ' vs ' + f['away']).lower(): continue
        print('#####', f['home'], 'vs', f['away'], f['comp'], 'λ', [f2(x) for x in r['lam']], 'base', [f2(x) for x in r['lam_base']])
        print('  model', {k: f2(v) for k, v in r['model'].items()}); print('  market', {k: f2(v) for k, v in r['market'].items()})
        print('  goals-only alt', {k: f2(v) for k, v in r['alt_goals_only'].items()}); print('  final', {k: f2(v) for k, v in r['final'].items()})
        print('  top scores', [(s, round(p, 3)) for p, s in r['top_scores']])
        for side in ('home', 'away'):
            t = r[side]; p = t['prof']
            print(f"  == {t['name']} [{t['grp']}] str {f2(t['str'])} att {f2(t['att'])} def {f2(t['dfn'])} tier {t['tier_own']} / in-opp-league {t['tier_in_opp_league']} nr(GF,GA vs avg own-league) {[f2(x) for x in t['nr']]} SoS {f2(t['sos'])}")
            for key in ('all', 'home', 'away', 'last10', 'last5', 'league', 'uefa', 'cup'):
                a = p[key]
                if a.get('n'):
                    print(f"     {key:7s} n{a['n']} {a['w']}-{a['d']}-{a['l']} GF {a['gf']} GA {a['ga']} gpg {a['gf_pg']:.2f}/{a['ga_pg']:.2f} O2.5 {a['o25']:.0%} O3.5 {a['o35']:.0%} BTTS {a['btts']:.0%} CS {a['cs']:.0%} FTS {a['fts']:.0%} xG {a.get('xgf_pg', float('nan')):.2f}/{a.get('xga_pg', float('nan')):.2f} (n{a.get('xg_n',0)}) SoT {a.get('sotf_pg', float('nan')):.1f}/{a.get('sota_pg', float('nan')):.1f} BC {a.get('bcf_pg', float('nan')):.1f}/{a.get('bca_pg', float('nan')):.1f} oppstr {f2(a.get('opp_str_avg'))}")
            if rows:
                for x in t['rows']:
                    print(f"       {x['date']} {x['comp'][:16]:16s} {x['venue']} {x['opp'][:22]:22s} {x['gf']}-{x['ga']} (HT {x['htf']}-{x['hta']}) xG {x.get('xgf','-')}-{x.get('xga','-')} opp {f2(x['opp_str'])}{' RED' if x['red_for'] or x['red_against'] else ''}")
            print('     absent:', [(x['name'], x['pos'], x['status'], f"{x['min_share']:.0%}", f"{x['goals']}g{x['assists']}a", x['reason']) for x in t['absent']], 'att×', f2(t['att_mult']), 'opp×', f2(t['opp_mult']))
            print('     mgr:', t['mgr'], 'rest:', t['rest'])
            print('     comparables (band', t['comp_band'], '):', [(c['date'], c['venue'], c['opp'], f"{c['gf']}-{c['ga']}", f"xG {c.get('xgf','-')}-{c.get('xga','-')}", round(c['dist'], 2), c['season']) for c in t['comps']])
        print('  h2h', [(h['date'], h['hn'], h['hg'], h['ag'], h['an']) for h in r['h2h']])
        print('  weather', r['weather'], 'baseline', {k: f2(v) for k, v in (r['baseline'] or {}).items()})
if __name__ == '__main__':
    for q in sys.argv[1:]:
        show(q)
