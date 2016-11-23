## str_dslist {#sas_str_dslist}

NOOOOOOOOOOOOOOOOOO - look at [%ds_check](@ref sas_ds_check)

Trim a list of strings to keep only those that actually define existing datasets in a given
library.

	%str_dslist(dsn, _dslst_=, lib=WORK);

### Arguments
* `dsn` : (list of) reference dataset(s);
* `lib` : (_option_) name of the input library; by default: `WORK` is used.

### Returns
`_dslst_` : name of the macro variable used to store the elements from `var` that actually
	define existing variables/fields in `dsn`. 

### Example
Let us generate some default datasets in `WORK`ing directory:

	%_dstest1;
	%_dstest2;
	%_dstest5;

we can then retrieve those elements in a given list that actually correspond to existing  
datasets in `WORK`:

	%let ds=;
	%let ids= _dstest1 dummy1 _dstest2 dummy2 _dstest5;
	%str_dslist(&ids, _dslst_=ds, lib=WORK);

returns `ods=_dstest1 _dstest2 _dstest5`.

Run macro `%%_example_str_listds` for more examples.

### Note
1. The order of the variables in the output list matches that in the input list `dsn`.
2. When none of the string elements in `dsn` matches a dataset in `lib`, an empty list is set. 

### See also
[%str_varlist](@ref sas_str_varlist), [%ds_check](@ref sas_ds_check).
