## _DSTEST1 {#sas_dstest1}
Test dataset #1.

	%_dstest1;
	%_dstest1(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest1`:
| a |
|---|
| . |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest1`.

### Note 
In practice, it runs:

	DATA _dstest1;
		a=.;
	run;
	
### Example
To create dataset #1 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest1;
	%ds_print(_dstest1);

### See also
[%_dstestlib](@ref sas_dstestlib).
