## _DSTEST30 {#sas_dstest30}
Test dataset #30.

	%_dstest30;
	%_dstest30(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest30`:
geo | value 
----|-------
 BE |  0    
 AT |  0.1  
 BG |  0.2  
 '' |  0.3 
 FR |  0.4  
 IT |  0.5 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest30`.
	
### Examples
To create dataset #30 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest30;
	%ds_print(_dstest30);

### See also
[%_dstestlib](@ref sas_dstestlib).
