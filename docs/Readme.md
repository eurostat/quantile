quantile
======

_How shall I compute quantiles?_ Software-agnostic implementation of standard quantile estimation algorithms.
---

**<a name="Description"></a>Description**

The source code implements the same identical algorithms for quantile estimation (9 derived from Hyndman and Fan's framework, plus 1 described in Cunnane's article and 1 one proposed by Filiben) on different software platforms and/or using different programming languages, namely:

* [`R`](https://www.r-project.org),
* [`Python`](https://www.python.org),
* [`SAS`](http://www.sas.com/),
* `C` with the [gsl](https://www.gnu.org/software/gsl/) library.

For this purpose, it either extends (wraps) already existing implementations when they exist, or actually reimplements the algorithm(s) from scratch.

**Table of Contents**

* [algorithm](algorithm.md): Algorithm(s) used for quantile estimation of sample data.
  + [detailed description](algorithm.md#Algorithms).
  + [references from the literature](algorithm.md#References).
* [syntax](syntax.md): Play with parameters in the different languages.
  + [common arguments](syntax.md#quantile) of the quantile estimation.
  + `Python` method [`quantile.py`](syntax.md#python_quantile).
  + `C` `gsl`-based functions [`quantile*.c`](syntax.md#c_quantile).
  + `R` function [`quantile.r`](syntax.md#r_quantile).
  + `SAS` macro [`quantile.sas`](syntax.md#python_quantile).
* [usage](usage.md): Run and test the programs.
* [service applications](service.md): Run a micro web-service for quantile estimation.

**<a name="About"></a>About**

This source code material is intended as a supporting material for _Grazzini and Lamarche_'s article referenced below:

* Grazzini J. and Lamarche P. (2017): [**Production of social statistics... goes social!**](https://www.conference-service.com/NTTS2017/documents/agenda/data/abstracts/abstract_124.html), in _Proc.  New Techniques and Technologies for Statistics_.

    
**<a name="Notice"></a>Notice**

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission.

Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11).
