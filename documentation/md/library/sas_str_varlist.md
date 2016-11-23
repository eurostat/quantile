## str_varlist {#sas_str_varlist}
* Output a formatted/zipped list of dataset and variables:

      %let %str_varlist(var, ds=, rep=%quote(, ), sep=%quote( ));

* Split a list of strings into a pair of dataset/variable strings, possibly trimming those 
that do not define actual variables in a dataset:

	%str_varlist(var, _varlst_=, _dslst_=, rep=%quote(, ), sep=%quote( ), lib=WORK, check=no);

### Arguments
* `var` : a list of strings/elements of the form `var` or `dsn.var` where the `dsn` represents
	some dataset and `var`, some variable;
* `ds=` : (_option_) Input reference dataset 								
* `_dslst_` : (_option_) Output list of datasets  						
* `_varlst_` : (_option_) Output list of variables			  				
* `sep, rep` : (_option_)  Replacement string 									
* `check=no` : (_option_) Boolean flag (`yes/no`) set to check the  variables' existence 	
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_varlst_` : name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`. 

### Example
Let us consider the following simple examples:

	%let var=a b y z c;
	%let ds=tab;
	%let lvar=%str_varlist(&var, ds=&ds);

returns `list=tab.a, tab.b, tab.y, tab.z, tab.c`, while

	%_dstest5;
	%let var=_dstest5.a,_dstest5.b,_dstest5.y,_dstest5.z,_dstest5.c;
	%let ds=;
	%let var=;
	%str_varlist(%quote(&var), _varlst_=var, _dslst_=ds, check=yes, rep=%quote( ), sep=%quote(,));

sets `var=a b c` and `ds=_dstest5 _dstest5 _dstest5`.

Run macro `%%_example_str_varlist` for more examples.

### Note
In short, given some variables `var` and `ds`, the first-case (most common) scenario ran through
the command `str_varlist(&var, ds=&ds)` actually runs:

	%let varlst=&ds..%list_quote(&var, mark=_EMPTY_, sep=&sep, rep=&rep%quote(&ds..));
which is also equivalent to:

	%let varlst=%list_append(%list_ones(%length(&var, sep=&sep), item=&ds), &var, zip=%quote(.), rep=%quote(, ));

### See also
[%str_dslist](@ref sas_str_dslist), [%var_check](@ref sas_var_check), [%ds_contents](@ref sas_ds_contents), 
[%ds_check](@ref sas_ds_check), [%list_append](@ref sas_list_append).
