## ds_order {#sas_ds_order}
(Re)order the variables (columns) of a given dataset.

	%ds_order(idsn, odsn=, varnum=alpha, varlst=, varlike=, ilib=WORK, olib=WORK, liblike=WORK);

### Arguments
* `idsn` : a dataset reference;
* `varnum` : (_option_) list of variables positions (numeric indexes) to consider so as to reorder 
	the columns/fields of `idsn`; note that `varnum=alpha` is also accepted, so that, in that case,
	the variables in `idsn` are reordered alphabetically; incompatible with options `varlst` and 
	`varlike` below; default: `varnum=alpha`, and the variables in the dataset `idsn` are reordered
	alphabetically when none of the parameteres `varnum`, `varlst` and `varlike` (see below) is 
	passed;
* `varlst` : (_option_) list of variables names to consider so as to reorder the columns/fields of 
	`idsn`; incompatible with options `varnum` above and `varlike` below; default: `varlst=`, _i.e._
	it is not set;
* `varlike` : (_option_) table whose variables order will be applied to the dataset reference; 
	incompatible with options `varlst` above and `varlike` above; default: `varlike=`, _i.e._
	it is not set;
* `odsn` : (_option_) name of the output dataset (in `WORK` library); when not set, the input
	dataset `dsn` is replaced with the newly sorted version; default: not set;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used,
* `olib` : (_option_) name of the output library; by default: empty, _i.e._ `ilib` will be used in 
	case `odsn` is set;
* `liblike` : (_option_) name of the library where `varlike` is stored; by default: empty, _i.e._ 
	`ilib` will be used in case `varlike` is set.
 
### Returns
In either `odsn` or `idsn` (updated when the former is not passed), the original dataset with reordered 
variables.

### Examples
Let us first  consider test dataset #5:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then the variables in the dataset can be easily reordered alphabetically, _e.g._ using 
undifferently any of the instructions below:

	%ds_order(_dstest5, odsn=dsn);
	%ds_order(_dstest5, odsn=dsn, varnum=alpha);

so as to store in the output dataset `dsn` the following table:
 a | b | c | d | e | f 
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5 

Let us also consider test dataset #6:
 a | b | c | d | e | f | g | h 
---|---|---|---|---|---|---|--- 
 . | 1 | 2 | 3 | . | 5 | 6 | .

the following instructions enable us to explicitely reorder the variables in the table (note that
the variables not mentioned in `varlst` are retrieved from the remaining positions):

	%let varlst=b a h e c;
	%ds_order(_dstest6, odsn=dsn, varlst=&varlst);

so that the output dataset `dsn` contains the table:
 b | a | h | e | c | d | f | h 
---|---|---|---|---|---|---|--- 
 1 | . | . | . | 2 | 3 | 5 | .

Instead, the instructions below allow us to order the variables according to their initial positions in
the table:

	%let varnum=4 7 3 2;
	%ds_order(_dstest6, odsn=dsn, varnum=&varnum);

so that the output dataset `dsn` contains the table:
 d | g | c | b | a | e | f | h 
---|---|---|---|---|---|---|--- 
 3 | 6 | 2 | 1 | . | . | 5 | .

	
It is also possible to order the variables in test dataset #6 according to the position of the same variables
(_i.e._ same name) in test dataset #5:

	%ds_order(_dstest6, odsn=dsn, varlike=_dstest5);

which returns in the output dataset `dsn` the following table:
 f | e | d | c | b | a | g | h 
---|---|---|---|---|---|---|---
 5 | . | 3 | 2 | 1 | . | 6 | .

Run macro `%%_example_ds_order` for more examples.

### Notes
1. In short, when `varlst` is set (instead of `varnum` or `varlike`), the macro runs the following `DATA` step:

        DATA &olib..&odsn;
			FORMAT &varlst; 
			SET &ilib..&idsn; 
        run;

2. Even when the input dataset `idsn` is already ordered as desired, the `DATA` step will still be ran 
as long as the output dataset `odsn` differs from `idsn`, so that a duplicated dataset is created.

### References
1. Go, I.C. (2002): ["Reordering variables in a SAS data set"](http://analytics.ncsu.edu/sesug/2002/PS12.pdf).
2. Clapson, A. (2014): ["Ordering columns in a SAS dataset: Should you really RETAIN that?"](http://support.sas.com/resources/papers/proceedings14/1751-2014.pdf).
3. ["Re-ordering variables"](http://www.sascommunity.org/wiki/Re-ordering_variables).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), 
[%var_rename](@ref sas_var_rename).
