## _DSTEST27 {#sas_dstest27}
Test dataset #27.

	%_dstest27;
	%_dstest27(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest27`:
geo | time 
----|-------
 BE |  2014    
 AT |  2013  
 BG |  2012  
 LU |  2014 
 FR |  2013  
 IT |  2013 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest27`.

### Example
To create dataset #27 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest27;
	%ds_print(_dstest27);

### See also
[%_dstestlib](@ref sas_dstestlib).
