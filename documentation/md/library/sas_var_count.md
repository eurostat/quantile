## var_count {#sas_var_count}
Return the number of missing and non-missing values of a given variable in a dataset.

	%var_count(dsn, var, _count_=, _nmiss_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : a field name whose information is provided;
* `lib` : (_option_) output library; default: `lib` is set to `WORK`.

### Returns
`_count_, _nmiss_` : (_option_) names of the macro variables used to store the count or non-missing
	and missing values of the var variable in the dataset respectively; though both optional, one	
	at least should be passed.

### Examples
Let us consider the table `_dstest28`:
geo | value 
----|-------
 ' '|  1    
 AT |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  5 

then we can find the number of non-missing/missing `value` by running:

	%let count=;
	%let nmiss=;
	%var_count(_dstest28, value, _count_=count, _nmiss_=nmiss); 

which returns `count=4` and `nmiss=2`.

Run macro `%%_example_var_count` for more examples.

### See also
[%ds_count](@ref sas_ds_count), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info).
