
"""
Documentation of scipy.stats.mstats.mquantiles

Samples quantile are defined by 
    Q(p) = (1-gamma)*x[j] + gamma*x[j+1], 
where x[j] is the j-th order statistic, and gamma is a function of j = floor(n*p + m), 
m = alphap + p*(1 - alphap - betap) and g = n*p + m - j.

Reinterpreting the above equations to compare to R lead to the equation: 
    p(k) = (k - alphap)/(n + 1 - alphap - betap)

Typical values of (alphap,betap) are:
- (0,1) : p(k) = k/n : linear interpolation of cdf (R type 4)
- (.5,.5) : p(k) = (k - 1/2.)/n : piecewise linear function (R type 5)
- (0,0) : p(k) = k/(n+1) : (R type 6)
- (1,1) : p(k) = (k-1)/(n-1): p(k) = mode[F(x[k])]. (R type 7, R default)
- (1/3,1/3): p(k) = (k-1/3)/(n+1/3): Then p(k) ~ median[F(x[k])]. The resulting quantile estimates are approximately median-unbiased regardless of the distribution of x. (R type 8)
- (3/8,3/8): p(k) = (k-3/8)/(n+1/4): Blom. The resulting quantile estimates are approximately unbiased if x is normally distributed (R type 9)
- (.4,.4) : approximately quantile unbiased (Cunnane)
- (.35,.35): APL, used with PWM

Parameters default:
* R:        quantile(x, probs = seq(0, 1, 0.25), na.rm = FALSE, names = TRUE, type = 7)
* Python:   mquantiles(a, prob=[0.25, 0.5, 0.75], alphap=0.4, betap=0.4, axis=None, limit=()
"""

from scipy.stats import mstats as sp_mstats

import numpy as np
import numpy.ma as np_ma 
from numpy.ma import masked, nomask


def canonical_quantile_1D(x, probs, na_rm = False, names = True, type = 7):
    m_indice = lambda p, i: {1: 0, 2: 0, 3: -0.5, 4: 0, 5: 0.5, 6: p, 7: 1-p, \
                             8:(p+1)/3 , 9:(2*p+3)/8, 10:.4 + .2 * p}[i]
    j_indice = lambda p, n, m: np.int_(np.floor(n*p + m))
    g_indice = lambda p, n, m, j: p * n + m - j
    ind_sorted = np.argsort(x)
    sorted_x = x[ind_sorted]
    N = x.size
    m = m_indice(probs, type)
    j = j_indice(probs, N, m)
    x1 = sorted_x[j-1] # indexes start at 0...
    x2 = sorted_x[j]
    g = g_indice(probs, N, m, j)
    if type==1:
        if g > 0:                       gamma=1
        else:                           gamma=0
    elif type==2:
        if g > 0:                       gamma=1
        else:                           gamma=0.5
    elif type==3:
        if g == 0 and j%2 == 0:         gamma=0;
        else:                           gamma=1;
    elif type >= 4:                     gamma=g;
    return (1-gamma) * x1 + gamma * x2;

def warp_quantile(x, probs, na_rm = False, names = True, type = 7):
    abp = lambda typ: {4: (0, 1),     5: (.5 , .5),    6: (0 , 0),  7:(1 , 1), 
           8: (1/3, 1/3), 9: (3/8 , 3/8), 10: (.4,.4)}[typ]
    # for given p probability, compute the (p,m,j) indices and extract the 
    # sorted (x1,x2)=(x_j,x_{j+1}) pair 
    if type==1:
        alphap, betap = 0, 0
    elif type==2:
        alphap, betap = 0, 0
    elif type==3:
        alphap, betap = 0, 0  
    elif type>=4:
        alphap, betap = abp(type)
        sp_mstats.mquantiles(x, prob=probs, alphap=alphap, betap=betap)
     
def wquantile_1D(x, probs, weights):
    """
    Compute the weighted quantile of a 1D numpy array.
    """
    # Check the data
    if not isinstance(x, np.matrix):
        x = np.asarray(x)
    if not isinstance(weights, np.matrix):
        weights = np.asarray(weights)
    nd = x.ndim
    if nd != 1:
        raise TypeError("data must be a one dimensional array")
    ndw = weights.ndim
    if ndw != 1:
        raise TypeError("weights must be a one dimensional array")
    if x.shape != weights.shape:
        raise TypeError("the length of data and weights must be the same")
    if (not all(probs > 1.) or all(probs < 0.)):
        raise ValueError("quantile must have a value between 0. and 1.")
    # Sort the data
    ind_sorted = np.argsort(x)
    sorted_x = x[ind_sorted]
    sorted_weights = weights[ind_sorted]
    # Compute the auxiliary arrays
    Sn = np.cumsum(sorted_weights)
    #assert Sn != 0, "The sum of the weights must not be zero"
    Pn = (Sn-0.5*sorted_weights)/np.sum(sorted_weights)
    # Get the value of the weighted median
    return np.interp(probs, Pn, sorted_x)
        
        
def mquantiles(a, prob=list([.25,.5,.75]), alphap=.4, betap=.4, axis=None,
               limit=()):
    """
    source: https://github.com/scipy/scipy/blob/master/scipy/stats/mstats_basic.py
    """
    def _quantiles1D(data,m,p):
        x = np.sort(data.compressed())
        n = len(x)
        if n == 0:
            return np_ma.array(np.empty(len(p), dtype=float), mask=True)
        elif n == 1:
            return np_ma.array(np.resize(x, p.shape), mask=nomask)
        aleph = (n*p + m)
        k = np.floor(aleph.clip(1, n-1)).astype(int)
        gamma = (aleph-k).clip(0,1)
        return (1.-gamma)*x[(k-1).tolist()] + gamma*x[k.tolist()]

    data = np_ma.array(a, copy=False)
    if data.ndim > 2:
        raise TypeError("Array should be 2D at most !")

    if limit:
        condition = (limit[0] < data) & (data < limit[1])
        data[~condition.filled(True)] = masked

    p = np.array(prob, copy=False, ndmin=1)
    m = alphap + p*(1.-alphap-betap)
    # Computes quantiles along axis (or globally)
    if (axis is None):
        return _quantiles1D(data, m, p)

    return np_ma.apply_along_axis(_quantiles1D, axis, data, m, p)
