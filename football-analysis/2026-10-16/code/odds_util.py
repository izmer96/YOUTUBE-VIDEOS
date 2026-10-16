from fractions import Fraction
def dec(fr):
    try:
        return 1.0 + float(Fraction(fr))
    except Exception:
        return None
def market_probs(d, use='fractionalValue'):
    """De-vigged (proportional) market probabilities from a Sofascore odds payload."""
    out = {}
    for m in d.get('markets', []):
        name, cg = m['marketName'], m.get('choiceGroup')
        ch = {c['name']: dec(c.get(use) or c.get('fractionalValue')) for c in m['choices']}
        if any(v is None for v in ch.values()):
            continue
        if name == 'Full time' and set(ch) == {'1', 'X', '2'}:
            inv = {k: 1 / v for k, v in ch.items()}; s = sum(inv.values())
            out['home'], out['draw'], out['away'] = inv['1'] / s, inv['X'] / s, inv['2'] / s
            out['margin_1x2'] = s - 1
        elif name == 'Both teams to score' and set(ch) == {'Yes', 'No'}:
            s = 1 / ch['Yes'] + 1 / ch['No']; out['btts'] = (1 / ch['Yes']) / s
        elif name == 'Match goals' and str(cg) in ('2.5', '3.5') and set(ch) == {'Over', 'Under'}:
            s = 1 / ch['Over'] + 1 / ch['Under']
            out['o25' if str(cg) == '2.5' else 'o35'] = (1 / ch['Over']) / s
    return out
