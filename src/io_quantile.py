#!/usr/bin/env python -io_quantile
# -*- coding: utf-8 -*-
"""
.. io_quantile

**Description**

Compute empirical quantiles of a file with sample data corresponding to given probabilities. 
   
**Usage**

Two ways to estimate the quantiles. First, using the `quantile` method of the
`quantile` module, _i.e._:
    
    >>> from quantile import quantile
    >>> probs, typ, method, limit = ...
    >>> data = ...
    >>> quant = quantile(data, probs, typ=type, method=method, limit=limit)
    
Second, using the `Quantile` class of the current module, `io_quantile`, _i.e._ 
when considering the same input parameters:
    
    >>> from io_quantile import Quantile
    >>> Q = Quantile({'probs': probs, 'typ': typ, 'method': method, 'limit': limit})
    >>> quant = Q(data)

**About**

This code is intended as a sproof of concept for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
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

import quantile 


#==============================================================================
# IO_QUANTILE CLASS
#==============================================================================
class IO_Quantile(quantile.Quantile):

    #/************************************************************************/
    def __call__(self, data, **kwargs):  
        if data is None:
            raise IOError("input data not set")
        elif not isinstance(data, str):
            raise TypeError("a filename should be passed")
        data = self.__read(data)
        return super(IO_Quantile, self).__call__(data, **kwargs)

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
# IO_QUARTILE CLASS
#==============================================================================
class IO_Quartile(IO_Quantile):
    
    #/************************************************************************/
    def __init__(self, **kwargs):
        kwargs.pop('probs', None) # just in case...
        super(IO_Quartile, self).__init__(**kwargs)
        self.__operator = quantile.quartile
       
    #/************************************************************************/
    @staticmethod
    def outlier_limits(data, whis=1.5, **kwargs):
        if len(data) == 5:
            quart = data
        else:
            quart = quantile.quartile(data, **kwargs)
        iqr = quantile.IQR(data)
        low = quart[1] - whis * iqr
        hi = quart[3] + whis * iqr
        return [low, hi]
       
    #/************************************************************************/
    @staticmethod
    def whisker_limits(data, whis=1.5, **kwargs):
        quart = quantile.quartile(data, **kwargs)
        iqr = quantile.IQR(quart)
    
        # get low extreme
        low = quart[1] - whis * iqr
        wisk_low = np.compress(data >= low, data)
        if len(wisk_low) == 0 or np.min(wisk_low) > quart[1]:
            wisk_low = quart[1]
        else:
            wisk_low = min(wisk_low)
    
        # get high extreme
        hi = quart[3] + whis * iqr
        wisk_hi = np.compress(data <= hi, data)
        if len(wisk_hi) == 0 or np.max(wisk_hi) < quart[3]:
            wisk_hi = quart[3]
        else:
            wisk_hi = max(wisk_hi)
    
        return [wisk_low, wisk_hi]

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
        "    def.: {}.".format(quantile.DEF_PROBS),                      \
        default=quantile.DEF_PROBS)
    parser.add_argument('-typ', type=int, nargs=1,                              \
        help="\nan integer used to select the quantile algorithm.\n"            \
        "    def.: {}.".format(quantile.DEF_TYPE),                       \
        default=quantile.DEF_TYPE)
    parser.add_argument('-method', type=str, nargs=1,                           \
        help="\nmethod of implementation of the quantile algorithm; this can\n" \
        "    be either: 'MQUANT' for an estimation based on the use of the\n"   \
        "    mquantiles method available in scipy (package stats.mstats), or\n" \
        "    'DIRECT' for a canonical implementation based on the direct\n"     \
        "    transcription of the algorithm;"                                   \
        "    def.: {}.".format(quantile.DEF_METHOD),                     \
        default=quantile.DEF_METHOD)
    parser.add_argument('-na_rm', type=int, nargs=1,                            \
        help="\nlogical flag; if true, any NA and NaN's are removed from the\n" \
        "    input dataset before the quantiles are computed;"                  \
        "    def.: {}.".format(quantile.DEF_NARM),                       \
        default=quantile.DEF_NARM)
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
    Q = IO_Quantile({'probs': argv.probs, 'typ': argv.typ, 'method': argv.method, 
                  'na_rm': argv.na_rm, 'limit': argv.limit})
    
    # prepare the output
    if argv.verbose:    print("\tloading and processing the input file...")   
    Q(argv.input)

    # process
    if argv.verbose:    print("\tsaving estimated quantiles in output file...")
    
    if argv.verbose:    print("OK...")
        
    
