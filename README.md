[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.322313.svg)](https://doi.org/10.5281/zenodo.322313)
quantile
======

Software-agnostic (re)implementations (R/SAS/Python/C) of common quantile estimation algorithms
---

**About**

This material is meant as a proof of concept for [Grazzini and Lamarche's article](#References) and aims at promoting software/language-agnostic development and deployment of statistical processes. 

<table align="center">
    <tr> <td align="left"><i>documentation</i></td> <td align="left">available at: https://gjacopo.github.io/quantile/</td> </tr> 
    <tr> <td align="left"><i>version</i></td> <td align="left">0.9</td> </tr> 
    <tr> <td align="left"><i>since</i></td> <td align="left">Thu Jan  5 10:22:03 2017</td> </tr> 
    <tr> <td align="left"><i>license</i></td> <td align="left"><a href="https://joinup.ec.europa.eu/sites/default/files/eupl1.1.-licence-en_0.pdfEUPL">EUPL</a>  <i>(cite the source code or the reference above!)</i> </td> </tr> 
</table>

**Rationale**

We consider here the implementation of [quantile estimates](http://www.math.ntu.edu.tw/~hchen/teaching/LargeSample/notes/noteorder.pdf) based on order statistics. 
Although _quantiles_ are often implemented throughout various packages of statistical software ([`R`](https://www.r-project.org), [`Python`](https://www.python.org), [`SAS`](http://www.sas.com/), Stata, Maple, _etc_...), the different implementations may not be consistent with each other and, therefore, provide different output estimates. 
Typically, this happens because different estimation methods are available in the [literature](http://mathworld.wolfram.com/Quantile.html), and each one of them corresponds to a specific implementation. 

Let us consider, for instance, the (broad) range of techniques for quantile estimation implemented ad-hoc in both `SAS` and `R` software. They are respectively made available through the `SAS` [procedure `UNIVARIATE`](http://support.sas.com/documentation/cdl/en/procstat/66703/HTML/default/viewer.htm#procstat_univariate_syntax01.htm) and the `R` [function `quantile`](http://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html), whose documentations are displayed below: 


Looking at which of Hyndman and Fan's (<code>HF&num;n</code>), Cunnane's (<code>C</code>), and/or Filliben's (<code>F</code>) algorithms (see references [below](#References)) are actually available (or not: <i>n.a.</i>) on either software, it appears that there is no one-to-one correspondance between the implementations:
<table>
<tr>
<td>algorithm</td>
<td align="centre"><code>HF&num;1</code></td> <td align="centre"><code>HF&num;2</code></td> 
<td align="centre"><code>HF&num;3</code></td> <td align="centre"><code>HF&num;4</code></td> 
<td align="centre"><code>HF&num;5</code></td> <td align="centre"><code>HF&num;6</code></td>
<td align="centre"><code>HF&num;7</code></td> <td align="centre"><code>HF&num;8</code></td> 
<td align="centre"><code>HF&num;9</code></td> <td align="centre"><code>C</code></td> 
<td align="centre"><code>F</code></td> 
</tr>
<tr>
<td><code>quantile type</code></td>
<td align="centre"> 1 </td> <td align="centre"> 2 </td> 
<td align="centre"> 3 </td> <td align="centre"> 4 </td> 
<td align="centre"> 5 </td>  <td align="centre"> 6 </td> 
<td align="centre"> 7 </td> <td align="centre"> 8 </td> 
<td align="centre"> 9 </td> <td align="centre"> <i>n.a.</i> </td> 
<td align="centre"> <i>n.a.</i> </td>
</tr>
<tr>
<td><code>UNIVARIATE PCTLDEF</code></td>
<td align="centre"> 3</td> <td align="centre"> 5</td> 
<td align="centre"> 2 </td> <td align="centre"> 1 </td> 
<td align="centre"> <i>n.a.</i> </td> <td align="centre"> 4 </td> 
<td align="centre"> <i>n.a.</i> </td> <td align="centre"> <i>n.a.</i> </td> 
<td align="centre"> <i>n.a.</i> </td> <td align="centre"> <i>n.a.</i> </td> 
<td align="centre"> <i>n.a.</i> </td>
</tr>
</table>
In particular, the algorithms implemented by default (_i.e._, when no parameter `type`, or `PCTLDEF`, is passed) differ, since indeed <code>HF&num;7</code> (`type=7`) is the default algorithm in `R quantile` implementation, while <code>HF&num;2</code> (`PCTLDEF=5`) is the default one in `SAS UNIVARIATE` implementation. Similarly, note that `Python` [method `mquantiles`](http://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.mstats.mquantiles.html) implements  Cunnane's algorithm as its default option (through <code>(&alpha;,&beta;)=(.4,.4)</code> parameter). 

Altogether, a user may be left at a disadvantage since he may neither understand all the implications of the estimation process &ndash; depending on which platform he performs his calculations, depending on whether he chooses default parameters or not, ... &ndash; nor how to test the validity of results produced by the software. A stronger control of the practical and effective implementation of statistical methods and techniques is required. 

**Objectives**

We propose to go back to the original algorithms and provide with a canonical implementation of quantile estimates on different software platforms and/or using different programming languages, so as to show that a consistent implementation is possible accross platforms. In practice, we implement 10 algorithms, 9 derived from Hyndman and Fan's framework, plus 1 described in Cunnane's article and 1 proposed by Filiben, in `R`, `Python`, `C` and `SAS`. To do so, we either extend/complement (wrap) already existing implementations for quantile estimation (`R` function `quantile`, `Python` method `mquantiles`, `C` [function `gsl_stats`](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html), or `SAS` procedure `UNIVARIATE`), or actually reimplement the algorithm from scratch (`SAS`, `C` and `Python`). In the former case, we provide with consistent parameterisation/configuration accross the different software so as to ensure consistency and transparency for the user.

However, unnecessary duplication (the same algorithm is being, above, implemented on 4 different platforms) shall be avoided, and, instead the choice of statistical software/packages should be transparent to the user, _i.e._ the quantile estimation should be provided in a _"software-agnostic"_ manner. To this end, we show that it is possible to easily implement microservices (SOA) that run the quantile estimation (either operated using `R` or `Python`) through a web interface ([`shiny`](https://shiny.rstudio.com/) for `R`, [`flask`](http://flask.pocoo.org/) for `Python`).

**<a name="References"></a>References**

* Grazzini J. and Lamarche P. (2017): [**Production of social statistics... goes social!**](https://www.conference-service.com/NTTS2017/documents/agenda/data/abstracts/abstract_124.html), in _Proc.  New Techniques and Technologies for Statistics_.
* Hyndman R.J. and Fan Y. (1996): [**Sample quantiles in statistical packages**](https://www.amherst.edu/media/view/129116/original/Sample+Quantiles.pdf), _The American Statistician_, 50(4):361-365, doi:[10.2307/2684934](http://www.jstor.org/stable/2684934)
* Cunnane C. (1978): [**Unbiased plotting positions: a review**](http://www.sciencedirect.com/science/article/pii/0022169478900173), _Journal of Hydrology_, 37(3-4):205-222, doi:[10.1016/0022-1694(78)90017-3](https://dx.doi.org/10.1016/0022-1694(78)90017-3).
* Filliben J.J. (1975): [**The probability plot correlation coefficient test for normality**](http://www1.cmc.edu/pages/faculty/MONeill/Math152/Handouts/filliben.pdf), _Technometrics_, 17(1):111-117, doi:[10.2307/1268008](https://dx.doi.org/10.2307/1268008).
