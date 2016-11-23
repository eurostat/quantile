## var_rename {#sas_var_rename}
Perform a 'bulk-renaming' of the variables of a given table. 

    %var_rename(idsn, var=, ex_var=, odsn=, suff=_new, ilib=WORK, olib=WORK);

### Arguments
* `idsn` : input reference dataset, whose variables shall be renamed;
* `var` : (_option_) list of variables that should be renamed; this parameter is incompatible
	with the parameter `ex_var` below; default: `var` is empty, and all variables present in
	the input dataset `idsn` will be renamed (unless `ex_var` is not empty);
* `ex_var` : (_option_) list of variables that should not be renamed; this parameter is 
	incompatible with the parameter `var` below;typically the identifying variables which will 
	be used to perform the matching shall not be renamed; default: `ex_var` is empty;
* `suff` : (_option_) generic suffix to be added to the names of the variables; default: 
	`suff=_new`, _i.e._ a variable `a` in `idsn` will be renamed as `a_new`;
* `odsn` : (_option_) name of the output dataset; default: `odsn=idsn` so that the input
	dataset is in practice updated;
* `ilib` : (_option_) name of the input library; by default: empty, _i.e._ `WORK` is used;
* `olib` : (_option_) name of the output library; by default: empty, and the value of `ilib` 
	is used.

### Returns
`odsn` : output dataset (stored in the `olib` library), containing the exact same data than `idsn`,
	where all variables defined by `var` and/or excluding those defined by `ex_var` are renamed as 
	a concatenation of their former name and `suff`.

### Examples
Let us consider test dataset #5 in WORKing directory:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

then both calls to the macro below:

	%var_rename(_dstest5, var=a c d, odsn=out1, suff=2);
	%var_rename(_dstest5, ex_var=b e f, odsn=out2, suff=2);
	
will return the exact same dataset `out1=out2` (in WORKing directory) below:
 f | e | d2 | c2 | b | a2
---|---|----|----|---|---
 . | 1 | 2  | 3  | . | 5

Run macro `%%_example_var_rename` for more examples.

### Note
1. When merging two similar tables, it may be useful to be able to add a suffix over the names of 
the variables in order to avoid unexpected deletion of data. One may, for instance, need to merge 
two similar tables from different years: it is then necessary to rename all variables containing 
information that varies across time. The macro `var_rename` can be used for this purpose.
2. When none of the input parameters `var` and `ex_var` is passed, all variables present in the 
input dataset `idsn` are renamed.
3. The macro implementation was contributed to by P.BBES.Lamarche (<mailto:pierre.lamarche@ec.europa.eu>).

### See also
[%ds_contents](@ref sas_ds_contents), [%var_check](@ref sas_var_check), [%var_info](@ref sas_var_info), 
[%ds_order](@ref sas_ds_order).
