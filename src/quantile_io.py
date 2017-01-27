#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
.. quantile_io

**About**

This code runs quantile estimation over a sample file. It aims at supporting the 
following publication:

    Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

**Usage**

    >>> q = quantile_io(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
"""

import quantile

class quantile_io(object):
    
    def __init__(self):
        self.data = None
        self.sample = None 
        return
        
    @staticmethod
    def read():
        return
    
    def load(self, filename):
        self.data = self.read(filename)
        
    @staticmethod
    def write():
        return
        
    def compute(self, filename, probs, **kwargs):
        return quantile(self.data, probs, **kwargs)
        