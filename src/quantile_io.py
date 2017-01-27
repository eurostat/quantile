#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 27 00:59:26 2017

@author: gjacopo
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
        