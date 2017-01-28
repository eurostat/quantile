#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
.. quantile

**About**

This code implements sample quantiles. It aims at supporting the following 
publication:

    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

**Usage**

    >>> q = quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
"""

import numpy as np
import numpy.ma as np_ma 

try:
    import pandas as pd
except:
    class pd(): # dummy class
        DataFrame = type('dummy',(object,))
        Series = type('dummy',(object,))

        
DEF_PROBS =     [0, 0.25, 0.5, 0.75, 1]
DEF_TYPE =      7
DEF_METHOD =    'DIRECT'
DEF_LIMIT =     (0,1)
DEF_NARM =      False

        
def quantile(x, probs = DEF_PROBS, typ = DEF_TYPE, method = DEF_METHOD, 
             limit = DEF_LIMIT, na_rm = DEF_NARM, is_sorted = False):
    """Compute the sample quantiles of any vector distribution.
    
        >>> quantile(x, probs=DEF_PROBS, type = DEF_TYPE, method=DEF_METHOD, limit=DEF_LIMIT, 
             na_rm = DEF_NARM, is_sorted=False)
    """
    
    ## various parameter checkings
    
    # check the data
    if isinstance(x, (pd.DataFrame,pd.Series)):
        try:        x = x.values
        except:     raise TypeError("conversion type error for input dataset")        
    elif not isinstance(x, np.ndarray):
        try:        x = np.asarray(x)
        except:     raise TypeError("wrong type for input dataset")        
    ndim = x.ndim
    if ndim > 2:
        raise ValueError("array should be 2D at most !")

    # check the probs
    if isinstance(probs, (pd.DataFrame,pd.Series)):
        try:        probs = probs.values
        except:     raise TypeError("conversion type error for input probabilities")        
    elif not isinstance(probs, np.ndarray):
        try:        probs = np.array(probs, copy=False, ndmin=1)
        except:     raise TypeError("wrong type for input probabilities")      
    # adjust the values: this is taken from R implementation, where alues up to 
    # 2e-14 outside that range are accepted and moved to the nearby endpoint
    eps = 100*np.finfo(np.double).eps
    if (probs < -eps).any() or (probs > 1+eps).any():
        raise ValueError("probs values outside [0,1]")
    probs = np.maximum(0, np.minimum(1, probs))
    
    #weights = np.ones(x)
    ## check the weights
    #if isinstance(weights, (pd.DataFrame,pd.Series)):
    #    try:        weights = weights.values
    #    except:     raise TypeError("conversion type error for input weights")        
    #elif not isinstance(weights, np.ndarray):
    #    try:        weights = np.asarray(weights)
    #    except:     raise TypeError("wrong type for input weights")
    #if x.shape != weights.shape:
    #    raise ValueError("the length of data and weights must be the same")

    # check parameter typ value
    if typ not in range(1,11):
        raise ValueError("typ should be an integer in range [1,10]!")

    # check parameter method value
    if method not in ('DIRECT', 'MQUANT'):
        raise ValueError("method should be either 'DIRECT' or 'MQUANT'!")
        
    # check parameter method
    if not isinstance(is_sorted,bool):
        raise TypeError("wrong type for boolean flag is_sorted!")

     # check parameter na_rm
    if not isinstance(na_rm,bool):
        raise TypeError("wrong type for boolean flag na_rm!")

     # check parameter limit
    if not isinstance(limit, (list, tuple, np.array)):
        raise TypeError("wrong type for boolean flag limit!")
    if len(limit) != 2:
        raise ValueError("the length of limit must be 2")
    
    ## algorithm implementation
        
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

    def _canonical_quantile1D(typ, sorted_x, probs):
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

    def _mquantile1D(typ, sorted_x, probs):
        """Compute the quantiles of a 1D numpy array following the implementation
        of the _quantiles1D function of mquantiles.
        source: https://github.com/scipy/scipy/blob/master/scipy/stats/mstats_basic.py
        """
        N = len(sorted_x) 
        if N == 0:
            return np_ma.array(np.empty(len(probs), dtype=float), mask=True)
        elif N == 1:
            return np_ma.array(np.resize(sorted_x, probs.shape), mask=np_ma.nomask)
        # note that, wrt to the original implementation (see source code mentioned
        # above), we also added the definitions of (alphap,betap) for typ in [1,2,3]
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

    def _wquantile1D(typ, x, probs, weights): # not used
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
            
    ## actual calculation

    # select method
    if method == 'DIRECT':
        _quantile1D = _canonical_quantile1D
        
    elif method == 'MQUANT': 
        _quantile1D = _mquantile1D

    # define input data
    if na_rm is True:
        data = np_ma.array(x, copy=True, mask = np.isnan(x))
        # weights = np_ma.array(x, copy=True, mask = np.isnan(x))
    elif np.isnan(x).any():
        raise ValueError("missing values and NaN's not allowed if 'na_rm' is FALSE")
    else:
        data = np_ma.array(x, copy=False)

    # filter the input data 
    if limit is True:
        condition = (limit[0] < data) & (data < limit[1])
        data[~condition.filled(True)] = np_ma.masked
       
    # sort if not already the case  
    if is_sorted is False:
        # ind_sorted = np.argsort(x)
        # sorted_x = x[ind_sorted]
        sorted_data = np_ma.sort(data.compressed())

    # Computes quantiles along axis (or globally)
    if ndim == 1:
        return _quantile1D(typ, data if is_sorted else sorted_data, probs)
    else:
        return np_ma.apply_along_axis(_quantile1D, 1, typ,                         \
                                      data if is_sorted else sorted_data, probs)
        
def IQR(x, typ = DEF_TYPE, method = DEF_METHOD, na_rm = DEF_NARM, is_sorted = False):
    return np.diff(quantile(x, probs = [0.25, 0.75], typ = typ, method = method,    \
             limit = DEF_LIMIT, na_rm = na_rm, is_sorted = is_sorted))
