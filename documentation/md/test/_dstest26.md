## _DSTEST26 {#sas_dstest26}
Test dataset #26.

	%_dstest26;
	%_dstest26(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest26`:
geo | time 
----|-------
 BE |  2014    
 AT |  2013  
 BG |  2012  
 LU |  2014 
 IT |  2013 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest26`.

### Example
To create dataset #26 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest26;
	%ds_print(_dstest26);

### See also
[%_dstestlib](@ref sas_dstestlib).
