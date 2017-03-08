#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
.. quantile

**Description**

Compute empirical quantiles of a variable with sample data corresponding to given probabilities. 

    >>> q = quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
    
**Usage**

To estimate the quantiles, one can run:
    
    >>> from quantile import quantile
    >>> probs, typ, method, limit = ...
    >>> data = ...
    >>> quant = quantile(data, probs, typ=type, method=method, limit=limit)

**About**

This code is intended as a proof of concept for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
"""

from __future__ import division, print_function, absolute_import


import warnings

#__all__ = ['quantile', 'quartile', 'quintile', 'IQR',
#           'Quantile', 'Quartile', 'Quintile']


import numpy as np
import numpy.ma as np_ma 

try:
    import pandas as pd
except:
    class pd(): # dummy class
        DataFrame = type('dummy',(object,))
        Series = type('dummy',(object,))
        
# list of algorithms implemented
ALGORITHMS =    [ (1, '[1] inverted empirical CDF'),                                      \
                 (2, '[2] inverted empirical CDF with averaging at discontinuities'),     \
                 (3, '[3] observation closest to qN (piecewise linear function)'),        \
                 (4, '[4] linear interpolation of the empirical CDF'),                    \
                 (5, '[5] Hazen''s model (piecewise linear function)'),                   \
                 (6, '[6] Weibull quantile'),                                             \
                 (7, '[7] interpolation points divide sample range into n-1 intervals'),  \
                 (8, '[8] unbiased median (regardless of the distribution)'),             \
                 (9, '[9] approximate unbiased estimate for a normal distribution'),      \
                 (10, '[10] Cunnane''s definition (approximately unbiased)'),             \
                 (11, '[11] Filliben''s estimate')                                        \
                 ]   
TYPES =         [a[0] for a in ALGORITHMS] # range(1,11+1)
DEF_TYPE =      7

APPROACHES =    [('DIRECT','[DIRECT] canonical application of quantile algorithm'), \
                 ('INHERIT','[INHERIT] extension of already existing method')]
METHODS =       [a[0] for a in APPROACHES] # range(1,11+1)
DEF_METHOD =    'DIRECT'

DEF_PROBS =     [0, 0.25, 0.5, 0.75, 1]
DEF_LIMIT =     (0,1)
DEF_NARM =      False
 
# specialized quantiles
SQUANTILES =    [ (2, 'M2 - median'),                         \
                  (3, 'T3 - terciles'),                       \
                  (4,'Qu4 - quartiles'),                      \
                  (5,'Q5 - quintiles'),                       \
                  (6,'S6 - sextiles'),                        \
                  (10,'D10 - deciles'),                       \
                  (12,'Dd12 - duo-deciles'),                  \
                  (20,'V - ventiles'),                        \
                  (100,'P - percentiles') ]        
SPROBS =        dict([(q[0],np.linspace(0,1,q[0]+1)[1:-1]) \
                      for q in SQUANTILES])

#==============================================================================
# QUANTILE METHOD
#==============================================================================
       
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
    if typ not in TYPES:
        raise ValueError("typ should be an integer in range [1,{}]!".format(TYPES))

    # check parameter method value
    if method not in METHODS:
        raise ValueError("method should be in {}!".format(METHODS))
        
    # check parameter method
    if not isinstance(is_sorted, bool):
        raise TypeError("wrong type for boolean flag is_sorted!")

     # check parameter na_rm
    if not isinstance(na_rm, bool):
        raise TypeError("wrong type for boolean flag na_rm!")

     # check parameter limit
    if not isinstance(limit, (list, tuple, np.ndarray)):
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
            gamma = np.zeros(len(j))
            gamma[g != 0 or j%2 == 1] = 1;
        elif typ >= 4:                      gamma=g;
        return gamma

    def _canonical_quantile1D(typ, sorted_x, probs):
        """Compute the quantile of a 1D numpy array using the canonical/direct
        approach derived from the original algorithms from Hyndman & Fan, Cunane
        and Filliben.
        """
        # inspired by the _quantiles1D function of mquantiles
        N = len(sorted_x) # sorted_x.count() 
        m_indice = lambda p, i: {1: 0, 2: 0, 3: -0.5, 4: 0, 5: 0.5,         \
                                 6: p, 7: 1-p, 8: (p+1)/3 , 9: (2*p+3)/8,   \
                                 10: .4 + .2 * p, 11: .3175 +.365*p}[i]
        j_indice = lambda p, n, m: np.int_(np.floor(n*p + m))
        g_indice = lambda p, n, m, j: p * n + m - j
        m = m_indice(probs, typ)
        j = j_indice(probs, N, m)
        j_1 = j-1
        # adjust for the bounds
        j_1[j_1<0] = 0 ; j[j>N-1] = N-1
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
        N = len(sorted_x) # sorted_x.count() # though ndarray's have no 'count' attribute
        if N == 0:
            return np_ma.array(np.empty(len(probs), dtype=float), mask=True)
        elif N == 1:
            return np_ma.array(np.resize(sorted_x, probs.shape), mask=np_ma.nomask)
        # note that, wrt to the original implementation (see source code mentioned
        # above), we also added the definitions of (alphap,betap) for typ in [1,2,3]
        abp_indice = lambda typ: {1: (0, 1), 2: (0, 1), 3: (-.5, -1.5), 4: (0, 1),  \
                           5: (.5 , .5),  6: (0 , 0),  7:(1 , 1), 8: (1/3, 1/3),    \
                            9: (3/8 , 3/8), 10: (.4,.4), 11: (.3175, .3175)}[typ]
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
        
    elif method == 'INHERIT': 
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

        
#==============================================================================
# QUANTILE CLASS
#==============================================================================

class Quantile(object):
    
    #/************************************************************************/
    def __init__(self, **kwargs):
        self.__operator = quantile
        self.__quantile = None
        self.__params = None
        # set default values
        self.__probs = DEF_PROBS
        self.__typ = DEF_TYPE
        self.__method = DEF_METHOD 
        self.__limit = DEF_LIMIT
        self.__na_rm = DEF_NARM
        if kwargs == {}:
            return
        attrs = ('probs','typ','method','limit','na_rm')
        for attr in list(set(attrs).intersection(kwargs.keys())):
            try:
                setattr(self, '{}'.format(attr), kwargs.pop(attr))
            except: 
                warnings.warn('wrong attribute value {}'.format(attr.upper()))        
        
    #/************************************************************************/
    @property
    def probs(self):
        return self.__probs
    @probs.setter
    def probs(self, probs):
        if isinstance(probs, int) and probs in SPROBS:
            probs = SPROBS[probs]
        elif not isinstance(probs, (tuple,list,pd.DataFrame,pd.Series,np.ndarray)):
            raise TypeError('wrong type for PROBS parameter')
        self.__probs = probs

    @property
    def typ(self):
        return self.__typ
    @typ.setter
    def typ(self, typ):
        if not isinstance(typ, int):
            raise TypeError('wrong type for TYP parameter')
        self.__typ = typ

    @property
    def method(self):
        return self.__method
    @method.setter
    def method(self, method):
        if not isinstance(method, str):
            raise TypeError('wrong type for METHOD parameter')
        self.__method = method

    @property
    def limit(self):
        return self.__limit
    @limit.setter
    def limit(self, limit):
        if not isinstance(limit, (tuple,list,np.ndarray)):
            raise TypeError('wrong type for LIMIT parameter')
        self.__limit = limit

    @property
    def na_rm(self):
        return self.__na_rm
    @na_rm.setter
    def na_rm(self, na_rm):
        if not isinstance(na_rm, bool):
            raise TypeError('wrong type for NA_RM parameter')
        self.__na_rm = na_rm

    @property
    def quantile(self):
        return self.__quantile

    @property
    def params(self):
        return self.__params

    #/************************************************************************/
    def __repr__(self):
        # generic representation special method
        return "<{} instance at {}>".format(self.__class__.__name__, id(self))
    def __str__(self): 
        # generic string printing method
        strprint = ''
        disp_field = lambda field: '\n'+field+'\n'+ '-'*len(field)
        disp_attr = lambda attr: "\t{}\n".format(self.params[attr])
        strprint += disp_field('probs: Numeric vector of probabilities')
        strprint += disp_attr('probs')
        strprint += disp_field('limit: Tuple of (lower,upper) probability values')
        strprint += disp_attr('limit')
        strprint += disp_field('typ: Index of algorithm selected from Hyndman and Fan')
        strprint += disp_attr('typ')
        strprint += disp_field('method: Method of implementation of the quantile algorithm')
        strprint += disp_attr('method')
        strprint += disp_field('na_rm: Logical flag used to remov any NA and NaN')
        strprint += disp_attr('na_rm')
        return strprint

    #/************************************************************************/
    def __call__(self, data, **kwargs):  
        if data is None:
            raise IOError("input data not set")
        elif not isinstance(data, (np.ndarray,pd.DataFrame,pd.Series)):
            raise TypeError("wrong type for input dataset")
        kwargs.update({'probs': kwargs.get('probs') or self.probs,
                       'typ': kwargs.get('typ') or self.typ,
                       'method': kwargs.get('method') or self.method,
                       'limit': kwargs.get('limit') or self.limit,
                       'na_rm': kwargs.get('na_rm') or self.na_rm,
                       'is_sorted': kwargs.get('is_sorted',False)})
        print(kwargs)
        self.__params = kwargs
        self.__quantile = self.__operator(data, **kwargs)
        return self.__quantile
  
        
#==============================================================================
# QUARTILE METHOD
#==============================================================================

def quartile(x, typ = DEF_TYPE, method = DEF_METHOD, na_rm = DEF_NARM, 
             is_sorted = False):
    return quantile(x, probs = [0., .25, .5, .75, 1.], typ = typ, method = method,    \
             limit = DEF_LIMIT, na_rm = na_rm, is_sorted = is_sorted)

#==============================================================================
# QUARTILE CLASS
#==============================================================================

class Quartile(Quantile):
    
    def __init__(self, **kwargs):
        kwargs.pop('probs', None) # just in case...
        super(Quartile, self).__init__(**kwargs)
        self.__operator = quartile

        
#==============================================================================
# QUINTILE METHOD
#==============================================================================
    
def quintile(x, typ = DEF_TYPE, method = DEF_METHOD, na_rm = DEF_NARM, 
             is_sorted = False):
    return quantile(x, probs = [0., .2, .4, .6, .8, 1.], typ = typ, method = method,    \
             limit = DEF_LIMIT, na_rm = na_rm, is_sorted = is_sorted)
     
#==============================================================================
# QUINTILE CLASS
#==============================================================================

class Quintile(Quantile):
    
    def __init__(self, **kwargs):
        kwargs.pop('probs', None) # just in case...
        super(Quartile, self).__init__(**kwargs)
        self.__operator = quintile
     
     
#==============================================================================
# IQR METHOD
#==============================================================================

def IQR(data, **kwargs):
    if len(data) == 5:
        return data[3] - data[1]
    else:
        return np.diff(quantile(data, probs = [0.25, 0.75], **kwargs))

