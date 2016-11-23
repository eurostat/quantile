## ds_count {#sas_ds_count}
Count the number of observations in a dataset, possibly missing or non missing for a given variable.

	%ds_count(dsn, _nobs_=, miss=, nonmiss=, lib=WORK);

### Arguments
* `dsn` : a dataset;
* `miss` : (_option_) the name of variable/field in the dataset for which only missing
	observations are considered; default: `miss` is not set;
* `nonmiss` : (_option_) the names of variable/field in the dataset for which only NON missing
	observations are considered; this is obviously compatible with the `miss` argument above
	only when the variables differ; default: `nonmiss` is not set;
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_nobs_` : name of the macro variable used to store the result number of observations; by default 
	(_i.e._, when neither miss nor nonmiss is set, the total number of observations is returned)

### Example
Let us consider the table `_dstest28`:
geo | value 
----|------:
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can compute the TOTAL number of observations in `_dstest28`:

	%local nobs;
	%ds_count(_dstest28, _nobs_=nobs);

returns `nobs=6`, while:

	%ds_count(_dstest28, _nobs_=nobs, nonmiss=value);

returns the number of observations with NON MISSING `value`, _i.e._ `nobs=4`, and:

	%ds_count(_dstest28, _nobs_=nobs, miss=value, nonmiss=geo);

returns the number of observations with MISSING `value` and NON MISSING `geo` at the same time, 
_i.e._ `nobs=1`.

Run macro `%%_example_ds_count` for more examples.

### Reference
1. ["Counting the number of missing and non-missing values for each variable in a data set"](<http://support.sas.com/kb/44/124.html>).
2. Hamilton, J. (2001): ["How many observations are in my dataset?"](http://www2.sas.com/proceedings/sugi26/p095-26.pdf).

### See also
[%var_count](@ref sas_var_count), [%ds_check](@ref sas_ds_check), [%ds_isempty](@ref sas_ds_isempty), [%var_check](@ref sas_var_check).
