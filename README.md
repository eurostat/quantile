quantile
======

Agnostic (re)implementations (R/SAS/Python/C) of common quantile estimation algorithms.
---

**About**

This source code material is intended to support the claim made in [Grazzini and Lamarche's article](#References) on the need for robust, software/language-agnostic statistical processes in the development and deployment of statistical production chains. 

*documentation*:	https://gjacopo.github.io/quantile/

*version*:      	0.9

*since*:        	Thu Jan  5 10:22:03 2017

*license*:      	[EUPL](https://joinup.ec.europa.eu/sites/default/files/eupl1.1.-licence-en_0.pdf)


**Description**

As a simple illustration, we implement the same identical algorithms for quantile estimation (9 derived from Hyndman and Fan's framework, plus 1 described in Cunnane's article) on different software platforms and/or using programming languages. For that purpose, we either extend (wrap) already existing implementations, or actually reimplement the algorithm from scratch.

**<a name="References"></a>References**

* Grazzini J. and Lamarche P. (2017): [**Production of social statistics... goes social!**](https://www.conference-service.com/NTTS2017/documents/agenda/data/abstracts/abstract_124.html), in _Proc.  New Techniques and Technologies for Statistics_.
* Hyndman, R.J. and Fan, Y. (1996): [**Sample quantiles in statistical packages**](https://www.amherst.edu/media/view/129116/original/Sample+Quantiles.pdf), _The American Statistician_, 50(4):361-365, doi: [10.2307/2684934](http://www.jstor.org/stable/2684934)
* Cunnane, C. (1978): [**Unbiased plotting positions—a review**](http://www.sciencedirect.com/science/article/pii/0022169478900173), _Journal of Hydrology_, 37(3-4):205-222, doi: [10.1016/0022-1694(78)90017-3](https://dx.doi.org/10.1016/0022-1694(78)90017-3).
