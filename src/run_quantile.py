#!/usr/bin/env python -run_quantile
# -*- coding: utf-8 -*-
"""
.. run_quantile

**About**

This code runs quantile estimation over a sample file. It aims at supporting the 
following publication:

    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

**Usage**

    >>> from run_quantile import Quantile
    >>> probs, type, method, limit = ...
    >>> Q = Quantile({'probs': probs, 'type': type, 'method': method, 'limit': limit})
    >>> data = ...
    >>> quant = Q(data)
"""

import os, sys, re
import warnings
import argparse

import numpy as np
try:
    import pandas as pd
except:
    class pd(): # dummy class
        DataFrame = type('dummy',(object,))
        Series = type('dummy',(object,))

import quantile

class Quantile(object):
    
    def __init__(self, **kwargs):
        self.probs = quantile.DEF_PROBS
        self.type = quantile.DEF_TYPE
        self.method = quantile.DEF_METHOD 
        self.limit = quantile.DEF_LIMIT
        if kwargs == {}:
            return
        attrs = ( 'probs','type','method','limit')
        for attr in list(set(attrs).intersection(kwargs.keys())):
            try:
                setattr(self, '{}'.format(attr), kwargs.pop(attr))
            except: 
                warnings.warn('wrong attribute value {}'.format(attr.upper()))        
        
    def __call__(self, data, **kwargs):  
        if isinstance(data, str):
            if not os.path.exists(data):
                raise IOError("input dataset not found")
            # see http://pandas.pydata.org/pandas-docs/stable/io.html
            for fmt in ['csv','excel','sql','json','html','sas','pickle']:
                try:
                    data = getattr(np, 'read_{fmt}'.format(fmt=fmt))(data)
                except:
                    pass
        if not isinstance(data, (np.array, pd.DataFrame,pd.Series)):
            raise TypeError("wrong type for input dataset")
        kwargs.update({'probs': kwargs.get('probs') or self.probs,
                       'type': kwargs.get('type') or self.type,
                       'method': kwargs.get('method') or self.method,
                       'limit': kwargs.get('limit') or self.limit})
        return quantile(data, self.probs, **kwargs)
        
    #@staticmethod
    #def load_csv(filename):
    ##    return np.loadtxt(filename, delimiter=',')            
    #    return pd.read_csv(filename)            
    #@staticmethod
    #def save_csv(filename, x, **kwargs):
    ##    np.savetxt(filename, x, **kwargs)
    #    pd.to_csv(filename, x)
    
    def __getattribute__(self, obj): # hiding traces of decoration.
        # known names
        if obj.startswith('read_','to_'): 
            try:
                return getattr(np, obj)
            except:
                pass#print getattr(self.func_orig, attr_name) # stopping recursion.
        try:
            return self.__get__(obj) # getattr(self, obj) 
        except:
            raise AttributeError

        
#/*************************************************************************/
# MAIN                            
# Main chosen as default
#/*************************************************************************/
def main(argv=None):
    """Main function launched when module is used as a script.
    """
    
    if argv is None:    raise IOError("no arguments passed")

    # parser
    parser = argparse.ArgumentParser(                                           \
        description="Run quantile estimation over a sample file\n"              \
        )
    parser.add_argument('input', type=str, nargs='?',                           \
        help="\nfilename defining the path of the input file where the\n"       \
        "   numeric vector whose sample quantiles are wanted.",                 \
        default=None)
    parser.add_argument('output', type=str, nargs='?',                          \
        help="\nfilename defining the path of the output file where the\n"      \
        "   quantile data are stored.",                                         \
        default=None)
    parser.add_argument('probs', type=list,                                     \
        help="\nnumeric vector of probabilities with values in [0,1];"          \
        "    def.: {}.".format(quantile.DEF_PROBS),                             \
        default=quantile.DEF_PROBS)
    parser.add_argument('-type', type=int, nargs=1,                             \
        help="\nan integer between 1 and 10 selecting one of the ten quantile\n"\
        "    algorithms detailed in Hyndman and Fan's article.\n"               \
        "    input dataset before the quantiles are computed;"                  \
        "    def.: {}.".format(quantile.DEF_TYPE),                              \
        default=quantile.DEF_TYPE)
    parser.add_argument('-method', type=str, nargs=1,                           \
        help="\nmethod of implementation of the quantile algorithm; this can\n" \
        "    be either: 'MQUANT' for an estimation based on the use of the\n"   \
        "    mquantiles method available in scipy (package stats.mstats), or\n" \
        "    'DIRECT' for a canonical implementation based on the direct\n"     \
        "    transcription of the algorithm;"                                   \
        "    def.: {}.".format(quantile.DEF_METHOD),                            \
        default=quantile.DEF_METHOD)
    parser.add_argument('-na_rm', type=int, nargs=1,                            \
        help="\nlogical flag; if true, any NA and NaN's are removed from the\n" \
        "    input dataset before the quantiles are computed;"                  \
        "    def.: {}.".format(quantile.DEF_NARM),                              \
        default=quantile.DEF_NARM)
    parser.add_argument('-limit', metavar='(min,max)', type=tuple, nargs=1,     \
        help="\ntuple of (lower,upper) values; values of a outside this open\n" \
        "   interval are ignored; def: ignored."                                \
        )
    parser.add_argument('-intensity', \
        help="\noptional boolean flag defining if the histogram matching of the input\n" \
        "   image is performed 'band per band', ie. matching is performed independently over\n" \
        "   all bands (case intensity=False), or only the intensity band in a transformed color\n" \
        "   space (L of Lab, case intensity=True); def.: intensity=False.", \
        action='store_true')
    parser.add_argument('--verbose', '-v', dest='verbose', action='count')
    
    argv = parser.parse_args(argv)

    if argv is None:
        print("!!! no arguments passed !!!")
        sys.exit(False)
    elif argv.input is None:
        print("!!! no input file provided !!!")
        sys.exit(False)
        
    if argv.verbose:    print("\tsetting the quantile parameters...")   
    Q = Quantile({'probs': argv.probs, 'type': argv.type, 'method': argv.method, 
                  'limit': argv.limit})
    
    # prepare the output
    if argv.verbose:    print("\tloading and processing the input file...")   
    Q(argv.input)

    # process
    if argv.verbose:    print("\tsaving estimated quantiles in output file...")
    
    if argv.verbose:    print("OK...")
    return True
        
    
if __name__ == "__main__":
    def firstnonmatch(pattern,strings):
        """Return the index of the first element in a list of strings that does not 
        match a given pattern, or the lenght of that list if all strings match.
        """
        try:
            return next(i for i, v in enumerate([re.search(pattern, i) for i in strings]) if not v)
        except:
            return len(strings) #None
    # _init_argv_ = 1 # 2
    _init_argv_ = firstnonmatch("run_quantile",sys.argv)
    # this is the only to retrieve the correct list of arguments when calling this function
    # in both batch and bash scripts
    main(sys.argv[_init_argv_:])
