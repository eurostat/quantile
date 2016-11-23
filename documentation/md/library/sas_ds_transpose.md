## ds_transpose {#sas_ds_transpose}
Tanspose many variables in a multiple-row-per-subject table to a one-row-per-subject table

	%ds_transpose(idsn, odsn, var=, by=, pivot=, copy=, missing=no, numeric=no, ilib=WORK, olib=WORK, llib=WORK);
  
### Arguments
* `idsn` : name of the input dataset; 	
* `var` : lists of variables to be transposed; 	
* `by` : name of the variable(s) that identifies(y) a subject; 	
* `pivot` : name of the variable from input dataset for which each row value should lead to series
	of variables (one series per variable listed in `var`, above) in output dataset; there should be 
	only one variable named in pivot argument;
* `copy` : (_option_) list of variables that occur repeatedly with each observation for a subject 
	and will be copied to the resulting dataset; default: not taken into account;	
* `missing` : (_option_) boolean flag (`yes/no`) set to keep (`no`) or drop (`yes`) the observations
	that correspond	to a missing value in pivot from the input dataset before transposing; default: 
	`missing=no`;
* `numeric` : (_option_) boolean flag (`yes/no`) set to replace the observed character string value 
  	for variable used as pivot (when it is indeed a string variable) by numbers as suffixes in 
	transposed variable names or not; default: `numeric=no` (_i.e._ character string values observed 
	in pivot variable will be used as suffixes in new variable names); this is relevant only when 
	pivot variable is literal;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ the value of `ilib` will 
	be used;
* `llib` : (_option_) name of the library where value labels are defined (if any variables of interest 
	in the input dataset were categorical/attached value labels); by default: empty, _i.e._ `WORK` is 
	used.

### Returns
* `odsn` : name of the output dataset.

### Examples
We provide here the examples already used in the original code (see note below).

Given the table `dsn` in `WORK`ing library ("example1"):
centre | subjectno | gender |  visit  |   sbp    |     wt
-------|-----------|--------|---------|----------|-----------
	1  |	1	   | female |	A	  |	121.667	 |	75.4
	1  |	1	   | female	| baseline|	120	 	 |	75
	1  |	1	   | female	| week 1  |	125	 	 |	75.5
	1  |	1	   | female	| week 4  |	120	 	 |	75.7
	1  |	2	   | male   |	A	  |	142.5	 |	71.5
	1  |	2	   | male	| baseline|	140	 	 |	70
	1  |	2	   | male	| week 1  |	145	 	 |	73
	2  |	1	   | female |	A	  |	153.333	 |	90.6667
	2  |	1	   | female	| baseline|	155		 |	90
	2  |	1	   | female	| week 1  |	150	 	 |	90.8
	2  |	1	   | female	 |week 4  |	155	 	 |	91.2
then running:

	%ds_transpose(dsn, out, var=sbp wt, by=centre subjectno, pivot=visit);

will set the output table `out` to:
 centre|subjectno|  sbpA |  wtA  |sbpbaseline|wtbaseline|sbpweek_1|wtweek_1|sbpweek_4|wtweek_4
-------|---------|-------|-------|-----------|----------|---------|--------|---------|--------
	1  |	1	 |121.667| 75.4  | 	120	     | 75       |	 125  |  75.5  |   120   |  75.7
 	1  |	2	 |142.5  | 71.5  | 	140	     | 70       |	 145  |  73    |    .    |   . 
	2  |	1	 |153.333|90.6667| 	155	     | 90       |	 150  |  90.8  |   155   |  91.2

and running:

	%ds_transpose(dsn, out, var=sbp wt, by=centre subjectno, pivot=visit, copy=gender);

will set the output table `out` to:
vcentre|subjectno|  sbpA |  wtA  |sbpbaseline|wtbaseline|sbpweek_1|wtweek_1|sbpweek_4|wtweek_4|gender
-------|---------|-------|-------|-----------|----------|---------|--------|---------|--------|------
	1  |	1	 |121.667| 75.4  | 	120	     | 75       |	 125  |  75.5  |   120   |  75.7  |female
 	1  |	2	 |142.5  | 71.5  | 	140	     | 70       |	 145  |  73    |    .    |   .    | male
	2  |	1	 |153.333|90.6667| 	155	     | 90       |	 150  |  90.8  |   155   |  91.2  |female

Run macro `%%_example_ds_transpose` for examples.

### Notes
1. **The macro `%%ds_transpose` is  a wrapper to L. Joseph's original `%%MultiTranspose` macro**. 
Original source code (no license, no disclaimer) is available at 
<http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html>.
2. This macro transposes multiple variables in a dataset as if multiple calls to `PROC TRANSPOSE` were 
performed. Indeed, it is useful when data need to be restructured from a multiple-row-per-subject structure 
into a one-row-per-subject structure. While when only one variable needs to be transposed, `PROC TRANSPOSE` 
can perform the task directly, the same operation may be time consuming when two or more variables need to 
be transposed, since it is then necessary to transpose each variable separately and then merge the transposed 
datasets.
3. The following conditions need to be satisfied:
	* a column used as a pivot cannot have any duplicate values for a given series of values found in
	`by` variables,
	* `copy` variables have the same values within each series of `by` values.
4. Use the following options:
	* `numeric=yes` to use numbers as suffixes in transposed variable names rather than characters,
	* `missing=yes` if you'd rather not drop observations where variable defined as pivot has a missing 
	value.

### Reference
Zdeb, M.(2006): ["An introduction to reshaping (TRANSPOSE) and combining (MATCH-MERGE) SAS datasets"](http://www.lexjansen.com/nesug/nesug06/hw/hw09.pdf).

### See also
[PROC TRANSPOSE](http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000063661.htm),
[%MultiTranspose](http://www.medicine.mcgill.ca/epidemiology/joseph/pbelisle/multitranspose.html),
[%MAKEWIDE/%MAKELONG](http://www.sascommunity.org/mwiki/images/3/37/Transpose_Macros_MAKEWIDE_and_MAKELONG.sas).
