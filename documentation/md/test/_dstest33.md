## _DSTEST33 {#sas_dstest33}
Test dataset #33.

	%_dstest33;
	%_dstest33(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest33`:
geo | value
----|------
 BE |  1
 AT |  .
 BG |  2
 LU |  3
 FR |  .
 IT |  4

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest33`.

### Example
To create dataset #33 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest33;
	%ds_print(_dstest33);

### See also
[%_dstestlib](@ref sas_dstestlib).
