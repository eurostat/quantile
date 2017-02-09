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

Two ways to estimate the quantiles. Using the `quantile` method, _i.e._:
    
    >>> from quantile import quantile
    >>> probs, typ, method, limit = ...
    >>> data = ...
    >>> quant = quantile(data, probs, typ=type, method=method, limit=limit)
    
Or using the `Quantile` class, _i.e._ when considering the same input parameters:
    
    >>> from quantile import Quantile
    >>> Q = Quantile({'probs': probs, 'typ': typ, 'method': method, 'limit': limit})
    >>> quant = Q(data)

"""

import os
import warnings

QUANTILE_PROGRAM =  "quantile"
FORMATS =           {'csv':'csv', 'xls':'excel', 'sql':'sql', 'json':'json',    \
                     'html':'html', 'htm':'html', 'sas':'sas', 'raw':'pickle'}

import numpy as np
try:
    import pandas as pd
except:
    class pd(): # dummy class
        DataFrame = type('dummy',(object,))
        Series = type('dummy',(object,))

import quantile_source 


#==============================================================================
# QUANTILE METHOD
#==============================================================================
def quantile(*args, **kwargs):
    return quantile_source.quantile(*args, **kwargs)


#==============================================================================
# QUANTILE CLASS
#==============================================================================
class Quantile(object):
    
    #/************************************************************************/
    def __init__(self, **kwargs):
        self.__quantile = None
        self.__params = None
        # set default values
        self.__probs = quantile_source.DEF_PROBS
        self.__typ = quantile_source.DEF_TYPE
        self.__method = quantile_source.DEF_METHOD 
        self.__limit = quantile_source.DEF_LIMIT
        self.__na_rm = quantile_source.DEF_NARM
        if kwargs == {}:
            return
        attrs = ( 'probs','typ','method','limit','na_rm')
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
        if not isinstance(probs, (tuple,list,pd.DataFrame,pd.Series,np.ndarray)):
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
        if isinstance(data, str):
            data = self.__read(data)
        if data is None:
            raise IOError("input data not set")
        elif not isinstance(data, (np.ndarray,pd.DataFrame,pd.Series)):
            raise TypeError("wrong type for input dataset")
        kwargs.update({'probs': kwargs.get('probs') or self.probs,
                       'typ': kwargs.get('typ') or self.typ,
                       'method': kwargs.get('method') or self.method,
                       'limit': kwargs.get('limit') or self.limit,
                       'na_rm': kwargs.get('na_rm') or self.na_rm,
                       'is_sorted': kwargs.get('is_sorted')})
        self.__params = kwargs
        self.__quantile = quantile_source.quantile(data, self.probs, **kwargs)
        return self.__quantile

    #/************************************************************************/
    @staticmethod
    def __read(filename):  
        if not os.path.exists(filename):
            raise IOError("input filename not found")
        data = None
        # see http://pandas.pydata.org/pandas-docs/stable/io.html
        ext = filename.split('.')[-1]
        if ext in FORMATS.keys():   
            fmts = FORMATS[ext]
        else:                       
            fmts = FORMATS.values()
        for fmt in fmts:
            try:
                data = getattr(pd, 'read_{fmt}'.format(fmt=fmt))(filename)
            except:
                pass
        return data
 
    #/************************************************************************/
    def save(self, filename, fmt=None): 
        if self.quantile is None:
            warnings.warn("quantile not calculated yet")
            return
        if os.path.exists(filename):
            warnings.warn("output filename already exists")
        #if not isinstance(self.quantile, (pd.DataFrame,pd.Series)):
        #    try:
        #        self.quantile = pd.DataFrame.from_records(self.quantile)
        #    except:
        #        raise TypeError("wrong type for input dataset")  
        if fmt is not None:
            ext = filename.split('.')[-1]
            if ext in FORMATS.keys():   
                fmt = FORMATS[ext]
            else:                       
                raise IOError("format of output file not recognised")
        try:
            getattr(self.quantile, 'to_{fmt}'.format(fmt=fmt))(filename)
        except:
            raise IOError("output data not saved")
       
    #@staticmethod
    #def load_csv(filename):
    ##    return np.loadtxt(filename, delimiter=',')            
    #    return pd.read_csv(filename)            
    #@staticmethod
    #def save_csv(filename, x, **kwargs):
    ##    np.savetxt(filename, x, **kwargs)
    #    pd.to_csv(filename, x)
    
    #/************************************************************************/
    def __getattribute__(self, obj): # hiding traces of decoration.
        # known names
        if obj.startswith('read_','to_'): 
            try:
                return getattr(np, obj)
            except:
                pass # stopping recursion.
        try:
            return self.__get__(obj) # getattr(self, obj) 
        except:
            raise AttributeError

 
#==============================================================================
# QUARTILE CLASS
#==============================================================================
class Quartile(Quantile):
    
    #/************************************************************************/
    def __init__(self, **kwargs):
        kwargs.pop('probs', None) # just in case...
        super(Quartile, self).__init__(**kwargs)
       
    #/************************************************************************/
    @staticmethod
    def __custom_boxplot(quantile, ax, *args, **kwargs):
        """Generate a customized boxplot based on store quartile values
        
            >>> fig, ax = plt.subplots()
            >>> Quartile.__custom_boxplot(quartile, ax, notch=0, sym='+', vert=1, whis=1.5)
            >>> ax.figure.canvas.draw() # canvas is updated
        """            

        n_box = 1 # len(quantile)
        dummy = [1, 2, 3, 4, 5] # [-9, -4, 2, 4, 9]
        box_plot = ax.boxplot([dummy,]*n_box, *args, **kwargs) 
        # Creates len(percentiles) no of box plots
    
        min_y, max_y = float('inf'), -float('inf')
    
        for box_no, pdata in enumerate(quantile):
            if len(pdata) == 6:
                (q1_start, q2_start, q3_start, q4_start, q4_end, outliers) = pdata
            elif len(pdata) == 5:
                (q1_start, q2_start, q3_start, q4_start, q4_end) = pdata
                outliers = None
            else:
                raise ValueError("Quantile arrays must have either 5 or 6 values")
    
            # Lower cap
            box_plot['caps'][2*box_no].set_ydata([q1_start, q1_start])
            # xdata is determined by the width of the box plot
    
            # Lower whiskers
            box_plot['whiskers'][2*box_no].set_ydata([q1_start, q2_start])
    
            # Higher cap
            box_plot['caps'][2*box_no + 1].set_ydata([q4_end, q4_end])
    
            # Higher whiskers
            box_plot['whiskers'][2*box_no + 1].set_ydata([q4_start, q4_end])
    
            # Box
            path = box_plot['boxes'][box_no].get_path()
            path.vertices[0][1] = q2_start
            path.vertices[1][1] = q2_start
            path.vertices[2][1] = q4_start
            path.vertices[3][1] = q4_start
            path.vertices[4][1] = q2_start
    
            # Median
            box_plot['medians'][box_no].set_ydata([q3_start, q3_start])
    
            # Outliers
            if outliers is not None and len(outliers[0]) != 0:
                # If outliers exist
                box_plot['fliers'][box_no].set(xdata = outliers[0],
                                               ydata = outliers[1])
    
                min_y = min(q1_start, min_y, outliers[1].min())
                max_y = max(q4_end, max_y, outliers[1].max())
    
            else:
                min_y = min(q1_start, min_y)
                max_y = max(q4_end, max_y)
    
            # The y axis is rescaled to fit the new box plot completely with 10% 
            # of the maximum value at both ends
            ax.set_ylim([min_y*1.1, max_y*1.1])

        return box_plot

    
#==============================================================================
# MAIN
#==============================================================================
if __name__ == "__main__":
    """Main function launched when module is used as a script.
    """
    
    import sys, re
    import argparse

    prog = QUANTILE_PROGRAM
    try:
        # return the index of the first element in the list of arguments that   
        # does not match the program's name
        _init_argv_ = next(i for i, v in enumerate([re.search(prog, k)  \
                                                    for k in sys.argv]) if not v)
    except:
        _init_argv_ =  1 # 2 # len(sys.argv) #None
        
    # this is the only to retrieve the correct list of arguments when calling this function
    # in both batch and bash scripts
    argv = sys.argv[_init_argv_:]
    
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
        "    def.: {}.".format(quantile_source.DEF_PROBS),                      \
        default=quantile_source.DEF_PROBS)
    parser.add_argument('-typ', type=int, nargs=1,                              \
        help="\nan integer used to select the quantile algorithm.\n"            \
        "    def.: {}.".format(quantile_source.DEF_TYPE),                       \
        default=quantile_source.DEF_TYPE)
    parser.add_argument('-method', type=str, nargs=1,                           \
        help="\nmethod of implementation of the quantile algorithm; this can\n" \
        "    be either: 'MQUANT' for an estimation based on the use of the\n"   \
        "    mquantiles method available in scipy (package stats.mstats), or\n" \
        "    'DIRECT' for a canonical implementation based on the direct\n"     \
        "    transcription of the algorithm;"                                   \
        "    def.: {}.".format(quantile_source.DEF_METHOD),                     \
        default=quantile_source.DEF_METHOD)
    parser.add_argument('-na_rm', type=int, nargs=1,                            \
        help="\nlogical flag; if true, any NA and NaN's are removed from the\n" \
        "    input dataset before the quantiles are computed;"                  \
        "    def.: {}.".format(quantile_source.DEF_NARM),                       \
        default=quantile_source.DEF_NARM)
    parser.add_argument('-limit', metavar='(min,max)', type=tuple, nargs=1,     \
        help="\ntuple of (lower,upper) values; values of a outside this open\n" \
        "   interval are ignored; def: ignored."                                \
        )
    parser.add_argument('--verbose', '-v', dest='verbose', action='count')
    
    argv = parser.parse_args(argv)

    if argv is None:
        print("!!! no arguments passed !!!")
        sys.exit(False)
    elif argv.input is None:
        print("!!! no input file provided !!!")
        sys.exit(False)
        
    if argv.verbose:    print("\tsetting the quantile parameters...")   
    Q = Quantile({'probs': argv.probs, 'typ': argv.typ, 'method': argv.method, 
                  'na_rm': argv.na_rm, 'limit': argv.limit})
    
    # prepare the output
    if argv.verbose:    print("\tloading and processing the input file...")   
    Q(argv.input)

    # process
    if argv.verbose:    print("\tsaving estimated quantiles in output file...")
    
    if argv.verbose:    print("OK...")
        
    
