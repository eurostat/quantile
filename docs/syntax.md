## <a name="Syntax"></a>Syntax

`quantile`: Compute empirical quantiles of a variable with sample data corresponding to given probabilities. 

### Common Arguments

* `probs` : (_option_) list of probabilities with values in [0,1]; the smallest observation 
	corresponds to a probability of 0 and the largest to a probability of 1; default: 
	`probs=0 0.25 0.5 0.75 1`, so as to match default values `seq(0, 1, 0.25)` used in R 
	[quantile](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html); 
* `type` : (_option_) an integer between 1 and 11 selecting one of the nine quantile algorithms 
	discussed in Hyndman and Fan's article (see references) and detailed below to be used; 
	
	| `type` |                    description                                 |
	|:------:|:---------------------------------------------------------------|
	|    1   | inverted empirical CDF					  |
	|    2   | inverted empirical CDF with averaging at discontinuities       |       
	|    3   | observation numberer closest to qN (piecewise linear function) | 
	|    4   | linear interpolation of the empirical CDF                      | 
	|    5   | Hazen's model (piecewise linear function)                      | 
	|    6   | Weibull quantile                                               |
	|    7   | interpolation points divide sample range into n-1 intervals    |
	|    8   | unbiased median (regardless of the distribution)               |
	|    9   | approximate unbiased estimate for a normal distribution        |
	|   10   | Cunnane's definition (approximately unbiased)                  |
	|   11   | Filliben's estimate                                            |

### <a name="sas_quantile"></a> SAS macro
	
	%quantile(var, probs=, type=7, method=DIRECT, names=, _quantiles_=, 
				idsn=, odsn=, ilib=WORK, olib=WORK, na_rm = YES);
				
#### Arguments
* `var` : data whose sample quantiles are estimated; this can be either:
		+ the name of the variable in a dataset storing the data; in that case, the parameter 
			`idsn` (see below) should be set; 
		+ a list of (blank separated) numeric values;
* `probs` : (_option_) list of probabilities with values in [0,1]; the smallest observation 
	corresponds to a probability of 0 and the largest to a probability of 1; in the case 
	`method=UNIVAR` (see below), these values are multiplied by 100 in order to be used by 
	`PROC UNIVARIATE`; default: `probs=0 0.25 0.5 0.75 1`, so as to match default values 
	`seq(0, 1, 0.25)` used in R 
	[quantile](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html); 
* `type` : (_option_) an integer between 1 and 11 selecting one of the nine quantile algorithms 
	discussed in Hyndman and Fan's, Cunane's and Filliben's articles (see references); note
	the (non bijective) correspondance between the different algorithms and the currently 
	available methods in `PROC UNIVARIATE` (through the use of `PCTLDEF` parameter):

<table align="center">
    <tr> <td align="centre"><code>type</code></td>
         <td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td><td>11</td>
    </tr>
    <tr> <td align="centre"><code>PCTLDEF</code></td>
         <td>3</td><td>5</td><td>2</td><td>1</td><td> <i>n.a.</i></td><td>4</td><td> <i>n.a.</i></td><td> <i>n.a.</i></td><td> <i>n.a.</i></td><td> <i>n.a.</i></td><td> <i>n.a</i></td>
    </tr>
</table>
	default: `type=7` (likewise R `quantile`);
* `method` : (_option_) choice of the implementation of the quantile estimation method; this can 
	be either:
		+ `UNIVAR` for an estimation based on the use of the `PROC UNIVARIATE` procedure already
			implemented in SAS,
		+ `DIRECT` for a canonical implementation based on the direct transcription of the various
			quantile estimation algorithms (see below) into SAS language;
	note that the former (`method=UNIVAR`) is incompatible with `type` other than `(1,2,3,4,6)` since 
	`PROC UNIVARIATE` does actually not support these quantile definitions (see table above); in the 
	case `type=5`, `7`, `8`, or `9`, `method` is then set to `DIRECT`; default: `method=DIRECT`;
* `idsn` : (_option_) when input data is passed as a variable name, `idsn` represents the dataset
	to look for the variable `var` (see above);
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used if `idsn` is 
	set;
* `olib` : (_option_) name of the output library (see `names` below); by default: empty, _i.e._ `WORK` 
	is also used when `odsn` is set;
* `na_rm` : (_obsolete_) logical; if true (`yes`), any NA and NaN's are removed from x before the quantiles 
	are computed.
	
#### Returns
Return estimates of underlying distribution quantiles based on one or two order statistics from 
the supplied elements in `var` at probabilities in `probs`, following quantile estimation algorithm
defined by `type`. The output sample quantile are stored either in a list or as a table, through:
* `_quantiles_` : (_option_) name of the output numeric list where quantiles are stored in increasing
	`probs` order; incompatible with parameters `odsn` and `names `below;
* `odsn, names` : (_option_) respective names of the output dataset and variable where quantiles are 
	stored; if both `odsn` and `names` are set, the quantiles are saved in the `names` variable ot the
	`odsn` dataset; if just `odsn` is set, then they are stored in a variable named `QUANT`; if 
	instead only `names` is set, then the dataset will also be named after `names`.
  
###  <a name="python_quantile"></a> `Python` method

  >>> q = quantile(x, probs, na_rm = False, type = 7, method='DIRECT', limit=(0,1))
        
#### Arguments
* `x` : (`numpy.array`) input vector data; 2D arrays are also accepted.
* `na_rm` : (`bool`) default: `na_rm=False`.
* `type` : (`int`) default: `type=7`.
* `method` : (`str`) string defining the estimation method
* `limit` : (`list,tuple`)
       
#### Returns
* `q` : (`numpy.array`) 

### See also
* [UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm).
* [quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html).
* [mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html).
* [gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).  
