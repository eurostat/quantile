## _DSTEST0 {#sas_dstest0}
Test dataset #0.

	%_dstest0;
	%_dstest0(lib=, _ds_=, verb=no, force=no);

### Contents
`_dstest0` is an empty table.

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the name (library+table) of the dataset `_dstest0`. 

### Note 
In practice, it runs:

	DATA _dstest0; STOP; RUN;
	
### Example
To create dataset #0 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest0;
	%ds_print(_dstest0);

### See also
[%_dstestlib](@ref sas_dstestlib).
