## quantile {#sas_quantile}
Compute empirical quantiles of a variable with sample data corresponding to given probabilities. 
	
	%quantile(var, probs=, type=7, method=DIRECT, names=, _quantiles_=, 
				idsn=, odsn=, ilib=WORK, olib=WORK, na_rm = YES);
				
### Arguments
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
* `type` : (_option_) an integer between 1 and 9 selecting one of the nine quantile algorithms 
	discussed in Hyndman and Fan's article (see references) and detailed below to be used; 
	
| `type` |                    description                                 | `PCTLDEF` |
|:------:|:---------------------------------------------------------------|:---------:|
|    1   | inverted empirical CDF					  |     3     |
|    2   | inverted empirical CDF with averaging at discontinuities       |     5     |        
|    3   | observation numberer closest to qN (piecewise linear function) |     2     | 
|    4   | linear interpolation of the empirical CDF                      |     1     | 
|    5   | Hazen's model (piecewise linear function)                      |   _n.a._  | 
|    6   | Weibull quantile                                               |     4     | 
|    7   | interpolation points divide sample range into n-1 intervals    |   _n.a._  | 
|    8   | unbiased median (regardless of the distribution)               |   _n.a._  | 
|    9   | approximate unbiased estimate for a normal distribution        |   _n.a._  |
|   10   | Cunnane's definition (approximately unbiased)                  |   _n.a._  |
|   11   | Filliben's estimate                                            |   _n.a._  |
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
	
### Returns
Return estimates of underlying distribution quantiles based on one or two order statistics from 
the supplied elements in `var` at probabilities in `probs`, following quantile estimation algorithm
defined by `type`. The output sample quantile are stored either in a list or as a table, through:
* `_quantiles_` : (_option_) name of the output numeric list where quantiles are stored in increasing
	`probs` order; incompatible with parameters `odsn` and `names `below;
* `odsn, names` : (_option_) respective names of the output dataset and variable where quantiles are 
	stored; if both `odsn` and `names` are set, the quantiles are saved in the `names` variable ot the
	`odsn` dataset; if just `odsn` is set, then they are stored in a variable named `QUANT`; if 
	instead only `names` is set, then the dataset will also be named after `names`.

### Algorithm
All sample quantiles are defined as weighted averages of consecutive order statistics. Sample 
quantiles of type `i` are defined for `1 <= i <= 9` by:
	Q[i](p) = (1 - gamma) * x[j] + gamma *  x[j+1]
where `x[j]`, for `(j-m)/N<=p<(j-m+1)/N`, is the `j`-th order statistic, `N` is the sample 
size, the value of `gamma` is a function of:
	j = floor(N*p + m)
	g = N*p + m - j
and `m` is a constant determined by the sample quantile type. 
For types 1, 2 and 3, `Q[i](p)` is a discontinuous function:
| `type` |     `p[k]`    |   `m`   |`alphap`|`betap`|	             `gamma`               | 
|:------:|:-------------:|:-------:|:------:|:-----:|:------------------------------------:|
|    1   |     `k/N`     |    0    |    0   |   0   | 1 if `g>0`, 0 if `g=0`               |
|    2   |     `k/N`     |    0    |    .   |   .   | 1/2 if `g>0`, 0 if `g=0`             | 
|    3   |  `(k+1/2)/N`  |  -1/2   |   1/2  |   0   | 0 if `g=0` and `j` even, 1 otherwise | 
For types 4 through 9, `Q[i](p)` is a continuous function of `p`, with `gamma` and `m` given 
below. The sample quantiles can be obtained equivalently by linear interpolation between the 
points `(p[k],x[k])` where `x[k]` is the `k`-th order statistic:
| `type` |       `p[k]`       |      `m`     |`alphap`|`betap`|`gamma`| 
|:------:|:------------------:|:------------:|:------:|:-----:|:-----:|
|    4   |        `k/N`       |       0      |    0   |   0   |  `g`  | 
|    5   |     `(k-1/2)/N`    |      1/2     |   1/2  |   0   |  `g`  | 
|    6   |       `k/(N+1)`    |      `p`     |    0   |   1   |  `g`  | 
|    7   |    `(k-1)/(N-1)`   |     `1-p`    |    1   |  -1   |  `g`  | 
|    8   |  `(k-1/3)/(N+1/3)` |   `(1+p)3`   |   1/3  |  1/3  |  `g`  | 
|    9   |  `(k-3/8)/(N+1/4)` |  `(2*p+3)/8` |   3/8  |  1/4  |  `g`  | 
|   10   |   `(k-.4)/(N+.2)`  |   `.2*p+.4`  |    .4  |   .4  |  `g`  |
|   11   |`(k-.3175)/(N+.365)`|`.365*p+.3175`| .3175  | .3175 |  `g`  |
In the above tables, the `(alphap,betap)` pair is defined such that:
	p[k] = (k - alphap)/(n + 1 - alphap - betap)

### References
1. Makkonen, L. and Pajari, M. (2014): ["Defining sample quantiles by the true rank probability"](https://www.hindawi.com/journals/jps/2014/326579/cta/).
2. Hyndman, R.J. and Fan, Y. (1996): ["Sample quantiles in statistical packages"](http://www.jstor.org/stable/2684934). 
3. Barnett, V. (1975): ["Probability plotting methods and order statistics"](http://www.jstor.org/stable/2346708).
 
### See also
[%io_quantile](@ref sas_io_quantile),
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html),
[gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).

## io_quantile {#sas_io_quantile}
Compute empirical quantiles of a file with sample data corresponding to given probabilities. 
	
	%io_quantile(ifn, ofn, idir=, odir=, probs=, _quantiles_=, 
				 type=7, method=DIRECT, ifmt=csv, ofmt=csv);
				 
### Arguments
* `ifn` : input filename; 2-columns or 1-column data file (_e.g._, in csv format) where input data samples
	are stored; the last column of the file will be used for quantile estimation (since the first, when
	it exists, will be regarded as a list of indexes);
* `probs`, `type`, `method` : list of probabilities, type and method flags used for the definition
	of the quantile algorithm and its actual estimation; see macro [%quantile](@ref sas_io_quantile);
* `ifmt` : (_option_) type of the input file; default: `ifmt=csv`.

### Returns
* `ofn` : name of the output file  and variable where quantile estimates are saved; quantiles are 
	stored in a variable named `QUANT`;
* `ofmt` : (_option_) type of the output file; default: `ofmt=csv`;
* `_quantiles_` : (_option_) name of the output numeric list where quantiles can be stored in 
	increasing `probs` order.

### Description
Return estimates of underlying distribution quantiles based on one or two order statistics from 
the supplied elements in `var` at probabilities in `probs`, following quantile estimation algorithm
defined by `type` (see macro [%quantile](@ref sas_io_quantile)). 

### See also
[%quantile](@ref sas_quantile),
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html),
[gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).
