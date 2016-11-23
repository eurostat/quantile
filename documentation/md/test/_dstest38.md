## _DSTEST38 {#sas_dstest38}
Test dataset #38.

	%_dstest38;
	%_dstest38(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest38`:
geo | EQ_INC20 | RB050a
----|----------|----------| 
 BE | 10       |   10 
 MK | 50       |   10
 MK | 60       |   10
 MK | 20       |   20
 UK | 10       |   20
 IT | 40       |   20

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) set for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest38`.

### Examples
To create dataset #38 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest38;
	%ds_print(_dstest38);

### See also
[%_dstestlib](@ref sas_dstestlib).
