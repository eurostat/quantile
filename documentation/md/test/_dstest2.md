## _DSTEST2 {#sas_dstest2}
Test dataset #2.

	%_dstest2;
	%_dstest2(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest2`:
| a |
|---|
| 1 |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest2`. 

### Note 
In practice, it runs:

	DATA _dstest2;
		a=1;
	run;
	
### Example
To create dataset #2 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest2;
	%ds_print(_dstest2);

### See also
[%_dstestlib](@ref sas_dstestlib).
