#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
.. quantile

**About**

Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
in Proc. New Techniques and Technologies for Statistics.

**Contents**
"""



import numpy as np
import numpy.ma as np_ma 
from numpy.ma import masked, nomask

def quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1), is_sorted=False):
    """Compute the sample quantiles of any vector distribution.
    
        >>> q = quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
        
    Arguments
    ---------
    x : numpy.array
        input vector data; 2D arrays are also accepted.
    na_rm : bool
        default: `na_rm=False`.
    type : int
        default: `type=7`.
    method : str
        string defining the estimation method
    limit: list,tuple
    
    Returns
    -------
    
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
    * Python:   mquantiles(a, prob=[0.25, 0.5, 0.75], alphap=0.4, betap=0.4, axis=None, limit=())
    """
    
    # check the data
    if not isinstance(x, np.ndarray):
        try:
            x = np.asarray(x)
        except:
            raise TypeError("wrong type for input dataset")        
    ndim = x.ndim
    if ndim > 2:
        raise TypeError("array should be 2D at most !")
    if not isinstance(probs, np.ndarray):
        try:
            probs = np.array(probs, copy=False, ndmin=1)
        except:
            raise TypeError("wrong type for input probabilities")
            
    weights = np.ones(x)
    if not isinstance(weights, np.ndarray):
        try:
            weights = np.asarray(weights)
        except:
            raise TypeError("wrong type for input weights")
    if x.shape != weights.shape:
        raise TypeError("the length of data and weights must be the same")

    if method not in ('DIRECT', 'MQUANT'):
        raise ValueError("method should be either 'DIRECT' or 'MQUANT'!")
        
    data = np_ma.array(x, copy=False)

    if limit:
        condition = (limit[0] < data) & (data < limit[1])
        data[~condition.filled(True)] = masked
        
    def gamma_indice(g, j, typ):
        if typ==1:
            if g > 0:                       gamma=1
            else:                           gamma=0
        elif typ==2:
            if g > 0:                       gamma=1
            else:                           gamma=0.5
        elif typ==3:
            if g == 0 and j%2 == 0:         gamma=0;
            else:                           gamma=1;
        elif typ >= 4:                      gamma=g;
        return gamma

    def _canonical_quantile1D(typ, sorted_x, probs, na_rm = False):
        """Compute the quantile of a 1D numpy array using the canonical/direct
        approach derived from the original algorithm from Hyndman & Fan.
        """
        # inspired by the _quantiles1D function of mquantiles
        N = len(sorted_x) # sorted_x.size
        m_indice = lambda p, i: {1: 0, 2: 0, 3: -0.5, 4: 0, 5: 0.5, 6: p, 7: 1-p, \
                                 8:(p+1)/3 , 9:(2*p+3)/8, 10:.4 + .2 * p}[i]
        j_indice = lambda p, n, m: np.int_(np.floor(n*p + m))
        g_indice = lambda p, n, m, j: p * n + m - j
        m = m_indice(probs, type)
        j = j_indice(probs, N, m)
        x1 = sorted_x[j-1] # indexes start at 0...
        x2 = sorted_x[j]
        g = g_indice(probs, N, m, j)
        gamma = gamma_indice(g, j, typ);
        return (1-gamma) * x1 + gamma * x2;

    def _mquantile1D(typ, sorted_x, probs, na_rm = False):
        """Compute the quantiles of a 1D numpy array following the implementation
        of the _quantiles1D function of mquantiles.
        source: https://github.com/scipy/scipy/blob/master/scipy/stats/mstats_basic.py
        """
        N = len(sorted_x) 
        if N == 0:
            return np_ma.array(np.empty(len(probs), dtype=float), mask=True)
        elif N == 1:
            return np_ma.array(np.resize(sorted_x, probs.shape), mask=nomask)
        abp_indice = lambda typ: {1: (0, 1), 2: (0, 1), 3: (-.5, -1.5), 4: (0, 1),  \
                           5: (.5 , .5),  6: (0 , 0),  7:(1 , 1), 8: (1/3, 1/3),    \
                            9: (3/8 , 3/8), 10: (.4,.4)}[typ]
        alphap, betap = abp_indice[type]
        m = alphap + probs * (1.-alphap-betap)
        aleph = (probs * N + m)
        j = np.floor(aleph.clip(1, N-1)).astype(int)
        g = (aleph-j).clip(0,1)
        gamma = gamma_indice(g, j, typ);
        return (1.-gamma)*sorted_x[(j-1).tolist()] + gamma*sorted_x[j.tolist()]

    def _wquantile1D(typ, x, probs, weights):
        """Compute the weighted quantile of a 1D numpy array.
        """
        # Check the data
        ind_sorted = np.argsort(x)
        sorted_x = x[ind_sorted]
        sorted_weights = weights[ind_sorted]
        # Compute the auxiliary arrays
        Sn = np.cumsum(sorted_weights)
        #assert Sn != 0, "The sum of the weights must not be zero"
        Pn = (Sn-0.5*sorted_weights)/np.sum(sorted_weights)
        # Get the value of the weighted median
        return np.interp(probs, Pn, sorted_x)
        
    if method == 'DIRECT':
        _quantile1D = _canonical_quantile1D
        
    elif method == 'MQUANT': 
        _quantile1D = _mquantile1D

    if is_sorted is False:
        # ind_sorted = np.argsort(x)
        # sorted_x = x[ind_sorted]
        sorted_data = np.sort(data.compressed())

    # Computes quantiles along axis (or globally)
    if ndim == 1:
        return _quantile1D(type, data if is_sorted is False else sorted_data, probs)
    else:
        return np_ma.apply_along_axis(_quantile1D, 1, type,                         \
                                      data if is_sorted is False else sorted_data, probs)

    
        