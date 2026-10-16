import numpy as np
from scipy.optimize import minimize
from model import score_matrix, markets
KEYS = ('home', 'draw', 'away', 'o25', 'o35', 'btts')
def fit_dc(target, lh0=1.4, la0=1.2):
    """Single Dixon-Coles distribution (lh, la, rho) closest (least squares) to the target market probabilities."""
    keys = [k for k in KEYS if k in target]
    def loss(x):
        lh, la, rho = np.exp(x[0]), np.exp(x[1]), x[2]
        m = markets(score_matrix(lh, la, rho))
        return sum((m[k] - target[k]) ** 2 for k in keys)
    best = None
    for start in ((np.log(lh0), np.log(la0), -0.05), (np.log(1.5), np.log(1.0), 0.0)):
        r = minimize(loss, start, method='L-BFGS-B', bounds=[(-2.5, 1.8), (-2.5, 1.8), (-0.25, 0.25)])
        if best is None or r.fun < best.fun:
            best = r
    lh, la, rho = np.exp(best.x[0]), np.exp(best.x[1]), best.x[2]
    P = score_matrix(lh, la, rho)
    return lh, la, rho, P, float(np.sqrt(best.fun / len(keys)))
