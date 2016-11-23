## var_to_clist {#sas_var_to_clist}
Return the values of a given variable in a dataset into a formatted (_e.g._, parentheses-enclosed, 
comma-separated and/or quote-enhanced) list of strings.

	%var_to_clist(dsn, var, _varclst_=, distinct=no, mark=%str(%"), sep=%str(,), lib=WORK);

### Arguments
* `dsn` : a dataset reference;
* `var` : either a field name, or the position of a field name in, in `dsn`, whose values (observations) 
	will be converted into a list;
* `distinct` : (_option_) boolean flag (`yes/no`) set to return in the list only distinct values
	from `var` variable; in practice, runs a SQL `SELECT DISTINCT` process prior to the values'
	extraction; default: `no`, _i.e._ all values are returned;
* `na_rm` : (_option_) boolean flag (`yes/no`) set to remove missing (NA) values from the observations;
	default: `na_rm=yes`, therefore all missing (`.` or ' ') values will be discarded in the output
	list;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%str(%"), and" `sep= %%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details;
* `lib` : (_option_) output library; default (not passed or ' '): `lib` is set to `WORK`.

### Returns
`_varclst_` : name of the macro variable used to store the output formatted list, _i.e._ the list 
	of (comma-separated) main observations in between quotes.

### Examples
Let us consider the test dataset #32 in `WORK.dsn`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5
then running the macro:
	
	%let ctry=;
	%var_to_clist(_dstest32, geo, _varclst_=ctry);
	%var_to_clist(_dstest32,   1, _varclst_=ctry);

will both return: `ctry=("BE","AT","BG","LU","FR","IT")`, while:

	%let val=;
	%var_to_clist(_dstest32, value, _varclst_=val, distinct=yes, lib=WORK);
	
will return: `val=("0","0.1","0.2","0.3","0.4","0.5")`.

Run macro `%%_example_var_to_clist` for more examples.

### See also
[%var_to_list](@ref sas_var_to_list), [%clist_to_var](@ref sas_clist_to_var), [%var_info](@ref sas_var_info), [%list_quote](@ref sas_list_quote).
