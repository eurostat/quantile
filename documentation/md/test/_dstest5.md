## _DSTEST5 {#sas_dstest5}
Test dataset #5.

### Contents
The following table is stored in `_dstest5`:
 f | e | d | c | b | a
---|---|---|---|---|---
 . | 1 | 2 | 3 | . | 5

###Usage 
Generate dataset #5 for testing.

	%_dstest5(lib=, _ds_=, verb=no, force=no);

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest5`.

### Example
To create dataset #5 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest5;
	%ds_print(_dstest5);

### See also
[%_dstestlib](@ref sas_dstestlib).
