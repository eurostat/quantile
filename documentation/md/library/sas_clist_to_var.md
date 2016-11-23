## clist_to_var {#sas_clist_to_var}

Insert into a (possibly already existing) dataset a variable formatted as a list 
of (_e.g._, comma-separated and quote-enhanced) values.

	%clist_to_var(clist, var, dsn, mark=%str(%"), sep=%quote(,), lib=WORK);

### Arguments
* `clist` :  list of formatted (_e.g._, comma-separated, quote-enhanced, parentheses-enclosed) 
	items;
* `var` : name of the variable to use in the dataset;
* `mark, sep` : (_option_) characters/strings used respectively as a "quote" and a separator in 
	the input list; default: `mark=`%%str(%"), and" `sep=``%%quote(,)`, _i.e._ the input `clist` is a 
	comma-separated list of quote-enhanced items; see [%clist_unquote](@ref sas_clist_unquote) for
	further details;
* `lib` : (_option_) output library; default (not passed or ''): `lib` is set to `WORK`.

### Returns
`dsn` : output dataset; if the dataset already exists, then observations with missing
	values everywhere except for the variable `var` (possibly not present in `dsn`) will 
	be appended to the dataset.
	
### Examples

	%let clist=("DE", "UK", "SE", "IT", "PL", "AT");
 	%clist_to_var(&clist, geo, dsn);	
	
returns in `WORK.dsn` the following table:
	Obs|geo
	---|---
	 1 | DE
	 2 | UK
	 3 | SE
	 4 | IT
	 5 | PL
	 6 | AT

Run macro `%_example_clist_to_var` for more examples.

### Note
If the dataset already exists and there are no numeric, or character variables  in it, 
then the following warning will be issued:

    WARNING: Defining an array with zero elements.

This message is not an error. See [%list_to_var](@ref sas_list_to_var).

### See also
[%list_to_var](@ref sas_list_to_var), [%var_to_clist](@ref sas_var_to_clist), [%clist_unquote](@ref sas_clist_unquote). 
