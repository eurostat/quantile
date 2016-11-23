## _DSTEST28 {#sas_dstest28}
Test dataset #28.

	%_dstest28;
	%_dstest28(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest28`:
geo | value 
----|-------
 AT |  1    
 '' |  .  
 BG |  2  
 '' |  3 
 FR |  .  
 IT |  4 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest28`.

### Example
To create dataset #28 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest28;
	%ds_print(_dstest28);

### See also
[%_dstestlib](@ref sas_dstestlib).
