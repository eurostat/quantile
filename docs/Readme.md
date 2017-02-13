quantile
======

How to compute a quantile? Software-agnostic implementations of common quantile estimation algorithms.
---

**<a name="Description"></a>Description**

The source code implements the same identical algorithms for quantile estimation (9 derived from Hyndman and Fan's framework, plus 1 described in Cunnane's article and 1 one proposed by Filiben) on different software platforms and/or using different programming languages, namely:

* [`R`](https://www.r-project.org),
* [`Python`](https://www.python.org),
* [`SAS`](http://www.sas.com/),
* `C` with the [gsl](https://www.gnu.org/software/gsl/) library.

For this purpose, it either extends (wraps) already existing implementations when they exist, or actually reimplements the algorithm from scratch.

**Table of Contents**

* algorithm [page](algorithm.md): Algorithm(s) used for quantile estimation of sample data.
  + [detailed algorithms](algorithm.md#Algorithms).
  + [references](algorithm.md#References).
* syntax [page](syntax.md): play with parameters in the different languages.
  + [common implementation](quantile.md) of quantile estimation.
  + `Python` method [quantile.py](python_quantile.md).
  + `C` `gsl`-based function [quantile.](C_quantile.md).
  + `R` function [quantile.](r_quantile.md).
  + `SAS` macro [`quantile.sas`](python_quantile.md).
* usage [page](usage.md): how to run and test the programs.
* service applications [page](service.md): run a web-service for quantile estimation.

**<a name="About"></a>About**

This source code material is intended as a supporting material for _Grazzini and Lamarche_'s article referenced below:

* Grazzini J. and Lamarche P. (2017): [**Production of social statistics... goes social!**](https://www.conference-service.com/NTTS2017/documents/agenda/data/abstracts/abstract_124.html), in _Proc.  New Techniques and Technologies for Statistics_.

    
**<a name="Notice"></a>Notice**

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission.

Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11).
