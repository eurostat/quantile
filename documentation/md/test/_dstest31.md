## _DSTEST31 {#sas_dstest31}
Test dataset #31.

	%_dstest31;
	%_dstest31(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest31`:
geo | value | unit
----|-------|-----
 BE |  0    | EUR
 AT |  0.1  | EUR
 BG |  0.2  | NAC
 LU |  0.3  | EUR
 FR |  0.4  | NAC
 IT |  0.5  | EUR

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest31`. 
	
### Example
To create dataset #31 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest31;
	%ds_print(_dstest31);

### See also
[%_dstestlib](@ref sas_dstestlib).
