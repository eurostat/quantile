## _DSTEST32 {#sas_dstest32}
Test dataset #32.

	%_dstest32;
	%_dstest32(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest32`:
geo | value
----|------
 BE |  0
 AT |  0.1
 BG |  0.2
 LU |  0.3
 FR |  0.4
 IT |  0.5

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest32`.

### Example
To create dataset #32 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest32;
	%ds_print(_dstest32);

### See also
[%_dstestlib](@ref sas_dstestlib).
