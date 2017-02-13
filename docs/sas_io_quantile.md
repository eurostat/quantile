## SAS io_quantile {#sas_io_quantile}
Compute empirical quantiles of a file with sample data corresponding to given probabilities. 
	
	%io_quantile(ifn, ofn, idir=, odir=, probs=, _quantiles_=, 
				 type=7, method=DIRECT, ifmt=csv, ofmt=csv);
				 
### Arguments
* `ifn` : input filename; 2-columns or 1-column data file (_e.g._, in csv format) where input data samples
	are stored; the last column of the file will be used for quantile estimation (since the first, when
	it exists, will be regarded as a list of indexes);
* `probs`, `type`, `method` : list of probabilities, type and method flags used for the definition
	of the quantile algorithm and its actual estimation; see macro [%quantile](@ref sas_quantile);
* `ifmt` : (_option_) type of the input file; default: `ifmt=csv`.

### Returns
* `ofn` : name of the output file  and variable where quantile estimates are saved; quantiles are 
	stored in a variable named `QUANT`;
* `ofmt` : (_option_) type of the output file; default: `ofmt=csv`;
* `_quantiles_` : (_option_) name of the output numeric list where quantiles can be stored in 
	increasing `probs` order.

### Description
Return an output file `ofn` with estimates of underlying distribution quantiles from the supplied 
sample data in input file `ifn` at probabilities in `probs`, following quantile estimation algorithm 
defined by `type` and implemented using the method specified by `method` (see macro 
[%quantile](@ref sas_quantile)). 

### See also
[%quantile](@ref sas_quantile),
[UNIVARIATE](https://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#univariate_toc.htm),
[quantile (R)](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html),
[mquantiles (scipy)](https://docs.scipy.org/doc/scipy-0.18.1/reference/generated/scipy.stats.mstats.mquantiles.html),
[gsl_stats_quantile* (C)](https://www.gnu.org/software/gsl/manual/html_node/Median-and-Percentiles.html).