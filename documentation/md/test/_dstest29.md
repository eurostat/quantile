## _DSTEST29 {#sas_dstest29}
Test dataset #29.

	%_dstest29;
	%_dstest29(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest29`:
|geo | 
|----|
| BE |   
| AT | 
| BG | 
| '' |
| FR | 
| IT |

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest29`.
	
### Example
To create dataset #29 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest29;
	%ds_print(_dstest29);

### See also
[%_dstestlib](@ref sas_dstestlib).
