## ds_check {#sas_ds_check}
* Check the existence of a dataset in a given library. 

      %let ans=%ds_check(dsn, lib=WORK);
* Trim a list of string elements to keep only those that actually define existing datasets in a given library.

      %ds_check(dsn, _dslst_=, lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `lib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used.
  
### Returns
* `ans` : (_option_) the error code of the test, _i.e._:
		+ `-1` when the library does not exist,
		+ `0` if the dataset exists,
    	+ `1` (error: "dsn does not exist") otherwise.
	
	should not be used contemporaneously with the option `_dslst_` below;
* `_dslst_` : (_option_) name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`; incompatible with returned result `ans` above. 

### Examples
Let us consider a non-empty dataset:
	
	%_dstest0;
	%let ans=%ds_check(_dstest0, lib=WORK);

returns `ans=0`. Let us then generate some datasets in `WORK`ing directory:

	%_dstest1;
	%_dstest2;
	%_dstest5;

we can then also use the macro to retrieve those elements in a given list that actually correspond 
to existing  datasets in `WORK`:

	%let ds=;
	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%ds_check(&ids, _dslst_=ds, lib=WORK);

returns `ods=_dstest1 _dstest2 _dstest5`.

Run macro `%%_example_ds_check` for examples.

### Notes
1. As mentioned above, two types of outputs are possible: either the answer `ans` to the test when
a result shall be returned (and `_dslst_` is not passed), or an updated list of acceptable datasets
(when `_dslst_` is passed). The former case is useful when testing a single dataset existence in a 
library, the latter for triming a list of actual datasets. Contemporaneous use is impossible.
2. In short, the error code returned (when `_dslst_` is not passed) is the evaluation of:

	   1 - %sysfunc(exist(&lib..&dsn, data));
3. The order of the variables in the output list matches that in the input list `dsn`.
4. When none of the string elements in `dsn` matches a dataset in `lib`, an empty list is set. 

### References
1. SAS support: ["Determine if a data set exists"](http://support.sas.com/kb/24/670.html).
2. Johnson, J. (2010): ["OBJECT_EXIST: A macro to check if a specified object exists"](http://www.pharmasug.org/cd/papers/TU/TU01.pdf).

### See also
[%ds_isempty](@ref sas_ds_isempty), [%lib_check](@ref sas_lib_check), [%var_check](@ref sas_var_check),
[%ds_contents](@ref sas_ds_contents), 
[EXIST](http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/viewer.htm#a000210903.htm).
