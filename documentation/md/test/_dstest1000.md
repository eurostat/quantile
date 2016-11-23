## _DSTEST1000 {#sas_dstest1000}
Test dataset #1000.

	%_dstest1000;
	%_dstest1000(lib=, _ds_=, verb=no, force=no);

### Contents
The following table is stored in `_dstest1000`:
| i	| 
|---|
| 1	|
| 2	| 
| 3	| 
| 4	| 
|...| 
|999| 
|1000| 

### Arguments
* `lib` : (_option_) output library; default: `lib` is set to `WORK`;
* `verb` : (_option_) boolean flag (`yes/no`) for verbose mode; default: `no`;
* `force` : (_option_) boolean flag (`yes/no`) set to force the overwritting of the
	test dataset whenever it already exists; default: `no`. 

### Returns
`_ds_` : (_option_) the full name (library+table) of the dataset `_dstest1000`.

### Example
To create dataset #1000 in the `WORK`ing directory and print it, simply launch:
	
	%_dstest1000;
	%ds_print(_dstest1000);

### See also
[%_dstestlib](@ref sas_dstestlib).
