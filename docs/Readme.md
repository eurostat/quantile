quantile
======

How to compute a quantile? Software-agnostic implementations of common quantile estimation algorithms.
---

**<a name="About"></a>About**

This source code material is intended as a supporting material for _Grazzini and Lamarche_;s article referenced [below](#References).

It implements the same identical algorithms for quantile 
estimation (9 derived from Hyndman and Fan's framework, plus 1 described in Cunnane's article and 1 one proposed by Filiber) on different software platforms and/or using different programming languagesm namely:
* [`R`](https://www.r-project.org),
* [`python`](https://www.python.org),
* [`SAS`](http://www.sas.com/),
* `C` with the [gsl](https://www.gnu.org/software/gsl/) library.

For that purpose, it either extends (wraps) already existing implementations when they exist, or actually reimplements the algorithm from scratch.

**Table of Contents**

* [algorithm](algorithm.md)
* [syntax](syntax.md)
* [usage](usage.md)

**<a name="References"></a>References**

* Grazzini J. and Lamarche P. (2017): [**Production of social statistics... goes social!**](https://www.conference-service.com/NTTS2017/documents/agenda/data/abstracts/abstract_124.html), in _Proc.  New Techniques and Technologies for Statistics_.
* Hyndman, R.J. and Fan, Y. (1996): [**Sample quantiles in statistical packages**](https://www.amherst.edu/media/view/129116/original/Sample+Quantiles.pdf), _The American Statistician_, 50(4):361-365, doi:[10.2307/2684934](http://www.jstor.org/stable/2684934)
* Cunnane, C. (1978): [**Unbiased plotting positions: a review**](http://www.sciencedirect.com/science/article/pii/0022169478900173), _Journal of Hydrology_, 37(3-4):205-222, doi:[10.1016/0022-1694(78)90017-3](https://dx.doi.org/10.1016/0022-1694(78)90017-3).
* Filliben, J.J. (1975): [**The probability plot correlation coefficient test for normality**](http://www1.cmc.edu/pages/faculty/MONeill/Math152/Handouts/filliben.pdf), _Technometrics_, 17(1):111-117, doi:[10.2307/1268008](https://dx.doi.org/10.2307/1268008).
